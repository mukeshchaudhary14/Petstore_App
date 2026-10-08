#!/usr/bin/env bash
# ==============================================================================
# Helper Script to launch Komodor Helm Dashboard
# ==============================================================================

set -e

PORT="${PORT:-8085}"
BIND="${BIND:-0.0.0.0}"

echo "======================================================================"
echo " Launching Komodor Helm Dashboard"
echo " Web UI will be available at: http://localhost:${PORT}"
echo "======================================================================"

if command -v helm &> /dev/null && helm plugin list | grep -q "dashboard"; then
    echo "[INFO] Running via Helm plugin..."
    helm dashboard --port "${PORT}" --bind "${BIND}"
elif command -v docker &> /dev/null; then
    echo "[INFO] Helm CLI plugin not found. Launching via Docker container..."
    KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/config}"
    if [ ! -f "$KUBECONFIG_PATH" ]; then
        echo "[WARNING] Kubeconfig not found at $KUBECONFIG_PATH. Helm dashboard might not see your cluster."
    fi
    docker run --rm -it \
      --name helm-dashboard \
      -p "${PORT}:8080" \
      -v "${KUBECONFIG_PATH}:/root/.kube/config:ro" \
      ghcr.io/komodorio/helm-dashboard:latest \
      --bind=0.0.0.0 --port=8080
else
    echo "[ERROR] Neither Helm dashboard plugin nor Docker is available."
    echo "To deploy in Kubernetes cluster, run:"
    echo "  kubectl apply -f helm-dashboard/k8s/rbac.yaml"
    echo "  kubectl apply -f helm-dashboard/k8s/deployment.yaml"
    echo "  kubectl port-forward svc/helm-dashboard-service -n helm-dashboard 8080:8080"
    exit 1
fi
