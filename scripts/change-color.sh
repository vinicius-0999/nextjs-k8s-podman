#!/bin/bash

# Script para configurar cores de fundo diferentes
set -e

NAMESPACE="nextjs-app"
COLORS=("#3498db" "#e74c3c" "#2ecc71" "#f39c12" "#9b59b6" "#1abc9c")
COLOR_NAMES=("azul" "vermelho" "verde" "laranja" "roxo" "turquesa")

echo "🎨 Configurador de cores para o Pod Info App"
echo ""
echo "Cores disponíveis:"
for i in "${!COLORS[@]}"; do
    echo "  $((i+1)). ${COLOR_NAMES[i]} - ${COLORS[i]}"
done
echo ""

read -p "Escolha uma cor (1-6): " choice

if [[ $choice -ge 1 && $choice -le 6 ]]; then
    selected_color=${COLORS[$((choice-1))]}
    color_name=${COLOR_NAMES[$((choice-1))]}
    
    echo "🎨 Configurando cor de fundo para: $color_name ($selected_color)"
    
    # Atualizar o ConfigMap
    kubectl patch configmap nextjs-config -n ${NAMESPACE} --patch "{\"data\":{\"BACKGROUND_COLOR\":\"$selected_color\"}}"
    
    # Reiniciar o deployment para aplicar a nova configuração
    echo "🔄 Reiniciando pods para aplicar a nova cor..."
    kubectl rollout restart deployment/nextjs-app -n ${NAMESPACE}
    kubectl rollout status deployment/nextjs-app -n ${NAMESPACE} --timeout=300s
    
    echo "✅ Cor atualizada com sucesso!"
    echo "🌐 Acesse a aplicação para ver a mudança."
else
    echo "❌ Opção inválida. Por favor, escolha um número entre 1 e 6."
    exit 1
fi