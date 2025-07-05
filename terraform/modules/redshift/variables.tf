#=============================================================================
# REDSHIFT MODULE VARIABLES - Financial Data Pipeline
#=============================================================================
#
# Variables for Redshift cluster configuration
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

variable "cluster_identifier" {
  description = "Unique identifier for the Redshift cluster"
  type        = string
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "financial_data"
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
  default     = "admin"
}

variable "master_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "node_type" {
  description = "Type of node to use for the cluster"
  type        = string
  default     = "dc2.large"
  validation {
    condition = contains([
      "dc2.large", "dc2.8xlarge", "ds2.xlarge", "ds2.8xlarge",
      "ra3.xlplus", "ra3.4xlarge", "ra3.16xlarge"
    ], var.node_type)
    error_message = "Node type must be a valid Redshift node type."
  }
}

variable "cluster_type" {
  description = "Type of cluster (single-node or multi-node)"
  type        = string
  default     = "single-node"
  validation {
    condition     = contains(["single-node", "multi-node"], var.cluster_type)
    error_message = "Cluster type must be either 'single-node' or 'multi-node'."
  }
}

variable "number_of_nodes" {
  description = "Number of nodes in the cluster (for multi-node clusters)"
  type        = number
  default     = 1
}

variable "port" {
  description = "Port for the Redshift cluster"
  type        = number
  default     = 5439
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs"
  type        = list(string)
  default     = []
}

variable "cluster_subnet_group_name" {
  description = "Name of the subnet group for the cluster"
  type        = string
  default     = null
}

variable "publicly_accessible" {
  description = "Whether the cluster is publicly accessible"
  type        = bool
  default     = false
}

variable "encrypted" {
  description = "Whether the cluster is encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = null
}

variable "enhanced_vpc_routing" {
  description = "Enable enhanced VPC routing"
  type        = bool
  default     = true
}

variable "automated_snapshot_retention_period" {
  description = "Number of days to retain automated snapshots"
  type        = number
  default     = 7
}

variable "preferred_maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying cluster"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Identifier for final snapshot"
  type        = string
  default     = null
}

variable "parameter_group_name" {
  description = "Name of the parameter group"
  type        = string
  default     = null
}

variable "allow_version_upgrade" {
  description = "Allow version upgrade"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "logging_enabled" {
  description = "Enable logging to S3"
  type        = bool
  default     = true
}

variable "logging_bucket_name" {
  description = "S3 bucket name for logging"
  type        = string
  default     = null
}

variable "logging_s3_key_prefix" {
  description = "S3 key prefix for logs"
  type        = string
  default     = "redshift-logs/"
}

variable "snapshot_copy_enabled" {
  description = "Enable snapshot copy to another region"
  type        = bool
  default     = false
}

variable "snapshot_copy_destination_region" {
  description = "Destination region for snapshot copy"
  type        = string
  default     = null
}

variable "snapshot_copy_retention_period" {
  description = "Retention period for copied snapshots"
  type        = number
  default     = 7
}

variable "elastic_ip" {
  description = "Elastic IP for the cluster"
  type        = string
  default     = null
}