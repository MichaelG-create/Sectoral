#=============================================================================
# Cloud Composer (Managed Airflow) MODULE - Financial Data Pipeline
#=============================================================================
#
# Google Managed Workflows for Apache Airflow (Cloud Composer) configuration
#
#------------------------------------------------------------------------------

# GCS bucket for Airflow source code
resource "gcs_bucket" "cloudcomposer_source" {
  bucket = "${var.project_name}-${var.environment}-cloudcomposer-source"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-cloudcomposer-source"
    Environment = var.environment
    Component   = "cloudcomposer"
  })
}

# GCS bucket versioning
resource "gcs_bucket_versioning" "cloudcomposer_source" {
  bucket = gcs_bucket.cloudcomposer_source.id
  versioning_configuration {
    status = "Enabled"
  }
}

# GCS bucket public access block
resource "gcs_bucket_public_access_block" "cloudcomposer_source" {
  bucket = gcs_bucket.cloudcomposer_source.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# GCS bucket server-side encryption
resource "gcs_bucket_server_side_encryption_configuration" "cloudcomposer_source" {
  bucket = gcs_bucket.cloudcomposer_source.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "gcp:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = true
  }
}

# Upload requirements.txt for Airflow
resource "gcs_object" "requirements" {
  bucket = gcs_bucket.cloudcomposer_source.id
  key    = "requirements.txt"
  source = var.requirements_file_path
  etag   = filemd5(var.requirements_file_path)

  depends_on = [gcs_bucket_versioning.cloudcomposer_source]
}

# Upload DAGs to GCS
resource "gcs_object" "dags" {
  for_each = var.dags_folder_path != null ? fileset(var.dags_folder_path, "**/*.py") : []

  bucket = gcs_bucket.cloudcomposer_source.id
  key    = "dags/${each.value}"
  source = "${var.dags_folder_path}/${each.value}"
  etag   = filemd5("${var.dags_folder_path}/${each.value}")

  depends_on = [gcs_bucket_versioning.cloudcomposer_source]
}

# Upload plugins to GCS
resource "gcs_object" "plugins" {
  for_each = var.plugins_folder_path != null ? fileset(var.plugins_folder_path, "**/*.py") : []

  bucket = gcs_bucket.cloudcomposer_source.id
  key    = "plugins/${each.value}"
  source = "${var.plugins_folder_path}/${each.value}"
  etag   = filemd5("${var.plugins_folder_path}/${each.value}")

  depends_on = [gcs_bucket_versioning.cloudcomposer_source]
}

# IAM role for Cloud Composer
resource "gcp_iam_role" "cloudcomposer_execution_role" {
  name = "${var.project_name}-${var.environment}-cloudcomposer-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "airflow-env.googlegcp.com",
            "airflow.googlegcp.com"
          ]
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-cloudcomposer-execution-role"
    Environment = var.environment
    Component   = "cloudcomposer"
  })
}

# IAM policy for Cloud Composer execution role
resource "gcp_iam_role_policy" "cloudcomposer_execution_policy" {
  name = "${var.project_name}-${var.environment}-cloudcomposer-execution-policy"
  role = gcp_iam_role.cloudcomposer_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "airflow:PublishMetrics"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "gcp:ListAllMyBuckets"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "gcp:GetObject*",
          "gcp:GetBucket*",
          "gcp:List*"
        ]
        Resource = [
          gcs_bucket.cloudcomposer_source.arn,
          "${gcs_bucket.cloudcomposer_source.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "gcp:GetObject*",
          "gcp:PutObject*",
          "gcp:DeleteObject*",
          "gcp:GetBucket*",
          "gcp:List*"
        ]
        Resource = var.data_bucket_arns
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:GetLogRecord",
          "logs:GetLogGroupFields",
          "logs:GetQueryResults",
          "logs:DescribeLogGroups"
        ]
        Resource = "arn:gcp:logs:${var.gcp_region}:${var.gcp_account_id}:log-group:airflow-${var.environment_name}-*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ]
        Resource = "arn:gcp:sqs:${var.gcp_region}:*:airflow-celery-*"
      },
      {
        Effect = "Allow"
        Action = [
          "bigquery:GetClusterCredentials",
          "bigquery:DescribeClusters"
        ]
        Resource = var.bigquery_cluster_arn
      },
      {
        Effect = "Allow"
        Action = [
          "bigquery-data:BatchExecuteStatement",
          "bigquery-data:ExecuteStatement",
          "bigquery-data:GetStatementResult",
          "bigquery-data:DescribeStatement",
          "bigquery-data:ListStatements"
        ]
        Resource = "*"
      }
    ]
  })
}

# Security group for Cloud Composer
resource "gcp_security_group" "cloudcomposer" {
  name        = "${var.project_name}-${var.environment}-cloudcomposer-sg"
  description = "Security group for Cloud Composer environment"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-cloudcomposer-sg"
    Environment = var.environment
    Component   = "cloudcomposer"
  })
}

# Cloud Composer Environment
resource "gcp_cloudcomposer_environment" "main" {
  name                    = "${var.project_name}-${var.environment}"
  airflow_version         = var.airflow_version
  environment_class       = var.environment_class
  max_workers             = var.max_workers
  min_workers             = var.min_workers
  source_bucket_arn       = gcs_bucket.cloudcomposer_source.arn
  dag_gcs_path             = "dags"
  plugins_gcs_path         = var.plugins_folder_path != null ? "plugins" : null
  requirements_gcs_path    = "requirements.txt"
  execution_role_arn      = gcp_iam_role.cloudcomposer_execution_role.arn
  kms_key                 = var.kms_key_id
  webserver_access_mode   = var.webserver_access_mode
  weekly_maintenance_window_start = var.weekly_maintenance_window_start

  network_configuration {
    security_group_ids = [gcp_security_group.cloudcomposer.id]
    subnet_ids         = var.subnet_ids
  }

  logging_configuration {
    dag_processing_logs {
      enabled   = var.dag_processing_logs_enabled
      log_level = var.dag_processing_logs_level
    }

    scheduler_logs {
      enabled   = var.scheduler_logs_enabled
      log_level = var.scheduler_logs_level
    }

    task_logs {
      enabled   = var.task_logs_enabled
      log_level = var.task_logs_level
    }

    webserver_logs {
      enabled   = var.webserver_logs_enabled
      log_level = var.webserver_logs_level
    }

    worker_logs {
      enabled   = var.worker_logs_enabled
      log_level = var.worker_logs_level
    }
  }

  airflow_configuration_options = var.airflow_configuration_options

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-cloudcomposer"
    Environment = var.environment
    Component   = "cloudcomposer"
  })

  depends_on = [
    gcs_object.requirements,
    gcs_object.dags,
    gcs_object.plugins,
    gcp_iam_role_policy.cloudcomposer_execution_policy
  ]
}
