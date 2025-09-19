#!/bin/bash
set -e

echo "🚀 Deploy do Next.js + Sidecar no Kubernetes"

# Variáveis vindas do CI/CD ou setadas manualmente
IMAGE_TAG="${CI_COMMIT_SHA:-latest}"
REGISTRY="registry.gitlab.com"
MAIN_IMAGE="$REGISTRY/${CI_PROJECT_PATH:-seu-grupo/seu-projeto}/nextjs-k8s-podman"
SIDECAR_IMAGE="$REGISTRY/${CI_PROJECT_PATH:-seu-grupo/seu-projeto}/nextjs-k8s-podman-sidecar"
NAMESPACE="nextjs-app"

echo "📋 Usando imagens:"
echo "   Main:    $MAIN_IMAGE:$IMAGE_TAG"
echo "   Sidecar: $SIDECAR_IMAGE:$IMAGE_TAG"

# Atualizar as imagens no deployment
kubectl set image deployment/nextjs-app \
  main=$MAIN_IMAGE:$IMAGE_TAG \
  sidecar=$SIDECAR_IMAGE:$IMAGE_TAG \
  -n $NAMESPACE

# Aguardar rollout
kubectl rollout status deployment/nextjs-app -n $NAMESPACE --timeout=300s

echo "✅ Deploy concluído!"
