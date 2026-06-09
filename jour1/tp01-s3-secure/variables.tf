variable "bucket_prefix" {
  type        = string
  description = "Préfixe appliqué au nom du bucket S3"
  default     = "formation-tp01"
}

variable "environment" {
  type        = string
  description = "Environnement de déploiement"
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit être dev, staging ou prod."
  }
}

variable "owner" {
  type        = string
  description = "Email de l'owner du bucket"
  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.owner))
    error_message = "owner doit être un email valide."
  }
}
