FROM ubuntu:22.04 AS mybaseimage
LABEL org.opencontainers.image.authors="eric.s.landry@gmail.com"

RUN apt-get update && \
    apt-get install -y \
        curl \
        haproxy \
        iputils-ping \
        iproute2 \
        keepalived \
        net-tools \
        netcat \
        sudo \
        openssh-client \
        openssh-server \
        sshpass \
        vim

# Configure SSH
COPY <<EOF /etc/ssh/ssh_config.d/user.conf
Host *
  StrictHostKeyChecking no
  LogLevel QUIET
EOF

# Configure the user and its environment
RUN useradd -rms /bin/bash -d /home/user -g root -G sudo -u 1001 user \
    && echo 'user:user' | chpasswd \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER user
WORKDIR /home/user
ENV HOME /home/user
RUN touch ~/.sudo_as_admin_successful \
    && touch ~/.hushlogin
RUN ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519 \
    && cp ~/.ssh/id_ed25519.pub ~/.ssh/authorized_keys

EXPOSE 22
ENTRYPOINT sudo service ssh --full-restart \
    && if [ -f /etc/haproxy.cnf ]; then sudo haproxy -D -f /etc/haproxy.cnf; fi \
    && if [ -f /etc/keepalived/keepalived.conf ]; then sudo keepalived --log-console; fi \
    && tail -f /dev/null
