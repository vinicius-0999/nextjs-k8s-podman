// Força a página ser dinâmica (server-side rendering em cada request)
export const dynamic = 'force-dynamic';
export const revalidate = 0;

interface PodInfo {
  podName: string;
  podIP: string;
  nodeName: string;
  namespace: string;
  backgroundColor: string;
  nodeVersion: string;
  platform: string;
  arch: string;
  timestamp: string;
  status: string;
  k8sEnvVars: Record<string, string>;
}

// Função para buscar dados do sidecar usando HTTP nativo (força IPv4)
async function getPodInfoFromSidecar(): Promise<PodInfo> {
  const sidecarUrl = process.env.SIDECAR_URL || 'http://127.0.0.1:8080';
  
  try {
    console.log(`🔍 Fetching pod info from sidecar: ${sidecarUrl}/pod-info`);
    
    // Usar http nativo para forçar IPv4 ao invés de fetch
    const http = require('http');
    const url = new URL(`${sidecarUrl}/pod-info`);
    
    const data = await new Promise<any>((resolve, reject) => {
      const options = {
        hostname: '127.0.0.1', // Força IPv4
        port: 8080,
        path: '/pod-info',
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'NextJS-PodInfo/1.0'
        },
        timeout: 5000
      };
      
      const req = http.request(options, (res: any) => {
        let responseData = '';
        res.on('data', (chunk: any) => responseData += chunk);
        res.on('end', () => {
          if (res.statusCode === 200) {
            resolve(JSON.parse(responseData));
          } else {
            reject(new Error(`Sidecar response: ${res.statusCode}`));
          }
        });
      });
      
      req.on('error', reject);
      req.on('timeout', () => reject(new Error('Timeout')));
      req.end();
    });
    
    console.log('✅ Sidecar data received successfully');
    
    return {
      podName: data.podName || 'unknown',
      podIP: data.podIP || 'unknown',
      nodeName: data.nodeName || 'unknown',
      namespace: data.namespace || 'unknown',
      backgroundColor: data.backgroundColor || '#3498db',
      nodeVersion: data.nodeVersion || 'unknown',
      platform: data.platform || 'unknown',
      arch: data.arch || 'unknown',
      timestamp: data.timestamp || new Date().toISOString(),
      status: data.status || 'unknown',
      k8sEnvVars: data.k8sEnvVars || {}
    };
  } catch (error) {
    console.error('❌ Error fetching from sidecar:', error);
    
    // Fallback para variáveis de ambiente diretas (caso o sidecar não esteja disponível)
    return {
      podName: process.env.HOSTNAME || process.env.POD_NAME || 'fallback-pod',
      podIP: process.env.POD_IP || 'fallback-ip',
      nodeName: process.env.NODE_NAME || 'fallback-node',
      namespace: process.env.POD_NAMESPACE || 'fallback-namespace',
      backgroundColor: '#ff6b6b', // Vermelho claro para indicar fallback
      nodeVersion: process.version,
      platform: process.platform,
      arch: process.arch,
      timestamp: new Date().toISOString(),
      status: 'fallback-mode',
      k8sEnvVars: {
        'ERROR': 'Sidecar não acessível - usando fallback',
        'SIDECAR_URL': sidecarUrl,
        'ERROR_DETAILS': error instanceof Error ? error.message : 'Unknown error',
        'HOSTNAME': process.env.HOSTNAME || 'N/A',
        'POD_IP': process.env.POD_IP || 'N/A',
        'NODE_NAME': process.env.NODE_NAME || 'N/A'
      }
    };
  }
}

export default async function Home() {
  const podInfo = await getPodInfoFromSidecar();

  return (
    <div 
      className="container" 
      style={{ backgroundColor: podInfo.backgroundColor }}
    >
      <div className="card">
        <h1 className="title">🚀 Pod Info</h1>
        <p className="subtitle">
          {podInfo.status === 'fallback-mode' 
            ? '⚠️ Aplicação Next.js (Modo Fallback)' 
            : '✅ Aplicação Next.js + Sidecar'
          }
        </p>
        
        <div className="info-grid">
          <div className="info-item">
            <span className="info-label">Nome do Pod:</span>
            <div className="info-value">{podInfo.podName}</div>
          </div>
          
          <div className="info-item">
            <span className="info-label">IP do Pod:</span>
            <div className="info-value">{podInfo.podIP}</div>
          </div>
          
          <div className="info-item">
            <span className="info-label">Nome do Nó:</span>
            <div className="info-value">{podInfo.nodeName}</div>
          </div>
          
          <div className="info-item">
            <span className="info-label">Namespace:</span>
            <div className="info-value">{podInfo.namespace}</div>
          </div>
          
          <div className="info-item">
            <span className="info-label">Cor de Fundo:</span>
            <div className="info-value">{podInfo.backgroundColor}</div>
          </div>
          
          <div className="info-item">
            <span className="info-label">Node.js Version:</span>
            <div className="info-value">{podInfo.nodeVersion}</div>
          </div>
          
          <div className="info-item">
            <span className="info-label">Plataforma:</span>
            <div className="info-value">{podInfo.platform} ({podInfo.arch})</div>
          </div>
          
          <div className="info-item">
            <span className="info-label">Status:</span>
            <div className="info-value">
              {podInfo.status === 'healthy' && '🟢 Sidecar Ativo'}
              {podInfo.status === 'fallback-mode' && '🟡 Modo Fallback'}
              {podInfo.status === 'unknown' && '🔴 Status Desconhecido'}
            </div>
          </div>
        </div>

        {/* Variáveis de Ambiente do Kubernetes */}
        <div style={{ marginTop: '2rem' }}>
          <h3 style={{ marginBottom: '1rem', color: '#2c3e50' }}>
            🔧 Variáveis de Ambiente do Kubernetes
          </h3>
          <div style={{ 
            background: '#f8f9fa', 
            padding: '1rem', 
            borderRadius: '8px',
            maxHeight: '300px',
            overflowY: 'auto'
          }}>
            {Object.keys(podInfo.k8sEnvVars).length > 0 ? (
              Object.entries(podInfo.k8sEnvVars).map(([key, value]) => (
                <div key={key} style={{ 
                  padding: '0.5rem 0', 
                  borderBottom: '1px solid #eee',
                  fontFamily: 'monospace',
                  fontSize: '0.9rem'
                }}>
                  <strong style={{ color: '#2c3e50' }}>{key}:</strong>{' '}
                  <span style={{ color: '#7f8c8d' }}>{value || 'N/A'}</span>
                </div>
              ))
            ) : (
              <p style={{ color: '#7f8c8d', fontStyle: 'italic' }}>
                Nenhuma variável de ambiente encontrada
              </p>
            )}
          </div>
        </div>

        <div className="footer">
          <p>
            {podInfo.status === 'healthy' 
              ? '🐳 Rodando com sidecar Podman' 
              : '⚠️ Rodando em modo fallback'
            }
          </p>
          <p>☸️ Deploy via Kubernetes (Multi-Container Pod)</p>
          <p>Última atualização: {new Date(podInfo.timestamp).toLocaleString('pt-BR')}</p>
          {podInfo.status === 'fallback-mode' && (
            <p style={{ color: '#e74c3c', fontSize: '0.8rem', marginTop: '0.5rem' }}>
              ⚠️ Sidecar não disponível - dados obtidos via fallback
            </p>
          )}
        </div>
      </div>
    </div>
  );
}