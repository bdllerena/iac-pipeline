# KMS Key for CloudWatch Log Groups
resource "aws_kms_key" "cloudwatch_logs" {
  description             = "KMS key for CloudWatch log groups encryption"
  deletion_window_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.service_name}-logs-kms"
  })
}

resource "aws_kms_alias" "cloudwatch_logs" {
  name          = "alias/${var.cluster_name}-${var.service_name}-logs"
  target_key_id = aws_kms_key.cloudwatch_logs.key_id
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.cluster_name}/${var.service_name}"
  retention_in_days = 365 # 1 year minimum for compliance
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.service_name}-logs"
  })
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.private.id}/${var.api_gateway_stage_name}"
  retention_in_days = 365 # 1 year minimum for compliance
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.service_name}-apigw-logs"
  })
}