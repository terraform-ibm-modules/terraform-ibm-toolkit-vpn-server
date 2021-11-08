ibmcloud config --check-version=false

ibmcloud login -r "${REGION}" -g "${RESOURCE_GROUP}" --apikey "${IBMCLOUD_API_KEY}" || exit 1

ibmcloud is vpn-server-delete "${VPN_SERVER}" -f