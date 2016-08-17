#!/bin/sh

run () {
    docker rm -fv `docker ps -aq` && \
    docker run -d \
                -e HOST=104.199.173.158:27017 \
                -e DATABASE=beee-dev \
                -v `pwd`/bkp:/bkp/bkp.json \
                bkp_cron
}

deploy () {
    docker run -d \
                -e NEO4J=107.167.181.111 \
                -e NEO4J_PORT=6362 \
                -e MONGODB=104.199.173.158 \
                -e M_PORT=27017 \
                -e M_DATABASE=beee-dev \
                -v $HOME/bkp/mongodb:/mongodb \
                -v $HOME/bkp/neo4j:/neo4j \
                bkp_cron
}

build () {
    make
}

$*