resource "aws_security_group_rule" "rds_ingress_from_eks_nodes" {
  description              = "Allow Postgres access from EKS worker nodes"
  type                      = "ingress"
  from_port                 = 5432
  to_port                   = 5432
  protocol                  = "tcp"
  security_group_id         = aws_security_group.rds.id
  source_security_group_id  = module.eks.node_security_group_id
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "${var.project_name}-db-subnets"
  }
}

resource "random_password" "db_master" {
  length  = 20
  special = false
}

resource "aws_db_instance" "this" {
  identifier     = "${var.project_name}-db"
  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  storage_type          = "gp3"
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.db_master.result
  port                   = 5432

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

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
