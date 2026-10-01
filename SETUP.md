# Ledgerly — Supabase setup (login + per-user data)

Ledgerly now signs people in and stores each account's data in Supabase. Every
account only ever sees its **own** workspace — enforced by Postgres Row-Level
Security, not just by the UI.

You only have to do this once. Budget ~10 minutes.

## 1. Create a Supabase project
1. Go to <https://supabase.com> and sign up (free tier is plenty).
2. **New project** → give it a name and a database password → wait for it to finish provisioning.

## 2. Create the tables + security rules
1. In your project: **SQL Editor** → **New query**.
2. Open [`supabase-schema.sql`](supabase-schema.sql) from this repo, copy the whole file, paste it in, and click **Run**.
3. You should see "Success. No rows returned." That created the tables, the membership helper, and all the RLS policies.

## 3. Get your API keys into the app
1. In Supabase: **Project Settings** → **API**.
2. Copy the **Project URL** and the **anon / public** key.
3. In [`index.html`](index.html), near the top of the `<script>` block, replace:
   ```js
   const SUPABASE_URL='https://YOUR_PROJECT.supabase.co';
   const SUPABASE_ANON_KEY='YOUR_ANON_KEY';
   ```
   with your real values.

> The anon key is **meant** to be public in client-side code. It can't bypass
> Row-Level Security — a signed-in user can still only touch their own workspace.
> (The key you must *never* ship to the browser is the `service_role` key. Don't
> put that one here.)

## 4. Configure auth (email)
In Supabase: **Authentication** → **Providers** → **Email** is on by default.
- **Quick testing:** **Authentication → Providers → Email** → turn *Confirm email* **off** so you can sign up and sign in immediately.
- **Production:** leave confirmation **on**. New users get a confirmation email; magic-link sign-in also works out of the box.
- **Redirect URLs:** under **Authentication → URL Configuration**, add your site URL (your Vercel domain, and `http://localhost:8000` for local testing) to **Redirect URLs** so magic links / confirmations return to the app.

## 5. Run it
Local:
```bash
cd ledgerly && python3 -m http.server 8000
```
Open <http://localhost:8000>, create an account, and you're in. Deploy to Vercel
as before — nothing about the deploy changes.

---

## What happens on first sign-in
- A **workspace** is created for you and you're added as its owner.
- If you'd used Ledgerly on that browser before, your existing `localStorage`
  data (expenses, budgets, cash) is **migrated up** into your new workspace, then
  cleared locally.
- If there was nothing local, your workspace starts with the usual demo data,
  which you can clear with **Remove demo data**.

## Adding your co-founder later (no code/schema change)
The data is already keyed by workspace, so sharing is just granting membership:
1. Have your co-founder sign up (they'll get their own empty workspace).
2. In Supabase **SQL Editor**, add them to *your* workspace:
   ```sql
   -- your workspace id:
   select w.id, w.name from workspaces w
   join workspace_members m on m.workspace_id = w.id
   where m.user_id = auth.uid();   -- run while signed in via the app, or look it up by owner

   -- their user id: Authentication -> Users -> copy the UUID
   insert into workspace_members (workspace_id, user_id, role)
   values ('<your-workspace-id>', '<their-user-id>', 'member');
   ```
   Note: the app currently loads the first workspace a user belongs to, so for a
   true shared view, have the co-founder use the workspace you added them to. A
   nicer in-app invite flow (an `invites` table + an "accept invite" button) is
   the natural follow-up.

## Keys / env
`SUPABASE_URL` and `SUPABASE_ANON_KEY` live in `index.html`. Because this is a
pure static site with no build step, there's no `.env` — the anon key is public
by design. Keep the `service_role` key out of the repo entirely.
