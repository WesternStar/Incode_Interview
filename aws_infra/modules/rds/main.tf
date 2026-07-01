resource "aws_security_group" "this" {
  name        = "${var.identifier}-sg"
  description = "Allow database access from allowed security groups"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.identifier}-sg" })
}

resource "aws_security_group_rule" "ingress_from_allowed" {
  for_each = toset(var.allowed_security_group_ids)

  description              = "Allow database access from ${each.value}"
  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = each.value
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnets"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, { Name = "${var.identifier}-subnets" })
}

resource "random_password" "master" {
  length  = 20
  special = false
}

resource "aws_db_instance" "this" {
  identifier     = var.identifier
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type
  storage_encrypted = var.kms_key_id != null
  kms_key_id        = var.kms_key_id
  db_name           = var.db_name
  username          = var.username
  password          = random_password.master.result
  port              = var.port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  multi_az                = var.multi_az
  publicly_accessible     = var.publicly_accessible
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot
  deletion_protection     = var.deletion_protection

  tags = merge(var.tags, { Name = var.identifier })
}
