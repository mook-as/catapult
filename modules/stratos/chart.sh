#!/usr/bin/env bash

. ../../include/common.sh
. .envrc

set -Eexuo pipefail
debug_mode

if [ -z "$STRATOS_CHART" ]; then
    warn "No chart url given - using latest public release from GH"
        STRATOS_CHART=$(curl -s https://api.github.com/repos/cloudfoundry/stratos/releases/latest | grep "browser_download_url.*zip" | cut -d : -f 2,3 | tr -d \" | tr -d " ")
fi

if echo "$STRATOS_CHART" | grep -q "http"; then
    curl -L "$STRATOS_CHART" -o stratos-chart
else
    cp -rfv "$STRATOS_CHART" stratos-chart
fi

# remove old uncompressed chart
rm -rf console

if echo "$STRATOS_CHART" | grep -q "tgz"; then
    tar -xvf stratos-chart -C ./
else
    unzip -o stratos-chart
fi
rm stratos-chart

ok "Chart uncompressed"