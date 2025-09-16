#!/bin/bash

# Script para testar aplicação com sidecar localmente
set -e

MAIN_IMAGE_NAME="localhost/nextjs-k8s-podman"
SIDECAR_IMAGE_NAME="localhost/nextjs-k8s-podman-sidecar"
IMAGE_TAG="latest"

SIDECAR_PORT=${1:-8080}
MAIN_PORT=${2:-3000}
BACKGROUND_COLOR=${3:-"#2ecc71"}

echo "🧪 Testing multi-container application locally..."
echo "   Sidecar port: $SIDECAR_PORT"
echo "   Main app port: $MAIN_PORT"
echo "   Background color: $BACKGROUND_COLOR"

# Detectar runtime
if command -v podman &> /dev/null; then
    RUNTIME="podman"
    NETWORK_URL="http://host.containers.internal:$SIDECAR_PORT"
elif command -v docker &> /dev/null; then
    RUNTIME="docker"
    NETWORK_URL="http://host.docker.internal:$SIDECAR_PORT"
else
    echo "❌ Nem Podman nem Docker encontrados!"
    exit 1
fi

echo "🐳 Using $RUNTIME"

# Função para cleanup
cleanup() {
    echo ""
    echo "🧹 Cleaning up containers..."
    $RUNTIME stop nextjs-sidecar-test nextjs-main-test 2>/dev/null || true
    $RUNTIME rm nextjs-sidecar-test nextjs-main-test 2>/dev/null || true
}

# Trap para cleanup
trap cleanup EXIT

# Verificar se as imagens existem
echo "🔍 Checking if images exist..."
if ! $RUNTIME images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${SIDECAR_IMAGE_NAME}:${IMAGE_TAG}$"; then
    echo "❌ Sidecar image not found: ${SIDECAR_IMAGE_NAME}:${IMAGE_TAG}"
    echo "💡 Run: ./scripts/build-all.sh"
    exit 1
fi

if ! $RUNTIME images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${MAIN_IMAGE_NAME}:${IMAGE_TAG}$"; then
    echo "❌ Main app image not found: ${MAIN_IMAGE_NAME}:${IMAGE_TAG}"
    echo "💡 Run: ./scripts/build-all.sh"
    exit 1
fi

echo "✅ Both images found"

# Iniciar sidecar
echo ""
echo "🚀 Starting sidecar container..."
$RUNTIME run -d \
    --name nextjs-sidecar-test \
    -p $SIDECAR_PORT:8080 \
    -e BACKGROUND_COLOR="$BACKGROUND_COLOR" \
    -e POD_NAME="sidecar-test-pod" \
    -e POD_IP="127.0.0.1" \
    -e NODE_NAME="local-test-node" \
    -e POD_NAMESPACE="test-namespace" \
    ${SIDECAR_IMAGE_NAME}:${IMAGE_TAG}

# Aguardar sidecar ficar pronto
echo "⏳ Waiting for sidecar to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:$SIDECAR_PORT/health > /dev/null 2>&1; then
        echo "✅ Sidecar is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Sidecar failed to start"
        $RUNTIME logs nextjs-sidecar-test
        exit 1
    fi
    sleep 1
done

# Iniciar aplicação principal
echo ""
echo "🚀 Starting main application..."
$RUNTIME run -d \
    --name nextjs-main-test \
    -p $MAIN_PORT:3000 \
    -e SIDECAR_URL="$NETWORK_URL" \
    -e BACKGROUND_COLOR="$BACKGROUND_COLOR" \
    -e POD_NAME="main-test-pod" \
    -e NODE_NAME="local-test-node" \
    -e POD_NAMESPACE="test-namespace" \
    ${MAIN_IMAGE_NAME}:${IMAGE_TAG}

# Aguardar aplicação ficar pronta
echo "⏳ Waiting for main application to be ready..."
for i in {1..60}; do
    if curl -s http://localhost:$MAIN_PORT > /dev/null 2>&1; then
        echo "✅ Main application is ready!"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "❌ Main application failed to start"
        $RUNTIME logs nextjs-main-test
        exit 1
    fi
    sleep 1
done

echo ""
echo "🎉 Both containers are running successfully!"
echo ""
echo "🌐 Access points:"
echo "   Main application: http://localhost:$MAIN_PORT"
echo "   Sidecar API:      http://localhost:$SIDECAR_PORT/pod-info"
echo "   Sidecar health:   http://localhost:$SIDECAR_PORT/health"
echo ""
echo "🔍 Test commands:"
echo "   curl http://localhost:$SIDECAR_PORT/pod-info | jq"
echo "   curl http://localhost:$SIDECAR_PORT/health | jq"
echo ""
echo "📝 Container logs:"
echo "   $RUNTIME logs nextjs-sidecar-test"
echo "   $RUNTIME logs nextjs-main-test"
echo ""
echo "Press Ctrl+C to stop containers..."

# Mostrar logs em tempo real
$RUNTIME logs -f nextjs-main-test