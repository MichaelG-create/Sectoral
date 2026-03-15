# =============================================================================
# OUTPUTS TERRAFORM - Financial Data Pipeline
# =============================================================================

# -----------------------------------------------------------------------------
# GCS Bucket Outputs
# -----------------------------------------------------------------------------

output "gcs_raw_bucket_name" {
  description = "Name of the GCS bucket for raw data"
  value       = module.gcp.raw_bucket_name
}

output "gcs_raw_bucket_arn" {
  description = "ARN of the GCS bucket for raw data"
  value       = module.gcp.raw_bucket_arn
}

output "gcs_processed_bucket_name" {
  description = "Name of the GCS bucket for processed data"
  value       = module.gcp.processed_bucket_name
}

output "gcs_processed_bucket_arn" {
  description = "ARN of the GCS bucket for processed data"
  value       = module.gcp.processed_bucket_arn
}

output "gcs_logs_bucket_name" {
  description = "Name of the GCS bucket for logs"
  value       = module.gcp.logs_bucket_name
}

output "gcs_logs_bucket_arn" {
  description = "ARN of the GCS bucket for logs"
  value       = module.gcp.logs_bucket_arn
}

# -----------------------------------------------------------------------------
# BigQuery Outputs
# -----------------------------------------------------------------------------

output "bigquery_cluster_identifier" {
  description = "BigQuery cluster identifier"
  value       = module.bigquery.cluster_identifier
}

output "bigquery_cluster_endpoint" {
  description = "BigQuery cluster endpoint"
  value       = module.bigquery.cluster_endpoint
  sensitive   = true
}

output "bigquery_cluster_port" {
  description = "BigQuery cluster port"
  value       = module.bigquery.cluster_port
}

output "bigquery_database_name" {
  description = "BigQuery database name"
  value       = module.bigquery.database_name
}

output "bigquery_master_username" {
  description = "BigQuery master username"
  value       = module.bigquery.master_username
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Cloud Composer (Airflow) Outputs
# -----------------------------------------------------------------------------

output "cloudcomposer_environment_name" {
  description = "Cloud Composer environment name"
  value       = module.cloudcomposer.environment_name
}

output "cloudcomposer_environment_arn" {
  description = "Cloud Composer environment ARN"
  value       = module.cloudcomposer.environment_arn
}

output "cloudcomposer_webserver_url" {
  description = "Cloud Composer webserver URL"
  value       = module.cloudcomposer.webserver_url
  sensitive   = true
}

output "cloudcomposer_dag_gcs_bucket" {
  description = "GCS bucket for Cloud Composer DAGs"
  value       = module.cloudcomposer.dag_gcs_bucket
}

# -----------------------------------------------------------------------------
# IAM Outputs
# -----------------------------------------------------------------------------

output "airflow_execution_role_arn" {
  description = "ARN of Airflow execution role"
  value       = module.iam.airflow_execution_role_arn
}

output "bigquery_service_role_arn" {
  description = "ARN of BigQuery service role"
  value       = module.iam.bigquery_service_role_arn
}

output "cloudfunctions_execution_role_arn" {
  description = "ARN of Lambda execution role"
  value       = module.iam.cloudfunctions_execution_role_arn
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

output "bigquery_security_group_id" {
  description = "Security group ID for BigQuery"
  value       = module.bigquery.security_group_id
}

output "cloudcomposer_security_group_id" {
  description = "Security group ID for Cloud Composer"
  value       = module.cloudcomposer.security_group_id
}

# -----------------------------------------------------------------------------
# Monitoring Outputs
# -----------------------------------------------------------------------------

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  value       = "/gcp/cloudcomposer/${var.project_name}-${var.environment}"
}

output "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  value       = gcp_sns_topic.pipeline_notifications.arn
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
  description = "GCP region"
  value       = var.gcp_region
}

# -----------------------------------------------------------------------------
# Connection Strings (for applications)
# -----------------------------------------------------------------------------

output "bigquery_connection_string" {
  description = "BigQuery connection string for applications"
  value       = "bigquery://${module.bigquery.master_username}:${var.bigquery_master_password}@${module.bigquery.cluster_endpoint}:${module.bigquery.cluster_port}/${module.bigquery.database_name}"
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Data Quality Monitoring
# -----------------------------------------------------------------------------

output "data_quality_cloudfunctions_function_name" {
  description = "Data quality monitoring Lambda function name"
  value       = "data-quality-monitor-${var.environment}"
}

output "cost_anomaly_detector_arn" {
  description = "Cost anomaly detector ARN"
  value       = gcp_ce_anomaly_detector.pipeline_costs.arn
}
