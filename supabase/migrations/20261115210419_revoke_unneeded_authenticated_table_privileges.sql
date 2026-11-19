-- Remove privileges that are not needed by the Flutter Data API client.
-- RLS does not constrain TRUNCATE, so it must not be granted to app users.
DO $$
DECLARE
  v_table record;
BEGIN
  FOR v_table IN
    SELECT schemaname, tablename
    FROM pg_tables
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format(
      'REVOKE TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE %I.%I FROM authenticated',
      v_table.schemaname,
      v_table.tablename
    );
  END LOOP;
END;
$$;

-- Prevent the postgres migration owner from reintroducing these privileges
-- on future public tables. Keep SELECT/INSERT/UPDATE/DELETE unchanged.
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLES FROM authenticated;
