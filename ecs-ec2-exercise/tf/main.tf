locals {
  stack_name       = trimspace("${var.thing_name}${var.name_suffix}")
  coralogix_region = var.coralogix_region != "" ? var.coralogix_region : upper(split(".", var.cx_domain)[0])
}

resource "aws_cloudformation_stack" "jpetstore_otel" {
  name          = local.stack_name
  capabilities  = ["CAPABILITY_NAMED_IAM"]
  template_body = file("${path.module}/task-definition.yaml")

  tags = {
    Name       = local.stack_name
    owner      = length(trimspace(var.user)) > 0 ? trimspace(var.user) : "-"
    created_by = "terraform"
    type       = length(trimspace(var.lab_type)) > 0 ? trimspace(var.lab_type) : "-"
    cx_team    = length(trimspace(var.cx_team_name)) > 0 ? trimspace(var.cx_team_name) : "-"
    repo       = "https://github.com/BigRedS/cx-labs.git"
  }

  parameters = {
    VpcId           = var.vpc_id
    SubnetIds       = join(",", var.subnet_ids)
    InstanceType    = var.ecs_ec2_instance_type
    AllowedCidr8080 = var.allowed_cidr_8080
    CoralogixRegion = local.coralogix_region
    PrivateKey      = var.cx_data_token
    ResourcePrefix  = local.stack_name
  }
}
