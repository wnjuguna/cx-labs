locals {
  cx_values = templatefile("${path.module}/../values.yaml", {
    cx_domain      = var.cx_domain
    cluster_name   = var.cluster_name
    enable_gateway = var.enable_gateway
  })
}

resource "kubernetes_secret" "coralogix_keys" {
  metadata {
    name      = "coralogix-keys"
    namespace = var.namespace
  }

  data = {
    PRIVATE_KEY = var.cx_data_key
  }

  type = "Opaque"
}

resource "helm_release" "otel_integration" {
  name       = "otel-coralogix-integration"
  repository = "https://cgx.jfrog.io/artifactory/coralogix-charts-virtual"
  chart      = "otel-integration"
  namespace  = var.namespace

  values = [local.cx_values]

  # Static list required by helm provider; Deployments always exist (replicas 0 when disabled).
  depends_on = [
    kubernetes_secret.coralogix_keys,
    kubernetes_deployment.tiny_telemetry,
    kubernetes_deployment.log_generator,
  ]
}

resource "helm_release" "otel_demo" {
  count      = var.enable_otel_demo ? 1 : 0
  name       = "otel-demo"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-demo"
  namespace  = "otel-demo"

  create_namespace = true
  values           = [file("${path.module}/../otel-demo-values.yaml")]
}
