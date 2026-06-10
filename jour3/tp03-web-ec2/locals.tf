# locals.tf
locals {
  name_prefix = "etudiant20"

  # Map AZ -> CIDR public (10.0.1.0/24, 10.0.2.0/24, ...)
  public_subnets = {
    for idx, az in var.azs : az => cidrsubnet(var.vpc_cidr, 8, idx + 1)
  }

  # Map AZ -> CIDR prive (10.0.101.0/24, 10.0.102.0/24, ...)
  private_subnets = {
    for idx, az in var.azs : az => cidrsubnet(var.vpc_cidr, 8, idx + 101)
  }
}

# locals.tf — ajout TP03

locals {
  # ... locaux existants du TP02 (name_prefix, public_subnets, private_subnets) ...

  # Map AZ -> subnet_id prive, consommee par for_each sur aws_instance.web.
  web_subnets = { for k, s in aws_subnet.private : k => s.id }
}
