#!/usr/bin/env bash

export PATH="$BIN_DIR:$PATH"

ibmcloud config --check-version=false

ibmcloud login -r "${REGION}" -g "${RESOURCE_GROUP}" --apikey "${IBMCLOUD_API_KEY}" || exit 1

ibmcloud is vpn-server-delete "${VPN_SERVER}" -f

count=0
while ibmcloud is vpn-server "${VPN_SERVER}" 1> /dev/null 2> /dev/null && [[ "${count}" -lt 20 ]]; do
  echo "VPN Server still destroying: ${VPN_SERVER}"
  count=$((count+1))
  sleep 30
done

if [[ "${count}" -eq 20 ]]; then
  echo "Timed out waiting for vpn-server to be deleted" >&2
  ## Log error but don't return an error code
  exit 0
fi
