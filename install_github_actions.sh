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
    mkdir -p /home/useragent/.actions-runner/ && cd /home/useragent/.actions-runner/
    curl -o actions-runner-linux-x64-2.319.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.319.1/actions-runner-linux-x64-2.319.1.tar.gz
    echo "3f6efb7488a183e291fc2c62876e14c9ee732864173734facc85a1bfb1744464  actions-runner-linux-x64-2.319.1.tar.gz" | sha256sum -c -
    tar xzf ./actions-runner-linux-x64-2.319.1.tar.gz
    rm actions-runner-*.tar.gz
    ./bin/installdependencies.sh
    ;;
  falsefalse)
    echo "Neither arm64 nor amd64 architectures detected"
    exit 1
    ;;
  falsetrue)
    mkdir -p /home/useragent/.actions-runner/ && cd /home/useragent/.actions-runner/
    curl -o actions-runner-linux-arm64-2.319.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.319.1/actions-runner-linux-arm64-2.319.1.tar.gz
    echo "03d993c65e0c4daa5e3bf5a5a35ba356f363bdb5ceb6b5808fd52fdb813dd8e8  actions-runner-linux-arm64-2.319.1.tar.gz" | sha256sum -c -
    tar xzf ./actions-runner-linux-arm64-2.319.1.tar.gz
    rm actions-runner-*.tar.gz
    ./bin/installdependencies.sh
    ;;
esac
