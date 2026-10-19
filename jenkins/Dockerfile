FROM ghcr.io/opentofu/opentofu:minimal AS tofu

FROM jenkins/jenkins:lts
USER root
COPY --from=tofu /usr/local/bin/tofu /usr/local/bin/tofu
RUN apt-get update \
 && apt-get install -y curl docker.io openssh-client python3 python3-venv \
 && python3 -m venv /opt/ansible \
 && /opt/ansible/bin/pip install --no-cache-dir ansible-core \
 && ln -s /opt/ansible/bin/ansible /opt/ansible/bin/ansible-playbook /usr/local/bin/ \
 && rm -rf /var/lib/apt/lists/*
USER jenkins
