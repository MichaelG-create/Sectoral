#=============================================================================
# MWAA (Managed Airflow) MODULE - Financial Data Pipeline
#=============================================================================
#
# Amazon Managed Workflows for Apache Airflow (MWAA) configuration
#
#------------------------------------------------------------------------------

# S3 bucket for Airflow source code
resource "aws_s3_bucket" "mwaa_source" {
  bucket = "${var.project_name}-${var.environment}-mwaa-source"
  
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-mwaa-source"
    Environment = var.environment
    Component   = "mwaa"
  })
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "mwaa_source" {
  bucket = aws_s3_bucket.mwaa_source.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "mwaa_source" {
  bucket = aws_s3_bucket.mwaa_source.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "mwaa_source" {
  bucket = aws_s3_bucket.mwaa_source.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = true
  }
}

# Upload requirements.txt for Airflow
resource "aws_s3_object" "requirements" {
  bucket = aws_s3_bucket.mwaa_source.id
  key    = "requirements.txt"
  source = var.requirements_file_path
  etag   = filemd5(var.requirements_file_path)

  depends_on = [aws_s3_bucket_versioning.mwaa_source]
}

# Upload DAGs to S3
resource "aws_s3_object" "dags" {
  for_each = var.dags_folder_path != null ? fileset(var.dags_folder_path, "**/*.py") : []
  
  bucket = aws_s3_bucket.mwaa_source.id
  key    = "dags/${each.value}"
  source = "${var.dags_folder_path}/${each.value}"
  etag   = filemd5("${var.dags_folder_path}/${each.value}")

  depends_on = [aws_s3_bucket_versioning.mwaa_source]
}

# Upload plugins to S3
resource "aws_s3_object" "plugins" {
  for_each = var.plugins_folder_path != null ? fileset(var.plugins_folder_path, "**/*.py") : []
  
  bucket = aws_s3_bucket.mwaa_source.id
  key    = "plugins/${each.value}"
  source = "${var.plugins_folder_path}/${each.value}"
  etag   = filemd5("${var.plugins_folder_path}/${each.value}")

  depends_on = [aws_s3_bucket_versioning.mwaa_source]
}

# IAM role for MWAA
resource "aws_iam_role" "mwaa_execution_role" {
  name = "${var.project_name}-${var.environment}-mwaa-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "airflow-env.amazonaws.com",
            "airflow.amazonaws.com"
          ]
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-mwaa-execution-role"
    Environment = var.environment
    Component   = "mwaa"
  })
}

# IAM policy for MWAA execution role
resource "aws_iam_role_policy" "mwaa_execution_policy" {
  name = "${var.project_name}-${var.environment}-mwaa-execution-policy"
  role = aws_iam_role.mwaa_execution_role.id

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
          "s3:ListAllMyBuckets"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject*",
          "s3:GetBucket*",
          "s3:List*"
        ]
        Resource = [
          aws_s3_bucket.mwaa_source.arn,
          "${aws_s3_bucket.mwaa_source.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject*",
          "s3:PutObject*",
          "s3:DeleteObject*",
          "s3:GetBucket*",
          "s3:List*"
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
        Resource = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:airflow-${var.environment_name}-*"
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
        Resource = "arn:aws:sqs:${var.aws_region}:*:airflow-celery-*"
      },
      {
        Effect = "Allow"
        Action = [
          "redshift:GetClusterCredentials",
          "redshift:DescribeClusters"
        ]
        Resource = var.redshift_cluster_arn
      },
      {
        Effect = "Allow"
        Action = [
          "redshift-data:BatchExecuteStatement",
          "redshift-data:ExecuteStatement",
          "redshift-data:GetStatementResult",
          "redshift-data:DescribeStatement",
          "redshift-data:ListStatements"
        ]
        Resource = "*"
      }
    ]
  })
}

# Security group for MWAA
resource "aws_security_group" "mwaa" {
  name        = "${var.project_name}-${var.environment}-mwaa-sg"
  description = "Security group for MWAA environment"
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
    Name        = "${var.project_name}-${var.environment}-mwaa-sg"
    Environment = var.environment
    Component   = "mwaa"
  })
}

# MWAA Environment
resource "aws_mwaa_environment" "main" {
  name                    = "${var.project_name}-${var.environment}"
  airflow_version         = var.airflow_version
  environment_class       = var.environment_class
  max_workers             = var.max_workers
  min_workers             = var.min_workers
  source_bucket_arn       = aws_s3_bucket.mwaa_source.arn
  dag_s3_path             = "dags"
  plugins_s3_path         = var.plugins_folder_path != null ? "plugins" : null
  requirements_s3_path    = "requirements.txt"
  execution_role_arn      = aws_iam_role.mwaa_execution_role.arn
  kms_key                 = var.kms_key_id
  webserver_access_mode   = var.webserver_access_mode
  weekly_maintenance_window_start = var.weekly_maintenance_window_start

  network_configuration {
    security_group_ids = [aws_security_group.mwaa.id]
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
    Name        = "${var.project_name}-${var.environment}-mwaa"
    Environment = var.environment
    Component   = "mwaa"
  })

  depends_on = [
    aws_s3_object.requirements,
    aws_s3_object.dags,
    aws_s3_object.plugins,
    aws_iam_role_policy.mwaa_execution_policy
  ]
}