module "jenkins_deploy" {
  source                 = "fuchicorp/chart/helm"
  version                = "0.0.11"
  deployment_name        = "jenkins"
  deployment_path        = "jenkins"
  deployment_environment = "tools"
  enabled                = "${var.jenkins["enabled"]}"
  remote_chart           = "true"
  release_version        = "${var.jenkins["version"]}"
  chart_repo             = "${var.jenkins["chart_repo_url"]}"

  remote_override_values = <<EOF
controller:
  tag: "${var.jenkins["tag"]}"
  tagLabel: lts
  numExecutors: 3
  customJenkinsLabels: "master"
  adminUser: "${var.jenkins["admin_user"]}"
  adminPassword: "${var.jenkins["admin_password"]}"
  resources:
    requests:
      cpu: "1"
      memory: "1Gi"
    limits:
      cpu: "2"
      memory: "2Gi"
  affinity: 
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: jenkinsPreferred
            operator: In
            values:
            - "true"
  containerEnv:
  - name: DOMAIN_NAME
    value: "${var.google_domain_name}"
  
  - name: GOOGLE_PROJECT_ID
    value: "${var.google_project_id}"
  
  - name: GOOGLE_BUCKET_NAME
    value: "${var.google_bucket_name}"

  - name: GIT_TOKEN
    value: "${var.jenkins["git_token"]}"

  - name: GIT_USERNAME
    value: "${var.jenkins["git_username"]}"

  - name: JENKINS_GITHUB_AUTH_ID
    value: "${var.jenkins["jenkins_auth_client_id"]}"

  - name: JENKINS_GITHUB_AUTH_SECRET
    value: "${var.jenkins["jenkins_auth_secret"]}"


  javaOpts: "-Xms512m -Xmx512m"
  installPlugins:
${var.jenkins["plugins"]}
  # Set to false to download the minimum required version of all dependencies.
  installLatestPlugins: true
  # Set to true to download latest dependencies of any plugin that is requested to have the latest version.
  installLatestSpecifiedPlugins: false
 

  initScripts: 
   - |
     ${indent(8, data.template_file.jenkins_init_scripts.rendered)}
  
  JCasC:
    defaultConfig: true
    configScripts: 
      jenkins: |-
        securityRealm:
          local:
            allowsSignup: false
            users:
              - id: "${var.jenkins["admin_user"]}"
                password: "${var.jenkins["admin_password"]}"
        authorizationStrategy:
          roleBased:
            roles:
              global:
                - name: "${var.jenkins["admin_user"]}"
                  description: "Jenkins administrators"
                  permissions:
                    - "Overall/Administer"
                  assignments:
                    - "admin"
                - name: "readonly"
                  description: "Read-only users"
                  permissions:
                    - "Overall/Read"
                    - "Job/Read"
                  assignments:
                    - "authenticated"
        unclassified:
          themeManager:
            disableUserThemes: true
            theme: "darkSystem"
              
  ingress:
    enabled: true
    annotations: 
      kubernetes.io/ingress.class: nginx
      ingressClassName: nginx
      cert-manager.io/cluster-issuer: letsencrypt-prod
      nginx.ingress.kubernetes.io/whitelist-source-range: "${join(",",var.common_tools_access)}"
      nginx.ingress.kubernetes.io/server-snippet: |
        error_page 403 "${var.custom_403_endpoint}";
    hostName: "jenkins.${var.google_domain_name}"
    tls:
     - secretName: "jenkins-letsencrypt-prod"
       hosts:
         - "jenkins.${var.google_domain_name}"

persistence:
  enabled: true
  existingClaim: "${kubernetes_persistent_volume_claim.fuchicorp_pv_claim.metadata.0.name}"

serviceAccount:
  create: true
  name: jenkins

serviceAccountAgent:
  create: true
  name: jenkins-agent

rbac:
  serviceAccount.Name: jenkins
  create: true
  readSecrets: true
EOF
}

resource "kubernetes_persistent_volume_claim" "fuchicorp_pv_claim" {
  metadata {
    name      = "jenkins"
    namespace = "tools"
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests {
        storage = "15Gi"
      }
    }

    storage_class_name = "standard"
  }

  lifecycle {
    prevent_destroy = "false"
  }
}


data "template_file" "jenkins_init_scripts" {
  template = "${file("terraform_templates/jenkins/initScripts.groovy")}"
  vars = {}
}
