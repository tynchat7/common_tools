## Gitlab Terraform structure
module "helm_gitlab" {
  source                 = "fuchicorp/chart/helm"
  version                = "0.0.11"
  deployment_name        = "gitlab"
  deployment_path        = "gitlab"
  deployment_endpoint    = "gitlab.${var.google_domain_name}"
  deployment_environment = "tools"
  enabled                = "${var.gitlab["enabled"]}"
  remote_chart           = "true"
  release_version        = "${var.gitlab["version"]}"
  chart_repo             = "${var.gitlab["chart_repo_url"]}"

  ## The Values yaml for the Gitlab application
  remote_override_values = <<EOF
## Global configs for the Gitlab 
global:
  hosts:
    domain: "${var.google_domain_name}"

  grafana:
    enabled: false

  minio:
    enabled: true

  ingress:
    configureCertmanager: false
    class: nginx
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
    tls:
      enabled: true
      secretName: "gitlab-tls"

## Using existing cert manager
certmanager:
  install: false

## Using existing ingress controller 
nginx-ingress:
  enabled: false

## Using existing prometheus
prometheus:
  install: false

registry:
  enabled: false

gitlab:
  toolbox:
    enabled: false
EOF
}

