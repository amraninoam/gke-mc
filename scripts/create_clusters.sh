#!/bin/bash
[ -d "$SCRIPT_DIR" ] || SCRIPT_DIR="."
source ${SCRIPT_DIR}/.env

function create_cluster() {
    CLUSTER_NAME=$1
    ZONE=$2
    # Check if the cluster already exists
    if ! gcloud container clusters describe $CLUSTER_NAME --zone $ZONE --project ${PROJECT_ID} > /dev/null 2>&1; then
        echo "Cluster ${CLUSTER_NAME} does not exist. Creating cluster..."
        gcloud container clusters create $CLUSTER_NAME \
            --gateway-api=standard \
            --enable-ip-alias \
            --zone=$ZONE \
            --workload-pool=${PROJECT_ID}.svc.id.goog \
            --cluster-version=$CLUSTER_VERSION \
            --project=${PROJECT_ID} \
            --quiet
    else
        echo "Cluster already exists. Skipping creation."
    fi
}

# Start cluster creation in the background
create_cluster "gke-west-1" "us-west1-a" &
create_cluster "gke-east-1" "us-east1-b" &

# Wait for all background processes to complete
wait
echo "All clusters have been created."