locals {
  cluster_name = "${var.thing_name}${var.name_suffix}"
  stack_name   = "${var.thing_name}${var.name_suffix}"
  # Map cx_domain (e.g. eu2.coralogix.com) to template region (EU2); override with var.coralogix_region if set
  coralogix_region = var.coralogix_region != "" ? var.coralogix_region : upper(split(".", var.cx_domain)[0])
}

resource "aws_ecs_cluster" "main" {
  name = local.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudformation_stack" "jpetstore_otel" {
  name         = local.stack_name
  capabilities = ["CAPABILITY_NAMED_IAM"]
  template_body = file("${path.module}/task-definition.yaml")

  parameters = {
    ClusterName       = aws_ecs_cluster.main.name
    VpcId             = var.vpc_id
    SubnetIds         = join(",", var.subnet_ids)
    AllowedCidrFor8080 = var.allowed_cidr_8080
    CoralogixRegion   = local.coralogix_region
    PrivateKey        = var.cx_data_token
    StorageType       = "ParameterStoreAdvanced"
    ParameterName     = "CX_OTEL_ECS_Fargate_config_${replace(local.stack_name, "-", "_")}"
  }
}
