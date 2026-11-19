terraform {
  backend "s3" {
    bucket       = "event-driven-order-platform"
    key          = "dev/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}