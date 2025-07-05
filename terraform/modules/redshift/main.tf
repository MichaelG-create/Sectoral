# =============================================================================
# REDSHIFT MODULE - Financial Data Pipeline
# =============================================================================

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

# -----------------------------------------------------------------------------
# Redshift Subnet Group
# -----------------------------------------------------------------------------

resource "aws_redshift_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-redshift-subnet-group"
  })
}

# -----------------------------------------------------------------------------
# Redshift Parameter Group
# -----------------------------------------------------------------------------

resource "aws_redshift_parameter_group" "main" {
  name   = "${var.project_name}-${var.environment}-parameter-group"
  family = "redshift-1.0"

  parameter {
    name  = "query_timeout"
    value = var.query_timeout
  }

  parameter {
    name  = "max_cursor_result_set_size"
    value = "default"
  }

  parameter {
    name  = "enable_user_activity_logging"
    value = "true"
  }

  parameter {
    name  = "auto_analyze"
    value = "true"
  }

  parameter {
    name  = "auto_vacuum"
    value = "true"
  }

  parameter {
    name  = "search_path"
    value = "public,staging,marts"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-redshift-parameter-group"
  })
}

# -----------------------------------------------------------------------------
# Security Group for Redshift
# -----------------------------------------------------------------------------

resource "aws_security_group" "redshift" {
  name        = "${var.project_name}-${var.environment}-redshift-sg"
  description = "Security group for Redshift cluster"
  vpc_id      = var.vpc_id

  ingress {
    description = "Redshift access from VPC"
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description     = "Redshift access from Airflow"
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = [var.airflow_security_group_id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-redshift-sg"
  })
}

# -----------------------------------------------------------------------------
# KMS Key for Redshift Encryption
# -----------------------------------------------------------------------------

resource "aws_kms_key" "redshift" {
  count = var.enable_encryption ? 1 : 0

  description             = "KMS key for Redshift encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-redshift-kms-key"
  })
}

resource "aws_kms_alias" "redshift" {
  count = var.enable_encryption ? 1 : 0

  name          = "alias/${var.project_name}-${var.environment}-redshift"
  target_key_id = aws_kms_key.redshift[0].key_id
}

# -----------------------------------------------------------------------------
# Redshift Cluster
# -----------------------------------------------------------------------------

resource "aws_redshift_cluster" "main" {
  cluster_identifier      = var.cluster_identifier
  database_name          = var.database_name
  master_username        = var.master_username
  master_password        = var.master_password
  node_type              = var.node_type
  number_of_nodes        = var.number_of_nodes
  port                   = var.port
  
  # Network configuration
  cluster_subnet_group_name = aws_redshift_subnet_group.main.name
  vpc_security_group_ids    = [aws_security_group.redshift.id]
  publicly_accessible       = false
  enhanced_vpc_routing      = var.enhanced_vpc_routing

  # Backup configuration
  automated_snapshot_retention_period = var.backup_retention_period
  skip_final_snapshot                 = var.skip_final_snapshot
  final_snapshot_identifier          = var.skip_final_snapshot ? null : "${var.cluster_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  # Maintenance configuration
  preferred_maintenance_window = var.maintenance_window
  
  # Parameter group
  cluster_parameter_group_name = aws_redshift_parameter_group.main.name
  
  # Encryption
  encrypted  = var.enable_encryption
  kms_key_id = var.enable_encryption ? aws_kms_key.redshift[0].arn : null
  
  # Monitoring
  enable_logging = true
  logging {
    enable        = true
    bucket_name   = var.logging_bucket_name
    s3_key_prefix = "redshift-logs/"
  }
  
  # IAM roles
  iam_roles = [var.redshift_service_role_arn]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-redshift-cluster"
  })

  depends_on = [
    aws_redshift_subnet_group.main,
    aws_redshift_parameter_group.main,
    aws_security_group.redshift
  ]
}

# -----------------------------------------------------------------------------
# Redshift Scheduled Actions (for auto-scaling)
# -----------------------------------------------------------------------------

resource "aws_redshift_scheduled_action" "pause_cluster" {
  count = var.enable_auto_pause ? 1 : 0

  name        = "${var.project_name}-${var.environment}-pause-cluster"
  description = "Pause Redshift cluster during off-hours"
  schedule    = var.pause_schedule
  iam_role    = var.redshift_scheduler_role_arn

  target_action {
    pause_cluster {
      cluster_identifier = aws_redshift_cluster.main.cluster_identifier
    }
  }

  depends_on = [aws_redshift_cluster.main]
}

