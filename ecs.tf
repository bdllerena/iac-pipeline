# ecs.tf
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Data sources for existing VPC resources
data "aws_vpc" "existing" {
  id = var.vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "subnet-id"
    values = var.private_subnet_ids
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(var.tags, {
    Name = var.cluster_name
  })
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.cluster_name}-${var.service_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  runtime_platform {
    cpu_architecture        = var.cpu_architecture
    operating_system_family = var.operating_system_family
  }

  container_definitions = jsonencode([
    {
      name  = var.container_name
      image = var.docker_image

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
          name          = "${var.service_name}-port"
        }
      ]

      environment = var.environment_variables

      secrets = var.container_secrets

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }

      essential = true

      healthCheck = {
        command = [
          "CMD-SHELL",
          var.health_check_command
        ]
        interval    = var.health_check_interval
        timeout     = var.health_check_timeout
        retries     = var.health_check_retries
        startPeriod = var.health_check_start_period
      }

      memoryReservation = var.memory_reservation

      readonlyRootFilesystem = var.readonly_root_filesystem
      privileged             = var.privileged
    }
  ])

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.service_name}-task-definition"
  })
}

# ECS Service
resource "aws_ecs_service" "main" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider
    weight            = var.capacity_provider_weight
    base              = var.capacity_provider_base
  }

  platform_version = var.platform_version

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  deployment_circuit_breaker {
    enable   = var.deployment_circuit_breaker_enable
    rollback = var.deployment_circuit_breaker_rollback
  }

  health_check_grace_period_seconds = var.health_check_grace_period_seconds
  enable_execute_command            = var.enable_execute_command
  enable_ecs_managed_tags           = var.enable_ecs_managed_tags
  propagate_tags                    = var.propagate_tags
  wait_for_steady_state             = var.wait_for_steady_state

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy,
    aws_lb_listener.tcp
  ]

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.service_name}-service"
  })

  lifecycle {
    ignore_changes = [desired_count]
  }
}

