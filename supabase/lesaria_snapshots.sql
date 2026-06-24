drop table if exists public.lesaria_snapshots;

create table public.lesaria_snapshots (
    user_id uuid primary key references auth.users(id) on delete cascade,
    payload jsonb not null,
    device_id text,
    updated_at timestamptz not null default now()
);

create or replace function public.set_lesaria_snapshots_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger set_lesaria_snapshots_updated_at
before update on public.lesaria_snapshots
for each row
execute function public.set_lesaria_snapshots_updated_at();

alter table public.lesaria_snapshots enable row level security;

grant select, insert, update on public.lesaria_snapshots to authenticated;

create policy "Lesaria snapshots are readable by owner"
on public.lesaria_snapshots
for select
to authenticated
using (auth.uid() = user_id);

create policy "Lesaria snapshots are insertable by owner"
on public.lesaria_snapshots
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "Lesaria snapshots are updateable by owner"
on public.lesaria_snapshots
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
