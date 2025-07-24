##################################
## General - Variables          ##
##################################
region = "us-east-1"
tags = {
  Environment = "production"
  Project     = "my-rest-api"
  Owner       = "platform-team"
  ManagedBy   = "terraform"
}
##################################
## Network - Variables          ##
##################################
vpc_id = "vpc-0c2782484f3a78c2e"
private_subnet_ids = [
  "subnet-04fd3bd34030b27bf",
  "subnet-0ecb5ac4ee9874c9f"
]
##################################
## ECS - Variables              ##
##################################
cluster_name = "my-app-cluster"
service_name = "my-rest-api"
docker_image = "docker.io/kennethreitz/httpbin:latest"
# Container Configuration
container_name = "rest-api-container"
container_port = 80

# Task Configuration
task_cpu           = 256
task_memory        = 512
memory_reservation = 410 # 80% of task_memory

# CPU Architecture (X86_64 or ARM64)
cpu_architecture        = "X86_64"
operating_system_family = "LINUX"

# Service Configuration
desired_count            = 2
capacity_provider        = "FARGATE"
capacity_provider_weight = 100
capacity_provider_base   = 1
platform_version         = "LATEST"

# Environment Variables
environment_variables = [
  {
    name  = "ENV"
    value = "production"
  },
  {
    name  = "PORT"
    value = "80"
  },
  {
    name  = "LOG_LEVEL"
    value = "info"
  }
]

# Container Secrets (uncomment and configure if needed)
# container_secrets = [
#   {
#     name      = "DATABASE_PASSWORD"
#     valueFrom = "arn:aws:secretsmanager:us-west-2:123456789012:secret:db-password-abc123"
#   },
#   {
#     name      = "API_KEY"
#     valueFrom = "/app/api-key"
#   }
# ]

# Health Check Configuration
health_check_command              = "curl -f http://localhost:8080/status/200 || exit 1"
health_check_interval             = 30
health_check_timeout              = 5
health_check_retries              = 3
health_check_start_period         = 60
health_check_grace_period_seconds = 300

# Deployment Configuration
deployment_maximum_percent          = 200
deployment_minimum_healthy_percent  = 100
deployment_circuit_breaker_enable   = true
deployment_circuit_breaker_rollback = true

# Security Configuration
readonly_root_filesystem = false
privileged               = false

# Logging Configuration
log_retention_days = 14

# Feature Flags
enable_container_insights    = true
enable_execute_command       = false
enable_ecs_managed_tags      = true
propagate_tags               = "TASK_DEFINITION"
wait_for_steady_state        = false
ignore_changes_desired_count = true
##################################
## NLB - Variables              ##
##################################
# NLB Configuration (required for VPC Link)
nlb_enable_deletion_protection       = false
nlb_enable_cross_zone_load_balancing = true
nlb_access_logs_enabled              = false
# nlb_access_logs_bucket = "my-custom-nlb-logs-bucket" # Optional: specify custom bucket name

# Optional SSL Certificate (uncomment if you have one)
# ssl_certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"

# Target Group Health Check Configuration (NLB/TCP)
target_group_health_check_healthy_threshold   = 3
target_group_health_check_interval            = 30
target_group_health_check_timeout             = 10
target_group_health_check_unhealthy_threshold = 3
target_group_deregistration_delay             = 300

##################################
## APIGW - Variables            ##
##################################
# API Gateway Configuration (Simple - Private REST API)
api_gateway_stage_name = "v1"
enable_xray_tracing    = true