resource "aws_redshift_scheduled_action" "resume_cluster" {
  count = var.enable_auto_pause ? 1 : 0

  name        = "${var.project_name}-${var.environment}-resume-cluster"
  description = "Resume Redshift cluster during work hours"
  schedule    = var.resume_schedule
  iam_role    = var.redshift_scheduler_role_arn

  target_action {
    resume_cluster {
      cluster_identifier = aws_redshift_cluster.main.cluster_identifier
    }
  }

  depends_on = [aws_redshift_cluster.main]
}

# -----------------------------------------------------------------------------
# Redshift Event Subscription
# -----------------------------------------------------------------------------

resource "aws_redshift_event_subscription" "main" {
  name      = "${var.project_name}-${var.environment}-redshift-events"
  sns_topic = var.sns_topic_arn

  source_type = "cluster"
  source_ids  = [aws_redshift_cluster.main.cluster_identifier]

  severity = "ERROR"

  event_categories = [
    "configuration",
    "management",
    "monitoring",
    "security"
  ]

  enabled = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-redshift-event-subscription"
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms for Redshift
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "${var.project_name}-${var.environment}-redshift-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/Redshift"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors redshift cpu utilization"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    ClusterIdentifier = aws_redshift_cluster.main.cluster_identifier
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  alarm_name          = "${var.project_name}-${var.environment}-redshift-database-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/Redshift"
  period              = "300"
  statistic           = "Average"
  threshold           = "40"
  alarm_description   = "This metric monitors redshift database connections"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    ClusterIdentifier = aws_redshift_cluster.main.cluster_identifier
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "health_status" {
  alarm_name          = "${var.project_name}-${var.environment}-redshift-health-status"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthStatus"
  namespace           = "AWS/Redshift"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors redshift health status"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    ClusterIdentifier = aws_redshift_cluster.main.cluster_identifier
  }

  tags = var.common_tags
}

# -----------------------------------------------------------------------------
# Redshift Usage Limits
# -----------------------------------------------------------------------------

resource "aws_redshift_usage_limit" "concurrency_scaling" {
  count = var.enable_concurrency_scaling ? 1 : 0

  cluster_identifier = aws_redshift_cluster.main.cluster_identifier
  feature_type       = "concurrency-scaling"
  limit_type         = "time"
  amount             = var.concurrency_scaling_max_time
  period             = "monthly"

  breach_action = "log"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-concurrency-scaling-limit"
  })
}

resource "aws_redshift_usage_limit" "spectrum" {
  count = var.enable_spectrum_limit ? 1 : 0

  cluster_identifier = aws_redshift_cluster.main.cluster_identifier
  feature_type       = "spectrum"
  limit_type         = "data-scanned"
  amount             = var.spectrum_data_limit_tb
  period             = "monthly"

  breach_action = "log"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-spectrum-limit"
  })
}

# -----------------------------------------------------------------------------
# Redshift Snapshot Configuration
# -----------------------------------------------------------------------------

resource "aws_redshift_snapshot_copy_grant" "main" {
  count = var.enable_cross_region_snapshots ? 1 : 0

  snapshot_copy_grant_name = "${var.project_name}-${var.environment}-snapshot-copy-grant"
  kms_key_id              = var.enable_encryption ? aws_kms_key.redshift[0].arn : null

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-snapshot-copy-grant"
  })
}

# -----------------------------------------------------------------------------
# Redshift Workload Management (WLM) Configuration
# -----------------------------------------------------------------------------

resource "aws_redshift_parameter_group" "wlm_config" {
  name   = "${var.project_name}-${var.environment}-wlm-config"
  family = "redshift-1.0"

  parameter {
    name  = "wlm_json_configuration"
    value = jsonencode([
      {
        query_group                = "default"
        query_group_wild_card      = 0
        user_group                 = "default"
        user_group_wild_card       = 0
        concurrency_level          = 5
        memory_percent_to_use      = 15
        max_execution_time         = 0
        query_timeout              = 0
      },
      {
        query_group                = "analytics"
        query_group_wild_card      = 0
        user_group                 = "analytics_users"
        user_group_wild_card       = 0
        concurrency_level          = 3
        memory_percent_to_use      = 30
        max_execution_time         = 0
        query_timeout              = 7200
      },
      {
        query_group                = "etl"
        query_group_wild_card      = 0
        user_group                 = "etl_users"
        user_group_wild_card       = 0
        concurrency_level          = 2
        memory_percent_to_use      = 40
        max_execution_time         = 0
        query_timeout              = 14400
      },
      {
        query_group                = "admin"
        query_group_wild_card      = 0
        user_group                 = "admin_users"
        user_group_wild_card       = 0
        concurrency_level          = 1
        memory_percent_to_use      = 15
        max_execution_time         = 0
        query_timeout              = 0
      }
    ])
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-wlm-config"
  })
}