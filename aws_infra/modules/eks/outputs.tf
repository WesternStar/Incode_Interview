output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded cluster CA certificate"
  value       = module.eks.cluster_certificate_authority_data
}

output "node_security_group_id" {
  description = "Security group ID attached to EKS worker nodes"
  value       = module.eks.node_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the cluster's IAM OIDC provider, for IRSA trust policies"
  value       = module.eks.oidc_provider_arn
}

output "cluster_oidc_issuer_url" {
  description = "URL of the cluster's OIDC issuer, for IRSA trust policies"
  value       = module.eks.cluster_oidc_issuer_url
}
