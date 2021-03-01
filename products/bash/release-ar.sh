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
#   -l : <LICENSE_ACCEPT> (boolean), Defaults to false, optional
#   -n : <namespace> (string), Defaults to "cp4i"
#   -r : <release-name> (string), Defaults to "demo"
#
# USAGE:
#   With defaults values
#     ./release-ar.sh
#
#   Overriding the namespace and release-name
#     ./release-ar.sh [-l] -n cp4i-prod -r prod

function usage() {
  echo "Usage: $0 [-l] -n <namespace> -r <release-name>"
}

assetDataVolume="ibmc-file-gold-gid"
couchVolume="ibmc-block-gold"
LICENSE_ACCEPT="false"
namespace="cp4i"
release_name="demo"

while getopts "a:c:ln:r:" opt; do
  case ${opt} in
  a)
    assetDataVolume="$OPTARG"
    ;;
  c)
    couchVolume="$OPTARG"
    ;;
  l)
    LICENSE_ACCEPT="true"
    ;;
  n)
    namespace="$OPTARG"
    ;;
  r)
    release_name="$OPTARG"
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

cat <<EOF | oc apply -f -
apiVersion: integration.ibm.com/v1beta1
kind: AssetRepository
metadata:
  name: ${release_name}
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
  storage:
    assetDataVolume:
      class: ${assetDataVolume}
    couchVolume:
      class: ${couchVolume}
  version: 2020.3.1-0
EOF
