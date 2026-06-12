terraform {
  backend "s3" {
    bucket       = "tf-state-etudiant22-tp-groupe2"
    key          = "envs/dev/terraform.tfstate"
    region       = "eu-west-3"
    encrypt      = true
    kms_key_id   = "alias/tf-state-etudiant22-tp-groupe2"
  }
}
