#!/bin/bash

# Script para testar load balancing e salvar HTMLs
# Faz múltiplas requisições e salva as respostas para análise

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configurações
NAMESPACE="nextjs-app"
OUTPUT_DIR="/tmp/nextjs-tests"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Criar diretório de saída
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}🧪 Script de Teste de Load Balancing${NC}"
echo -e "${YELLOW}📁 Salvando resultados em: $OUTPUT_DIR${NC}"
echo

# Função para extrair informações do HTML
extract_pod_info() {
    local html_file="$1"
    local pod_name=$(grep -o 'Nome do Pod:</span><div class="info-value">[^<]*' "$html_file" | sed 's/.*>//' || echo "N/A")
    local pod_ip=$(grep -o 'IP do Pod:</span><div class="info-value">[^<]*' "$html_file" | sed 's/.*>//' || echo "N/A")
    echo "$pod_name|$pod_ip"
}

# Função para testar uma URL
test_url() {
    local url="$1"
    local test_name="$2"
    local num_requests="$3"
    
    echo -e "${CYAN}🔍 Testando: $test_name${NC}"
    echo -e "${BLUE}URL: $url${NC}"
    echo
    
    local summary_file="$OUTPUT_DIR/${test_name}_summary_${TIMESTAMP}.txt"
    
    echo "=== RESUMO DO TESTE: $test_name ===" > "$summary_file"
    echo "URL: $url" >> "$summary_file"
    echo "Data: $(date)" >> "$summary_file"
    echo "Número de requisições: $num_requests" >> "$summary_file"
    echo >> "$summary_file"
    
    declare -A pod_count
    
    for i in $(seq 1 $num_requests); do
        local output_file="$OUTPUT_DIR/${test_name}_req${i}_${TIMESTAMP}.html"
        
        echo -n "Requisição $i/$num_requests: "
        
        if curl -s -m 10 -H "User-Agent: LoadBalancer-Test" "$url" > "$output_file" 2>/dev/null; then
            # Extrair informações do pod
            local pod_info=$(extract_pod_info "$output_file")
            local pod_name=$(echo "$pod_info" | cut -d'|' -f1)
            local pod_ip=$(echo "$pod_info" | cut -d'|' -f2)
            
            if [[ "$pod_name" != "N/A" ]]; then
                echo -e "${GREEN}✅ Pod: $pod_name (IP: $pod_ip)${NC}"
                pod_count["$pod_name"]=$((${pod_count["$pod_name"]} + 1))
                echo "Requisição $i: $pod_name ($pod_ip)" >> "$summary_file"
            else
                echo -e "${YELLOW}⚠️ HTML salvo, mas não foi possível extrair info do pod${NC}"
                echo "Requisição $i: Sucesso, mas sem info do pod" >> "$summary_file"
            fi
        else
            echo -e "${RED}❌ Falha na conexão${NC}"
            echo "Requisição $i: FALHA" >> "$summary_file"
            echo "Erro na conexão" > "$output_file"
        fi
        
        sleep 1
    done
    
    echo >> "$summary_file"
    echo "=== DISTRIBUIÇÃO DE PODS ===" >> "$summary_file"
    for pod in "${!pod_count[@]}"; do
        echo "$pod: ${pod_count[$pod]} requisições" >> "$summary_file"
    done
    
    echo
    echo -e "${YELLOW}📊 Resumo do teste:${NC}"
    for pod in "${!pod_count[@]}"; do
        echo -e "  ${GREEN}$pod: ${pod_count[$pod]} requisições${NC}"
    done
    
    echo -e "${BLUE}📁 Arquivos salvos: $OUTPUT_DIR/${test_name}_*${NC}"
    echo
}

