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

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO PUBLIC;
REVOKE CREATE ON SCHEMA public FROM public;
GRANT USAGE ON SCHEMA public to ${group};
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ${group};

 %{~ endfor ~}
