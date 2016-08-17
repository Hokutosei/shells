#!/bin/sh

run () {
    docker rm -fv `docker ps -aq` && \
    docker run -d \
                -e HOST=104.199.173.158:27017 \
                -e DATABASE=beee-dev \
                -v `pwd`/bkp:/bkp/bkp.json \
                bkp_cron
}

build () {
    make
}

$*