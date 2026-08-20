module "network" {
  source        = "../../modules/network"
  name_prefix   = "adria-stay-dev"
  vpc_cidr      = "10.0.0.0/16"
  public_a_cidr = "10.0.0.0/24"
  public_b_cidr = "10.0.1.0/24"
  app_a_cidr    = "10.0.10.0/24"
  app_b_cidr    = "10.0.11.0/24"
  data_a_cidr   = "10.0.20.0/24"
  data_b_cidr   = "10.0.21.0/24"
}

module "compute" {
  source            = "../../modules/compute"
  name_prefix       = "adria-stay-dev"
  vpc_id            = module.network.vpc_id
  alb_ingress_cidr  = "0.0.0.0/0"
  public_subnet_ids = module.network.public_subnet_ids
  app_subnet_ids    = module.network.app_subnet_ids
}

