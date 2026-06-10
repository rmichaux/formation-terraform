# main.tf

# -----------------------------------------------------------------------------
# AMI Amazon Linux 2023 (derniere version officielle)
# -----------------------------------------------------------------------------
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# -----------------------------------------------------------------------------
# Key Pair : votre cle publique SSH locale
# AWS la deposera automatiquement dans ~/.ssh/authorized_keys de chaque EC2.
# -----------------------------------------------------------------------------
resource "aws_key_pair" "formation" {
  key_name   = "etudiant20-key"
  public_key = file(pathexpand(var.public_key_path))

  tags = {
    Name = "${local.name_prefix}-key"
  }
}

# -----------------------------------------------------------------------------
# Security Group : instances web
# Accepte SSH et HTTP UNIQUEMENT depuis le SG bastion (pas depuis un CIDR).
# Egress all pour que yum/dnf puisse installer nginx via NAT.
# -----------------------------------------------------------------------------
resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Allow SSH/HTTP from bastion SG only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-web-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_ssh" {
  security_group_id            = aws_security_group.web.id
  description                  = "SSH depuis le bastion"
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id
}

resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id            = aws_security_group.web.id
  description                  = "HTTP depuis le bastion"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id
}

resource "aws_vpc_security_group_egress_rule" "web_all" {
  security_group_id = aws_security_group.web.id
  description       = "Egress all (yum/nginx updates)"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# -----------------------------------------------------------------------------
# EC2 bastion (subnet public AZ-a)
# Seul point d'entree SSH vers les instances privees.
# -----------------------------------------------------------------------------
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[var.azs[0]].id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = aws_key_pair.formation.key_name

  # Sur aws_instance c'est associate_public_ip_address (PAS _on_launch,
  # _on_launch etant l'attribut de aws_subnet).
  associate_public_ip_address = true

  tags = {
    Name = "${local.name_prefix}-bastion"
    Role = "bastion"
    Owner = "etudiant20"
  }
}

# -----------------------------------------------------------------------------
# EIP bastion : IP publique stable (survit aux reboots)
# -----------------------------------------------------------------------------
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = {
    Name = "${local.name_prefix}-bastion-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# EC2 web (subnets prives, 1 par AZ via for_each sur map AZ->subnet_id)
# user_data rend une page nginx qui identifie l'AZ de l'instance.
# -----------------------------------------------------------------------------
resource "aws_instance" "web" {
  for_each = local.web_subnets

  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = each.value
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.formation.key_name

  # Template nginx + variable AZ passee au shell
  user_data = templatefile("${path.module}/templates/nginx.sh.tftpl", {
    az = each.key
  })

  # Si le user_data change, on recree l'instance (nginx reinstalle)
  user_data_replace_on_change = true

  # Cree la nouvelle avant de detruire l'ancienne (zero downtime applicatif)
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.name_prefix}-web-${each.key}"
    Role = "web"
    Owner = "etudiant20"
    AZ   = each.key
  }
}
