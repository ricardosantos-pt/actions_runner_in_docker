#!/bin/bash

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

check_vars GITHUB_ACTIONS_URL GITHUB_ACTIONS_TOKEN GITHUB_ACTIONS_AGENT_NAME

if [ ! -z "$DOCKER_REGISTRY_URL" ] || [ ! -z "$DOCKER_REGISTRY_USERNAME" ] || [ ! -z "$DOCKER_REGISTRY_TOKEN" ]; then
    check_vars DOCKER_REGISTRY_URL DOCKER_REGISTRY_USERNAME DOCKER_REGISTRY_TOKEN
fi

#check docker credential
expected_registry=$DOCKER_REGISTRY_URL
expected_username=$DOCKER_REGISTRY_USERNAME

credentials=""

cache_folder=~/.cache_volume
cache_folder_exists="false"
if [[ -d "$cache_folder" ]]; then
  cache_folder_exists="true"
  if [[ -d "$cache_folder/docker_cache/" ]]; then
    echo "copying cache docker"
    mkdir -p ~/.docker
    cd "$cache_folder/docker_cache"
    files_to_cache=$(find . -type f)
    rsync -av --files-from=<(echo "$files_to_cache") "$cache_folder/docker_cache/" ~/.docker
  fi
  if [[ -d "$cache_folder/github_actions_cache/" ]]; then
    echo "copying cache actions runner"
    cd "$cache_folder/github_actions_cache"
    files_to_cache=$(find . -type f)
    rsync -av --files-from=<(echo "$files_to_cache") "$cache_folder/github_actions_cache/" ~/.actions-runner
  fi
fi &&
if [ -z "$KUBE_CONFIG" ]; then
    echo "$KUBE_CONFIG" > ~/.kube/config
fi &&
if [ -n "$DOCKER_REGISTRY_URL" ] && [ -n "$DOCKER_REGISTRY_USERNAME" ] && [ -n "$DOCKER_REGISTRY_TOKEN" ]; then
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
        if [[ "$cache_folder_exists" == "true" ]]; then
            cd ~/.docker/
            echo "Caching docker"
            mkdir -p "$cache_folder/docker_cache/"
            files_to_cache=$(find . -type f)
            rsync -av --files-from=<(echo "$files_to_cache") ~/.docker "$cache_folder/docker_cache/"
        fi
    fi
fi &&
#confirm if svc.sh already exists if exists it was already configures
if [ ! -e ~/.actions-runner/svc.sh ]; then 
    cd ~/.actions-runner/

    if [[ "$cache_folder_exists" == "true" ]]; then
        find . -type f -exec md5sum {} \; > before.md5
    fi

    ./config.sh --replace --url $GITHUB_ACTIONS_URL --token $GITHUB_ACTIONS_TOKEN --name $GITHUB_ACTIONS_AGENT_NAME --labels $GITHUB_ACTIONS_AGENT_NAME --work /home/useragent/_work --unattended; 
    pid=$!
    wait $pid

    if [ $? -eq 0 ]; then
        if [[ "$cache_folder_exists" == "true" ]]; then
            echo "Caching github runner"
            find . -type f -exec md5sum {} \; | grep -E -v 'before.md5|after.md5' > after.md5
            files_changed=$(diff before.md5 after.md5 | awk '$1 == ">" {print $3}')
            mkdir -p "$cache_folder/github_actions_cache/"
            rsync -av --files-from=<(echo "$files_changed") ~/.actions-runner/ "$cache_folder/github_actions_cache/"
            rm -f before.md5 after.md5
        fi
    else
        echo "Previous command failed, skipping the if statement."
    fi
fi &&
#run actions
~/.actions-runner/run.sh
