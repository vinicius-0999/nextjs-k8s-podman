#!/bin/bash
set -e

echo "🚀 Build & Push de imagens Next.js + Sidecar para o GitLab Registry"

# Variáveis vindas do CI/CD ou setadas manualmente para teste local
IMAGE_TAG="${CI_COMMIT_SHA:-latest}"
REGISTRY="registry.gitlab.com"
MAIN_IMAGE="$CI_REGISTRY_IMAGE/nextjs-k8s-podman"
SIDECAR_IMAGE="$CI_REGISTRY_IMAGE/nextjs-k8s-podman-sidecar"

# Detectar runtime (preferência Podman > Docker)
detect_runtime() {
    if command -v podman &> /dev/null; then
        echo "podman"
    elif command -v docker &> /dev/null; then
        echo "docker"
    else
        echo "none"
    fi
}

RUNTIME=$(detect_runtime)
if [ "$RUNTIME" = "none" ]; then
    echo "❌ Nem Podman nem Docker encontrados!"
    exit 1
fi

echo "🐳 Usando $RUNTIME para build"

# Login no registry (no CI usa gitlab-ci-token, localmente precisa docker/podman login manual)
if [ -n "$CI_JOB_TOKEN" ]; then
    echo "🔑 Fazendo login no GitLab Registry..."
    $RUNTIME login $REGISTRY -u gitlab-ci-token -p "$CI_JOB_TOKEN"
fi

# Build das imagens
echo "📦 Build da aplicação principal"
$RUNTIME build --format=docker -f Dockerfile.simple -t $MAIN_IMAGE:$IMAGE_TAG .

echo "📦 Build do sidecar"
$RUNTIME build --format=docker -f Containerfile -t $SIDECAR_IMAGE:$IMAGE_TAG ./sidecar

# Push
echo "📤 Push das imagens"
$RUNTIME push $MAIN_IMAGE:$IMAGE_TAG
$RUNTIME push $SIDECAR_IMAGE:$IMAGE_TAG

echo "✅ Imagens publicadas com sucesso!"
