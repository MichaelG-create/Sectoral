# =============================================================================
# S3 MODULE OUTPUTS - Financial Data Pipeline
# =============================================================================

# -----------------------------------------------------------------------------
# Raw Data Bucket Outputs
# -----------------------------------------------------------------------------

output "raw_bucket_name" {
  description = "Name of the raw data S3 bucket"
  value       = aws_s3_bucket.raw_data.bucket
}

output "raw_bucket_arn" {
  description = "ARN of the raw data S3 bucket"
  value       = aws_s3_bucket.raw_data.arn
}

output "raw_bucket_id" {
  description = "ID of the raw data S3 bucket"
  value       = aws_s3_bucket.raw_data.id
}

output "raw_bucket_region" {
  description = "Region of the raw data S3 bucket"
  value       = aws_s3_bucket.raw_data.region
}

output "raw_bucket_domain_name" {
  description = "Domain name of the raw data S3 bucket"
  value       = aws_s3_bucket.raw_data.bucket_domain_name
}

# -----------------------------------------------------------------------------
# Processed Data Bucket Outputs
# -----------------------------------------------------------------------------

output "processed_bucket_name" {
  description = "Name of the processed data S3 bucket"
  value       = aws_s3_bucket.processed_data.bucket
}

output "processed_bucket_arn" {
  description = "ARN of the processed data S3 bucket"
  value       = aws_s3_bucket.processed_data.arn
}

output "processed_bucket_id" {
  description = "ID of the processed data S3 bucket"
  value       = aws_s3_bucket.processed_data.id
}

output "processed_bucket_region" {
  description = "Region of the processed data S3 bucket"
  value       = aws_s3_bucket.processed_data.region
}

output "processed_bucket_domain_name" {
  description = "Domain name of the processed data S3 bucket"
  value       = aws_s3_bucket.processed_data.bucket_domain_name
}

# -----------------------------------------------------------------------------
# Logs Bucket Outputs
# -----------------------------------------------------------------------------

output "logs_bucket_name" {
  description = "Name of the logs S3 bucket"
  value       = aws_s3_bucket.logs.bucket
}

output "logs_bucket_arn" {
  description = "ARN of the logs S3 bucket"
  value       = aws_s3_bucket.logs.arn
}

output "logs_bucket_id" {
  description = "ID of the logs S3 bucket"
  value       = aws_s3_bucket.logs.id
}

output "logs_bucket_region" {
  description = "Region of the logs S3 bucket"
  value       = aws_s3_bucket.logs.region
}

output "logs_bucket_domain_name" {
  description = "Domain name of the logs S3 bucket"
  value       = aws_s3_bucket.logs.bucket_domain_name
}

# -----------------------------------------------------------------------------
# DAGs Bucket Outputs
# -----------------------------------------------------------------------------

output "dags_bucket_name" {
  description = "Name of the DAGs S3 bucket"
  value       = aws_s3_bucket.dags.bucket
}

output "dags_bucket_arn" {
  description = "ARN of the DAGs S3 bucket"
  value       = aws_s3_bucket.dags.arn
}

output "dags_bucket_id" {
  description = "ID of the DAGs S3 bucket"
  value       = aws_s3_bucket.dags.id
}

output "dags_bucket_region" {
  description = "Region of the DAGs S3 bucket"
  value       = aws_s3_bucket.dags.region
}

output "dags_bucket_domain_name" {
  description = "Domain name of the DAGs S3 bucket"
  value       = aws_s3_bucket.dags.bucket_domain_name
}

# -----------------------------------------------------------------------------
# Bucket URLs and Paths
# -----------------------------------------------------------------------------

output "raw_data_s3_path" {
  description = "S3 path for raw data bucket"
  value       = "s3://${aws_s3_bucket.raw_data.bucket}"
}

output "processed_data_s3_path" {
  description = "S3 path for processed data bucket"
  value       = "s3://${aws_s3_bucket.processed_data.bucket}"
}

output "logs_s3_path" {
  description = "S3 path for logs bucket"
  value       = "s3://${aws_s3_bucket.logs.bucket}"
}

output "dags_s3_path" {
  description = "S3 path for DAGs bucket"
  value       = "s3://${aws_s3_bucket.dags.bucket}"
}

