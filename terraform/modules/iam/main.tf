#=============================================================================
# IAM MODULE - Financial Data Pipeline
#=============================================================================
#
# IAM roles and policies for the financial data pipeline
#
#------------------------------------------------------------------------------

# Data Lake GCS Access Role
resource "gcp_iam_role" "data_lake_role" {
  name = "${var.project_name}-${var.environment}-data-lake-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "computeengine.googlegcp.com",
            "cloudfunctions.googlegcp.com",
            "dataflow.googlegcp.com"
          ]
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-data-lake-role"
    Environment = var.environment
    Component   = "iam"
  })
}

# Data Lake GCS Policy
resource "gcp_iam_role_policy" "data_lake_gcs_policy" {
  name = "${var.project_name}-${var.environment}-data-lake-gcp-policy"
  role = gcp_iam_role.data_lake_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "gcp:GetObject",
          "gcp:GetObjectVersion",
          "gcp:PutObject",
          "gcp:PutObjectAcl",
          "gcp:DeleteObject",
          "gcp:ListBucket",
          "gcp:GetBucketLocation",
          "gcp:GetBucketVersioning"
        ]
        Resource = concat(
          var.gcs_bucket_arns,
          [for arn in var.gcs_bucket_arns : "${arn}/*"]
        )
      },
      {
        Effect = "Allow"
        Action = [
          "gcp:ListAllMyBuckets",
          "gcp:GetBucketLocation"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda Execution Role
resource "gcp_iam_role" "cloudfunctions_execution_role" {
  name = "${var.project_name}-${var.environment}-cloudfunctions-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudfunctions.googlegcp.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-cloudfunctions-execution-role"
    Environment = var.environment
    Component   = "iam"
  })
}

# Lambda Basic Execution Policy
resource "gcp_iam_role_policy_attachment" "cloudfunctions_basic_execution" {
  role       = gcp_iam_role.cloudfunctions_execution_role.name
  policy_arn = "arn:gcp:iam::gcp:policy/service-role/GCPLambdaBasicExecutionRole"
}

# Lambda VPC Execution Policy (if needed)
resource "gcp_iam_role_policy_attachment" "cloudfunctions_vpc_execution" {
  count      = var.cloudfunctions_vpc_access ? 1 : 0
  role       = gcp_iam_role.cloudfunctions_execution_role.name
  policy_arn = "arn:gcp:iam::gcp:policy/service-role/GCPLambdaVPCAccessExecutionRole"
}

