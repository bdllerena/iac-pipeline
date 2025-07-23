terraform {
  backend "s3" {
    bucket         = "kashio-iac-terraform-statefiles-dev"
    key            = "ecs/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}