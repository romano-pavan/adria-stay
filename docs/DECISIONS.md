## ADR-001: Write core Terraform modules by hand instead of using registry modules

**Date:** 2026-07-10

**Context:** Community modules like terraform-aws-modules/vpc are
battle-tested and production-ready. Using them would get me to a
working stack much faster.


**Options considered:**
- A) Registry modules — fast, proven, but I'd be learning the module's
  input variables instead of the actual AWS resources underneath.
- B) Hand-written modules — slower, more mistakes along the way, but I
  learn every resource, every argument, every relationship.


**Decision:** B for v1 of this project.

**Why:** The main output of this project is my understanding, not the
infrastructure itself. I'm sacrificing speed for depth on purpose.


**Revisit when:** In a team/production context I would default to
registry modules and review their source instead.





## ADR-002 - State locking with the S3 lockfile instead of DynamoDB

**Date:** 2026-07-27

Two applies running at the same time against one state file can corrupt it, so the backend needs a lock. 
The classic setup adds a DynamoDB table that exists only to hold that lock. Since Terraform 1.10 the S3 backend
can lock natively with a lockfile (use_lockfile = true), no extra table.

I'm going with the lockfile: one less resource to build, pay for and break, and the lock lives in the same bucket as the state itself. The trade-off is that it needs Terraform 1.10 or newer, and that most older tutorials and teams still run the DynamoDB pattern, so I want to
recognize that setup when I see it. On a team pinned to older Terraform, DynamoDB would be my fallback.



## ADR-003 - Discover availability zones with a data source instead of hardcoding them

**Date:** 2026-08-18

The subnets need to be spread across two availability zones. I could
write "eu-central-1a" and "eu-central-1b" straight into the module, but
then the module only ever works in Frankfurt. Instead I read the
aws_availability_zones data source and take the first two names from it.

The module is now region-portable:point it at another region and it
picks up that region's zones. The trade-off is that zone names are
per-account aliases, so names[0] in my account is not guaranteed to be
the same physical zone as names[0] in someone else's. For a dev
environment that does not matter. Where physical placement actually
matters pinning a workload next to another account's resources, or
tracking real capacity the zone IDs are the stable identifier and I
would use those instead.


## ADR-004 - One NAT gateway in dev, no internet route for the data tier

**Date:** 2026-08-18

Private subnets need outbound internet access for OS and package updates,
but nothing from the internet should be able to reach them. That is what
a NAT gateway does: it only lets connections that were started from the
inside.

Options I looked at: one NAT for the whole VPC; one NAT per availability
zone; no NAT at all with VPC endpoints for the specific AWS services;
or a self-managed NAT instance on EC2.

I'm running one NAT gateway in the public subnet of the first zone. It is
roughly 33€ per month plus data processing in eu-central-1, and the second
NAT would double that for an environment that is torn down after every
session. The trade-off is real and I'm accepting it knowingly. If the
first zone fails, instances in the second zone keep serving traffic
through the load balancer and keep talking to the database, but they lose
their outbound path, so updates stop until the zone recovers.Traffic from
the second zone also crosses a zone boundary to reach the NAT, which is
billed. For production I would run one NAT per zone.

The data subnets get their own route table with no default route at all
only the implicit local route. RDS is a managed service and AWS patches it
from the inside, so the database tier has no reason to reach the internet.
Fewer routes, smaller blast radius.



## ADR-005 - The load balancer listens on HTTP only in dev

**Date:** 2026-08-19

Serving the site over HTTPS needs a TLS certificate, and AWS Certificate
Manager only issues certificates for domains you can prove you own. This
project has no registered domain, so there is nothing to issue a
certificate against. The load balancer listens on port 80.

I'm recording this as a known gap rather than a finished design. In
production the stack would have a domain, a certificate from ACM, a
listener on 443, and a listener on 80 whose only job is to redirect
everything to 443. None of that changes the application or the
architecture, so it stays a certificate problem, not a design problem.



## ADR-006 - Access instances through SSM Session Manager instead of SSH

**Date:** 2026-08-19

