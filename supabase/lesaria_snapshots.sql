create table if not exists public.lesaria_snapshots (
    id text primary key,
    payload jsonb not null,
    device_id text,
    sync_token text not null,
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

drop trigger if exists set_lesaria_snapshots_updated_at on public.lesaria_snapshots;

create trigger set_lesaria_snapshots_updated_at
before update on public.lesaria_snapshots
for each row
execute function public.set_lesaria_snapshots_updated_at();

alter table public.lesaria_snapshots enable row level security;

grant select, insert, update on public.lesaria_snapshots to anon;

drop policy if exists "Lesaria snapshots select with sync token" on public.lesaria_snapshots;
drop policy if exists "Lesaria snapshots insert with sync token" on public.lesaria_snapshots;
drop policy if exists "Lesaria snapshots update with sync token" on public.lesaria_snapshots;

create policy "Lesaria snapshots select with sync token"
on public.lesaria_snapshots
for select
to anon
using (
    sync_token = coalesce(
        nullif(nullif(current_setting('request.headers', true), '')::json ->> 'x-lesaria-sync-token', ''),
        '__missing__'
    )
);

create policy "Lesaria snapshots insert with sync token"
on public.lesaria_snapshots
for insert
to anon
with check (
    sync_token = coalesce(
        nullif(nullif(current_setting('request.headers', true), '')::json ->> 'x-lesaria-sync-token', ''),
        '__missing__'
    )
);

create policy "Lesaria snapshots update with sync token"
on public.lesaria_snapshots
for update
to anon
using (
    sync_token = coalesce(
        nullif(nullif(current_setting('request.headers', true), '')::json ->> 'x-lesaria-sync-token', ''),
        '__missing__'
    )
)
with check (
    sync_token = coalesce(
        nullif(nullif(current_setting('request.headers', true), '')::json ->> 'x-lesaria-sync-token', ''),
        '__missing__'
    )
);
