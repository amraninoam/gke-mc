#!/bin/bash
# Set environment variables from .env
set -o allexport
export SCRIPT_DIR=$(dirname "$0")
source ${SCRIPT_DIR}/.env
set +o allexport


${SCRIPT_DIR}/scripts/enable_google_services.sh
${SCRIPT_DIR}/scripts/create_clusters.sh
${SCRIPT_DIR}/scripts/configure_clusters.sh
${SCRIPT_DIR}/scripts/deploy_applications.sh
${SCRIPT_DIR}/scripts/test_applications.sh