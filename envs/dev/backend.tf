terraform {
  backend "s3" {
    bucket       = "adria-stay-tfstate-rp"
    key          = "envs/dev/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}