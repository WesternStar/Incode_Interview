module "ecr" {
  source = "./modules/ecr"

  repository_name = "${var.project_name}-demo-app"

  tags = {
    Name = "${var.project_name}-demo-app"
  }
}
