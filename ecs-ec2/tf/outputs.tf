output "coralogix_nlb_dns_name" {
  description = "DNS name of the internal Coralogix NLB"
  value       = aws_lb.coralogix_nlb.dns_name
}

output "coralogix_nlb_zone_id" {
  description = "Zone ID for the internal NLB (useful for alias records)"
  value       = aws_lb.coralogix_nlb.zone_id
}

output "ecs_asg_name" {
  description = "AutoScaling Group name for ECS instances"
  value       = aws_autoscaling_group.ecs_asg.name
}

output "ecs_asg_instance_ids" {
  description = "Instance IDs currently returned by the ASG (via data.aws_instances.ecs_asg_instances)"
  value       = data.aws_instances.ecs_asg_instances.ids
}
# These will be the OTLP endpoints in-cluster for the CX collector, which any other workload
# might need
output "coralogix_otlp_endpoints" {
  description = "OTLP HTTP endpoints (hostIP:4318) for the Coralogix collectors."
  # Fall back to the user-configurable demo_otlp_candidates if instance lookups
  # are not available in this plan. This is a best-effort convenience output.
  value = var.demo_otlp_candidates != "" ? split(",", var.demo_otlp_candidates) : []
}

output "coralogix_otlp_endpoint_primary" {
  description = "Primary OTLP HTTP endpoint (first host) or empty if none"
  value = length(split(",", var.demo_otlp_candidates)) > 0 ? split(",", var.demo_otlp_candidates)[0] : ""
}