# Função para gerar relatório HTML
generate_html_report() {
    local report_file="$OUTPUT_DIR/report_${TIMESTAMP}.html"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Relatório de Load Balancing - NextJS K8s</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }
        .header { text-align: center; color: #2c3e50; margin-bottom: 30px; }
        .test-section { margin-bottom: 30px; padding: 20px; border: 1px solid #ddd; border-radius: 8px; }
        .test-title { color: #3498db; font-size: 1.5em; margin-bottom: 10px; }
        .file-list { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 10px; margin-top: 15px; }
        .file-item { padding: 10px; background: #ecf0f1; border-radius: 5px; }
        .file-item a { text-decoration: none; color: #2980b9; font-weight: bold; }
        .file-item a:hover { color: #1abc9c; }
        .summary { background: #e8f5e8; padding: 15px; border-radius: 5px; margin-top: 10px; }
        .timestamp { color: #7f8c8d; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧪 Relatório de Load Balancing</h1>
            <p class="timestamp">Gerado em: $(date)</p>
        </div>
EOF

    # Adicionar seções para cada teste
    for test_type in "port-forward" "ingress" "service-ip"; do
        if ls "$OUTPUT_DIR"/${test_type}_* >/dev/null 2>&1; then
            echo "        <div class=\"test-section\">" >> "$report_file"
            echo "            <h2 class=\"test-title\">📊 Teste: $test_type</h2>" >> "$report_file"
            
            # Adicionar summary se existir
            if [[ -f "$OUTPUT_DIR/${test_type}_summary_${TIMESTAMP}.txt" ]]; then
                echo "            <div class=\"summary\">" >> "$report_file"
                echo "                <h3>Resumo:</h3>" >> "$report_file"
                echo "                <pre>$(cat "$OUTPUT_DIR/${test_type}_summary_${TIMESTAMP}.txt")</pre>" >> "$report_file"
                echo "            </div>" >> "$report_file"
            fi
            
            # Listar arquivos HTML
            echo "            <h3>Arquivos HTML:</h3>" >> "$report_file"
            echo "            <div class=\"file-list\">" >> "$report_file"
            
            for file in "$OUTPUT_DIR"/${test_type}_req*_${TIMESTAMP}.html; do
                if [[ -f "$file" ]]; then
                    local filename=$(basename "$file")
                    echo "                <div class=\"file-item\">" >> "$report_file"
                    echo "                    <a href=\"$filename\" target=\"_blank\">$filename</a>" >> "$report_file"
                    echo "                </div>" >> "$report_file"
                fi
            done
            
            echo "            </div>" >> "$report_file"
            echo "        </div>" >> "$report_file"
        fi
    done

    cat >> "$report_file" << EOF
        <div style="text-align: center; margin-top: 30px; color: #7f8c8d;">
            <p>Relatório gerado automaticamente pelo script de teste de Load Balancing</p>
        </div>
    </div>
</body>
</html>
EOF

    echo -e "${GREEN}📋 Relatório HTML gerado: $report_file${NC}"
}

# Menu de opções
show_menu() {
    echo -e "${BLUE}Escolha o tipo de teste:${NC}"
    echo "1. Port-forward (localhost:3000) - 10 requisições"
    echo "2. Ingress (nextjs-app.local) - 10 requisições"
    echo "3. IP direto do Minikube - 10 requisições"
    echo "4. Teste completo (todos os métodos) - 5 req cada"
    echo "5. Teste intensivo (port-forward) - 25 requisições"
    echo
}

# Verificar se port-forward está ativo
check_port_forward_active() {
    if netstat -tuln | grep -q ":3000 "; then
        return 0
    else
        return 1
    fi
}

# Main
main() {
    show_menu
    read -p "Opção (1-5): " choice
    
    case $choice in
        1)
            if ! check_port_forward_active; then
                echo -e "${RED}❌ Port-forward não está ativo!${NC}"
                echo -e "${YELLOW}💡 Execute: /home/vini-lnx/inst/projeto_sabia/nextjs-k8s-podman/scripts/setup-port-forward.sh${NC}"
                exit 1
            fi
            test_url "http://localhost:3000" "port-forward" 10
            ;;
        2)
            test_url "http://nextjs-app.local" "ingress" 10
            ;;
        3)
            MINIKUBE_IP=$(minikube ip)
            test_url "http://$MINIKUBE_IP" "service-ip" 10
            ;;
        4)
            if check_port_forward_active; then
                test_url "http://localhost:3000" "port-forward" 5
            fi
            test_url "http://nextjs-app.local" "ingress" 5
            MINIKUBE_IP=$(minikube ip)
            test_url "http://$MINIKUBE_IP" "service-ip" 5
            ;;
        5)
            if ! check_port_forward_active; then
                echo -e "${RED}❌ Port-forward não está ativo!${NC}"
                echo -e "${YELLOW}💡 Execute: /home/vini-lnx/inst/projeto_sabia/nextjs-k8s-podman/scripts/setup-port-forward.sh${NC}"
                exit 1
            fi
            test_url "http://localhost:3000" "port-forward" 25
            ;;
        *)
            echo -e "${RED}❌ Opção inválida!${NC}"
            exit 1
            ;;
    esac
    
    # Gerar relatório
    generate_html_report
    
    echo -e "${CYAN}🎉 Teste concluído!${NC}"
    echo -e "${YELLOW}📁 Todos os arquivos estão em: $OUTPUT_DIR${NC}"
    echo -e "${GREEN}🌐 Abra o relatório HTML no navegador: file://$OUTPUT_DIR/report_${TIMESTAMP}.html${NC}"
    
    # Mostrar comando para limpar
    echo
    echo -e "${BLUE}💡 Para limpar os arquivos de teste:${NC}"
    echo "rm -rf $OUTPUT_DIR"
}

main "$@"