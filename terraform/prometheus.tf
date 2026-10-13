resource "kubernetes_deployment_v1" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace_v1.lab.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "prometheus"
      }
    }

    template {
      metadata {
        labels = {
          app = "prometheus"
        }

        annotations = {
          config_checksum = sha256(
            kubernetes_config_map_v1.prometheus.data["prometheus.yml"]
          )
        }
      }

      spec {
        service_account_name            = kubernetes_service_account_v1.prometheus.metadata[0].name
        automount_service_account_token = true
        enable_service_links            = false

        container {
          name  = "prometheus"
          image = "prom/prometheus:v3.15.0"

          args = [
            "--config.file=/etc/prometheus/prometheus.yml",
            "--storage.tsdb.path=/prometheus",
            "--storage.tsdb.retention.time=24h",
            "--storage.tsdb.retention.size=100MB"
          ]

          port {
            name           = "http"
            container_port = 9090
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }

            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/-/ready"
              port = "http"
            }

            initial_delay_seconds = 5
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/-/healthy"
              port = "http"
            }

            initial_delay_seconds = 15
            period_seconds        = 10
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/prometheus"
            read_only  = true
          }

          volume_mount {
            name       = "data"
            mount_path = "/prometheus"
          }
        }

        volume {
          name = "config"

          config_map {
            name = kubernetes_config_map_v1.prometheus.metadata[0].name
          }
        }

        volume {
          name = "data"

          empty_dir {}
        }
      }
    }
  }

  depends_on = [
    kubernetes_role_binding_v1.prometheus
  ]
}

resource "kubernetes_service_v1" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace_v1.lab.metadata[0].name
  }

  spec {
    selector = {
      app = "prometheus"
    }

    port {
      name        = "http"
      port        = 9090
      target_port = "http"
    }

    type = "ClusterIP"
  }
}