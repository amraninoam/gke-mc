#!/bin/bash
[ -d "$SCRIPT_DIR" ] || SCRIPT_DIR="."
source ${SCRIPT_DIR}/.env

function delete_cluster() {
    CLUSTER_NAME=$1
    ZONE=$2
    
    gcloud container clusters delete ${CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT_ID} --quiet &
}
# Delete clusters
delete_cluster "gke-west-1" "us-west1-a"
delete_cluster "gke-east-1" "us-east1-b"