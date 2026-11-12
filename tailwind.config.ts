import type { Config } from 'tailwindcss';
export default { content: ['./app/**/*.{ts,tsx}','./components/**/*.{ts,tsx}'], theme: { extend: { colors: { ink:'#0b1020', panel:'#111a31', violet:'#8057f5', cyan:'#38bdf8' } } }, plugins: [] } satisfies Config;
