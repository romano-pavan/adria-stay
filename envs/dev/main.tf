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


