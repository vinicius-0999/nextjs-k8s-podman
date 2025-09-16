#!/bin/bash

# Script Rápido para Teste de Load Balancing
# Salva HTMLs de múltiplas requisições para análise

echo "🧪 Teste Rápido de Load Balancing"
echo

# Criar diretório
mkdir -p /tmp/nextjs-test
cd /tmp/nextjs-test

echo "📁 Salvando arquivos em: /tmp/nextjs-test"
echo

# Função para testar e extrair info
test_and_extract() {
    local url="$1"
    local filename="$2"
    
    echo -n "Requisição $filename: "
    
    if curl -s "$url" > "${filename}.html" 2>/dev/null; then
        # Extrair nome do pod
        local pod_name=$(grep -o 'Nome do Pod:</span><div class="info-value">[^<]*' "${filename}.html" | sed 's/.*>//' || echo "N/A")
        local pod_ip=$(grep -o 'IP do Pod:</span><div class="info-value">[^<]*' "${filename}.html" | sed 's/.*>//' || echo "N/A")
        
        if [[ "$pod_name" != "N/A" ]]; then
            echo "✅ Pod: $pod_name (IP: $pod_ip)"
            echo "$filename -> $pod_name ($pod_ip)" >> summary.txt
        else
            echo "✅ HTML salvo (sem info do pod)"
            echo "$filename -> Sucesso (sem info)" >> summary.txt
        fi
    else
        echo "❌ Falha"
        echo "$filename -> ERRO" >> summary.txt
    fi
}

# Menu
echo "Escolha o teste:"
echo "1. Port-forward (localhost:3000)"
echo "2. Ingress (nextjs-app.local)" 
echo "3. Ambos"
echo
read -p "Opção (1-3): " choice

echo "=== TESTE INICIADO $(date) ===" > summary.txt
echo >> summary.txt

case $choice in
    1)
        echo "🔗 Testando Port-forward..."
        echo "URL: http://localhost:3000" >> summary.txt
        echo >> summary.txt
        
        for i in {1..10}; do
            test_and_extract "http://localhost:3000" "portforward_req$i"
            sleep 1
        done
        ;;
    2)
        echo "🌐 Testando Ingress..."
        echo "URL: http://nextjs-app.local" >> summary.txt
        echo >> summary.txt
        
        for i in {1..10}; do
            test_and_extract "http://nextjs-app.local" "ingress_req$i"
            sleep 1
        done
        ;;
    3)
        echo "🔗 Testando Port-forward..."
        echo "=== PORT-FORWARD ===" >> summary.txt
        echo "URL: http://localhost:3000" >> summary.txt
        echo >> summary.txt
        
        for i in {1..5}; do
            test_and_extract "http://localhost:3000" "portforward_req$i"
            sleep 1
        done
        
        echo
        echo "🌐 Testando Ingress..."
        echo >> summary.txt
        echo "=== INGRESS ===" >> summary.txt
        echo "URL: http://nextjs-app.local" >> summary.txt
        echo >> summary.txt
        
        for i in {1..5}; do
            test_and_extract "http://nextjs-app.local" "ingress_req$i"
            sleep 1
        done
        ;;
esac

echo
echo "🎉 Teste concluído!"
echo
echo "📊 Resumo:"
cat summary.txt | grep -E "req.*->" | sort | uniq -c | sort -nr

echo
echo "📁 Arquivos salvos em: /tmp/nextjs-test"
echo "📋 Resumo completo: /tmp/nextjs-test/summary.txt"
echo
echo "💡 Para visualizar os HTMLs:"
echo "ls -la /tmp/nextjs-test/*.html"
echo
echo "🌐 Para abrir um HTML específico:"
echo "firefox /tmp/nextjs-test/portforward_req1.html"