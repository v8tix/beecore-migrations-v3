# BeeCore Migrations v3

Database migrations for BeeCore microservices platform.

## Prerequisites

1. **Docker cluster** — Start via `beecore-net`:
   ```bash
   cd /Users/vrock/Public/V8TIX/repos/Deilora/beecore-net/cluster
   docker compose up -d
   ```

2. **golang-migrate** — Install:
   ```bash
   make install
   ```

## Local Setup

```bash
# 1. Start PostgreSQL cluster (from beecore-net)
cd /Users/vrock/Public/V8TIX/repos/Deilora/beecore-net/cluster
docker compose up -d postgres

# 2. Initialize database and schemas
cd /Users/vrock/Public/V8TIX/repos/Deilora/beecore-migrations-v3
./local/scripts/local/create_db.sh

# 3. Run migrations (000000 creates the custom SQL functions — see below)
make migrations/local/up

# 4. Seed test data
./local/scripts/local/seed_db.sh

# 5. Grant privileges
./local/scripts/local/grant_privileges.sh
```

**Local connection:** `localhost:5432/deilora-dev` — user `v8tix`

## Make Commands

```bash
make migrations/local/up
make migrations/local/down
make migrations/local/version
make migrations/local/goto GOTO=1
make migrations/local/force GOTO=1
```

## Schemas

| Migration | Schema | Contents |
|-----------|--------|----------|
| 000000 | *(none — `public`)* | Shared custom SQL functions (see below) |
| 000001 | `baskets` | Product/store cache, events, inbox/outbox |
| 000002 | `users` | RBAC, roles, permissions, tokens, addresses |
| 000004 | `notifications` | User cache |
| 000005 | `ordering` | Orders, events, inbox/outbox |
| 000006 | `payments` | Payments, invoices, inbox/outbox |
| 000007 | `stores` | Stores, products, full-text search, events |

## Custom SQL Functions

Migration `000000_create_custom_functions.up.sql` defines two functions,
before any schema-owning migration runs, that several later migrations'
`up.sql` files reference directly in `CREATE INDEX`/generated-column
expressions:

| Function | Used by | Purpose |
|---|---|---|
| `fnv32a(text) RETURNS BIGINT` | outbox `id_hash` generated columns (000001, 000002, 000005, 000006, 000007) | deterministic partition hash, equivalent to Go's `hash/fnv.New32a()` |
| `bytea_to_jsonb_utf8(bytea) RETURNS JSONB` | `idx_events_event_data_jsonb` GIN indexes (000001, 000005, 000007) | wraps `convert_from(...)::jsonb` as `IMMUTABLE` so it's usable in an index expression (`convert_from` itself is `STABLE`, which Postgres rejects there) |

They're database-level, not schema-scoped, so creating them once in
`000000` is enough for every schema that follows. `000000`'s `down.sql`
drops them *last* in a full teardown — `migrate down` runs migrations in
strict reverse order (7,6,5,4,2,1,0), so every table that references them
in a generated column is already gone by the time `000000`'s own down runs.

Note: version `0` is a real migration version here, not a reserved value —
golang-migrate's "nothing applied yet" sentinel is `-1`
(`database.NilVersion`), so `000000` behaves like any other version.

### Adding a new custom SQL function

1. Add it to `000000_create_custom_functions.up.sql` as
   `CREATE OR REPLACE FUNCTION` — idempotent, since `up` can be re-run
   against a database that already has it.
2. If the function is used inside a `CREATE INDEX` expression, mark it
   `IMMUTABLE STRICT LEAKPROOF PARALLEL SAFE` (Postgres rejects `STABLE`/
   `VOLATILE` functions in index expressions).
3. Add the matching `DROP FUNCTION IF EXISTS` to
   `000000_create_custom_functions.down.sql`.
4. Document it in the table above.

These are tracked by `golang-migrate` like everything else — no separate
install step, no risk of forgetting it on a fresh database.

## Important: Timestamps

Always set `updated_at` explicitly on UPDATE:

```sql
UPDATE users.users SET email = 'new@email.com', updated_at = NOW() WHERE id = '123';
```

---

**PostgreSQL 18** | **golang-migrate:** install with `make install`