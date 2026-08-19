resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  vpc_id      = var.vpc_id
  description = "application load balancer security group"
  tags = {
    Name = "${var.name_prefix}-alb-sg"
  }
}

resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  vpc_id      = var.vpc_id
  description = "application server security group"
  tags = {
    Name = "${var.name_prefix}-app-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = var.alb_ingress_cidr
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow tcp on port 80 to application"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  description                  = "Allow tcp from application load balancer to application server on port 80"
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  description                  = "Allow tcp traffic on port 80 to application server from application load balancer "
}

resource "aws_vpc_security_group_egress_rule" "app_all_out" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all traffic from  application server to public internet"

}

