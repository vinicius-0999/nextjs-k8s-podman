#!/bin/bash

# Deploy completo do projeto Next.js + Sidecar no Kubernetes
set -e

echo "🚀 Iniciando deploy do projeto Next.js com Sidecar..."

# Verificar se kubectl está disponível
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl não encontrado. Por favor, instale o kubectl."
    exit 1
fi

# Verificar se podman/docker está disponível
CONTAINER_RUNTIME=""
if command -v podman &> /dev/null; then
    CONTAINER_RUNTIME="podman"
    echo "🐳 Usando Podman como runtime"
elif command -v docker &> /dev/null; then
    CONTAINER_RUNTIME="docker"
    echo "🐳 Usando Docker como runtime"
else
    echo "❌ Nem Podman nem Docker foram encontrados"
    exit 1
fi

# 1. Build das imagens
echo "📦 Construindo imagens..."
./scripts/build-all.sh

# 2. Carregar imagens no Minikube (se estiver usando Minikube)
if kubectl config current-context | grep -q minikube; then
    echo "📥 Carregando imagens no Minikube..."
    minikube image load localhost/nextjs-k8s-podman:latest
    minikube image load localhost/nextjs-k8s-podman-sidecar:latest
fi

# 3. Aplicar manifests do Kubernetes
echo "☸️  Aplicando manifests do Kubernetes..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment-multi.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

# 4. Aguardar deployment estar pronto
echo "⏳ Aguardando deployment estar pronto..."
kubectl rollout status deployment/nextjs-app -n nextjs-app --timeout=300s

# 5. Fazer rollout restart para garantir que as imagens mais recentes sejam usadas
echo "🔄 Fazendo rollout restart para garantir imagens atualizadas..."
kubectl rollout restart deployment/nextjs-app -n nextjs-app

# 6. Aguardar novamente o rollout
echo "⏳ Aguardando rollout restart..."
kubectl rollout status deployment/nextjs-app -n nextjs-app --timeout=300s

# 7. Verificar status dos pods
echo "🔍 Verificando status dos pods..."
kubectl get pods -n nextjs-app

echo ""
echo "✅ Deploy concluído com sucesso!"
echo ""
echo "📋 Informações do deploy:"
echo "   Namespace: nextjs-app"
echo "   Deployment: nextjs-app"
echo "   Service: nextjs-service"
echo "   Ingress: nextjs-ingress"
echo ""
echo "🌐 Para acessar a aplicação:"
echo "   Porta local: kubectl port-forward svc/nextjs-service -n nextjs-app 3000:80"
echo "   Via Ingress: Consulte ./scripts/setup-host.sh para configurar o host local"
echo ""