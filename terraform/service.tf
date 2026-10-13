resource "kubernetes_service_v1" "app" {
  metadata {
    name      = "practice-app"
    namespace = kubernetes_namespace_v1.lab.metadata[0].name
  }

  spec {
    selector = {
      app = "practice-app"
    }

    port {
      name        = "http"
      port        = 80
      target_port = "http"
    }

    type = "ClusterIP"
  }
}