#!/bin/sh
source $GOPATH/src/shells/app_scripts/config.sh
source $GOPATH/src/shells/app_scripts/remote_builds.sh

proto_start () {

    for i in "${@:2}"
    do
    case $i in
        -w=*|--web=*)
        WEB="${i#*=}"

        if [ "$WEB" == "true" ]; then
            build_for_web
        fi
        shift
        ;;
    esac
    done
}

build_for_web () {
    print "building for web"
}

print () {
    echo "-->> $1"
}

$*