#!/bin/bash
[ -d "$SCRIPT_DIR" ] || SCRIPT_DIR="."
source ${SCRIPT_DIR}/.env

# Enable gcloud services
gcloud services enable \
  trafficdirector.googleapis.com \
  multiclusterservicediscovery.googleapis.com \
  gkehub.googleapis.com \
  cloudresourcemanager.googleapis.com \
  multiclusteringress.googleapis.com \
  dns.googleapis.com \
  container.googleapis.com \
  gkeconnect.googleapis.com \
  iam.googleapis.com \
  --project=${PROJECT_ID}