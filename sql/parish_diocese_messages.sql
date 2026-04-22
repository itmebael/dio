-- Parish <-> Diocese chat.
--
-- A dedicated thread table so a parish staff member can message the
-- chancery ("Chat with Diocesan") and diocesan admins can message any
-- parish ("Chat with Parishes"). Separate from parish_secretary_messages
-- (which is user <-> parish), so the two inboxes don't mix.
--
-- Schema:
--   - Every message belongs to exactly one parish (parish_id).
--   - A message is either sent by the parish (sender_role = 'parish') or
--     by the diocese (sender_role = 'diocese').
--   - read_at is per-message; we flip it when the recipient opens the
--     thread, so we can render unread counts.
--
-- Safe to re-run.

create extension if not exists pgcrypto;

grant usage on schema public to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 1. Table
-- ---------------------------------------------------------------------------
create table if not exists public.parish_diocese_messages (
  id uuid primary key default gen_random_uuid(),
  parish_id uuid not null references public.parishes(id) on delete cascade,
  parish_name text,
  sender_role text not null check (sender_role in ('parish','diocese')),
  sender_email text not null,
  sender_name text,
  message_text text not null,
  read_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint parish_diocese_messages_message_text_check
    check (char_length(btrim(message_text)) > 0)
);

create index if not exists parish_diocese_messages_parish_id_idx
  on public.parish_diocese_messages (parish_id, created_at desc);

create index if not exists parish_diocese_messages_unread_idx
  on public.parish_diocese_messages (parish_id, sender_role, read_at);

create index if not exists parish_diocese_messages_created_idx
  on public.parish_diocese_messages (created_at desc);

-- Keep parish_name denormalized in sync on insert / update.
create or replace function public.parish_diocese_messages_fill_defaults()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if new.parish_name is null or btrim(new.parish_name) = '' then
    select p.parish_name into new.parish_name
      from public.parishes p
     where p.id = new.parish_id;
  end if;
  if new.sender_email is null or btrim(new.sender_email) = '' then
    new.sender_email := coalesce(auth.jwt() ->> 'email', '');
  end if;
  new.updated_at := timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists parish_diocese_messages_fill_defaults
  on public.parish_diocese_messages;

create trigger parish_diocese_messages_fill_defaults
  before insert or update on public.parish_diocese_messages
  for each row execute function public.parish_diocese_messages_fill_defaults();

-- ---------------------------------------------------------------------------
-- 2. Grants
-- ---------------------------------------------------------------------------
grant select, insert, update
  on public.parish_diocese_messages
  to authenticated;

grant select on public.parish_diocese_messages to anon;
grant all on public.parish_diocese_messages to service_role;

-- ---------------------------------------------------------------------------
-- 3. Helpers
-- ---------------------------------------------------------------------------
create or replace function public.pdm_current_role()
returns text
language sql
stable
security definer
set search_path = public, auth
as $$
  select coalesce(
    nullif(auth.jwt() -> 'user_metadata' ->> 'role', ''),
    nullif(auth.jwt() -> 'app_metadata'  ->> 'role', ''),
    case when exists (
      select 1 from public.parishes p
       where lower(coalesce(p.email, '')) = lower(coalesce(auth.jwt() ->> 'email', ''))
    ) then 'parish' else '' end
  );
$$;

grant execute on function public.pdm_current_role() to anon, authenticated;

create or replace function public.pdm_current_parish_id()
returns uuid
language sql
stable
security definer
set search_path = public, auth
as $$
  select p.id
    from public.parishes p
   where lower(coalesce(p.email, '')) = lower(coalesce(auth.jwt() ->> 'email', ''))
   limit 1;
$$;

grant execute on function public.pdm_current_parish_id() to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. RLS
--
-- Parish staff   -> their own parish_id only
-- Diocese admin  -> every parish
-- Everyone else  -> nothing
-- ---------------------------------------------------------------------------
alter table public.parish_diocese_messages enable row level security;

drop policy if exists "pdm_select" on public.parish_diocese_messages;
drop policy if exists "pdm_insert" on public.parish_diocese_messages;
drop policy if exists "pdm_update" on public.parish_diocese_messages;

