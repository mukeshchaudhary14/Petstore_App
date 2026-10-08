#!/usr/bin/env bash
# ==============================================================================
# Helper Script to Build and Run Petstore Application locally via Docker
# ==============================================================================

set -e

IMAGE_NAME="${1:-petstore-app:latest}"
CONTAINER_NAME="petstore-app"
PORT="${PORT:-8082}"

echo "======================================================================"
echo " Building Docker Image: ${IMAGE_NAME}"
echo "======================================================================"

docker build -t "${IMAGE_NAME}" .

echo ""
echo "======================================================================"
echo " Starting Container: ${CONTAINER_NAME}"
echo "======================================================================"

# Stop and remove existing container if running
if [ "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "[INFO] Stopping and removing existing container..."
    docker stop "${CONTAINER_NAME}" || true
    docker rm "${CONTAINER_NAME}" || true
fi

docker run -d \
  --name "${CONTAINER_NAME}" \
  -p "${PORT}:8080" \
  "${IMAGE_NAME}"

echo ""
echo ">>> Waiting for application to initialize on http://localhost:${PORT}/jpetstore/ ..."
for i in {1..20}; do
    if curl -s -f "http://localhost:${PORT}/jpetstore/" > /dev/null 2>&1 || curl -s -f "http://localhost:${PORT}/" > /dev/null 2>&1; then
        echo ""
        echo "======================================================================"
        echo " Petstore Application is LIVE and healthy!"
        echo " Access URL: http://localhost:${PORT}/jpetstore/"
        echo " Direct URL: http://localhost:${PORT}/"
        echo "======================================================================"
        exit 0
    fi
    echo -n "."
    sleep 3
done

echo ""
echo "[WARNING] Application is taking longer than usual to respond. Inspect logs with:"
echo "  docker logs -f ${CONTAINER_NAME}"
