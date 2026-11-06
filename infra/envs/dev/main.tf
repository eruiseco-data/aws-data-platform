terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
  backend "s3" {
    bucket       = "erik-adp-tfstate-12342234"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags { tags = { project = "aws-data-platform", env = "dev" } }
}

resource "aws_s3_bucket" "landing" {
    bucket = "erik-adp-landing-12342234"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "landing" {
    bucket = aws_s3_bucket.landing.id

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}

resource "aws_s3_bucket_public_access_block" "landing" {
    bucket = aws_s3_bucket.landing.id

    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}