#************************************************************#
# Application Load Balancer Core                             # 
#************************************************************#
resource "aws_lb" "asg_lb" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.asg_lb_sg.id]
  subnets            = var.alb_subnets
}

#************************************************************#
# Application Load Balancer HTTP Listener                    #
#************************************************************#
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.asg_lb.arn
    port              = local.http_port
    protocol          = "HTTP"

    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "Hello, World"
            status_code  = "200"
        }
    }
}

#*******************************************************************#
# Application Load Balancer HTTP Listener Rule redirect 80 --> 443  #
#*******************************************************************#
resource "aws_lb_listener_rule" "asg_lb_listener_rule_http_to_https" {
    listener_arn = aws_lb_listener.http.arn
    priority     = 100

    action {
        type = "redirect"

        redirect {
            port        = local.https_port
            protocol    = "HTTPS"
            status_code = "HTTP_301"
        }
    }
    condition {
        path_pattern {
            values = ["/*"]
        }
    }
}

#************************************************************#
# Application Load Balancer https listener                   #
#************************************************************#
resource "aws_lb_listener" "https" {
    load_balancer_arn = aws_lb.asg_lb.arn
    port              = local.https_port
    protocol          = "HTTPS"
    ssl_policy        = "ELBSecurityPolicy-2016-08"
    certificate_arn   = var.certificate_arn

    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "Hello, World"
            status_code  = "200"
        }
    }
}

#************************************************************#
# Application Load Balancer https listener rule              #
#************************************************************#
resource "aws_lb_listener_rule" "asg_lb_listener_rule_https" {
    listener_arn = aws_lb_listener.https.arn
    priority     = 100

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.asg_tg.arn
    }

    condition {
        path_pattern {
            values = ["/*"]
        }
    }
}

#************************************************************#
# Application Load Balancer Security Group                   #
#************************************************************#
resource "aws_security_group" "asg_lb_sg" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Allow HTTP traffic"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "allow_http_to_alb" {
    type              = "ingress"
    security_group_id = aws_security_group.asg_lb_sg.id
    from_port         = local.http_port
    to_port           = local.http_port
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_https_to_alb" {
    type              = "ingress"
    security_group_id = aws_security_group.asg_lb_sg.id
    from_port         = local.https_port
    to_port           = local.https_port
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
    type              = "egress"
    security_group_id = aws_security_group.asg_lb_sg.id
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
}

#************************************************************#
# Application Load Balancer Target Group                     #
#************************************************************#
resource "aws_lb_target_group" "asg_tg" {
  name     = "${var.cluster_name}-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

    health_check {
        path = "/"
        port = var.server_port
        protocol = "HTTP"
        matcher = "200"
        interval = 30
        timeout = 5
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}