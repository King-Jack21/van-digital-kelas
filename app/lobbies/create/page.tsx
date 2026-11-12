import {requireRole} from '@/lib/auth';import {CreateLobbyForm} from '@/components/action-forms';
export default async function Page(){await requireRole(['teacher','owner']);return <main className="main-area"><section className="module-hero"><p className="eyebrow">COLLABORATION</p><h1>Buat Assignment Lobby</h1><p>Ruang tugas dengan undangan khusus dan pengumpulan privat.</p></section><section className="panel" style={{maxWidth:650}}><CreateLobbyForm/></section></main>}
        
