# Adria-Stay

Terraform-built AWS infrastructure for a small hospitality business on the
Croatian coast. The traffic is brutally seasonal, close to ten times as many
visitors in August as in January, so the stack is built to scale for the peak
without paying peak prices the rest of the year. Everything runs from code.
Guest data sits in private subnets, no SSH port is open anywhere, and every
real decision is written down as it was made.

![Architecture diagram](docs/adria-stay-architecture.drawio.png)

## Highlights

- No SSH ports are open to the internet. Getting a shell means going through
  SSM Session Manager, so there is no bastion host and no key pair to lose.
- No long-lived AWS keys live anywhere. The pipeline signs in with OIDC and
  gets a token that lasts an hour, then expires on its own.
- The database password never appears in the code or in the state file. RDS
  creates it, keeps it in Secrets Manager, and gives Terraform nothing but
  the ARN.
- Static files sit in a private S3 bucket that only one CloudFront
  distribution is allowed to read. Ask the bucket directly and it says no.
- Every pull request runs 225 security checks and they all pass. The 27 rules
  that are switched off are switched off in a single file, each with a note
  next to the resource explaining the call.
- Eleven decisions are written down as short records, from why there is only
  one NAT gateway to why the database sits in a single zone.

## Architecture

A guest's request lands first on the Application Load Balancer, which sits
across the two public subnets and hands the request to one of the app
instances behind it. Those instances live in private subnets, split across
two availability zones, and they are the only tier allowed to talk to the
database. The database has no route to the internet at all, not even
outbound. A managed Postgres instance has no reason to reach out, and every
route you remove is one less way in.

Images and other static files never go near the load balancer. They come from
CloudFront, which pulls them from a private bucket that visitors cannot open
on their own. Hit the bucket URL directly and you get access denied. Go
through the CDN and the file arrives from a nearby edge location, over HTTPS.

The whole thing runs across two zones for a reason that is more about learning
than production. I wanted the failure story to be something you could actually
watch happen. Kill an instance by hand and the Auto Scaling group brings up a
replacement. Lose a whole zone and the load balancer keeps serving from the
other one. A single instance would have hidden all of that, which is the
opposite of what I wanted.

## Key design decisions

The full reasoning for each of these is in [docs/DECISIONS.md](docs/DECISIONS.md).

| Decision | What I chose | Why |
|---|---|---|
| Modules | Written by hand instead of pulled from the registry | The goal was to learn the resources, not a module's input variables |
| NAT gateway | One, shared across both zones | A second one doubles the cost to protect an environment that is torn down every session |
| Database | Single zone, with the master password managed by AWS | Multi-AZ is one boolean away, and the password stays out of the code and the state |
| Access | SSM Session Manager rather than SSH | No bastion, no open port 22, no private key sitting somewhere |
| TLS | HTTP only, for now | With no domain there is no certificate to issue, so it is recorded as a gap, not a design choice |

## Security posture

- Guest data sits in private subnets with no way in from the internet.
- The app tier reaches the outside world only through the NAT gateway, and
  only outbound.
- The database tier has no default route at all, so it could not reach the
  internet even if something on it tried.
- Instances enforce IMDSv2, which closes the metadata path an attacker would
  use to steal the credentials of the instance's own role.
- Root volumes are encrypted, and the load balancer drops malformed headers
  before they ever reach the application.
- The VPC's default security group is emptied and left unused, so nothing can
  quietly fall back onto it.

## How changes ship

Every change goes through a pull request. GitHub Actions signs in to AWS with
OIDC, so there are no long-lived keys stored anywhere, then runs fmt,
validate, tflint, checkov and a plan, and posts that plan back as a comment.
The pipeline is allowed to read the account and lock the state, but it cannot
change anything. Running apply is still a person's job.

![The pipeline running on a pull request, every check green](docs/ci-plan-on-pr.png)

## Cost engineering

Left running around the clock, the stack would cost somewhere near 88 euros a
month, and the NAT gateway on its own is about a third of that. It almost
never runs around the clock. Every session ends with `terraform destroy`, so
what actually gets paid is a few hours of the hourly resources plus one very
small state bucket that stays behind. The line-by-line breakdown is in
[docs/COSTS.md](docs/COSTS.md).

Tearing the stack down after every session is not a saving trick bolted on
top. It is the proof that the code by itself can rebuild the whole environment
from nothing, with no manual step and no click in a console. The small bill is
just a side effect of that.

## Deploy it yourself

You will need an AWS account with admin rights, Terraform 1.10 or newer, and
the AWS CLI configured. Two things tend to catch people out. The bucket names
for the state and the assets have to be globally unique, so change them first.
And the Auto Scaling service-linked role has to exist in the account before
the first apply. If it does not, create it once:

```
aws iam create-service-linked-role --aws-service-name autoscaling.amazonaws.com
```

Then apply in order. Bootstrap goes first, because it builds the state bucket
and the CI role, and it keeps its own state locally:

```
cd bootstrap
terraform init
terraform apply
```

Then the environment, which stores its state in the bucket bootstrap just
made:

```
cd ../envs/dev
terraform init
terraform apply
```

When you are finished, tear the environment down. Never the bootstrap.

```
terraform destroy
```

## Roadmap (v2)

These are the known gaps. Every one of them is deliberate and written down
somewhere, rather than quietly skipped.

- VPC flow logs, and access logging on the load balancer, the CDN and the
  buckets
- A WAF in front of both the load balancer and CloudFront
- A real domain with an ACM certificate, an HTTPS listener, and a redirect off
  port 80
- Multi-AZ on the database
- A move to ECS Fargate
- A multi-account setup with AWS Organizations
- An AI review step in the pipeline that reads the plan and flags anything
  destructive or expensive before a human has to


## How I think about a stack

Somewhere in this project the resources stopped being a list and started
being answers to a handful of questions. This is the frame I now use to read
any architecture, and every part of this repository maps onto one of these:

- **Where does it live?** The network: a VPC, subnets layered across
  availability zones, and the ways out, an internet gateway, a NAT, or
  endpoints.
- **What runs the code?** EC2 behind an Auto Scaling group here, but it could
  be containers or functions, and the real question is how it scales.
- **How does traffic get in?** A load balancer, a CDN, an API gateway.
- **Where is the state?** A relational database, object storage, a cache.
- **Who is allowed to do what, and who can reach whom?** IAM roles vertically,
  from a resource to the AWS services it may use; security groups
  horizontally, from one tier to the next.
- **How do I know it works?** Health checks, logs, alarms.
- **How do changes ship?** Infrastructure as code, state, a pipeline, and who
  gets to approve.

Once the questions are in that order, an unfamiliar stack stops being
intimidating. You are not looking at fifty resources. You are looking at seven
decisions, and the resources are just how each one was answered.

## What I learned

The point of this project was Terraform and infrastructure as code, and most
of what was new to me was structural. Splitting the repository into a
bootstrap that builds its own backend, reusable modules, and a CI workflow was
a shape I had not worked in before, and getting that layout right taught me
more than any single resource did. Writing an ADR for each decision was new
too. I hold an AWS Solutions Architect Associate, so the calls themselves were
not surprises, but having to write down the reason turned a gut feeling into
something I had to defend in a sentence.

The one finding that genuinely caught me off guard was the scanner flagging
port 80 as open to the world on a rule that has no CIDR block in it at all. It
matches on the port and the resource type without looking at where the traffic
comes from, which is the load balancer's security group. A good reminder that
a tool with a checklist and no context will be confidently wrong.