#!/bin/bash
# cd <APP REPOSITORY ROOT DIR>
# path/to/this/deploy.sh <ENV> <APP_NAME>  // deploy.sh stg web-ui

PROJECT_ID=${PROJECT_ID:-smartstage-159404}

APP_NAME=${APP_NAME:-$2}
CONTAINER_NAME=${CONTAINER_NAME:-beee-$APP_NAME}
DEPLOYMENT_ROOT_DIR=${DEPLOYMENT_ROOT_DIR:-../shells/oem}

DOCKER_API_VERSION=1.23

print () {
  echo "--->> $1"
}

print "DIR= $DEPLOYMENT_ROOT_DIR "

print "deploying to $1 ==============="


#make

case $1 in
  stg) print "deploying to k8s gce $1"
    #CTL_ENV=${CTL_ENV:-dev}

    print "build container"
    cd $GOPATH/src/$APP_NAME &&

    print "pull deploy code"
    git checkout develop &&
    git pull origin develop &&

    if [ "$APP_NAME" -ne "web-ui" ]; then
        GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -v -o bin/linux_amd64
    fi
    docker build --tag=gcr.io/$PROJECT_ID/$CONTAINER_NAME:latest --no-cache -f docker/app/Dockerfile . &&

    print "pushing container to GCR"
    gcloud docker push gcr.io/$PROJECT_ID/$CONTAINER_NAME:latest &&

    print "stopping $CONTAINER_NAME"
    kubectl delete -f $DEPLOYMENT_ROOT_DIR/apps/$APP_NAME/deployments/$1/$1-deployments.yml

    print "creating $CONTAINER_NAME pod"
    kubectl create -f $DEPLOYMENT_ROOT_DIR/apps/$APP_NAME/deployments/$1/$1-deployments.yml
    
    print "finish deploy $1"
    ;;

  prod) print "deploying to k8s $1"
    CTL_ENV=${CTL_ENV:-production}

    print "pushing container to GCR"
    gcloud docker push gcr.io/$PROJECT_ID/$CONTAINER_NAME:latest

    print "stopping $CONTAINER_NAME"
    kubectl delete rc $CONTAINER_NAME

    print "creating $CONTAINER_NAME pod"
    kubectl create -f docker/app/$CTL_ENV-$CONTROLLER_NAME-controller.yml
    
    print "finish deploy $1"
    ;;

  local) echo "deploy to local"
  ;;
esac

print "show pods"
kubectl get pods -o wide
