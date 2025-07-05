# =============================================================================
# S3 MODULE VARIABLES - Financial Data Pipeline
# =============================================================================

# -----------------------------------------------------------------------------
# General Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# S3 Bucket Names
# -----------------------------------------------------------------------------

variable "raw_bucket_name" {
  description = "Name of the S3 bucket for raw data"
  type        = string
}

variable "processed_bucket_name" {
  description = "Name of the S3 bucket for processed data"
  type        = string
}

variable "logs_bucket_name" {
  description = "Name of the S3 bucket for logs"
  type        = string
}

variable "dags_bucket_name" {
  description = "Name of the S3 bucket for Airflow DAGs"
  type        = string
}

# -----------------------------------------------------------------------------
# Lifecycle Configuration
# -----------------------------------------------------------------------------

variable "raw_data_expiration_days" {
  description = "Number of days after which raw data expires"
  type        = number
  default     = 365
}

variable "processed_data_expiration_days" {
  description = "Number of days after which processed data expires"
  type        = number
  default     = 1095
}

variable "logs_expiration_days" {
  description = "Number of days after which logs expire"
  type        = number
  default     = 90
}

# -----------------------------------------------------------------------------
# Lambda Function Integration
# -----------------------------------------------------------------------------

variable "data_processing_lambda_arn" {
  description = "ARN of the Lambda function for data processing"
  type        = string
  default     = ""
}

variable "data_validation_lambda_arn" {
  description = "ARN of the Lambda function for data validation"
  type        = string
  default     = ""
}

variable "data_processing_lambda_function_name" {
  description = "Name of the Lambda function for data processing"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# IAM Role ARNs
# -----------------------------------------------------------------------------

variable "airflow_execution_role_arn" {
  description = "ARN of the Airflow execution role"
  type        = string
}

variable "redshift_service_role_arn" {
  description = "ARN of the Redshift service role"
  type        = string
}

# -----------------------------------------------------------------------------
# SNS Topic
# -----------------------------------------------------------------------------

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  type        = string
}

# -----------------------------------------------------------------------------
# Encryption Configuration
# -----------------------------------------------------------------------------

variable "kms_key_id" {
  description = "KMS key ID for S3 encryption"
  type        = string
  default     = ""
}

variable "enable_kms_encryption" {
  description = "Enable KMS encryption for S3 buckets"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Access Control Configuration
# -----------------------------------------------------------------------------

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access S3 buckets"
  type        = list(string)
  default     = []
}

variable "cross_region_replication" {
  description = "Enable cross-region replication"
  type        = bool
  default     = false
}

variable "replication_destination_bucket" {
  description = "Destination bucket for cross-region replication"
  type        = string
  default     = ""
}

variable "replication_destination_region" {
  description = "Destination region for cross-region replication"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Monitoring Configuration
# -----------------------------------------------------------------------------

variable "enable_cloudwatch_metrics" {
  description = "Enable CloudWatch metrics for S3 buckets"
  type        = bool
  default     = true
}

variable "enable_inventory" {
  description = "Enable S3 inventory for buckets"
  type        = bool
  default     = true
}

variable "enable_access_logging" {
  description = "Enable S3 access logging"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Data Partitioning Configuration
# -----------------------------------------------------------------------------

variable "enable_data_partitioning" {
  description = "Enable automatic data partitioning by date"
  type        = bool
  default     = true
}

variable "partition_format" {
  description = "Format for data partitioning (year/month/day)"
  type        = string
  default     = "year=%Y/month=%m/day=%d"
}

# -----------------------------------------------------------------------------
# Cost Optimization
# -----------------------------------------------------------------------------

variable "enable_intelligent_tiering" {
  description = "Enable S3 Intelligent Tiering"
  type        = bool
  default     = true
}

variable "multipart_upload_threshold" {
  description = "Threshold for multipart uploads (in MB)"
  type        = number
  default     = 64
}

# -----------------------------------------------------------------------------
# Data Quality Configuration
# -----------------------------------------------------------------------------

variable "enable_data_validation" {
  description = "Enable automatic data validation on upload"
  type        = bool
  default     = true
}

variable "max_file_size_mb" {
  description = "Maximum file size allowed (in MB)"
  type        = number
  default     = 1000
}

variable "allowed_file_extensions" {
  description = "List of allowed file extensions"
  type        = list(string)
  default     = [".json", ".csv", ".parquet", ".avro"]
}