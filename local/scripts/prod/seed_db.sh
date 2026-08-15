#!/usr/bin/env bash

# Production seed — structurally the same as local/scripts/k3d/seed_db.sh
# (same roles/permissions reference data, not secret), but deliberately
# DIFFERENT for the admin user itself:
#   - fresh UUID (../../uuid-generator), not dev's 6c21a2ef-...
#   - info@v8tix.com, not dev's malmeidap@hotmail.com test address
#   - a freshly-generated Argon2id password hash, NOT dev's hash — reusing
#     dev's hash would mean dev's admin password also unlocks prod
#
# Uses the scp'd-file approach (see create_db.sh's header comment) rather
# than `ssh host psql -c "<multi-line SQL>"`, which breaks on multi-line
# SQL once SSH joins argv into one remote command string.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

set -a
source "${PROJECT_ROOT}/local/prod.env"
set +a

SSH_KEY="${PROD_SSH_KEY/#\~/$HOME}"
SSH="ssh -i ${SSH_KEY} -o ConnectTimeout=10 ${PROD_SSH_HOST}"
REMOTE_TMP="/tmp/beecore-migrations-prod-seed.sql"

ADMIN_USER_ID="d89f2559-57df-43ba-ab01-790f7a38525c"
ADMIN_EMAIL="info@v8tix.com"
# Generated via beecore-admin-v2's hash.Argon2idHash (Argon2id, same params
# CheckHash expects: salt=16B, time=1, memory=64MiB, threads=4, key=32B) —
# NOT dev's hash. Corresponding plaintext password is in
# /Users/vrock/Public/Common/infra/Deilora/... (wherever you choose to keep
# it) — not stored in this repo, same reasoning as the DB password itself.
ADMIN_PASSWORD_HASH="eD9XPbH2lsxjZwi1e18YCw:JX6XTKDg2sqdqoTQAPMhBjTa1YMj6Xi6MBVQnL+X3KM"

cleanup() {
  ${SSH} "rm -f ${REMOTE_TMP}" 2>/dev/null || true
}
trap cleanup EXIT

POD="$(${SSH} "microk8s kubectl -n postgres-standalone get pod -l app.kubernetes.io/name=postgres-standalone -o jsonpath='{.items[0].metadata.name}'")"

run_sql() {
  local sql_file="$1"
  scp -i "${SSH_KEY}" -q "${sql_file}" "${PROD_SSH_HOST}:${REMOTE_TMP}"
  ${SSH} "microk8s kubectl -n postgres-standalone cp ${REMOTE_TMP} ${POD}:${REMOTE_TMP}"
  ${SSH} "microk8s kubectl -n postgres-standalone exec deploy/postgres-standalone -- psql -U ${PROD_DB_USER} -d ${PROD_DB} -f ${REMOTE_TMP}"
}

echo "Starting seed data insertion (production: ${PROD_SSH_HOST})..."

echo "1. Inserting admin user..."
cat > /tmp/prod_seed_1_user.sql << EOF
INSERT INTO users.users (id, dni, first_name, last_name, email, birthday, genre, phone, img_url, website, enabled, password)
VALUES ('${ADMIN_USER_ID}',
        '1718725938',
        'Marco',
        'Almeida',
        '${ADMIN_EMAIL}',
        '12-04-1983',
        'male',
        '0987837393',
        'www.google.com',
        'www.google.com',
        true,
        '${ADMIN_PASSWORD_HASH}')
RETURNING id;
EOF
run_sql /tmp/prod_seed_1_user.sql
rm -f /tmp/prod_seed_1_user.sql

echo "2. Inserting roles..."
cat > /tmp/prod_seed_2_roles.sql << 'EOF'
INSERT INTO users.roles (id, name) VALUES ('13a2f208-bfbf-4eea-b040-28a42bee08f1', 'STORE_ADMIN');
INSERT INTO users.roles (id, name) VALUES ('8a1df9e1-d2cc-4d08-81dd-d805a56e03d3', 'STORE_BUYER');
EOF
run_sql /tmp/prod_seed_2_roles.sql
rm -f /tmp/prod_seed_2_roles.sql

