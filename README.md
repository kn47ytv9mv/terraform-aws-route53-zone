# terraform-aws-route53-zone

Terraform module for a Route 53 hosted zone, public or private.

## Cost

Route 53 bills per hosted zone, per month, and per query against that
zone — this module creates the zone itself, so both charges originate
here. See AWS's [Route53 pricing](https://aws.amazon.com/route53/pricing/)
page for current rates.

## Design

Setting `vpc_id` makes this a **private** hosted zone, associated with
that VPC; leaving it null creates a **public** one. AWS requires a
private zone to have at least one VPC at creation, so `vpc_id`/`vpc_region`
are this module's *only* VPC association — later plans ignore drift on
the zone's `vpc` attribute entirely, so **changing `vpc_id`/`vpc_region`
after creation has no effect**. This is deliberate: without it, this
resource would fight
[`terraform-aws-route53-zone-association`](https://github.com/kn47ytv9mv/terraform-aws-route53-zone-association)
over every VPC that module adds.

Add more VPCs to a private zone with
[`terraform-aws-route53-zone-association`](https://github.com/kn47ytv9mv/terraform-aws-route53-zone-association)
(same account or a different one, once authorized via
[`terraform-aws-route53-vpc-association-authorization`](https://github.com/kn47ytv9mv/terraform-aws-route53-vpc-association-authorization)).
Add records with
[`terraform-aws-route53-record`](https://github.com/kn47ytv9mv/terraform-aws-route53-record).

### Why query logging takes a switch

`enable_query_logging` beside `query_log_group_arn` looks redundant. It
exists because **Terraform decides how many resources to create before it
knows any value AWS computes.** A log group built in the same
configuration has no ARN at plan time, so gating on
`query_log_group_arn != null` fails with *"Invalid count argument ...
cannot be determined until apply"* — which is the ordinary case, since the
log group normally comes from
[`terraform-aws-cloudwatch-log-group`](https://github.com/kn47ytv9mv/terraform-aws-cloudwatch-log-group).
A boolean the caller writes is always known at plan time. Supplying one
without the other is rejected in both directions.

**Query logging is only available in `us-east-1`**, regardless of where
the rest of a configuration lives, and the log group's resource policy
must permit `route53.amazonaws.com` to write to it.

## Usage

A public zone:

```hcl
module "zone" {
  source = "kn47ytv9mv/route53-zone/aws"

  name = "example.com"
}
```

Or directly from this repository, a private zone shared across every
region in a global network — paired with
[`terraform-aws-route53-zone-association`](https://github.com/kn47ytv9mv/terraform-aws-route53-zone-association)
for the VPCs beyond the first:

```hcl
module "zone" {
  source = "github.com/kn47ytv9mv/terraform-aws-route53-zone"

  name       = "internal.example.com"
  vpc_id     = module.vpc_us_east_1.vpc_id
  vpc_region = "us-east-1"
}

module "zone_association_eu_west_1" {
  source = "kn47ytv9mv/route53-zone-association/aws"

  providers = { aws = aws.eu_west_1 }

  zone_id    = module.zone.id
  vpc_id     = module.vpc_eu_west_1.vpc_id
  vpc_region = "eu-west-1"
}
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.0 |
| aws | ~> 6.61 |

## Providers

| Name | Version |
|---|---|
| aws | ~> 6.61 |

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| name | Domain name for the hosted zone. | `null` | no |
| comment | A comment for the hosted zone. If null, no comment is set. | `null` | no |
| force_destroy | Whether to destroy the zone even if it still contains records. | `false` | no |
| vpc_id | The ID of a VPC to associate at creation, making this a private hosted zone. If null, a public hosted zone is created. Only this module's own initial association is managed here — see the Design section for adding more. | `null` | no |
| vpc_region | Region of vpc_id, used only when vpc_id is set. If null, AWS assumes this provider's own region. | `null` | no |
| tags | A map of tags to assign to the hosted zone. | `null` | no |
| enable_query_logging | Whether DNS queries against this zone are logged to `query_log_group_arn`. Separate from the ARN because Terraform needs the decision known at plan time — see Design. | `false` | no |
| query_log_group_arn | ARN of a CloudWatch log group receiving DNS query logs, from `terraform-aws-cloudwatch-log-group`. Supplying one enables query logging. Public zones only, and AWS requires the log group to live in `us-east-1`. | `null` | no |

## Outputs

| Name | Description |
|---|---|
| id | The ID of the hosted zone. |
| arn | The ARN of the hosted zone. |
| name_servers | Authoritative name servers for the zone. Populated for a public zone — delegate the domain's NS records to these. |

## License

MIT — see [LICENSE.md](LICENSE.md).
