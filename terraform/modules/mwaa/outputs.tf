#=============================================================================
# Cloud Composer MODULE OUTPUTS - Financial Data Pipeline
#=============================================================================
#
# Outputs for Cloud Composer (Managed Airflow) resources
#
#------------------------------------------------------------------------------

output "cloudcomposer_environment_name" {
  description = "Name of the Cloud Composer environment"
  value       = gcp_cloudcomposer_environment.main.name
}

output "cloudcomposer_environment_arn" {
  description = "ARN of the Cloud Composer environment"
  value       = gcp_cloudcomposer_environment.main.arn
}

output "cloudcomposer_webserver_url" {
  description = "Webserver URL of the Cloud Composer environment"
  value       = gcp_cloudcomposer_environment.main.webserver_url
}

output "cloudcomposer_environment_status" {
  description = "Status of the Cloud Composer environment"
  value       = gcp_cloudcomposer_environment.main.status
}

output "cloudcomposer_service_role_arn" {
  description = "Service role ARN of the Cloud Composer environment"
  value       = gcp_cloudcomposer_environment.main.service_role_arn
}

output "cloudcomposer_execution_role_arn" {
  description = "Execution role ARN for Cloud Composer"
  value       = gcp_iam_role.cloudcomposer_execution_role.arn
}

output "cloudcomposer_execution_role_name" {
  description = "Name of the execution role"
  value       = gcp_iam_role.cloudcomposer_execution_role.name
}

output "cloudcomposer_source_bucket_name" {
  description = "Name of the GCS source bucket"
  value       = gcs_bucket.cloudcomposer_source.id
}

output "cloudcomposer_source_bucket_arn" {
  description = "ARN of the GCS source bucket"
  value       = gcs_bucket.cloudcomposer_source.arn
}

output "cloudcomposer_security_group_id" {
  description = "Security group ID for Cloud Composer"
  value       = gcp_security_group.cloudcomposer.id
}

output "cloudcomposer_security_group_arn" {
  description = "Security group ARN for Cloud Composer"
  value       = gcp_security_group.cloudcomposer.arn
}

output "cloudcomposer_environment_class" {
  description = "Environment class of the Cloud Composer environment"
  value       = gcp_cloudcomposer_environment.main.environment_class
}

output "cloudcomposer_airflow_version" {
  description = "Airflow version of the Cloud Composer environment"
  value       = gcp_cloudcomposer_environment.main.airflow_version
}

output "cloudcomposer_created_at" {
  description = "Creation timestamp of the Cloud Composer environment"
  value       = gcp_cloudcomposer_environment.main.created_at
}

output "cloudcomposer_last_updated" {
  description = "Last update timestamp of the Cloud Composer environment"
  value       = gcp_cloudcomposer_environment.main.last_updated
}
