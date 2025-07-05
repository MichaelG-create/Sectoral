#=============================================================================
# MWAA MODULE OUTPUTS - Financial Data Pipeline
#=============================================================================
#
# Outputs for MWAA (Managed Airflow) resources
#
#------------------------------------------------------------------------------

output "mwaa_environment_name" {
  description = "Name of the MWAA environment"
  value       = aws_mwaa_environment.main.name
}

output "mwaa_environment_arn" {
  description = "ARN of the MWAA environment"
  value       = aws_mwaa_environment.main.arn
}

output "mwaa_webserver_url" {
  description = "Webserver URL of the MWAA environment"
  value       = aws_mwaa_environment.main.webserver_url
}

output "mwaa_environment_status" {
  description = "Status of the MWAA environment"
  value       = aws_mwaa_environment.main.status
}

output "mwaa_service_role_arn" {
  description = "Service role ARN of the MWAA environment"
  value       = aws_mwaa_environment.main.service_role_arn
}

output "mwaa_execution_role_arn" {
  description = "Execution role ARN for MWAA"
  value       = aws_iam_role.mwaa_execution_role.arn
}

output "mwaa_execution_role_name" {
  description = "Name of the execution role"
  value       = aws_iam_role.mwaa_execution_role.name
}

output "mwaa_source_bucket_name" {
  description = "Name of the S3 source bucket"
  value       = aws_s3_bucket.mwaa_source.id
}

output "mwaa_source_bucket_arn" {
  description = "ARN of the S3 source bucket"
  value       = aws_s3_bucket.mwaa_source.arn
}

output "mwaa_security_group_id" {
  description = "Security group ID for MWAA"
  value       = aws_security_group.mwaa.id
}

output "mwaa_security_group_arn" {
  description = "Security group ARN for MWAA"
  value       = aws_security_group.mwaa.arn
}

output "mwaa_environment_class" {
  description = "Environment class of the MWAA environment"
  value       = aws_mwaa_environment.main.environment_class
}

output "mwaa_airflow_version" {
  description = "Airflow version of the MWAA environment"
  value       = aws_mwaa_environment.main.airflow_version
}

output "mwaa_created_at" {
  description = "Creation timestamp of the MWAA environment"
  value       = aws_mwaa_environment.main.created_at
}

output "mwaa_last_updated" {
  description = "Last update timestamp of the MWAA environment"
  value       = aws_mwaa_environment.main.last_updated
}