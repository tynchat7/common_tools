module "grafana_deploy" {
  source                 = "fuchicorp/chart/helm"
  version                = "0.0.11"
  deployment_endpoint    = "grafana.${var.google_domain_name}"
  deployment_name        = "grafana"
  deployment_path        = "grafana"
  deployment_environment = "tools"
  enabled                = "${var.grafana["enabled"]}"
  remote_chart           = "true"
  release_version        = "${var.grafana["version"]}"
  chart_repo             = "${var.grafana["chart_repo_url"]}"

  ## Custom terraform configuration
  remote_override_values = <<EOF
## Setting the admin username
adminUser: "${var.grafana["grafana_username"]}"
adminPassword: "${var.grafana["grafana_password"]}"

## Setting up the ingress configurations
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/whitelist-source-range: ${join(",",var.common_tools_access)}
    nginx.ingress.kubernetes.io/server-snippet: |
      error_page 403 ${var.custom_403_endpoint};
  hosts:
  - "grafana.${var.google_domain_name}"
  tls: 
  - secretName: grafana-tls
    hosts:
    - "grafana.${var.google_domain_name}"

## Installing the kubernetes plugins
plugins: 
- grafana-kubernetes-app

## Setting the grafana configurations
grafana.ini:
  server:
    root_url: https://grafana.${var.google_domain_name}
  auth.github:
    enabled: true
    allow_sign_up: true
    client_id: "${var.grafana["grafana_auth_client_id"]}"
    client_secret: "${var.grafana["grafana_client_secret"]}"
    scopes: user:email,read:org
    auth_url: https://github.com/login/oauth/authorize
    token_url: https://github.com/login/oauth/access_token
    api_url: https://api.github.com/user
    allowed_organizations: "${var.grafana["github_organization"]}"

## All datasources can can be added here
datasources: 
 datasources.yaml:
   apiVersion: 1
   datasources:
   - name: Prometheus
     type: prometheus
     url: http://${var.prometheus["deployment_name"]}-tools-server:80
     access: proxy
     isDefault: true
   - name: BastionPrometheus
     type: prometheus
     url: http://bastion.${var.google_domain_name}:9090
     isDefault: false

## Add the side card container to load custom dashboards
sidecar:
  dashboards:
    enabled: true
EOF
}



## All custom dashboards configmaps for grafana
resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name      = "all-custom-grafana-dashboards"
    namespace = "tools"

    labels {
      grafana_dashboard = "1"
    }
  }

  data = {
    "Kubernetes-Capacity.json"          = "${file("${path.module}/terraform_templates/grafana/dashboards/6912.json")}"
    "Kubernetes-Deployment.json"        = "${file("${path.module}/terraform_templates/grafana/dashboards/5303.json")}"
    "Kubernetes-Pods.json"              = "${file("${path.module}/terraform_templates/grafana/dashboards/6781.json")}"
    "Kubernetes-Nodes.json"             = "${file("${path.module}/terraform_templates/grafana/dashboards/6915.json")}"
    "Kubernetes-Resource-Requests.json" = "${file("${path.module}/terraform_templates/grafana/dashboards/5321.json")}"
    "Kubernetes-Overview.json"          = "${file("${path.module}/terraform_templates/grafana/dashboards/6918.json")}"
    "Kubernetes-Persistence-Volumes"    = "${file("${path.module}/terraform_templates/grafana/dashboards/6739.json")}"
    "Academy-Deployment.json"           = "${file("${path.module}/terraform_templates/grafana/dashboards/academy.json")}"
    "Kubernetes-Dashboard.json"         = "${file("${path.module}/terraform_templates/grafana/dashboards/kubernetes-dashboard.json")}"
    "Kubernetes-Vault.json"             = "${file("${path.module}/terraform_templates/grafana/dashboards/vault-dashboard.json")}"
    "Grafana-Nexus.json"                = "${file("${path.module}/terraform_templates/grafana/dashboards/nexus-dashboard.json")}"
    "External-Dns.json"                 = "${file("${path.module}/terraform_templates/grafana/dashboards/external-dns-dashboard.json")}"
    "Kubernetes-Cert-Manager.json"      = "${file("${path.module}/terraform_templates/grafana/dashboards/cert-manager-dashboard.json")}"
    "SonarQube-Dashboard.json"          = "${file("${path.module}/terraform_templates/grafana/dashboards/sonarqube-dashboard.json")}"
    "Jenkins-Dashboards.json"           = "${file("${path.module}/terraform_templates/grafana/dashboards/jenkins-dashboard.json")}"
    "Ingress-Controller.json"           = "${file("${path.module}/terraform_templates/grafana/dashboards/ingress-controller.json")}"
    "Prometheus-Dashboard.json"         = "${file("${path.module}/terraform_templates/grafana/dashboards/prometheus-dashboard.json")}"
    "Kubernetes-Waypoint.json"          = "${file("${path.module}/terraform_templates/grafana/dashboards/waypoint-dashboard.json")}"
    "Bastion-Host.json"                 = "${file("${path.module}/terraform_templates/grafana/dashboards/bastion.json")}"
  }
}
