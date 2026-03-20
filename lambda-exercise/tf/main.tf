locals {
  stack_name = "${var.thing_name}${var.name_suffix}"
  # Unique suffix so S3 bucket name is globally unique
  name_prefix = "${local.stack_name}-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_cloudformation_stack" "lambda_exercise" {
  name          = local.stack_name
  capabilities  = ["CAPABILITY_NAMED_IAM"]
  template_body = file("${path.module}/template.yaml")

  parameters = {
    StackNamePrefix = local.name_prefix
  }
}

# S3 bucket notification is added in Terraform to avoid circular dependency in CloudFormation
# (bucket needs Lambda ARN, Lambda permission needs bucket ARN).
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_cloudformation_stack.lambda_exercise.outputs["BucketName"]

  lambda_function {
    lambda_function_arn = aws_cloudformation_stack.lambda_exercise.outputs["ProducerFunctionArn"]
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_cloudformation_stack.lambda_exercise]
}
