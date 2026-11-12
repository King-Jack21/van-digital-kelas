-- VAN Classroom: core schema. Apply with `supabase db push`.
create extension if not exists pgcrypto;
create type public.app_role as enum ('owner','teacher','student');
create type public.submission_status as enum ('draft','submitted','under_review','graded','revision_requested','late','missing');
create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 email text not null unique, full_name text not null default 'New member', role public.app_role not null default 'student',
 avatar_url text, is_suspended boolean not null default false, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.classes (
 id uuid primary key default gen_random_uuid(), teacher_id uuid not null references public.profiles(id), name text not null,
 subject text, description text, invite_code_hash text unique, is_archived boolean not null default false,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.class_members (
 id uuid primary key default gen_random_uuid(), class_id uuid not null references public.classes(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade, member_role text not null default 'student' check(member_role in ('teacher','student')),
 joined_at timestamptz not null default now(), unique(class_id,user_id)
);
create table public.class_invites (id uuid primary key default gen_random_uuid(), class_id uuid not null references public.classes(id) on delete cascade, code_hash text not null unique, expires_at timestamptz, revoked_at timestamptz, created_at timestamptz not null default now());
create table public.class_topics (id uuid primary key default gen_random_uuid(), class_id uuid not null references public.classes(id) on delete cascade, title text not null, position int not null default 0);
create table public.class_posts (id uuid primary key default gen_random_uuid(), class_id uuid not null references public.classes(id) on delete cascade, author_id uuid not null references public.profiles(id), title text, body text not null, pinned boolean not null default false, created_at timestamptz not null default now());
create table public.post_comments (id uuid primary key default gen_random_uuid(), post_id uuid not null references public.class_posts(id) on delete cascade, author_id uuid not null references public.profiles(id), body text not null, created_at timestamptz not null default now());
create table public.materials (id uuid primary key default gen_random_uuid(), class_id uuid not null references public.classes(id) on delete cascade, author_id uuid not null references public.profiles(id), title text not null, body text, storage_path text, created_at timestamptz not null default now());
create table public.assignments (id uuid primary key default gen_random_uuid(), class_id uuid not null references public.classes(id) on delete cascade, teacher_id uuid not null references public.profiles(id), title text not null, instructions text not null default '', due_at timestamptz, max_score numeric(8,2) not null default 100 check(max_score>0), allow_late boolean not null default false, created_at timestamptz not null default now());
create table public.assignment_attachments (id uuid primary key default gen_random_uuid(), assignment_id uuid not null references public.assignments(id) on delete cascade, storage_path text not null, file_name text not null, mime_type text, size_bytes bigint check(size_bytes>=0));
create table public.submissions (id uuid primary key default gen_random_uuid(), assignment_id uuid not null references public.assignments(id) on delete cascade, student_id uuid not null references public.profiles(id), answer_text text, status public.submission_status not null default 'draft', submitted_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(assignment_id,student_id));
create table public.submission_files (id uuid primary key default gen_random_uuid(), submission_id uuid not null references public.submissions(id) on delete cascade, storage_path text not null, file_name text not null, mime_type text, size_bytes bigint);
create table public.submission_feedback (id uuid primary key default gen_random_uuid(), submission_id uuid not null references public.submissions(id) on delete cascade, teacher_id uuid not null references public.profiles(id), body text not null, created_at timestamptz not null default now());
create table public.quizzes (id uuid primary key default gen_random_uuid(), class_id uuid not null references public.classes(id) on delete cascade, teacher_id uuid not null references public.profiles(id), title text not null, duration_minutes int, max_attempts int not null default 1 check(max_attempts>0), published boolean not null default false, created_at timestamptz not null default now());
create table public.quiz_questions (id uuid primary key default gen_random_uuid(), quiz_id uuid not null references public.quizzes(id) on delete cascade, prompt text not null, question_type text not null check(question_type in ('multiple_choice','short_answer')), points numeric(8,2) not null default 1, position int not null default 0, answer_key text);
create table public.quiz_options (id uuid primary key default gen_random_uuid(), question_id uuid not null references public.quiz_questions(id) on delete cascade, option_text text not null, is_correct boolean not null default false);
create table public.quiz_attempts (id uuid primary key default gen_random_uuid(), quiz_id uuid not null references public.quizzes(id) on delete cascade, student_id uuid not null references public.profiles(id), score numeric(8,2), started_at timestamptz not null default now(), submitted_at timestamptz);
create table public.quiz_answers (id uuid primary key default gen_random_uuid(), attempt_id uuid not null references public.quiz_attempts(id) on delete cascade, question_id uuid not null references public.quiz_questions(id) on delete cascade, answer_text text, selected_option_id uuid references public.quiz_options(id), points_awarded numeric(8,2), unique(attempt_id,question_id));
create table public.grades (id uuid primary key default gen_random_uuid(), assignment_id uuid not null references public.assignments(id) on delete cascade, student_id uuid not null references public.profiles(id), teacher_id uuid not null references public.profiles(id), score numeric(8,2) not null, feedback text, created_at timestamptz not null default now(), unique(assignment_id,student_id));
create table public.grade_history (id uuid primary key default gen_random_uuid(), grade_id uuid not null references public.grades(id) on delete cascade, changed_by uuid not null references public.profiles(id), old_score numeric(8,2), new_score numeric(8,2) not null, note text, created_at timestamptz not null default now());
create table public.assignment_lobbies (id uuid primary key default gen_random_uuid(), class_id uuid references public.classes(id) on delete set null, teacher_id uuid not null references public.profiles(id), title text not null, description text not null default '', capacity int check(capacity is null or capacity>0), approval_required boolean not null default false, registration_open boolean not null default true, submissions_open boolean not null default true, allow_late boolean not null default false, due_at timestamptz, archived_at timestamptz, created_at timestamptz not null default now());
create table public.lobby_members (id uuid primary key default gen_random_uuid(), lobby_id uuid not null references public.assignment_lobbies(id) on delete cascade, user_id uuid not null references public.profiles(id) on delete cascade, status text not null default 'active' check(status in ('pending','active','rejected','removed')), joined_at timestamptz not null default now(), unique(lobby_id,user_id));
create table public.lobby_invite_codes (id uuid primary key default gen_random_uuid(), lobby_id uuid not null references public.assignment_lobbies(id) on delete cascade, code_hash text not null unique, expires_at timestamptz, revoked_at timestamptz, created_at timestamptz not null default now());
create table public.lobby_announcements (id uuid primary key default gen_random_uuid(), lobby_id uuid not null references public.assignment_lobbies(id) on delete cascade, teacher_id uuid not null references public.profiles(id), title text not null, body text not null, pinned boolean not null default false, created_at timestamptz not null default now());
create table public.lobby_announcement_files (id uuid primary key default gen_random_uuid(), announcement_id uuid not null references public.lobby_announcements(id) on delete cascade, storage_path text not null, file_name text not null, mime_type text, size_bytes bigint);
create table public.lobby_submissions (id uuid primary key default gen_random_uuid(), lobby_id uuid not null references public.assignment_lobbies(id) on delete cascade, student_id uuid not null references public.profiles(id), answer_text text, status public.submission_status not null default 'draft', submitted_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(lobby_id,student_id));
create table public.lobby_submission_files (id uuid primary key default gen_random_uuid(), submission_id uuid not null references public.lobby_submissions(id) on delete cascade, storage_path text not null, file_name text not null, mime_type text, size_bytes bigint);
create table public.lobby_submission_versions (id uuid primary key default gen_random_uuid(), submission_id uuid not null references public.lobby_submissions(id) on delete cascade, version_no int not null, answer_text text, created_at timestamptz not null default now(), unique(submission_id,version_no));
create table public.lobby_feedback (id uuid primary key default gen_random_uuid(), submission_id uuid not null references public.lobby_submissions(id) on delete cascade, teacher_id uuid not null references public.profiles(id), body text not null, created_at timestamptz not null default now());
create table public.lobby_grades (id uuid primary key default gen_random_uuid(), submission_id uuid not null unique references public.lobby_submissions(id) on delete cascade, teacher_id uuid not null references public.profiles(id), score numeric(8,2) not null check(score>=0), max_score numeric(8,2) not null check(max_score>0), feedback text, created_at timestamptz not null default now(), check(score<=max_score));
create table public.notifications (id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade, title text not null, body text not null, href text, read_at timestamptz, created_at timestamptz not null default now());
create table public.calendar_events (id uuid primary key default gen_random_uuid(), class_id uuid references public.classes(id) on delete cascade, user_id uuid references public.profiles(id) on delete cascade, title text not null, starts_at timestamptz not null, ends_at timestamptz, created_at timestamptz not null default now());
create table public.file_metadata (id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.profiles(id), bucket text not null default 'private-files', storage_path text not null unique, entity_type text, entity_id uuid, file_name text not null, mime_type text, size_bytes bigint, created_at timestamptz not null default now());
create table public.user_settings (user_id uuid primary key references public.profiles(id) on delete cascade, theme text not null default 'dark' check(theme in ('dark','light','system')), notifications jsonb not null default '{}'::jsonb, updated_at timestamptz not null default now());
create table public.audit_logs (id uuid primary key default gen_random_uuid(), actor_id uuid references public.profiles(id), action text not null, entity_type text not null, entity_id uuid, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now());
create table public.system_settings (key text primary key, value jsonb not null default '{}'::jsonb, updated_by uuid references public.profiles(id), updated_at timestamptz not null default now());

create index on public.class_members(user_id); create index on public.class_members(class_id);
create index on public.assignments(class_id,due_at); create index on public.submissions(student_id,status);
create index on public.lobby_members(user_id,status); create index on public.lobby_submissions(lobby_id,student_id);
create index on public.notifications(user_id,read_at,created_at desc); create index on public.audit_logs(created_at desc);

-- Helper functions use a fixed search_path to avoid search_path injection and avoid policy recursion.
create or replace function public.current_role() returns public.app_role language sql stable security definer set search_path=public as $$ select role from profiles where id=auth.uid() $$;
create or replace function public.is_owner() returns boolean language sql stable security definer set search_path=public as $$ select coalesce(public.current_role()='owner',false) $$;
create or replace function public.teaches_class(cid uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from classes where id=cid and teacher_id=auth.uid()) $$;
create or replace function public.member_of_class(cid uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from class_members where class_id=cid and user_id=auth.uid() and member_role='student') or public.teaches_class(cid) $$;
create or replace function public.teaches_lobby(lid uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from assignment_lobbies where id=lid and teacher_id=auth.uid()) $$;
create or replace function public.member_of_lobby(lid uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from lobby_members where lobby_id=lid and user_id=auth.uid() and status='active') $$;

-- Auth bootstrap: public signups are always students; allowlisted owner email is the only bootstrap elevation.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
declare allowed text[]; assigned_role public.app_role := 'student'; begin
 allowed := string_to_array(lower(coalesce(current_setting('app.owner_emails',true),'')), ',');
 if lower(new.email) = any(allowed) and array_length(allowed,1)>0 then assigned_role := 'owner'; end if;
 insert into public.profiles(id,email,full_name,role) values(new.id,new.email,coalesce(new.raw_user_meta_data->>'full_name','New member'),assigned_role);
 return new; end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

-- RLS enabled on every application table.
do $$ declare t text; begin foreach t in array array['profiles','classes','class_members','class_invites','class_topics','class_posts','post_comments','materials','assignments','assignment_attachments','submissions','submission_files','submission_feedback','quizzes','quiz_questions','quiz_options','quiz_attempts','quiz_answers','grades','grade_history','assignment_lobbies','lobby_members','lobby_invite_codes','lobby_announcements','lobby_announcement_files','lobby_submissions','lobby_submission_files','lobby_submission_versions','lobby_feedback','lobby_grades','notifications','calendar_events','file_metadata','user_settings','audit_logs','system_settings'] loop execute format('alter table public.%I enable row level security',t); end loop; end $$;

create policy "profiles self or owner" on profiles for select using(id=auth.uid() or is_owner() or exists(select 1 from class_members cm where cm.user_id=profiles.id and member_of_class(cm.class_id)));
create policy "profile self update" on profiles for update using(id=auth.uid() and role=current_role() or is_owner()) with check(id=auth.uid() and role=current_role() or is_owner());
create policy "owner manages profiles" on profiles for all using(is_owner()) with check(is_owner());
create policy "class read members" on classes for select using(member_of_class(id) or is_owner());
create policy "teacher creates class" on classes for insert with check(teacher_id=auth.uid() and current_role() in ('teacher','owner'));
create policy "teacher updates class" on classes for update using(teacher_id=auth.uid() or is_owner()) with check(teacher_id=auth.uid() or is_owner());
create policy "teacher deletes class" on classes for delete using(teacher_id=auth.uid() or is_owner());
create policy "members visible in class" on class_members for select using(member_of_class(class_id) or is_owner());
create policy "teacher manages class members" on class_members for all using(teaches_class(class_id) or is_owner()) with check(teaches_class(class_id) or is_owner());
create policy "student joins self" on class_members for insert with check(user_id=auth.uid() and current_role()='student');
create policy "class content readable" on class_topics for select using(member_of_class(class_id) or is_owner());
create policy "class content teacher write" on class_topics for all using(teaches_class(class_id) or is_owner()) with check(teaches_class(class_id) or is_owner());
create policy "posts readable" on class_posts for select using(member_of_class(class_id) or is_owner());
create policy "teacher posts" on class_posts for all using(teaches_class(class_id) or is_owner()) with check((teaches_class(class_id) and author_id=auth.uid()) or is_owner());
create policy "comments class members" on post_comments for select using(exists(select 1 from class_posts p where p.id=post_id and member_of_class(p.class_id)) or is_owner());
create policy "members comment" on post_comments for insert with check(author_id=auth.uid() and exists(select 1 from class_posts p where p.id=post_id and member_of_class(p.class_id)));
create policy "materials members read" on materials for select using(member_of_class(class_id) or is_owner());
create policy "teachers manage materials" on materials for all using(teaches_class(class_id) or is_owner()) with check(teaches_class(class_id) or is_owner());
create policy "assignments class read" on assignments for select using(member_of_class(class_id) or is_owner());
create policy "teachers manage assignments" on assignments for all using(teacher_id=auth.uid() or is_owner()) with check((teacher_id=auth.uid() and current_role() in ('teacher','owner')) or is_owner());
create policy "assignment attachments read" on assignment_attachments for select using(exists(select 1 from assignments a where a.id=assignment_id and member_of_class(a.class_id)) or is_owner());
create policy "assignment attachments teacher write" on assignment_attachments for all using(exists(select 1 from assignments a where a.id=assignment_id and (a.teacher_id=auth.uid() or is_owner()))) with check(exists(select 1 from assignments a where a.id=assignment_id and (a.teacher_id=auth.uid() or is_owner())));
create policy "submission private read" on submissions for select using(student_id=auth.uid() or exists(select 1 from assignments a where a.id=assignment_id and a.teacher_id=auth.uid()) or is_owner());
create policy "student creates own submission" on submissions for insert with check(student_id=auth.uid() and current_role()='student' and exists(select 1 from assignments a join class_members cm on cm.class_id=a.class_id where a.id=assignment_id and cm.user_id=auth.uid()));
create policy "student edits own draft or teacher" on submissions for update using(student_id=auth.uid() or exists(select 1 from assignments a where a.id=assignment_id and a.teacher_id=auth.uid()) or is_owner()) with check(student_id=auth.uid() or exists(select 1 from assignments a where a.id=assignment_id and a.teacher_id=auth.uid()) or is_owner());
create policy "submission files private" on submission_files for select using(exists(select 1 from submissions s join assignments a on a.id=s.assignment_id where s.id=submission_id and (s.student_id=auth.uid() or a.teacher_id=auth.uid())) or is_owner());
create policy "submission file owner write" on submission_files for all using(exists(select 1 from submissions s where s.id=submission_id and s.student_id=auth.uid()) or is_owner()) with check(exists(select 1 from submissions s where s.id=submission_id and s.student_id=auth.uid()) or is_owner());
create policy "submission feedback private" on submission_feedback for select using(exists(select 1 from submissions s join assignments a on a.id=s.assignment_id where s.id=submission_id and (s.student_id=auth.uid() or a.teacher_id=auth.uid())) or is_owner());
create policy "teacher feedback write" on submission_feedback for all using(teacher_id=auth.uid() or is_owner()) with check((teacher_id=auth.uid() and exists(select 1 from submissions s join assignments a on a.id=s.assignment_id where s.id=submission_id and a.teacher_id=auth.uid())) or is_owner());
create policy "quiz class read" on quizzes for select using(member_of_class(class_id) or is_owner());
create policy "quiz teacher write" on quizzes for all using(teacher_id=auth.uid() or is_owner()) with check(teacher_id=auth.uid() or is_owner());
create policy "quiz questions read" on quiz_questions for select using(exists(select 1 from quizzes q where q.id=quiz_id and member_of_class(q.class_id)) or is_owner());
create policy "quiz question teacher write" on quiz_questions for all using(exists(select 1 from quizzes q where q.id=quiz_id and q.teacher_id=auth.uid()) or is_owner()) with check(exists(select 1 from quizzes q where q.id=quiz_id and q.teacher_id=auth.uid()) or is_owner());
create policy "quiz options read" on quiz_options for select using(exists(select 1 from quiz_questions qq join quizzes q on q.id=qq.quiz_id where qq.id=question_id and member_of_class(q.class_id)) or is_owner());
create policy "quiz options teacher write" on quiz_options for all using(exists(select 1 from quiz_questions qq join quizzes q on q.id=qq.quiz_id where qq.id=question_id and q.teacher_id=auth.uid()) or is_owner()) with check(exists(select 1 from quiz_questions qq join quizzes q on q.id=qq.quiz_id where qq.id=question_id and q.teacher_id=auth.uid()) or is_owner());
create policy "attempt private" on quiz_attempts for select using(student_id=auth.uid() or exists(select 1 from quizzes q where q.id=quiz_id and q.teacher_id=auth.uid()) or is_owner());
create policy "student attempt" on quiz_attempts for insert with check(student_id=auth.uid() and current_role()='student');
create policy "attempt answer private" on quiz_answers for select using(exists(select 1 from quiz_attempts a where a.id=attempt_id and a.student_id=auth.uid()) or exists(select 1 from quiz_attempts a join quizzes q on q.id=a.quiz_id where a.id=attempt_id and q.teacher_id=auth.uid()) or is_owner());
create policy "student answer write" on quiz_answers for all using(exists(select 1 from quiz_attempts a where a.id=attempt_id and a.student_id=auth.uid()) or is_owner()) with check(exists(select 1 from quiz_attempts a where a.id=attempt_id and a.student_id=auth.uid()) or is_owner());
create policy "grades private" on grades for select using(student_id=auth.uid() or teacher_id=auth.uid() or is_owner());
create policy "teacher grade write" on grades for all using(teacher_id=auth.uid() or is_owner()) with check(teacher_id=auth.uid() or is_owner());
create policy "grade history private" on grade_history for select using(exists(select 1 from grades g where g.id=grade_id and (g.student_id=auth.uid() or g.teacher_id=auth.uid())) or is_owner());
create policy "teacher grade history" on grade_history for insert with check(changed_by=auth.uid() and (is_owner() or exists(select 1 from grades g where g.id=grade_id and g.teacher_id=auth.uid())));
create policy "lobby readable" on assignment_lobbies for select using(teacher_id=auth.uid() or member_of_lobby(id) or is_owner());
create policy "teacher manages lobby" on assignment_lobbies for all using(teacher_id=auth.uid() or is_owner()) with check(teacher_id=auth.uid() or is_owner());
create policy "lobby members visible" on lobby_members for select using(user_id=auth.uid() or teaches_lobby(lobby_id) or is_owner());
create policy "student requests lobby membership" on lobby_members for insert with check(user_id=auth.uid() and current_role()='student');
create policy "teacher manages lobby members" on lobby_members for update using(teaches_lobby(lobby_id) or is_owner()) with check(teaches_lobby(lobby_id) or is_owner());
create policy "teacher removes lobby members" on lobby_members for delete using(teaches_lobby(lobby_id) or is_owner());
create policy "lobby invite teacher only" on lobby_invite_codes for all using(teaches_lobby(lobby_id) or is_owner()) with check(teaches_lobby(lobby_id) or is_owner());
create policy "lobby announcements member read" on lobby_announcements for select using(member_of_lobby(lobby_id) or teaches_lobby(lobby_id) or is_owner());
create policy "lobby announcement teacher write" on lobby_announcements for all using(teaches_lobby(lobby_id) or is_owner()) with check((teacher_id=auth.uid() and teaches_lobby(lobby_id)) or is_owner());
create policy "lobby announcement files read" on lobby_announcement_files for select using(exists(select 1 from lobby_announcements a where a.id=announcement_id and (member_of_lobby(a.lobby_id) or teaches_lobby(a.lobby_id))) or is_owner());
create policy "lobby announcement files teacher write" on lobby_announcement_files for all using(exists(select 1 from lobby_announcements a where a.id=announcement_id and teaches_lobby(a.lobby_id)) or is_owner()) with check(exists(select 1 from lobby_announcements a where a.id=announcement_id and teaches_lobby(a.lobby_id)) or is_owner());
-- Crucial privacy boundary: a student sees only their own lobby submission; a teacher only their own lobby's submissions.
create policy "lobby submission private read" on lobby_submissions for select using(student_id=auth.uid() or teaches_lobby(lobby_id) or is_owner());
create policy "student owns lobby submission" on lobby_submissions for insert with check(student_id=auth.uid() and member_of_lobby(lobby_id));
create policy "student edits own lobby submission" on lobby_submissions for update using(student_id=auth.uid() or teaches_lobby(lobby_id) or is_owner()) with check(student_id=auth.uid() or teaches_lobby(lobby_id) or is_owner());
create policy "lobby submission files private" on lobby_submission_files for select using(exists(select 1 from lobby_submissions s where s.id=submission_id and (s.student_id=auth.uid() or teaches_lobby(s.lobby_id))) or is_owner());
create policy "lobby submission file owner write" on lobby_submission_files for all using(exists(select 1 from lobby_submissions s where s.id=submission_id and s.student_id=auth.uid()) or is_owner()) with check(exists(select 1 from lobby_submissions s where s.id=submission_id and s.student_id=auth.uid()) or is_owner());
create policy "lobby versions private" on lobby_submission_versions for select using(exists(select 1 from lobby_submissions s where s.id=submission_id and (s.student_id=auth.uid() or teaches_lobby(s.lobby_id))) or is_owner());
create policy "lobby version owner write" on lobby_submission_versions for all using(exists(select 1 from lobby_submissions s where s.id=submission_id and s.student_id=auth.uid()) or is_owner()) with check(exists(select 1 from lobby_submissions s where s.id=submission_id and s.student_id=auth.uid()) or is_owner());
create policy "lobby feedback private" on lobby_feedback for select using(exists(select 1 from lobby_submissions s where s.id=submission_id and (s.student_id=auth.uid() or teaches_lobby(s.lobby_id))) or is_owner());
create policy "lobby teacher feedback" on lobby_feedback for all using(teacher_id=auth.uid() or is_owner()) with check(teacher_id=auth.uid() and exists(select 1 from lobby_submissions s where s.id=submission_id and teaches_lobby(s.lobby_id)) or is_owner());
create policy "lobby grades private" on lobby_grades for select using(exists(select 1 from lobby_submissions s where s.id=submission_id and (s.student_id=auth.uid() or teaches_lobby(s.lobby_id))) or is_owner());
create policy "lobby teacher grades" on lobby_grades for all using(teacher_id=auth.uid() or is_owner()) with check(teacher_id=auth.uid() and exists(select 1 from lobby_submissions s where s.id=submission_id and teaches_lobby(s.lobby_id)) or is_owner());
create policy "notification owner" on notifications for all using(user_id=auth.uid() or is_owner()) with check(user_id=auth.uid() or is_owner());
create policy "calendar own or class member" on calendar_events for select using(user_id=auth.uid() or (class_id is not null and member_of_class(class_id)) or is_owner());
create policy "calendar own write" on calendar_events for all using(user_id=auth.uid() or is_owner()) with check(user_id=auth.uid() or is_owner());
create policy "file metadata private" on file_metadata for select using(owner_id=auth.uid() or is_owner() or (entity_type='lobby_submission' and exists(select 1 from lobby_submissions s where s.id=entity_id and teaches_lobby(s.lobby_id))));
create policy "file metadata owner write" on file_metadata for all using(owner_id=auth.uid() or is_owner()) with check(owner_id=auth.uid() or is_owner());
create policy "settings self" on user_settings for all using(user_id=auth.uid() or is_owner()) with check(user_id=auth.uid() or is_owner());
create policy "audit owner read" on audit_logs for select using(is_owner());
create policy "audit actor insert" on audit_logs for insert with check(actor_id=auth.uid() or is_owner());
create policy "system settings owner" on system_settings for all using(is_owner()) with check(is_owner());

-- Private Storage bucket. Policies constrain path prefix to authenticated user for personal uploads;
-- server-side upload handlers should use scoped paths and verify entity membership before signing.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values
('private-files','private-files',false,10485760,array['image/jpeg','image/png','image/webp','application/pdf','application/vnd.openxmlformats-officedocument.wordprocessingml.document','application/vnd.openxmlformats-officedocument.presentationml.presentation','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','text/plain'])
on conflict(id) do update set public=false,file_size_limit=10485760;
create policy "private file read own prefix" on storage.objects for select to authenticated using(bucket_id='private-files' and (name like auth.uid()::text || '/%' or public.is_owner()));
create policy "private file upload own prefix" on storage.objects for insert to authenticated with check(bucket_id='private-files' and name like auth.uid()::text || '/%');
create policy "private file delete own prefix" on storage.objects for delete to authenticated using(bucket_id='private-files' and (name like auth.uid()::text || '/%' or public.is_owner()));

-- Atomic invite redemption: no client-side reads of invite hashes; serialize capacity checks.
create table public.invite_rate_limits(user_id uuid not null references auth.users(id) on delete cascade, action text not null, window_started_at timestamptz not null default now(), attempts int not null default 0, primary key(user_id,action));
alter table public.invite_rate_limits enable row level security;
create policy "rate limits hidden" on public.invite_rate_limits for all using(false) with check(false);
create or replace function public.join_lobby_by_code(p_code text) returns jsonb language plpgsql security definer set search_path=public,extensions as $$
declare uid uuid:=auth.uid(); inv public.lobby_invite_codes%rowtype; lob public.assignment_lobbies%rowtype; active_count int; rl public.invite_rate_limits%rowtype; member_status text;
begin
 if uid is null or public.current_role()<>'student' then raise exception 'not allowed'; end if;
 insert into public.invite_rate_limits(user_id,action,window_started_at,attempts) values(uid,'lobby_join',now(),1)
 on conflict(user_id,action) do update set attempts=case when invite_rate_limits.window_started_at < now()-interval '15 minutes' then 1 else invite_rate_limits.attempts+1 end, window_started_at=case when invite_rate_limits.window_started_at < now()-interval '15 minutes' then now() else invite_rate_limits.window_started_at end;
 select * into rl from public.invite_rate_limits where user_id=uid and action='lobby_join'; if rl.attempts>10 then raise exception 'rate limited'; end if;
 select * into inv from public.lobby_invite_codes where code_hash=encode(digest(upper(trim(p_code)),'sha256'),'hex') and revoked_at is null and (expires_at is null or expires_at>now()) limit 1;
 if inv.id is null then raise exception 'invalid invite'; end if;
 select * into lob from public.assignment_lobbies where id=inv.lobby_id for update;
 if lob.id is null or not lob.registration_open or lob.archived_at is not null then raise exception 'closed'; end if;
 select count(*) into active_count from public.lobby_members where lobby_id=lob.id and status in ('active','pending');
 if lob.capacity is not null and active_count>=lob.capacity then raise exception 'full'; end if;
 member_status:=case when lob.approval_required then 'pending' else 'active' end;
 insert into public.lobby_members(lobby_id,user_id,status) values(lob.id,uid,member_status);
 return jsonb_build_object('status',member_status,'lobby_id',lob.id);
end $$;
grant execute on function public.join_lobby_by_code(text) to authenticated;

create or replace function public.join_class_by_code(p_code text) returns jsonb language plpgsql security definer set search_path=public,extensions as $$
declare uid uuid:=auth.uid(); inv public.class_invites%rowtype;
begin
 if uid is null or public.current_role()<>'student' then raise exception 'not allowed'; end if;
 select * into inv from public.class_invites where code_hash=encode(digest(upper(trim(p_code)),'sha256'),'hex') and revoked_at is null and (expires_at is null or expires_at>now()) limit 1;
 if inv.id is null then raise exception 'invalid invite'; end if;
 insert into public.class_members(class_id,user_id,member_role) values(inv.class_id,uid,'student');
 return jsonb_build_object('class_id',inv.class_id);
end $$;
grant execute on function public.join_class_by_code(text) to authenticated;

create or replace function public.can_read_private_file(object_path text) returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.file_metadata fm where fm.storage_path=object_path and (fm.owner_id=auth.uid() or public.is_owner() or
 (fm.entity_type='lobby_submission' and exists(select 1 from public.lobby_submissions s where s.id=fm.entity_id and public.teaches_lobby(s.lobby_id))) or
 (fm.entity_type='assignment_submission' and exists(select 1 from public.submissions s join public.assignments a on a.id=s.assignment_id where s.id=fm.entity_id and a.teacher_id=auth.uid()))))
$$;
create policy "private file read authorized entity" on storage.objects for select to authenticated using(bucket_id='private-files' and public.can_read_private_file(name));
