## Deploying the external dns 
module "external-dns" {
  source                 = "fuchicorp/chart/helm"
  version                = "0.0.11"
  deployment_name        = "external-dns"
  deployment_environment = "tools"
  deployment_endpoint    = "${var.google_domain_name}"
  deployment_path        = "external-dns"
  enabled                = "${var.external_dns["enabled"]}"
  remote_chart           = "true"
  release_version        = "${var.external_dns["version"]}"
  chart_repo             = "${var.external_dns["chart_repo_url"]}"

  remote_override_values = <<EOF
provider: google
google:
  project: "${var.google_project_id}"
  serviceAccountSecret: "${kubernetes_secret.external_dns_secret.metadata.0.name}"
EOF
}

## Creating the secret for External DNS to manage DNS 
resource "kubernetes_secret" "external_dns_secret" {
  metadata {
    name      = "google-service-account"
    namespace = "tools"
  }

  data = {  
    "credentials.json" = "${file(pathexpand("~/google-credentials.json"))}"
  }

  type = "generic"
}

## Updating the local cluster DNS
resource "null_resource" "kube_dns" {
  provisioner "local-exec" {
    command = "kubectl apply -f terraform_templates/kube-dns.yaml"
  }
}
