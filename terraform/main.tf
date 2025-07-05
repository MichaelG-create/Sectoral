# ===============================
# Financial Data Pipeline - Main Terraform Configuration
# ===============================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    # Configuration will be provided via backend config file
    # bucket = "your-terraform-state-bucket"
    # key    = "financial-pipeline/terraform.tfstate"
    # region = "us-east-1"
  }
}

# ===============================
# Local Variables
# ===============================

locals {
  project_name = "financial-data-pipeline"
  environment  = var.environment
  
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

# ===============================
# Data Sources
# ===============================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ===============================
# IAM Module
# ===============================

module "iam" {
  source = "./modules/iam"
  
  project_name = local.project_name
  environment  = local.environment
  
  s3_bucket_names = [
    module.s3.raw_data_bucket_name,
    module.s3.processed_data_bucket_name,
    module.s3.logs_bucket_name
  ]
  
  redshift_cluster_identifier = module.redshift.cluster_identifier
  
  tags = local.common_tags
}

# ===============================
# S3 Module
# ===============================

module "s3" {
  source = "./modules/s3"
  
  project_name = local.project_name
  environment  = local.environment
  
  # Lifecycle configuration
  raw_data_lifecycle_days    = var.raw_data_lifecycle_days
  processed_data_lifecycle_days = var.processed_data_lifecycle_days
  logs_lifecycle_days        = var.logs_lifecycle_days
  
  tags = local.common_tags
}

# ===============================
# Redshift Module
# ===============================

module "redshift" {
  source = "./modules/redshift"
  
  project_name = local.project_name
  environment  = local.environment
  
  # Cluster configuration
  cluster_identifier      = var.redshift_cluster_identifier
  node_type              = var.redshift_node_type
  number_of_nodes        = var.redshift_number_of_nodes
  database_name          = var.redshift_database_name
  master_username        = var.redshift_master_username
  master_password        = var.redshift_master_password
  
  # Security
  vpc_security_group_ids = var.redshift_vpc_security_group_ids
  subnet_group_name      = var.redshift_subnet_group_name
  
  # IAM
  iam_role_arn = module.iam.redshift_service_role_arn
  
  tags = local.common_tags
}

# ===============================
# MWAA (Managed Airflow) Module
# ===============================

module "mwaa" {
  source = "./modules/mwaa"
  
  project_name = local.project_name
  environment  = local.environment
  
  # MWAA configuration
  airflow_version = var.mwaa_airflow_version
  environment_class = var.mwaa_environment_class
  
  # S3 configuration
  source_bucket_arn = module.s3.airflow_bucket_arn
  dag_s3_path       = var.mwaa_dag_s3_path
  
  # Network configuration
  subnet_ids         = var.mwaa_subnet_ids
  security_group_ids = var.mwaa_security_group_ids
  
  # IAM
  execution_role_arn = module.iam.mwaa_execution_role_arn
  
  # Airflow configuration
  airflow_configuration_options = var.mwaa_airflow_configuration_options
  
  tags = local.common_tags
}

# ===============================
# CloudWatch Dashboards and Alarms
# ===============================

resource "aws_cloudwatch_dashboard" "pipeline_dashboard" {
  dashboard_name = "${local.project_name}-${local.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/S3", "BucketSizeBytes", "BucketName", module.s3.raw_data_bucket_name],
            ["AWS/S3", "BucketSizeBytes", "BucketName", module.s3.processed_data_bucket_name]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "S3 Storage Usage"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Redshift", "CPUUtilization", "ClusterIdentifier", module.redshift.cluster_identifier],
            ["AWS/Redshift", "DatabaseConnections", "ClusterIdentifier", module.redshift.cluster_identifier]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Redshift Performance"
        }
      }
    ]
  })
}

# ===============================
# Output Values
# ===============================

output "s3_buckets" {
  description = "S3 bucket information"
  value = {
    raw_data_bucket      = module.s3.raw_data_bucket_name
    processed_data_bucket = module.s3.processed_data_bucket_name
    logs_bucket          = module.s3.logs_bucket_name
    airflow_bucket       = module.s3.airflow_bucket_name
  }
}

output "redshift_cluster" {
  description = "Redshift cluster information"
  value = {
    cluster_identifier = module.redshift.cluster_identifier
    cluster_endpoint   = module.redshift.cluster_endpoint
    cluster_port       = module.redshift.cluster_port
    database_name      = module.redshift.database_name
  }
  sensitive = true
}

output "mwaa_environment" {
  description = "MWAA environment information"
  value = {
    name        = module.mwaa.environment_name
    arn         = module.mwaa.environment_arn
    webserver_url = module.mwaa.webserver_url
  }
}

output "iam_roles" {
  description = "IAM roles created"
  value = {
    airflow_execution_role = module.iam.mwaa_execution_role_arn
    redshift_service_role  = module.iam.redshift_service_role_arn
  }
}