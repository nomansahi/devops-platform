resource "kubernetes_deployment_v1" "app" {
  wait_for_rollout = true
  metadata {
    name      = "practice-app"
    namespace = kubernetes_namespace_v1.lab.metadata[0].name
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "practice-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "practice-app"
        }
      }

      spec {
        automount_service_account_token = false
        enable_service_links            = false

        container {
          name              = "app"
          image             = var.app_image
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = 8000
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }

            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = "http"
            }

            initial_delay_seconds = 5
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = "http"
            }

            initial_delay_seconds = 15
            period_seconds        = 10
          }
        }
      }
    }
  }
}