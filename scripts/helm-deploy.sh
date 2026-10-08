#!/usr/bin/env bash
# ==============================================================================
# Helper Script to Deploy Petstore Application using Helm
# ==============================================================================

set -e

RELEASE_NAME="${1:-petstore}"
NAMESPACE="${2:-petstore}"
IMAGE_TAG="${3:-latest}"

echo "======================================================================"
echo " Deploying Petstore Application via Helm Chart"
echo " Release Name: ${RELEASE_NAME}"
echo " Namespace:    ${NAMESPACE}"
echo " Image Tag:    ${IMAGE_TAG}"
echo "======================================================================"

# 1. Lint the chart
echo ">>> [1/3] Linting Helm Chart..."
helm lint helm/petstore

# 2. Deploy or Upgrade Release
echo ">>> [2/3] Installing / Upgrading Helm Release..."
helm upgrade --install "${RELEASE_NAME}" helm/petstore \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --set image.tag="${IMAGE_TAG}"

# 3. View status
echo ""
echo ">>> [3/3] Release Status:"
helm status "${RELEASE_NAME}" -n "${NAMESPACE}"

echo ""
echo "======================================================================"
echo " Helm Deployment Completed!"
echo " List releases: helm list -n ${NAMESPACE}"
echo "======================================================================"
