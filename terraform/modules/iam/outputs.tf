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
  value       = aws_iam_role.data_lake_role.arn
}

output "data_lake_role_name" {
  description = "Name of the data lake role"
  value       = aws_iam_role.data_lake_role.name
}

# Lambda Role Outputs
output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.name
}

# Redshift Role Outputs
output "redshift_service_role_arn" {
  description = "ARN of the Redshift service role"
  value       = aws_iam_role.redshift_service_role.arn
}

output "redshift_service_role_name" {
  description = "Name of the Redshift service role"
  value       = aws_iam_role.redshift_service_role.name
}

# Glue Role Outputs
output "glue_service_role_arn" {
  description = "ARN of the Glue service role"
  value       = aws_iam_role.glue_service_role.arn
}

output "glue_service_role_name" {
  description = "Name of the Glue service role"
  value       = aws_iam_role.glue_service_role.name
}

# CloudWatch Events Role Outputs
output "cloudwatch_events_role_arn" {
  description = "ARN of the CloudWatch Events role"
  value       = aws_iam_role.cloudwatch_events_role.arn
}

output "cloudwatch_events_role_name" {
  description = "Name of the CloudWatch Events role"
  value       = aws_iam_role.cloudwatch_events_role.name
}

# API Gateway Role Outputs (conditional)
output "api_gateway_execution_role_arn" {
  description = "ARN of the API Gateway execution role"
  value       = var.create_api_gateway_role ? aws_iam_role.api_gateway_execution_role[0].arn : null
}

output "api_gateway_execution_role_name" {
  description = "Name of the API Gateway execution role"
  value       = var.create_api_gateway_role ? aws_iam_role.api_gateway_execution_role[0].name : null
}

# Cross-account Role Outputs (conditional)
output "cross_account_role_arn" {
  description = "ARN of the cross-account role"
  value       = length(var.trusted_account_ids) > 0 ? aws_iam_role.cross_account_role[0].arn : null
}

output "cross_account_role_name" {
  description = "Name of the cross-account role"
  value       = length(var.trusted_account_ids) > 0 ? aws_iam_role.cross_account_role[0].name : null
}

# All Role ARNs (for convenience)
output "all_role_arns" {
  description = "Map of all IAM role ARNs"
  value = {
    data_lake_role            = aws_iam_role.data_lake_role.arn
    lambda_execution_role     = aws_iam_role.lambda_execution_role.arn
    redshift_service_role     = aws_iam_role.redshift_service_role.arn
    glue_service_role         = aws_iam_role.glue_service_role.arn
    cloudwatch_events_role    = aws_iam_role.cloudwatch_events_role.arn
    api_gateway_execution_role = var.create_api_gateway_role ? aws_iam_role.api_gateway_execution_role[0].arn : null
    cross_account_role        = length(var.trusted_account_ids) > 0 ? aws_iam_role.cross_account_role[0].arn : null
  }
}

# All Role Names (for convenience)
output "all_role_names" {
  description = "Map of all IAM role names"
  value = {
    data_lake_role            = aws_iam_role.data_lake_role.name
    lambda_execution_role     = aws_iam_role.lambda_execution_role.name
    redshift_service_role     = aws_iam_role.redshift_service_role.name
    glue_service_role         = aws_iam_role.glue_service_role.name
    cloudwatch_events_role    = aws_iam_role.cloudwatch_events_role.name
    api_gateway_execution_role = var.create_api_gateway_role ? aws_iam_role.api_gateway_execution_role[0].name : null
    cross_account_role        = length(var.trusted_account_ids) > 0 ? aws_iam_role.cross_account_role[0].name : null
  }
}