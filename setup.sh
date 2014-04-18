#!/usr/bin/env bash

set -e

function green() {
  echo -e '\e[1;32m'"$*"'\e[0m'
}

function magenta() {
  echo -e '\e[1;35m'"$*"'\e[0m'
}

function drop_priv() {
  green "$*"
  sudo "PATH=$PATH" -u "$SUDO_USER" -s "$@"
}

function with_priv() {
  magenta "$*"
  "$@"
}

already_apt_get_updated=false
function apt_get_update_once() {
  if [[ "$already_apt_get_updated" != "true" ]]; then
    with_priv apt-get -qq update
    already_apt_get_updated=true
  fi
}

function install_chef() {
  OMNIBUS_URL="https://www.opscode.com/chef/install.sh"

  if [[ ! -x /opt/chef/bin/chef-solo ]]; then
    apt_get_update_once

    chef_install_script=$(mktemp)
    with_priv wget -O "$chef_install_script" "$OMNIBUS_URL"
    with_priv bash "$chef_install_script"
    rm "$chef_install_script"
  fi
}

function install_prereqs() {
  PREREQ_PACKAGES="
    libxslt1-dev
    libxml2-dev
    build-essential
    git-core
  "

  for package in $PREREQ_PACKAGES; do
    if ! dpkg -s "$package" >/dev/null 2>&1; then
      apt_get_update_once
      with_priv apt-get -qq install "$package"
    fi
  done
}

function main() {
  if [[ $(id -u) != 0 ]]; then
    sudo -p "Chef Accelerator needs to run as root, but will drop privledge for some operations (shown in green)." $0 "$@"
    exit
  fi

  install_chef
  install_prereqs

  export PATH="/opt/chef/embedded/bin:$PATH"

  drop_priv mkdir -p build
  drop_priv bundle install --path .ruby
  drop_priv bundle exec berks install --path build/cookbooks
  drop_priv bundle exec ruby generate_node_json.rb node.yml build/node.json

  with_priv mkdir -pv /etc/chef /var/chef
  with_priv rm -rf /var/chef/{cookbooks,node.json}
  with_priv cp -r  build/{cookbooks,node.json} /var/chef
  with_priv cp solo.rb /etc/chef/solo.rb

  with_priv chef-solo -j /var/chef/node.json
}

if [[ $0 = ${BASH_SOURCE} ]]; then
  main
fi
