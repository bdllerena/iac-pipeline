# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.cluster_name}-${var.service_name}-ecs-tasks"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.existing.cidr_block]
    description = "Allow traffic from VPC"
  }

  # More restrictive egress - HTTPS for container image pulls and AWS APIs
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS outbound for container registry and AWS APIs"
  }

  # HTTP for health checks and internal communication
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.existing.cidr_block]
    description = "Allow HTTP within VPC"
  }

  # DNS resolution
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow DNS resolution"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.service_name}-ecs-tasks-sg"
  })
}

# Security Group for API Gateway VPC Endpoint
resource "aws_security_group" "api_gateway_vpce" {
  name        = "${var.cluster_name}-${var.service_name}-apigw-vpce-sg"
  description = "Security group for API Gateway VPC Endpoint"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.existing.cidr_block]
    description = "Allow HTTPS traffic from VPC"
  }

  # Restrictive egress - only HTTPS to AWS services
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS to AWS services"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.service_name}-apigw-vpce-sg"
  })
}
