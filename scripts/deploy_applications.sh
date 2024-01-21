#!/bin/bash
[ -d "$SCRIPT_DIR" ] || SCRIPT_DIR="."
source ${SCRIPT_DIR}/.env

# Wait for ServiceExport CRD to exist
until kubectl get crd serviceexports.net.gke.io --context gke-west-1 &> /dev/null; do
  echo "gke-west-1: Waiting for ServiceExport CRD to exist... sleeping 30s."
  sleep 30
done
echo "gke-west-1: ServiceExport CRD exists."

until kubectl get crd serviceexports.net.gke.io --context gke-east-1 &> /dev/null; do
  echo "gke-east-1: Waiting for ServiceExport CRD to exist... sleeping 30s."
  sleep 30
done
echo "gke-east-1: ServiceExport CRD exists."

# Store Deployments
kubectl apply --context gke-west-1 -f ${SCRIPT_DIR}/manifests/store.yaml
kubectl apply --context gke-east-1 -f ${SCRIPT_DIR}/manifests/store.yaml

# Store services
kubectl apply --context gke-west-1 -f ${SCRIPT_DIR}/manifests/service-west-1.yaml
kubectl apply --context gke-east-1 -f ${SCRIPT_DIR}/manifests/service-east-1.yaml

kubectl get serviceexports --context gke-west-1 --namespace store
kubectl get serviceexports --context gke-east-1 --namespace store

# Wait for ServiceImport object to exist in 'store' namespace...
until kubectl get serviceimport -n store --context gke-west-1 --no-headers | grep '.' &> /dev/null; do
  echo "gke-west-1: Waiting for ServiceImport object to exist in 'store' namespace... sleeping 30s."
  sleep 30
done
echo "gke-west-1: ServiceImport object exists in 'store' namespace."


until kubectl get serviceimport -n store --context gke-east-1 --no-headers | grep '.' &> /dev/null; do
  echo "gke-east-1: Waiting for ServiceImport object to exist in 'store' namespace... sleeping 30s."
  sleep 30
done
echo "gke-east-1: ServiceImport object exists in 'store' namespace."


kubectl get serviceimports --context gke-west-1 --namespace store
kubectl get serviceimports --context gke-east-1 --namespace store

# Deploy gateway
kubectl apply --context gke-west-1 -f ${SCRIPT_DIR}/manifests/gateway.yaml

# Deploy HTTPRoute
kubectl apply --context gke-west-1 -f ${SCRIPT_DIR}/manifests/HTTPRoute.yaml
