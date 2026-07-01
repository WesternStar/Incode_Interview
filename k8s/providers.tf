data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = var.infra_state_path
  }
}

locals {
  cluster_name       = data.terraform_remote_state.infra.outputs.eks_cluster_name
  cluster_endpoint   = data.terraform_remote_state.infra.outputs.eks_cluster_endpoint
  cluster_ca_data    = data.terraform_remote_state.infra.outputs.eks_cluster_certificate_authority_data
  ecr_repository_url = data.terraform_remote_state.infra.outputs.ecr_repository_url
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = base64decode(local.cluster_ca_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--region", var.aws_region, "--cluster-name", local.cluster_name]
  }
}

# Helm uses the same exec-plugin auth as the kubernetes provider — no AWS
# Terraform provider required in this config.
provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = base64decode(local.cluster_ca_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--region", var.aws_region, "--cluster-name", local.cluster_name]
    }
  }
}
