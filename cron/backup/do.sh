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
                -v $HOME/bkp/neo4j:/neo4j/backup \
                -v $HOME/neo4j/bin:/neo4j/bin \
                -v /var/run/docker.sock:/var/run/docker.sock \
                bkp_cron
}

deploy_win () {
    dir=/c/Users/jeanepaul/Development/go/src/shells/cron/backup
    docker run -d \
                -e NEO4J=107.167.181.111 \
                -e NEO4J_PORT=6362 \
                -e MONGODB=104.199.173.158 \
                -e M_PORT=27017 \
                -e M_DATABASE=beee-dev \
                -v $dir/bkp/mongodb:/mongodb \
                -v $dir/bkp/neo4j:/neo4j/backup \
                -v $dir/neo4j/bin:/neo4j/bin \
                bkp_cron
}

build () {
    make
}

build_win () {
    docker build --no-cache --tag=bkp_cron .
}

$*