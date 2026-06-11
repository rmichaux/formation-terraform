# envs/dev/providers.tf
# Provider AWS pour l environnement dev.
# default_tags s applique automatiquement a toutes les ressources creees (y compris
# celles du module vpc qui herite de ce provider).

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "formation-terraform"
      Module      = "tp04-multi-env"
      ManagedBy   = "Terraform"
      Environment = "staging"
    }
  }
}
