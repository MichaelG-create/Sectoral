# =============================================================================
# S3 MODULE - Financial Data Pipeline
# =============================================================================

# -----------------------------------------------------------------------------
# S3 Bucket for Raw Data
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "raw_data" {
  bucket = var.raw_bucket_name

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-raw-data-${var.environment}"
    Type = "raw-data"
  })
}

resource "aws_s3_bucket_versioning" "raw_data_versioning" {
  bucket = aws_s3_bucket.raw_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw_data_encryption" {
  bucket = aws_s3_bucket.raw_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "raw_data_pab" {
  bucket = aws_s3_bucket.raw_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "raw_data_lifecycle" {
  bucket = aws_s3_bucket.raw_data.id

  rule {
    id     = "raw_data_lifecycle"
    status = "Enabled"

    expiration {
      days = var.raw_data_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# -----------------------------------------------------------------------------
# S3 Bucket for Processed Data
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "processed_data" {
  bucket = var.processed_bucket_name

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-processed-data-${var.environment}"
    Type = "processed-data"
  })
}

resource "aws_s3_bucket_versioning" "processed_data_versioning" {
  bucket = aws_s3_bucket.processed_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "processed_data_encryption" {
  bucket = aws_s3_bucket.processed_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "processed_data_pab" {
  bucket = aws_s3_bucket.processed_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "processed_data_lifecycle" {
  bucket = aws_s3_bucket.processed_data.id

  rule {
    id     = "processed_data_lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = var.processed_data_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# -----------------------------------------------------------------------------
# S3 Bucket for Logs
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "logs" {
  bucket = var.logs_bucket_name

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-logs-${var.environment}"
    Type = "logs"
  })
}

resource "aws_s3_bucket_versioning" "logs_versioning" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs_encryption" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "logs_pab" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs_lifecycle" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "logs_lifecycle"
    status = "Enabled"

    transition {
      days          = 7
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = var.logs_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# -----------------------------------------------------------------------------
# S3 Bucket for Airflow DAGs
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "dags" {
  bucket = var.dags_bucket_name

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-dags-${var.environment}"
    Type = "dags"
  })
}

resource "aws_s3_bucket_versioning" "dags_versioning" {
  bucket = aws_s3_bucket.dags.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dags_encryption" {
  bucket = aws_s3_bucket.dags.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "dags_pab" {
  bucket = aws_s3_bucket.dags.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# S3 Bucket Notifications
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_notification" "raw_data_notification" {
  bucket = aws_s3_bucket.raw_data.id

  lambda_function {
    lambda_function_arn = var.data_processing_lambda_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "stock-data/"
    filter_suffix       = ".json"
  }

  lambda_function {
    lambda_function_arn = var.data_validation_lambda_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "sector-data/"
    filter_suffix       = ".json"
  }

  depends_on = [aws_lambda_permission.allow_bucket_raw_data]
}

# -----------------------------------------------------------------------------
# Lambda Permissions for S3 Notifications
# -----------------------------------------------------------------------------

resource "aws_lambda_permission" "allow_bucket_raw_data" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = var.data_processing_lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.raw_data.arn
}

# -----------------------------------------------------------------------------
# S3 Bucket Policies
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_policy" "raw_data_policy" {
  bucket = aws_s3_bucket.raw_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAirflowAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.airflow_execution_role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.raw_data.arn,
          "${aws_s3_bucket.raw_data.arn}/*"
        ]
      },
      {
        Sid    = "AllowRedshiftAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.redshift_service_role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.raw_data.arn,
          "${aws_s3_bucket.raw_data.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "processed_data_policy" {
  bucket = aws_s3_bucket.processed_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAirflowAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.airflow_execution_role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.processed_data.arn,
          "${aws_s3_bucket.processed_data.arn}/*"
        ]
      },
      {
        Sid    = "AllowRedshiftAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.redshift_service_role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.processed_data.arn,
          "${aws_s3_bucket.processed_data.arn}/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Events for S3 Monitoring
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "s3_data_arrival" {
  name        = "${var.project_name}-s3-data-arrival-${var.environment}"
  description = "Trigger when new data arrives in S3"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.raw_data.id]
      }
    }
  })

  tags = var.common_tags
}

resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.s3_data_arrival.name
  target_id = "SendToSNS"
  arn       = var.sns_topic_arn
}

# -----------------------------------------------------------------------------
# S3 Inventory Configuration
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_inventory" "raw_data_inventory" {
  bucket = aws_s3_bucket.raw_data.id
  name   = "raw-data-inventory"

  included_object_versions = "Current"

  schedule {
    frequency = "Daily"
  }

  destination {
    bucket {
      format     = "CSV"
      bucket_arn = aws_s3_bucket.logs.arn
      prefix     = "inventory/raw-data/"
    }
  }

  optional_fields = [
    "Size",
    "LastModifiedDate",
    "StorageClass",
    "ETag",
    "IsMultipartUploaded",
    "ReplicationStatus",
    "EncryptionStatus"
  ]
}

# -----------------------------------------------------------------------------
# S3 Metrics Configuration
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_metric" "raw_data_metrics" {
  bucket = aws_s3_bucket.raw_data.id
  name   = "raw-data-metrics"

  filter {
    prefix = "stock-data/"
    tags = {
      Environment = var.environment
    }
  }
}

resource "aws_s3_bucket_metric" "processed_data_metrics" {
  bucket = aws_s3_bucket.processed_data.id
  name   = "processed-data-metrics"

  filter {
    prefix = "analytics/"
    tags = {
      Environment = var.environment
    }
  }
}