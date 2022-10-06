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

# Get group id
SECRET_GROUPS=$(curl -s -X GET --location  \
    --header "Authorization: Bearer $IAM_TOKEN" \
    --header 'Accept: application/json' \
    "${BASE_URL}/api/v1/secret_groups")

GROUP_ID=$(echo ${SECRET_GROUPS} | jq '.resources' | jq ".[]|select(.name==\"${NAME}\")" | jq -r '.id' )

if [[ -z ${GROUP_ID} ]]; then
  echo "ERROR: Group ${NAME} not found in security manager ${INSTANCE_ID}"
  exit 2
else

  # Check that group is empty
  SECRETS=$(curl -s -X GET --location  \
      --header "Authorization: Bearer $IAM_TOKEN" \
      --header 'Accept: application/json' \
      "${BASE_URL}/api/v1/secrets")

  GROUP_SECRETS=$(echo ${SECRETS} | jq '.resources' | jq ".[]|select(.secret_group_id==\"${GROUP_ID}\")" )

  if [[ ! -z ${GROUP_SECRETS} ]]; then
      echo "ERROR: Security group is not empty. Delete all secrets in group first."
      exit 2
  else
      DELETE_RESULT=$(curl -X DELETE --location  \
          --header "Authorization: Bearer $IAM_TOKEN" \
          "${BASE_URL}/api/v1/secret_groups/${GROUP_ID}")
  fi

fi