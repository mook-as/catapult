#!/bin/bash

# SCF options
#############

# scf-chart revelant:

CHART_URL="${CHART_URL:-}" # FIXME deprecated, used in SCF_CHART
SCF_CHART="${SCF_CHART:-$CHART_URL}"

SCF_HELM_VERSION="${SCF_HELM_VERSION:-}"
OPERATOR_CHART_URL="${OPERATOR_CHART_URL:-latest}"

# scf-gen-config relevant:

GARDEN_ROOTFS_DRIVER="${GARDEN_ROOTFS_DRIVER:-overlay-xfs}"
DIEGO_SIZING="${DIEGO_SIZING:-$SIZING}"
STORAGECLASS="${STORAGECLASS:-persistent}"
AUTOSCALER="${AUTOSCALER:-false}"

EMBEDDED_UAA="${EMBEDDED_UAA:-false}"

HA="${HA:-false}"
if [ "$HA" = "true" ]; then
    SIZING="${SIZING:-2}"
else
    SIZING="${SIZING:-1}"
fi

UAA_UPGRADE="${UAA_UPGRADE:-true}"

OVERRIDE="${OVERRIDE:-}"
CONFIG_OVERRIDE="${CONFIG_OVERRIDE:-$OVERRIDE}"

SCF_TESTGROUP="${SCF_TESTGROUP:-false}"

# scf-build relevant:

SCF_LOCAL="${SCF_LOCAL:-}"

# relevant to several:

SCF_OPERATOR="${SCF_OPERATOR:-false}"
HELM_VERSION="${HELM_VERSION:-v3.1.1}"
