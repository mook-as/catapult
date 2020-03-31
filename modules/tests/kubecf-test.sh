#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

smoke_tests_pod_name() {
  kubectl get pods --namespace "${KUBECF_NAMESPACE}" --output name 2> /dev/null | grep "smoke-tests"
}

sync_integration_tests_pod_name() {
  kubectl get pods --namespace "${KUBECF_NAMESPACE}" --output name 2> /dev/null | grep "sync-integration-tests"
}

cf_acceptance_tests_pod_name() {
  kubectl get pods --namespace "${KUBECF_NAMESPACE}" --output name 2> /dev/null | grep "acceptance-tests"
}

brain_tests_pod_name() {
  kubectl get pods --namespace "${KUBECF_NAMESPACE}" --output name 2> /dev/null | grep "brain-tests"
}

# Wait for tests pod to start.
wait_for_tests_pod() {
  local podname=$1
  local containername=$2
  local timeout="300"
  info "Waiting for container $containername in $podname"
  until [[ "$(kubectl get "${podname}" --namespace "${KUBECF_NAMESPACE}" --output jsonpath='{.status.containerStatuses[?(@.name == "'"$containername"'")].state.running}' 2> /dev/null)" != "" ]] || [[ "$(kubectl get "${podname}" --namespace "${KUBECF_NAMESPACE}" --output jsonpath='{.status.containerStatuses[?(@.name == "'"$containername"'")].state.terminated}' 2> /dev/null)" != "" ]]  || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
  if [[ "${timeout}" == 0 ]]; then return 1; fi
  return 0
}

# Delete any pending job
kubectl delete jobs -n "${KUBECF_NAMESPACE}"  --all --wait || true

timeout="300"
if [ "${KUBECF_TEST_SUITE}" == "smokes" ]; then
    kubectl patch qjob "${KUBECF_DEPLOYMENT_NAME}"-smoke-tests --namespace "${KUBECF_NAMESPACE}" --type merge --patch 'spec:
      trigger:
          strategy: now'
    info "Waiting for the smoke-tests pod to start..."
    until smoke_tests_pod_name || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
    if [[ "${timeout}" == 0 ]]; then return 1; fi
    pod_name="$(smoke_tests_pod_name)"
    container_name="smoke-tests-smoke-tests"
elif [ "${KUBECF_TEST_SUITE}" == "cats-internetless" ]; then

    info "Patching cats secret to use internetless CATS test suite"
		cats_secret_name="$(kubectl get qjobs -n "${KUBECF_NAMESPACE}" "${KUBECF_DEPLOYMENT_NAME}"-acceptance-tests -o json | jq -r '.spec.template.spec.template.spec.volumes[] | select(.name=="ig-resolved").secret.secretName')"
		cats_secret="$(kubectl get secrets --export -n "${KUBECF_NAMESPACE}" "${cats_secret_name}" -o yaml)"

    cats_updated_properties="$(kubectl get secret -n "${KUBECF_NAMESPACE}" "${cats_secret_name}" -o json  | jq -r '.data."properties.yaml"' | base64 -d | yq w - "instance_groups.(name==acceptance-tests).jobs.(name==acceptance-tests).properties.acceptance_tests.include" '=internetless' | base64 -w 0 )"
    echo $cats_secret
    echo $cats_updated_properties
    set -xe
    cats_updated="$(echo "$cats_secret" | yq w - 'data[properties.yaml]' $cats_updated_properties)"
    cats_updated="$(echo "$cats_updated" | yq w - 'metadata.name' 'susecf-scf-cats-internetless')"
    kubectl apply -f <(echo "${cats_updated}") -n "${KUBECF_NAMESPACE}"

    #kubectl patch secret "${cats_secret}" --type='json' -n "${KUBECF_NAMESPACE}" -p='[{"op" : "replace" ,"path" : "/data/properties.yaml" ,"value" : "'"${cats_updated_properties}"'"}]'

    kubectl patch qjob "${KUBECF_DEPLOYMENT_NAME}"-acceptance-tests --namespace "${KUBECF_NAMESPACE}" --type merge --patch 'spec:
      template:
        spec:
          template:
            spec:
              volumes:
              - name: ig-resolved
                secret:
                  secretName: susecf-scf-cats-internetless
      trigger:
          strategy: now'
    info "Waiting for the acceptance-tests pod to start..."
    until cf_acceptance_tests_pod_name || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
    if [[ "${timeout}" == 0 ]]; then return 1; fi
    pod_name="$(cf_acceptance_tests_pod_name)"
    container_name="acceptance-tests-acceptance-tests"
elif [ "${KUBECF_TEST_SUITE}" == "sits" ]; then
    kubectl patch qjob "${KUBECF_DEPLOYMENT_NAME}"-sync-integration-tests --namespace "${KUBECF_NAMESPACE}" --type merge --patch 'spec:
      trigger:
          strategy: now'
    info "Waiting for the sync-integration-tests pod to start..."
    until sync_integration_tests_pod_name || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
    if [[ "${timeout}" == 0 ]]; then return 1; fi
    pod_name="$(sync_integration_tests_pod_name)"
    container_name="sync-integration-tests-sync-integration-tests"
elif [ "${KUBECF_TEST_SUITE}" == "brain" ]; then
    kubectl patch qjob "${KUBECF_DEPLOYMENT_NAME}"-brain-tests --namespace "${KUBECF_NAMESPACE}" --type merge --patch 'spec:
      trigger:
          strategy: now'
    info "Waiting for the acceptance-tests-brain pod to start..."
    until brain_tests_pod_name || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
    if [[ "${timeout}" == 0 ]]; then return 1; fi
    pod_name="$(brain_tests_pod_name)"
    container_name="acceptance-tests-brain-acceptance-tests-brain"
else
    kubectl patch qjob "${KUBECF_DEPLOYMENT_NAME}"-acceptance-tests --namespace "${KUBECF_NAMESPACE}" --type merge --patch 'spec:
      trigger:
          strategy: now'
    info "Waiting for the acceptance-tests pod to start..."
    until cf_acceptance_tests_pod_name || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
    if [[ "${timeout}" == 0 ]]; then return 1; fi
    pod_name="$(cf_acceptance_tests_pod_name)"
    container_name="acceptance-tests-acceptance-tests"
fi

wait_for_tests_pod "$pod_name" "$container_name" || {
>&2 err "Timed out waiting for the tests pod"
exit 1
}

# Follow the logs. If the tests fail, or container exits it will move on (with all logs printed)
kubectl logs -f "${pod_name}" --namespace "${KUBECF_NAMESPACE}" --container "$container_name" ||:

# Wait for the container to terminate and then exit the script with the container's exit code.
jsonpath='{.status.containerStatuses[?(@.name == "'"$container_name"'")].state.terminated.exitCode}'
while true; do
exit_code="$(kubectl get "${pod_name}" --namespace "${KUBECF_NAMESPACE}" --output "jsonpath=${jsonpath}")"
if [[ -n "${exit_code}" ]]; then
    exit "${exit_code}"
fi
sleep 1
done
