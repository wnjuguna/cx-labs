variable "kubeconfig_path" {
  description = "Path to kubeconfig for kind-local cluster"
  type        = string
  default     = "~/.kube/kind-local.yaml"
}

variable "kubeconfig_context" {
  description = "Kube context to use for kind-local"
  type        = string
  default     = "kind-cx-labs-kind-local"
}

variable "namespace" {
  description = "Namespace for Coralogix chart"
  type        = string
  default     = "default"
}

variable "cx_domain" {
  description = "Coralogix domain, e.g. eu2.coralogix.com"
  type        = string
  default     = "eu2.coralogix.com"
}

variable "cx_data_key" {
  description = "Coralogix send-your-data key"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Cluster name sent in chart values"
  type        = string
  default     = "kind-local"
}

variable "enable_gateway" {
  description = "Enable opentelemetry-gateway chart component"
  type        = bool
  default     = false
}

variable "enable_otel_demo" {
  description = "Install OpenTelemetry demo chart"
  type        = bool
  default     = false
}

variable "enable_tiny_telemetry" {
  description = "Deploy tiny-telemetry workload (image must be built and kind-loaded by Ansible)"
  type        = bool
  default     = true
}

variable "tiny_telemetry_image" {
  description = "Local image tag for tiny-telemetry (must match Ansible tiny_telemetry_image)"
  type        = string
  default     = "tiny-telemetry:local"
}

variable "enable_log_generator" {
  description = "Run log-generator Deployment (replicas 0 when false); requires kind extraMounts for logs"
  type        = bool
  default     = true
}

variable "log_generator_image" {
  description = "Local image tag for log-generator (must match Ansible log_generator_image)"
  type        = string
  default     = "log-generator:local"
}

variable "log_generator_lines_per_sec" {
  description = "Lines per second emitted to stdout (global across files); default 5"
  type        = number
  default     = 5
}
