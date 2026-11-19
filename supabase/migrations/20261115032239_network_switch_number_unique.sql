-- Enforce case-insensitive uniqueness for registered network switch numbers.
create unique index if not exists network_switches_switch_number_unique
  on public.network_switches (lower(btrim(switch_number)))
  where switch_number is not null and btrim(switch_number) <> '';
