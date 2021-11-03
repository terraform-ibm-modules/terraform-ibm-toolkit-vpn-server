ibmcloud config --check-version=false

ibmcloud login -r "${REGION}" -g "${RESOURCE_GROUP}" --apikey "${IBMCLOUD_API_KEY}" || exit 1

VPN_SERVER = $(ibmcloud is vpn-server "${VPN_SERVER}" --output json)

VPN_SERVER_ID = $(echo $VPN_SERVER | jq ".id" -r)

if [ ! -z "$VPN_SERVER_ID" ]
then
    ibmcloud is vpn-server-delete "${VPN_SERVER_ID}"
fi