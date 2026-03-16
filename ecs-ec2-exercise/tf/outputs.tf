output "cluster_name" {
  description = "ECS cluster name"
  value       = try(aws_cloudformation_stack.jpetstore_otel.outputs["ClusterName"], "N/A")
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = try(aws_cloudformation_stack.jpetstore_otel.outputs["ClusterArn"], "N/A")
}

output "stack_name" {
  description = "CloudFormation stack name"
  value       = aws_cloudformation_stack.jpetstore_otel.name
}

output "service_name" {
  description = "ECS service name"
  value       = try(aws_cloudformation_stack.jpetstore_otel.outputs["ServiceName"], "N/A")
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = try(aws_cloudformation_stack.jpetstore_otel.outputs["BucketName"], "N/A")
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = try(aws_cloudformation_stack.jpetstore_otel.outputs["BucketArn"], "N/A")
}
