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
#   -a : <LICENSE_ACCEPT> (boolean), Defaults to false, optional
#   -l : <LICENSE> (string), Defaults to ""
#   -n : <namespace> (string), Defaults to "cp4i"
#   -r : <dashboard-release-name> (string), Defaults to "ace-dashboard-demo"
#
# USAGE:
#   With defaults values
#     ./release-ace-dashboard.sh
#
#   Overriding the namespace and release-name
#     ./release-ace-dashboard.sh [-a] -l L-APEX-LEGNDS -n cp4i-prod -r prod

function usage() {
  echo "Usage: $0 [-a] -l <LICENSE> -n <namespace> -r <dashboard-release-name>"
}

dashboard_release_name="ace-dashboard-demo"
LICENSE=""
LICENSE_ACCEPT="false"
namespace="cp4i"
production="false"
storage="ibmc-file-gold-gid"

while getopts "al:n:r:s:p" opt; do
  case ${opt} in
  a)
    LICENSE_ACCEPT="true"
    ;;
  l)
    LICENSE="$OPTARG"
    ;;
  n)
    namespace="$OPTARG"
    ;;
  r)
    dashboard_release_name="$OPTARG"
    ;;
  s)
    storage="$OPTARG"
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

echo "INFO: Release ACE Dashboard..."
echo "INFO: Namespace: '$namespace'"
echo "INFO: Dashboard Release Name: '$dashboard_release_name'"

use="CloudPakForIntegrationNonProduction"

if [[ "$production" == "true" ]]; then
  echo "Production Mode Enabled"
  use="CloudPakForIntegrationProduction"

fi

json=$(oc get configmap -n $namespace operator-info -o json)
if [[ $? == 0 ]]; then
  METADATA_NAME=$(echo $json | tr '\r\n' ' ' | jq -r '.data.METADATA_NAME')
  METADATA_UID=$(echo $json | tr '\r\n' ' ' | jq -r '.data.METADATA_UID')
fi

cat <<EOF | oc apply -f -
apiVersion: appconnect.ibm.com/v1beta1
kind: Dashboard
metadata:
  name: ${dashboard_release_name}
  namespace: ${namespace}
  $(if [[ ! -z ${METADATA_UID} && ! -z ${METADATA_NAME} ]]; then
  echo "ownerReferences:
    - apiVersion: integration.ibm.com/v1beta1
      kind: Demo
      name: ${METADATA_NAME}
      uid: ${METADATA_UID}"
  fi)
spec:
  license:
    accept: ${LICENSE_ACCEPT}
    license: ${LICENSE}
    use: ${use}
  replicas: 1
  storage:
    class: ${storage}
    size: 5Gi
    type: persistent-claim
  useCommonServices: true
  version: 11.0.0.10
EOF
