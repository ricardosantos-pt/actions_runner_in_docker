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

cache_folder=~/.cache_volume
cache_folder_exists="false"
if [[ -d "$cache_folder" ]]; then
  cache_folder_exists="true"
  if [[ -d "$cache_folder/github_actions_cache/" ]]; then
    echo "copying cache actions runner"
    cd "$cache_folder/github_actions_cache"
    files_to_cache=$(find . -type f)
    rsync -av --files-from=<(echo "$files_to_cache") "$cache_folder/github_actions_cache/" ~/.actions-runner
  fi
fi &&
if [ -n "$DOCKER_REGISTRY_URL" ] && [ -n "$DOCKER_REGISTRY_USERNAME" ] && [ -n "$DOCKER_REGISTRY_TOKEN" ]; then
    docker login $DOCKER_REGISTRY_URL -u $DOCKER_REGISTRY_USERNAME -p $DOCKER_REGISTRY_TOKEN;
fi &&
#confirm if svc.sh already exists if exists it was already configures
if [ ! -e ~/.actions-runner/svc.sh ]; then 
    cd ~/.actions-runner/

    if [[ "$cache_folder_exists" == "true" ]]; then
        find . -type f -exec md5sum {} \; > before.md5
    fi

    ./config.sh --replace --url $GITHUB_ACTIONS_URL --token $GITHUB_ACTIONS_TOKEN --name $GITHUB_ACTIONS_AGENT_NAME --labels $GITHUB_ACTIONS_AGENT_NAME --work /home/useragent/_work --unattended; 
    config_status=$?

    if [ $config_status -eq 0 ]; then
        mkdir -p "$cache_folder/github_actions_cache/"
        echo "Caching github runner"
        find . -type f -exec md5sum {} \; | grep -E -v 'before.md5|after.md5' > after.md5
        files_changed=$(diff before.md5 after.md5 | awk '$1 == ">" {print $3}')
        rsync -av --files-from=<(echo "$files_changed") ~/.actions-runner/ "$cache_folder/github_actions_cache/"
        rm -f before.md5 after.md5
    else
        echo "Previous command failed, skipping the if statement."
    fi
fi &&
#run actions
~/.actions-runner/run.sh
