#!/usr/bin/env bash

if [[ -n "${BIN_DIR}" ]]; then
  export PATH="${BIN_DIR}:${PATH}"
fi

if [[ -z "${IBMCLOUD_API_KEY}" ]]; then
  echo "IBMCLOUD_API_KEY must be provided via environment variables" >&2
  exit 1
fi

if [[ -z "${REGION}" ]]; then
  echo "REGION must be provided via environment variables" >&2
  exit 1
fi

if [[ -z "${RESOURCE_GROUP}" ]]; then
  echo "RESOURCE_GROUP must be provided via environment variables" >&2
  exit 1
fi

if [[ -z "${VPN_SERVER}" ]]; then
  echo "VPN_SERVER must be provided via environment variables" >&2
  exit 1
fi

if ! command -v ibmcloud 1> /dev/null 2> /dev/null; then
  echo "ibmcloud cli not found" >&2
  exit 1
fi

if ! ibmcloud plugin show infrastructure-service 1> /dev/null 2> /dev/null; then
  echo "ibmcloud is plugin not installed" >&2
  exit 1
fi

ibmcloud config --check-version=false

ibmcloud login -r "${REGION}" -g "${RESOURCE_GROUP}" || exit 1

count=0
vpn_ready=0
while [[ "${vpn_ready}" -eq 0 ]] && [[ "${count}" -lt 45 ]]; do
    vpn=$(ibmcloud is vpn-server "${VPN_SERVER}" --output json)
    health=$(echo "${vpn}" | jq -r ".health_state")
    lifecycle=$(echo "${vpn}" | jq -r ".lifecycle_state")

    if [[ $HEALTH == "ok" && $LIFECYCLE == "stable" ]]; then
      vpn_ready=1
    elif [[ "${lifecycle}" == "failed" ]]; then
      echo "VPN:${VPN_SERVER} failed to provision. health_state: ${health}, lifecycle_state: ${lifecycle}" >&2
      exit 1
    else
      echo "Waiting for VPN:${VPN_SERVER} to become stable. health_state: ${health}, lifecycle_state: ${lifecycle}"
      sleep 60
    fi
done

if [[ "${count}" -eq 45 ]]; then
  echo "Timed out waiting for VPN:${VPN_SERVER} to become stable." >&2
  exit 1
fi

echo "VPN ${VPN_SERVER} ready"

rm -rf "${VPN_SERVER}.ovpn"

ibmcloud is vpn-server-client-configuration "${VPN_SERVER}" --file "${VPN_SERVER}.ovpn"

echo "Inserting client certificate into vpn profile"

if [[ ! -f ./certificates/issued/client1.vpn.ibm.com.crt ]] ; then
    echo './certificates/issued/client1.vpn.ibm.com.crt not found'
    exit 1
fi
if [[ ! -f ./certificates/private/client1.vpn.ibm.com.key ]] ; then
    echo './certificates/private/client1.vpn.ibm.com.key not found'
    exit 1
fi

# update the ovpn profile and embed certificates (syntax is different in mac vs linux)
echo "${OSTYPE}"
if [[ $OSTYPE == 'darwin'* ]]; then

echo "executing MacOS syntax"
sed -i '' '/#cert client_public_key.crt/a\
<cert>\
</cert>\
 ' "${VPN_SERVER}.ovpn"

sed -i '' '/<cert>/r ./certificates/issued/client1.vpn.ibm.com.crt' "${VPN_SERVER}.ovpn"

sed -i '' '/#key client_private_key.key/a\
<key>\
</key>\
 ' "${VPN_SERVER}.ovpn"

sed -i '' '/<key>/r ./certificates/private/client1.vpn.ibm.com.key' "${VPN_SERVER}.ovpn"
else 

echo "executing Linux syntax"
sed -i '/#cert client_public_key.crt/a\
<cert>\
</cert>\
 ' "${VPN_SERVER}.ovpn"

sed -i '/<cert>/r ./certificates/issued/client1.vpn.ibm.com.crt' "${VPN_SERVER}.ovpn"

sed -i '/#key client_private_key.key/a\
<key>\
</key>\
 ' "${VPN_SERVER}.ovpn"

sed -i '/<key>/r ./certificates/private/client1.vpn.ibm.com.key' "${VPN_SERVER}.ovpn"
fi

echo "Your OpenVPN client profile has been created, with certificates added, and is available at $(pwd)/${VPN_SERVER}.ovpn"