# Lambda Custom Policy for Data Pipeline
resource "gcp_iam_role_policy" "cloudfunctions_data_pipeline_policy" {
  name = "${var.project_name}-${var.environment}-cloudfunctions-data-pipeline-policy"
  role = gcp_iam_role.cloudfunctions_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "gcp:GetObject",
          "gcp:PutObject",
          "gcp:DeleteObject",
          "gcp:ListBucket"
        ]
        Resource = concat(
          var.gcs_bucket_arns,
          [for arn in var.gcs_bucket_arns : "${arn}/*"]
        )
      },
      {
        Effect = "Allow"
        Action = [
          "bigquery:GetClusterCredentials",
          "bigquery:DescribeClusters"
        ]
        Resource = var.bigquery_cluster_arn != null ? [var.bigquery_cluster_arn] : []
      },
      {
        Effect = "Allow"
        Action = [
          "bigquery-data:BatchExecuteStatement",
          "bigquery-data:ExecuteStatement",
          "bigquery-data:GetStatementResult",
          "bigquery-data:DescribeStatement"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.secrets_manager_arns
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:gcp:ssm:${var.gcp_region}:${var.gcp_account_id}:parameter/${var.project_name}/${var.environment}/*"
      }
    ]
  })
}

# BigQuery Service Role
resource "gcp_iam_role" "bigquery_service_role" {
  name = "${var.project_name}-${var.environment}-bigquery-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bigquery.googlegcp.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-bigquery-service-role"
    Environment = var.environment
    Component   = "iam"
  })
}

# BigQuery GCS Access Policy
resource "gcp_iam_role_policy" "bigquery_gcs_policy" {
  name = "${var.project_name}-${var.environment}-bigquery-gcp-policy"
  role = gcp_iam_role.bigquery_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "gcp:GetObject",
          "gcp:GetObjectVersion",
          "gcp:ListBucket",
          "gcp:GetBucketLocation",
          "gcp:GetBucketVersioning"
        ]
        Resource = concat(
          var.gcs_bucket_arns,
          [for arn in var.gcs_bucket_arns : "${arn}/*"]
        )
      },
      {
        Effect = "Allow"
        Action = [
          "gcp:PutObject",
          "gcp:PutObjectAcl",
          "gcp:DeleteObject"
        ]
        Resource = [for arn in var.gcs_bucket_arns : "${arn}/bigquery-logs/*"]
      }
    ]
  })
}

# Glue Service Role
resource "gcp_iam_role" "dataflow_service_role" {
  name = "${var.project_name}-${var.environment}-dataflow-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "dataflow.googlegcp.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-dataflow-service-role"
    Environment = var.environment
    Component   = "iam"
  })
}

# Glue Service Policy
resource "gcp_iam_role_policy_attachment" "dataflow_service_policy" {
  role       = gcp_iam_role.dataflow_service_role.name
  policy_arn = "arn:gcp:iam::gcp:policy/service-role/GCPGlueServiceRole"
}

# Glue Custom Policy for Data Pipeline
resource "gcp_iam_role_policy" "dataflow_data_pipeline_policy" {
  name = "${var.project_name}-${var.environment}-dataflow-data-pipeline-policy"
  role = gcp_iam_role.dataflow_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "gcp:GetObject",
          "gcp:PutObject",
          "gcp:DeleteObject",
          "gcp:ListBucket",
          "gcp:GetBucketLocation"
        ]
        Resource = concat(
          var.gcs_bucket_arns,
          [for arn in var.gcs_bucket_arns : "${arn}/*"]
        )
      },
      {
        Effect = "Allow"
        Action = [
          "bigquery:GetClusterCredentials",
          "bigquery:DescribeClusters"
        ]
        Resource = var.bigquery_cluster_arn != null ? [var.bigquery_cluster_arn] : []
      },
      {
        Effect = "Allow"
        Action = [
          "bigquery-data:BatchExecuteStatement",
          "bigquery-data:ExecuteStatement",
          "bigquery-data:GetStatementResult",
          "bigquery-data:DescribeStatement"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Events Role
resource "gcp_iam_role" "cloudwatch_events_role" {
  name = "${var.project_name}-${var.environment}-cloudwatch-events-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.googlegcp.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-cloudwatch-events-role"
    Environment = var.environment
    Component   = "iam"
  })
}

# CloudWatch Events Policy
resource "gcp_iam_role_policy" "cloudwatch_events_policy" {
  name = "${var.project_name}-${var.environment}-cloudwatch-events-policy"
  role = gcp_iam_role.cloudwatch_events_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudfunctions:InvokeFunction"
        ]
        Resource = "arn:gcp:cloudfunctions:${var.gcp_region}:${var.gcp_account_id}:function:${var.project_name}-${var.environment}-*"
      }
    ]
  })
}

# API Gateway Execution Role
resource "gcp_iam_role" "api_gateway_execution_role" {
  count = var.create_api_gateway_role ? 1 : 0
  name  = "${var.project_name}-${var.environment}-api-gateway-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.googlegcp.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-api-gateway-execution-role"
    Environment = var.environment
    Component   = "iam"
  })
}

# API Gateway CloudWatch Logs Policy
resource "gcp_iam_role_policy" "api_gateway_cloudwatch_policy" {
  count = var.create_api_gateway_role ? 1 : 0
  name  = "${var.project_name}-${var.environment}-api-gateway-cloudwatch-policy"
  role  = gcp_iam_role.api_gateway_execution_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "arn:gcp:logs:${var.gcp_region}:${var.gcp_account_id}:*"
      }
    ]
  })
}

# Cross-account role for external access (optional)
resource "gcp_iam_role" "cross_account_role" {
  count = length(var.trusted_account_ids) > 0 ? 1 : 0
  name  = "${var.project_name}-${var.environment}-cross-account-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          GCP = [for account_id in var.trusted_account_ids : "arn:gcp:iam::${account_id}:root"]
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-cross-account-role"
    Environment = var.environment
    Component   = "iam"
  })
}

# Cross-account policy
resource "gcp_iam_role_policy" "cross_account_policy" {
  count = length(var.trusted_account_ids) > 0 ? 1 : 0
  name  = "${var.project_name}-${var.environment}-cross-account-policy"
  role  = gcp_iam_role.cross_account_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "gcp:GetObject",
          "gcp:ListBucket"
        ]
        Resource = concat(
          var.gcs_bucket_arns,
          [for arn in var.gcs_bucket_arns : "${arn}/*"]
        )
      },
      {
        Effect = "Allow"
        Action = [
          "bigquery:DescribeClusters"
        ]
        Resource = var.bigquery_cluster_arn != null ? [var.bigquery_cluster_arn] : []
      }
    ]
  })
}
