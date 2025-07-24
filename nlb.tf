# alb.tf -> nlb.tf (Network Load Balancer for VPC Link)

# Network Load Balancer doesn't require a separate security group
# ECS tasks use the security group defined in sg.tf

# Note: ECS security group already allows traffic from VPC CIDR block
# No additional rule needed since NLB traffic comes from within the VPC

# NLB access logs disabled for simplified deployment

# Internal Network Load Balancer (Required for VPC Link)
resource "aws_lb" "internal" {
  name               = "${var.cluster_name}-${var.service_name}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnet_ids

  enable_deletion_protection       = var.nlb_enable_deletion_protection
  enable_cross_zone_load_balancing = var.nlb_enable_cross_zone_load_balancing

  # Access logs disabled for simplified deployment

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.service_name}-internal-nlb"
  })
}

# NLB Target Group
resource "aws_lb_target_group" "ecs" {
  name        = "${var.service_name}-${var.container_port}-tg"
  port        = var.container_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = var.target_group_health_check_healthy_threshold
    interval            = var.target_group_health_check_interval
    port                = var.container_port
    protocol            = "TCP"
    timeout             = var.target_group_health_check_timeout
    unhealthy_threshold = var.target_group_health_check_unhealthy_threshold
  }

  # Target group attributes for NLB
  deregistration_delay   = var.target_group_deregistration_delay
  preserve_client_ip     = "false"
  proxy_protocol_v2      = false
  connection_termination = false

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.service_name}-target-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# NLB Listener (TCP)
resource "aws_lb_listener" "tcp" {
  load_balancer_arn = aws_lb.internal.arn
  port              = var.container_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.service_name}-tcp-listener"
  })

  depends_on = [aws_lb_target_group.ecs]
}