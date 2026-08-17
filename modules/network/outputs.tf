output "vpc_id" {
  description = "id for vpc "
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, one per AZ"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]

}

output "app_subnet_ids" {
  description = "IDs of the private application subnets, one per AZ"
  value       = [aws_subnet.app_a.id, aws_subnet.app_b.id]
}

output "data_subnet_ids" {
  description = "IDs of the private data subnets, one per AZ"
  value       = [aws_subnet.data_a.id, aws_subnet.data_b.id]
}

