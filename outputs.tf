# outputs.tf

output "api_gateway_url" {
  description = "Private API Gateway URL"
  value       = "https://${aws_api_gateway_rest_api.private.id}-${aws_vpc_endpoint.api_gateway.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.api_gateway_stage_name}"
}

output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.private.id
}

output "vpc_endpoint_id" {
  description = "VPC Endpoint ID for API Gateway"
  value       = aws_vpc_endpoint.api_gateway.id
}

output "nlb_dns_name" {
  description = "Network Load Balancer DNS name"
  value       = aws_lb.internal.dns_name
}

output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS Service name"
  value       = aws_ecs_service.main.name
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = aws_lb_target_group.ecs.arn
}