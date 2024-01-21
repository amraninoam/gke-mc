#!/bin/bash
[ -d "$SCRIPT_DIR" ] || SCRIPT_DIR="."
source ${SCRIPT_DIR}/.env

function register_cluster() {
    CLUSTER_NAME=$1
    ZONE=$2
    # Check if the cluster already exists
    if gcloud container clusters describe $CLUSTER_NAME --zone $ZONE --project ${PROJECT_ID} > /dev/null 2>&1; then
        echo "Registering ${CLUSTER_NAME} to fleet"
        gcloud container fleet memberships register ${CLUSTER_NAME} \
        --gke-cluster ${ZONE}/${CLUSTER_NAME} \
        --enable-workload-identity \
        --project=${PROJECT_ID}
    else
        echo "Cluster ${CLUSTER_NAME} doesn't exist."
    fi
}

function get_cluster_context() {
    CLUSTER_NAME=$1
    ZONE=$2
    # Check if the cluster already exists
    if gcloud container clusters describe $CLUSTER_NAME --zone $ZONE --project ${PROJECT_ID} > /dev/null 2>&1; then
        # Rename
        gcloud container clusters get-credentials ${CLUSTER_NAME} --zone=${ZONE} --project=${PROJECT_ID}
        kubectl config delete-context ${CLUSTER_NAME}
        kubectl config rename-context gke_${PROJECT_ID}_${ZONE}_${CLUSTER_NAME} ${CLUSTER_NAME}
    else
        echo "Cluster ${CLUSTER_NAME} doesn't exist."
    fi
}

# Enable MC Services
gcloud container fleet multi-cluster-services enable \
    --project=${PROJECT_ID}

# Grant the required Identity and Access Management (IAM) permissions for MCS Importer
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${PROJECT_ID}.svc.id.goog[gke-mcs/gke-mcs-importer]" \
    --role "roles/compute.networkViewer" \
    --project=${PROJECT_ID}

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${PROJECT_ID}.svc.id.goog[gke-mcs/gke-mcs-importer]" \
    --role "roles/dns.admin" \
    --project=${PROJECT_ID}

# get clusters contexts
cp $KUBECONFIG $KUBECONFIG.$(date +%Y-%m-%d_%H-%M-%S)
get_cluster_context "gke-west-1" "us-west1-a"
get_cluster_context "gke-east-1" "us-east1-b"

# register clusters
register_cluster "gke-west-1" "us-west1-a"
register_cluster "gke-east-1" "us-east1-b"

# Fleet list and configuration
echo 'Running: container fleet memberships list'
gcloud container fleet memberships list --project=${PROJECT_ID}

# Enable MC Gateway
# Set configuration cluster
CONFIG_CLUSTER_NAME=gke-west-1
CONFIG_CLUSTER_REGION=us-west1
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-multiclusteringress.iam.gserviceaccount.com" \
    --role "roles/container.admin" \
    --project=${PROJECT_ID}

gcloud container fleet ingress enable \
    --config-membership=projects/${PROJECT_ID}/locations/${CONFIG_CLUSTER_REGION}/memberships/${CONFIG_CLUSTER_NAME} \
    --project=${PROJECT_ID}

echo 'Running: container fleet ingress describe'
gcloud container fleet ingress describe --project=${PROJECT_ID}

# Switch to config cluster
kubectl config use-context ${CONFIG_CLUSTER_NAME}