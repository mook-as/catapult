#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


if [ -n "$SCF_CHART" ]; then
# save SCF_CHART on cap-values configmap
    kubectl patch -n kube-system configmap cap-values -p $'data:\n chart: "'$SCF_CHART'"'
fi

if [ "${SCF_OPERATOR}" == "true" ]; then

    helm_upgrade susecf-scf kubecf/ \
                 --namespace scf \
                 --values scf-config-values.yaml
    sleep 10

else

    SECRET=$(kubectl get pods --namespace uaa \
    -o jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')

    CA_CERT="$(kubectl get secret "$SECRET" --namespace uaa \
    -o jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"

    if [ "$UAA_UPGRADE" == true ]; then

        helm_upgrade susecf-uaa helm/uaa/ --values scf-config-values.yaml \
        --set "secrets.UAA_CA_CERT=${CA_CERT}"

        wait_ns uaa

    fi


    helm_upgrade susecf-scf helm/cf/ --values scf-config-values.yaml \
    --set "secrets.UAA_CA_CERT=${CA_CERT}"
fi

wait_ns scf

ok "SCF deployment upgraded successfully"
