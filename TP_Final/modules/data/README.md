# Module `data` — Rôle 4

**GRP2 — Akram · Ayoub · Raphael · Pierrick**

## Périmètre

Ce module construit la couche données de Nextcloud (Kolab) :

| Ressource | Détail |
|-----------|--------|
| `aws_db_subnet_group.nextcloud` | 2 subnets DB privés (Multi-AZ) |
| `aws_db_parameter_group.nextcloud` | PG16 : SSL forcé + logs connexions |
| `aws_db_instance.nextcloud` | RDS PG16, db.t3.micro, Multi-AZ, SSE-KMS |
| `aws_s3_bucket.primary` | Stockage fichiers Nextcloud |
| `aws_s3_bucket.logs` | ALB access logs (pour Rôle 3) |

## Nommage

Tous les noms de ressources sont préfixés `grp2-` pour éviter
les collisions avec les autres groupes sur le même compte AWS.

Exemple : `grp2-kolab-dev-nextcloud-primary`

## Dépendances entre rôles

```
Rôle 1 (bootstrap) ──→ bucket S3 state + KMS backend
Rôle 2 (networking) ──→ private_db_subnet_ids
Rôle 5 (security)   ──→ kms_key_arn + db_password_secret_arn + db_security_group_id
                              ↓
                    [ Rôle 4 — DATA ]
                              ↓
Rôle 3 (ALB/compute) consomme s3_logs_bucket_name/arn
Rôle 6 (app)         consomme db_endpoint, db_port, db_name, s3_primary_bucket_name
```

## Utilisation

```hcl
module "data" {
  source = "./modules/data"

  vpc_id                 = module.networking.vpc_id
  private_db_subnet_ids  = module.networking.private_db_subnet_ids
  db_security_group_id   = module.security.db_security_group_id
  kms_key_arn            = module.security.kms_key_arn
  db_password_secret_arn = module.security.db_password_secret_arn

  project_name = "kolab"
  environment  = "dev"
}
```

## Outputs publiés

| Output | Description |
|--------|-------------|
| `db_endpoint` | Hostname RDS (sans port) |
| `db_port` | 5432 |
| `db_name` | `nextcloud` |
| `db_username` | `ncadmin` |
| `s3_primary_bucket_name` | Nom du bucket primary |
| `s3_primary_bucket_arn` | ARN du bucket primary |
| `s3_logs_bucket_name` | Nom du bucket logs |
| `s3_logs_bucket_arn` | ARN du bucket logs |
