variable "name_prefix" {
  type        = string
  description = "prefix applied to resource names and name tags"
}

variable "vpc_id" {
  type        = string
  description = "ID of virtual private cloud"
}

variable "alb_ingress_cidr" {
  type        = string
  description = "ingress CIDR block "
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "ec2 instance type"
}