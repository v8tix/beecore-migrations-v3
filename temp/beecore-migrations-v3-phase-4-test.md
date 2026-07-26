# Test Report: beecore-migrations-v3 Migration

## Test Results (All Passed)

| Test | Status | Details |
|------|--------|---------|
| Database creation | ✅ | DB & 6 schemas created |
| fnv32a function | ✅ | Returns deterministic INT8 values |
| bytea_to_jsonb_utf8 function | ✅ | IMMUTABLE wrapper for GIN index |
| Migration 000001 — baskets | ✅ | 7 tables, 9 indexes (GIN on jsonb) |
| Migration 000002 — users | ✅ | 11 tables, 7 indexes |
| Migration 000004 — notifications | ✅ | 1 table |
| Migration 000005 — ordering | ✅ | 5 tables, 10 indexes (GIN on jsonb) |
| Migration 000006 — payments | ✅ | 4 tables, 4 indexes |
| Migration 000007 — stores | ✅ | 6 tables, 11 indexes (GIN on jsonb + TSVECTOR) |
| Seed data | ✅ | 1 admin user, 2 roles, 9 permissions |
| Down migration — stores | ✅ | Clean drop |
| Down migration — payments | ✅ | Clean drop |
| Down migration — ordering | ✅ | Clean drop |
| Down migration — notifications | ✅ | Clean drop |
| Down migration — users | ✅ | Clean drop |
| Down migration — baskets | ✅ | Clean drop |
| Full up → down → up cycle | ✅ | Idempotent, no errors |

## Tables Created

**34 tables** across 6 schemas + `schema_migrations`:

- baskets: stores_cache, products_cache, events, snapshots, inbox, outbox (6)
- users: users, addresses, inbox, outbox, roles, permissions, user_roles, role_permissions, role_hierarchy, resources, audit_logs, tokens (12)
- notifications: users_cache (1)
- ordering: orders, events, snapshots, inbox, outbox (5)
- payments: payments, invoices, inbox, outbox (4)
- stores: stores, products, events, snapshots, inbox, outbox (6)

## Key SQL Adaptations Verified

| Change | Verified |
|--------|----------|
| INVERTED INDEX → GIN | ✅ Via bytea_to_jsonb_utf8() and GIN on TSVECTOR |
| fnv32a INT8 STORED → BIGINT GENERATED ALWAYS AS ... STORED | ✅ |
| BOOL → BOOLEAN | ✅ |
| psql CLI instead of cockroach sql | ✅ |
| postgres:// DSN format | ✅ |
| sslmode=disable | ✅ |
| Port 5432 | ✅ |