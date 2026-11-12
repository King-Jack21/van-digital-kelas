// One-time administrative bootstrap. Run only from a trusted operator machine.
import { createClient } from '@supabase/supabase-js';
const url=process.env.NEXT_PUBLIC_SUPABASE_URL, key=process.env.SUPABASE_SERVICE_ROLE_KEY;
const emails=(process.env.OWNER_EMAILS||'').split(',').map(x=>x.trim().toLowerCase()).filter(Boolean);
if(!url||!key||!emails.length) throw new Error('Set Supabase URL, service role key, and OWNER_EMAILS.');
const supabase=createClient(url,key,{auth:{autoRefreshToken:false,persistSession:false}});
for(const email of emails){const {data,error}=await supabase.from('profiles').update({role:'owner'}).eq('email',email).select('id,email');if(error) throw error;if(!data?.length) console.warn(`No profile for ${email}; create/verify the account first.`);else console.log(`Owner enabled: ${email}`);}
