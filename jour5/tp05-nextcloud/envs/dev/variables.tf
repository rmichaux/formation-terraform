variable "aws_region" {
  type    = string
  default = "eu-west-3"
}

variable "allowed_admin_cidr" {
  type = string
}

variable "project_name" {
  type    = string
  default = "TP-PMONNIER"
}

variable "environment" {
  type    = string
  default = "dev"
}
