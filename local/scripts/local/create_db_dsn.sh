#!/usr/bin/env bash

# Initialize PostgreSQL database, user, and schemas using DSN connection format.
# This script should be run after PostgreSQL is up and running.

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

echo "Creating database and user..."
echo "DSN: ${LOCAL_DB_DSN}"
echo ""

docker exec -e PGPASSWORD="${LOCAL_DB_PASSWD}" "${LOCAL_PG_CONTAINER}" psql -U "${LOCAL_DB_USER}" -h localhost -d postgres -c "
CREATE DATABASE \"${LOCAL_DB}\";
" 2>/dev/null || echo "Database '${LOCAL_DB}' may already exist, continuing..."

echo "Creating schemas and setting permissions..."
docker exec -e PGPASSWORD="${LOCAL_DB_PASSWD}" "${LOCAL_PG_CONTAINER}" psql -U "${LOCAL_DB_USER}" -h localhost -d "${LOCAL_DB}" -c "
CREATE SCHEMA IF NOT EXISTS baskets;
CREATE SCHEMA IF NOT EXISTS users;
CREATE SCHEMA IF NOT EXISTS notifications;
CREATE SCHEMA IF NOT EXISTS ordering;
CREATE SCHEMA IF NOT EXISTS payments;
CREATE SCHEMA IF NOT EXISTS stores;
"

echo ""
echo "PostgreSQL initialized successfully!"
echo ""
echo "Database: ${LOCAL_DB}"
echo "User: ${LOCAL_DB_USER}"
echo ""
echo "Schemas created:"
echo "  - baskets"
echo "  - users"
echo "  - notifications"
echo "  - ordering"
echo "  - payments"
echo "  - stores"
echo ""
echo "Next steps:"
echo "  1. Run migrations: make migrations/local/up"
echo "  2. Seed database: ./local/scripts/local/seed_db.sh"