# -----------------------------------------------------------------------------
# Bucket Policies
# -----------------------------------------------------------------------------

output "raw_data_bucket_policy" {
  description = "Policy document for raw data bucket"
  value       = aws_s3_bucket_policy.raw_data_policy.policy
}

output "processed_data_bucket_policy" {
  description = "Policy document for processed data bucket"
  value       = aws_s3_bucket_policy.processed_data_policy.policy
}

# -----------------------------------------------------------------------------
# Monitoring Resources
# -----------------------------------------------------------------------------

output "cloudwatch_event_rule_arn" {
  description = "ARN of the CloudWatch event rule for S3 data arrival"
  value       = aws_cloudwatch_event_rule.s3_data_arrival.arn
}

output "inventory_configuration" {
  description = "S3 inventory configuration details"
  value = {
    raw_data_inventory = {
      name   = aws_s3_bucket_inventory.raw_data_inventory.name
      bucket = aws_s3_bucket_inventory.raw_data_inventory.bucket
    }
  }
}

# -----------------------------------------------------------------------------
# Data Partitioning Paths
# -----------------------------------------------------------------------------

output "data_partitioning_paths" {
  description = "Standard data partitioning paths"
  value = {
    stock_data = {
      daily   = "s3://${aws_s3_bucket.raw_data.bucket}/stock-data/year=%Y/month=%m/day=%d/"
      hourly  = "s3://${aws_s3_bucket.raw_data.bucket}/stock-data/year=%Y/month=%m/day=%d/hour=%H/"
    }
    sector_data = {
      daily   = "s3://${aws_s3_bucket.raw_data.bucket}/sector-data/year=%Y/month=%m/day=%d/"
      weekly  = "s3://${aws_s3_bucket.raw_data.bucket}/sector-data/year=%Y/week=%W/"
    }
    macro_data = {
      daily   = "s3://${aws_s3_bucket.raw_data.bucket}/macro-data/year=%Y/month=%m/day=%d/"
      monthly = "s3://${aws_s3_bucket.raw_data.bucket}/macro-data/year=%Y/month=%m/"
    }
  }
}

# -----------------------------------------------------------------------------
# Access Configuration
# -----------------------------------------------------------------------------

output "bucket_access_configuration" {
  description = "Access configuration for all buckets"
  value = {
    raw_data = {
      public_access_blocked = true
      versioning_enabled    = true
      encryption_enabled    = true
    }
    processed_data = {
      public_access_blocked = true
      versioning_enabled    = true
      encryption_enabled    = true
    }
    logs = {
      public_access_blocked = true
      versioning_enabled    = true
      encryption_enabled    = true
    }
    dags = {
      public_access_blocked = true
      versioning_enabled    = true
      encryption_enabled    = true
    }
  }
}

# -----------------------------------------------------------------------------
# Cost Optimization Information
# -----------------------------------------------------------------------------

output "lifecycle_policies" {
  description = "Lifecycle policies applied to buckets"
  value = {
    raw_data = {
      expiration_days = var.raw_data_expiration_days
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]
    }
    processed_data = {
      expiration_days = var.processed_data_expiration_days
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
        {
          days          = 365
          storage_class = "DEEP_ARCHIVE"
        }
      ]
    }
    logs = {
      expiration_days = var.logs_expiration_days
      transitions = [
        {
          days          = 7
          storage_class = "STANDARD_IA"
        },
        {
          days          = 30
          storage_class = "GLACIER"
        }
      ]
    }
  }
}

# -----------------------------------------------------------------------------
# Integration Endpoints
# -----------------------------------------------------------------------------

output "integration_endpoints" {
  description = "Integration endpoints for other services"
  value = {
    airflow_dags_bucket     = aws_s3_bucket.dags.bucket
    redshift_copy_path      = "s3://${aws_s3_bucket.processed_data.bucket}/redshift-ready/"
    analytics_output_path   = "s3://${aws_s3_bucket.processed_data.bucket}/analytics/"
    data_quality_logs_path  = "s3://${aws_s3_bucket.logs.bucket}/data-quality/"
    pipeline_logs_path      = "s3://${aws_s3_bucket.logs.bucket}/pipeline/"
  }
}