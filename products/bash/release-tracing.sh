#!/bin/bash
#******************************************************************************
# Licensed Materials - Property of IBM
# (c) Copyright IBM Corporation 2020. All Rights Reserved.
#
# Note to U.S. Government Users Restricted Rights:
# Use, duplication or disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
#******************************************************************************

#******************************************************************************
# PREREQUISITES:
#   - Logged into cluster on the OC CLI (https://docs.openshift.com/container-platform/4.4/cli_reference/openshift_cli/getting-started-cli.html)
#
# PARAMETERS:
#   -a : <LICENSE_ACCEPT> (boolean), Default to false, optional
#   -b : <block-storage-class> (string), Default to "ibmc-block-gold"
#   -f : <file-storage-class> (string), Default to "ibmc-file-gold-gid"
#   -n : <namespace> (string), Defaults to "cp4i"
#   -r : <release-name> (string), Defaults to "tracing-demo"
#
# USAGE:
#   With defaults values
#     ./release-tracing.sh
#
#   Overriding the namespace and release-name
#     ./release-tracing -a -n cp4i-prod -r prod

function usage() {
  echo "Usage: $0 -a -n <namespace> -r <release-name>"
}

block_storage="ibmc-block-gold"
file_storage="ibmc-file-gold-gid"
LICENSE_ACCEPT="false"
namespace="cp4i"
production="false"
release_name="tracing-demo"

while getopts "ab:f:n:r:p" opt; do
  case ${opt} in
  a)
    LICENSE_ACCEPT="true"
    ;;
  b)
    block_storage="$OPTARG"
    ;;
  f)
    file_storage="$OPTARG"
    ;;
  n)
    namespace="$OPTARG"
    ;;
  r)
    release_name="$OPTARG"
    ;;
  p)
    production="true"
    ;;
  \?)
    usage
    exit
    ;;
  esac
done

json=$(oc get configmap -n $namespace operator-info -o json)
if [[ $? == 0 ]]; then
  METADATA_NAME=$(echo $json | tr '\r\n' ' ' | jq -r '.data.METADATA_NAME')
  METADATA_UID=$(echo $json | tr '\r\n' ' ' | jq -r '.data.METADATA_UID')
fi

if [[ "$production" == "true" ]]; then
  echo "Production Mode Enabled"
  cat <<EOF | oc apply -f -
apiVersion: integration.ibm.com/v1beta2
kind: OperationsDashboard
metadata:
  namespace: "${namespace}"
  name: "${release_name}"
  labels:
    app.kubernetes.io/instance: ibm-integration-operations-dashboard
    app.kubernetes.io/managed-by: ibm-integration-operations-dashboard
    app.kubernetes.io/name: ibm-integration-operations-dashboard
  $(if [[ ! -z ${METADATA_UID} && ! -z ${METADATA_NAME} ]]; then
  echo "ownerReferences:
    - apiVersion: integration.ibm.com/v1beta1
      kind: Demo
      name: ${METADATA_NAME}
      uid: ${METADATA_UID}"
  fi)
spec:
  env:
    - name: ENV_ResourceTemplateName
      value: production
  license:
    accept: ${LICENSE_ACCEPT}
  replicas:
    configDb: 3
    frontend: 3
    housekeepingWorker: 3
    jobWorker: 3
    master: 3
    scheduler: 3
    store: 3
  storage:
    configDbVolume:
      class: "${file_storage}"
    sharedVolume:
      class: "${file_storage}"
    tracingVolume:
      class: "${block_storage}"
      size: 150Gi
  version: 2020.3.1-1
EOF
else
  cat <<EOF | oc apply -f -
apiVersion: integration.ibm.com/v1beta2
kind: OperationsDashboard
metadata:
  namespace: "${namespace}"
  name: "${release_name}"
  labels:
    app.kubernetes.io/instance: ibm-integration-operations-dashboard
    app.kubernetes.io/managed-by: ibm-integration-operations-dashboard
    app.kubernetes.io/name: ibm-integration-operations-dashboard
  $(if [[ ! -z ${METADATA_UID} && ! -z ${METADATA_NAME} ]]; then
  echo "ownerReferences:
    - apiVersion: integration.ibm.com/v1beta1
      kind: Demo
      name: ${METADATA_NAME}
      uid: ${METADATA_UID}"
  fi)
spec:
  license:
    accept: true
  storage:
    configDbVolume:
      class: "${file_storage}"
    sharedVolume:
      class: "${file_storage}"
    tracingVolume:
      class: "${block_storage}"
  version: 2020.3.1-1
EOF
fi
