# =============================================================================
# GCS MODULE - Financial Data Pipeline
# =============================================================================

# -----------------------------------------------------------------------------
# GCS Bucket for Raw Data
# -----------------------------------------------------------------------------

resource "gcs_bucket" "raw_data" {
  bucket = var.raw_bucket_name

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-raw-data-${var.environment}"
    Type = "raw-data"
  })
}

resource "gcs_bucket_versioning" "raw_data_versioning" {
  bucket = gcs_bucket.raw_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "gcs_bucket_server_side_encryption_configuration" "raw_data_encryption" {
  bucket = gcs_bucket.raw_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "gcs_bucket_public_access_block" "raw_data_pab" {
  bucket = gcs_bucket.raw_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "gcs_bucket_lifecycle_configuration" "raw_data_lifecycle" {
  bucket = gcs_bucket.raw_data.id

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
# GCS Bucket for Processed Data
# -----------------------------------------------------------------------------

resource "gcs_bucket" "processed_data" {
  bucket = var.processed_bucket_name

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-processed-data-${var.environment}"
    Type = "processed-data"
  })
}

resource "gcs_bucket_versioning" "processed_data_versioning" {
  bucket = gcs_bucket.processed_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "gcs_bucket_server_side_encryption_configuration" "processed_data_encryption" {
  bucket = gcs_bucket.processed_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "gcs_bucket_public_access_block" "processed_data_pab" {
  bucket = gcs_bucket.processed_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "gcs_bucket_lifecycle_configuration" "processed_data_lifecycle" {
  bucket = gcs_bucket.processed_data.id

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
# GCS Bucket for Logs
# -----------------------------------------------------------------------------

resource "gcs_bucket" "logs" {
  bucket = var.logs_bucket_name

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-logs-${var.environment}"
    Type = "logs"
  })
}

resource "gcs_bucket_versioning" "logs_versioning" {
  bucket = gcs_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "gcs_bucket_server_side_encryption_configuration" "logs_encryption" {
  bucket = gcs_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "gcs_bucket_public_access_block" "logs_pab" {
  bucket = gcs_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "gcs_bucket_lifecycle_configuration" "logs_lifecycle" {
  bucket = gcs_bucket.logs.id

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
# GCS Bucket for Airflow DAGs
# -----------------------------------------------------------------------------

resource "gcs_bucket" "dags" {
  bucket = var.dags_bucket_name

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-dags-${var.environment}"
    Type = "dags"
  })
}

resource "gcs_bucket_versioning" "dags_versioning" {
  bucket = gcs_bucket.dags.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "gcs_bucket_server_side_encryption_configuration" "dags_encryption" {
  bucket = gcs_bucket.dags.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "gcs_bucket_public_access_block" "dags_pab" {
  bucket = gcs_bucket.dags.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# GCS Bucket Notifications
# -----------------------------------------------------------------------------

resource "gcs_bucket_notification" "raw_data_notification" {
  bucket = gcs_bucket.raw_data.id

  cloudfunctions_function {
    cloudfunctions_function_arn = var.data_processing_cloudfunctions_arn
    events              = ["gcp:ObjectCreated:*"]
    filter_prefix       = "stock-data/"
    filter_suffix       = ".json"
  }

  cloudfunctions_function {
    cloudfunctions_function_arn = var.data_validation_cloudfunctions_arn
    events              = ["gcp:ObjectCreated:*"]
    filter_prefix       = "sector-data/"
    filter_suffix       = ".json"
  }

  depends_on = [gcp_cloudfunctions_permission.allow_bucket_raw_data]
}

# -----------------------------------------------------------------------------
# Lambda Permissions for GCS Notifications
# -----------------------------------------------------------------------------

resource "gcp_cloudfunctions_permission" "allow_bucket_raw_data" {
  statement_id  = "AllowExecutionFromGCSBucket"
  action        = "cloudfunctions:InvokeFunction"
  function_name = var.data_processing_cloudfunctions_function_name
  principal     = "gcp.googlegcp.com"
  source_arn    = gcs_bucket.raw_data.arn
}

# -----------------------------------------------------------------------------
# GCS Bucket Policies
# -----------------------------------------------------------------------------

resource "gcs_bucket_policy" "raw_data_policy" {
  bucket = gcs_bucket.raw_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAirflowAccess"
        Effect = "Allow"
        Principal = {
          GCP = var.airflow_execution_role_arn
        }
        Action = [
          "gcp:GetObject",
          "gcp:PutObject",
          "gcp:DeleteObject",
          "gcp:ListBucket"
        ]
        Resource = [
          gcs_bucket.raw_data.arn,
          "${gcs_bucket.raw_data.arn}/*"
        ]
      },
      {
        Sid    = "AllowBigQueryAccess"
        Effect = "Allow"
        Principal = {
          GCP = var.bigquery_service_role_arn
        }
        Action = [
          "gcp:GetObject",
          "gcp:ListBucket"
        ]
        Resource = [
          gcs_bucket.raw_data.arn,
          "${gcs_bucket.raw_data.arn}/*"
        ]
      }
    ]
  })
}

resource "gcs_bucket_policy" "processed_data_policy" {
  bucket = gcs_bucket.processed_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAirflowAccess"
        Effect = "Allow"
        Principal = {
          GCP = var.airflow_execution_role_arn
        }
        Action = [
          "gcp:GetObject",
          "gcp:PutObject",
          "gcp:DeleteObject",
          "gcp:ListBucket"
        ]
        Resource = [
          gcs_bucket.processed_data.arn,
          "${gcs_bucket.processed_data.arn}/*"
        ]
      },
      {
        Sid    = "AllowBigQueryAccess"
        Effect = "Allow"
        Principal = {
          GCP = var.bigquery_service_role_arn
        }
        Action = [
          "gcp:GetObject",
          "gcp:ListBucket"
        ]
        Resource = [
          gcs_bucket.processed_data.arn,
          "${gcs_bucket.processed_data.arn}/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Events for GCS Monitoring
# -----------------------------------------------------------------------------

resource "gcp_cloudwatch_event_rule" "gcs_data_arrival" {
  name        = "${var.project_name}-gcp-data-arrival-${var.environment}"
  description = "Trigger when new data arrives in GCS"

  event_pattern = jsonencode({
    source      = ["gcp.gcp"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [gcs_bucket.raw_data.id]
      }
    }
  })

  tags = var.common_tags
}

resource "gcp_cloudwatch_event_target" "sns_target" {
  rule      = gcp_cloudwatch_event_rule.gcs_data_arrival.name
  target_id = "SendToSNS"
  arn       = var.sns_topic_arn
}

# -----------------------------------------------------------------------------
# GCS Inventory Configuration
# -----------------------------------------------------------------------------

resource "gcs_bucket_inventory" "raw_data_inventory" {
  bucket = gcs_bucket.raw_data.id
  name   = "raw-data-inventory"

  included_object_versions = "Current"

  schedule {
    frequency = "Daily"
  }

  destination {
    bucket {
      format     = "CSV"
      bucket_arn = gcs_bucket.logs.arn
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
# GCS Metrics Configuration
# -----------------------------------------------------------------------------

resource "gcs_bucket_metric" "raw_data_metrics" {
  bucket = gcs_bucket.raw_data.id
  name   = "raw-data-metrics"

  filter {
    prefix = "stock-data/"
    tags = {
      Environment = var.environment
    }
  }
}

resource "gcs_bucket_metric" "processed_data_metrics" {
  bucket = gcs_bucket.processed_data.id
  name   = "processed-data-metrics"

  filter {
    prefix = "analytics/"
    tags = {
      Environment = var.environment
    }
  }
}
