-- Relational switch port registry.
create table if not exists public.network_switch_ports (
  id text primary key,
  switch_id text not null references public.network_switches(id) on delete cascade,
  port_number integer not null check (port_number > 0),
  point_number text,
  office_location text,
  device_id text references public.devices(id) on delete set null,
  connected_device_label text,
  notes text,
  created_at timestamptz not null default now(),
  constraint network_switch_ports_switch_port_unique unique (switch_id, port_number)
);
create unique index if not exists network_switch_ports_device_unique
  on public.network_switch_ports(device_id) where device_id is not null;
alter table public.network_switch_ports enable row level security;
grant select, insert, update, delete on public.network_switch_ports to authenticated;
revoke all on public.network_switch_ports from anon;
drop policy if exists network_switch_ports_member_read on public.network_switch_ports;
create policy network_switch_ports_member_read on public.network_switch_ports for select to authenticated
using ((select public.current_app_role()) in ('primary_admin','admin','operator','viewer'));
drop policy if exists network_switch_ports_admin_insert on public.network_switch_ports;
create policy network_switch_ports_admin_insert on public.network_switch_ports for insert to authenticated
with check ((select public.is_app_admin()));
drop policy if exists network_switch_ports_admin_update on public.network_switch_ports;
create policy network_switch_ports_admin_update on public.network_switch_ports for update to authenticated
using ((select public.is_app_admin())) with check ((select public.is_app_admin()));
drop policy if exists network_switch_ports_admin_delete on public.network_switch_ports;
create policy network_switch_ports_admin_delete on public.network_switch_ports for delete to authenticated
using ((select public.is_app_admin()));
insert into public.network_switch_ports
(id, switch_id, port_number, point_number, office_location, connected_device_label, notes)
select 'swp_' || md5(s.id || ':' || (m.value->>'portNumber')), s.id,
(m.value->>'portNumber')::integer, nullif(m.value->>'pointNumber',''),
nullif(m.value->>'officeLocation',''), nullif(m.value->>'connectedDevice',''),
nullif(m.value->>'notes','')
from public.network_switches s
cross join lateral jsonb_array_elements(case when jsonb_typeof(s.data->'portMappings')='array' then s.data->'portMappings' else '[]'::jsonb end) m(value)
where coalesce(m.value->>'portNumber','') ~ '^[1-9][0-9]*$'
on conflict (switch_id,port_number) do update set point_number=excluded.point_number,
office_location=excluded.office_location,connected_device_label=excluded.connected_device_label,notes=excluded.notes;
comment on table public.network_switch_ports is 'Relational switch port registry with optional device references.';