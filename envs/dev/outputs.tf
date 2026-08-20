output "vpc_id" {
  description = "id for vpc "
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = " IDs of the public subnet"
  value       = module.network.public_subnet_ids
}

output "app_subnet_ids" {
  description = "IDs of the private application subnets"
  value       = module.network.app_subnet_ids
}

output "data_subnet_ids" {
  description = "IDs of the private data subnet"
  value       = module.network.data_subnet_ids
}

output "alb_dns_name" {
  value = module.compute.alb_dns_name

}