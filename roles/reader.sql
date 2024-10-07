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

REVOKE ALL PRIVILEGES ON SCHEMA public FROM ${group};
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM ${group};
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM ${group};
REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public FROM ${group};
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL PRIVILEGES FROM ${group};

GRANT SELECT ON ALL TABLES IN SCHEMA public TO ${group};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO ${group};

 %{~ endfor ~}
