'use server';
import { z } from 'zod';
import { createClient } from '@/lib/supabase/server';
import { requireRole } from '@/lib/auth';
import { revalidatePath } from 'next/cache';
const classSchema=z.object({name:z.string().min(3).max(80),subject:z.string().max(80).optional(),description:z.string().max(1000).optional()});
export async function createClass(formData:FormData) {
 const ctx=await requireRole(['teacher','owner']); const parsed=classSchema.safeParse(Object.fromEntries(formData)); if(!parsed.success) return {error:'Nama kelas minimal 3 karakter.'};
 const {error}=await ctx.supabase.from('classes').insert({...parsed.data,teacher_id:ctx.user.id}); if(error) return {error:'Kelas gagal dibuat: '+error.message}; revalidatePath('/classes'); return {success:true};
}
export async function joinClass(formData:FormData) {
 const ctx=await requireRole(['student']); const code=String(formData.get('code')||'').trim().toUpperCase(); if(!/^[A-Z0-9-]{6,16}$/.test(code)) return {error:'Kode kelas tidak valid.'};
 const {error}=await ctx.supabase.rpc('join_class_by_code',{p_code:code}); if(error) return {error:'Kode tidak valid, kedaluwarsa, atau Anda sudah menjadi anggota.'}; revalidatePath('/classes'); return {success:true};
}
