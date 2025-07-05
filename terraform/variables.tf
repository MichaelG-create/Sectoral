# ===============================
# General Variables
# ===============================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "data-engineering-team"
}

# ===============================
# S3 Variables
# ===============================

variable "raw_data_lifecycle_days" {
  description = "Number of days to keep raw data in S3"
  type        = number
  default     = 90
}

variable "processed_data_lifecycle_days" {
  description = "Number of days to keep processed data in S3"
  type        = number
  default     = 365
}

variable "logs_lifecycle_days" {
  description = "Number of days to keep logs in S3"
  type        = number
  default     = 30
}

# ===============================
# Redshift Variables
# ===============================

variable "redshift_cluster_identifier" {
  description = "Redshift cluster identifier"
  type        = string
  default     = "financial-data-cluster"
}

variable "redshift_node_type" {
  description = "Redshift node type"
  type        = string
  default     = "dc2.large"
}

variable "redshift_number_of_nodes" {
  description = "Number of nodes in Redshift cluster"
  type        = number
  default     = 2
}

variable "redshift_database_name" {
  description = "Name of the Redshift database"
  type        = string
  default     = "financial_data"
}

variable "redshift_master_username" {
  description = "Master username for Redshift cluster"
  type        = string
  default     = "admin"
}

variable "redshift_master_password" {
  description = "Master password for Redshift cluster"
  type        = string
  sensitive   = true
}

variable "redshift_vpc_security_group_ids" {
  description = "List of VPC security group IDs for Redshift"
  type        = list(string)
  default     = []
}

variable "redshift_subnet_group_name" {
  description = "Name of the subnet group for Redshift"
  type        = string
  default     = null
}

# ===============================
# MWAA Variables
# ===============================

variable "mwaa_airflow_version" {
  description = "Airflow version for MWAA"
  type        = string
  default     = "2.7.2"
}

variable "mwaa_environment_class" {
  description = "Environment class for MWAA"
  type        = string
  default     = "mw1.small"
  validation {
    condition     = contains(["mw1.small", "mw1.medium", "mw1.large"], var.mwaa_environment_class)
    error_message = "Environment class must be one of: mw1.small, mw1.medium, mw1.large."
  }
}

variable "mwaa_dag_s3_path" {
  description = "S3 path for DAGs in MWAA"
  type        = string
  default     = "dags"
}

variable "mwaa_subnet_ids" {
  description = "List of subnet IDs for MWAA"
  type        = list(string)
  default     = []
}

variable "mwaa_security_group_ids" {
  description = "List of security group IDs for MWAA"
  type        = list(string)
  default     = []
}

variable "mwaa_airflow_configuration_options" {
  description = "Airflow configuration options for MWAA"
  type        = map(string)
  default = {
    "core.dags_are_paused_at_creation"          = "True"
    "core.load_examples"                        = "False"
    "webserver.expose_config"                   = "True"
    "scheduler.dag_dir_list_interval"           = "300"
    "scheduler.catchup_by_default"              = "False"
    "scheduler.max_threads"                     = "2"
    "celery.worker_concurrency"                 = "2"
    "logging.logging_level"                     = "INFO"
    "logging.remote_logging"                    = "True"
    "logging.remote_base_log_folder"           = "s3://BUCKET_NAME/logs"
    "logging.remote_log_conn_id"               = "aws_default"
  }
}

# ===============================
# Network Variables
# ===============================

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
  default     = null
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
  default     = []
}

# ===============================
# Monitoring Variables
# ===============================

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "notification_email" {
  description = "Email address for notifications"
  type        = string
  default     = ""
}

# ===============================
# Cost Optimization Variables
# ===============================

variable "enable_cost_optimization" {
  description = "Enable cost optimization features"
  type        = bool
  default     = true
}

variable "redshift_pause_cluster" {
  description = "Pause Redshift cluster when not in use (dev/staging only)"
  type        = bool
  default     = false
}

# ===============================
# Backup and Recovery Variables
# ===============================

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "enable_automated_backups" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

# ===============================
# Data Sources Configuration
# ===============================

variable "alpha_vantage_api_key" {
  description = "Alpha Vantage API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "fred_api_key" {
  description = "FRED API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "data_sources_enabled" {
  description = "Map of data sources to enable"
  type        = map(bool)
  default = {
    alpha_vantage = true
    yahoo_finance = true
    fred          = true
  }
}