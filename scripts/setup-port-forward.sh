#!/bin/bash

# Setup Port Forward para Windows
# Este script cria um túnel direto do Windows para o pod via WSL

set -e

echo "🔗 Configurando Port Forward para Windows..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Namespace
NAMESPACE="nextjs-app"

# Função para verificar se o port-forward está rodando
check_port_forward() {
    if netstat -tuln | grep -q ":3000 "; then
        return 0
    else
        return 1
    fi
}

# Função para parar port-forward existente
stop_existing_port_forward() {
    echo -e "${YELLOW}📦 Parando port-forward existente...${NC}"
    pkill -f "kubectl port-forward" 2>/dev/null || true
    sleep 2
}

# Função para obter o nome do service
get_service_name() {
    kubectl get services -n $NAMESPACE -l app=nextjs-app -o jsonpath="{.items[0].metadata.name}" 2>/dev/null
}

# Função para obter o nome do pod (para logs apenas)
get_pod_name() {
    kubectl get pods -n $NAMESPACE -l app=nextjs-app -o jsonpath="{.items[0].metadata.name}" 2>/dev/null
}

# Verificar se minikube está rodando
if ! minikube status | grep -q "host: Running"; then
    echo -e "${RED}❌ Minikube não está rodando!${NC}"
    echo -e "${YELLOW}💡 Execute: minikube start${NC}"
    exit 1
fi

# Verificar se o namespace existe
if ! kubectl get namespace $NAMESPACE &>/dev/null; then
    echo -e "${RED}❌ Namespace $NAMESPACE não encontrado!${NC}"
    echo -e "${YELLOW}💡 Execute primeiro: ./scripts/deploy.sh${NC}"
    exit 1
fi

# Parar port-forward existente
stop_existing_port_forward

# Obter nome do service
SERVICE_NAME=$(get_service_name)

if [ -z "$SERVICE_NAME" ]; then
    echo -e "${RED}❌ Nenhum service encontrado no namespace $NAMESPACE${NC}"
    echo -e "${YELLOW}💡 Execute primeiro: ./scripts/deploy.sh${NC}"
    exit 1
fi

echo -e "${BLUE}� Service encontrado: $SERVICE_NAME${NC}"

# Verificar se há pods rodando (para garantir que o service tem endpoints)
POD_NAME=$(get_pod_name)
if [ -z "$POD_NAME" ]; then
    echo -e "${RED}❌ Nenhum pod encontrado para o service${NC}"
    echo -e "${YELLOW}💡 Execute primeiro: ./scripts/deploy.sh${NC}"
    exit 1
fi

# Verificar se o pod está pronto
echo -e "${YELLOW}⏳ Aguardando pod estar pronto...${NC}"
kubectl wait --for=condition=Ready pod/$POD_NAME -n $NAMESPACE --timeout=60s

# Iniciar port-forward no SERVICE (balanceador)
echo -e "${YELLOW}🔗 Iniciando port-forward no SERVICE (com load balancing) na porta 3000...${NC}"
echo -e "${BLUE}📋 Service: $SERVICE_NAME (porta 80 -> container 3000)${NC}"

# Port-forward correto: localhost:3000 -> service:80 -> pod:3000
kubectl port-forward service/$SERVICE_NAME -n $NAMESPACE 3000:80 --address=0.0.0.0 &

PORTFORWARD_PID=$!

# Aguardar alguns segundos para o port-forward se estabelecer
sleep 8

echo -e "${CYAN}🔍 Testando conectividade...${NC}"

# Testar conectividade múltiplas vezes para verificar load balancing
for i in {1..3}; do
    echo -n "Teste $i: "
    if curl -s -m 5 http://localhost:3000 >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Conectado${NC}"
    else
        echo -e "${RED}❌ Falhou${NC}"
    fi
    sleep 1
done

echo

# Verificar se funcionou
if check_port_forward; then
    echo -e "${GREEN}✅ Port-forward ativo na porta 3000 (via SERVICE com load balancing)${NC}"
    echo
    echo -e "${BLUE}🌐 Acesso disponível em:${NC}"
    echo -e "${GREEN}   • WSL: http://localhost:3000${NC}"
    echo -e "${GREEN}   • Windows: http://localhost:3000${NC}"
    echo
    echo -e "${BLUE}🔄 Load Balancing:${NC}"
    echo -e "${GREEN}   • Requisições distribuídas via Service Kubernetes${NC}"
    echo -e "${GREEN}   • Service: $SERVICE_NAME${NC}"
    echo -e "${GREEN}   • Fluxo: localhost:3000 -> service:80 -> pod:3000${NC}"
    echo -e "${GREEN}   • Se um pod falhar, outros continuam funcionando${NC}"
    echo
    echo -e "${YELLOW}💡 Para parar o port-forward:${NC}"
    echo -e "   pkill -f 'kubectl port-forward'"
    echo
    
    # Obter IP do WSL para Windows
    WSL_IP=$(hostname -I | awk '{print $1}')
    echo -e "${BLUE}📍 IP do WSL: $WSL_IP${NC}"
    echo -e "${GREEN}   • Windows também pode usar: http://$WSL_IP:3000${NC}"
    echo
    
else
    echo -e "${RED}❌ Erro ao configurar port-forward${NC}"
    exit 1
fi

# Manter script rodando para mostrar logs
echo -e "${YELLOW}📋 Port-forward ativo via SERVICE. Pressione Ctrl+C para parar.${NC}"
echo -e "${BLUE}🔍 Logs do port-forward (com load balancing):${NC}"
echo -e "${CYAN}💡 Teste o balanceamento: curl http://localhost:3000 (múltiplas vezes)${NC}"
echo

# Capturar Ctrl+C e limpar
trap 'echo -e "\n${YELLOW}🛑 Parando port-forward...${NC}"; kill $PORTFORWARD_PID 2>/dev/null; exit 0' INT

# DISCLAIMER
echo -e "${YELLOW}⚠️  IMPORTANTE - Load Balancing via Service:${NC}"
echo -e "${GREEN}   • Este script usa port-forward no SERVICE, não em pods específicos${NC}"
echo -e "${GREEN}   • Requisições são automaticamente distribuídas entre todos os pods${NC}"
echo -e "${GREEN}   • Se um pod falhar, o Service continua funcionando com outros pods${NC}"
echo -e "${GREEN}   • Para testar: ./scripts/quick-test.sh ou ./scripts/test-load-balancing.sh${NC}"
echo

# Aguardar até ser interrompido  
wait $PORTFORWARD_PID