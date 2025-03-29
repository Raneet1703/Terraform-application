terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.92.0"
    }
  }

  backend "s3" {
    bucket = "mystatebuckettodelete"   # S3 bucket name
    key    = "mykey/statefile.tfstate" # Path within the bucket where the state file will be stored
    region = "us-east-1"               # AWS region where your S3 bucket is located
  }
}

provider "aws" {
  region = "us-east-1"
}