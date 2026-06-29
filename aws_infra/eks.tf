module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = "${var.project_name}-eks"
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Cost control: skip a managed NAT/EIP-per-AZ control plane log bucket etc.
  # by only enabling the public endpoint (no private VPN/Direct Connect needed
  # for this demo) while still restricting it implicitly via security groups.
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]
      capacity_type  = "ON_DEMAND"

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # gp3 is cheaper than gp2 for the same performance.
      disk_size = 20

      labels = {
        role = "general"
      }
    }
  }

  tags = {
    Name = "${var.project_name}-eks"
  }
}
