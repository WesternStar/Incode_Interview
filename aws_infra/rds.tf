module "rds" {
  source = "./modules/rds"

  identifier     = "${var.project_name}-db"
  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  db_name           = var.db_name
  username          = var.db_username

  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnets
  allowed_security_group_ids = [module.eks.node_security_group_id]

  kms_key_id = aws_kms_key.rds.arn

  # Cost / demo-friendly settings: single-AZ, no read replica, short backup
  # retention, and skip the final snapshot so `terraform destroy` is clean.
  multi_az                = false
  publicly_accessible     = false
  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = {
    Name = "${var.project_name}-db"
  }
}
