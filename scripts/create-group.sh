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

DATA="{ \"metadata\": { \"collection_type\": \"application/vnd.ibm.secrets-manager.secret.group+json\", \"collection_total\": 1 }, \"resources\": [ { \"name\": \"${NAME}\", \"description\": \"${DESCRIPTION}\" } ] }"

BASE_URL="https://${INSTANCE_ID}.${REGION}.secrets-manager.appdomain.cloud"

# POST request
POST_RESULT=$(curl -X POST --location  \
    --header "Authorization: Bearer $IAM_TOKEN" \
    --header 'Accept: application/json' \
    --header 'Content-Type: application/json' \
    --data "$DATA" \
    "${BASE_URL}/api/v1/secret_groups")
