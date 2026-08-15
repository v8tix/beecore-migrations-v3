#!/usr/bin/env bash

# k3d equivalent of local/scripts/local/seed_db.sh — same seed data, executed
# via `kubectl exec` (the pod's own psql) instead of `docker exec` against a
# docker-compose container that doesn't exist in k3d.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

source "${PROJECT_ROOT}/local/k3d.env"

PSQL_CMD=(kubectl --context "${K3D_CONTEXT}" -n "${K3D_NAMESPACE}" exec "deploy/${K3D_DEPLOYMENT}" -- \
  psql -U "${LOCAL_DB_USER}" -d "${LOCAL_DB}")

echo "Starting seed data insertion (k3d: ${K3D_CONTEXT}/${K3D_NAMESPACE})..."

# 1. Insert admin user
echo "1. Inserting admin user..."
"${PSQL_CMD[@]}" -c "
INSERT INTO users.users (id,
                         dni,
                         first_name,
                         last_name,
                         email,
                         birthday,
                         genre,
                         phone,
                         img_url,
                         website,
                         enabled,
                         password)
VALUES ('6c21a2ef-c47b-4104-b619-72d9677a9887',
        '1718725938',
        'Marco',
        'Almeida',
        'malmeidap@hotmail.com',
        '12-04-1983',
        'male',
        '0987837393',
        'www.google.com',
        'www.google.com',
        true,
        'NzCbL/WlxNXbJEAXmstTcA:iWoeMfGc/PEc5zuUzj/AmuF5kK9/F8ptEdoqvuya3MQ')
RETURNING id;
"

# 2. Insert roles
echo "2. Inserting roles..."
"${PSQL_CMD[@]}" -c "
INSERT INTO users.roles (id, name) VALUES ('13a2f208-bfbf-4eea-b040-28a42bee08f1', 'STORE_ADMIN');
INSERT INTO users.roles (id, name) VALUES ('8a1df9e1-d2cc-4d08-81dd-d805a56e03d3', 'STORE_BUYER');
"

# 3. Insert permissions
echo "3. Inserting permissions..."
"${PSQL_CMD[@]}" -c "
INSERT INTO users.permissions (id, name) VALUES ('a22067fd-2575-4bda-831a-3acf34544168', 'MANAGE_USERS');
INSERT INTO users.permissions (id, name) VALUES ('311364d8-edce-4dda-a385-3bfc4143a50b', 'MANAGE_ADDRESSES');
INSERT INTO users.permissions (id, name) VALUES ('ba0dc689-72de-4c2f-9d3f-c7d46ef56cff', 'MANAGE_STORES');
INSERT INTO users.permissions (id, name) VALUES ('9038e096-9bb5-465f-aa85-1903a6fe45da', 'MANAGE_PRODUCTS');
INSERT INTO users.permissions (id, name) VALUES ('3f8e2a32-0955-408d-a130-c318e2c34489', 'MANAGE_BASKETS');
INSERT INTO users.permissions (id, name) VALUES ('797da2ad-1702-4e73-be98-2d75db0254ab', 'MANAGE_ORDERS');
INSERT INTO users.permissions (id, name) VALUES ('e04ab3ad-610f-4f5e-a00a-84adbd5d14ad', 'BUY_PRODUCTS');
INSERT INTO users.permissions (id, name) VALUES ('7861c86d-b636-4976-8fb1-f8e8a8e1d46d', 'MANAGE_PAYMENTS');
INSERT INTO users.permissions (id, name) VALUES ('f3119233-1c3b-4fec-9836-45fdeeb4d34a', 'MANAGE_INVOICES');
"

# 4. Insert admin roles
echo "4. Inserting admin roles..."
"${PSQL_CMD[@]}" -c "
INSERT INTO users.user_roles (user_id, role_id)
VALUES ('6c21a2ef-c47b-4104-b619-72d9677a9887', '13a2f208-bfbf-4eea-b040-28a42bee08f1');

INSERT INTO users.user_roles (user_id, role_id)
VALUES ('6c21a2ef-c47b-4104-b619-72d9677a9887', '8a1df9e1-d2cc-4d08-81dd-d805a56e03d3');
"

# 5. Insert role permissions
echo "5. Inserting role permissions..."
"${PSQL_CMD[@]}" -c "
-- STORE_ADMIN permissions
INSERT INTO users.role_permissions (role_id, permission_id)
VALUES ('13a2f208-bfbf-4eea-b040-28a42bee08f1', 'a22067fd-2575-4bda-831a-3acf34544168');

INSERT INTO users.role_permissions (role_id, permission_id)
VALUES ('13a2f208-bfbf-4eea-b040-28a42bee08f1', '311364d8-edce-4dda-a385-3bfc4143a50b');

INSERT INTO users.role_permissions (role_id, permission_id)
VALUES ('13a2f208-bfbf-4eea-b040-28a42bee08f1', 'ba0dc689-72de-4c2f-9d3f-c7d46ef56cff');

INSERT INTO users.role_permissions (role_id, permission_id)
VALUES ('13a2f208-bfbf-4eea-b040-28a42bee08f1', '9038e096-9bb5-465f-aa85-1903a6fe45da');

INSERT INTO users.role_permissions (role_id, permission_id)
VALUES ('13a2f208-bfbf-4eea-b040-28a42bee08f1', '3f8e2a32-0955-408d-a130-c318e2c34489');

INSERT INTO users.role_permissions (role_id, permission_id)
VALUES ('13a2f208-bfbf-4eea-b040-28a42bee08f1', '797da2ad-1702-4e73-be98-2d75db0254ab');

INSERT INTO users.role_permissions (role_id, permission_id)
VALUES ('13a2f208-bfbf-4eea-b040-28a42bee08f1', '7861c86d-b636-4976-8fb1-f8e8a8e1d46d');

INSERT INTO users.role_permissions (role_id, permission_id)
VALUES ('13a2f208-bfbf-4eea-b040-28a42bee08f1', 'f3119233-1c3b-4fec-9836-45fdeeb4d34a');

-- STORE_BUYER permissions
INSERT INTO users.role_permissions (role_id, permission_id)
VALUES ('8a1df9e1-d2cc-4d08-81dd-d805a56e03d3', 'e04ab3ad-610f-4f5e-a00a-84adbd5d14ad');

INSERT INTO users.role_permissions (role_id, permission_id)
VALUES ('8a1df9e1-d2cc-4d08-81dd-d805a56e03d3', '311364d8-edce-4dda-a385-3bfc4143a50b');
"

echo ""
echo "Seed data inserted successfully!"
echo ""
echo "Admin user credentials:"
echo "  Email: malmeidap@hotmail.com"
echo "  Password: (hashed)"
echo ""
echo "Roles created:"
echo "  - STORE_ADMIN"
echo "  - STORE_BUYER"
echo ""
echo "Permissions created: 9 total"
