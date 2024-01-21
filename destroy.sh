#!/bin/bash
# Set environment variables from .env
set -o allexport
export SCRIPT_DIR=$(dirname "$0")
source ${SCRIPT_DIR}/.env
set +o allexport

${SCRIPT_DIR}/scripts/unregister_clusters.sh
${SCRIPT_DIR}/scripts/destroy_clusters.sh