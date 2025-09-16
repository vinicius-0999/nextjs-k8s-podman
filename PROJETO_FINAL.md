# 🚀 Next.js + Kubernetes + Sidecar - Projeto Final

## 📁 Estrutura do Projeto Limpo

```
projeto_sabia/nextjs-k8s-podman/
├── 📦 Aplicação Principal
│   ├── app/
│   │   ├── globals.css              # Estilos globais
│   │   ├── layout.tsx               # Layout do Next.js
│   │   ├── page.tsx                 # Página principal com sidecar integration
│   │   └── api/route.ts             # API endpoint (opcional)
│   ├── package.json                 # Dependencies do Next.js
│   ├── next.config.js               # Configuração do Next.js
│   ├── tsconfig.json                # Configuração TypeScript
│   └── Containerfile                # Container Next.js
│
├── 🔧 Sidecar Service
│   ├── server.js                    # Servidor HTTP do sidecar
│   ├── package.json                 # Dependencies do sidecar
│   └── Containerfile                # Container sidecar
│
├── ☸️ Kubernetes Manifests
│   ├── namespace.yaml               # Namespace nextjs-app
│   ├── configmap.yaml               # Configurações (cores, etc.)
│   ├── deployment-multi.yaml        # Deployment multi-container
│   ├── service.yaml                 # Service ClusterIP
│   ├── ingress.yaml                 # Ingress para acesso externo
│   └── debug-pod.yaml               # Pod para debug (opcional)
│
├── 🛠️ Scripts de Automação
│   ├── build-all.sh                 # Build de ambos os containers
│   ├── deploy.sh                    # Deploy completo com rollout
│   ├── setup-host.sh                # Configuração do host local
│   ├── change-color.sh              # Mudança de cor via ConfigMap
│   ├── cleanup.sh                   # Limpeza do ambiente
│   └── test-local.sh                # Teste local dos containers
│
└── 📖 Documentação
    ├── README.md                    # Documentação principal
    └── IMPROVEMENTS.md              # Melhorias implementadas
```

## ✅ Funcionalidades Implementadas

### 🌐 **Acesso via Ingress**
- **URL**: http://nextjs-app.local
- **Host configurado**: 192.168.49.2 → nextjs-app.local
- **Nginx Ingress Controller**: Habilitado no Minikube

### 🎨 **Configuração Dinâmica**
- **Cor de fundo**: Configurável via ConfigMap
- **Rollout automático**: Scripts incluem restart deployment
- **Mudança em tempo real**: `./scripts/change-color.sh <cor>`

### 🐳 **Arquitetura Multi-Container**
- **Container 1**: Next.js App (porta 3000)
- **Container 2**: Sidecar Service (porta 8080)
- **Comunicação**: localhost entre containers no mesmo pod

### ☸️ **Deploy Automatizado**
- **Build**: `./scripts/build-all.sh`
- **Deploy**: `./scripts/deploy.sh` (inclui rollout restart)
- **Host Setup**: `./scripts/setup-host.sh`

## 🎯 Como Usar

### 1. **Deploy Completo**
```bash
# Fazer deploy completo (build + deploy + rollout)
./scripts/deploy.sh

# Configurar host local para acesso via ingress
./scripts/setup-host.sh
```

### 2. **Acessar a Aplicação**
```bash
# Via navegador
open http://nextjs-app.local

# Via curl
curl http://nextjs-app.local
```

### 3. **Mudar Configurações**
```bash
# Mudar cor de fundo
./scripts/change-color.sh "#3498db"  # Azul
./scripts/change-color.sh "#2ecc71"  # Verde
./scripts/change-color.sh "#e74c3c"  # Vermelho
```

### 4. **Monitoramento**
```bash
# Ver pods
kubectl get pods -n nextjs-app

# Ver logs do sidecar
kubectl logs <pod-name> -n nextjs-app -c pod-info-sidecar

# Ver logs do next.js
kubectl logs <pod-name> -n nextjs-app -c nextjs-app
```

### 5. **Limpeza**
```bash
# Remover todo o deploy
./scripts/cleanup.sh
```

## 🌐 **Mapeamento de Host Configurado**

Adicionado ao `/etc/hosts`:
```
192.168.49.2  nextjs-app.local
```

**Para acessar**: http://nextjs-app.local

## 🎉 **Resultado Final**

✅ **Aplicação Multi-Container Funcionando**  
✅ **Sidecar coletando variáveis do Kubernetes**  
✅ **Interface responsiva com cores configuráveis**  
✅ **Deploy automatizado com rollout**  
✅ **Acesso via Ingress configurado**  
✅ **Scripts de automação completos**  

A aplicação está **100% funcional** e pronta para uso em produção! 🚀