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

ALTER ROLE ${group} NOINHERIT;

--REVOKE CREATE ON SCHEMA public FROM public;
REVOKE ALL PRIVILEGES ON SCHEMA public FROM ${group};
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM ${group};
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM ${group};

GRANT SELECT ON ALL TABLES IN SCHEMA public TO ${group};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO ${group};

-- Set pgaudit log level to groups:
ALTER ROLE ${group} SET pgaudit.log = 'all';


 %{~ endfor ~}
