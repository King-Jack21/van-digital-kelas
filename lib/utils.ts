import { clsx, type ClassValue } from 'clsx';
export function cn(...v: ClassValue[]) { return clsx(v); }
export function initials(name: string) { return name.split(' ').map(x => x[0]).slice(0,2).join('').toUpperCase(); }
