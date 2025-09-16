# 🚀 Next.js Pod Info App

Uma aplicação Next.js que exibe informações do pod Kubernetes onde está sendo executada, construída com Podman e deployada em Kubernetes.

## 📋 Funcionalidades

- 🏷️ Exibe o nome do pod atual
- 🌐 Mostra o IP do pod dentro do cluster
- 🖥️ Apresenta o nome do nó onde o pod está rodando
- 📦 Indica o namespace do Kubernetes
- 🎨 Cor de fundo configurável via variável de ambiente
- 🐳 Otimizada para containers Podman
- ☸️ Pronta para deploy em Kubernetes

## 🛠️ Tecnologias Utilizadas

- **Next.js 14** - Framework React com App Router
- **TypeScript** - Tipagem estática
- **Podman** - Construção de containers
- **Kubernetes** - Orquestração de containers
- **Node.js 18** - Runtime JavaScript

## 📁 Estrutura do Projeto

```
nextjs-k8s-podman/
├── app/                    # Aplicação Next.js (App Router)
│   ├── globals.css        # Estilos globais
│   ├── layout.tsx         # Layout principal
│   └── page.tsx          # Página principal
├── k8s/                   # Manifests Kubernetes
│   ├── namespace.yaml     # Namespace da aplicação
│   ├── configmap.yaml     # Configurações (cor de fundo)
│   ├── deployment.yaml    # Deployment da aplicação
│   ├── service.yaml       # Serviço Kubernetes
│   └── ingress.yaml       # Ingress para acesso externo
├── scripts/               # Scripts de automação
│   ├── build.sh          # Build da imagem Podman
│   ├── deploy.sh         # Deploy no Kubernetes
│   ├── change-color.sh   # Alterar cor de fundo
│   └── cleanup.sh        # Limpeza dos recursos
├── Dockerfile            # Definição da imagem
├── next.config.js        # Configuração Next.js
├── package.json          # Dependências do projeto
└── README.md            # Este arquivo
```

## ✅ Projeto Atualizado - Build Funcionando!

### 🔧 Problemas Resolvidos

- ✅ **Compatibilidade Docker/Podman**: O projeto agora detecta automaticamente qual runtime usar
- ✅ **Build rootless**: Funciona em ambientes com restrições de permissão
- ✅ **Dockerfile otimizado**: Versão simples e funcional
- ✅ **Scripts universais**: Funcionam tanto com Docker quanto com Podman

### 🚀 Como Usar Agora

1. **Build da imagem** (funciona com Docker ou Podman):
   ```bash
   ./scripts/build.sh
   ```

2. **Teste local** com cores personalizadas:
   ```bash
   ./scripts/test-local.sh 3000 "#9b59b6"  # Roxo na porta 3000
   ```

3. **Deploy no Kubernetes**:
   ```bash
   ./scripts/deploy.sh
   ```

4. **Alterar cores no K8s**:
   ```bash
   ./scripts/change-color.sh
   ```

## 🚀 Início Rápido

### Pré-requisitos

- **Node.js 18+**
- **Podman** (alternativa ao Docker)
- **Kubernetes cluster** (minikube, k3s, etc.)
- **kubectl** configurado

### 1. Clone e Instale Dependências

```bash
cd nextjs-k8s-podman
npm install
```

### 2. Desenvolvimento Local

```bash
npm run dev
```

Acesse: http://localhost:3000

### 3. Build da Imagem

```bash
./scripts/build.sh
```

### 4. Deploy no Kubernetes

```bash
./scripts/deploy.sh
```

### 5. Acesse a Aplicação

```bash
# Port-forward para acesso local
kubectl port-forward svc/nextjs-service 8080:80 -n nextjs-app
```

Acesse: http://localhost:8080

## 🎨 Configuração de Cores

A aplicação suporta diferentes cores de fundo através da variável de ambiente `BACKGROUND_COLOR`.

### Alterar Cor via Script

```bash
./scripts/change-color.sh
```

### Alterar Cor Manualmente

```bash
# Editar o ConfigMap
kubectl edit configmap nextjs-config -n nextjs-app

# Reiniciar pods para aplicar
kubectl rollout restart deployment/nextjs-app -n nextjs-app
```

### Cores Pré-definidas

- 🔵 **Azul**: `#3498db`
- 🔴 **Vermelho**: `#e74c3c`
- 🟢 **Verde**: `#2ecc71`
- 🟠 **Laranja**: `#f39c12`
- 🟣 **Roxo**: `#9b59b6`
- 🔷 **Turquesa**: `#1abc9c`

## 📝 Variáveis de Ambiente

A aplicação utiliza as seguintes variáveis de ambiente do Kubernetes:

| Variável | Descrição | Origem |
|----------|-----------|---------|
| `HOSTNAME` | Nome do pod | Kubernetes |
| `POD_IP` | IP do pod | Kubernetes Downward API |
| `NODE_NAME` | Nome do nó | Kubernetes Downward API |
| `POD_NAMESPACE` | Namespace do pod | Kubernetes Downward API |
| `BACKGROUND_COLOR` | Cor de fundo | ConfigMap |

