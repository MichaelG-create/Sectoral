#=============================================================================
# BIGQUERY MODULE OUTPUTS - Financial Data Pipeline
#=============================================================================
#
# Outputs for BigQuery cluster resources
#
#------------------------------------------------------------------------------

output "cluster_identifier" {
  description = "Identifier of the BigQuery cluster"
  value       = gcp_bigquery_cluster.main.cluster_identifier
}

output "cluster_endpoint" {
  description = "Endpoint of the BigQuery cluster"
  value       = gcp_bigquery_cluster.main.endpoint
}

output "cluster_port" {
  description = "Port of the BigQuery cluster"
  value       = gcp_bigquery_cluster.main.port
}

output "cluster_database_name" {
  description = "Database name of the BigQuery cluster"
  value       = gcp_bigquery_cluster.main.database_name
}

output "cluster_master_username" {
  description = "Master username of the BigQuery cluster"
  value       = gcp_bigquery_cluster.main.master_username
  sensitive   = true
}

output "cluster_arn" {
  description = "ARN of the BigQuery cluster"
  value       = gcp_bigquery_cluster.main.arn
}

output "cluster_dns_name" {
  description = "DNS name of the BigQuery cluster"
  value       = gcp_bigquery_cluster.main.dns_name
}

output "cluster_availability_zone" {
  description = "Availability zone of the BigQuery cluster"
  value       = gcp_bigquery_cluster.main.availability_zone
}

output "cluster_subnet_group_name" {
  description = "Name of the subnet group"
  value       = gcp_bigquery_cluster.main.cluster_subnet_group_name
}

output "cluster_vpc_security_group_ids" {
  description = "VPC security group IDs"
  value       = gcp_bigquery_cluster.main.vpc_security_group_ids
}

output "cluster_parameter_group_name" {
  description = "Name of the parameter group"
  value       = gcp_bigquery_cluster.main.cluster_parameter_group_name
}

output "cluster_security_groups" {
  description = "Security groups associated with the cluster"
  value       = gcp_bigquery_cluster.main.cluster_security_groups
}

output "cluster_version" {
  description = "Version of the BigQuery cluster"
  value       = gcp_bigquery_cluster.main.cluster_version
}

output "cluster_nodes" {
  description = "Cluster nodes information"
  value       = gcp_bigquery_cluster.main.cluster_nodes
}

output "parameter_group_name" {
  description = "Name of the parameter group"
  value       = try(gcp_bigquery_parameter_group.main[0].name, null)
}

output "parameter_group_arn" {
  description = "ARN of the parameter group"
  value       = try(gcp_bigquery_parameter_group.main[0].arn, null)
}

output "subnet_group_name" {
  description = "Name of the subnet group"
  value       = try(gcp_bigquery_subnet_group.main[0].name, null)
}

output "subnet_group_arn" {
  description = "ARN of the subnet group"
  value       = try(gcp_bigquery_subnet_group.main[0].arn, null)
}

output "connection_string" {
  description = "Connection string for the BigQuery cluster"
  value       = "bigquery://${gcp_bigquery_cluster.main.master_username}:${var.master_password}@${gcp_bigquery_cluster.main.endpoint}/${gcp_bigquery_cluster.main.database_name}"
  sensitive   = true
}

output "jdbc_url" {
  description = "JDBC URL for the BigQuery cluster"
  value       = "jdbc:bigquery://${gcp_bigquery_cluster.main.endpoint}/${gcp_bigquery_cluster.main.database_name}"
}

output "cluster_status" {
  description = "Status of the BigQuery cluster"
  value       = gcp_bigquery_cluster.main.cluster_status
}
