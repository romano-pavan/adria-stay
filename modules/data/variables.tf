variable "name_prefix" {
  type = string

}

variable "vpc_id" {
  type = string
}

variable "data_subnet_ids" {
  type = list(string)
}

variable "app_security_group_id" {
  type = string
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_name" {
  type    = string
  default = "adriastay"
}

variable "db_username" {
  type    = string
  default = "adriastay_admin"
}