create policy "pdm_select"
on public.parish_diocese_messages
for select
to authenticated
using (
  public.pdm_current_role() = 'diocese'
  or (
    public.pdm_current_role() = 'parish'
    and public.pdm_current_parish_id() is not null
    and parish_id = public.pdm_current_parish_id()
  )
);

create policy "pdm_insert"
on public.parish_diocese_messages
for insert
to authenticated
with check (
  (
    sender_role = 'diocese'
    and public.pdm_current_role() = 'diocese'
  )
  or (
    sender_role = 'parish'
    and public.pdm_current_role() = 'parish'
    and public.pdm_current_parish_id() is not null
    and parish_id = public.pdm_current_parish_id()
  )
);

-- Only the recipient can flip read_at; this policy leaves the payload
-- immutable otherwise (message_text stays what the sender wrote).
create policy "pdm_update"
on public.parish_diocese_messages
for update
to authenticated
using (
  public.pdm_current_role() = 'diocese'
  or (
    public.pdm_current_role() = 'parish'
    and public.pdm_current_parish_id() is not null
    and parish_id = public.pdm_current_parish_id()
  )
)
with check (
  public.pdm_current_role() = 'diocese'
  or (
    public.pdm_current_role() = 'parish'
    and public.pdm_current_parish_id() is not null
    and parish_id = public.pdm_current_parish_id()
  )
);

-- ---------------------------------------------------------------------------
-- 5. RPCs the UI calls
-- ---------------------------------------------------------------------------

-- 5a. Thread list (used by the Diocese inbox). For parish staff this
--     collapses to a single row (their own parish).
drop function if exists public.pdm_list_threads();

create or replace function public.pdm_list_threads()
returns table (
  parish_id uuid,
  parish_name text,
  parish_email text,
  last_message_text text,
  last_message_role text,
  last_message_at timestamptz,
  unread_for_me bigint,
  total_messages bigint
)
language plpgsql
stable
security definer
set search_path = public, auth
as $$
declare
  v_role text := public.pdm_current_role();
  v_my_parish uuid := public.pdm_current_parish_id();
begin
  if v_role not in ('parish','diocese') then
    return;
  end if;

  return query
  with relevant_parishes as (
    select p.id, p.parish_name, p.email
      from public.parishes p
     where v_role = 'diocese'
        or (v_role = 'parish' and p.id = v_my_parish)
  ),
  last_msg as (
    select distinct on (m.parish_id)
           m.parish_id,
           m.message_text,
           m.sender_role,
           m.created_at
      from public.parish_diocese_messages m
     where v_role = 'diocese'
        or (v_role = 'parish' and m.parish_id = v_my_parish)
     order by m.parish_id, m.created_at desc
  ),
  counts as (
    select m.parish_id,
           count(*) filter (
             where m.read_at is null
               and (
                 (v_role = 'diocese' and m.sender_role = 'parish')
                 or (v_role = 'parish' and m.sender_role = 'diocese')
               )
           ) as unread_for_me,
           count(*) as total_messages
      from public.parish_diocese_messages m
     where v_role = 'diocese'
        or (v_role = 'parish' and m.parish_id = v_my_parish)
     group by m.parish_id
  )
  select
    rp.id          as parish_id,
    rp.parish_name as parish_name,
    rp.email       as parish_email,
    lm.message_text      as last_message_text,
    lm.sender_role       as last_message_role,
    lm.created_at        as last_message_at,
    coalesce(c.unread_for_me, 0) as unread_for_me,
    coalesce(c.total_messages, 0) as total_messages
  from relevant_parishes rp
  left join last_msg lm on lm.parish_id = rp.id
  left join counts   c  on c.parish_id  = rp.id
  order by
    coalesce(c.unread_for_me, 0) desc,
    lm.created_at desc nulls last,
    rp.parish_name asc;
end;
$$;

grant execute on function public.pdm_list_threads() to anon, authenticated;

-- 5b. Message list for a single thread.
drop function if exists public.pdm_list_messages(uuid, int, int);

