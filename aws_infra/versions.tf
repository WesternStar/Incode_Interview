terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Local state file is read by the k8s/ config via `terraform_remote_state`.
  # Swap this for an S3/DynamoDB backend (and update the data source in
  # k8s/providers.tf to match) for real environments.
  backend "local" {
    path = "terraform.tfstate"
  }
}
