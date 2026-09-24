mock_provider "aws" {
}

run "no_vpc_id_creates_public_zone" {
  command = plan

  variables {
    name = "example.com"
  }

  assert {
    condition     = length(aws_route53_zone.resource.vpc) == 0
    error_message = "No vpc_id was given, so the zone should have no vpc block (a public zone)."
  }
}

run "vpc_id_creates_private_zone" {
  command = plan

  variables {
    name       = "internal.example.com"
    vpc_id     = "vpc-0123456789abcdef0"
    vpc_region = "eu-west-1"
  }

  assert {
    condition     = length(aws_route53_zone.resource.vpc) == 1
    error_message = "vpc_id was given, so the zone should have exactly one vpc block."
  }

  assert {
    condition     = anytrue([for v in aws_route53_zone.resource.vpc : v.vpc_id == "vpc-0123456789abcdef0"])
    error_message = "vpc_id should pass through unchanged into the vpc block."
  }

  assert {
    condition     = anytrue([for v in aws_route53_zone.resource.vpc : v.vpc_region == "eu-west-1"])
    error_message = "vpc_region should pass through unchanged into the vpc block."
  }
}

run "comment_and_force_destroy_pass_through" {
  command = plan

  variables {
    name          = "example.com"
    comment       = "managed by terraform"
    force_destroy = true
  }

  assert {
    condition     = aws_route53_zone.resource.comment == "managed by terraform"
    error_message = "comment should pass through unchanged."
  }

  assert {
    condition     = aws_route53_zone.resource.force_destroy == true
    error_message = "force_destroy should pass through unchanged."
  }
}

run "no_query_logging_by_default" {
  command = plan

  variables {
    name = "example.com"
  }

  assert {
    condition     = length(aws_route53_query_log.resource) == 0
    error_message = "Leaving query_log_group_arn unset should create no query log resource."
  }
}

run "supplying_a_log_group_enables_query_logging" {
  command = plan

  variables {
    name                 = "example.com"
    enable_query_logging = true
    query_log_group_arn  = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/example"
  }

  assert {
    condition     = length(aws_route53_query_log.resource) == 1
    error_message = "Supplying a log group should create exactly one query log resource."
  }
}

run "readme_public_zone_example" {
  command = plan

  variables {
    name = "example.com"
  }
}

run "readme_private_global_zone_example" {
  command = plan

  variables {
    name       = "internal.example.com"
    vpc_id     = "vpc-0123456789abcdef0"
    vpc_region = "us-east-1"
  }
}

run "enabling_query_logging_without_a_log_group_is_rejected" {
  command = plan

  variables {
    name                 = "example.com"
    enable_query_logging = true
  }

  expect_failures = [var.enable_query_logging]
}

run "a_log_group_without_enabling_query_logging_is_rejected" {
  command = plan

  variables {
    name                = "example.com"
    query_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/example"
  }

  expect_failures = [var.enable_query_logging]
}
