provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      Environment = "shared"
      Project     = "adria-stay"
      ManagedBy   = "terraform"
      Owner       = "romano-pavan"
    }
  }
}

