#!/usr/bin/env bash
# ==============================================================================
# Helper Script to Install and Configure ArgoCD for PetStore GitOps
# ==============================================================================

set -e

ARGOCD_NAMESPACE="argocd"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================================================"
echo " Setting up ArgoCD GitOps for PetStore Application"
echo "======================================================================"

# 1. Create ArgoCD namespace
echo ">>> [1/5] Creating ArgoCD Namespace..."
kubectl create namespace ${ARGOCD_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# 2. Install ArgoCD
echo ">>> [2/5] Applying ArgoCD Official Manifests..."
kubectl apply -n ${ARGOCD_NAMESPACE} -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Wait for ArgoCD server
echo ">>> [3/5] Waiting for ArgoCD Server to be ready..."
kubectl wait --for=condition=available deployment/argocd-server -n ${ARGOCD_NAMESPACE} --timeout=180s || true

# 4. Get Initial Admin Password
echo ">>> [4/5] Retrieving ArgoCD Initial Admin Password..."
ADMIN_PWD=$(kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "Password secret pending, check in 1-2 minutes.")
echo "----------------------------------------------------------------------"
echo " ArgoCD Web UI: https://localhost:8443"
echo " Username:      admin"
echo " Password:      ${ADMIN_PWD}"
echo "----------------------------------------------------------------------"

# 5. Apply PetStore Application Manifest
echo ">>> [5/5] Deploying PetStore ArgoCD Application..."
kubectl apply -f "${SCRIPT_DIR}/application.yaml"

echo ""
echo "======================================================================"
echo " Setup Completed!"
echo " To access the ArgoCD Web UI locally, run:"
echo "   kubectl port-forward svc/argocd-server -n ${ARGOCD_NAMESPACE} 8443:443"
echo "======================================================================"
