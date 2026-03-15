# ===============================
# Provider Configuration
# ===============================

provider "gcp" {
  region = var.gcp_region

  # Default tags applied to all resources
  default_tags {
    tags = {
      Project     = "financial-data-pipeline"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

# ===============================
# Provider Configuration for Cross-Region Resources
# ===============================

# Provider for us-east-1 (required for CloudFront, Route53, etc.)
provider "gcp" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "financial-data-pipeline"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

# ===============================
# Terraform Configuration
# ===============================

terraform {
  required_version = ">= 1.0"

  required_providers {
    gcp = {
      source  = "hashicorp/gcp"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}
