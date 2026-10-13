resource "kubernetes_config_map_v1" "prometheus" {
  metadata {
    name      = "prometheus-config"
    namespace = kubernetes_namespace_v1.lab.metadata[0].name
  }

  data = {
    "prometheus.yml" = <<-YAML
      global:
        scrape_interval: 15s
        evaluation_interval: 15s

      scrape_configs:
        - job_name: prometheus
          static_configs:
            - targets: ["localhost:9090"]

        - job_name: practice_app
          kubernetes_sd_configs:
            - role: pod
              namespaces:
                names: ["devops-lab"]

          relabel_configs:
            - source_labels: [__meta_kubernetes_pod_label_app]
              regex: practice-app
              action: keep

            - source_labels: [__meta_kubernetes_pod_container_port_name]
              regex: http
              action: keep

            - source_labels: [__meta_kubernetes_pod_phase]
              regex: Running
              action: keep

            - source_labels: [__meta_kubernetes_namespace]
              target_label: namespace

            - source_labels: [__meta_kubernetes_pod_name]
              target_label: pod
    YAML
  }
}