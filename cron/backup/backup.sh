#!/bin/sh

CONCURRENT=${CONCURRENT:-15}

NEO4J=${NEO4J:-107.167.181.111}
NEO4J_PORT=${NEO4J_PORT:-6362}

# mongodump -h 104.199.173.158:27017 -d beee-dev --out bkp.json -j 15 --excludeCollection temporary_collections --excludeCollection temporary_datastore_rows --gzip
# HOST=104.199.136.27:27018 DATABASE=beee-dev ./backup.sh dump
dump () {
    DATE=`date +%Y-%m-%d:%H:%M:%S`
    mongodump -h $HOST \
                -d $DATABASE \
                --out /bkp/bkp_$DATE.json \
                -j $CONCURRENT \
                --excludeCollection temporary_collections \
                --excludeCollection temporary_datastore_rows \
                --gzip
}

neo4j-backup () {
    DATE=`date +%Y-%m-%d:%H:%M:%S`
    ./bin/neo4j-backup -host $NEO4J -port $NEO4J_PORT -to /data/neo4j_$DATE
}

$*