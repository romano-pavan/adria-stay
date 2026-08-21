provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      Environment = "dev"
      Project     = "adria-stay"
      ManagedBy   = "terraform"
      Owner       = "Romano-Pavan"
    }
  }
}