#!/bin/sh

build () {
    APP_NAME=${APP_NAME:-elasticsearch}
    TAG=${TAG:-latest}
    docker build -t gcr.io/smartstage-159404/$APP_NAME:$TAG --no-cache .
    docker push gcr.io/smartstage-159404/$APP_NAME:$TAG
}

$*