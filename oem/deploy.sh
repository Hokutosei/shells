#!/bin/bash
# cd <APP REPOSITORY ROOT DIR>
# path/to/this/deploy.sh <ENV> <APP_NAME>  // deploy.sh stg web-ui

APP_NAME=${APP_NAME:-$2}
PROJECT_ID=${PROJECT_ID:-smartstage-159404}
DEPLOYMENT_ROOT_DIR=${DEPLOYMENT_ROOT_DIR:-../shells/oem}

DOCKER_API_VERSION=1.23

print () {
  echo "--->> $1"
}

print "DIR= $DEPLOYMENT_ROOT_DIR "

print "deploying to $1 ==============="


make

case $1 in
  stg) print "deploying to k8s gce $1"
    #CTL_ENV=${CTL_ENV:-dev}

#    print "build container"
#    docker build --tag=gcr.io/smartstage-159404/beee-lp:latest -f docker/app/Dockerfile .

    print "retag container"
    docker tag beee/$APP_NAME:latest gcr.io/$PROJECT_ID/$APP_NAME:latest

    print "pushing container to GCR"
    gcloud docker push gcr.io/$PROJECT_ID/$APP_NAME:latest

    print "stopping $APP_NAME"
    kubectl delete -f $DEPLOYMENT_ROOT_DIR/apps/$APP_NAME/deployments/$1/$1-deployments.yml

    print "creating $APP_NAME pod"
    kubectl create -f $DEPLOYMENT_ROOT_DIR/apps/$APP_NAME/deployments/$1/$1-deployments.yml
    
    print "finish deploy $1"
    ;;

  prod) print "deploying to k8s $1"
    #CTL_ENV=${CTL_ENV:-production}

    print "retag container"
    docker tag beee/$APP_NAME gcr.io/$PROJECT_ID/$APP_NAME:latest

    print "pushing container to GCR"
    gcloud docker push gcr.io/$PROJECT_ID/$APP_NAME:latest

    print "stopping $APP_NAME"
    kubectl delete rc $APP_NAME

    print "creating $APP_NAME pod"
    kubectl create -f docker/app/$CTL_ENV-$CONTROLLER_NAME-controller.yml
    
    print "finish deploy $1"
    ;;

  local) echo "deploy to local"
  ;;
esac
