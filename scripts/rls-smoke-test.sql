-- Run in Supabase SQL editor after creating fixtures for two students and two teachers.
-- Set JWT claims to simulate each authenticated principal. These assertions are intended
-- as a manual smoke-test harness; use the Supabase local stack for automated CI tests.
begin;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-0000000000a1',true);
select set_config('request.jwt.claim.role','authenticated',true);
-- Student A should not see Student B's lobby submissions or private feedback.
select count(*) as visible_other_student_submissions from public.lobby_submissions where student_id='00000000-0000-0000-0000-0000000000b2';
select count(*) as visible_other_student_feedback from public.lobby_feedback f join public.lobby_submissions s on s.id=f.submission_id where s.student_id='00000000-0000-0000-0000-0000000000b2';
-- As a student, mutation of grade tables should fail due to missing write policy.
-- Teacher A/B ownership checks should be verified by switching sub claim and repeating.
rollback;
