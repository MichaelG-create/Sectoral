# =============================================================================
# OUTPUTS TERRAFORM - Financial Data Pipeline
# =============================================================================

# -----------------------------------------------------------------------------
# S3 Bucket Outputs
# -----------------------------------------------------------------------------

output "s3_raw_bucket_name" {
  description = "Name of the S3 bucket for raw data"
  value       = module.s3.raw_bucket_name
}

output "s3_raw_bucket_arn" {
  description = "ARN of the S3 bucket for raw data"
  value       = module.s3.raw_bucket_arn
}

output "s3_processed_bucket_name" {
  description = "Name of the S3 bucket for processed data"
  value       = module.s3.processed_bucket_name
}

output "s3_processed_bucket_arn" {
  description = "ARN of the S3 bucket for processed data"
  value       = module.s3.processed_bucket_arn
}

output "s3_logs_bucket_name" {
  description = "Name of the S3 bucket for logs"
  value       = module.s3.logs_bucket_name
}

output "s3_logs_bucket_arn" {
  description = "ARN of the S3 bucket for logs"
  value       = module.s3.logs_bucket_arn
}

# -----------------------------------------------------------------------------
# Redshift Outputs
# -----------------------------------------------------------------------------

output "redshift_cluster_identifier" {
  description = "Redshift cluster identifier"
  value       = module.redshift.cluster_identifier
}

output "redshift_cluster_endpoint" {
  description = "Redshift cluster endpoint"
  value       = module.redshift.cluster_endpoint
  sensitive   = true
}

output "redshift_cluster_port" {
  description = "Redshift cluster port"
  value       = module.redshift.cluster_port
}

output "redshift_database_name" {
  description = "Redshift database name"
  value       = module.redshift.database_name
}

output "redshift_master_username" {
  description = "Redshift master username"
  value       = module.redshift.master_username
  sensitive   = true
}

# -----------------------------------------------------------------------------
# MWAA (Airflow) Outputs
# -----------------------------------------------------------------------------

output "mwaa_environment_name" {
  description = "MWAA environment name"
  value       = module.mwaa.environment_name
}

output "mwaa_environment_arn" {
  description = "MWAA environment ARN"
  value       = module.mwaa.environment_arn
}

output "mwaa_webserver_url" {
  description = "MWAA webserver URL"
  value       = module.mwaa.webserver_url
  sensitive   = true
}

output "mwaa_dag_s3_bucket" {
  description = "S3 bucket for MWAA DAGs"
  value       = module.mwaa.dag_s3_bucket
}

# -----------------------------------------------------------------------------
# IAM Outputs
# -----------------------------------------------------------------------------

output "airflow_execution_role_arn" {
  description = "ARN of Airflow execution role"
  value       = module.iam.airflow_execution_role_arn
}

output "redshift_service_role_arn" {
  description = "ARN of Redshift service role"
  value       = module.iam.redshift_service_role_arn
}

output "lambda_execution_role_arn" {
  description = "ARN of Lambda execution role"
  value       = module.iam.lambda_execution_role_arn
}

# -----------------------------------------------------------------------------
# VPC Outputs (if using custom VPC)
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

# -----------------------------------------------------------------------------
# Security Group Outputs
# -----------------------------------------------------------------------------

output "redshift_security_group_id" {
  description = "Security group ID for Redshift"
  value       = module.redshift.security_group_id
}

output "mwaa_security_group_id" {
  description = "Security group ID for MWAA"
  value       = module.mwaa.security_group_id
}

# -----------------------------------------------------------------------------
# Monitoring Outputs
# -----------------------------------------------------------------------------

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  value       = "/aws/mwaa/${var.project_name}-${var.environment}"
}

output "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  value       = aws_sns_topic.pipeline_notifications.arn
}

# -----------------------------------------------------------------------------
# Environment Information
# -----------------------------------------------------------------------------

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

# -----------------------------------------------------------------------------
# Connection Strings (for applications)
# -----------------------------------------------------------------------------

output "redshift_connection_string" {
  description = "Redshift connection string for applications"
  value       = "redshift://${module.redshift.master_username}:${var.redshift_master_password}@${module.redshift.cluster_endpoint}:${module.redshift.cluster_port}/${module.redshift.database_name}"
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Data Quality Monitoring
# -----------------------------------------------------------------------------

output "data_quality_lambda_function_name" {
  description = "Data quality monitoring Lambda function name"
  value       = "data-quality-monitor-${var.environment}"
}

output "cost_anomaly_detector_arn" {
  description = "Cost anomaly detector ARN"
  value       = aws_ce_anomaly_detector.pipeline_costs.arn
}