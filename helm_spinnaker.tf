module "spinnaker_deploy" {
  source                 = "fuchicorp/chart/helm"
  version                = "0.0.11"
  deployment_name        = "spinnaker"
  deployment_path        = "spinnaker"
  deployment_environment = "tools"
  enabled                = "${var.spinnaker["enabled"]}"
  remote_chart           = "true"
  release_version        = "${var.spinnaker["version"]}"
  chart_repo             = "${var.spinnaker["chart_repo_url"]}"

  ## Custom terraform configuration
  remote_override_values = <<EOF
ingress:
  enabled: true
  host:  spinnaker.${var.google_domain_name}
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/whitelist-source-range:  ${join(",",var.common_tools_access)}
    nginx.ingress.kubernetes.io/server-snippet: |
      error_page 403 ${var.custom_403_endpoint};
  tls:
  - secretName: spinnaker-tls
    hosts:
    - spinnaker.${var.google_domain_name}
EOF
}
