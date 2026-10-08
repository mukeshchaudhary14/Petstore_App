#!/usr/bin/env bash
# ==============================================================================
# Helper Script to Deploy Petstore Application to Kubernetes via kubectl
# ==============================================================================

set -e

NAMESPACE="${1:-petstore}"

echo "======================================================================"
echo " Deploying Petstore Application to Kubernetes (Namespace: ${NAMESPACE})"
echo "======================================================================"

kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml -n "${NAMESPACE}"
kubectl apply -f k8s/secret.yaml -n "${NAMESPACE}"
kubectl apply -f k8s/deployment.yaml -n "${NAMESPACE}"
kubectl apply -f k8s/service.yaml -n "${NAMESPACE}"
kubectl apply -f k8s/ingress.yaml -n "${NAMESPACE}" || echo "[NOTE] Ingress skipped or not supported by cluster."
kubectl apply -f k8s/hpa.yaml -n "${NAMESPACE}" || echo "[NOTE] HPA skipped (requires metrics-server)."

echo ""
echo ">>> Checking Deployment Status..."
kubectl rollout status deployment/petstore-deployment -n "${NAMESPACE}" --timeout=120s || true

echo ""
echo ">>> Current Pods & Services in namespace ${NAMESPACE}:"
kubectl get pods,svc,ingress,hpa -n "${NAMESPACE}"

echo ""
echo "======================================================================"
echo " Deployment Complete!"
echo " Port forward command: kubectl port-forward svc/petstore-service 8080:80 -n ${NAMESPACE}"
echo "======================================================================"
