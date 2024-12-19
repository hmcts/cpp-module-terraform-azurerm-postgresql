%{~ for group in groups ~}
-- Creating all the required roles for AAD Admin groups
DO
$do$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_catalog.pg_roles WHERE rolname = '${group}') THEN
      PERFORM * from pgaadauth_create_principal('${group}', false, false);
  END IF;
END
$do$;

-- Full admin privileges (read/write) on tables and sequences only:
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${group};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${group};

-- Ensure future tables and sequences get the same privileges:
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO ${group};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO ${group};

-- Set pgaudit log level to groups:
ALTER ROLE ${group} SET pgaudit.log = 'all';

%{~ endfor ~}
