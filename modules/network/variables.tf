variable "name_prefix" {
  type        = string
  description = "prefix applied to resource names and name tags"

}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the vpc"
}