# CloudWatch Log Group (simplified - no KMS encryption for now)
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.cluster_name}/${var.service_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.service_name}-logs"
  })
}

# CloudWatch Log Group for API Gateway (simplified - no KMS encryption for now)
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.private.id}/${var.api_gateway_stage_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.service_name}-apigw-logs"
  })
}