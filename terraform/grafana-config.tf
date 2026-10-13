resource "kubernetes_persistent_volume_claim_v1" "grafana" {
  metadata {
    name      = "grafana-data"
    namespace = kubernetes_namespace_v1.lab.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "standard"

    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

resource "kubernetes_config_map_v1" "grafana" {
  metadata {
    name      = "grafana-datasource"
    namespace = kubernetes_namespace_v1.lab.metadata[0].name
  }

  data = {
    "prometheus.yml" = <<-YAML
      apiVersion: 1

      datasources:
        - name: Prometheus
          uid: prometheus
          type: prometheus
          access: proxy
          url: http://prometheus:9090
          isDefault: true
          editable: false
    YAML
  }
}