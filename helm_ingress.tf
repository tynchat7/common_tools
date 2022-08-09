module "ingress_controller" {
  source                 = "fuchicorp/chart/helm"
  version                = "0.0.11"
  deployment_endpoint    = "ingress.${var.google_domain_name}"
  deployment_name        = "ingress-controller"
  deployment_path        = "ingress-nginx"
  deployment_environment = "tools"
  enabled                = "${var.ingress_controller["enabled"]}"
  remote_chart           = "true"
  release_version        = "${var.ingress_controller["version"]}"
  chart_repo             = "${var.ingress_controller["chart_repo_url"]}"

  ## The Ingress controller values configurations
  remote_override_values = <<EOF
controller:
  config:
    use-forwarded-headers: "true"
    forwarded-for-header: "X-Forwarded-For"

    ## Need for cert managers http challengers
    ## https://github.com/fuchicorp/common_tools/issues/767
    ssl-redirect: "false"
  kind: DaemonSet
  service:
    externalTrafficPolicy: "Local"
    enableHttp: false
EOF
}
