#!/usr/bin/env bash

# Grant privileges to the local PostgreSQL user for BeeCore schemas.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

if [ -f "${PROJECT_ROOT}/local/.env" ]; then
  set -a
  source "${PROJECT_ROOT}/local/.env"
  set +a
elif [ -f "${PROJECT_ROOT}/.env" ]; then
  set -a
  source "${PROJECT_ROOT}/.env"
  set +a
fi

LOCAL_PG_CONTAINER="${LOCAL_PG_CONTAINER:-beecore-postgres}"

echo "Granting privileges on database '${LOCAL_DB}' to user '${LOCAL_DB_USER}'..."

docker exec -e PGPASSWORD="${LOCAL_DB_PASSWD}" "${LOCAL_PG_CONTAINER}" psql -U "${LOCAL_DB_USER}" -h localhost -d "${LOCAL_DB}" -c "
-- Grant schema-level privileges
GRANT ALL ON SCHEMA public TO \"${LOCAL_DB_USER}\";
GRANT ALL ON SCHEMA baskets TO \"${LOCAL_DB_USER}\";
GRANT ALL ON SCHEMA users TO \"${LOCAL_DB_USER}\";
GRANT ALL ON SCHEMA notifications TO \"${LOCAL_DB_USER}\";
GRANT ALL ON SCHEMA ordering TO \"${LOCAL_DB_USER}\";
GRANT ALL ON SCHEMA payments TO \"${LOCAL_DB_USER}\";
GRANT ALL ON SCHEMA stores TO \"${LOCAL_DB_USER}\";

-- Grant default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA baskets GRANT ALL ON TABLES TO \"${LOCAL_DB_USER}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA baskets GRANT ALL ON SEQUENCES TO \"${LOCAL_DB_USER}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA users GRANT ALL ON TABLES TO \"${LOCAL_DB_USER}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA users GRANT ALL ON SEQUENCES TO \"${LOCAL_DB_USER}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA notifications GRANT ALL ON TABLES TO \"${LOCAL_DB_USER}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA notifications GRANT ALL ON SEQUENCES TO \"${LOCAL_DB_USER}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA ordering GRANT ALL ON TABLES TO \"${LOCAL_DB_USER}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA ordering GRANT ALL ON SEQUENCES TO \"${LOCAL_DB_USER}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA payments GRANT ALL ON TABLES TO \"${LOCAL_DB_USER}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA payments GRANT ALL ON SEQUENCES TO \"${LOCAL_DB_USER}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA stores GRANT ALL ON TABLES TO \"${LOCAL_DB_USER}\";
ALTER DEFAULT PRIVILEGES IN SCHEMA stores GRANT ALL ON SEQUENCES TO \"${LOCAL_DB_USER}\";
"

echo ""
echo "Privileges granted successfully to '${LOCAL_DB_USER}'!"