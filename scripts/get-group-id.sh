#!/usr/bin/env bash

INPUT=$(tee)

# Get bin dir from input (cannot use yq as it may be in the bin_dir)
BIN_DIR=$(echo "${INPUT}" | grep "bin_dir" | sed -E 's/.*"bin_dir": ?"([^"]+)".*/\1/g')

export PATH="${BIN_DIR}:${PATH}"

# Parse input for other variables
IBMCLOUD_API_KEY=$(echo "${INPUT}" | jq -r '.ibmcloud_api_key')
GROUP_NAME=$(echo "${INPUT}" | jq -r '.group_name')
REGION=$(echo "${INPUT}" | jq -r '.region')
INSTANCE_ID=$(echo "${INPUT}" | jq -r '.instance_id')

IAM_TOKEN=$(curl -s -X POST "https://iam.cloud.ibm.com/identity/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${IBMCLOUD_API_KEY}" | jq -r '.access_token')

ACCOUNT_ID=$(curl -s -X GET 'https://iam.cloud.ibm.com/v1/apikeys/details' \
  -H "Authorization: Bearer $IAM_TOKEN" -H "IAM-Apikey: ${IBMCLOUD_API_KEY}" \
  -H 'Content-Type: application/json' | jq -r '.account_id')

if [[ -z "${ACCOUNT_ID}" ]]; then
  echo "ACCOUNT_ID could not be retrieve" >&2
  exit 1
fi

BASE_URL="https://${INSTANCE_ID}.${REGION}.secrets-manager.appdomain.cloud"

# POST request
POST_RESULT=$(curl -s -X GET --location  \
    --header "Authorization: Bearer $IAM_TOKEN" \
    --header 'Accept: application/json' \
    "${BASE_URL}/api/v1/secret_groups")

GROUP_ID=$(echo ${POST_RESULT} | jq '.resources' | jq ".[]|select(.name==\"${GROUP_NAME}\")" | jq -r '.id' )

jq -n --arg GROUP_ID "${GROUP_ID}" \
  '{"group_id": $GROUP_ID}'