#!/bin/bash

teardown () {
    kubectl delete -f $1
    kubectl delete pvc `kubectl get pvc | grep neo4j | awk '{print $1}'`
    kubectl delete pod `kubectl get pods | grep neo4j | awk '{print $1}'`
}

$*