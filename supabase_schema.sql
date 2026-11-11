-- ============================================================
-- جداول Asset Flow على Supabase
-- نفّذ هذا الملف من SQL Editor في لوحة Supabase
-- ============================================================

-- الأجهزة
create table if not exists devices (
  id text primary key,
  data jsonb default '{}'::jsonb,
  name text,
  category text,
  manufacturer text,
  model text,
  serial_number text,
  barcode text,
  asset_number text,
  condition text,
  status text,
  location text,
  assigned_employee text,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- بطاقات العهدة
create table if not exists custody_cards (
  id text primary key,
  card_number text,
  employee_name text,
  national_id text,
  job_title text,
  department text,
  division text,
  office_or_center text,
  creation_date text,
  items jsonb default '[]'::jsonb,
  status text default 'active',
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_custody_national_id on custody_cards (national_id);

-- الحركات
create table if not exists movements (
  id text primary key,
  reference_number text,
  type text,
  device_id text,
  device_name text,
  serial_number text,
  from_entity text,
  to_entity text,
  executor_name text,
  date text,
  reason text,
  notes text,
  created_at timestamptz default now()
);

-- بلاغات الصيانة
create table if not exists maintenance_tickets (
  id text primary key,
  ticket_number text,
  device_name text,
  serial_number text,
  fault_description text,
  station_or_dept text,
  report_date text,
  priority text,
  assigned_tech text,
  actions_taken text,
  spare_parts_used text,
  status text,
  created_at timestamptz default now()
);

-- دليل الهواتف
create table if not exists phone_directory (
  id text primary key,
  phone_number text,
  employee_name text,
  department text,
  office_location text,
  pbx_port_number text,
  point_number text,
  status text default 'active',
  notes text
);

-- الشبكات
create table if not exists telecom_networks (
  id text primary key,
  name text,
  type text,
  ip_range text,
  gateway text,
  bandwidth text,
  frequency text,
  location text,
  status text default 'active',
  notes text
);

-- سجل التدقيق
create table if not exists audit_logs (
  id text primary key,
  action text,
  entity text,
  entity_id text,
  user_name text,
  user_email text,
  timestamp timestamptz default now(),
  details text
);

-- طلبات الاعتماد (للفنيين — يعتمد النظام يعتمدها)
create table if not exists pending_requests (
  id text primary key,
  action_type text,
  title text,
  details text,
  requester_uid text,
  requester_email text,
  requester_name text,
  payload jsonb default '{}'::jsonb,
  target_collection text,
  target_doc_id text,
  status text default 'pending',
  created_at timestamptz default now(),
  reviewed_at timestamptz,
  reviewed_by text,
  rejection_reason text
);

-- ملاحظة: للتخزين الكامل لنماذج Flutter يمكن حفظ الصف كاملاً في عمود jsonb
-- أو مطابقة الحقول واحداً بواحد. الخدمة الحالية تستخدم upsert بالـ payload كاملاً
-- لذا يُفضّل إضافة الأعمدة الناقصة أو استخدام جدول مرن:

-- بديل مبسّط (اختياري): جدول عام لكل كيان
-- create table app_docs (
--   collection text not null,
--   id text not null,
--   data jsonb not null default '{}',
--   primary key (collection, id)
-- );
