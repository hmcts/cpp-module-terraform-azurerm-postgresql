%{~ for group in groups ~}
-- Acquire locks to prevent concurrent updates
BEGIN;
LOCK TABLE pg_roles IN ACCESS EXCLUSIVE MODE;
LOCK TABLE pg_default_acl IN ACCESS EXCLUSIVE MODE;
--creating all the required roles for AAD groups
DO
$do$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_catalog.pg_roles WHERE  rolname = '${group}') THEN
      PERFORM * from pgaadauth_create_principal('${group}', false, false);
  END IF;
END
$do$;

---read_insert_update:
grant select, insert, update on all tables in schema public to ${group};
alter default privileges in schema public grant select, insert, update on tables to ${group};
alter default privileges in schema public grant usage, select on sequences to ${group};

-- Set pgaudit log level to groups:
ALTER ROLE ${group} SET pgaudit.log = 'all';
COMMIT;
 %{~ endfor ~}
