module "vpc" {
  source = "./modules/vpc"

  name     = "${var.project_name}-vpc"
  cidr     = var.vpc_cidr
  az_count = var.az_count

  # Single NAT gateway keeps cost down; not highly available but fine for a demo.
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # Tags required for EKS / ELB auto-discovery of subnets.
  public_subnet_tags = {
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
  }

  tags = {
    Name = "${var.project_name}-vpc"
  }
}
