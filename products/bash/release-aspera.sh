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
#   -a : <LICENSE_ACCEPT> (boolean), Defaults to false, optional
#   -c : storage class to be used
#   -k : absolute path to license key file
#   -n : <namespace> (string), Defaults to "cp4i"
#   -r : <release-name> (string), Defaults to "ademo"
#
# USAGE:
#   With defaults values
#     ./release-aspera.sh
#
#   Overriding the namespace and release-name
#     ./release-aspera [-a] -n cp4i-prod -r prod -k keyfile_path

function usage() {
  echo "Usage: $0 [-a] -n <namespace> -r <release-name> [-t]"
}

LICENSE_ACCEPT="false"
license_key_filepath=""
namespace="cp4i"
production="false"
release_name="aspera"
storage_class=""

while getopts "ac:k:n:pr:" opt; do
  case ${opt} in
  a)
    LICENSE_ACCEPT="true"
    ;;
  c)
    storage_class="$OPTARG"
    ;;
  k)
    license_key_filepath="$OPTARG"
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

license="$(cat ${license_key_filepath} | awk '{printf "      %s\n",$0}')"

if [[ "$production" == "true" ]]; then
  echo "Production Mode Enabled"
  cat <<EOF | oc apply -f -
apiVersion: hsts.aspera.ibm.com/v1
kind: IbmAsperaHsts
metadata:
  labels:
    app.kubernetes.io/instance: ibm-aspera-hsts
    app.kubernetes.io/managed-by: ibm-aspera-hsts-prod
    app.kubernetes.io/name: ibm-aspera-hsts-prod
  name: ${release_name}
  namespace: ${namespace}
spec:
  containers:
    ascp:
      resources:
        limits:
          cpu: 4000m
          memory: 4096Mi
        requests:
          cpu: 1000m
          memory: 2048Mi
    asperanoded:
      resources:
        limits:
          cpu: 2000m
          memory: 2048Mi
        requests:
          cpu: 500m
          memory: 1024Mi
    default:
      resources:
        limits:
          cpu: 1000m
          memory: 500Mi
        requests:
          cpu: 100m
          memory: 250Mi
  deployments:
    default:
      replicas: 3
  license:
    accept: ${LICENSE_ACCEPT}
    key: >-
${license}
    use: CloudPakForIntegrationProduction
  redis:
    persistence:
      enabled: true
      storageClass: ${storage_class}
    resources:
      requests:
        cpu: 1000m
        memory: 8Gi
  services:
    httpProxy:
      type: ClusterIP
    tcpProxy:
      type: LoadBalancer
  storages:
    - claimName: hsts-transfer-pvc
      class: ${storage_class}
      deleteClaim: false
      mountPath: /data/
      size: 2000Gi
  version: 4.0.0
EOF
else

  cat <<EOF | oc apply -f -
apiVersion: hsts.aspera.ibm.com/v1
kind: IbmAsperaHsts
metadata:
  labels:
    app.kubernetes.io/instance: ibm-aspera-hsts
    app.kubernetes.io/managed-by: ibm-aspera-hsts
    app.kubernetes.io/name: ibm-aspera-hsts
  name: ${release_name}
  namespace: ${namespace}
spec:
  deployments:
    default:
      replicas: 1
  license:
    accept: true
    key: >-
${license}
    use: CloudPakForIntegrationNonProduction
  redis:
    persistence:
      enabled: false
  services:
    httpProxy:
      type: ClusterIP
    tcpProxy:
      type: LoadBalancer
  storages:
    - claimName: hsts-transfer-pvc
      class: ${storage_class}
      deleteClaim: true
      mountPath: /data/
      size: 20Gi
  version: 4.0.0

EOF
fi
