# VAN Classroom

VAN Classroom is a Next.js App Router LMS foundation styled to closely follow the supplied dark dashboard reference: fixed compact sidebar, navy surfaces, violet/cyan/emerald accents, welcome illustration, KPI cards, activity chart, status donut, announcement rail, and responsive mobile navigation.

## Current implementation status

This repository is a **working foundation, not a claim that every requested LMS workflow is production-complete**. Implemented in this delivery:

- Next.js 15 + React 19 + TypeScript + Tailwind + Recharts + Lucide.
- Supabase SSR client setup, middleware session refresh, email/password sign-in, signup, reset email.
- Public signup defaults to `student`; role is stored in PostgreSQL and authorization checks run in server helpers and RLS.
- Owner dashboard KPIs and recent class/announcement data query Supabase (no fabricated KPI totals). The line chart currently visualizes a visual activity series and is **not yet backed by event aggregation**; do not use it for operational reporting until the aggregation endpoint is completed.
- Teacher class creation, student class join, teacher lobby creation with cryptographically random invite code (only its SHA-256 hash is stored), lobby join with server-side checks, and private signed URL route guarded by file metadata RLS.
- Initial SQL migration includes the requested major entity tables, indexes, constraints, helper functions, RLS, and private Storage bucket/policies.
- Dark/light theme preference persisted in localStorage; responsive layout and local SVG assets.

## Known gaps before production

- Owner dashboard charts and analytics aggregations are not complete; only count KPIs and recent rows are real database reads.
- Full class stream/classwork/gradebook, quiz authoring/attempt grading, complete submission upload/version/revision/grading UI, lobby moderation/announcement/grading center, notification delivery/realtime, calendar, audit event capture, pagination, and export are not yet implemented end-to-end. Several routes are intentional module entry points.
- Class invite generation/rotation UI and atomic invite RPC are pending. The current class join action expects an invite row accessible through the caller's RLS context; configure a secure RPC before enabling class invites in production.
- Lobby join validates invite and capacity server-side, but concurrent capacity enforcement should be moved into a single database RPC/transaction before production load. Rate limiting for invite-code attempts must be added (e.g. Upstash Redis or an edge rate limiter).
- File upload UI, MIME sniffing, malware scanning, per-entity storage path authorization, and cleanup jobs remain to be completed. Current private bucket has a 10 MB cap and allowlisted MIME types; browser MIME metadata alone is not a security boundary.
- Owner role bootstrap is deliberately an explicit trusted-operator script, not an unauthenticated registration feature. The SQL signup trigger creates student profiles. Run `OWNER_EMAILS=... node scripts/bootstrap-owner.mjs` once after those users have signed up. Keep the service role key out of browser code and CI logs.
- RLS smoke-test SQL is a manual harness, not a completed automated test suite. Review policies with your own fixture IDs and run adversarial tests before production.
- No real Supabase project credentials are included. Consequently a live database integration, OAuth provider handshake, and deployed Vercel test cannot be performed from this ZIP alone.

## Requirements

- Node.js 20.9+ (Node 22 recommended)
- npm 10+
- Supabase project with PostgreSQL, Auth, and Storage enabled

## Local setup

1. Clone this repository and install dependencies:
   ```bash
   npm install
   ```
2. Copy `.env.example` to `.env.local` and fill in your Supabase project URL and anon key. Never expose `SUPABASE_SERVICE_ROLE_KEY` to client code.
3. Apply the migration:
   ```bash
   npx supabase login
   npx supabase link --project-ref YOUR_PROJECT_REF
   npx supabase db push
   ```
4. In Supabase Auth > URL Configuration, set Site URL to `http://localhost:3000` and add `http://localhost:3000/**` to Redirect URLs.
5. Enable Email provider in Supabase Auth. Configure SMTP for production email delivery.
6. Start the app:
   ```bash
   npm run dev
   ```
7. Register users. For initial owner, set `OWNER_EMAILS` and run the trusted bootstrap script from a secure terminal after the account exists:
   ```bash
   OWNER_EMAILS=owner@yourdomain.com node scripts/bootstrap-owner.mjs
   ```
   `SUPABASE_SERVICE_ROLE_KEY` must be present in that terminal environment only.

## Google OAuth setup

1. In Google Cloud Console create an OAuth 2.0 Web client.
2. Add the Supabase Auth callback URL shown in Supabase Auth > Providers > Google as an authorized redirect URI.
3. Copy Google Client ID and Secret into Supabase Auth > Providers > Google and enable the provider.
4. Add local and production app URLs to Supabase Auth redirect allowlist. Do not put the Google client secret in this repository.
5. The UI currently uses email/password; add a Google sign-in button calling `supabase.auth.signInWithOAuth({ provider: 'google', options: { redirectTo: ... }})` when enabling the provider.

## Vercel deployment

1. Push this project to GitHub.
2. Import the repository in Vercel; framework preset should detect Next.js.
3. Add the public Supabase URL and anon key, `NEXT_PUBLIC_APP_URL`, and app name in Vercel Environment Variables. Add `OWNER_EMAILS` only if required by the operator bootstrap workflow. Keep service-role/cron secrets server-only.
4. Set the production Site URL and OAuth redirect allowlist in Supabase.
5. Deploy. Apply database migrations separately with `npx supabase db push` from a trusted environment.
6. Smoke-test login, role boundaries, RLS, Storage access, and production build before inviting real students.

## Security notes

- RLS is the source of truth; frontend role checks are not authorization.
- The service-role key is not imported by app runtime modules.
- Lobby invite codes are generated with Node crypto and hashed with SHA-256 before storage.
- Private submission policies restrict rows to the submitting student and the owning lobby teacher (plus owner).
- Signed URLs expire after 120 seconds and require a visible `file_metadata` row. Extend this only after adding entity-specific authorization and upload verification.
- Review all SQL policies with production-specific threat modeling. This starter policy set should be treated as a baseline requiring independent security review.

## Quality commands

```bash
npm run typecheck
npm run lint
npm test
npm run build
```

## Verification performed for this archive

- `npm install --no-audit --no-fund` was attempted twice; the environment could not reach the npm registry and timed out.
- `npm install --package-lock-only --offline` was attempted; it failed because the Supabase SSR package was not present in the local npm cache. A lockfile is therefore not included rather than fabricating one.
- `npm run typecheck` was attempted and failed because dependencies/type declarations were unavailable (`next/server`, `zod`, React JSX types, etc.).
- `npm run lint` was attempted and could not start because ESLint is not installed in this environment.
- `npm test` was attempted and could not start because Vitest is not installed in this environment.
- `npm run build` was attempted and could not start because Next.js is not installed in this environment.
- SQL migrations were authored but could not be applied or integration-tested against a Supabase instance because no project credentials or PostgreSQL CLI/server are available here.

These are environment-blocked checks, not passing checks. Run the quality commands after `npm install` on a network-enabled machine and complete the documented Supabase RLS/security test plan before production deployment.
