variable "google_credentials_json" {
  default     = "/fuchicorp/home/username/common_tools/google-credentials.json"
  description = "-(Optional) The google credentials file full path."
}

variable "deployment_environment" {
  default     = "tools"
  description = "-(Optional) Namespace of the deployment <It will be created>"
}

variable "email" {
  default     = "contact@fuchicorp.com"
  description = "-(Optional) By default is using contact email."
}

variable "google_project_id" {
  description = "-(Required) Google cloud platform project id."
}

variable "google_domain_name" {
  description = "-(Required) Please change to your domain name"
}

variable "google_bucket_name" {
  description = "-(Required) please provied bucket name"
}

variable "deployment_name" {
  description = "-(Required) please provied deployment name"
}

variable "namespaces" {
  type = "list"

  default = [
    "dev-students",
    "qa-students",
    "prod-students",
    "dev",
    "qa",
    "prod",
    "test",
    "stage",
    "elk",
    "tools",
  ]

  description = "-(Optional) list of all namespaces for fuchicorp cluster"
}

variable "show_passwords" {
  default     = "false"
  description = "-(Optional) if you put <true> output will show password."
}

variable "custom_403_endpoint" {
  default     = "https://academy.fuchicorp.com/accounting/plans/"
  description = "-(Optional) All non whitelisted people will be redirected to."
}

variable "common_tools_access" {
  type = "list"

  default = [
    "10.40.0.13/8",       ## Cluster access
    "34.133.222.35/32",   ## Fuchicorp bastion host
    "24.14.53.36/32",     ## Farkhod Sadykov
    "67.167.220.165/32",  ## Kelly Salrin
    "106.168.195.106/32", ## Asiat Osmonova
  ]

  description = "-(Optional) Lits of IP ranges to whitelist all common tools."
}

variable "cert_manager" {
  type = "map"

  default = {
    version = "1.7.2"
    enabled = "true"
    chart_repo_url= "https://charts.jetstack.io"
  }

  description = "-(Optional) The Cert manager map configuration."
}

variable "kube_dashboard" {
  type = "map"

  default = {
    version               = "5.3.0"
    enabled               = "false"
    chart_repo_url        = "https://kubernetes.github.io/dashboard/"
  }

  description = "-(Optional) The Kubernetes map configuration."
}

variable "external_dns" {
  type = "map"

  default {
    version = "6.1.4"
    enabled = "true"
    chart_repo_url = "https://charts.bitnami.com/bitnami"
  }

  description = "-(Optional) The External dns map configuration."
}

variable "gitlab" {
  type = "map"

  default {
    version = "5.7.7"
    enabled = "false"
    chart_repo_url = "https://charts.gitlab.io/"
  }

  description = "-(Optional) The Gitlab map configuration."
}

variable "grafana" {
  type = "map"

  default = {
    version             = "6.0.1"
    enabled             = "true"
    grafana_username    = "admin"
    grafana_password    = "password"
    slack_url           = "https://fuchicorp.slack.com"
    github_organization = "fuchicorp"
    chart_repo_url      = "https://grafana.github.io/helm-charts"
  }

  description = "-(Optional) The Grafana map configuration."
}

variable "ingress_controller" {
  type = "map"

  default {
    version = "4.0.19"
    enabled = "true"
    chart_repo_url = "https://kubernetes.github.io/ingress-nginx"
  }

  description = "-(Optional) The Ingress controller map configuration."
}

