# Spec: beecore-migrations-v2 → beecore-migrations-v3 Migration

## Objective

Mirror the beecore-migrations-v2 repository (CockroachDB) into `/Users/vrock/Public/V8TIX/repos/Deilora/beecore-migrations-v3/local`, adapting all SQL, scripts, configuration, and tooling from CockroachDB to PostgreSQL. The v3 directory will be the canonical source for all future PostgreSQL migrations.

**Target:** PostgreSQL 18 (via `beecore-net` docker-compose)
**Source:** CockroachDB v23.1+ (via beecore-migrations-v2)

## Assumptions

- All services use PostgreSQL DSN format (`postgres://`) not CockroachDB (`crdb-postgres://` or `cockroachdb://`)
- PostgreSQL runs on port 5432 (not 26257)
- SSL mode will use `disable` for local dev (PostgreSQL in Docker)
- The `golang-migrate` tool with `postgres` driver tag (not `cockroachdb` tag)
- Docker exec will use `psql` not `cockroach sql`
- No CockroachDB-specific SQL features in source (INVERTED INDEX, fnv32a, crdb_internal functions, etc.)

## Changes Required

### 1. CockroachDB → PostgreSQL SQL Compatibility

| CockroachDB | PostgreSQL |
|---|---|
| `INVERTED INDEX` on JSONB | `GIN INDEX` on JSONB |
| `CAST(convert_from(event_data, 'UTF8') AS JSONB)` | Same (works in both) |
| `fnv32a(aggregate_id)` | `hashtext(aggregate_id)` or custom function |
| `INT8 AS (fnv32a(...)) STORED` | `BIGINT GENERATED ALWAYS AS (...) STORED` |
| `TSVECTOR AS (to_tsvector(...)) STORED` | Same (native PG feature) |
| `BOOL` | `BOOLEAN` (same, both accepted) |
| `BYTEA` | Same |
| `TIMESTAMPTZ` | Same |
| `DECIMAL(9,2)` | Same |
| `TEXT` | Same |
| `INT` | `INTEGER` (same) |
| `NOW()` | Same |

### 2. Script Changes (CockroachDB CLI → psql)

- `docker exec ... /cockroach/cockroach sql` → `docker exec ... psql -U user -d db`
- No certs needed for local dev (trust/auth)
- Schema creation SQL is largely the same
- `CREATE USER WITH PASSWORD` → same (works in PG)
- `GRANT ALL ON DATABASE` → same
- `ALTER SCHEMA OWNER TO` → same

### 3. Tooling

- `golang-migrate` install: `go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest`
- DSN format: `postgres://user:pass@host:port/db?sslmode=disable`
- Migrations path: `./local/migrations`

### 4. Configuration

- `.env` → PostgreSQL connection params (port 5432, sslmode=disable)
- `.envrc` → PostgreSQL DSN format

## Project Structure (v3 target)

```
local/
  migrations/         → Mirrored SQL migrations (CockroachDB → PostgreSQL adapted)
    000001_create_basket_schema.up.sql
    000001_create_basket_schema.down.sql
    000002_create_users_schema.up.sql
    000002_create_users_schema.down.sql
    000004_create_notifications_schema.up.sql
    000004_create_notifications_schema.down.sql
    000005_create_ordering_schema.up.sql
    000005_create_ordering_schema.down.sql
    000006_create_payments_schema.up.sql
    000006_create_payments_schema.down.sql
    000007_create_stores_schema.up.sql
    000007_create_stores_schema.down.sql
  scripts/
    local/
      create_db.sh          → Create DB, user, schemas via psql
      create_db_dsn.sh      → Same with DSN format
      seed_db.sh            → Seed test data via psql
      seed_db_dsn.sh        → Same with DSN format
      drop_db.sh            → Drop DB via psql
      drop_db_dsn.sh        → Same with DSN format
      grant_privileges.sh   → Grant PG privileges (different from CRDB)
  docs/
    (relevant docs from v2, adapted for PG)

Makefile                  → Adapted for PostgreSQL migrate commands
.env                      → PostgreSQL connection params
.envrc                    → PostgreSQL env vars
uuid-generator/           → Mirrored as-is (Go, no DB-specific code)
README.md                 → Updated for PostgreSQL
```

## Key SQL Adaptations Needed

### fnv32a → hashtext (in outbox tables)

The outbox tables use `id_hash INT8 AS (fnv32a(aggregate_id)) STORED`. PostgreSQL does not have `fnv32a`. Options:
1. Use `hashtext(aggregate_id)` — returns `integer`, cast to `bigint`
2. Create a custom `fnv32a` function in PostgreSQL
3. Use `md5(aggregate_id)::int8`

**Recommendation:** Create a custom fnv32a function since this is a hash partitioning concern.

### Drop/reorder indexes in down migrations

The down migrations must drop indexes before tables. The index naming convention moves from CockroachDB prefix convention.

## Success Criteria

- [ ] All 12 SQL migration files (6 up + 6 down) adapted and working against PostgreSQL
- [ ] All local scripts work with `psql` against PostgreSQL container
- [ ] `make migrations/local/up` runs all migrations successfully on PostgreSQL
- [ ] `make migrations/local/down` reverts all migrations successfully
- [ ] Seed script inserts data without errors
- [ ] `uuid-generator` builds and works (Go, no changes needed)

## Boundaries

- **Always:** Adapted SQL must maintain original schema behavior; test each migration up+down
- **Ask first:** Adding new schemas/tables beyond what v2 has; changing column types
- **Never:** Delete v2 files; modify the docker-compose; commit passwords

## Open Questions

1. Should fnv32a be a custom PG function or should we use `hashtext`?
2. Is there a specific PostgreSQL user/password expected for the test environment?