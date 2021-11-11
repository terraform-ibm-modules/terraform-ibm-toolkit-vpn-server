#!/bin/bash

set -e
PATH=$1:$PATH

LOGIN=$(ibmcloud login -q -r $2 -g ${3} --apikey ${4})

ibmcloud is subnet $5 --output json | jq -r ".vpc"