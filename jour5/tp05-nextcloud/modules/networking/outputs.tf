output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "private_db_subnet_ids" {
  value = { for k, s in aws_subnet.private_db : k => s.id }
}

output "private_app_subnet_ids" {
  value = { for k, s in aws_subnet.private_app : k => s.id }
}

output "public_subnet_ids" {
  value = { for k, s in aws_subnet.public : k => s.id }
}
