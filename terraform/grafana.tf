resource "kubernetes_deployment_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace_v1.lab.metadata[0].name
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = "grafana"
      }
    }

    template {
      metadata {
        labels = {
          app = "grafana"
        }

        annotations = {
          config_checksum = sha256(
            kubernetes_config_map_v1.grafana.data["prometheus.yml"]
          )
        }
      }

      spec {
        automount_service_account_token = false
        enable_service_links            = false

        security_context {
          fs_group = 472
        }

        container {
          name  = "grafana"
          image = "grafana/grafana:13.2.3"

          port {
            name           = "http"
            container_port = 3000
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }

            limits = {
              cpu    = "500m"
              memory = "384Mi"
            }
          }
          startup_probe {
            http_get {
              path = "/api/health"
              port = "http"
            }

            period_seconds    = 10
            timeout_seconds   = 5
            failure_threshold = 30
          }
          readiness_probe {
            http_get {
              path = "/api/health"
              port = "http"
            }

            initial_delay_seconds = 10
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/api/health"
              port = "http"
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }

          volume_mount {
            name       = "datasource"
            mount_path = "/etc/grafana/provisioning/datasources"
            read_only  = true
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/grafana"
          }
        }

        volume {
          name = "datasource"

          config_map {
            name = kubernetes_config_map_v1.grafana.metadata[0].name
          }
        }

        volume {
          name = "data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.grafana.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace_v1.lab.metadata[0].name
  }

  spec {
    selector = {
      app = "grafana"
    }

    port {
      name        = "http"
      port        = 3000
      target_port = "http"
    }

    type = "ClusterIP"
  }
}