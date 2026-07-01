resource "aws_ecr_repository" "demo_app" {
  name                 = "${var.project_name}-demo-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-demo-app"
  }
}
