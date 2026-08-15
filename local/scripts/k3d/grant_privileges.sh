#!/usr/bin/env bash

# k3d equivalent of local/scripts/local/grant_privileges.sh. Mostly a no-op
# in practice here — migrations run as LOCAL_DB_USER directly (not a
# separate admin role), so it already owns everything it created — but kept
# for parity with the documented local setup and as a safety net if that
# ever changes.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${PROJECT_ROOT}/local/k3d.env"

echo "Granting privileges on database '${LOCAL_DB}' to user '${LOCAL_DB_USER}' (k3d: ${K3D_CONTEXT}/${K3D_NAMESPACE})..."

kubectl --context "${K3D_CONTEXT}" -n "${K3D_NAMESPACE}" exec "deploy/${K3D_DEPLOYMENT}" -- \
  psql -U "${LOCAL_DB_USER}" -d "${LOCAL_DB}" -c "
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
