#!/bin/bash

# prerequisites: curl, git, ansible, python
# mandatory environment variables: ANSIBLE_VAR_NGINX_LE_ACCOUNT, ANSIBLE_VAR_NGINX_LE_PRIMARY_DOMAIN
#
# usage:
# curl -s https://raw.githubusercontent.com/hleb-rubanau/ansible-role-wsid-idp-basic-bootstrap/master/bootstrap.sh | /bin/bash
# 
# warnings:
#   Playbook is generated, and roles installed into `./roles` subdir *in current directory*
#
#   This script purpose is solely to provision new bare server with initial WSID identity, 
#   so that server could further fetch private recipes and configuration parameters using WSID authentication model
#
#   If you do *not* plan using nginx-letsencrypted feel free to build your own role/playbook on top of wsid-idp-basic
# 

set -e 
set -p pipefail

DEFAULT_BOOTSTRAP_IDENTITIES='["bootstrap"]'
PLAYBOOK_FILE_NAME=wsid_idp_playbook.yml

# Prerequisites  (presumed to be installed): curl, git, ansible

preconfigure_ansible() {
    if [ -z "$ANSIBLE_VAR_NGINX_LE_ACCOUNT" ] || [ -z "$ANSIBLE_VAR_NGINX_LE_PRIMARY_DOMAIN" ]; then
        echo "Please, export ANSIBLE_VAR_NGINX_LE_ACCOUNT and ANSIBLE_VAR_NGINX_LE_PRIMARY_DOMAIN before start" >&2
    fi

    echo "Configuring local ansible"
    curl -s https://gitlab.com/Rubanau/cloud-tools/raw/master/configure_local_ansible.sh | /bin/bash
}


initialize_playbook() {
    echo "Generating playbook file"
    tee $PLAYBOOK_FILE_NAME <<'PLAYBOOK'
---
- hosts: localhost
  vars:
    nginx_le_extra_mounts:
      - "{ \"type\": \"bind\", \"source\": \"/usr/share/wsid\", \"target\": \"/usr/share/wsid\" }"
      - "{ \"type\": \"bind\", \"source\": \"/var/run/wsid/public\", \"target\": \"/var/run/wsid/public\" }"
    nginx_le_mode: prod
    nginx_le_brave_mode: true
    nginx_le_compose_version: "3.2" 
    nginx_le_logging_options_inline: "tag: nginx"
  roles:
    - ansible-role-wsid-idp-basic-bootstrap
PLAYBOOK
}


export ANSIBLE_VAR_WSID_IDENTITIES=${ANSIBLE_VAR_WSID_IDENTITIES:-$DEFAULT_BOOTSTRAP_IDENTITIES}
preconfigure_ansible
initialize_playbook
set -x
ansible-galaxy install -p ./roles https://github.com/hleb-rubanau/ansible-role-wsid-idp-basic-bootstrap.git
exec ansible-playbook run $PLAYBOOK_FILE_NAME
