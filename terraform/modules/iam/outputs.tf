#=============================================================================
# IAM MODULE OUTPUTS - Financial Data Pipeline
#=============================================================================
#
# Outputs for IAM roles and policies
#
#------------------------------------------------------------------------------

# Data Lake Role Outputs
output "data_lake_role_arn" {
  description = "ARN of the data lake role"
  value       = gcp_iam_role.data_lake_role.arn
}

output "data_lake_role_name" {
  description = "Name of the data lake role"
  value       = gcp_iam_role.data_lake_role.name
}

# Lambda Role Outputs
output "cloudfunctions_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = gcp_iam_role.cloudfunctions_execution_role.arn
}

output "cloudfunctions_execution_role_name" {
  description = "Name of the Lambda execution role"
  value       = gcp_iam_role.cloudfunctions_execution_role.name
}

# BigQuery Role Outputs
output "bigquery_service_role_arn" {
  description = "ARN of the BigQuery service role"
  value       = gcp_iam_role.bigquery_service_role.arn
}

output "bigquery_service_role_name" {
  description = "Name of the BigQuery service role"
  value       = gcp_iam_role.bigquery_service_role.name
}

# Glue Role Outputs
output "dataflow_service_role_arn" {
  description = "ARN of the Glue service role"
  value       = gcp_iam_role.dataflow_service_role.arn
}

output "dataflow_service_role_name" {
  description = "Name of the Glue service role"
  value       = gcp_iam_role.dataflow_service_role.name
}

# CloudWatch Events Role Outputs
output "cloudwatch_events_role_arn" {
  description = "ARN of the CloudWatch Events role"
  value       = gcp_iam_role.cloudwatch_events_role.arn
}

output "cloudwatch_events_role_name" {
  description = "Name of the CloudWatch Events role"
  value       = gcp_iam_role.cloudwatch_events_role.name
}

# API Gateway Role Outputs (conditional)
output "api_gateway_execution_role_arn" {
  description = "ARN of the API Gateway execution role"
  value       = var.create_api_gateway_role ? gcp_iam_role.api_gateway_execution_role[0].arn : null
}

output "api_gateway_execution_role_name" {
  description = "Name of the API Gateway execution role"
  value       = var.create_api_gateway_role ? gcp_iam_role.api_gateway_execution_role[0].name : null
}

# Cross-account Role Outputs (conditional)
output "cross_account_role_arn" {
  description = "ARN of the cross-account role"
  value       = length(var.trusted_account_ids) > 0 ? gcp_iam_role.cross_account_role[0].arn : null
}

output "cross_account_role_name" {
  description = "Name of the cross-account role"
  value       = length(var.trusted_account_ids) > 0 ? gcp_iam_role.cross_account_role[0].name : null
}

# All Role ARNs (for convenience)
output "all_role_arns" {
  description = "Map of all IAM role ARNs"
  value = {
    data_lake_role            = gcp_iam_role.data_lake_role.arn
    cloudfunctions_execution_role     = gcp_iam_role.cloudfunctions_execution_role.arn
    bigquery_service_role     = gcp_iam_role.bigquery_service_role.arn
    dataflow_service_role         = gcp_iam_role.dataflow_service_role.arn
    cloudwatch_events_role    = gcp_iam_role.cloudwatch_events_role.arn
    api_gateway_execution_role = var.create_api_gateway_role ? gcp_iam_role.api_gateway_execution_role[0].arn : null
    cross_account_role        = length(var.trusted_account_ids) > 0 ? gcp_iam_role.cross_account_role[0].arn : null
  }
}

# All Role Names (for convenience)
output "all_role_names" {
  description = "Map of all IAM role names"
  value = {
    data_lake_role            = gcp_iam_role.data_lake_role.name
    cloudfunctions_execution_role     = gcp_iam_role.cloudfunctions_execution_role.name
    bigquery_service_role     = gcp_iam_role.bigquery_service_role.name
    dataflow_service_role         = gcp_iam_role.dataflow_service_role.name
    cloudwatch_events_role    = gcp_iam_role.cloudwatch_events_role.name
    api_gateway_execution_role = var.create_api_gateway_role ? gcp_iam_role.api_gateway_execution_role[0].name : null
    cross_account_role        = length(var.trusted_account_ids) > 0 ? gcp_iam_role.cross_account_role[0].name : null
  }
}
