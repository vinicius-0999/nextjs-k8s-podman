#!/bin/bash

# Script para limpeza de arquivos obsoletos do Windows
set -e

echo "🧹 Limpando arquivos obsoletos do Windows..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Array de arquivos obsoletos para remover
OBSOLETE_FILES=(
    "acesso-windows.bat"
    "teste-conectividade-windows.ps1"
    "scripts/open-windows.bat"
    "scripts/setup-windows-access.sh"
    "scripts/test-windows-access.ps1"
)

echo -e "${YELLOW}📋 Arquivos que serão removidos (se existirem):${NC}"
for file in "${OBSOLETE_FILES[@]}"; do
    echo "   • $file"
done
echo

# Remover arquivos obsoletos
removed_count=0
for file in "${OBSOLETE_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${YELLOW}🗑️  Removendo: $file${NC}"
        rm -f "$file"
        ((removed_count++))
    fi
done

echo
if [ $removed_count -gt 0 ]; then
    echo -e "${GREEN}✅ $removed_count arquivo(s) obsoleto(s) removido(s)${NC}"
else
    echo -e "${GREEN}✅ Nenhum arquivo obsoleto encontrado${NC}"
fi

echo
echo -e "${GREEN}🎯 Arquivos funcionais mantidos:${NC}"
echo -e "${GREEN}   • scripts/setup-port-forward.sh (port-forward via Service)${NC}"
echo -e "${GREEN}   • scripts/windows-access.bat (acesso Windows)${NC}"
echo -e "${GREEN}   • scripts/quick-test.sh (teste load balancing)${NC}"
echo -e "${GREEN}   • scripts/test-load-balancing.sh (teste completo)${NC}"

echo
echo -e "${YELLOW}💡 Para acessar do Windows:${NC}"
echo -e "${GREEN}   1. Execute: ./scripts/setup-port-forward.sh (no WSL)${NC}"
echo -e "${GREEN}   2. Execute: scripts\\windows-access.bat (no Windows)${NC}"

echo -e "${YELLOW}⚠️  IMPORTANTE: O setup-port-forward usa SERVICE (load balancing)${NC}"
echo