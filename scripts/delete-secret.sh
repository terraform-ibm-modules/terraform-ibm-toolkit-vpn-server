#!/usr/bin/env bash

export PATH="${BIN_DIR}:${PATH}"

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

# Find secret id
SECRETS=$(curl -s -X GET --location  \
    --header "Authorization: Bearer $IAM_TOKEN" \
    --header 'Accept: application/json' \
    "${BASE_URL}/api/v1/secrets")

SECRET_ID=$(echo "${SECRETS}" | jq '.resources' | jq -r ".[]|select(.secret_group_id==\"${GROUP_ID}\") | \"\(.name) \(.id)\" " | grep "${NAME}" | awk '{print $2}' )

if [[ -z ${SECRET_ID} ]]; then
  echo "ERROR: Secret ${NAME} not found in group id ${GROUP_ID}"
  exit 2
else
  DELETE_RESULT=$(curl -X DELETE --location  \
      --header "Authorization: Bearer $IAM_TOKEN" \
      "${BASE_URL}/api/v1/secrets/${TYPE}/${SECRET_ID}")  
fi