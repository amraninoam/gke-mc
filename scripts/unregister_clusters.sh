#!/bin/bash
[ -d "$SCRIPT_DIR" ] || SCRIPT_DIR="."
source ${SCRIPT_DIR}/.env

function unregister_cluster() {
    CLUSTER_NAME=$1
    ZONE=$2
    # Check if the cluster already exists
    if gcloud container clusters describe $CLUSTER_NAME --zone $ZONE --project ${PROJECT_ID} > /dev/null 2>&1; then
        echo "Unregistering ${CLUSTER_NAME} from fleet"
        gcloud container fleet memberships unregister ${CLUSTER_NAME} \
        --gke-cluster ${ZONE}/${CLUSTER_NAME} \
        --project=${PROJECT_ID}
    else
        echo "Cluster ${CLUSTER_NAME} doesn't exist."
    fi
}

# Unregister clusters
unregister_cluster "gke-east-1" "us-east1-b"
unregister_cluster "gke-west-1" "us-west1-a"

gcloud container fleet multi-cluster-services disable \
    --project=${PROJECT_ID}

gcloud container fleet ingress disable \
    --project=${PROJECT_ID}