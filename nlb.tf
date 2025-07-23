# alb.tf -> nlb.tf (Network Load Balancer for VPC Link)

# Network Load Balancer doesn't require a separate security group
# ECS tasks use the security group defined in sg.tf

# Note: ECS security group already allows traffic from VPC CIDR block
# No additional rule needed since NLB traffic comes from within the VPC

# S3 bucket for NLB access logs
resource "aws_s3_bucket" "nlb_logs" {
  count  = var.nlb_access_logs_enabled ? 1 : 0
  bucket = var.nlb_access_logs_bucket != null ? var.nlb_access_logs_bucket : "${var.cluster_name}-${var.service_name}-nlb-logs-${random_id.bucket_suffix[0].hex}"

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.service_name}-nlb-logs"
  })
}

resource "random_id" "bucket_suffix" {
  count       = var.nlb_access_logs_enabled ? 1 : 0
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "nlb_logs" {
  count  = var.nlb_access_logs_enabled ? 1 : 0
  bucket = aws_s3_bucket.nlb_logs[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "nlb_logs" {
  count  = var.nlb_access_logs_enabled ? 1 : 0
  bucket = aws_s3_bucket.nlb_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "nlb_logs" {
  count  = var.nlb_access_logs_enabled ? 1 : 0
  bucket = aws_s3_bucket.nlb_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Internal Network Load Balancer (Required for VPC Link)
resource "aws_lb" "internal" {
  name               = "${var.cluster_name}-${var.service_name}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnet_ids

  enable_deletion_protection       = var.nlb_enable_deletion_protection
  enable_cross_zone_load_balancing = var.nlb_enable_cross_zone_load_balancing

  dynamic "access_logs" {
    for_each = var.nlb_access_logs_enabled ? [1] : []
    content {
      bucket  = aws_s3_bucket.nlb_logs[0].id
      enabled = true
    }
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.service_name}-internal-nlb"
  })
}

# NLB Target Group
resource "aws_lb_target_group" "ecs" {
  name        = "${var.cluster_name}-${var.service_name}-tg"
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
}