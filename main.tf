terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# -----------------------------
# Default VPC and default subnets
# -----------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}


locals {
  subnet_ids = length(data.aws_subnets.default.ids) >= 2 ? slice(data.aws_subnets.default.ids, 0, 2) : data.aws_subnets.default.ids
}


# -----------------------------
# Security Groups
# -----------------------------
# ALB: public HTTP
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP from the internet"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "All egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Name = "alb-sg" }
}

# EC2/ASG: only ALB can reach on 80
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP from ALB only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description      = "All egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Name = "web-sg" }
}

# -----------------------------
# Amazon Linux 2 AMI (x86_64, HVM)
# -----------------------------

data "aws_ami" "amzn2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "image-id"
    values = ["ami-0532be01f26a3de55"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# -----------------------------
# Launch Template with user data
# -----------------------------
resource "aws_launch_template" "web_lt" {
  name_prefix   = "web-lt-"
  image_id      = data.aws_ami.amzn2.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Inject the user data file that installs Apache and writes your HTML
  user_data = filebase64("${path.module}/user_data.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Role = "web"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------
# Application Load Balancer
# -----------------------------
resource "aws_lb" "app" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = local.subnet_ids

  enable_deletion_protection = false

  tags = { Name = "app-alb" }
}

resource "aws_lb_target_group" "app_tg" {
  name        = "app-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    enabled             = true
    interval            = 15
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200-399"
  }

  tags = { Name = "app-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# -----------------------------
# Auto Scaling Group (2 instances across two subnets)
# -----------------------------
resource "aws_autoscaling_group" "web_asg" {
  name                      = "web-asg"
  max_size                  = 4
  min_size                  = 2
  desired_capacity          = 2
  vpc_zone_identifier       = local.subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 60
  target_group_arns         = [aws_lb_target_group.app_tg.arn]

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "web-asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_lb_listener.http]
}

# -----------------------------
# Auto Scaling Policies
# -----------------------------

# ✅ Option A (Recommended): Target Tracking on average CPU (50%)
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "cpu-tt-policy"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50
  }
}





# 🔁 Option B (Optional): Target Tracking on ALB RequestCountPerTarget
# Uncomment both the local and the policy below to use request-based scaling.

# locals {
#   # CloudWatch resource label format:
#   # app/<lb-name>/<lb-id>/targetgroup/<tg-name>/<tg-id>
#   tg_resource_label = "${aws_lb.app.arn_suffix}/${aws_lb_target_group.app_tg.arn_suffix}"
# }

# resource "aws_autoscaling_policy" "alb_rps_target_tracking" {
#   name                   = "alb-rps-tt-policy"
#   autoscaling_group_name = aws_autoscaling_group.web_asg.name
#   policy_type            = "TargetTrackingScaling"
#
#   target_tracking_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ALBRequestCountPerTarget"
#       resource_label         = local.tg_resource_label
#     }
#     target_value = 100
#   }
# }