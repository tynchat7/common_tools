resource "kubernetes_cron_job" "ns_cleaner_cronjob" {
  metadata {
    name      = "ns-cleaner-cj"
    namespace = "${kubernetes_service_account.common_service_account.metadata.0.namespace}"
  }

  spec {
    successful_jobs_history_limit = 1
    failed_jobs_history_limit     = 1
    schedule                      = "${var.ns_cleaner_cj_var}"

    job_template {
      metadata = {}

      spec {
        backoff_limit = 3

        template {
          metadata = {}

          spec {
            automount_service_account_token = "true"
            service_account_name            = "${kubernetes_service_account.common_service_account.metadata.0.name}"

            container {
              name    = "ns-cleaner"
              image   = "bitnami/kubectl:latest"
              command = ["/bin/sh", "-c", "kubectl delete `kubectl api-resources --namespaced=true --verbs=delete -o name | grep -Ev 'secrets|serviceaccounts' | tr '\n' ',' | sed -e 's/,\\$//'` --all -n test"]
            }

            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}

resource "kubernetes_cron_job" "terminated_pods_cleanup" {
  count       = "${var.spot_cleanup == "true" ? 1 : 0}"
  metadata {
    name      = "terminated-pods-cleanup"
    namespace = "${kubernetes_service_account.common_service_account.metadata.0.namespace}"
  }

  spec {
    successful_jobs_history_limit = 1
    failed_jobs_history_limit     = 1
    schedule                      = "${var.terminated_pods_cronjob}"

    job_template {
      metadata = {}

      spec {
        backoff_limit = 3

        template {
          metadata = {}

          spec {
            automount_service_account_token = "true"
            service_account_name            = "${kubernetes_service_account.common_service_account.metadata.0.name}"

            container {
              name    = "ns-cleaner"
              image   = "bitnami/kubectl:latest"
              command = ["/bin/sh", "-c", "kubectl get pod --all-namespaces | grep Terminated | awk '{print \"kubectl delete pod -n \"$1 \" \"$2 }' | bash && sleep 60"]
            }

            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}