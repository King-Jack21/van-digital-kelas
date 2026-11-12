'use server';
import { z } from 'zod';
import { randomBytes,createHash } from 'crypto';
import { requireRole } from '@/lib/auth';
import { revalidatePath } from 'next/cache';
const lobbySchema=z.object({title:z.string().min(3).max(100),description:z.string().max(2000).optional(),capacity:z.coerce.number().int().positive().max(10000).optional()});
export async function createLobby(formData:FormData) {
 const ctx=await requireRole(['teacher','owner']); const p=lobbySchema.safeParse(Object.fromEntries(formData)); if(!p.success) return {error:'Periksa judul dan kapasitas lobby.'};
 const {data:lobby,error}=await ctx.supabase.from('assignment_lobbies').insert({title:p.data.title,description:p.data.description||'',capacity:p.data.capacity||null,teacher_id:ctx.user.id}).select('id').single(); if(error||!lobby) return {error:'Lobby gagal dibuat.'};
 const code=randomBytes(6).toString('hex').toUpperCase(); const code_hash=createHash('sha256').update(code).digest('hex'); const {error:inviteError}=await ctx.supabase.from('lobby_invite_codes').insert({lobby_id:lobby.id,code_hash});
 if(inviteError) return {error:'Lobby dibuat, tetapi kode undangan gagal dibuat. Buat ulang dari pengaturan.'}; revalidatePath('/lobbies'); return {success:true,code,lobbyId:lobby.id};
}
export async function joinLobby(formData:FormData) {
 const ctx=await requireRole(['student']); const code=String(formData.get('code')||'').trim().toUpperCase(); if(!/^[A-F0-9]{12}$/.test(code)) return {error:'Format kode tidak valid.'};
 const {data,error}=await ctx.supabase.rpc('join_lobby_by_code',{p_code:code});
 if(error) return {error:'Tidak dapat bergabung. Periksa kode, kapasitas, dan status pendaftaran.'};
 if(data?.status==='pending') return {success:true}; return {success:true};
}
