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

## K3D Setup

`local/scripts/local/*.sh` shell out via `docker exec beecore-postgres` — that container doesn't exist against a k3d cluster (`beecore-net-v2`, replacing the legacy docker-compose `beecore-net`). Use the `k3d` variants instead, which run the same SQL via `kubectl exec` against the `postgres-standalone` pod:

```bash
# 1. Bootstrap the cluster and deploy postgres/redis/nats first — see
#    beecore-charts/k3d/doc/install.md steps 3-4.

# 2. Create schemas (database itself is already provisioned by the
#    postgres/v18 chart's POSTGRES_DB)
./local/scripts/k3d/create_db.sh

# 3. Run migrations — `local/.env`'s LOCAL_DB_DSN already points at
#    localhost:5432, same as k3d.env, so the existing Makefile targets work
#    unchanged once Postgres is reachable there (see
#    beecore-charts/k3d/doc/install.md step 6 for the `kubectl port-forward`
#    this depends on):
make migrations/local/up

# 4. Seed test data
./local/scripts/k3d/seed_db.sh

# 5. Grant privileges (mostly a no-op here — migrations already run as
#    v8tix directly, so it already owns everything — kept for parity)
./local/scripts/k3d/grant_privileges.sh
```

`local/k3d.env` holds the same `v8tix`/`deilora-dev` identifiers as `local/.env` (config-k8s intentionally keeps them identical to the native config — only the connection host differs) plus the `kubectl exec` target (`K3D_CONTEXT`/`K3D_NAMESPACE`/`K3D_DEPLOYMENT`).

## Production Setup

The production Postgres (`postgres-standalone` on the microk8s server,
`192.168.100.60`) has no direct or LAN-reachable route — only reachable via
SSH into the server, then `microk8s kubectl` from there into the cluster.
`local/scripts/prod/*.sh` handle this:

```bash
# 1. Open the tunnel (localhost:5433 -> SSH -> microk8s kubectl port-forward
#    -> in-cluster postgres-standalone Service). One SSH connection does
#    both hops — the remote command run over that same session IS the
#    kubectl port-forward. Leave this running in its own terminal/session.
./local/scripts/prod/connect_tunnel.sh

# 2. Create database and schemas (idempotent, safe to re-run)
./local/scripts/prod/create_db.sh

# 3. Run migrations
make migrations/prod/up

# 4. Seed the admin user + roles/permissions reference data (optional —
#    only needed once, for a real admin account to actually log into
#    production with)
./local/scripts/prod/seed_db.sh

# (No grant-privileges step for prod — migrations already run as v8tix,
#  which owns everything it creates.)
```

**`seed_db.sh` is NOT a copy of the k3d/local seed** — roles and permissions
(fixed UUIDs, names) are identical across environments since they're
structural reference data, not secrets. But the admin **user** row is
deliberately different from dev's:

| Field | Dev (`local/scripts/{local,k3d}/seed_db.sh`) | Production |
|---|---|---|
| User ID | `6c21a2ef-c47b-4104-b619-72d9677a9887` | fresh UUID (generated via `uuid-generator/`) |
| Email | `malmeidap@hotmail.com` (personal test address) | `info@v8tix.com` |
| Password hash | dev's own Argon2id hash | freshly generated Argon2id hash — **critically not the same hash as dev's**, since reusing it would mean dev's admin password also logs into production |

The actual plaintext production admin password isn't in this repo (same
reasoning as the DB password) — it's saved server-side at
`/home/v8tix/passwords/admin-v2-production-password.txt`, matching the
convention every other credential on that server follows.

If you ever need to generate another Argon2id hash by hand (new admin, password
rotation), the exact algorithm/params are in
`beecore-admin-v2/vendor/github.com/v8tix/beecore-hash-mod/argon2id.go` —
`Argon2idHash(plaintext string)` is a public function, callable from a
throwaway `go run` file in any repo that already vendors it.

