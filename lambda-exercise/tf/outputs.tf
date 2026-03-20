output "stack_name" {
  description = "CloudFormation stack name"
  value       = aws_cloudformation_stack.lambda_exercise.name
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_cloudformation_stack.lambda_exercise.outputs["BucketName"]
}

output "queue_url" {
  description = "SQS queue URL"
  value       = aws_cloudformation_stack.lambda_exercise.outputs["QueueUrl"]
}

output "producer_function_name" {
  description = "Producer Lambda function name"
  value       = aws_cloudformation_stack.lambda_exercise.outputs["ProducerFunctionName"]
}

output "consumer_function_name" {
  description = "Consumer Lambda function name"
  value       = aws_cloudformation_stack.lambda_exercise.outputs["ConsumerFunctionName"]
}
