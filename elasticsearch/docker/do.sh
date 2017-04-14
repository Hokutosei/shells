#!/bin/sh

build () {
    APP_NAME=${APP_NAME:-elasticsearch5-ja}
    TAG=${TAG:-latest}
    docker build -t beee/$APP_NAME:$TAG --no-cache .
    docker push beee/$APP_NAME:$TAG
}

$*