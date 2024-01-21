#!/bin/bash
[ -d "$SCRIPT_DIR" ] || SCRIPT_DIR="."
source ${SCRIPT_DIR}/.env

# Delete gateway
echo kubectl delete --context gke-west-1 -f ${SCRIPT_DIR}/manifests/gateway.yaml
kubectl delete --context gke-west-1 -f ${SCRIPT_DIR}/manifests/gateway.yaml

# Delete HTTPRoute
echo kubectl delete --context gke-west-1 -f ${SCRIPT_DIR}/manifests/HTTPRoute.yaml
kubectl delete --context gke-west-1 -f ${SCRIPT_DIR}/manifests/HTTPRoute.yaml

# Delete Store Deployments
echo kubectl delete --context gke-west-1 -f ${SCRIPT_DIR}/manifests/store.yaml
kubectl delete --context gke-west-1 -f ${SCRIPT_DIR}/manifests/store.yaml
# kubectl delete --context gke-west-2 -f ${SCRIPT_DIR}/manifests/store.yaml

echo kubectl delete --context gke-east-1 -f ${SCRIPT_DIR}/manifests/store.yaml
kubectl delete --context gke-east-1 -f ${SCRIPT_DIR}/manifests/store.yaml

# Delete Store services
echo kubectl delete --context gke-west-1 -f ${SCRIPT_DIR}/manifests/service-west-1.yaml
kubectl delete --context gke-west-1 -f ${SCRIPT_DIR}/manifests/service-west-1.yaml
echo kubectl delete --context gke-east-1 -f ${SCRIPT_DIR}/manifests/service-east-1.yaml
kubectl delete --context gke-east-1 -f ${SCRIPT_DIR}/manifests/service-east-1.yaml

