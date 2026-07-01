module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  cluster_endpoint_public_access  = var.endpoint_public_access
  cluster_endpoint_private_access = var.endpoint_private_access

  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]
      capacity_type  = var.node_capacity_type

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # Setting block_device_mappings makes the module use a custom launch
      # template, which is required to encrypt the node root volume — the
      # plain `disk_size` argument only ever configures an unencrypted
      # volume via the EKS API directly.
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.node_disk_size
            volume_type           = "gp3"
            encrypted             = var.node_disk_kms_key_id != null
            kms_key_id            = var.node_disk_kms_key_id
            delete_on_termination = true
          }
        }
      }

      labels = var.node_labels
    }
  }

  tags = merge(var.tags, { Name = var.cluster_name })
}
