module "rancher_deploy" {
  source                 = "fuchicorp/chart/helm"
  version                = "0.0.11"
  deployment_name        = "rancher"
  deployment_environment = "tools"
  deployment_endpoint    = "rancher.${var.google_domain_name}"
  enabled                = "${var.rancher["enabled"]}"
  remote_chart           = "true"
  deployment_path        = "rancher"
  release_version        = "${var.rancher["version"]}"
  chart_repo             = "${var.rancher["chart_repo_url"]}"

  remote_override_values = <<EOF
hostname: rancher.${var.google_domain_name}
ingress:
  enabled: true
  includeDefaultExtraAnnotations: true
  extraAnnotations:
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "30"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "1800"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "1800"
    cert-manager.io/cluster-issuer: letsencrypt-prod
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/whitelist-source-range: "${join(",",var.common_tools_access)}"
    nginx.ingress.kubernetes.io/server-snippet: 'error_page 403 "${var.custom_403_endpoint}";'    
  tls:
    # options: rancher, letsEncrypt, secret
    source: secret
    secretName: tls-rancher-ingress

# Set a bootstrap password. If leave empty, a random password will be generated.
bootstrapPassword: ${var.rancher["rancher_password"]}
EOF
}

