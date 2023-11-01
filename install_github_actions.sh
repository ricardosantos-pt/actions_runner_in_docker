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
    curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
    echo "29fc8cf2dab4c195bb147384e7e2c94cfd4d4022c793b346a6175435265aa278  actions-runner-linux-x64-2.311.0.tar.gz" | sha256sum -c -
    tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz
    rm actions-runner-*.tar.gz
    ./bin/installdependencies.sh
    ;;
  falsefalse)
    echo "Neither arm64 nor amd64 architectures detected"
    exit 1
    ;;
  falsetrue)
    mkdir -p .actions-runner && cd .actions-runner
    curl -o actions-runner-linux-arm64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-arm64-2.311.0.tar.gz
    echo "5d13b77e0aa5306b6c03e234ad1da4d9c6aa7831d26fd7e37a3656e77153611e  actions-runner-linux-arm64-2.311.0.tar.gz" | sha256sum -c -
    tar xzf ./actions-runner-linux-arm64-2.311.0.tar.gz
    rm actions-runner-*.tar.gz
    ./bin/installdependencies.sh
    ;;
esac
