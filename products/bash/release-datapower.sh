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
#   -a : admin password, defaults to "admin"
#   -l : <LICENSE_ACCEPT> (boolean), Defaults to false, optional
#   -n : <namespace> (string), Defaults to "cp4i"
#   -p : indicates production mode
#   -r : <release-name> (string), Defaults to "datapower"
#
# USAGE:
#   With defaults values
#     ./release-datapower.sh
#
#   Overriding the namespace and release-name
#     ./release-datapower -a admin [-l] -n cp4i-prod -p -r datapower

function usage() {
  echo "Usage: $0 [-l] -n <namespace> -r <release-name> [-t]"
}

SCRIPT_DIR=$(dirname $0)

admin_password="admin"
flavour="developers-limited"
LICENSE_ACCEPT="false"
memory_limit="4Gi"
namespace="cp4i"
production="false"
release_name="datapower"
replicas=1

while getopts "a:ln:pr:" opt; do
  case ${opt} in
  a)
    admin_password="$OPTARG"
    ;;
  l)
    LICENSE_ACCEPT="true"
    ;;
  n)
    namespace="$OPTARG"
    ;;
  p)
    production="true"
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

if [[ "$production" == "true" ]]; then
  echo "Production Mode Enabled"
  flavour="production"
  memory_limit="8Gi"
  replicas=5
fi

# Create ConfigMap for default
oc create configmap -n ${namespace} default-config --from-file=${SCRIPT_DIR}/datapower/default.cfg

# Create ConfigMap for test domain
oc create configmap -n ${namespace} test-config --from-file=${SCRIPT_DIR}/datapower/testconfig.cfg

# Create ConfigMap for test domain local
oc create configmap -n ${namespace} test-tar --from-file=${SCRIPT_DIR}/datapower/test.tar.gz

# Create Secret with certificate
oc create secret generic -n ${namespace} jon --from-file=${SCRIPT_DIR}/datapower/sharedcerts/jon.ssk

# Create Secret with DataPower admin credentials
oc create secret generic -n ${namespace} datapower-admin-credentials --from-literal=password=${admin_password}

# Create DataPowerService
cat <<EOF | oc apply -f -
apiVersion: datapower.ibm.com/v1beta2
kind: DataPowerService
metadata:
  name: ${release_name}
  namespace: ${namespace}
spec:
  debug: false
  env:
    - name: DATAPOWER_LOG_LEVEL
      value: '3'
  license:
    accept: ${LICENSE_ACCEPT}
    use: ${flavour}
  replicas: ${replicas}
  resources:
    limits:
      memory: ${memory_limit}
    requests:
      cpu: 4
      memory: 4Gi
  users:
    - accessLevel: privileged
      name: admin
      passwordSecret: datapower-admin-credentials
  annotations:
    this.is.a.test/anno: "hello-world"
  labels:
    this.is.a.test/label: "hello-world"
  env:
  - name: DATAPOWER_LOG_LEVEL
    value: "3"
  - name: DATAPOWER_LOG_COLOR
    value: "true"
  domains:
  - name: default
    certs:
    - certType: "sharedcerts"
      secret: "jon"
    dpApp:
      config:
      - default-config
  - name: testconfig
    dpApp:
      config:
      - test-config
      local:
      - test-tar
  version: 10.0-lts

EOF
