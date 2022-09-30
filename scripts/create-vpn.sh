#!/usr/bin/env bash

export PATH="$BIN_DIR:$PATH"

ibmcloud config --check-version=false

ibmcloud login -r "${REGION}" -g "${RESOURCE_GROUP}" --apikey "${IBMCLOUD_API_KEY}" || exit 1

echo "ibmcloud is vpn-server-create  \
  --name \"${VPN_SERVER}\"  \
  --subnet \"${SUBNET_IDS}\"  \
  --cert \"${SERVER_CERT_CRN}\"  \
  --client-ca \"${CLIENT_CERT_CRN}\"  \
  --client-ip-pool \"${VPNCLIENT_IP}\"  \
  --client-dns \"${CLIENT_DNS}\"  \
  --client-auth-methods \"${AUTH_METHOD}\"  \
  --sg \"${SECGRP_ID}\"  \
  --protocol \"${VPN_PROTO}\"  \
  --port \"${VPN_PORT}\"  \
  --enable-split-tunnel \"${SPLIT_TUNNEL}\"  \
  --client-idle-timeout \"${IDLE_TIMEOUT}\" "

ibmcloud is vpn-server-create  \
  --name "${VPN_SERVER}"  \
  --subnet "${SUBNET_IDS}"  \
  --cert "${SERVER_CERT_CRN}"  \
  --client-ca "${CLIENT_CERT_CRN}"  \
  --client-ip-pool "${VPNCLIENT_IP}"  \
  --client-dns "${CLIENT_DNS}"  \
  --client-auth-methods "${AUTH_METHOD}"  \
  --sg "${SECGRP_ID}"  \
  --protocol "${VPN_PROTO}"  \
  --port "${VPN_PORT}"  \
  --enable-split-tunnel "${SPLIT_TUNNEL}"  \
  --client-idle-timeout "${IDLE_TIMEOUT}" 

VPN=$(ibmcloud is vpn-server $VPN_SERVER --output json)
VPN_SERVER_ID=$(echo $VPN | jq -r ".id")

echo "  vpn_server: \"${VPN_SERVER}\"" >> output.yaml
echo "  vpn_server_id: \"${VPN_SERVER_ID}\"" >> output.yaml


ibmcloud is vpn-server-route-create $VPN_SERVER --name vpc-network --action translate --destination $VPC_CIDR
ibmcloud is vpn-server-route-create $VPN_SERVER --name services --action translate --destination $SERVICES_CIDR
ibmcloud is vpn-server-route-create $VPN_SERVER --name dns --action translate --destination $DNS_CIDR
