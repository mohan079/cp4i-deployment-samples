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
#   -e : <designer-release-name> (string), Defaults to "ace-designer-demo"
#
# USAGE:
#   With defaults values
#     ./release-ace.sh
#
#   Overriding the namespace and release-name
#     ./release-ace.sh [-a] -l L-APEX-LEGNDS -n cp4i-prod -r prod

function usage() {
  echo "Usage: $0 [-a] -l <LICENSE> -n <namespace> -r <dashboard-release-name> -e <designer-release-name>"
}

dashboard_release_name="ace-dashboard-demo"
designer_release_name="ace-designer-demo"
LICENSE=""
LICENSE_ACCEPT="false"
namespace="cp4i"

while getopts "al:n:r:e:" opt; do
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
  e)
    designer_release_name="$OPTARG"
    ;;
  \?)
    usage
    exit
    ;;
  esac
done

CURRENT_DIR=$(dirname $0)
echo "Current directory: $CURRENT_DIR"

# Ace Dashboard release
if ! ${CURRENT_DIR}/release-ace-dashboard.sh -a ${LICENSE_ACCEPT} -l ${LICENSE} -n ${namespace} -r ${dashboard_release_name}; then
  echo "ERROR: Failed to release the ace dashboard in the namespace '$namespace'" 1>&2
  exit 1
fi

# Ace Designer release
if ! ${CURRENT_DIR}/release-ace-designer.sh -a ${LICENSE_ACCEPT} -l ${LICENSE} -n ${namespace} -r ${designer_release_name}; then
  echo "ERROR: Failed to release the ace designer in the namespace '$namespace'" 1>&2
  exit 1
fi
