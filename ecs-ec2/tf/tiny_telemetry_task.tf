################################################################################
# Deploy Tiny Telemetry (https://github.com/BigRedS/tiny-telemetry)
# Minimal task + service to generate traces/metrics/logs for the in-cluster
# Coralogix collector. Users can delete this file to remove the workload.
################################################################################

resource "aws_cloudwatch_log_group" "tiny_telemetry" {
  # Place tiny-telemetry logs under the thing_name namespace
  name              = "/${var.thing_name}/tiny-telemetry"
  retention_in_days = 1
  tags = {
    Project = "cx-labs"
    Cluster = local.cluster_name
  }
}

resource "aws_ecs_task_definition" "tiny_telemetry" {
  family                   = "tiny-telemetry"
  # Run in host network mode because the Coralogix collector is installed
  # as a daemon on every EC2 host; this makes localhost inside the
  # container reach the host's OTLP listener on 127.0.0.1:4318.
  network_mode             = "host"
  requires_compatibilities = ["EC2"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.task_exec.arn

  container_definitions = jsonencode([
    {
      name  = "tiny-telemetry"
  image = "ghcr.io/bigreds/tiny-telemetry:latest"
      essential = true
      environment = [
  # Prefer an explicit endpoint variable if provided; otherwise fall back to
  # demo_otlp_candidates (comma-separated), and finally to the internal NLB DNS.
  { name = "OTEL_EXPORTER_OTLP_ENDPOINT", value = var.coralogix_nlb_endpoint != "" ? var.coralogix_nlb_endpoint : (var.demo_otlp_candidates != "" ? split(",", var.demo_otlp_candidates)[0] : "http://${aws_lb.coralogix_nlb.dns_name}:4318") },
        { name = "OTEL_EXPORTER_OTLP_PROTOCOL", value = "http/protobuf" },
        { name = "TELEMETRY_INTERVAL_SECONDS", value = "5" },
        { name = "FAILURE_RATE", value = "0.1" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.tiny_telemetry.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "tiny"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "tiny_telemetry" {
  name            = "tiny-telemetry"
  cluster         = module.ecs_cluster.cluster_arn
  task_definition = aws_ecs_task_definition.tiny_telemetry.arn
  desired_count   = 1
  force_new_deployment = true
  depends_on = [module.ecs_cluster]
}
