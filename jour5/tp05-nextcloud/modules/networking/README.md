# modules/networking

VPC 10.30.0.0/16 + 6 subnets sur 2 AZ + NAT Gateway + VPC Endpoints.

## Inputs

- project_name
- environment
- vpc_cidr
- azs

## Outputs

- vpc_id
- vpc_cidr
- public_subnet_ids
- private_app_subnet_ids
- private_db_subnet_ids
- nat_gateway_public_ip
- vpc_endpoints_security_group_id
