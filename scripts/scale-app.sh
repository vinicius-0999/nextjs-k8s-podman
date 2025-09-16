#!/bin/bash

# Script para escalar a aplicação e demonstrar load balancing
set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Namespace
NAMESPACE="nextjs-app"

echo -e "${BLUE}🚀 Demonstração de Load Balancing${NC}"
echo

# Função para mostrar pods atuais
show_current_pods() {
    echo -e "${CYAN}📦 Pods atuais:${NC}"
    kubectl get pods -n $NAMESPACE -l app=nextjs-app -o wide
    echo
}

# Função para testar load balancing
test_load_balancing() {
    local requests=$1
    echo -e "${YELLOW}🔄 Testando load balancing com $requests requisições...${NC}"
    echo
    
    for i in $(seq 1 $requests); do
        echo -n "Requisição $i: "
        RESPONSE=$(curl -s http://localhost:3000 2>/dev/null || echo "ERRO")
        
        if [[ "$RESPONSE" == *"Pod Name"* ]]; then
            POD_NAME=$(echo "$RESPONSE" | grep -o "Pod Name: [^<]*" | sed 's/Pod Name: //' || echo "Não encontrado")
            POD_IP=$(echo "$RESPONSE" | grep -o "Pod IP: [^<]*" | sed 's/Pod IP: //' || echo "Não encontrado")
            echo -e "${GREEN}✅ Pod: $POD_NAME (IP: $POD_IP)${NC}"
        else
            echo -e "${RED}❌ Erro na conexão${NC}"
        fi
        
        sleep 1
    done
    echo
}

# Verificar se minikube está rodando
if ! minikube status | grep -q "host: Running"; then
    echo -e "${RED}❌ Minikube não está rodando!${NC}"
    exit 1
fi

# Verificar se o namespace existe
if ! kubectl get namespace $NAMESPACE &>/dev/null; then
    echo -e "${RED}❌ Namespace $NAMESPACE não encontrado!${NC}"
    echo -e "${YELLOW}💡 Execute primeiro: ./scripts/deploy.sh${NC}"
    exit 1
fi

# Mostrar estado atual
show_current_pods

# Menu de opções
echo -e "${BLUE}Escolha uma opção:${NC}"
echo "1. Escalar para 3 replicas"
echo "2. Escalar para 5 replicas"
echo "3. Voltar para 1 replica"
echo "4. Teste de load balancing (10 requisições)"
echo "5. Teste intensivo (50 requisições)"
echo

read -p "Opção (1-5): " choice

case $choice in
    1)
        echo -e "${YELLOW}📈 Escalando para 3 replicas...${NC}"
        kubectl scale deployment nextjs-app --replicas=3 -n $NAMESPACE
        kubectl rollout status deployment/nextjs-app -n $NAMESPACE
        echo -e "${GREEN}✅ Escalonado para 3 replicas!${NC}"
        echo
        show_current_pods
        ;;
    2)
        echo -e "${YELLOW}📈 Escalando para 5 replicas...${NC}"
        kubectl scale deployment nextjs-app --replicas=5 -n $NAMESPACE
        kubectl rollout status deployment/nextjs-app -n $NAMESPACE
        echo -e "${GREEN}✅ Escalonado para 5 replicas!${NC}"
        echo
        show_current_pods
        ;;
    3)
        echo -e "${YELLOW}📉 Reduzindo para 1 replica...${NC}"
        kubectl scale deployment nextjs-app --replicas=1 -n $NAMESPACE
        kubectl rollout status deployment/nextjs-app -n $NAMESPACE
        echo -e "${GREEN}✅ Reduzido para 1 replica!${NC}"
        echo
        show_current_pods
        ;;
    4)
        echo -e "${CYAN}🧪 Verificando se port-forward está ativo...${NC}"
        if ! netstat -tuln | grep -q ":3000 "; then
            echo -e "${RED}❌ Port-forward não está ativo!${NC}"
            echo -e "${YELLOW}💡 Execute: ./scripts/setup-port-forward.sh${NC}"
            exit 1
        fi
        test_load_balancing 10
        ;;
    5)
        echo -e "${CYAN}🧪 Verificando se port-forward está ativo...${NC}"
        if ! netstat -tuln | grep -q ":3000 "; then
            echo -e "${RED}❌ Port-forward não está ativo!${NC}"
            echo -e "${YELLOW}💡 Execute: ./scripts/setup-port-forward.sh${NC}"
            exit 1
        fi
        echo -e "${YELLOW}⚠️ Teste intensivo - pode demorar...${NC}"
        test_load_balancing 50
        ;;
    *)
        echo -e "${RED}❌ Opção inválida!${NC}"
        exit 1
        ;;
esac

echo -e "${BLUE}🔄 Para ver o load balancing em ação:${NC}"
echo -e "${GREEN}   1. Escale para múltiplas replicas (opções 1 ou 2)${NC}"
echo -e "${GREEN}   2. Execute testes de carga (opções 4 ou 5)${NC}"
echo -e "${GREEN}   3. Observe diferentes Pod Names/IPs nas respostas${NC}"
echo