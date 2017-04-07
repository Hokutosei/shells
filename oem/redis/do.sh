#!/bin/bash

make () {
	docker build --tag=gcr.io/bizplatform-ix-production/redis:3.2.3-alpine --no-cache .
    gcloud docker -- push gcr.io/bizplatform-ix-production/redis:3.2.3-alpine
}

$*