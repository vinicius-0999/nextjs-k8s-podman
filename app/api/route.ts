import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({
    podName: process.env.POD_NAME,
    podIP: process.env.POD_IP,
    namespace: process.env.POD_NAMESPACE,
    nodeName: process.env.NODE_NAME,
    allEnv: Object.keys(process.env), // só para inspeção
  });
}
