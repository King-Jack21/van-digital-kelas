import { ModulePage } from '@/components/module-page';
import { getUserContext } from '@/lib/auth';
import { redirect } from 'next/navigation';
export default async function Page(){const {user}=await getUserContext();if(!user)redirect('/login');return <ModulePage title="Detail" description="Kelola aktivitas pembelajaran, kolaborasi, dan administrasi dalam satu ruang kerja." links={[{label:'Dashboard',href:'/dashboard'},{label:'Kelas',href:'/classes'},{label:'Assignment Lobby',href:'/lobbies'}]}/>;}