echo "3. Inserting permissions..."
cat > /tmp/prod_seed_3_permissions.sql << 'EOF'
INSERT INTO users.permissions (id, name) VALUES ('a22067fd-2575-4bda-831a-3acf34544168', 'MANAGE_USERS');
INSERT INTO users.permissions (id, name) VALUES ('311364d8-edce-4dda-a385-3bfc4143a50b', 'MANAGE_ADDRESSES');
INSERT INTO users.permissions (id, name) VALUES ('ba0dc689-72de-4c2f-9d3f-c7d46ef56cff', 'MANAGE_STORES');
INSERT INTO users.permissions (id, name) VALUES ('9038e096-9bb5-465f-aa85-1903a6fe45da', 'MANAGE_PRODUCTS');
INSERT INTO users.permissions (id, name) VALUES ('3f8e2a32-0955-408d-a130-c318e2c34489', 'MANAGE_BASKETS');
INSERT INTO users.permissions (id, name) VALUES ('797da2ad-1702-4e73-be98-2d75db0254ab', 'MANAGE_ORDERS');
INSERT INTO users.permissions (id, name) VALUES ('e04ab3ad-610f-4f5e-a00a-84adbd5d14ad', 'BUY_PRODUCTS');
INSERT INTO users.permissions (id, name) VALUES ('7861c86d-b636-4976-8fb1-f8e8a8e1d46d', 'MANAGE_PAYMENTS');
INSERT INTO users.permissions (id, name) VALUES ('f3119233-1c3b-4fec-9836-45fdeeb4d34a', 'MANAGE_INVOICES');
EOF
run_sql /tmp/prod_seed_3_permissions.sql
rm -f /tmp/prod_seed_3_permissions.sql

echo "4. Inserting admin roles..."
cat > /tmp/prod_seed_4_user_roles.sql << EOF
INSERT INTO users.user_roles (user_id, role_id) VALUES ('${ADMIN_USER_ID}', '13a2f208-bfbf-4eea-b040-28a42bee08f1');
INSERT INTO users.user_roles (user_id, role_id) VALUES ('${ADMIN_USER_ID}', '8a1df9e1-d2cc-4d08-81dd-d805a56e03d3');
EOF
run_sql /tmp/prod_seed_4_user_roles.sql
rm -f /tmp/prod_seed_4_user_roles.sql

echo "5. Inserting role permissions..."
cat > /tmp/prod_seed_5_role_permissions.sql << 'EOF'
-- STORE_ADMIN permissions
INSERT INTO users.role_permissions (role_id, permission_id) VALUES ('13a2f208-bfbf-4eea-b040-28a42bee08f1', 'a22067fd-2575-4bda-831a-3acf34544168');
INSERT INTO users.role_permissions (role_id, permission_id) VALUES ('13a2f208-bfbf-4eea-b040-28a42bee08f1', '311364d8-edce-4dda-a385-3bfc4143a50b');
INSERT INTO users.role_permissions (role_id, permission_id) VALUES ('13a2f208-bfbf-4eea-b040-28a42bee08f1', 'ba0dc689-72de-4c2f-9d3f-c7d46ef56cff');
INSERT INTO users.role_permissions (role_id, permission_id) VALUES ('13a2f208-bfbf-4eea-b040-28a42bee08f1', '9038e096-9bb5-465f-aa85-1903a6fe45da');
INSERT INTO users.role_permissions (role_id, permission_id) VALUES ('13a2f208-bfbf-4eea-b040-28a42bee08f1', '3f8e2a32-0955-408d-a130-c318e2c34489');
INSERT INTO users.role_permissions (role_id, permission_id) VALUES ('13a2f208-bfbf-4eea-b040-28a42bee08f1', '797da2ad-1702-4e73-be98-2d75db0254ab');
INSERT INTO users.role_permissions (role_id, permission_id) VALUES ('13a2f208-bfbf-4eea-b040-28a42bee08f1', '7861c86d-b636-4976-8fb1-f8e8a8e1d46d');
INSERT INTO users.role_permissions (role_id, permission_id) VALUES ('13a2f208-bfbf-4eea-b040-28a42bee08f1', 'f3119233-1c3b-4fec-9836-45fdeeb4d34a');

-- STORE_BUYER permissions
INSERT INTO users.role_permissions (role_id, permission_id) VALUES ('8a1df9e1-d2cc-4d08-81dd-d805a56e03d3', 'e04ab3ad-610f-4f5e-a00a-84adbd5d14ad');
INSERT INTO users.role_permissions (role_id, permission_id) VALUES ('8a1df9e1-d2cc-4d08-81dd-d805a56e03d3', '311364d8-edce-4dda-a385-3bfc4143a50b');
EOF
run_sql /tmp/prod_seed_5_role_permissions.sql
rm -f /tmp/prod_seed_5_role_permissions.sql

echo ""
echo "Seed data inserted successfully!"
echo ""
echo "Admin user credentials:"
echo "  ID: ${ADMIN_USER_ID}"
echo "  Email: ${ADMIN_EMAIL}"
echo "  Password: (not stored in this repo — see wherever you saved it when it was generated)"
echo ""
echo "Roles created:"
echo "  - STORE_ADMIN"
echo "  - STORE_BUYER"
echo ""
echo "Permissions created: 9 total"
