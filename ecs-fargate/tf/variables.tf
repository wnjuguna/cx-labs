variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "name_suffix" {
  type    = string
  default = "-lab"
}

variable "thing_name" {
  description = "Base name for resources (e.g. cluster, stack)"
  type        = string
}

variable "cx_team_name" {
  description = "Holds the team name, if known by the invoking script"
  type        = string
  default     = " "
}

variable "user" {
  description = "Local user running the terraform; used in the default tags"
  type        = string
}

variable "lab_type" {
  description = "Lab type name (e.g. ecs-fargate)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ECS tasks will run (e.g. default VPC)"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for Fargate tasks (e.g. default VPC subnets)"
  type        = list(string)
}

variable "cx_data_token" {
  description = "Coralogix Send-Your-Data API key (from CX_DATA_TOKEN)"
  type        = string
  sensitive   = true
}

variable "cx_domain" {
  description = "Coralogix domain (e.g. eu2.coralogix.com); used to derive region"
  type        = string
  default     = "eu2.coralogix.com"
}

variable "coralogix_region" {
  description = "Coralogix region for the template: EU1, EU2, AP1, AP2, AP3, US1, US2. Defaults from cx_domain."
  type        = string
  default     = ""
}

variable "allowed_cidr_8080" {
  description = "CIDR allowed to access the application on port 8080"
  type        = string
  default     = "0.0.0.0/0"
}
