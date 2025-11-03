# terraform/alb.tf
# Application Load Balancer
resource "aws_lb" "mediaserver" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = var.enable_deletion_protection

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = var.environment
  }
}

# Target Group for ECS Service
resource "aws_lb_target_group" "mediaserver" {
  name        = "${var.project_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.project_name}-target-group"
    Environment = var.environment
  }
}

# ALB Listener
resource "aws_lb_listener" "mediaserver" {
  load_balancer_arn = aws_lb.mediaserver.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mediaserver.arn
  }

  tags = {
    Name        = "${var.project_name}-listener"
    Environment = var.environment
  }
}

# HTTPS Listener (optional - requires SSL certificate)
# resource "aws_lb_listener" "mediaserver_https" {
#   load_balancer_arn = aws_lb.mediaserver.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn   = var.ssl_certificate_arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.mediaserver.arn
#   }

#   tags = {
#     Name        = "${var.project_name}-https-listener"
#     Environment = var.environment
#   }
# }