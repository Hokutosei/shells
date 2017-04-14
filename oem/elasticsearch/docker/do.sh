#!/bin/sh

PJ_ID=${PJ_ID:-bizplatform-ix-production}

build () {
    APP_NAME=${APP_NAME:-elasticsearch5-ja}
    TAG=${TAG:-latest}

    docker build -t gcr.io/${PJ_ID}/${APP_NAME}:${TAG} --no-cache .
    gcloud docker -- push gcr.io/${PJ_ID}/${APP_NAME}:${TAG}
}

$*