## 🛠️ Comandos Úteis

### Gerenciamento de Pods

```bash
# Listar pods
kubectl get pods -n nextjs-app

# Ver logs
kubectl logs -l app=nextjs-app -n nextjs-app --tail=100

# Escalar aplicação
kubectl scale deployment/nextjs-app --replicas=5 -n nextjs-app

# Ver detalhes do deployment
kubectl describe deployment nextjs-app -n nextjs-app
```

### Build e Push da Imagem

```bash
# Build automático (detecta Docker/Podman)
./scripts/build.sh

# Build universal com mais opções
./scripts/build-universal.sh

# Tag para registry remoto
docker tag localhost/nextjs-k8s-podman:latest registry.example.com/nextjs-k8s-podman:latest

# Push para registry
docker push registry.example.com/nextjs-k8s-podman:latest
```

### Dockerfiles Disponíveis

O projeto inclui diferentes versões do Dockerfile para diferentes necessidades:

- **`Dockerfile`**: Multi-stage otimizado (pode ter problemas em ambientes rootless)
- **`Dockerfile.simple`**: Versão simples e compatível (recomendado) ✅
- Os scripts usam automaticamente o `Dockerfile.simple` por compatibilidade

### Limpeza

```bash
# Remover todos os recursos
./scripts/cleanup.sh

# Ou manualmente
kubectl delete namespace nextjs-app
```

## 🔍 Troubleshooting

### Imagem não encontrada

Se o erro `ImagePullBackOff` aparecer:

1. Verifique se a imagem foi construída:
   ```bash
   podman images | grep nextjs-k8s-podman
   ```

2. Para clusters locais (minikube), carregue a imagem:
   ```bash
   minikube image load localhost/nextjs-k8s-podman:latest
   ```

3. Para outros clusters, faça push para um registry:
   ```bash
   podman push localhost/nextjs-k8s-podman:latest your-registry/nextjs-k8s-podman:latest
   ```

### Pods não iniciam

Verifique os eventos e logs:

```bash
# Ver eventos
kubectl get events -n nextjs-app --sort-by='.lastTimestamp'

# Ver logs dos pods
kubectl logs -l app=nextjs-app -n nextjs-app

# Descrever pods com problemas
kubectl describe pods -l app=nextjs-app -n nextjs-app
```

### Aplicação não responde

Verifique a conectividade:

```bash
# Testar conexão direta ao pod
kubectl port-forward deployment/nextjs-app 3000:3000 -n nextjs-app

# Verificar service
kubectl get svc -n nextjs-app

# Testar service internamente
kubectl run test-pod --image=curlimages/curl -i --tty --rm -- /bin/sh
# Dentro do pod: curl http://nextjs-service.nextjs-app.svc.cluster.local
```

## 🏗️ Arquitetura

### Multi-stage Build

O Dockerfile utiliza build multi-stage para otimizar o tamanho:

1. **deps**: Instala dependências
2. **builder**: Compila a aplicação
3. **runner**: Imagem final otimizada

### Kubernetes Resources

- **Namespace**: Isolamento dos recursos
- **ConfigMap**: Configurações da aplicação
- **Deployment**: 3 réplicas com health checks
- **Service**: Exposição interna na porta 80
- **Ingress**: Acesso externo (opcional)

### Health Checks

- **Liveness Probe**: Verifica se a aplicação está funcionando
- **Readiness Probe**: Verifica se está pronta para receber tráfego

## � Acesso via Windows

### Port-Forward com Load Balancing

O acesso do Windows é feito via port-forward no **Service** (não em pods específicos), garantindo load balancing automático:

```bash
# No WSL
./scripts/setup-port-forward.sh
```

**⚠️ IMPORTANTE**: Este método usa o Service do Kubernetes, distribuindo automaticamente as requisições entre todos os pods disponíveis. Se um pod falhar, o Service continua funcionando com os outros pods.

### Acesso Rápido (Windows)

Execute o arquivo batch para acesso direto:
```batch
# No Windows Explorer, execute:
scripts\windows-access.bat
```

### Testando Load Balancing

```bash
# Teste rápido de distribuição
./scripts/quick-test.sh

# Teste completo com relatório
./scripts/test-load-balancing.sh
```

### URLs de Acesso

- **Port-forward**: http://localhost:3000 (Windows + WSL)
- **Ingress**: http://nextjs-app.local (requer configuração hosts)

## �🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 🆘 Suporte

Se você encontrar problemas ou tiver dúvidas:

1. Verifique a seção [Troubleshooting](#-troubleshooting)
2. Consulte os logs da aplicação
3. Abra uma issue no GitHub

---

**Desenvolvido com ❤️ usando Next.js, Podman e Kubernetes**