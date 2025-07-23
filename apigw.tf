# api-gateway.tf

# Private API Gateway
resource "aws_api_gateway_rest_api" "private" {
  name        = "${var.cluster_name}-${var.service_name}-api"
  description = "Private API Gateway for ${var.service_name}"

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.api_gateway.id]
  }

  # Resource policy - only allow access from specific VPC endpoint
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "execute-api:Invoke"
        Resource  = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
        Condition = {
          StringEquals = {
            "aws:sourceVpce" = aws_vpc_endpoint.api_gateway.id
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.service_name}-private-api"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway VPC Link
resource "aws_api_gateway_vpc_link" "internal" {
  name        = "${var.cluster_name}-${var.service_name}-vpc-link"
  description = "VPC Link for ${var.service_name} internal load balancer"
  target_arns = [aws_lb.internal.arn]

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.service_name}-vpc-link"
  })
}

# API Gateway Resource (proxy for all paths)
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.private.id
  parent_id   = aws_api_gateway_rest_api.private.root_resource_id
  path_part   = "{proxy+}"
}

# API Gateway Method (ANY for proxy)
resource "aws_api_gateway_method" "proxy_any" {
  rest_api_id   = aws_api_gateway_rest_api.private.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# API Gateway Integration for proxy
resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.private.id
  resource_id = aws_api_gateway_method.proxy_any.resource_id
  http_method = aws_api_gateway_method.proxy_any.http_method

  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.internal.id
  uri                     = "http://${aws_lb.internal.dns_name}:${var.container_port}/{proxy}"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  timeout_milliseconds = 29000
}

# Root method for health checks and root path
resource "aws_api_gateway_method" "root_get" {
  rest_api_id   = aws_api_gateway_rest_api.private.id
  resource_id   = aws_api_gateway_rest_api.private.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

# Root integration
resource "aws_api_gateway_integration" "root" {
  rest_api_id = aws_api_gateway_rest_api.private.id
  resource_id = aws_api_gateway_method.root_get.resource_id
  http_method = aws_api_gateway_method.root_get.http_method

  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.internal.id
  uri                     = "http://${aws_lb.internal.dns_name}:${var.container_port}/"

  timeout_milliseconds = 29000
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "private" {
  depends_on = [
    aws_api_gateway_method.proxy_any,
    aws_api_gateway_integration.proxy,
    aws_api_gateway_method.root_get,
    aws_api_gateway_integration.root
  ]

  rest_api_id = aws_api_gateway_rest_api.private.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy_any.id,
      aws_api_gateway_integration.proxy.id,
      aws_api_gateway_method.root_get.id,
      aws_api_gateway_integration.root.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "private" {
  deployment_id = aws_api_gateway_deployment.private.id
  rest_api_id   = aws_api_gateway_rest_api.private.id
  stage_name    = var.api_gateway_stage_name

  # Access logging
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      responseTime   = "$context.responseTime"
    })
  }

  # X-Ray tracing
  xray_tracing_enabled = var.enable_xray_tracing

  # Enable caching for better performance
  cache_cluster_enabled = true
  cache_cluster_size    = "0.5"

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${var.service_name}-apigw-stage"
  })
}

