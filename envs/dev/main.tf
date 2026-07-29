module "network" {
  source      = "../../modules/network"
  name_prefix = "adria-stay-dev"
  vpc_cidr    = "10.0.0.0/16"
}


