#!/bin/bash

PROJECT_ID=${PROJECT_ID:-bizplatform-ix-production}
ZONE=${ZONE:-asia-northeast1-a}
APP_NAME=${APP_NAME:-taskmanager}

copy-files () {
	gcloud compute --project ${PROJECT_ID} copy-files --zone ${ZONE} config_files/* "opsmanager@opsmanager:go/src/${APP_NAME}"
}

$*