import type { NextConfig } from 'next';
const config: NextConfig = { poweredByHeader: false, experimental: { serverActions: { bodySizeLimit: '10mb' } } };
export default config;
