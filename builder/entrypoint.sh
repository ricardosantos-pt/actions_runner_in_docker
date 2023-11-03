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

check_vars DOCKER_REGISTRY_URL DOCKER_REGISTRY_USERNAME DOCKER_REGISTRY_TOKEN GITHUB_ACTIONS_URL GITHUB_ACTIONS_TOKEN GITHUB_ACTIONS_AGENT_NAME

#check docker credential
expected_registry=$DOCKER_REGISTRY_URL
expected_username=$DOCKER_REGISTRY_USERNAME

credentials=""

if [ -e ~/.docker/config.json ]; then
    credentials=$(jq -r '.auths | to_entries[] | "\(.key) \(.value.auth)"' ~/.docker/config.json)
fi &&
if [ -n "$credentials" ]; then
    registry=$(echo "$credentials" | cut -d' ' -f1)
    username=$(echo "$credentials" | cut -d' ' -f2 | base64 --decode | cut -d':' -f1)
    
    if [ "$registry" != "$expected_registry" ] || [ "$username" != "$expected_username" ]; then
        echo "Current Docker login does not match the expected credentials."
        exit 1
    else
        echo "Docker Registry and Username:"
        echo "$registry $username"
    fi
else
    docker login $DOCKER_REGISTRY_URL -u $DOCKER_REGISTRY_USERNAME -p $DOCKER_REGISTRY_TOKEN; 
fi &&
#confirm if svc.sh already exists if exists it was already configures
if [ ! -e svc.sh ]; then 
    ./config.sh --replace --url $GITHUB_ACTIONS_URL --token $GITHUB_ACTIONS_TOKEN --name $GITHUB_ACTIONS_AGENT_NAME --labels $GITHUB_ACTIONS_AGENT_NAME --work /home/useragent/_work --unattended; 
fi &&
#run actions
./run.sh
