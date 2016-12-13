#!/bin/bash

teardown () {
    kubectl delete -f $1
    # kubectl delete pvc `kubectl get pvc | grep mongo | awk '{print $1}'`
    kubectl delete pod `kubectl get pods | grep a-mongo | awk '{print $1}'`
}

# auth () {
    # db.createUser({
    #     user: "beee-admin",
    #     pwd: "Wcflx/WUlEjQdyFH2+w4fC8GuZ8ja2wHN8PoLQ09quQVEsLLRmNGUHlE6pEQfozb+aAGPIarkehH8JC5KO2pYw==",
    #     roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]
    # })

    # db.createUser({
    #     user: "jeane",
    #     pwd: "T55mH4kLyRGiWn1BK+3hmop/2516f1PUppL4Qx+Zn4/qkYYYQwFpPiMzDYfiiLTU+l4B7E8bTlc1KwFSGhtChQ==",
    #     roles: [ { role: "root", db: "admin" } ]
    # })

    # db.createUser({
    #     user: "jeane-user2",
    #     pwd: "jinpol",
    #     roles: [ { role: "root", db: "admin" } ]
    # })

    # hinode
    db.createUser({
        user: "devops",
        pwd: "OssuB-eee14",
        roles: [ { role: "root", db: "admin" } ]
    })

# }

restore () {
    mongorestore -h 104.155.211.57 \
    --verbose \
    --authenticationDatabase admin \
    --username beee-root \
    --password "T55mH4kLyRGiWn1BK+3hmop/2516f1PUppL4Qx+Zn4/qkYYYQwFpPiMzDYfiiLTU+l4B7E8bTlc1KwFSGhtChQ==" \
    --gzip bkp.json
}

dump () {
    mongodump -h 104.199.146.79:27017 \
    -d beee-dev \
    --out bkp.json \
    -j 15 \
    --excludeCollection temporary_collections \
    --excludeCollection temporary_datastore_rows \
    --gzip
}

prod_con_str () {
    echo "10.136.10.3:27017,10.136.4.4:27017,10.136.9.9:27017"
    echo "a-mongo-0.a-mongo.default.svc.cluster.local,a-mongo-1.a-mongo.default.svc.cluster.local"
}


make () {
	docker build --tag=gcr.io/b-eee-technology/mongodb:3.4.0 .
	gcloud docker push gcr.io/b-eee-technology/mongodb:3.4.0    
}

$*