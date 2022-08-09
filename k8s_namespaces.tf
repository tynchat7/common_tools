resource "kubernetes_namespace" "create_namespaces" {
  count = "${length(var.namespaces)}"

  metadata {
    name = "${var.namespaces[count.index]}"
  }
}
