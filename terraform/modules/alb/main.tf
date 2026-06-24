resource "aws_lb_target_group" "app_tg" {
  name        = "app-target-group"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = { Name = "app-target-group" }
}

resource "aws_lb" "dailylog_alb" {
  name               = "dailylog-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids 

  tags = { Name = "dailylog-alb" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.dailylog_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}