**Production connection:** `localhost:5433/deilora` (through the tunnel) — user `v8tix`

**Password handling is deliberately different from local/k3d.** `local/.env`
and `local/k3d.env` store their (local-only) passwords in plaintext, but
`local/prod.env` does not — the production password is fetched live over
SSH at the point of use (`local/scripts/prod/get_password.sh`, called from
inside each `migrations/prod/*` target) and never written to disk in this
repo. That script also URL-encodes the password before it goes into the
DSN — the generated password is base64 and can contain `/`, `+`, `=`, and a
raw `/` in particular breaks `postgres://` URI parsing (reads as a path
separator, not part of the credential).

`create_db.sh` pipes SQL through a scp'd file rather than `ssh host psql -c
"<multi-line SQL>"` — passing a multi-line/quoted argument through a plain
`ssh host cmd args...` loses the local shell's quoting once SSH joins the
trailing argv into one remote command string, and `-c` ends up with no
argument at all. A file sidesteps that.

## Make Commands

```bash
make migrations/local/up
make migrations/local/down
make migrations/local/version
make migrations/local/goto GOTO=1
make migrations/local/force GOTO=1

# Production — same commands, prod/ instead of local/, requires the tunnel
# (step 1 above) running first
make migrations/prod/up
make migrations/prod/down
make migrations/prod/version
make migrations/prod/goto GOTO=1
make migrations/prod/force GOTO=1
make migrations/prod/debug   # shows config without exposing the password
```

## Schemas

| Migration | Schema | Contents |
|-----------|--------|----------|
| 000000 | *(none — `public`)* | Shared custom SQL functions (see below) |
| 000001 | `baskets` | Product/store cache, events, inbox/outbox |
| 000002 | `users` | RBAC, roles, permissions, tokens, addresses |
| 000003 | `notifications` | User cache |
| 000004 | `ordering` | Orders (incl. `store_id` + `UNIQUE(basket_id, store_id)` — natural idempotency key for CreateOrder retries), events, inbox/outbox |
| 000005 | `payments` | Payments, invoices, inbox/outbox |
| 000006 | `stores` | Stores, products, full-text search, events |

## Custom SQL Functions

Migration `000000_create_custom_functions.up.sql` defines two functions,
before any schema-owning migration runs, that several later migrations'
`up.sql` files reference directly in `CREATE INDEX`/generated-column
expressions:

| Function | Used by | Purpose |
|---|---|---|
| `fnv32a(text) RETURNS BIGINT` | outbox `id_hash` generated columns (000001, 000002, 000004, 000005, 000006) | deterministic partition hash, equivalent to Go's `hash/fnv.New32a()` |
| `bytea_to_jsonb_utf8(bytea) RETURNS JSONB` | `idx_events_event_data_jsonb` GIN indexes (000001, 000004, 000006) | wraps `convert_from(...)::jsonb` as `IMMUTABLE` so it's usable in an index expression (`convert_from` itself is `STABLE`, which Postgres rejects there) |

They're database-level, not schema-scoped, so creating them once in
`000000` is enough for every schema that follows. `000000`'s `down.sql`
drops them *last* in a full teardown — `migrate down` runs migrations in
strict reverse order (6,5,4,3,2,1,0), so every table that references them
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

## Branching strategy

* `main` always holds released, working migrations.
* `develop` is the integration branch where new migrations land first.
* Both branches are protected: nobody can push to them directly, force-push them or delete them. Every change
  arrives through a pull request, which must pass CI (when configured) with all conversations resolved.
* Start a new migration from `develop` (`git switch -c feature/<name> develop`), open a pull request into
  `develop`, and merge it once it's ready.
* To release, open a pull request from `develop` into `main`. Use **Create a merge commit** (not squash or
  rebase) so the two branches keep a common history.

---

**PostgreSQL 18** | **golang-migrate:** install with `make install`