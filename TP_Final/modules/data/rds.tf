# ==============================================================
# modules/data/rds.tf
# GRP2 - Akram Ayoub Raphael Pierrick
# RDS PostgreSQL 16 Multi-AZ chiffré KMS
# Nommage : grp2-<project>-<env>-* pour éviter les collisions
# ==============================================================

# ---------------------------------------------------------------
# Data source : mot de passe DB depuis Secrets Manager (Rôle 5)
# ---------------------------------------------------------------
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = var.db_password_secret_arn
}

# ---------------------------------------------------------------
# DB Subnet Group - regroupe les 2 subnets privés DB (2 AZ)
# ---------------------------------------------------------------
resource "aws_db_subnet_group" "nextcloud" {
  name        = "grp2-${var.project_name}-${var.environment}-db-subnet-group"
  description = "Subnet group RDS Multi-AZ - GRP2 ${var.project_name} ${var.environment}"
  subnet_ids  = values(var.private_db_subnet_ids)

  tags = {
    Name        = "grp2-${var.project_name}-${var.environment}-db-subnet-group"
    Project     = var.project_name
    Environment = var.environment
    Team        = "GRP2-Akram-Ayoub-Raphael-Pierrick"
    ManagedBy   = "terraform"
    Role        = "data"
  }
}

# ---------------------------------------------------------------
# DB Parameter Group (BONUS) - active SSL et logs PG
# ---------------------------------------------------------------
resource "aws_db_parameter_group" "nextcloud" {
  name        = "grp2-${var.project_name}-${var.environment}-pg16"
  family      = "postgres16"
  description = "Parametres PG16 Nextcloud - GRP2"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = {
    Name        = "grp2-${var.project_name}-${var.environment}-pg16"
    Project     = var.project_name
    Environment = var.environment
    Team        = "GRP2-Akram-Ayoub-Raphael-Pierrick"
    ManagedBy   = "terraform"
    Role        = "data"
  }
}

# ---------------------------------------------------------------
# RDS Instance - PostgreSQL 16 Multi-AZ chiffré KMS
# ---------------------------------------------------------------
resource "aws_db_instance" "nextcloud" {
  identifier = "grp2-${var.project_name}-${var.environment}-nextcloud"

  # Moteur
  engine         = "postgres"
  engine_version = var.db_engine_version

  # Taille
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"

  # Base logique
  db_name  = "nextcloud"
  username = "ncadmin"
  password = data.aws_secretsmanager_secret_version.db_password.secret_string

  # Chiffrement KMS (clé gérée par Rôle 5)
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  # Haute dispo
  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.nextcloud.name
  parameter_group_name   = aws_db_parameter_group.nextcloud.name
  vpc_security_group_ids = [var.db_security_group_id]

  # Maintenance & backups
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Dev : pas de snapshot final pour pouvoir destroy proprement
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name        = "grp2-${var.project_name}-${var.environment}-nextcloud"
    Project     = var.project_name
    Environment = var.environment
    Team        = "GRP2-Akram-Ayoub-Raphael-Pierrick"
    ManagedBy   = "terraform"
    Role        = "data"
  }
}
