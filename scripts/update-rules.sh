

ibmcloud config --check-version=false

ibmcloud login -r "${REGION}" -g "${RESOURCE_GROUP}" --apikey "${IBMCLOUD_API_KEY}" || exit 1

# get default acl for the subnet by id
ACL_ID="$(ibmcloud is subnet $SUBNET_ID --output json | jq '.network_acl.id' -r)"

#echo $ACL_ID

RULES=$(ibmcloud is network-acl "${ACL_ID}" --output JSON)
INGRESS_RULE_ID=$(echo $RULES | jq -r '.rules[] | select(.name=="allow-vpn-ingress").id')
EGRESS_RULE_ID=$(echo $RULES | jq -r '.rules[] | select(.name=="allow-vpn-egress").id')

# only create rules if they don't already exist
if [ -z "$INGRESS_RULE_ID" ]
then
 ibmcloud is network-acl-rule-add "${ACL_ID}" allow inbound all 0.0.0.0/8 10.0.0.0/8 --name allow-vpn-ingress
fi

if [ -z "$EGRESS_RULE_ID" ]
then
  ibmcloud is network-acl-rule-add "${ACL_ID}" allow outbound all 0.0.0.0/8 10.0.0.0/8 --name allow-vpn-egress
fi