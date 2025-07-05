#=============================================================================
# MWAA MODULE VARIABLES - Financial Data Pipeline
#=============================================================================
#
# Variables for MWAA (Managed Airflow) configuration
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

variable "environment_name" {
  description = "MWAA environment name"
  type        = string
  default     = null
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where MWAA will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for MWAA"
  type        = list(string)
}

variable "airflow_version" {
  description = "Airflow version"
  type        = string
  default     = "2.8.1"
  validation {
    condition = contains([
      "2.8.1", "2.7.2", "2.6.3", "2.5.1", "2.4.3"
    ], var.airflow_version)
    error_message = "Airflow version must be supported by MWAA."
  }
}

variable "environment_class" {
  description = "Environment class for MWAA"
  type        = string
  default     = "mw1.small"
  validation {
    condition = contains([
      "mw1.small", "mw1.medium", "mw1.large", "mw1.xlarge", "mw1.2xlarge"
    ], var.environment_class)
    error_message = "Environment class must be a valid MWAA environment class."
  }
}

variable "max_workers" {
  description = "Maximum number of workers"
  type        = number
  default     = 10
  validation {
    condition     = var.max_workers >= 1 && var.max_workers <= 25
    error_message = "Max workers must be between 1 and 25."
  }
}

variable "min_workers" {
  description = "Minimum number of workers"
  type        = number
  default     = 1
  validation {
    condition     = var.min_workers >= 1 && var.min_workers <= 25
    error_message = "Min workers must be between 1 and 25."
  }
}

variable "webserver_access_mode" {
  description = "Webserver access mode"
  type        = string
  default     = "PRIVATE_ONLY"
  validation {
    condition     = contains(["PRIVATE_ONLY", "PUBLIC_ONLY"], var.webserver_access_mode)
    error_message = "Webserver access mode must be PRIVATE_ONLY or PUBLIC_ONLY."
  }
}

variable "weekly_maintenance_window_start" {
  description = "Weekly maintenance window start time"
  type        = string
  default     = "SUN:03:00"
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = null
}

variable "requirements_file_path" {
  description = "Path to requirements.txt file"
  type        = string
  default     = "../airflow/config/requirements.txt"
}

variable "dags_folder_path" {
  description = "Path to DAGs folder"
  type        = string
  default     = "../airflow/dags"
}

variable "plugins_folder_path" {
  description = "Path to plugins folder"
  type        = string
  default     = "../airflow/plugins"
}

variable "data_bucket_arns" {
  description = "List of S3 bucket ARNs for data access"
  type        = list(string)
  default     = []
}

variable "redshift_cluster_arn" {
  description = "ARN of the Redshift cluster"
  type        = string
  default     = "*"
}

variable "airflow_configuration_options" {
  description = "Airflow configuration options"
  type        = map(string)
  default = {
    "core.load_default_connections" = "False"
    "core.load_examples"           = "False"
    "webserver.expose_config"      = "True"
    "scheduler.catchup_by_default" = "False"
    "scheduler.max_threads"        = "2"
    "celery.worker_concurrency"    = "16"
  }
}

# Logging configuration
variable "dag_processing_logs_enabled" {
  description = "Enable DAG processing logs"
  type        = bool
  default     = true
}

variable "dag_processing_logs_level" {
  description = "Log level for DAG processing"
  type        = string
  default     = "INFO"
  validation {
    condition     = contains(["CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG"], var.dag_processing_logs_level)
    error_message = "Log level must be one of: CRITICAL, ERROR, WARNING, INFO, DEBUG."
  }
}

variable "scheduler_logs_enabled" {
  description = "Enable scheduler logs"
  type        = bool
  default     = true
}

variable "scheduler_logs_level" {
  description = "Log level for scheduler"
  type        = string
  default     = "INFO"
  validation {
    condition     = contains(["CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG"], var.scheduler_logs_level)
    error_message = "Log level must be one of: CRITICAL, ERROR, WARNING, INFO, DEBUG."
  }
}

variable "task_logs_enabled" {
  description = "Enable task logs"
  type        = bool
  default     = true
}

variable "task_logs_level" {
  description = "Log level for tasks"
  type        = string
  default     = "INFO"
  validation {
    condition     = contains(["CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG"], var.task_logs_level)
    error_message = "Log level must be one of: CRITICAL, ERROR, WARNING, INFO, DEBUG."
  }
}

variable "webserver_logs_enabled" {
  description = "Enable webserver logs"
  type        = bool
  default     = true
}

variable "webserver_logs_level" {
  description = "Log level for webserver"
  type        = string
  default     = "INFO"
  validation {
    condition     = contains(["CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG"], var.webserver_logs_level)
    error_message = "Log level must be one of: CRITICAL, ERROR, WARNING, INFO, DEBUG."
  }
}

variable "worker_logs_enabled" {
  description = "Enable worker logs"
  type        = bool
  default     = true
}

variable "worker_logs_level" {
  description = "Log level for workers"
  type        = string
  default     = "INFO"
  validation {
    condition     = contains(["CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG"], var.worker_logs_level)
    error_message = "Log level must be one of: CRITICAL, ERROR, WARNING, INFO, DEBUG."
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}