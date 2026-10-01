-- Ledgerly — Supabase schema + Row-Level Security
-- Run this once in the Supabase SQL editor:
--   Dashboard -> SQL Editor -> New query -> paste all of this -> Run.
-- Safe to re-run (uses "if not exists" / "or replace" / "drop policy if exists").

-- gen_random_uuid()
create extension if not exists pgcrypto;

-- ------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------
create table if not exists public.workspaces (
  id         uuid primary key default gen_random_uuid(),
  name       text not null default 'My startup',
  owner_id   uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.workspace_members (
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  role         text not null default 'member',
  created_at   timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

create table if not exists public.expenses (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  vendor       text not null,
  amount       numeric not null,
  category     text not null,
  date         date,
  payment      text,
  note         text,
  seed         boolean not null default false,
  created_at   timestamptz not null default now()
);
create index if not exists expenses_ws_idx on public.expenses(workspace_id);

create table if not exists public.budgets (
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  category     text not null,
  amount       numeric not null default 0,
  primary key (workspace_id, category)
);

create table if not exists public.settings (
  workspace_id  uuid primary key references public.workspaces(id) on delete cascade,
  starting_cash numeric not null default 0
);

-- ------------------------------------------------------------------
-- Membership helper.
-- SECURITY DEFINER so it bypasses RLS when checked from other tables'
-- policies — this is what prevents infinite policy recursion.
-- ------------------------------------------------------------------
create or replace function public.is_workspace_member(ws uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.workspace_members m
    where m.workspace_id = ws and m.user_id = auth.uid()
  );
$$;

-- ------------------------------------------------------------------
-- Enable Row-Level Security (deny-by-default once enabled)
-- ------------------------------------------------------------------
alter table public.workspaces        enable row level security;
alter table public.workspace_members enable row level security;
alter table public.expenses          enable row level security;
alter table public.budgets           enable row level security;
alter table public.settings          enable row level security;

-- workspaces: visible to members; created/updated/deleted by the owner.
drop policy if exists ws_select on public.workspaces;
create policy ws_select on public.workspaces for select
  using (owner_id = auth.uid() or public.is_workspace_member(id));
drop policy if exists ws_insert on public.workspaces;
create policy ws_insert on public.workspaces for insert
  with check (owner_id = auth.uid());
drop policy if exists ws_update on public.workspaces;
create policy ws_update on public.workspaces for update
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
drop policy if exists ws_delete on public.workspaces;
create policy ws_delete on public.workspaces for delete
  using (owner_id = auth.uid());

-- workspace_members: you can see your own membership rows, and add/remove
-- members only in a workspace you OWN. (Co-founder invites later will add an
-- invites table + a SECURITY DEFINER "accept invite" function; no change here.)
drop policy if exists wm_select on public.workspace_members;
create policy wm_select on public.workspace_members for select
  using (user_id = auth.uid());
drop policy if exists wm_insert on public.workspace_members;
create policy wm_insert on public.workspace_members for insert
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.workspaces w
                where w.id = workspace_id and w.owner_id = auth.uid())
  );
drop policy if exists wm_delete on public.workspace_members;
create policy wm_delete on public.workspace_members for delete
  using (
    exists (select 1 from public.workspaces w
            where w.id = workspace_id and w.owner_id = auth.uid())
  );

-- expenses / budgets / settings: full access for members of the workspace.
drop policy if exists exp_all on public.expenses;
create policy exp_all on public.expenses for all
  using (public.is_workspace_member(workspace_id))
  with check (public.is_workspace_member(workspace_id));

drop policy if exists bud_all on public.budgets;
create policy bud_all on public.budgets for all
  using (public.is_workspace_member(workspace_id))
  with check (public.is_workspace_member(workspace_id));

drop policy if exists set_all on public.settings;
create policy set_all on public.settings for all
  using (public.is_workspace_member(workspace_id))
  with check (public.is_workspace_member(workspace_id));

-- ------------------------------------------------------------------
-- Idempotent workspace bootstrap.
-- At most ONE auto-created workspace per owner, and a single race-safe
-- function the client calls on every sign-in. This prevents the duplicate
-- workspaces / double-migration that a client-side check-then-insert allowed.
--
-- NOTE for an EXISTING project: if a user already owns more than one
-- workspace, delete the extras FIRST — otherwise the unique index below fails.
-- ------------------------------------------------------------------
create unique index if not exists workspaces_owner_uniq on public.workspaces(owner_id);

create or replace function public.get_or_create_my_workspace()
returns table(workspace_id uuid, created boolean)
language plpgsql
security definer
set search_path = public
as $$
declare
  ws uuid;
  made boolean := false;
begin
  -- Already a member of one? Return the earliest (deterministic).
  select m.workspace_id into ws
  from public.workspace_members m
  where m.user_id = auth.uid()
  order by m.created_at asc
  limit 1;

  if ws is not null then
    workspace_id := ws; created := false; return next; return;
  end if;

  -- None yet: create one. on conflict handles a concurrent sign-in racing us.
  insert into public.workspaces(name, owner_id)
  values ('My startup', auth.uid())
  on conflict (owner_id) do nothing
  returning id into ws;

  if ws is null then
    select id into ws from public.workspaces where owner_id = auth.uid();
  else
    made := true;
  end if;

  insert into public.workspace_members(workspace_id, user_id, role)
  values (ws, auth.uid(), 'owner')
  on conflict (workspace_id, user_id) do nothing;

  workspace_id := ws; created := made; return next;
end;
$$;

grant execute on function public.get_or_create_my_workspace() to authenticated;
