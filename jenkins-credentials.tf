resource "kubernetes_secret" "sonarqube-admin-access" {
  depends_on = ["kubernetes_namespace.create_namespaces"]

  metadata {
    name      = "sonarqube-admin-access"
    namespace = "tools"

    annotations {
      "jenkins.io/credentials-description" = "Terraform managed Sonarqube credentials"
    }

    labels {
      "jenkins.io/credentials-type" = "usernamePassword"
    }
  }

  data = {
    "username" = "${var.sonarqube["username"]}"
    "password" = "${var.sonarqube["admin_password"]}"
  }
}

resource "kubernetes_secret" "nexus_docker_creds" {
  metadata {
    name      = "nexus-docker-creds"
    namespace = "tools"

    annotations {
      "jenkins.io/credentials-description" = "Terraform managed Nexus Credentials"
    }

    labels {
      "jenkins.io/credentials-type" = "usernamePassword"
    }
  }

  data = {
    "username" = "${var.nexus["username"]}"
    "password" = "${var.nexus["admin_password"]}"
  }

  depends_on = ["kubernetes_namespace.create_namespaces"]
}

resource "kubernetes_secret" "github_common_access" {
  metadata {
    name      = "github-common-access"
    namespace = "tools"

    labels = {
      "jenkins.io/credentials-type" = "usernamePassword"
    }

    annotations = {
      "jenkins.io/credentials-description" = "Terraform managed Github Creds"
    }
  }

  data = {
    "username" = "${var.jenkins["git_username"]}"
    "password" = "${var.jenkins["git_token"]}"
  }

  depends_on = ["kubernetes_namespace.create_namespaces"]
}

resource "kubernetes_secret" "common_tools_config" {
  metadata {
    name      = "common-tools-config"
    namespace = "tools"

    labels = {
      "jenkins.io/credentials-type" = "secretFile"
    }

    annotations = {
      "jenkins.io/credentials-description" = "Terraform managed common_tools.tfvars"
    }
  }

  data = {
    filename = "common_tools.tfvars"
    "data"   = "${file("common_tools.tfvars")}"
  }

  depends_on = ["kubernetes_namespace.create_namespaces"]
}

resource "kubernetes_secret" "slack_token" {
  metadata {
    name      = "slack-token"
    namespace = "tools"

    labels = {
      "jenkins.io/credentials-type" = "secretText"
    }

    annotations = {
      "jenkins.io/credentials-description" = "Terraform managed slack credentials"
    }
  }

  data = {
    "text" = "${var.jenkins["slack_token"]}"
  }

  depends_on = ["kubernetes_namespace.create_namespaces"]
}
