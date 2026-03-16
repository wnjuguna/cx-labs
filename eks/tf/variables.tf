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

variable "eks_k8s_version" {
  type = string
  default = "1.33"
}

variable "eks_node_type" {
  type = string
  default = "t3.medium"
}

variable "eks_min_nodes" {
  type = number
  default = 1
}

variable "eks_max_nodes" {
  type = number
  default = 3
}

variable "eks_desired_nodes" {
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
