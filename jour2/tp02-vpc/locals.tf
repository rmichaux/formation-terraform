# locals.tf
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Map AZ -> CIDR public (10.0.1.0/24, 10.0.2.0/24, ...)
  public_subnets = {
    for idx, az in var.azs : az => cidrsubnet(var.vpc_cidr, 8, idx + 1)
  }

  # Map AZ -> CIDR prive (10.0.101.0/24, 10.0.102.0/24, ...)
  private_subnets = {
    for idx, az in var.azs : az => cidrsubnet(var.vpc_cidr, 8, idx + 101)
  }
}
