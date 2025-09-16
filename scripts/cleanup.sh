#!/bin/bash

# Script para limpeza dos recursos do Kubernetes
set -e

NAMESPACE="nextjs-app"

echo "🧹 Limpando recursos do Kubernetes..."

# Confirmar antes de deletar
read -p "⚠️  Tem certeza que deseja remover todos os recursos? (y/N): " confirm

if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    echo "🗑️  Removendo recursos..."
    
    kubectl delete -f k8s/ingress.yaml --ignore-not-found=true
    kubectl delete -f k8s/service.yaml --ignore-not-found=true
    kubectl delete -f k8s/deployment.yaml --ignore-not-found=true
    kubectl delete -f k8s/configmap.yaml --ignore-not-found=true
    kubectl delete -f k8s/namespace.yaml --ignore-not-found=true
    
    echo "✅ Limpeza concluída!"
    
    # Mostrar se ainda existem recursos
    if kubectl get namespace ${NAMESPACE} &> /dev/null; then
        echo "⚠️  O namespace ainda existe. Pode estar sendo finalizado..."
    else
        echo "✨ Todos os recursos foram removidos com sucesso!"
    fi
else
    echo "❌ Operação cancelada."
fi