# modules/vpc/variables.tf
# Interface publique du module VPC.
# Pas de default sur environment/project_name/vpc_cidr : l appelant DOIT choisir.

variable "environment" {
  type        = string
  description = "Environnement de deploiement (dev, staging, prod)"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit etre dev, staging ou prod."
  }
}

variable "project_name" {
  type        = string
  description = "Prefixe applique aux noms de ressources"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR du VPC (ex: 10.10.0.0/16)"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr doit etre un CIDR valide (ex: 10.10.0.0/16)."
  }
}

variable "azs" {
  type        = list(string)
  description = "Liste des AZ a utiliser (minimum 2 pour la HA)"
  default     = ["eu-west-3a", "eu-west-3b"]

  validation {
    condition     = length(var.azs) >= 2
    error_message = "Au moins 2 AZ requises pour la HA."
  }
}

variable "bastion_allowed_cidr" {
  type        = string
  description = "CIDR autorise en SSH sur le bastion (jamais 0.0.0.0/0 en prod)"
  default     = "0.0.0.0/0"
}
