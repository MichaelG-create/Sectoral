#=============================================================================
# IAM MODULE VARIABLES - Financial Data Pipeline
#=============================================================================
#
# Variables for IAM roles and policies
#
#------------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs for access permissions"
  type        = list(string)
  default     = []
}

variable "redshift_cluster_arn" {
  description = "ARN of the Redshift cluster"
  type        = string
  default     = null
}

variable "secrets_manager_arns" {
  description = "List of Secrets Manager ARNs"
  type        = list(string)
  default     = []
}

variable "lambda_vpc_access" {
  description = "Whether Lambda functions need VPC access"
  type        = bool
  default     = false
}

variable "create_api_gateway_role" {
  description = "Whether to create API Gateway execution role"
  type        = bool
  default     = false
}

variable "trusted_account_ids" {
  description = "List of trusted AWS account IDs for cross-account access"
  type        = list(string)
  default     = []
}

variable "external_id" {
  description = "External ID for cross-account role assumption"
  type        = string
  default     = null
}

variable "enable_cloudtrail_access" {
  description = "Enable CloudTrail access for audit purposes"
  type        = bool
  default     = false
}

variable "enable_config_access" {
  description = "Enable AWS Config access for compliance"
  type        = bool
  default     = false
}

variable "enable_cost_explorer_access" {
  description = "Enable Cost Explorer access for cost analysis"
  type        = bool
  default     = false
}

variable "custom_policy_arns" {
  description = "List of custom policy ARNs to attach to roles"
  type        = list(string)
  default     = []
}

variable "data_lake_additional_actions" {
  description = "Additional actions for data lake role"
  type        = list(string)
  default     = []
}

variable "lambda_additional_actions" {
  description = "Additional actions for lambda role"
  type        = list(string)
  default     = []
}

variable "redshift_additional_actions" {
  description = "Additional actions for Redshift role"
  type        = list(string)
  default     = []
}

variable "glue_additional_actions" {
  description = "Additional actions for Glue role"
  type        = list(string)
  default     = []
}

variable "enable_data_pipeline_notifications" {
  description = "Enable SNS notifications for data pipeline"
  type        = bool
  default     = false
}

variable "sns_topic_arns" {
  description = "List of SNS topic ARNs for notifications"
  type        = list(string)
  default     = []
}

variable "enable_cross_region_replication" {
  description = "Enable cross-region replication permissions"
  type        = bool
  default     = false
}

variable "replication_regions" {
  description = "List of regions for cross-region replication"
  type        = list(string)
  default     = []
}

variable "enable_data_encryption" {
  description = "Enable data encryption permissions"
  type        = bool
  default     = true
}

variable "kms_key_arns" {
  description = "List of KMS key ARNs for encryption"
  type        = list(string)
  default     = []
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs permissions"
  type        = bool
  default     = false
}

variable "vpc_flow_logs_bucket_arn" {
  description = "S3 bucket ARN for VPC Flow Logs"
  type        = string
  default     = null
}

variable "enable_data_quality_checks" {
  description = "Enable data quality checks permissions"
  type        = bool
  default     = true
}

variable "data_quality_lambda_arns" {
  description = "List of Lambda ARNs for data quality checks"
  type        = list(string)
  default     = []
}

variable "enable_monitoring" {
  description = "Enable monitoring permissions"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_arns" {
  description = "List of CloudWatch log group ARNs"
  type        = list(string)
  default     = []
}

variable "enable_backup_access" {
  description = "Enable backup access permissions"
  type        = bool
  default     = false
}

variable "backup_vault_arns" {
  description = "List of backup vault ARNs"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}