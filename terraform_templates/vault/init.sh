#!/bin/sh
## Use following container vault:1.4.0
## Make sure folder name is not ending with /
apk add --no-cache curl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && mv kubectl /bin/
VAULT_ENDPOINT="http://vault-tools-internal:8200"

## Wait until the vault server is up and running  
while [ $(curl -X GET -s -o /dev/null -w "%{http_code}"  "$VAULT_ENDPOINT" -L ) != 200 ]
do
    echo "waiting for vault server..."
    sleep 2
done

## Getting the master keys from vault server 
MASTER_KEYS=$(vault operator init -address="$VAULT_ENDPOINT" -recovery-shares=5 -recovery-threshold=3 | grep -e "2:\|3:\|4:\|Token:" |  awk '{print $4}')
KEY_NUMBER=1
for key in $MASTER_KEYS
do
    if [[ $KEY_NUMBER != 4 ]]
    then
        MK=$(echo '{"key": "'"$key"'"}')
        kubectl create secret generic "vault-master-key-$KEY_NUMBER" --from-literal=key="$MK"
        curl --request PUT --data "$MK" "${VAULT_ENDPOINT}/v1/sys/unseal"
        KEY_NUMBER=$(( $KEY_NUMBER + 1 ))
    else
        MK=$(echo '{"key": "'"$key"'"}')
        kubectl create secret generic vault-token --from-literal=key="$MK"
    fi
done