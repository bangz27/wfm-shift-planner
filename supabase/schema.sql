-- WFM Shift Planner — Supabase schema
-- รันไฟล์นี้ 1 ครั้งใน Supabase Dashboard > SQL Editor

create table if not exists public.wfm_planner (
  id          uuid primary key default gen_random_uuid(),
  owner       uuid not null default auth.uid() references auth.users (id) on delete cascade,
  hub         text not null default 'ABBTG-A',
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now(),
  created_at  timestamptz not null default now(),
  unique (owner, hub)
);

-- ข้อมูลพนักงานเป็นข้อมูลส่วนบุคคล: เปิด RLS ให้แต่ละบัญชีเห็นเฉพาะข้อมูลของตัวเอง
alter table public.wfm_planner enable row level security;

drop policy if exists "owner can select" on public.wfm_planner;
drop policy if exists "owner can insert" on public.wfm_planner;
drop policy if exists "owner can update" on public.wfm_planner;
drop policy if exists "owner can delete" on public.wfm_planner;

create policy "owner can select" on public.wfm_planner
  for select to authenticated using ((select auth.uid()) = owner);
create policy "owner can insert" on public.wfm_planner
  for insert to authenticated with check ((select auth.uid()) = owner);
create policy "owner can update" on public.wfm_planner
  for update to authenticated using ((select auth.uid()) = owner) with check ((select auth.uid()) = owner);
create policy "owner can delete" on public.wfm_planner
  for delete to authenticated using ((select auth.uid()) = owner);

-- ไม่ให้ผู้ใช้ที่ยังไม่ล็อกอิน (anon) เข้าถึงตารางเลย
revoke all on public.wfm_planner from anon;
revoke truncate, references, trigger on public.wfm_planner from authenticated;
grant select, insert, update, delete on public.wfm_planner to authenticated;

-- ---------------------------------------------------------------
-- จำกัดการสมัครเฉพาะอีเมลบริษัท (+ รายชื่อยกเว้นใน wfm_signup_allowlist)
-- ---------------------------------------------------------------
create table if not exists public.wfm_signup_allowlist (
  email text primary key,
  note text,
  created_at timestamptz not null default now()
);
alter table public.wfm_signup_allowlist enable row level security;
revoke all on public.wfm_signup_allowlist from anon, authenticated;

create or replace function public.wfm_check_signup_email()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  em text := lower(coalesce(new.email, ''));
begin
  if split_part(em, '@', 2) in ('spxexpress.com', 'shopee.com')
     or exists (select 1 from public.wfm_signup_allowlist a where lower(a.email) = em) then
    return new;
  end if;
  raise exception 'สมัครได้เฉพาะอีเมล @spxexpress.com หรือ @shopee.com' using errcode = 'P0001';
end;
$$;
revoke execute on function public.wfm_check_signup_email() from public, anon, authenticated;

drop trigger if exists wfm_check_signup_email on auth.users;
create trigger wfm_check_signup_email
  before insert on auth.users
  for each row execute function public.wfm_check_signup_email();
