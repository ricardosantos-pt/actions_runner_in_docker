FROM --platform=$TARGETPLATFORM debian:bookworm-slim

RUN useradd -ms /bin/bash useragent
WORKDIR /home/useragent/

RUN apt update && apt install curl coreutils apt-utils python3 ca-certificates gnupg rsync jq -y 

#install only docker cli and compose and buildx
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN chmod a+r /etc/apt/keyrings/docker.gpg
RUN echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt update && apt install docker-ce-cli docker-buildx-plugin docker-compose-plugin

# install kubectl
RUN mkdir -p /etc/apt/keyrings/
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-focal main" | tee /etc/apt/sources.list.d/kubernetes.list
RUN apt update && apt-get install -y kubectl

# install github runner
COPY ./install_github_actions.sh .
RUN chmod +x /home/useragent/install_github_actions.sh
RUN ./install_github_actions.sh
RUN rm ./install_github_actions.sh

RUN mkdir -p /home/useragent/.kube/
RUN mkdir -p /home/useragent/_work/
RUN chown -R useragent /home/useragent/.kube/
RUN chown -R useragent /home/useragent/_work/
RUN chown -R useragent /home/useragent/.actions-runner/

COPY ./actions-runner/entrypoint.sh .
RUN chmod +x /home/useragent/entrypoint.sh

COPY ./emvsubt.py .
RUN chmod +x /home/useragent/emvsubt.py
RUN echo 'alias emvsubt="~/emvsubt.py"' >> /home/useragent/.bashrc

USER useragent
WORKDIR /home/useragent/

ENTRYPOINT ./entrypoint.sh

