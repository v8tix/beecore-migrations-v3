#!/usr/bin/env bash

# k3d equivalent of local/scripts/local/create_db.sh — the postgres/v18 chart
# already provisions the database via POSTGRES_DB at first init, so this is
# mainly the schema-creation step (idempotent either way).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${PROJECT_ROOT}/local/k3d.env"

KEXEC=(kubectl --context "${K3D_CONTEXT}" -n "${K3D_NAMESPACE}" exec "deploy/${K3D_DEPLOYMENT}" --)

echo "Creating database (if needed)..."
"${KEXEC[@]}" psql -U "${LOCAL_DB_USER}" -d postgres -c "
CREATE DATABASE \"${LOCAL_DB}\";
" 2>/dev/null || echo "Database '${LOCAL_DB}' may already exist, continuing..."

echo "Creating schemas..."
"${KEXEC[@]}" psql -U "${LOCAL_DB_USER}" -d "${LOCAL_DB}" -c "
CREATE SCHEMA IF NOT EXISTS baskets;
CREATE SCHEMA IF NOT EXISTS users;
CREATE SCHEMA IF NOT EXISTS notifications;
CREATE SCHEMA IF NOT EXISTS ordering;
CREATE SCHEMA IF NOT EXISTS payments;
CREATE SCHEMA IF NOT EXISTS stores;
"

echo ""
echo "PostgreSQL (k3d) initialized successfully!"
echo "Database: ${LOCAL_DB} | User: ${LOCAL_DB_USER} | Context: ${K3D_CONTEXT}"
