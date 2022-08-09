module "wikijs_deploy" {
  source                 = "fuchicorp/chart/helm"
  version                = "0.0.11"
  deployment_name        = "wikijs"
  deployment_environment = "tools"
  deployment_endpoint    = "wikijs.${var.google_domain_name}"
  deployment_path        = "wikijs"
  release_version        = "${var.wikijs["version"]}"
  remote_chart           = "true"
  enabled                = "${var.wikijs["enabled"]}"
  chart_repo             = "${var.wikijs["chart_repo_url"]}"

  ## Custom terraform configuration
  remote_override_values = <<EOF
ingress:
  main: 
    enabled: true
    annotations:
      kubernetes.io/ingress.class: nginx
      cert-manager.io/cluster-issuer: letsencrypt-prod
      nginx.ingress.kubernetes.io/whitelist-source-range: ${join(",",var.common_tools_access)}
      nginx.ingress.kubernetes.io/server-snippet: |
        error_page 403 ${var.custom_403_endpoint};
    hosts:
    - host: "wikijs.${var.google_domain_name}"
      paths:
      - path: /
        pathtype: Prefix
    tls: 
    - secretName: wikijs-tls
      hosts:
      - "wikijs.${var.google_domain_name}"
persistence:
  config: 
    enabled: true
    existingClaim: "wikijs"

EOF
}

resource "kubernetes_persistent_volume_claim" "wikijs_pv_claim" {
  count = "${var.wikijs["enabled"] == "true" ? 1 : 0}"

  metadata {
    name      = "wikijs"
    namespace = "tools"
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests {
        storage = "${var.wikijs["pvc_size"]}"
      }
    }

    storage_class_name = "standard"
  }

  lifecycle {
    prevent_destroy = "false"
  }
}
