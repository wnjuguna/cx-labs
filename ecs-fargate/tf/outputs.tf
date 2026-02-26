output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "stack_name" {
  description = "CloudFormation stack name (jpetstore + OTEL task definition and service)"
  value       = aws_cloudformation_stack.jpetstore_otel.name
}

output "service_name" {
  description = "ECS service name (from CloudFormation stack outputs)"
  value       = try(aws_cloudformation_stack.jpetstore_otel.outputs["ServiceName"], "N/A")
}
