# main.tf (version registry)
data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.5"

  name = "${local.name_prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  public_subnets  = [for idx, _ in var.azs : cidrsubnet(var.vpc_cidr, 8, idx + 1)]
  private_subnets = [for idx, _ in var.azs : cidrsubnet(var.vpc_cidr, 8, idx + 101)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags  = { Tier = "public" }
  private_subnet_tags = { Tier = "private" }
}
