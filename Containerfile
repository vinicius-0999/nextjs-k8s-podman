# Containerfile para Podman - otimizado para WSL
FROM docker.io/library/node:18-alpine

WORKDIR /app

# Copiar arquivos de dependências
COPY package*.json ./

# Instalar dependências
RUN npm install

# Copiar código fonte
COPY . .

# Build da aplicação
RUN npm run build

# Configurar ambiente
ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# Expor porta
EXPOSE 3000

# Iniciar aplicação usando standalone
CMD ["node", ".next/standalone/server.js"]
