terraform {
  backend "s3" {
    bucket         = "devsu-test-terraform-state-bucket"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    profile        = "devsu-terraform"
  }
}