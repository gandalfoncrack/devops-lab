FROM jenkins/jenkins:lts
USER root
RUN apt-get update \
 && apt-get install -y curl gnupg docker.io openssh-client python3 python3-venv \
 && curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com bookworm main" > /etc/apt/sources.list.d/hashicorp.list \
 && apt-get update \
 && apt-get install -y terraform \
 && python3 -m venv /opt/ansible \
 && /opt/ansible/bin/pip install --no-cache-dir ansible-core \
 && ln -s /opt/ansible/bin/ansible /opt/ansible/bin/ansible-playbook /usr/local/bin/ \
 && rm -rf /var/lib/apt/lists/*
USER jenkins
