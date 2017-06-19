#!/bin/bash

PROJECT_ID=${PROJECT_ID:-bizplatform-ix-production}
ZONE=${ZONE:-asia-northeast1-a}

# Perquisites : create go/src/apicore/gcp/secrets dir in deploy_server
copy-files () {
	gcloud compute --project ${PROJECT_ID} copy-files --zone ${ZONE} config_files/* "opsmanager@opsmanager:go/src/apicore"
	gcloud compute --project ${PROJECT_ID} copy-files --zone ${ZONE} gcs_key_file/* "opsmanager@opsmanager:go/src/apicore/gcp/secrets"
}

$*