provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  region   = "us-east-1"
  name     = "atrato"
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
}