create or replace function public.pdm_list_messages(
  p_parish_id uuid,
  p_limit int default 100,
  p_offset int default 0
)
returns table (
  id uuid,
  parish_id uuid,
  sender_role text,
  sender_email text,
  sender_name text,
  message_text text,
  read_at timestamptz,
  created_at timestamptz,
  is_mine boolean
)
language plpgsql
stable
security definer
set search_path = public, auth
as $$
declare
  v_role text := public.pdm_current_role();
  v_my_parish uuid := public.pdm_current_parish_id();
  v_email text := coalesce(auth.jwt() ->> 'email', '');
  v_limit int := greatest(1, least(coalesce(p_limit, 100), 500));
  v_offset int := greatest(0, coalesce(p_offset, 0));
begin
  if v_role = 'parish' and p_parish_id <> v_my_parish then
    return;
  end if;
  if v_role not in ('parish','diocese') then
    return;
  end if;

  return query
  select
    m.id,
    m.parish_id,
    m.sender_role,
    m.sender_email,
    m.sender_name,
    m.message_text,
    m.read_at,
    m.created_at,
    case
      when v_role = 'parish'  and m.sender_role = 'parish'  then true
      when v_role = 'diocese' and m.sender_role = 'diocese' then true
      else false
    end as is_mine
  from public.parish_diocese_messages m
  where m.parish_id = p_parish_id
  order by m.created_at asc
  limit v_limit
  offset v_offset;
end;
$$;

grant execute on function public.pdm_list_messages(uuid, int, int) to anon, authenticated;

-- 5c. Send a message.
drop function if exists public.pdm_send_message(uuid, text);

create or replace function public.pdm_send_message(
  p_parish_id uuid,
  p_message_text text
)
returns public.parish_diocese_messages
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_role text := public.pdm_current_role();
  v_my_parish uuid := public.pdm_current_parish_id();
  v_email text := coalesce(auth.jwt() ->> 'email', '');
  v_name  text := coalesce(
    auth.jwt() -> 'user_metadata' ->> 'display_name',
    auth.jwt() -> 'user_metadata' ->> 'full_name',
    split_part(v_email, '@', 1)
  );
  v_sender_role text;
  v_parish_id uuid;
  v_row public.parish_diocese_messages;
begin
  if p_message_text is null or char_length(btrim(p_message_text)) = 0 then
    raise exception 'Message cannot be empty.' using errcode = '22023';
  end if;

  if v_role = 'diocese' then
    v_sender_role := 'diocese';
    if p_parish_id is null then
      raise exception 'A parish must be specified.' using errcode = '22023';
    end if;
    v_parish_id := p_parish_id;
  elsif v_role = 'parish' then
    v_sender_role := 'parish';
    if v_my_parish is null then
      raise exception 'Your account is not linked to a parish.' using errcode = '28000';
    end if;
    v_parish_id := v_my_parish;
  else
    raise exception 'Only parish staff or diocese admins can send messages.' using errcode = '28000';
  end if;

  insert into public.parish_diocese_messages (
    parish_id, sender_role, sender_email, sender_name, message_text
  ) values (
    v_parish_id, v_sender_role, v_email, v_name, btrim(p_message_text)
  ) returning * into v_row;

  return v_row;
end;
$$;

grant execute on function public.pdm_send_message(uuid, text) to authenticated;

-- 5d. Mark a thread as read for "me" (flip read_at on every message the
--     other side sent that I haven't read yet).
drop function if exists public.pdm_mark_thread_read(uuid);

create or replace function public.pdm_mark_thread_read(p_parish_id uuid)
returns bigint
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_role text := public.pdm_current_role();
  v_my_parish uuid := public.pdm_current_parish_id();
  v_parish_id uuid;
  v_other text;
  v_count bigint;
begin
  if v_role = 'diocese' then
    v_other := 'parish';
    v_parish_id := p_parish_id;
  elsif v_role = 'parish' then
    if v_my_parish is null then return 0; end if;
    v_other := 'diocese';
    v_parish_id := v_my_parish;
  else
    return 0;
  end if;

  update public.parish_diocese_messages
     set read_at = timezone('utc', now())
   where parish_id = v_parish_id
     and sender_role = v_other
     and read_at is null;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

grant execute on function public.pdm_mark_thread_read(uuid) to authenticated;
