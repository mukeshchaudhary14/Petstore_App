#!/usr/bin/env bash
# ==============================================================================
# Trivy Security Scanner Script for Petstore App
# Scans filesystem, docker images, and Kubernetes/Helm configuration
# ==============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORTS_DIR="${PROJECT_DIR}/security-reports"
IMAGE_NAME="${1:-petstore-app:latest}"

mkdir -p "${REPORTS_DIR}"

echo "======================================================================"
echo " Starting Trivy Security Scan for PetStore Application"
echo " Reports will be saved to: ${REPORTS_DIR}"
echo "======================================================================"

# Determine if Trivy binary is available or use Docker container
if command -v trivy &> /dev/null; then
    TRIVY_CMD="trivy"
elif command -v docker &> /dev/null; then
    echo "[INFO] Trivy CLI not found locally. Using Docker container 'aquasec/trivy'..."
    TRIVY_CMD="docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v ${PROJECT_DIR}:/workspace -w /workspace -v ${HOME}/.cache/trivy:/root/.cache/trivy aquasec/trivy:latest"
else
    echo "[ERROR] Neither 'trivy' CLI nor 'docker' is installed. Cannot proceed."
    exit 1
fi

echo ""
echo ">>> [1/3] Scanning Filesystem (Dependencies, Secrets & Misconfigs)..."
${TRIVY_CMD} fs \
  --config trivy.yaml \
  --severity HIGH,CRITICAL \
  --format table \
  --output "security-reports/trivy-fs-report.txt" \
  . || true

${TRIVY_CMD} fs \
  --config trivy.yaml \
  --severity HIGH,CRITICAL \
  --format json \
  --output "security-reports/trivy-fs-report.json" \
  . || true

echo "[DONE] Filesystem scan report saved to security-reports/trivy-fs-report.txt"

echo ""
echo ">>> [2/3] Scanning Kubernetes & Helm Manifests (IaC Misconfigurations)..."
${TRIVY_CMD} config \
  --severity HIGH,CRITICAL \
  --format table \
  --output "security-reports/trivy-iac-report.txt" \
  k8s/ helm/ || true

echo "[DONE] IaC scan report saved to security-reports/trivy-iac-report.txt"

echo ""
echo ">>> [3/3] Scanning Docker Image: ${IMAGE_NAME}..."
${TRIVY_CMD} image \
  --severity HIGH,CRITICAL \
  --format table \
  --output "security-reports/trivy-image-report.txt" \
  "${IMAGE_NAME}" || true

${TRIVY_CMD} image \
  --severity HIGH,CRITICAL \
  --format json \
  --output "security-reports/trivy-image-report.json" \
  "${IMAGE_NAME}" || true

echo "[DONE] Image scan report saved to security-reports/trivy-image-report.txt"

echo ""
echo "======================================================================"
echo " Trivy Scan Completed Successfully!"
echo " Reports available at: ${REPORTS_DIR}"
echo "======================================================================"
