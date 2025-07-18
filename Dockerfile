FROM ubuntu:24.04
LABEL maintainer="Eydel R.R."

ARG DEBIAN_FRONTEND=noninteractive

ENV pip_packages="ansible"

# # Install dependencies. (original)
# RUN apt-get update \
#     && apt-get install -y --no-install-recommends \
#        apt-utils \
#        build-essential \
#        locales \
#        libffi-dev \
#        libssl-dev \
#        libyaml-dev \
#        python3-dev \
#        python3-setuptools \
#        python3-pip \
#        python3-yaml \
#        software-properties-common \
#        rsyslog systemd systemd-cron sudo iproute2 \
#     && apt-get clean \
#     && rm -Rf /var/lib/apt/lists/* \
#     && rm -Rf /usr/share/doc && rm -Rf /usr/share/man
# RUN sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf

# # Fix potential UTF-8 errors with ansible-test.
# RUN locale-gen en_US.UTF-8


# Install dependencies.
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
       apt-utils \
       locales \
       python3-dev \
       python3-setuptools \
       python3-pip \
       python3-yaml \
       software-properties-common \
       rsyslog sudo iproute2 \
       openssh-server openssh-client git curl nano openssl tar jq less tree \
    && apt-get purge -y --auto-remove \
    && apt-get clean \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man
RUN sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf

# Fix potential UTF-8 errors with ansible-test.
RUN locale-gen en_US.UTF-8


# Remove useless Python environment warning flag.
RUN sudo rm -rf /usr/lib/python3.12/EXTERNALLY-MANAGED

# Install Ansible via Pip.
RUN pip3 install $pip_packages

COPY initctl_faker .
RUN chmod +x initctl_faker && rm -fr /sbin/initctl && ln -s /initctl_faker /sbin/initctl

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN echo "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts

# Remove unnecessary getty and udev targets that result in high CPU usage when using
# multiple containers with Molecule (https://github.com/ansible/molecule/issues/1104)
RUN rm -f /lib/systemd/system/systemd*udev* \
  && rm -f /lib/systemd/system/getty.target

# Configure ubuntu user
RUN --mount=type=cache,target=/root/.cache \
    echo "ubuntu:mysecret" | chpasswd \
    && echo "ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

VOLUME ["/sys/fs/cgroup", "/tmp", "/run"]
CMD ["/lib/systemd/systemd"]
