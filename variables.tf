##################################
## General - Variables          ##
##################################
variable "region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
  default = {
    terraform = "true"
    resource  = "eks"
  }
}
##################################
## Network - Variables          ##
##################################
variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be in the format vpc-xxxxxxxxx."
  }
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnet IDs must be provided for high availability."
  }
}

##################################
## ECS - Variables              ##
##################################
variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.cluster_name))
    error_message = "Cluster name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.service_name))
    error_message = "Service name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "docker_image" {
  description = "Docker image URI for the application"
  type        = string
  sensitive   = true
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "app"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  validation {
    condition     = var.container_port > 0 && var.container_port < 65536
    error_message = "Container port must be between 1 and 65535."
  }
}

variable "task_cpu" {
  description = "CPU units for the ECS task (256, 512, 1024, 2048, 4096)"
  type        = number
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "task_memory" {
  description = "Memory in MiB for the ECS task"
  type        = number
  validation {
    condition     = var.task_memory >= 512 && var.task_memory <= 30720
    error_message = "Memory must be between 512 and 30720 MiB."
  }
}

variable "memory_reservation" {
  description = "Soft memory limit for the container"
  type        = number
  default     = null
}

variable "cpu_architecture" {
  description = "CPU architecture for the task (X86_64 or ARM64)"
  type        = string
  default     = "X86_64"
  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "CPU architecture must be either X86_64 or ARM64."
  }
}

variable "operating_system_family" {
  description = "Operating system family for the task"
  type        = string
  default     = "LINUX"
  validation {
    condition = contains([
      "LINUX",
      "WINDOWS_SERVER_2019_FULL",
      "WINDOWS_SERVER_2019_CORE",
      "WINDOWS_SERVER_2022_FULL",
      "WINDOWS_SERVER_2022_CORE"
    ], var.operating_system_family)
    error_message = "Operating system family must be a valid Fargate OS family."
  }
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  validation {
    condition     = var.desired_count >= 1
    error_message = "Desired count must be at least 1."
  }
}

variable "capacity_provider" {
  description = "Capacity provider for the service"
  type        = string
  default     = "FARGATE"
  validation {
    condition     = contains(["FARGATE", "FARGATE_SPOT"], var.capacity_provider)
    error_message = "Capacity provider must be either FARGATE or FARGATE_SPOT."
  }
}

variable "capacity_provider_weight" {
  description = "Weight for the capacity provider"
  type        = number
  default     = 100
  validation {
    condition     = var.capacity_provider_weight >= 0 && var.capacity_provider_weight <= 1000
    error_message = "Capacity provider weight must be between 0 and 1000."
  }
}

variable "capacity_provider_base" {
  description = "Base number of tasks for the capacity provider"
  type        = number
  default     = 1
  validation {
    condition     = var.capacity_provider_base >= 0
    error_message = "Capacity provider base must be 0 or greater."
  }
}

