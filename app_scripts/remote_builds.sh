#!/bin/sh

# init_remote_builder initialize rsync current directory to remote_builder
# ./do.sh init_remote_builder
init_remote_builder () {
    DEV_PATH=${DEV_PATH:-/home/$SSH_USER/Develop/devs/$DIR_NAME/$APP_NAME}

    ssh $SSH_USER@$BUILDER_IP "mkdir -p ${DEV_PATH}"
    rsync -a \
        --exclude '.*' \
        --progress . $SSH_USER@$BUILDER_IP:$DEV_PATH
}

# remote_build initialize remote build to remote machine
# ./do.sh remote_build
remote_build () {
    export ENV=$ENV
    print_build $APP_NAME $ENV

    DEV_PATH=${DEV_PATH:-/home/b-eee/Develop/devs/$DIR_NAME/$APP_NAME}
    start=$(date +%s)

    rsync -a \
        --progress \
        --exclude '.*' . b-eee@$BUILDER_IP:$DEV_PATH &&
    ssh b-eee@$BUILDER_IP "/usr/bin/docker run --rm \
                                                -v /home/b-eee/Develop/go/src:/go/src \
                                                -e GOOS=$OS \
                                                -e GOARCH=$ARCH \
                                                -e CGO_ENABLED=0 \
                                                -v ${DEV_PATH}:/go/src/${APP_NAME} \
                                                -w /go/src/${APP_NAME} golang:${GOVERSION} \
                                                go build -v -o $APP_NAME" &&
    rsync -a --progress b-eee@$BUILDER_IP:$DEV_PATH/$APP_NAME .


    end=$(date +%s)
    runtime=$(python -c "print '%u:%02u' % ((${end} - ${start})/60, (${end} - ${start})%60)")
    ./$APP_NAME
}

print_build () {
    echo "-->> building $1 $2"
}