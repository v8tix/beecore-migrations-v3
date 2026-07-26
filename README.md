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

# 3. Install fnv32a function
docker exec -e PGPASSWORD=qCeGbJgz2lNIXo beecore-postgres psql -U v8tix -d deilora-dev -f /dev/stdin < local/scripts/fnv32a.sql

# 4. Run migrations
make migrations/local/up

# 5. Seed test data
./local/scripts/local/seed_db.sh

# 6. Grant privileges
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
| 000001 | `baskets` | Product/store cache, events, inbox/outbox |
| 000002 | `users` | RBAC, roles, permissions, tokens, addresses |
| 000004 | `notifications` | User cache |
| 000005 | `ordering` | Orders, events, inbox/outbox |
| 000006 | `payments` | Payments, invoices, inbox/outbox |
| 000007 | `stores` | Stores, products, full-text search, events |

## Important: Timestamps

Always set `updated_at` explicitly on UPDATE:

```sql
UPDATE users.users SET email = 'new@email.com', updated_at = NOW() WHERE id = '123';
```

---

**PostgreSQL 18** | **golang-migrate:** install with `make install`