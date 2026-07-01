variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "EKS control plane version"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy the cluster into"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS control plane ENIs and worker nodes"
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Whether the EKS public API endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Whether the EKS private API endpoint is enabled"
  type        = bool
  default     = true
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Add the cluster creator (the identity running Terraform) as an administrator via access entry"
  type        = bool
  default     = true
}

variable "node_instance_type" {
  description = "Instance type for the EKS managed node group"
  type        = string
}

variable "node_capacity_type" {
  description = "Capacity type for the node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
}

variable "node_disk_size" {
  description = "Root EBS volume size (GiB) for worker nodes"
  type        = number
}

variable "node_disk_kms_key_id" {
  description = "KMS key ARN used to encrypt worker node root EBS volumes. If not set, volumes are left unencrypted."
  type        = string
  default     = null
}

variable "node_labels" {
  description = "Kubernetes labels applied to nodes in the managed node group"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to the cluster and its resources"
  type        = map(string)
  default     = {}
}
