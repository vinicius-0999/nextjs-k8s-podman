import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Pod Info App',
  description: 'Aplicação Next.js rodando em Kubernetes',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="pt-BR">
      <body>{children}</body>
    </html>
  )
}