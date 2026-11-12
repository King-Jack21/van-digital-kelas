import { redirect } from 'next/navigation';
import { getUserContext } from '@/lib/auth';
export default async function Home(){const {user}=await getUserContext();redirect(user?'/dashboard':'/login');}
