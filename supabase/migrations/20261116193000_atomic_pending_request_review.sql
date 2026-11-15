-- Review a pending operational request and apply its change atomically.
-- SECURITY INVOKER preserves the caller's RLS checks on request and target tables.
create or replace function public.review_pending_request(
  p_request_id text,
  p_decision text,
  p_rejection_reason text default null,
  p_encoded_payload jsonb default '{}'::jsonb,
  p_raw_payload jsonb default '{}'::jsonb
)
returns void
language plpgsql
security invoker
set search_path = ''
as $function$
declare
  v_request public.pending_requests%rowtype;
  v_table text;
  v_id text;
  v_assignments text;
  v_ports jsonb;
  v_affected integer;
  v_email text := coalesce(auth.jwt() ->> 'email', '');
begin
  if auth.uid() is null or not public.is_app_admin() then
    raise exception 'صلاحية مدير النظام مطلوبة';
  end if;
  if p_decision is null or p_decision not in ('approved', 'rejected') then
    raise exception 'قرار مراجعة الطلب غير صالح';
  end if;

  select * into v_request
    from public.pending_requests
   where id = p_request_id
   for update;
  if not found then
    raise exception 'طلب الاعتماد غير موجود';
  end if;
  if v_request.status is distinct from 'pending' then
    raise exception 'تمت مراجعة هذا الطلب مسبقاً';
  end if;

  if p_decision = 'rejected' then
    update public.pending_requests
       set status = 'rejected', reviewed_at = now(), reviewed_by = v_email,
           rejection_reason = nullif(btrim(coalesce(p_rejection_reason, '')), '')
     where id = p_request_id;
    insert into public.audit_logs
      (id, action, entity, entity_id, user_name, user_email, timestamp, details, data)
    values
      ('log_' || replace(gen_random_uuid()::text, '-', ''),
       'رفض طلب: ' || coalesce(v_request.title, ''),
       'pending_requests', p_request_id, v_email, v_email, now(),
       coalesce(nullif(btrim(coalesce(p_rejection_reason, '')), ''), v_request.details, ''),
       jsonb_build_object('request_id', p_request_id, 'decision', 'rejected'));
    return;
  end if;

  v_table := v_request.target_collection;
  if v_table is null or v_table not in (
    'devices', 'custody_cards', 'movements', 'maintenance_tickets',
    'phone_directory', 'telecom_networks', 'network_switches'
  ) then
    raise exception 'جدول الطلب غير مسموح: %', coalesce(v_table, 'NULL');
  end if;

  if p_raw_payload is distinct from v_request.payload then
    raise exception 'البيانات المرسلة لا تطابق محتوى طلب الاعتماد';
  end if;
  if v_request.target_doc_id is not null
     and v_request.payload ? 'id'
     and v_request.target_doc_id <> v_request.payload ->> 'id' then
    raise exception 'معرّف السجل لا يطابق الطلب الأصلي';
  end if;

  v_id := coalesce(v_request.target_doc_id, v_request.payload ->> 'id');
  if v_id is null or v_id = '' then
    raise exception 'معرّف السجل المطلوب غير موجود';
  end if;

  if left(coalesce(v_request.action_type, ''), 6) = 'delete' then
    execute format('delete from public.%I where id = $1', v_table) using v_id;
    get diagnostics v_affected = row_count;
    if v_affected = 0 then
      raise exception 'السجل المطلوب حذفه غير موجود';
    end if;
  elsif v_table = 'network_switches' then
    if jsonb_typeof(coalesce(p_raw_payload -> 'portMappings', '[]'::jsonb)) <> 'array' then
      raise exception 'قائمة منافذ السويتش غير صالحة';
    end if;
    select coalesce(
      jsonb_agg(jsonb_build_object(
        'id', coalesce(nullif(m.value ->> 'id', ''),
                      'swp_' || v_id || '_' || coalesce(m.value ->> 'portNumber', '')),
        'port_number', nullif(m.value ->> 'portNumber', '')::integer,
        'point_number', coalesce(m.value ->> 'pointNumber', ''),
        'office_location', coalesce(m.value ->> 'officeLocation', ''),
        'device_id', nullif(btrim(coalesce(m.value ->> 'deviceId', '')), ''),
        'connected_device_label', coalesce(m.value ->> 'connectedDevice', ''),
        'notes', coalesce(m.value ->> 'notes', '')
      )),
      '[]'::jsonb
    ) into v_ports
      from jsonb_array_elements(coalesce(p_raw_payload -> 'portMappings', '[]'::jsonb)) as m(value);

    if coalesce(p_encoded_payload ->> 'id', '') <> v_id then
      raise exception 'معرّف السويتش لا يطابق الطلب';
    end if;
    perform public.save_network_switch_with_ports(p_encoded_payload, v_ports);
  else
    if jsonb_typeof(p_encoded_payload) <> 'object'
       or coalesce(p_encoded_payload ->> 'id', '') <> v_id
       or p_encoded_payload -> 'data' is distinct from (v_request.payload - 'id' - 'portMappings') then
      raise exception 'بيانات السجل أو معرّفه غير صالحة';
    end if;
    select string_agg(
      format(
        '%1$I = CASE WHEN $1 ? %2$L THEN EXCLUDED.%1$I ELSE existing.%1$I END',
        a.attname, a.attname
      ),
      ', ' order by a.attnum
    ) into v_assignments
      from pg_attribute a
     where a.attrelid = to_regclass(format('public.%I', v_table))
       and a.attnum > 0 and not a.attisdropped
       and a.attname <> 'id' and a.attgenerated = '';
    if v_assignments is null then
      raise exception 'تعذر تحديد أعمدة الجدول المستهدف';
    end if;
    execute format(
      'insert into public.%1$I as existing ' ||
      'select (jsonb_populate_record(null::public.%1$I, $1)).* ' ||
      'on conflict (id) do update set %2$s',
      v_table, v_assignments
    ) using p_encoded_payload;
  end if;

  update public.pending_requests
     set status = 'approved', reviewed_at = now(), reviewed_by = v_email,
         rejection_reason = null
   where id = p_request_id;
  insert into public.audit_logs
    (id, action, entity, entity_id, user_name, user_email, timestamp, details, data)
  values
    ('log_' || replace(gen_random_uuid()::text, '-', ''),
     'اعتماد: ' || coalesce(v_request.title, ''),
     v_table, v_id, v_email, v_email, now(),
     coalesce(v_request.details, ''),
     jsonb_build_object('request_id', p_request_id, 'decision', 'approved'));
end;
$function$;

revoke all on function public.review_pending_request(text, text, text, jsonb, jsonb) from public;
revoke all on function public.review_pending_request(text, text, text, jsonb, jsonb) from anon;
grant execute on function public.review_pending_request(text, text, text, jsonb, jsonb) to authenticated;
