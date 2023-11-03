#!/bin/bash

cd ~/.actions-runner/

echo "--------------------------------$(date)--------------------------------"

check_vars()
{
    var_names=("$@")
    for var_name in "${var_names[@]}"; do
        [ -z "${!var_name}" ] && echo "$var_name is unset." && var_unset=true
    done
    [ -n "$var_unset" ] && exit 1
    return 0
}

check_vars KUBE_CONFIG GITHUB_ACTIONS_URL GITHUB_ACTIONS_TOKEN GITHUB_ACTIONS_AGENT_NAME

#decode KUBE_CONFIG
echo "$KUBE_CONFIG" > ~/.kube/config &&
#confirm if svc.sh already exists if exists it was already configures
if [ ! -e svc.sh ]; then 
    ./config.sh --replace --url $GITHUB_ACTIONS_URL --token $GITHUB_ACTIONS_TOKEN --name $GITHUB_ACTIONS_AGENT_NAME --labels $GITHUB_ACTIONS_AGENT_NAME --work /home/useragent/_work --unattended;
fi &&
./run.sh