#!/usr/bin/env bash

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

echo "Preparing to drop local database..."
echo "Host: ${LOCAL_DB_HOST}:${LOCAL_DB_PORT}"
echo "Database: ${LOCAL_DB}"
echo "User: ${LOCAL_DB_USER}"
echo ""
echo "WARNING: This will permanently drop database '${LOCAL_DB}'."
read -r -p "Type 'yes' to continue: " confirmation

if [ "${confirmation}" != "yes" ]; then
  echo "Operation cancelled."
  exit 0
fi

echo "Dropping database..."

docker exec -e PGPASSWORD="${LOCAL_DB_PASSWD}" "${LOCAL_PG_CONTAINER}" psql -U "${LOCAL_DB_USER}" -h localhost -d postgres -c "
DROP DATABASE IF EXISTS \"${LOCAL_DB}\" WITH (FORCE);
"

echo ""
echo "Drop completed successfully."
echo "Database '${LOCAL_DB}' was removed."