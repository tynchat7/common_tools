# FuchiCorp Vault Deployment
module "vault_deploy" {
  source                 = "fuchicorp/chart/helm"
  version                = "0.0.11"
  deployment_name        = "vault"
  deployment_environment = "tools"
  deployment_endpoint    = "vault.${var.google_domain_name}"
  enabled                = "${var.vault["enabled"]}"
  remote_chart           = "true"
  deployment_path        = "vault"
  release_version        = "${var.vault["version"]}"
  chart_repo             = "${var.vault["chart_repo_url"]}"

  ## The Vault values configurations
  remote_override_values = <<EOF
injector:
  enabled: false

server:
  ingress:
    enabled: true
    labels: {}
    annotations: 
      kubernetes.io/ingress.class: nginx
      cert-manager.io/cluster-issuer: letsencrypt-prod
      nginx.ingress.kubernetes.io/whitelist-source-range: ${join(",",var.common_tools_access)}
      nginx.ingress.kubernetes.io/server-snippet: |
        error_page 403 ${var.custom_403_endpoint};
    hosts:
      - host: "vault.${var.google_domain_name}"
        paths:
        - /
    tls:
    - secretName: chart-vault-tls
      hosts:
      - "vault.${var.google_domain_name}"
  readinessProbe:
    enabled: false
  dataStorage:
    size: 5Gi
EOF
}

## Creating the vault-init-cm configmap for vault-init-job to unseal the vault server after deployment
resource "kubernetes_config_map" "init_script_config_map" {
  count       = "${var.vault["enabled"] == "true" ? 1 : 0}"
  metadata {
    name      = "vault-init-cm"
    namespace = "tools"
  }

  data = {
    "init.sh" = "${file("${path.module}/terraform_templates/vault/init.sh")}"
  }

  depends_on = [
    "module.vault_deploy",
  ]
}

## Creating the vault-init-cron-job to unseal the vault server after deployment
resource "kubernetes_cron_job" "vault_init_cron_job" {
  count       = "${var.vault["enabled"] == "true" ? 1 : 0}"
  metadata {
    name      = "vault-init-cron-job"
    namespace = "tools"
  }

  spec {
    successful_jobs_history_limit = 1
    failed_jobs_history_limit     = 1
    schedule                      = "${var.vault["cronjob"]}"

    job_template {
      metadata = {}

      spec {
        template {
          metadata = {}

          spec {
            automount_service_account_token = "true"
            service_account_name            = "${kubernetes_service_account.common_service_account.metadata.0.name}"

            container {
              name    = "vault-init-job"
              image   = "vault:1.4.0"
              command = ["/bin/sh", "-c", "sh /init/init.sh"]

              volume_mount {
                name       = "vault-data"
                mount_path = "/init"
              }
            }

            restart_policy = "OnFailure"

            volume {
              name = "vault-data"

              config_map {
                name = "vault-init-cm"
              }
            }
          }
        }

        backoff_limit              = 10
        active_deadline_seconds    = 360
        ttl_seconds_after_finished = 210
      }
    }
  }

  depends_on = [
    "kubernetes_config_map.init_script_config_map",
  ]
}
