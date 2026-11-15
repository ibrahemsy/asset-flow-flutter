create or replace function public.save_network_switch_with_ports(
  p_switch jsonb,
  p_ports jsonb
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id text;
  v_ports_count integer;
  v_count integer;
begin
  if auth.uid() is null or not public.is_app_admin() then
    raise exception 'صلاحية مدير النظام مطلوبة';
  end if;
  if jsonb_typeof(p_switch) <> 'object' or jsonb_typeof(p_ports) <> 'array' then
    raise exception 'بيانات السويتش أو المنافذ غير صالحة';
  end if;
  v_id := nullif(p_switch->>'id', '');
  if v_id is null then raise exception 'معرّف السويتش مطلوب'; end if;
  if coalesce(p_switch->>'ports_count','') !~ '^[1-9][0-9]*$' then
    raise exception 'عدد منافذ السويتش غير صالح';
  end if;
  v_ports_count := (p_switch->>'ports_count')::integer;
  select count(*) into v_count from jsonb_to_recordset(p_ports) as p(port_number integer, device_id text);
  if v_count <> jsonb_array_length(p_ports) then raise exception 'تعذر قراءة قائمة المنافذ'; end if;
  if exists (select 1 from jsonb_to_recordset(p_ports) as p(port_number integer, device_id text)
    where p.port_number is null or p.port_number < 1 or p.port_number > v_ports_count) then
    raise exception 'رقم منفذ خارج نطاق السويتش';
  end if;
  if (select count(*) from jsonb_to_recordset(p_ports) as p(port_number integer, device_id text))
    <> (select count(distinct p.port_number) from jsonb_to_recordset(p_ports) as p(port_number integer, device_id text)) then
    raise exception 'أرقام المنافذ مكررة';
  end if;
  if exists (select 1 from jsonb_to_recordset(p_ports) as p(port_number integer, device_id text)
    where p.device_id is not null and not exists (select 1 from public.devices d where d.id = p.device_id)) then
    raise exception 'يوجد جهاز غير مسجل في سجل الأصول';
  end if;
  if (select count(*) from jsonb_to_recordset(p_ports) as p(port_number integer, device_id text) where p.device_id is not null)
    <> (select count(distinct p.device_id) from jsonb_to_recordset(p_ports) as p(port_number integer, device_id text) where p.device_id is not null) then
    raise exception 'لا يمكن ربط الجهاز نفسه بأكثر من منفذ';
  end if;
  insert into public.network_switches
    (id, switch_number, name, model, location, ports_count, status, notes, data)
  values (v_id, p_switch->>'switch_number', p_switch->>'name', p_switch->>'model',
    p_switch->>'location', p_switch->>'ports_count', p_switch->>'status',
    p_switch->>'notes', coalesce(p_switch->'data','{}'::jsonb))
  on conflict (id) do update set switch_number=excluded.switch_number, name=excluded.name,
    model=excluded.model, location=excluded.location, ports_count=excluded.ports_count,
    status=excluded.status, notes=excluded.notes, data=excluded.data;
  delete from public.network_switch_ports where switch_id=v_id;
  insert into public.network_switch_ports
    (id, switch_id, port_number, point_number, office_location, device_id, connected_device_label, notes)
  select coalesce(nullif(p.id,''), 'swp_' || md5(v_id || ':' || p.port_number::text)),
    v_id, p.port_number, p.point_number, p.office_location, p.device_id, p.connected_device_label, p.notes
  from jsonb_to_recordset(p_ports) as p(
    id text, port_number integer, point_number text, office_location text,
    device_id text, connected_device_label text, notes text
  );
end;
$$;
revoke all on function public.save_network_switch_with_ports(jsonb,jsonb) from public, anon;
grant execute on function public.save_network_switch_with_ports(jsonb,jsonb) to authenticated;

drop function if exists private.save_network_switch_with_ports(jsonb,jsonb);
revoke usage on schema private from authenticated;
