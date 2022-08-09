module "prometheus_deploy" {
  source                 = "fuchicorp/chart/helm"
  version                = "0.0.11"
  deployment_name        = "${var.prometheus["deployment_name"]}"
  deployment_environment = "tools"
  deployment_endpoint    = "prometheus.${var.google_domain_name}"
  deployment_path        = "prometheus"
  release_version        = "${var.prometheus["version"]}"
  remote_chart           = "true"
  enabled                = "${var.prometheus["enabled"]}"
  chart_repo             = "${var.prometheus["chart_repo_url"]}"

  remote_override_values = <<EOF
serviceAccounts:
  alertmanager:
    create: false
alertmanager:
  enabled: false
  baseURL: "/"
  ingress:
    enabled: true
    annotations: 
      kubernetes.io/ingress.class: nginx
      cert-manager.io/cluster-issuer: letsencrypt-prod
      nginx.ingress.kubernetes.io/whitelist-source-range: "${join(",",var.common_tools_access)}"
    hosts: 
    - "prometheus.${var.google_domain_name}"
    tls: 
    - secretName: prometheus-alerts-tls
      hosts:
      - "prometheus.${var.google_domain_name}"
server:
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: nginx
      cert-manager.io/cluster-issuer: letsencrypt-prod
      nginx.ingress.kubernetes.io/whitelist-source-range: "${join(",",var.common_tools_access)}"
      nginx.ingress.kubernetes.io/server-snippet: |
        error_page 403 "${var.custom_403_endpoint}"; 
    hosts: 
    - "prometheus.${var.google_domain_name}"
    tls: 
    - secretName: prometheus-server-tls
      hosts:
      - "prometheus.${var.google_domain_name}"
pushgateway:
  enabled: false
  ingress:
    enabled: true
    annotations: 
      kubernetes.io/ingress.class: nginx
      cert-manager.io/cluster-issuer: letsencrypt-prod
    hosts: 
    - "prometheus.${var.google_domain_name}"
    tls: 
    - secretName: prometheus-alerts-tls
      hosts:
        - "prometheus.${var.google_domain_name}"
EOF
}
