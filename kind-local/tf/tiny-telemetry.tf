resource "kubernetes_deployment" "tiny_telemetry" {
  metadata {
    name      = "tiny-telemetry"
    namespace = var.namespace
    labels = {
      app = "tiny-telemetry"
    }
  }

  spec {
    replicas = var.enable_tiny_telemetry ? 1 : 0

    selector {
      match_labels = {
        app = "tiny-telemetry"
      }
    }

    template {
      metadata {
        labels = {
          app = "tiny-telemetry"
        }
      }

      spec {
        container {
          name  = "tiny-telemetry"
          image = var.tiny_telemetry_image

          image_pull_policy = "IfNotPresent"

          env {
            name = "collector"
            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "status.hostIP"
              }
            }
          }

          env {
            name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
            value = "http://$(collector):4318"
          }

          env {
            name  = "OTEL_EXPORTER_OTLP_PROTOCOL"
            value = "http/protobuf"
          }
        }
      }
    }
  }

  depends_on = [kubernetes_secret.coralogix_keys]
}
