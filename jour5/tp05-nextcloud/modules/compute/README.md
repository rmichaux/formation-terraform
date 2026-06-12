# Module compute

ALB + Auto Scaling Group + Launch Template pour Nextcloud en Docker.

## Usage

```hcl
module "compute" {
  source = "../../modules/compute"

  project_name = "kolab"
  environment  = "dev"

  vpc_id                    = module.networking.vpc_id
  public_subnet_ids         = module.networking.public_subnet_ids
  private_app_subnet_ids    = module.networking.private_app_subnet_ids
  alb_security_group_id     = module.security.alb_security_group_id
  app_security_group_id     = module.security.app_security_group_id
  app_instance_profile_name = module.security.app_instance_profile_name
  db_endpoint               = module.data.db_endpoint
  db_name                   = module.data.db_name
  db_username               = module.data.db_username
  db_password_secret_arn    = module.security.db_password_secret_arn
  admin_password_secret_arn = module.security.admin_password_secret_arn
  s3_primary_bucket_name    = module.data.s3_primary_bucket_name
  s3_logs_bucket_name       = module.data.s3_logs_bucket_name
}
```

## Inputs

| Name | Type | Description |
|------|------|-------------|
| vpc_id | string | ID du VPC |
| public_subnet_ids | map(string) | Subnets publics pour l'ALB |
| private_app_subnet_ids | map(string) | Subnets prives pour l'ASG |
| alb_security_group_id | string | SG de l'ALB |
| app_security_group_id | string | SG des EC2 applicatives |
| app_instance_profile_name | string | Instance profile IAM |
| db_endpoint | string | Hostname RDS |
| db_name | string | Nom de la base |
| db_username | string | Utilisateur DB |
| db_password_secret_arn | string | ARN secret mot de passe DB |
| admin_password_secret_arn | string | ARN secret admin Nextcloud |
| s3_primary_bucket_name | string | Bucket S3 storage Nextcloud |
| s3_logs_bucket_name | string | Bucket S3 access logs ALB |
| project_name | string | Nom du projet (defaut: kolab) |
| environment | string | Environnement (defaut: dev) |
| instance_type | string | Type instance EC2 (defaut: t3.small) |

## Outputs

| Name | Description |
|------|-------------|
| alb_dns_name | DNS public de l'ALB |
| alb_zone_id | Zone Route53 alias de l'ALB |
| asg_name | Nom de l'ASG |
| nextcloud_url | URL HTTPS de Nextcloud |
