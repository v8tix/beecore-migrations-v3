#!/usr/bin/env bash

# Production equivalent of local/scripts/k3d/create_db.sh — the
# postgres/v18 chart already provisions the database via POSTGRES_DB at
# first init, so this is mainly the schema-creation step (idempotent
# either way).
#
# Runs via a SQL file scp'd to the server and piped into `psql -f`, rather
# than `psql -c "<multi-line SQL>"` over a plain `ssh host cmd...` — SSH
# joins trailing argv into one remote command string, which loses the local
# shell's quoting around multi-line SQL and breaks `-c`'s argument parsing.
# A file sidesteps that entirely. No tunnel needed for this one-off step,
# unlike the migrate-based targets.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

set -a
source "${PROJECT_ROOT}/local/prod.env"
set +a

SSH_KEY="${PROD_SSH_KEY/#\~/$HOME}"
SSH="ssh -i ${SSH_KEY} -o ConnectTimeout=10 ${PROD_SSH_HOST}"
REMOTE_TMP="/tmp/beecore-migrations-prod-setup.sql"

cleanup() {
  ${SSH} "rm -f ${REMOTE_TMP}" 2>/dev/null || true
}
trap cleanup EXIT

echo "Creating database (if needed)..."
cat > /tmp/prod_create_db.sql << EOF
CREATE DATABASE "${PROD_DB}";
EOF
scp -i "${SSH_KEY}" -q /tmp/prod_create_db.sql "${PROD_SSH_HOST}:${REMOTE_TMP}"
POD="$(${SSH} "microk8s kubectl -n postgres-standalone get pod -l app.kubernetes.io/name=postgres-standalone -o jsonpath='{.items[0].metadata.name}'")"
${SSH} "microk8s kubectl -n postgres-standalone cp ${REMOTE_TMP} ${POD}:${REMOTE_TMP}"
${SSH} "microk8s kubectl -n postgres-standalone exec deploy/postgres-standalone -- psql -U ${PROD_DB_USER} -d postgres -f ${REMOTE_TMP}" \
  2>/dev/null || echo "Database '${PROD_DB}' may already exist, continuing..."
rm -f /tmp/prod_create_db.sql

echo "Creating schemas..."
cat > /tmp/prod_create_schemas.sql << EOF
CREATE SCHEMA IF NOT EXISTS baskets;
CREATE SCHEMA IF NOT EXISTS users;
CREATE SCHEMA IF NOT EXISTS notifications;
CREATE SCHEMA IF NOT EXISTS ordering;
CREATE SCHEMA IF NOT EXISTS payments;
CREATE SCHEMA IF NOT EXISTS stores;
EOF
scp -i "${SSH_KEY}" -q /tmp/prod_create_schemas.sql "${PROD_SSH_HOST}:${REMOTE_TMP}"
${SSH} "microk8s kubectl -n postgres-standalone cp ${REMOTE_TMP} ${POD}:${REMOTE_TMP}"
${SSH} "microk8s kubectl -n postgres-standalone exec deploy/postgres-standalone -- psql -U ${PROD_DB_USER} -d ${PROD_DB} -f ${REMOTE_TMP}"
rm -f /tmp/prod_create_schemas.sql

echo ""
echo "PostgreSQL (production) initialized successfully!"
echo "Database: ${PROD_DB} | User: ${PROD_DB_USER} | Host: ${PROD_SSH_HOST}"
