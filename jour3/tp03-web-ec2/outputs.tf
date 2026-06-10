# outputs.tf

output "bastion_public_ip" {
  value       = aws_eip.bastion.public_ip
  description = "IP publique elastique du bastion"
}

output "bastion_public_dns" {
  value       = aws_instance.bastion.public_dns
  description = "DNS public du bastion"
}

output "web_private_ips" {
  value       = { for k, inst in aws_instance.web : k => inst.private_ip }
  description = "Map AZ -> IP privee des EC2 web"
}

output "web_instance_ids" {
  value       = { for k, inst in aws_instance.web : k => inst.id }
  description = "Map AZ -> ID instance EC2 web"
}

output "ssh_bastion_command" {
  value       = "ssh -i ~/.ssh/id_rsa -A ec2-user@${aws_eip.bastion.public_ip}"
  description = "Commande SSH pour rejoindre le bastion (agent forwarding -A)"
}
