resource "kubernetes_deployment" "log_generator" {
  metadata {
    name      = "log-generator"
    namespace = var.namespace
    labels = {
      app = "log-generator"
    }
  }

  spec {
    replicas = var.enable_log_generator ? 1 : 0

    selector {
      match_labels = {
        app = "log-generator"
      }
    }

    template {
      metadata {
        labels = {
          app = "log-generator"
        }
      }

      spec {
        volume {
          name = "host-logs"
          host_path {
            path = "/mnt/kind-local-logs"
            type = "Directory"
          }
        }

        container {
          name  = "log-generator"
          image = var.log_generator_image

          image_pull_policy = "IfNotPresent"

          env {
            name  = "LOG_GENERATOR_LOG_DIR"
            value = "/logs"
          }

          env {
            name  = "LOG_GENERATOR_LINES_PER_SEC"
            value = tostring(var.log_generator_lines_per_sec)
          }

          env {
            name  = "LOG_GENERATOR_GLOB"
            value = "*.log"
          }

          env {
            name  = "LOG_GENERATOR_UTF8_ERRORS"
            value = "strict"
          }

          volume_mount {
            name       = "host-logs"
            mount_path = "/logs"
            read_only  = true
          }
        }
      }
    }
  }

  depends_on = [kubernetes_secret.coralogix_keys]
}
