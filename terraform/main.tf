# ===============================
# Financial Data Pipeline - Main Terraform Configuration
# ===============================

terraform {
  required_version = ">= 1.0"
  required_providers {
    gcp = {
      source  = "hashicorp/gcp"
      version = "~> 5.0"
    }
  }

  backend "gcp" {
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

data "gcp_caller_identity" "current" {}
data "gcp_region" "current" {}

# ===============================
# IAM Module
# ===============================

module "iam" {
  source = "./modules/iam"

  project_name = local.project_name
  environment  = local.environment

  gcs_bucket_names = [
    module.gcp.raw_data_bucket_name,
    module.gcp.processed_data_bucket_name,
    module.gcp.logs_bucket_name
  ]

  bigquery_cluster_identifier = module.bigquery.cluster_identifier

  tags = local.common_tags
}

# ===============================
# GCS Module
# ===============================

module "gcp" {
  source = "./modules/gcp"

  project_name = local.project_name
  environment  = local.environment

  # Lifecycle configuration
  raw_data_lifecycle_days    = var.raw_data_lifecycle_days
  processed_data_lifecycle_days = var.processed_data_lifecycle_days
  logs_lifecycle_days        = var.logs_lifecycle_days

  tags = local.common_tags
}

# ===============================
# BigQuery Module
# ===============================

module "bigquery" {
  source = "./modules/bigquery"

  project_name = local.project_name
  environment  = local.environment

  # Cluster configuration
  cluster_identifier      = var.bigquery_cluster_identifier
  node_type              = var.bigquery_node_type
  number_of_nodes        = var.bigquery_number_of_nodes
  database_name          = var.bigquery_database_name
  master_username        = var.bigquery_master_username
  master_password        = var.bigquery_master_password

  # Security
  vpc_security_group_ids = var.bigquery_vpc_security_group_ids
  subnet_group_name      = var.bigquery_subnet_group_name

  # IAM
  iam_role_arn = module.iam.bigquery_service_role_arn

  tags = local.common_tags
}

# ===============================
# Cloud Composer (Managed Airflow) Module
# ===============================

module "cloudcomposer" {
  source = "./modules/cloudcomposer"

  project_name = local.project_name
  environment  = local.environment

  # Cloud Composer configuration
  airflow_version = var.cloudcomposer_airflow_version
  environment_class = var.cloudcomposer_environment_class

  # GCS configuration
  source_bucket_arn = module.gcp.airflow_bucket_arn
  dag_gcs_path       = var.cloudcomposer_dag_gcs_path

  # Network configuration
  subnet_ids         = var.cloudcomposer_subnet_ids
  security_group_ids = var.cloudcomposer_security_group_ids

  # IAM
  execution_role_arn = module.iam.cloudcomposer_execution_role_arn

  # Airflow configuration
  airflow_configuration_options = var.cloudcomposer_airflow_configuration_options

  tags = local.common_tags
}

# ===============================
# CloudWatch Dashboards and Alarms
# ===============================

resource "gcp_cloudwatch_dashboard" "pipeline_dashboard" {
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
            ["GCP/GCS", "BucketSizeBytes", "BucketName", module.gcp.raw_data_bucket_name],
            ["GCP/GCS", "BucketSizeBytes", "BucketName", module.gcp.processed_data_bucket_name]
          ]
          period = 300
          stat   = "Average"
          region = data.gcp_region.current.name
          title  = "GCS Storage Usage"
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
            ["GCP/BigQuery", "CPUUtilization", "ClusterIdentifier", module.bigquery.cluster_identifier],
            ["GCP/BigQuery", "DatabaseConnections", "ClusterIdentifier", module.bigquery.cluster_identifier]
          ]
          period = 300
          stat   = "Average"
          region = data.gcp_region.current.name
          title  = "BigQuery Performance"
        }
      }
    ]
  })
}

# ===============================
# Output Values
# ===============================

output "gcs_buckets" {
  description = "GCS bucket information"
  value = {
    raw_data_bucket      = module.gcp.raw_data_bucket_name
    processed_data_bucket = module.gcp.processed_data_bucket_name
    logs_bucket          = module.gcp.logs_bucket_name
    airflow_bucket       = module.gcp.airflow_bucket_name
  }
}

output "bigquery_cluster" {
  description = "BigQuery cluster information"
  value = {
    cluster_identifier = module.bigquery.cluster_identifier
    cluster_endpoint   = module.bigquery.cluster_endpoint
    cluster_port       = module.bigquery.cluster_port
    database_name      = module.bigquery.database_name
  }
  sensitive = true
}

output "cloudcomposer_environment" {
  description = "Cloud Composer environment information"
  value = {
    name        = module.cloudcomposer.environment_name
    arn         = module.cloudcomposer.environment_arn
    webserver_url = module.cloudcomposer.webserver_url
  }
}

output "iam_roles" {
  description = "IAM roles created"
  value = {
    airflow_execution_role = module.iam.cloudcomposer_execution_role_arn
    bigquery_service_role  = module.iam.bigquery_service_role_arn
  }
}
