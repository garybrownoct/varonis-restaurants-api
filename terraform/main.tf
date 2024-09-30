provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default = "us-east-1"
}

# DynamoDB Tables
resource "aws_dynamodb_table" "restaurants" {
  name           = "restaurants"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "restaurantId"
  attribute {
    name = "restaurantId"
    type = "S"
  }
}

resource "aws_dynamodb_table" "requests_history" {
  name           = "requests_history"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "requestId"
  attribute {
    name = "requestId"
    type = "S"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = [
      "dynamodb:Scan",
      "dynamodb:PutItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:UpdateItem",
      "dynamodb:GetItem"
    ]
    resources = [
      aws_dynamodb_table.restaurants.arn,
      aws_dynamodb_table.requests_history.arn
    ]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

# Lambda Function
resource "aws_lambda_function" "lambda_function" {
  function_name    = "varonis_restaurants_handler"
  runtime          = "python3.8"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  filename         = "${path.module}/../lambda/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/lambda_function.zip")

  environment {
    variables = {
      RESTAURANTS_TABLE      = aws_dynamodb_table.restaurants.name
      REQUESTS_HISTORY_TABLE = aws_dynamodb_table.requests_history.name
    }
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "api_gateway" {
  name = "VaronisRestaurantsAPI"
}

resource "aws_api_gateway_resource" "restaurants_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "restaurants"
}

resource "aws_api_gateway_method" "restaurants_get" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.restaurants_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.restaurants_resource.id
  http_method             = aws_api_gateway_method.restaurants_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function.invoke_arn
}

# Permission for API Gateway to Invoke Lambda
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
}

# Deploy API
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "prod"
}

# Output API Endpoint
output "api_endpoint" {
  value = "${aws_api_gateway_deployment.api_deployment.invoke_url}/restaurants"
}
