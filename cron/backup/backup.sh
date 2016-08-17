#!/bin/sh
set -x

# STG INSTANCE
NEO4J=${NEO4J:-107.167.181.111}
NEO4J_PORT=${NEO4J_PORT:-6362}

# STG INSTANCE
MONGODB=${MONGODB:-104.199.173.158}
M_PORT=${MONGODB_PORT:-27017}
CONCURRENT=${CONCURRENT:-15}
M_DATABASE=${MONGODB_DATABASE:-beee-dev}

# mongodump -h 104.199.173.158:27017 -d beee-dev --out bkp.json -j 15 --excludeCollection temporary_collections --excludeCollection temporary_datastore_rows --gzip
# HOST=104.199.136.27:27018 DATABASE=beee-dev ./backup.sh dump
mongodb_backup () {
    DATE=`date +%Y-%m-%d:%H:%M:%S`
    mongodump --host $MONGODB \
                --port $M_PORT \
                -d $M_DATABASE \
                -j $CONCURRENT \
                --out /mongodb/bkp_$DATE.json \
                --excludeCollection temporary_collections \
                --excludeCollection temporary_datastore_rows \
                --gzip
}

neo4j_backup () {
    DATE=`date +%Y-%m-%d:%H:%M:%S`
    ./neo4j/bin/neo4j-backup -host $NEO4J -port $NEO4J_PORT -to /neo4j/backup/neo4j_$DATE
    # docker run --rm \
    #             -it \
    #             -v `pwd`:/data neo4j:3.0.4-enterprise bin/neo4j-backup \
    #             -host 107.167.181.111 \
    #             -port 6362 \
    #             -to /data_$(DATE=`date +%Y-%m-%d:%H:%M:%S`)
}

$*