#=============================================================================
# REDSHIFT MODULE OUTPUTS - Financial Data Pipeline
#=============================================================================
#
# Outputs for Redshift cluster resources
#
#------------------------------------------------------------------------------

output "cluster_identifier" {
  description = "Identifier of the Redshift cluster"
  value       = aws_redshift_cluster.main.cluster_identifier
}

output "cluster_endpoint" {
  description = "Endpoint of the Redshift cluster"
  value       = aws_redshift_cluster.main.endpoint
}

output "cluster_port" {
  description = "Port of the Redshift cluster"
  value       = aws_redshift_cluster.main.port
}

output "cluster_database_name" {
  description = "Database name of the Redshift cluster"
  value       = aws_redshift_cluster.main.database_name
}

output "cluster_master_username" {
  description = "Master username of the Redshift cluster"
  value       = aws_redshift_cluster.main.master_username
  sensitive   = true
}

output "cluster_arn" {
  description = "ARN of the Redshift cluster"
  value       = aws_redshift_cluster.main.arn
}

output "cluster_dns_name" {
  description = "DNS name of the Redshift cluster"
  value       = aws_redshift_cluster.main.dns_name
}

output "cluster_availability_zone" {
  description = "Availability zone of the Redshift cluster"
  value       = aws_redshift_cluster.main.availability_zone
}

output "cluster_subnet_group_name" {
  description = "Name of the subnet group"
  value       = aws_redshift_cluster.main.cluster_subnet_group_name
}

output "cluster_vpc_security_group_ids" {
  description = "VPC security group IDs"
  value       = aws_redshift_cluster.main.vpc_security_group_ids
}

output "cluster_parameter_group_name" {
  description = "Name of the parameter group"
  value       = aws_redshift_cluster.main.cluster_parameter_group_name
}

output "cluster_security_groups" {
  description = "Security groups associated with the cluster"
  value       = aws_redshift_cluster.main.cluster_security_groups
}

output "cluster_version" {
  description = "Version of the Redshift cluster"
  value       = aws_redshift_cluster.main.cluster_version
}

output "cluster_nodes" {
  description = "Cluster nodes information"
  value       = aws_redshift_cluster.main.cluster_nodes
}

output "parameter_group_name" {
  description = "Name of the parameter group"
  value       = try(aws_redshift_parameter_group.main[0].name, null)
}

output "parameter_group_arn" {
  description = "ARN of the parameter group"
  value       = try(aws_redshift_parameter_group.main[0].arn, null)
}

output "subnet_group_name" {
  description = "Name of the subnet group"
  value       = try(aws_redshift_subnet_group.main[0].name, null)
}

output "subnet_group_arn" {
  description = "ARN of the subnet group"
  value       = try(aws_redshift_subnet_group.main[0].arn, null)
}

output "connection_string" {
  description = "Connection string for the Redshift cluster"
  value       = "redshift://${aws_redshift_cluster.main.master_username}:${var.master_password}@${aws_redshift_cluster.main.endpoint}/${aws_redshift_cluster.main.database_name}"
  sensitive   = true
}

output "jdbc_url" {
  description = "JDBC URL for the Redshift cluster"
  value       = "jdbc:redshift://${aws_redshift_cluster.main.endpoint}/${aws_redshift_cluster.main.database_name}"
}

output "cluster_status" {
  description = "Status of the Redshift cluster"
  value       = aws_redshift_cluster.main.cluster_status
}