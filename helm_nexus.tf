module "nexus_deploy" {
  source                 = "fuchicorp/chart/helm"
  version                = "0.0.11"
  deployment_name        = "nexus"
  deployment_environment = "tools"
  deployment_endpoint    = "nexus.${var.google_domain_name}"
  deployment_path        = "nexus-repository-manager"
  release_version        = "${var.nexus["version"]}"
  remote_chart           = "true"
  enabled                = "${var.nexus["enabled"]}"
  chart_repo             = "${var.nexus["chart_repo_url"]}"

  remote_override_values = <<EOF
nexus:
  docker:
    enabled: true
    registries:
    - host: docker.${var.google_domain_name}
      port: 8085
      secretName: docker-tls
  env:
  - name: INSTALL4J_ADD_VM_PARAMS
    value: "-Xms1200M -Xmx1200M -XX:MaxDirectMemorySize=2G -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap"
  - name: NEXUS_SECURITY_RANDOMPASSWORD
    value: "false"
  properties:
    override: true
  securityContext:
    runAsUser: 0
    runAsGroup: 0
    fsGroup: 0
ingress:
  enabled: true
  annotations:
    nginx.ingress.kubernetes.io/whitelist-source-range: "${join(",",var.common_tools_access)}"
    nginx.ingress.kubernetes.io/server-snippet: 'error_page 403 "${var.custom_403_endpoint}";'
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/proxy-body-size: 2000m
    nginx.org/client-max-body-size: 2000m
  hostPath: /
  hostRepo: "nexus.${var.google_domain_name}"
  tls:
  - secretName: nexus-local-tls
    hosts:
    - "nexus.${var.google_domain_name}"
persistence:
  enabled: true
  accessMode: ReadWriteOnce
  existingClaim: "${kubernetes_persistent_volume_claim.nexus_pv_claim.metadata.0.name}"

EOF
}

resource "kubernetes_persistent_volume_claim" "nexus_pv_claim" {
  metadata {
    name      = "nexus"
    namespace = "tools"
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests {
        storage = "30Gi"
      }
    }

    storage_class_name = "standard"
  }

  lifecycle {
    prevent_destroy = "false"
  }

  depends_on = ["kubernetes_namespace.create_namespaces"]
}

data "template_file" "docker_config_template" {
  template = "${file("${path.module}/terraform_templates/config_template.json")}"

  vars {
    docker_endpoint = "docker.${var.google_domain_name}"
    user_data       = "${base64encode("admin:${var.nexus["admin_password"]}")}"
  }
}

resource "kubernetes_secret" "nexus_creds" {
  metadata {
    name = "nexus-creds"
  }

  data = {
    ".dockerconfigjson" = "${data.template_file.docker_config_template.rendered}"
  }

  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_secret" "nexus_creds_namespaces" {
  count = "${length(var.namespaces)}"

  metadata {
    name      = "nexus-creds"
    namespace = "${var.namespaces[count.index]}"
  }

  data = {
    ".dockerconfigjson" = "${data.template_file.docker_config_template.rendered}"
  }

  type       = "kubernetes.io/dockerconfigjson"
  depends_on = ["kubernetes_namespace.create_namespaces"]
}

resource "null_resource" "chack_norris" {
  count = "${length(var.namespaces)}"

  provisioner "local-exec" {
    command = "kubectl patch serviceaccount default -p  '{\"imagePullSecrets\": [{\"name\": \"nexus-creds\"}]}' -n ${var.namespaces[count.index]}"
  }

  depends_on = ["kubernetes_namespace.create_namespaces"]
}

resource "kubernetes_config_map" "nexus_pwd_cm" {
  metadata {
    name      = "nexus-pwd-cm"
    namespace = "tools"
  }

  data = {
    "nexuspass.sh" = "${file("${path.module}/terraform_templates/nexus/nexus-setup.sh")}"
  }

  depends_on = [
    "module.nexus_deploy",
  ]
}

resource "kubernetes_cron_job" "nexus_pwd_cron_job" {
  metadata {
    name      = "nexus-pwd-cron-job"
    namespace = "tools"
  }

  spec {
    successful_jobs_history_limit = 1
    failed_jobs_history_limit     = 1
    schedule                      = "${var.nexus_pwd_cron_job_var}"

    job_template {
      metadata = {}

      spec {
        template {
          metadata = {}

          spec {
            volume {
              name = "passwordcm"

              config_map {
                name = "nexus-pwd-cm"
              }
            }

            container {
              name    = "password"
              image   = "fuchicorp/buildtools"
              command = ["/bin/bash"]
              args    = ["-c", "cd && bash nexuspass.sh http://nexus-tools-nexus-repository-manager:8081 admin123 ${var.nexus["admin_password"]}"]

              volume_mount {
                name       = "passwordcm"
                mount_path = "/root"
              }
            }

            restart_policy = "OnFailure"
          }
        }

        backoff_limit              = 10
        active_deadline_seconds    = 360
        ttl_seconds_after_finished = 210
      }
    }
  }

  depends_on = [
    "kubernetes_config_map.nexus_pwd_cm",
  ]
}
