data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = var.infra_state_path
  }
}

locals {
  cluster_name     = data.terraform_remote_state.infra.outputs.eks_cluster_name
  cluster_endpoint = data.terraform_remote_state.infra.outputs.eks_cluster_endpoint
  cluster_ca_data  = data.terraform_remote_state.infra.outputs.eks_cluster_certificate_authority_data
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = base64decode(local.cluster_ca_data)

  # Use the AWS CLI to mint a short-lived auth token instead of pulling in
  # the AWS Terraform provider here -- keeps this config's only dependency
  # on AWS being the `aws` CLI itself, so it stays fully decoupled from the
  # infra/ AWS provisioning config.
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--region", var.aws_region, "--cluster-name", local.cluster_name]
  }
}
