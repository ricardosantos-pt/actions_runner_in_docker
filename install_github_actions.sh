#!/bin/bash

cd /home/useragent
is_arm64=$( [[ $(dpkg --print-architecture) = "arm64" ]] && echo true || echo false )
is_amd64=$( [[ $(dpkg --print-architecture) = "amd64" ]] && echo true || echo false )

case "$is_amd64$is_arm64" in
  truetrue)
    echo "Both arm64 and amd64 architectures detected"
    exit 1
    ;;
  truefalse)
    mkdir -p .actions-runner && cd .actions-runner
    curl -o actions-runner-linux-x64-2.317.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.317.0/actions-runner-linux-x64-2.317.0.tar.gz
    echo "9e883d210df8c6028aff475475a457d380353f9d01877d51cc01a17b2a91161d  actions-runner-linux-x64-2.317.0.tar.gz" | sha256sum -c -
    tar xzf ./actions-runner-linux-x64-2.317.0.tar.gz
    rm actions-runner-*.tar.gz
    ./bin/installdependencies.sh
    ;;
  falsefalse)
    echo "Neither arm64 nor amd64 architectures detected"
    exit 1
    ;;
  falsetrue)
    mkdir -p .actions-runner && cd .actions-runner
    curl -o actions-runner-linux-arm64-2.317.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.317.0/actions-runner-linux-arm64-2.317.0.tar.gz
    echo "7e8e2095d2c30bbaa3d2ef03505622b883d9cb985add6596dbe2f234ece308f3  actions-runner-linux-arm64-2.317.0.tar.gz" | sha256sum -c -
    tar xzf ./actions-runner-linux-arm64-2.317.0.tar.gz
    rm actions-runner-*.tar.gz
    ./bin/installdependencies.sh
    ;;
esac
