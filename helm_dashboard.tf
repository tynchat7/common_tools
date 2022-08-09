module "dashboard_deployer" {
  source                 = "fuchicorp/chart/helm"
  version                = "0.0.11"
  deployment_name        = "kubernetes-dashboard"
  deployment_environment = "tools"
  deployment_endpoint    = "dashboard.${var.google_domain_name}"
  enabled                = "${var.kube_dashboard["enabled"]}"
  remote_chart           = "true"
  deployment_path        = "kubernetes-dashboard"
  release_version        = "${var.kube_dashboard["version"]}"
  chart_repo             = "${var.kube_dashboard["chart_repo_url"]}"

  ## Values.yaml structure
  remote_override_values = <<EOF
extraArgs:
  - --enable-insecure-login
  - --system-banner="Ali Welcomes you to Fuchicorp Kubernetes Dashboard"
protocolHttp: true
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: 'true'
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/whitelist-source-range: ${join(",",var.common_tools_access)}
    nginx.ingress.kubernetes.io/server-snippet: error_page 403 "${var.custom_403_endpoint}";
  paths:
    - /
  hosts:
    - "dashboard.${var.google_domain_name}"
  tls:
  - secretName: dashboard-tls
    hosts:
    - "dashboard.${var.google_domain_name}"
metricsScraper:
  enabled: true
  containerSecurityContext:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    runAsUser: 1001
    runAsGroup: 2001
serviceAccount:
  create: true
  name: dashboard
EOF
}


