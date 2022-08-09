module "waypoint_deploy" {
  source                 = "fuchicorp/chart/helm"
  version                = "0.0.11"
  deployment_endpoint    = "waypoint.${var.google_domain_name}"
  deployment_name        = "waypoint"
  deployment_path        = "waypoint"
  deployment_environment = "tools"
  enabled                = "${var.waypoint["enabled"]}"
  remote_chart           = "true"
  release_version        = "${var.waypoint["version"]}"
  chart_repo             = "${var.waypoint["chart_repo_url"]}"

  remote_override_values = <<EOF

# Values that configure the Waypoint UI.
ui:
  service:
    enabled: true
    type: ClusterIP
  ingress:
    enabled: true
    hosts:
      - host: waypoint.${var.google_domain_name}
        paths: 
          - /
    annotations: 
        kubernetes.io/ingress.class: nginx
        cert-manager.io/cluster-issuer: letsencrypt-prod
        nginx.ingress.kubernetes.io/whitelist-source-range: ${join(",",var.common_tools_access)}
        nginx.ingress.kubernetes.io/server-snippet: |
          error_page 403 ${var.custom_403_endpoint};
    tls: 
        - secretName: waypoint-tls
          hosts:
          - waypoint.${var.google_domain_name}
EOF
}


resource "kubernetes_ingress" "grpc_waypoint_ingress" {   
  count       = "${var.waypoint["enabled"] == "true" ? 1 : 0}"
  metadata {
    name = "grpc-waypoint-ingress"
    namespace = "tools"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/backend-protocol" = "GRPCS"   
    }
  }
  spec {
    rule {
      host = "grpc.waypoint.${var.google_domain_name}"
      http {
        path {
          path = "/"
          backend {
            service_name = "waypoint-tools-server"
            service_port = 9701
          }
        }
      }
    }
    tls {
      secret_name = "grpc-waypoint-tls"
      hosts = ["grpc.waypoint.${var.google_domain_name}"]
    }
  }
}
	

