#!/usr/bin/env bash

## Change this if terraform configurations got changed
SUPPORTED_TF_VERSION="v0.11.15"

## Making sure that GIT_TOKEN provded by FuchiCorp Member
if [ -z "$GIT_TOKEN" ]
then
  echo "To execute this script you need to provide <GIT_TOKEN> env!!!"
  return 1 
fi

## Triggering the trigger_before.sh 
if [ -f 'trigger_before.sh' ]; then echo 'Found trigger before script.'; bash "trigger_before.sh"; fi

## Downloading the set-env.sh script 
wget --quiet "--header=Authorization: token $GIT_TOKEN" "https://raw.githubusercontent.com/fuchicorp/common_scripts/master/set-environments/terraform/set-env.sh" \
  -O set-env >/dev/null

## If download was success sourcing the variables
if [ $? != 0 ]; then echo 'Make sure the GIT_TOKEN is valid!!'; fi 
source 'set-env' "$@" && rm -rf 'set-env'