resource "aws_ecr_repository" "this" {
  name                 = "${var.name_prefix}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project     = var.name_prefix
    Environment = "dev"
  }
}