variable "platform_version" {
  description = "Fargate platform version"
  type        = string
  default     = "LATEST"
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "container_secrets" {
  description = "Secrets for the container from SSM Parameter Store or Secrets Manager"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default   = []
  sensitive = true
}

variable "health_check_command" {
  description = "Health check command for the container"
  type        = string
  default     = "curl -f http://localhost:8080/status/200 || exit 1"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
  validation {
    condition     = var.health_check_interval >= 5 && var.health_check_interval <= 300
    error_message = "Health check interval must be between 5 and 300 seconds."
  }
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
  validation {
    condition     = var.health_check_timeout >= 2 && var.health_check_timeout <= 60
    error_message = "Health check timeout must be between 2 and 60 seconds."
  }
}

variable "health_check_retries" {
  description = "Number of health check retries"
  type        = number
  default     = 3
  validation {
    condition     = var.health_check_retries >= 1 && var.health_check_retries <= 10
    error_message = "Health check retries must be between 1 and 10."
  }
}

variable "health_check_start_period" {
  description = "Health check start period in seconds"
  type        = number
  default     = 60
  validation {
    condition     = var.health_check_start_period >= 0 && var.health_check_start_period <= 300
    error_message = "Health check start period must be between 0 and 300 seconds."
  }
}

variable "health_check_grace_period_seconds" {
  description = "Health check grace period for the service in seconds"
  type        = number
  default     = 300
  validation {
    condition     = var.health_check_grace_period_seconds >= 0 && var.health_check_grace_period_seconds <= 7200
    error_message = "Health check grace period must be between 0 and 7200 seconds."
  }
}

variable "deployment_maximum_percent" {
  description = "Maximum percent of tasks during deployment"
  type        = number
  default     = 200
  validation {
    condition     = var.deployment_maximum_percent >= 100 && var.deployment_maximum_percent <= 200
    error_message = "Deployment maximum percent must be between 100 and 200."
  }
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum percent of healthy tasks during deployment"
  type        = number
  default     = 100
  validation {
    condition     = var.deployment_minimum_healthy_percent >= 0 && var.deployment_minimum_healthy_percent <= 100
    error_message = "Deployment minimum healthy percent must be between 0 and 100."
  }
}

variable "deployment_circuit_breaker_enable" {
  description = "Enable deployment circuit breaker"
  type        = bool
  default     = true
}

variable "deployment_circuit_breaker_rollback" {
  description = "Enable rollback on deployment circuit breaker"
  type        = bool
  default     = true
}

variable "readonly_root_filesystem" {
  description = "Make the root filesystem read-only"
  type        = bool
  default     = false
}

variable "privileged" {
  description = "Run container in privileged mode"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 14
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the ECS cluster"
  type        = bool
  default     = true
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = false
}

variable "enable_ecs_managed_tags" {
  description = "Enable ECS managed tags"
  type        = bool
  default     = true
}

variable "propagate_tags" {
  description = "How to propagate tags (NONE, SERVICE, TASK_DEFINITION)"
  type        = string
  default     = "TASK_DEFINITION"
  validation {
    condition     = contains(["NONE", "SERVICE", "TASK_DEFINITION"], var.propagate_tags)
    error_message = "Propagate tags must be one of: NONE, SERVICE, TASK_DEFINITION."
  }
}

variable "wait_for_steady_state" {
  description = "Wait for the service to reach steady state"
  type        = bool
  default     = false
}

variable "ignore_changes_desired_count" {
  description = "Ignore changes to desired_count (useful with auto-scaling)"
  type        = bool
  default     = true
}
##################################
## LB - Variables               ##
##################################
variable "nlb_enable_deletion_protection" {
  description = "Enable deletion protection for NLB"
  type        = bool
  default     = false
}

variable "nlb_enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing for NLB"
  type        = bool
  default     = true
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for TLS listener (optional)"
  type        = string
  default     = null
  sensitive   = true
}

# Target Group Configuration (updated for NLB)
variable "target_group_health_check_healthy_threshold" {
  description = "Number of consecutive health checks successes required before considering an unhealthy target healthy"
  type        = number
  default     = 3
  validation {
    condition     = var.target_group_health_check_healthy_threshold >= 2 && var.target_group_health_check_healthy_threshold <= 10
    error_message = "Healthy threshold must be between 2 and 10."
  }
}

variable "target_group_health_check_interval" {
  description = "Approximate amount of time, in seconds, between health checks of an individual target"
  type        = number
  default     = 30
  validation {
    condition     = var.target_group_health_check_interval >= 10 && var.target_group_health_check_interval <= 300
    error_message = "Health check interval must be between 10 and 300 seconds for NLB."
  }
}

variable "target_group_health_check_timeout" {
  description = "Amount of time, in seconds, during which no response means a failed health check (NLB TCP)"
  type        = number
  default     = 10
  validation {
    condition     = var.target_group_health_check_timeout >= 6 && var.target_group_health_check_timeout <= 120
    error_message = "Health check timeout must be between 6 and 120 seconds for NLB."
  }
}

variable "target_group_health_check_unhealthy_threshold" {
  description = "Number of consecutive health check failures required before considering the target unhealthy"
  type        = number
  default     = 3
  validation {
    condition     = var.target_group_health_check_unhealthy_threshold >= 2 && var.target_group_health_check_unhealthy_threshold <= 10
    error_message = "Unhealthy threshold must be between 2 and 10."
  }
}

variable "target_group_deregistration_delay" {
  description = "Amount of time, in seconds, for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused"
  type        = number
  default     = 300
  validation {
    condition     = var.target_group_deregistration_delay >= 0 && var.target_group_deregistration_delay <= 3600
    error_message = "Deregistration delay must be between 0 and 3600 seconds."
  }
}
##################################
## APIGW - Variables            ##
##################################
variable "api_gateway_stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "v1"
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.api_gateway_stage_name))
    error_message = "Stage name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing for API Gateway"
  type        = bool
  default     = true
}

variable "nlb_access_logs_bucket" {
  description = "S3 bucket name for NLB access logs (optional)"
  type        = string
  default     = null
}

variable "nlb_access_logs_enabled" {
  description = "Enable NLB access logs"
  type        = bool
  default     = true
}