variable "jenkins" {
  type = "map"

  default = {
    admin_user             = "admin"
    admin_password         = "password"
    jenkins_auth_client_id = "id"
    jenkins_auth_secret    = "secret"
    git_token              = "awdiahwd12ehhaiodd"
    slack_url              = "please-add-your-slack-url"
    slack_token            = "please-add-your-slack-token"
    enabled                = "true"
    git_username           = "add-your-git-username"
    version                = "4.1.13"
    chart_repo_url         = "https://charts.jenkins.io"
    tag                    = "lts-centos7-jdk11"

    plugins                = <<EOF
  - ansicolor:1.0.2
  - authorize-project:1.4.0
  - buildtriggerbadge:251.vdf6ef853f3f5
  - command-launcher:84.v4a_97f2027398
  - configuration-as-code:1512.vb_79d418d5fc8
  - credentials-binding:523.vd859a_4b_122e6
  - dark-theme:185.v276b_5a_8966a_e
  - docker-build-step:2.8
  - docker-workflow:1.29
  - extended-choice-parameter:346.vd87693c5a_86c
  - git:4.11.4
  - git-parameter:0.9.16
  - github-oauth:0.39
  - jdk-tool:55.v1b_32b_6ca_f9ca
  - jobConfigHistory:1163.ve82c7c6e60a_3
  - kubernetes:3670.v6ca_059233222
  - kubernetes-credentials-provider:1.196.va_55f5e31e3c2
  - monitoring:1.91.0
  - oki-docki:1.1
  - parameterized-trigger:2.45
  - rebuild:1.34
  - role-strategy:552.v14cb_85499b_89
  - sonar:2.14
  - timestamper:1.18
  - workflow-aggregator:590.v6a_d052e5a_a_b_5
  - workflow-basic-steps:986.v6b_9c830a_6b_37
  - pipeline-stage-view:2.24
EOF
  }

  description = "-(Optional) The Jenkins map configuration."
}

variable "nexus" {
  type = "map"

  default = {
    admin_password = "fuchicorp"
    username       = "admin"
    version        = "37.3.1"
    enabled        = "true"
    chart_repo_url = "https://sonatype.github.io/helm3-charts/"
  }

  description = "-(Optional) The nexus map confifuration."
}

variable "prometheus" {
  type = "map"

  default {
    deployment_name = "prometheus"
    version         = "15.3.0"
    enabled         = "true"
    chart_repo_url  = "https://prometheus-community.github.io/helm-charts"
  }

  description = "-(Optional) The Promehteus map configuration."
}

variable "rancher" {
  type = "map"

  default = {
    version          = "2.5.9"
    enabled          = "false"
    rancher_password = "admin123"
    chart_repo_url   = "https://releases.rancher.com/server-charts/latest"
  }

  description = "-(Optional) The Rancher map configuration."
}

variable "sonarqube" {
  type = "map"

  default = {
    admin_password           = "admin123"
    username                 = "admin"
    sonarqube_auth_client_id = "id"
    sonarqube_auth_secret    = "secret"
    version                  = "3.0.0"
    enabled                  = "true"
    chart_repo_url           = "https://SonarSource.github.io/helm-chart-sonarqube"
  }

  description = "-(Optional) The SonarQube map configuration."
}

variable "spinnaker" {
  type = "map"

  default = {
    version = "2.2.7"
    enabled = "false"
    chart_repo_url = "https://helmcharts.opsmx.com/"
  }

  description = "-(Optional) The Spinnaker map configuration."
}

variable "vault" {
  type = "map"

  default = {
    version = "0.19.0"
    enabled = "true"
    chart_repo_url = "https://helm.releases.hashicorp.com"
    cronjob = "*/3 * * * *"
  }

  description = "-(Optional) The HashiCorp Vault map configuration."
}

variable "waypoint" {
  type = "map"

  default {
    enabled = "false"
    version = "0.1.8"
    chart_repo_url = "https://helm.releases.hashicorp.com"
  }

  description = "-(Optional) The haschicorp waypoint map configuration."
}

variable "wikijs" {
  type = "map"

  default = {
    version  = "6.2.1"
    enabled  = "false"
    pvc_size = "2Gi"
    chart_repo_url = "https://k8s-at-home.com/charts/"
  }

  description = "-(Optional) The WikiJs map configuration."
}

variable "spot_cleanup" {
  default     = "true"
  description = "-(Optional) deployment can be disabled or enabled by using this bool!"
}

variable "terminated_pods_cronjob" {
  default     = "0 * * * *"
  description = "cronjob for cleaning up terminated pods"
}

variable "ns_cleaner_cj_var" {
  default     = "55 23 * * 0"
  description = "cronjob for ns_cleaner-cj"
}

variable "nexus_pwd_cron_job_var" {
  default     = "*/3 * * * *"
  description = "cronjob for nexus_pwd_cron_job"
}