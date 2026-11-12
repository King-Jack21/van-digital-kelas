import type { Metadata } from 'next';
import './globals.css';
import { Sidebar } from '@/components/sidebar';
import { getUserContext } from '@/lib/auth';
export const metadata:Metadata={title:'VAN Classroom — Learn · Manage · Grow',description:'A focused learning management workspace.'};
export default async function RootLayout({children}:{children:React.ReactNode}){const {profile}=await getUserContext();return <html lang="id" data-theme="dark"><body>{profile&&<Sidebar name={profile.full_name} role={profile.role} />}{children}</body></html>}
