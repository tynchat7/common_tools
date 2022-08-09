module "sonarqube_deploy" {
  source                 = "fuchicorp/chart/helm"
  version                = "0.0.11"
  deployment_name        = "sonarqube"
  deployment_environment = "tools"
  deployment_endpoint    = "sonarqube.${var.google_domain_name}"
  deployment_path        = "sonarqube"
  enabled                = "${var.sonarqube["enabled"]}"
  remote_chart           = "true"
  release_version        = "${var.sonarqube["version"]}"
  chart_repo             = "${var.sonarqube["chart_repo_url"]}"

  ## Custom terraform configuration
  remote_override_values = <<EOF

## Setting tehup the admin username
account:
  adminPassword: ${var.sonarqube["admin_password"]} 
  currentAdminPassword: admin

## Setting up the ingress configurations
ingress:
  enabled: true
  # Used to create an Ingress record.
  hosts:
    - name: "sonarqube.${var.google_domain_name}"
      # Different clouds or configurations might need /* as the default path
      path: /
      # For additional control over serviceName and servicePort
      # serviceName: someService
      # servicePort: somePort
  annotations: 
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/whitelist-source-range:  ${join(",",var.common_tools_access)}
    nginx.ingress.kubernetes.io/server-snippet: |
      error_page 403 ${var.custom_403_endpoint};
  tls: 
  - secretName: chart-sonarqube-tls
    hosts:
    - "sonarqube.${var.google_domain_name}"

## Setting the sonarqube configurations 

sonarProperties:
  sonar.auth.github.enabled: true
  sonar.auth.github.clientId.secured: ${var.sonarqube["sonarqube_auth_client_id"]}
  sonar.auth.github.clientSecret.secured: ${var.sonarqube["sonarqube_auth_secret"]}
  sonar.auth.github.allowUsersToSignUp: true
  sonar.core.serverBaseURL: https://sonarqube.${var.google_domain_name}
  sonar.forceAuthentication: true
EOF
}

