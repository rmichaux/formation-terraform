variable "project_name" {
  description = "Nom du projet"
  type        = string
}
variable "environment" {
  description = "Environnement"
  type        = string
}
variable "vpc_id" {
  description = "ID du VPC"
  type        = string
}
variable "vpc_cidr" {
  description = "CIDR du VPC"
  type        = string
}
variable "s3_primary_bucket_arn" {
  description = "ARN bucket S3 primary"
  type        = string
}
variable "s3_logs_bucket_arn" {
  description = "ARN bucket S3 logs"
  type        = string
}
variable "allowed_admin_cidr" {
  description = "CIDR admin"
  type        = string
  default     = "0.0.0.0/0"
}
