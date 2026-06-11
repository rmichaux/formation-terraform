# envs/dev/main.tf
# Appel du module VPC avec les parametres de l environnement dev.

module "vpc" {
  source = "../../modules/vpc"

  environment          = "staging"
  project_name         = "formation"
  vpc_cidr             = "10.20.0.0/16"
  azs                  = ["eu-west-3a", "eu-west-3b"]
  bastion_allowed_cidr = "0.0.0.0/0"
}
