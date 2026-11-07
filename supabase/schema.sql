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
