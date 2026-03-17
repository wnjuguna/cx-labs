terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Name       = var.thing_name
      owner      = var.user
      created_by = "terraform"
      type       = var.lab_type
      cx_team    = var.cx_team_name
      repo       = "https://github.com/BigRedS/cx-labs.git"
    }
  }
}
