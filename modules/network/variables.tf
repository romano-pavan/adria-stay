variable "name_prefix" {
  type        = string
  description = "prefix applied to resource names and name tags"

}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the vpc"
}

variable "public_a_cidr" {
  type        = string
  description = "CIDR block for public subnet in AZ-A"
}

variable "public_b_cidr" {
  type        = string
  description = "CIDR block for public subnet in AZ-B"
}

variable "app_a_cidr" {
  type        = string
  description = "CIDR block for application subnet in AZ-A"

}

variable "app_b_cidr" {
  type        = string
  description = "CIDR block for application subnet in AZ-B"
}

variable "data_a_cidr" {
  type        = string
  description = "CIDR block for data subnet in AZ-A"
}

variable "data_b_cidr" {
  type        = string
  description = "CIDR block for data subnet in AZ-B"
}