#!/usr/bin/env bash

# Destroys an existing Caasp4 cluster on openstack
#
# Requirements:
# - Built skuba docker image
# - Sourced openrc.sh
# - Key on the ssh keyring

. ./defaults.sh
. ./lib/skuba.sh
. ../../include/common.sh

if [ -d "$BUILD_DIR" ]; then
    if [[ ! -v OS_PASSWORD ]]; then
        err "Missing openstack credentials" && exit 1
    fi

    . .envrc
    if kubectl get storageclass 2>/dev/null | grep -qi persistent; then
        kubectl delete storageclass persistent
        wait
    fi

    if [ -d deployment ]; then
        pushd deployment
        info "Destroying infrastructure with Terraform…"
        skuba_container terraform destroy -auto-approve
        info "Terraform infrastructure destroyed"
        popd
    else
        info "No Terraform infrastructure present"
    fi

    popd
    rm -rf "$BUILD_DIR"
fi
ok "CaaSP4 on Openstack succesfully destroyed!"
