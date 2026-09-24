resource "aws_route53_zone" "resource" {
  name    = var.name
  comment = var.comment

  force_destroy = var.force_destroy

  dynamic "vpc" {
    for_each = var.vpc_id[*]

    content {
      vpc_id     = vpc.value
      vpc_region = var.vpc_region
    }
  }

  tags = var.tags

  # Avoids fighting terraform-aws-route53-zone-association over VPCs it adds.
  lifecycle {
    ignore_changes = [vpc]
  }
}

resource "aws_route53_query_log" "resource" {
  count = var.enable_query_logging ? 1 : 0

  zone_id                  = aws_route53_zone.resource.zone_id
  cloudwatch_log_group_arn = var.query_log_group_arn
}

output "id" {
  description = "The ID of the hosted zone."
  value       = aws_route53_zone.resource.id
}

output "arn" {
  description = "The ARN of the hosted zone."
  value       = aws_route53_zone.resource.arn
}

output "name_servers" {
  description = "Authoritative name servers for the zone. Populated for a public zone — delegate the domain's NS records to these."
  value       = aws_route53_zone.resource.name_servers
}
