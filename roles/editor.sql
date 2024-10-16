%{~ for group in groups ~}
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

--read only:
grant select, insert, update, delete, create on all tables in schema public to ${group};
grant usage, select, update on all sequences in schema public to ${group};
alter default privileges in schema public grant select, insert, update, delete, create on tables to ${group};
alter default privileges in schema public grant usage, select, update on sequences to ${group};
 %{~ endfor ~}