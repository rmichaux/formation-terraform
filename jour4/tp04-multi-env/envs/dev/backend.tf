# envs/dev/backend.tf
# Backend S3 natif : state stocke dans s3://tf-state-USERNAME-formation/envs/dev/vpc/terraform.tfstate
# use_lockfile = true utilise le lock S3 natif (TF >= 1.10), pas besoin de DynamoDB.

terraform {
  backend "s3" {
    bucket       = "tf-state-etudiant20-formation" # <-- a adapter a votre bucket
    key          = "envs/dev/vpc/terraform.tfstate"
    region       = "eu-west-3"
    encrypt      = true
    use_lockfile = true
  }
}
