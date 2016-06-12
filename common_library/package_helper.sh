#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : package_helper.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-01-08>
## Updated: Time-stamp: <2016-06-12 15:35:22>
##-------------------------------------------------------------------

function install_package() {
    local package=${1?}
    local binary_name=${2:-""}
    [ -n "$binary_name" ] || binary_name="$package"

    # TODO: support more OS
    fail_unless_os "ubuntu"
    if ! which "$binary_name" 1>/dev/null 2>&1; then
        apt-get install -y "$package"
    fi
}

function install_package_list() {
    # install_package_list "wget,curl,git"
    local package_list=${1?}

    for package in ${package_list//,/ }; do
        install_package "$package"
    done
}

function ssh_apt_update() {
    set +e
    # Sample:
    #  ssh_apt_update "ssh -i $ssh_key_file -p $ssh_port -o StrictHostKeyChecking=no root@$ssh_server_ip"
    local ssh_command=${1?}
    echo "Run apt-get -y update"
    apt_get_output=$($ssh_command apt-get -y update)
    if echo "$apt_get_output" | "Hash Sum mismatch" 1>/dev/null 2>&1; then
        echo "apt-get update fail with complain of 'Hash Sum mismatch'"
        echo "rm -rf /var/lib/apt/lists/*"
        $ssh_command "rm -rf /var/lib/apt/lists/*"
        echo "Re-run apt-get -y update"
        $ssh_command "apt-get -y update"
    fi
    # TODO: unset -e without changing previous state
    set -e
}

function update_system() {
    local os_release_name
    os_release_name=$(os_release)
    if [ "$os_release_name" == "ubuntu" ]; then
        log "apt-get -y update"
        rm -rf /var/lib/apt/lists/*
        apt-get -y update
    fi

    if [ "$os_release_name" == "redhat" ] || [ "$os_release_name" == "centos" ]; then
        yum -y update
    fi
}

function install_chef() {
    local chef_version=${1:-"12.4.1"}
    if ! which chef-client 1>/dev/null 2>&1; then
        (echo "version=$chef_version"; curl -L https://www.opscode.com/chef/install.sh) |  bash
    fi
}

######################################################################
## File : package_helper.sh ends