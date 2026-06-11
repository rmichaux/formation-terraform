# envs/dev/variables.tf
variable "aws_region" {
  type        = string
  description = "Region AWS de deploiement"
  default     = "eu-west-3"
}
