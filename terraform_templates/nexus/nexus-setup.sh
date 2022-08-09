#!/bin/bash
NEXUS_URL=$1
NEXUS_API_PATH="${NEXUS_URL}/service/rest/v1"
NEXUS_OLD_PWD=$2
NEXUS_NEW_PWD=$3
docker_repo='docker-repo'
helm_repo='helm-repo'
SCRIPT_NAME="change-admin-password"
SCRIPT_JSON=$(cat <<EOF
{
  "name": "${SCRIPT_NAME}",
  "type": "groovy",
  "content": "security.securitySystem.changePassword('admin', '${NEXUS_NEW_PWD}')"
}
EOF
) 

while [ "$(curl -X GET -s -o /dev/null -w "%{http_code}" -u admin:"${NEXUS_OLD_PWD}" "${NEXUS_URL}")" != "200" ]
do
  echo "INFO: waiting for nexus server..."
  sleep 4
done

## Uploading the script to the nexus server!
CHECK_CHANGE_PASSWORD_SCRIPT=$(curl  -s -o /dev/null -I -w "%{http_code}" -u "admin:${NEXUS_OLD_PWD}" "${NEXUS_API_PATH}/script/${SCRIPT_NAME}")
if [ "${CHECK_CHANGE_PASSWORD_SCRIPT}" == "404" ];then
  echo "INFO: Creating change admin password script in nexus server!"
  curl -s -H "Accept: application/json" -H "Content-Type: application/json" -d "${SCRIPT_JSON}" -u "admin:${NEXUS_OLD_PWD}" "${NEXUS_API_PATH}/script/"

elif [ "${CHECK_CHANGE_PASSWORD_SCRIPT}" == "200" ];then
  echo "INFO: Updating (${SCRIPT_NAME}) nexus script to make sure new password set!!"
  curl -s  -X PUT -H "Accept: application/json" -H "Content-Type: application/json" -d "${SCRIPT_JSON}" -u "admin:${NEXUS_OLD_PWD}" "${NEXUS_API_PATH}/script/${SCRIPT_NAME}"
  
elif [ "${CHECK_CHANGE_PASSWORD_SCRIPT}" == "401" ]; then
  echo "INFO: The script (${SCRIPT_NAME}) already uploaded!"
fi


## Making sure that script is executed
CHECK_RUN_STATUS=$(curl -X POST -s -o /dev/null -w "%{http_code}" -H "Content-Type: text/plain" -u "admin:${NEXUS_OLD_PWD}" "${NEXUS_API_PATH}/script/${SCRIPT_NAME}/run")
if [ "${CHECK_RUN_STATUS}" == "200" ];then
  echo "INFO: Executed the change password script!!"
else
  echo "WARNING: Skipping password execution script, password has already been changed!"
fi

if [ "$(curl -s -X GET -w "%{http_code}" -u admin:"${NEXUS_NEW_PWD}" "${NEXUS_URL}/repository/${docker_repo}/" -o /dev/null)" != "200" ]; then

  CHECK_DOCKER_REPO=$(curl -s -L -X POST -o /dev/null -w "%{http_code}" "${NEXUS_API_PATH}"/repositories/docker/hosted \
    -H 'Content-Type: application/json' -H 'Content-Type: text/plain' -u admin:"${NEXUS_NEW_PWD}" \
    --data '{"name": "'"${docker_repo}"'","online": true,"storage": {"blobStoreName": "default","strictContentTypeValidation": true,"writePolicy": "allow"},"cleanup": {"policyNames": ["cleanup"]},"docker": {"v1Enabled": true,"forceBasicAuth": true,"httpPort": 8085}}')

  if [ "${CHECK_DOCKER_REPO}" == "201" ];then
    echo "INFO: succeed! ${docker_repo} repository created."
  else
    echo "ERROR: failed to create the repository, error code ${CHECK_DOCKER_REPO}"
  fi
else
  echo "INFO: The '${docker_repo}' repository already exists"
fi

if [ "$(curl -s -X GET -w "%{http_code}" -u admin:"${NEXUS_NEW_PWD}" "${NEXUS_URL}/repository/${helm_repo}/" -o /dev/null)" != "200" ]; then
  
  REPO_CHECK=$(curl -s -L -X POST -o /dev/null -w "%{http_code}" "${NEXUS_API_PATH}"/repositories/helm/hosted \
    -H 'Content-Type: application/json' -H 'Content-Type: text/plain' -u admin:"${NEXUS_NEW_PWD}" \
    --data '{"name": "'"${helm_repo}"'","online": true,"storage": {"blobStoreName": "default","strictContentTypeValidation": true,"writePolicy": "allow_once"},"cleanup": {"policyNames": ["string"]},"component": {"proprietaryComponents": true}}')

  if [ "${REPO_CHECK}" == "201" ];then
    echo "INFO: succeed! ${helm_repo} repository created."
  else
    echo "ERROR: failed to create the repository, error code ${REPO_CHECK}"
  fi
else
  echo "INFO: The '${helm_repo}' repository already exists"
fi