#!/bin/bash

make () {
	docker build --tag=gcr.io/bizplatform-ix-production/mongodb:3.4.0 --no-cache .
    gcloud docker -- push gcr.io/bizplatform-ix-production/mongodb:3.4.0
}

$*