// Common variables for ecs-ec2 Terraform

variable "demo_otlp_candidates" {
  description = <<-EOD
  Optional comma-separated list of OTLP HTTP endpoints to use for demo workloads.
  Example: "http://172.31.6.92:4318,http://172.31.42.82:4318".
  Leave empty ("") to set this at apply time with -var or a tfvars file.
  EOD
  type    = string
  default = ""
}
variable "vpc_id" {
  type = string
}

variable "name_suffix" {
  type = string
  default = "-lab"
}

variable "subnet_ids" {
  type = list(string)
}

variable "ecs_node_type" {
  type = string
  default = "t3.medium"
}

variable "ecs_min_nodes" {
  type = number
  default = 1
}

variable "ecs_max_nodes" {
  type = number
  default = 3
}

variable "ecs_desired_nodes" {
  type = number
  default = 2
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "thing_name" {
  description = "Name of the EC2 Instance"
  type = string
}

variable "cx_team_name" {
  description = "Holds the team name, if known by the invoking script"
  type = string
  default = " "
}

variable "user" {
  description = "Local user running the terraform; used in the default tags"
  type = string
}

variable "cx_data_key" {
  description = "Send-your-data key for coralogix"
  type = string
}

variable cx_region {
  description = "Coralogix region name"
  type = string
}


variable "coralogix_nlb_endpoint" {
  description = <<-EOD
  Optional pre-resolved endpoint (hostname[:port] or full URL) for the Coralogix NLB.
  If set, demo tasks will use this value as their OTLP endpoint. Leave empty to let
  tasks default to the internal NLB DNS name (available as aws_lb.coralogix_nlb.dns_name).
  EOD
  type    = string
  default = ""
}
