output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = try(aws_cloudformation_stack.ec2_otel.outputs["PublicIP"], null)
}

output "instance_id" {
  description = "Instance ID"
  value       = try(aws_cloudformation_stack.ec2_otel.outputs["InstanceId"], null)
}

output "ssh_command" {
  description = "Example SSH command"
  value       = "ssh -i ${var.private_ssh_key_path} -o StrictHostKeyChecking=accept-new ec2-user@${try(aws_cloudformation_stack.ec2_otel.outputs["PublicIP"], "")}"
}
