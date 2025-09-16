const http = require('http');
const os = require('os');

const PORT = process.env.SIDECAR_PORT || 8080;

// Função para obter IP real do pod
function getRealPodIP() {
  const networkInterfaces = os.networkInterfaces();
  
  // Priorizar POD_IP se definida
  if (process.env.POD_IP) {
    return process.env.POD_IP;
  }
  
  // Buscar IP real das interfaces de rede
  for (const [interfaceName, addresses] of Object.entries(networkInterfaces)) {
    if (addresses) {
      for (const addr of addresses) {
        // Pular interfaces internas e IPv6
        if (!addr.internal && addr.family === 'IPv4' && !addr.address.startsWith('127.')) {
          return addr.address;
        }
      }
    }
  }
  
  return '127.0.0.1';
}

// Função para obter todas as variáveis relevantes
function getPodInfo() {
  const now = new Date();
  
  return {
    // Informações básicas do pod
    podName: process.env.HOSTNAME || process.env.POD_NAME || os.hostname() || 'unknown-pod',
    podIP: getRealPodIP(),
    nodeName: process.env.NODE_NAME || 'unknown-node',
    namespace: process.env.POD_NAMESPACE || process.env.NAMESPACE || 'default',
    
    // Configurações da aplicação
    backgroundColor: process.env.BACKGROUND_COLOR || '#3498db',
    nodeEnv: process.env.NODE_ENV || 'development',
    
    // Informações do Kubernetes
    serviceAccount: process.env.SERVICE_ACCOUNT || 'default',
    kubernetesServiceHost: process.env.KUBERNETES_SERVICE_HOST || 'unknown',
    kubernetesServicePort: process.env.KUBERNETES_SERVICE_PORT || 'unknown',
    
    // Informações do sistema
    nodeVersion: process.version,
    platform: process.platform,
    arch: process.arch,
    cpus: os.cpus().length,
    totalMemory: `${Math.round(os.totalmem() / 1024 / 1024)} MB`,
    freeMemory: `${Math.round(os.freemem() / 1024 / 1024)} MB`,
    uptime: Math.round(process.uptime()),
    loadAverage: os.loadavg(),
    
    // Interfaces de rede
    networkInterfaces: Object.keys(os.networkInterfaces()),
    
    // Todas as variáveis de ambiente relacionadas ao Kubernetes
    k8sEnvVars: Object.keys(process.env)
      .filter(key => 
        key.startsWith('POD_') || 
        key.startsWith('NODE_') || 
        key.startsWith('KUBERNETES_') ||
        key.startsWith('SERVICE_') ||
        key === 'HOSTNAME' ||
        key === 'NAMESPACE'
      )
      .reduce((acc, key) => {
        acc[key] = process.env[key];
        return acc;
      }, {}),
    
    // Timestamp
    timestamp: now.toISOString(),
    timestampLocal: now.toLocaleString('pt-BR', { timeZone: 'America/Sao_Paulo' }),
    
    // Health check
    status: 'healthy',
    sidecarVersion: '1.0.0'
  };
}

// Função para logging
function log(message) {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${message}`);
}

// Criar servidor HTTP
const server = http.createServer((req, res) => {
  // Configurar CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Content-Type', 'application/json');
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }
  
  const url = new URL(req.url, `http://localhost:${PORT}`);
  
  try {
    // Rota principal - informações do pod
    if (url.pathname === '/pod-info' && req.method === 'GET') {
      const podInfo = getPodInfo();
      res.writeHead(200);
      res.end(JSON.stringify(podInfo, null, 2));
      log(`Pod info requested from ${req.connection.remoteAddress}`);
    }
    
    // Health check
    else if (url.pathname === '/health' && req.method === 'GET') {
      res.writeHead(200);
      res.end(JSON.stringify({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        service: 'pod-info-sidecar'
      }));
    }
    
    // Rota para variáveis específicas
    else if (url.pathname === '/env' && req.method === 'GET') {
      const envVar = url.searchParams.get('var');
      if (envVar) {
        res.writeHead(200);
        res.end(JSON.stringify({
          variable: envVar,
          value: process.env[envVar] || null,
          timestamp: new Date().toISOString()
        }));
      } else {
        res.writeHead(200);
        res.end(JSON.stringify({
          environment: process.env,
          timestamp: new Date().toISOString()
        }));
      }
    }
    
    // Rota 404
    else {
      res.writeHead(404);
      res.end(JSON.stringify({ 
        error: 'Not Found',
        availableRoutes: ['/pod-info', '/health', '/env'],
        timestamp: new Date().toISOString()
      }));
    }
  } catch (error) {
    log(`Error processing request: ${error.message}`);
    res.writeHead(500);
    res.end(JSON.stringify({ 
      error: 'Internal Server Error',
      message: error.message,
      timestamp: new Date().toISOString()
    }));
  }
});

// Iniciar servidor
server.listen(PORT, '0.0.0.0', () => {
  log(`🚀 Pod Info Sidecar running on port ${PORT}`);
  log(`📡 Available endpoints:`);
  log(`   GET /pod-info - Complete pod information`);
  log(`   GET /health   - Health check`);
  log(`   GET /env      - Environment variables`);
  log(`🔍 Pod Information:`);
  
  const info = getPodInfo();
  log(`   Pod Name: ${info.podName}`);
  log(`   Pod IP: ${info.podIP}`);
  log(`   Node: ${info.nodeName}`);
  log(`   Namespace: ${info.namespace}`);
  log(`   Background Color: ${info.backgroundColor}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  log('🛑 Received SIGTERM, shutting down gracefully');
  server.close(() => {
    log('✅ Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  log('🛑 Received SIGINT, shutting down gracefully');
  server.close(() => {
    log('✅ Server closed');
    process.exit(0);
  });
});

// Log startup environment
log('🔧 Environment variables:');
Object.keys(process.env)
  .filter(key => 
    key.startsWith('POD_') || 
    key.startsWith('NODE_') || 
    key.startsWith('KUBERNETES_') ||
    key === 'HOSTNAME' ||
    key === 'BACKGROUND_COLOR'
  )
  .forEach(key => {
    log(`   ${key}=${process.env[key]}`);
  });