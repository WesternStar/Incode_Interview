module "eks" {
  source = "./modules/eks"

  cluster_name    = "${var.project_name}-eks"
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Cost control: skip a managed NAT/EIP-per-AZ control plane log bucket etc.
  # by only enabling the public endpoint (no private VPN/Direct Connect needed
  # for this demo) while still restricting it implicitly via security groups.
  endpoint_public_access  = true
  endpoint_private_access = true

  enable_cluster_creator_admin_permissions = true

  node_instance_type   = var.node_instance_type
  node_min_size        = var.node_min_size
  node_max_size        = var.node_max_size
  node_desired_size    = var.node_desired_size
  node_disk_size       = var.node_disk_size
  node_disk_kms_key_id = aws_kms_key.ebs.arn

  node_labels = {
    role = "general"
  }

  tags = {
    Name = "${var.project_name}-eks"
  }
}
