#!/bin/bash

# Script para build das imagens principal e sidecar
set -e

MAIN_IMAGE_NAME="localhost/nextjs-k8s-podman"
SIDECAR_IMAGE_NAME="localhost/nextjs-k8s-podman-sidecar"
IMAGE_TAG="latest"

echo "🚀 Building multi-container application..."

# Função para detectar runtime disponível (prioriza Podman)
detect_runtime() {
    if command -v podman &> /dev/null; then
        echo "podman"
    elif command -v docker &> /dev/null && docker info &> /dev/null 2>&1; then
        echo "docker"
    else
        echo "none"
    fi
}

# Detectar runtime
RUNTIME=$(detect_runtime)

case $RUNTIME in
    "podman")
        echo "🐳 Usando Podman como runtime (preferido)"
        BUILD_CMD_MAIN="podman build --cgroup-manager=cgroupfs --format=docker -f Containerfile -t ${MAIN_IMAGE_NAME}:${IMAGE_TAG} ."
        BUILD_CMD_SIDECAR="podman build --cgroup-manager=cgroupfs --format=docker -f Containerfile -t ${SIDECAR_IMAGE_NAME}:${IMAGE_TAG} ."
        IMAGES_CMD="podman images"
        ;;
    "docker")
        echo "🐳 Usando Docker como runtime (fallback)"
        BUILD_CMD_MAIN="docker build -f Dockerfile.simple -t ${MAIN_IMAGE_NAME}:${IMAGE_TAG} ."
        BUILD_CMD_SIDECAR="docker build -f Containerfile -t ${SIDECAR_IMAGE_NAME}:${IMAGE_TAG} ."
        IMAGES_CMD="docker images"
        ;;
    "none")
        echo "❌ Nem Podman nem Docker foram encontrados!"
        exit 1
        ;;
esac

echo ""
echo "📦 Building main application (Next.js)..."
eval $BUILD_CMD_MAIN

if [ $? -eq 0 ]; then
    echo "✅ Main application build successful!"
else
    echo "❌ Main application build failed!"
    exit 1
fi

echo ""
echo "📦 Building sidecar service..."
cd sidecar
eval $BUILD_CMD_SIDECAR
cd ..

if [ $? -eq 0 ]; then
    echo "✅ Sidecar build successful!"
else
    echo "❌ Sidecar build failed!"
    exit 1
fi

echo ""
echo "🎉 Both images built successfully!"
echo ""
echo "📋 Built images:"
$IMAGES_CMD | grep nextjs-k8s-podman

echo ""
echo "🎯 Next steps:"
echo "   🧪 Test locally:"
echo "      # Terminal 1 - Sidecar"
echo "      $RUNTIME run -p 8080:8080 --rm -e BACKGROUND_COLOR=\"#2ecc71\" ${SIDECAR_IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "      # Terminal 2 - Main app"
echo "      $RUNTIME run -p 3000:3000 --rm -e SIDECAR_URL=\"http://host.containers.internal:8080\" ${MAIN_IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "   ☸️ Deploy to Kubernetes:"
echo "      kubectl apply -f k8s/deployment-multi.yaml"
echo ""
echo "   📤 Push to registry:"
echo "      $RUNTIME push ${MAIN_IMAGE_NAME}:${IMAGE_TAG} <registry-url>/"
echo "      $RUNTIME push ${SIDECAR_IMAGE_NAME}:${IMAGE_TAG} <registry-url>/"

if [ "$RUNTIME" = "podman" ]; then
    echo ""
    echo "   🔄 Load to minikube:"
    echo "      podman save ${MAIN_IMAGE_NAME}:${IMAGE_TAG} | minikube image load -"
    echo "      podman save ${SIDECAR_IMAGE_NAME}:${IMAGE_TAG} | minikube image load -"
fi