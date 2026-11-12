import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createClient } from '@/lib/supabase/server';
const schema=z.object({path:z.string().min(3).max(500)});
export async function POST(req:Request) {
 const supabase=await createClient(); const {data:{user}}=await supabase.auth.getUser(); if(!user) return NextResponse.json({error:'Unauthorized'},{status:401});
 const parsed=schema.safeParse(await req.json()); if(!parsed.success) return NextResponse.json({error:'Invalid path'},{status:400});
 const {data:file}=await supabase.from('file_metadata').select('id').eq('storage_path',parsed.data.path).maybeSingle(); if(!file) return NextResponse.json({error:'Not found'},{status:404});
 const {data,error}=await supabase.storage.from('private-files').createSignedUrl(parsed.data.path,120); if(error||!data) return NextResponse.json({error:'Unable to sign file'},{status:403}); return NextResponse.json({url:data.signedUrl,expiresIn:120});
}
