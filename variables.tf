variable "name" {
  default     = null
  description = "Domain name for the hosted zone."
}

variable "comment" {
  default     = null
  description = "A comment for the hosted zone. If null, no comment is set."
}

variable "force_destroy" {
  default     = false
  description = "Whether to destroy the zone even if it still contains records."
}

variable "vpc_id" {
  default     = null
  description = "The ID of a VPC to associate at creation, making this a private hosted zone. If null, a public hosted zone is created. Only this module's own initial association is managed here — see the Design section for adding more."
}

variable "vpc_region" {
  default     = null
  description = "Region of vpc_id, used only when vpc_id is set. If null, AWS assumes this provider's own region."
}

variable "enable_query_logging" {
  default     = false
  description = "Whether DNS queries against this zone are logged to query_log_group_arn. This is a separate switch because Terraform requires the decision to be known before it plans, and the ARN of a log group created in the same configuration is not — see the Design section."

  validation {
    condition     = !var.enable_query_logging || var.query_log_group_arn != null
    error_message = "enable_query_logging requires query_log_group_arn to name the log group receiving the queries."
  }

  validation {
    condition     = var.query_log_group_arn == null || var.enable_query_logging
    error_message = "query_log_group_arn is set but enable_query_logging is false, so no queries would be logged. Set enable_query_logging = true."
  }
}

variable "query_log_group_arn" {
  default     = null
  description = "ARN of a CloudWatch log group receiving DNS query logs for this zone, from terraform-aws-cloudwatch-log-group. Supplying one enables query logging automatically. Only public zones can be query-logged, and AWS requires the log group to live in us-east-1 regardless of where the zone is managed. If null, queries are not logged."
}

variable "tags" {
  default     = null
  description = "A map of tags to assign to the hosted zone."
}
