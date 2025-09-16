@echo off
title NextJS App - Acesso Windows

echo.
echo ==========================================
echo   NEXTJS APP - ACESSO VIA WINDOWS
echo ==========================================
echo.

echo IMPORTANTE:
echo   - Este acesso usa LOAD BALANCING via Service
echo   - Requisicoes sao distribuidas entre todos os pods
echo   - Se um pod falhar, outros continuam funcionando
echo.

REM Verificar se o port-forward está ativo
echo Verificando conectividade...

curl -s -o nul -w "%%{http_code}" --connect-timeout 3 http://localhost:3000 > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✅ Conectividade OK - Abrindo navegador...
    echo.
    echo 🔄 Load Balancing ativo via Service Kubernetes
    echo 📊 Para testar distribuicao: F5 multiplas vezes no navegador
    echo.
    start http://localhost:3000
    goto :end
)

REM Se localhost não funcionar, mostrar instruções
echo ❌ Aplicacao nao acessivel em localhost:3000
echo.
echo SOLUCOES:
echo.
echo 1. No WSL, execute:
echo    cd /home/vini-lnx/inst/projeto_sabia/nextjs-k8s-podman
echo    ./scripts/setup-port-forward.sh
echo.
echo 2. Aguarde a mensagem "Port-forward ativo via SERVICE"
echo.
echo 3. Execute este script novamente
echo.
echo 📋 NOTA: O port-forward usa SERVICE, nao pods especificos
echo    Isso garante load balancing automatico!
echo.

:end
echo.
echo Pressione qualquer tecla para sair...
pause > nul