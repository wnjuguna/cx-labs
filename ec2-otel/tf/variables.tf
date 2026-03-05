variable "region" {
  description = "AWS region"
  type        = string
}

variable "name_suffix" {
  type    = string
  default = "-lab"
}

variable "user" {
  description = "Local username; used for tagging resources"
  type        = string
}

variable "cx_team_name" {
  description = "CX team name; used for tagging resources"
  default     = ""
  type        = string
}

variable "thing_name" {
  description = "Name of the CloudFormation stack and resources"
  type        = string
}

variable "lab_type" {
  description = "Name of the project type"
  type        = string
}

variable "aws_ssh_key_name" {
  description = "AWS key pair name (without suffix)"
  type        = string
}

variable "public_ssh_key_path" {
  description = "Path to your local SSH public key"
  type        = string
}

variable "private_ssh_key_path" {
  description = "Path to your local SSH private key (for SSH to instance)"
  type        = string
}

# Set by tf-wrapper; not used by CF template but declared to avoid undeclared variable
variable "vpc_id" {
  description = "VPC ID (from tf-wrapper; not used by ec2-otel CF template)"
  default     = ""
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs (from tf-wrapper; not used by ec2-otel CF template)"
  default     = []
  type        = list(string)
}

# Set by tf-wrapper for other labs; ec2-otel uses AMI from CF template (SSM). Declare to avoid undeclared variable.
variable "ec2_ami" {
  description = "AMI ID (from tf-wrapper; not used by ec2-otel)"
  default     = ""
  type        = string
}

variable "eks_k8s_version" {
  description = "EKS version (from tf-wrapper; not used by ec2-otel)"
  default     = ""
  type        = string
}
