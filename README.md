**THE COMMON_TOOLS DEPLOYMENT STEPS**


## Prerequisites:
1. Make sure you have finished with [cluster-infrastructure](https://github.com/fuchicorp/cluster-infrastructure) deployment
2. Make sure you have the domain name configured
3. Make sure you can see nodes `kubectl get nodes` 


## Terraform Version 
```
Terraform v0.11.15
+ provider.helm v1.3.2
+ provider.kubernetes v1.13.4
+ provider.local v1.4.0
+ provider.null v2.1.2
+ provider.template v2.1.2
```

**A - THE STEPS OF CONFIGURATION:**


1. Clone the repository from GitHub

```
git clone git@github.com:fuchicorp/common_tools.git
cd common_tools
```

2. Make sure `~/google-credentials.json` is exist and can be used by common tools 
```
ls -l ~/google-credentials.json  
```


3. Create Github oAuth Credentials under your github account. </br>
Please note that once you generate your client secret you will not be able to repull this information.  You can generate new secret if you lose your inital seceret text.  You will need both the Client ID and Client secret for each App for the common_tools.tvars configuration in the next step. </br>

   - Go to your github profile page than go Settings>> Developer Settings >>  oAuth Apps </br>
   - You have to create a new oAuth application for each of the resource ( Jenkins, Grafana, Sonarqube )</br>
   - Replace "fuchicorp.com" with your domain name. <br>
- Jenkins
```
     Register a new oAuth application:
     Application Name: Jenkins
     HomePage URL, add your domain name: https://jenkins.yourdomain.com
     Authorization callback URL: https://jenkins.yourdomain.com/securityRealm/finishLogin
     
```
- Grafana
 ```    
     Register a new oAuth application:
     Application Name: Grafana
     HomePage URL, add your domain name: https://grafana.yourdomain.com/login
     Authorization callback URL: https://grafana.yourdomain.com/login
     
```
- Sonarqube
 ```
     Register a new oAuth application:
     Application Name: Sonarqube 
     HomePage URL, add your domain name: https://sonarqube.yourdomain.com
     Authorization callback URL: https://sonarqube.yourdomain.com/oauth2/callback
```
4. Create `common_tools.tfvars` file inside common_tools directory. </br>
#Spelling of `common_tools.tfvars` must be exactly same syntax see [WIKI](https://github.com/fuchicorp/common_tools/wiki/Create-a-jenkins-secret-type-SecretFile-on-kubernetes-using-terraform) for more info

5. Configure  the `common_tools.tfvars` file 

```
# Your main configurations for common tools 
google_bucket_name         = "" # Write your bucket name from google cloud
google_project_id          = "" # Write your project id from google cloud
google_domain_name         = "" # your domain name
deployment_environment     = "tools" # Required to leave as tools
deployment_name            = "common-tools" # Configure a deployment name

## Cert manager configuration !!
cert_manager {
  version                  = "1.7.2"
  enabled                  = "true"
}

## Your Kubernetes Dashboard configuration !!
kube_dashboard = {
  version                  = "5.3.0" # Put dashboard helm chart version to deploy here
  enabled                  = "false" # Set to True if you want to deploy dashboard chart
}

## External DNS configurations
external_dns {
  version                  = "6.1.4"
  enabled                  = "true"
}

## The Gitlab configurations
gitlab {
  version                  = "5.7.7"
  enabled                  = "false"
}

## Your Grafana configuration !!
grafana = {
  grafana_username         = "" # Configure grafana admin username
  grafana_password         = "" # Configure strong password for Grafana
  grafana_auth_client_id   = "" # Client ID for grafana from your github oAuth Apps
  grafana_client_secret    = "" # Client Secret for grafana from your github oAuth Apps
  slack_url                = "https://fuchicorp.slack.com" # Please keep example until we fixed issue with slack notifications
  version                  = "6.20.5"
  enabled                  = "true"
}

## Ingress-controller configurations
ingress_controller {
  version                  = "4.0.19"
  enabled                  = "true"
}

# Your Jenkins configuration !!
jenkins = {
  admin_user               = "" # Configure jenkins admin username
  admin_password           = "" # Configure strong password for Jenkins admin
  jenkins_auth_client_id   = "" # Client ID for jenkins from your github oAuth Apps
  jenkins_auth_secret      = "" # Client Secret for jenkins from your github oAuth Apps
  git_token                = "" # Github token
  git_username             = "" # Github username
  version                  = "2.19.0"
  enabled                  = "true"
}

# Your Nexus configuration !!
nexus = {
  admin_password            = "" # Configure strong password for Nexus admin 
  version                   = "37.3.1" # Configure your nexus helm chart version here
  enabled                   = "true"
}

## Your Prometheus configuration !!
prometheus = {
  deployment_name           = "prometheus" # Configure your prometheus deployment name
  version                   = "15.3.0" # Configure your prometheus helm chart version here
  enabled                   = "true"
}


## Your Rancher configuration !!
rancher = {
  rancher_password          = "iPlhGpfbMEQIK5X9" # Configure strong password for Nexus admin
  version                   = "2.5.9" # Put rancher helm chart version to deploy here
  enabled                   = "false" # Set to True if you want to deploy rancher chart
}


# Your SonarQube configuration !!
sonarqube = {
  sonarqube_auth_client_id = "" # Client ID for Sonarqube from your github oAuth Apps
  sonarqube_auth_secret    = "" # Client Secret for Sonarqube from your github oAuth Apps
  admin_password           = "" # Configure a strong password for sonarqube admin
  version                  = "3.0.0"
  enabled                  = "true"
}


## The spinnaker configurations
spinnaker {
  version                  = "2.2.7"
  enabled                  = "false"
}

## Hashicorp Vault configuration
vault = {
  version                  = "0.19.0"
  enabled                  = "true"
}

## Hashicorp Waypoint configuration
waypoint = {
  version                  = "0.1.8"
  enabled                  = "false"
}

## The WikiJS configurations
wikijs {
  pvc_size                 = "2Gi"
  version                  = "6.2.1"
  enabled                  = "false"
}

#create lists of trusted IP addresses or IP ranges from which your users can access your domains
common_tools_access = [ 
  "10.16.0.27/8",       # Cluster access
  "34.133.222.35/32",   # Fuchicorp bastion host
  "24.14.53.36/32",     # Farkhod Sadykov
  "67.167.220.165/32",  # Kelly Salrin
]

# Set to <false> to do not show password on terraform output
show_passwords            = "true" # Set to false when presenting a demo or showing output to someone

```
   

6. After you have configured all of the above now you run commands below to create the resources.
commands:

```
source set-env.sh common_tools.tfvars
terraform apply -var-file=$DATAFILE
```

If you are facing any issues please submit the issue here https://github.com/fuchicorp/common_tools/issues
