# Cost engineering

Adria-Stay is a dev environment. It is built for a work session and
destroyed at the end of it, so the number that matters is not the monthly
bill but the cost of one session. This file records both: what the stack
would cost left running around the clock, and what it actually costs given
that it is torn down every time.


All prices are eu-central-1 (Frankfurt), on-demand, and assume roughly 730
hours in a month.

## If left running 24/7

Prices are USD list rates for eu-central-1, converted to EUR at roughly current rates; the actual bill in Cost Explorer shows AWS's own conversion.

| Component | Cost / month | Notes |
|---|---|---|
| NAT gateway | ~€34 | The single largest line. Charged per hour plus per GB processed, whether or not traffic flows. |
| Application Load Balancer | ~€20 | Charged per hour plus per LCU. At dev traffic the LCU part sits near the minimum. |
| 2 x t3.micro (EC2) | ~€16 | Two instances, one per availability zone. Priced per instance-hour. |
| RDS db.t4g.micro | ~€12 | Single-AZ PostgreSQL. Instance-hour only; storage is the next row. |
| RDS storage, 20 GB gp3 | ~€2 | Priced per GB-month, independent of the instance. |
| Public IPv4 (Elastic IP on the NAT) | ~€3.30 | Since February 2024 every public IPv4 address is billed per hour, attached or not. |
| CloudFront + S3 assets | ~€0.50 | Data transfer out plus requests, plus a few GB-months of storage. Pennies at dev traffic. |
| S3 state bucket | ~€0.10 | The only resource that is never destroyed. State is a few KB, so this is effectively a rounding error. |
| **Total** | **~€88** | |

## What a session actually costs

The stack is destroyed with `terraform destroy` from `envs/dev` at the end
of every session, so almost none of the monthly figure above is ever paid.
The real cost is the hourly resources multiplied by the length of a session,
plus the one permanent resource.

To measure it against reality: AWS Billing -> Cost Explorer, filter by the
tag `Project = adria-stay`, group by service, and read the last few days.


## Why the environment is destroyed after every session

Destroying the stack is not a saving measure bolted on afterwards; it is
part of the design. An environment rebuilt from zero every time is proof
that the code alone is enough to stand the whole thing up, no manual step,
no console click, nothing that lives only in one person's memory. The low
bill is a side effect of that discipline, not its purpose.