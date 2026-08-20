resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.data_subnet_ids
  tags = {
    Name = "${var.name_prefix}-db-subnet-group"
  }

}

resource "aws_security_group" "db" {
  name        = "${var.name_prefix}-db-sg"
  vpc_id      = var.vpc_id
  description = "Database security group"
  tags = {
    Name = "${var.name_prefix}-db-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = var.app_security_group_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Allowed tcp traffic from app to db on port 5432 "

}

resource "aws_db_instance" "this" {
  identifier                  = "${var.name_prefix}-db"
  engine                      = "postgres"
  engine_version              = "18"
  auto_minor_version_upgrade  = true
  instance_class              = var.db_instance_class
  allocated_storage           = 20
  storage_type                = "gp3"
  storage_encrypted           = true
  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.this.name
  vpc_security_group_ids      = [aws_security_group.db.id]
  multi_az                    = false
  backup_retention_period     = 1
  skip_final_snapshot         = true
  deletion_protection         = false
  apply_immediately           = true
  tags = {
    Name = "${var.name_prefix}-db"
  }

}

