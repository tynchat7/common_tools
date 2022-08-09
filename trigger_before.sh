#!/bin/bash
echo -e "Checking for common_tools_config secret update."
if kubectl get pods &> /dev/null; then
  kubectl get secret common-tools-config -n tools &> /dev/null
  if [ $? -eq 0 ]; then
    echo -e "${green} Updated <common-tools-config> to newer version ${reset}"
    terraform apply -var-file=common_tools.tfvars  -target=kubernetes_secret.common_tools_config -auto-approve  &> /dev/null
  fi
else
  echo -e "${red}Cluster is not up and running skipping update <common-tools-config> update ${reset}"
fi