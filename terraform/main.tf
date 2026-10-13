resource "kubernetes_namespace_v1" "lab" {
  metadata {
    name = "devops-lab"
  }
}