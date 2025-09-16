#!/bin/bash

# Script para configurar mapeamento de host local para acessar a aplicação via Ingress
set -e

INGRESS_HOST="nextjs-app.local"

echo "🌐 Configurando mapeamento de host para acesso via Ingress..."

# Verificar se estamos usando Minikube
if ! kubectl config current-context | grep -q minikube; then
    echo "⚠️  Este script é otimizado para Minikube. Para outros clusters, ajuste o IP do Ingress Controller."
fi

# Obter IP do Minikube
MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "127.0.0.1")

if [ "$MINIKUBE_IP" = "127.0.0.1" ]; then
    echo "⚠️  Não foi possível obter o IP do Minikube. Usando 127.0.0.1"
    echo "   Se estiver usando outro cluster, configure manualmente o IP correto."
fi

echo "📋 Informações de configuração:"
echo "   Host: $INGRESS_HOST"  
echo "   IP: $MINIKUBE_IP"
echo ""

# Verificar se já existe entrada no /etc/hosts
if grep -q "$INGRESS_HOST" /etc/hosts; then
    echo "✅ Entrada já existe em /etc/hosts"
    echo "   Atual: $(grep "$INGRESS_HOST" /etc/hosts)"
    echo ""
    read -p "🤔 Deseja atualizar? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Remove entrada antiga
        sudo sed -i "/$INGRESS_HOST/d" /etc/hosts
        # Adiciona nova entrada
        echo "$MINIKUBE_IP $INGRESS_HOST" | sudo tee -a /etc/hosts > /dev/null
        echo "✅ Entrada atualizada em /etc/hosts"
    else
        echo "⏭️  Mantendo configuração atual"
    fi
else
    echo "➕ Adicionando entrada no /etc/hosts..."
    echo "   Será necessária permissão de administrador"
    echo "$MINIKUBE_IP $INGRESS_HOST" | sudo tee -a /etc/hosts > /dev/null
    echo "✅ Entrada adicionada em /etc/hosts"
fi

echo ""
echo "🎯 Configuração concluída!"
echo ""
echo "📡 Para habilitar o Ingress Controller no Minikube (se ainda não habilitado):"
echo "   minikube addons enable ingress"
echo ""
echo "🌐 Para acessar a aplicação:"
echo "   Browser: http://$INGRESS_HOST"
echo "   Curl: curl http://$INGRESS_HOST"
echo ""
echo "🔍 Para verificar o status:"
echo "   kubectl get ingress -n nextjs-app"
echo "   kubectl describe ingress nextjs-ingress -n nextjs-app"
echo ""
echo "🗑️  Para remover o mapeamento posteriormente:"
echo "   sudo sed -i '/$INGRESS_HOST/d' /etc/hosts"
echo ""