The app instances live in private subnets and still need to be reachable
for troubleshooting. The classic answer is SSH with a key pair, which
also means a bastion host in a public subnet, an inbound rule on port 22,
and a private key that has to live somewhere. SSM Session Manager needs
none of that: an agent on the instance opens an outbound connection to
the SSM service, and sessions are relayed through the AWS API. No open
port, no key pair, no bastion to run and patch. Who gets in is decided by
IAM, the same way as everything else, so it lands in the same audit trail
and sessions can be logged.

The trade-off is a new dependency. Access now relies on the agent running
and on the instance having a path to the SSM endpoints, which in this
build means through the NAT gateway. If the NAT is gone, so is my way in,
while a bastion with SSH would still be reachable. The fix for production
is VPC endpoints for SSM, which removes the NAT from the access path
entirely. I'm accepting the dependency in dev because losing shell access
to a throwaway environment costs nothing.


## ADR-007 - Two instances in dev, and the ASG judges health by the load balancer

**Date:** 2026-08-20

The Auto Scaling group runs a minimum of two instances, one per
availability zone, with a ceiling of four. One instance would be cheaper,
but it would also make the whole point of this layer invisible. With a
single target I cannot show traffic being distributed, I cannot lose a
zone without losing the site, and a failed instance means downtime
instead of a rolling replacement. Two t3.micro instances in a dev
environment that gets destroyed after every session cost cents.

By default an Auto Scaling group only looks at the EC2 status checks,
which say whether the virtual machine and its operating system are
alive. That is not the same question the users are asking. If nginx dies
while the box keeps running, the load balancer stops sending traffic to
that instance but the group happily keeps it, so I end up paying for a
target nobody uses and nobody replaces. Setting the health check type to
ELB makes the group defer to the target group's verdict, which is the
one that reflects whether the application actually answers.

The cost of that choice is a grace period. Instances install nginx at
boot, so the group has to wait before it starts judging them, and I set
that to 300 seconds. A genuinely broken instance therefore survives its
first five minutes. Too short and I get a replacement loop where every
new instance is killed before it finishes booting; too long and real
failures linger. In production the right fix is a pre-baked image so
there is nothing to install at boot and the grace period can shrink.


## ADR-008 - Single-AZ database in dev, with the master password managed by AWS

**Date:** 2026-08-20

The database runs single-AZ in the first availability zone. Multi-AZ
would keep a synchronous standby in the second zone and fail over
automatically, and it roughly doubles the cost of the instance for an
environment that is destroyed at the end of every session. The trade-off
is stated plainly in ADR-004: if the first zone fails, the app instances
in the second zone stay up and keep serving requests, but they have
nothing to talk to. Production runs Multi-AZ, and nothing in this code
changes except one boolean.

The master password is never generated by me. RDS creates it, stores it
in Secrets Manager, rotates it, and hands Terraform only the ARN of the
secret. That keeps the password out of the repository and, more
importantly, out of the state file, which otherwise records every
attribute of every resource in plain text. The application reads the
secret at runtime through its IAM role, so nobody ever holds a copy.

Final snapshots are skipped and deletion protection is off, both because
this environment is meant to be thrown away. In production both are
inverted, and that inversion is the difference between a recoverable
mistake and a permanent one.


## ADR-009 - Static assets stay in a private bucket behind CloudFront

**Date:** 2026-08-20

The simplest way to serve images is a public S3 bucket. 
A public bucket has no gate,anyone who guesses or leaks an object key 
reads it, every request is billed at S3 rates from a single region,
and a bucket that is public today is public for every object anyone ever 
puts in it.

Instead the bucket blocks all public access and the only reader is one
specific CloudFront distribution, enforced by a condition on the
distribution ARN in the bucket policy. CloudFront signs every request to
the origin, so there is no path to the objects that bypasses the CDN.
Visitors get the files from an edge location near them, over HTTPS on
CloudFront's own certificate, which is more than the load balancer
currently offers.

The cost is one more moving part and cache invalidation to think about
when a file changes. For a site whose images change a few times a season
that is not a real problem.


