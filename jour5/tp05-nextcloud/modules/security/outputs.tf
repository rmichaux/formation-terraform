output "alb_security_group_id" {
  value = aws_security_group.alb.id
}
output "app_security_group_id" {
  value = aws_security_group.app.id
}
output "db_security_group_id" {
  value = aws_security_group.db.id
}
output "kms_key_id" {
  value = aws_kms_key.main.id
}
output "kms_key_arn" {
  value = aws_kms_key.main.arn
}
output "app_instance_profile_name" {
  value = aws_iam_instance_profile.app.name
}
output "app_iam_role_arn" {
  value = aws_iam_role.app.arn
}
output "db_password_secret_arn" {
  value = aws_secretsmanager_secret.db_password.arn
}
output "admin_password_secret_arn" {
  value = aws_secretsmanager_secret.admin_password.arn
}
