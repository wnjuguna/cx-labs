variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "name_suffix" {
  type    = string
  default = ""
}

variable "thing_name" {
  description = "Base name for resources (e.g. stack)"
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
  description = "Lab type name (e.g. lambda-exercise)"
  type        = string
}
