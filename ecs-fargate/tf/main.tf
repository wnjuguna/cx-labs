locals {
  # ECS cluster and CloudFormation names allow only alphanumerics, hyphens, underscores.
  # Sanitize so e.g. $USER with "." (e.g. john.doe) does not produce an invalid name.
  raw_name = "${var.thing_name}${var.name_suffix}"
  sanitized_name = replace(
    replace(replace(replace(local.raw_name, ".", "-"), " ", "-"), "/", "-"),
    "@", "-"
  )
  cluster_name = local.sanitized_name
  stack_name   = local.sanitized_name
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
    ClusterName        = aws_ecs_cluster.main.name
    VpcId              = var.vpc_id
    SubnetIds          = join(",", var.subnet_ids)
    AllowedCidrFor8080 = var.allowed_cidr_8080
    CoralogixRegion    = local.coralogix_region
    PrivateKey         = var.cx_data_token
    StorageType        = "ParameterStoreAdvanced"
    ParameterName      = "CX_OTEL_ECS_Fargate_config_${replace(local.stack_name, "-", "_")}"
    ResourcePrefix     = local.stack_name
  }
}
