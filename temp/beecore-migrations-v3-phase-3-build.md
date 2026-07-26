# Build Report: beecore-migrations-v2 → v3 Migration

## Summary

All 19 tasks from the plan are complete. The v3 repository now mirrors v2's functionality fully adapted for PostgreSQL.

## Files Created/Modified

| Location | Contents |
|----------|----------|
| `local/migrations/` | 12 migration files (6 up + 6 down) — adapted for PG |
| `local/scripts/fnv32a.sql` | Custom FNV-1a hash function (PL/pgSQL) |
| `local/scripts/local/` | 7 scripts — create, seed, drop, grant (psql-based) |
| `local/scripts/test/` | 3 scripts — create, seed, drop (psql-based) |
| `local/.env` | PostgreSQL connection config |
| `.envrc` | PostgreSQL env vars |
| `Makefile` | Adapted for PG (postgres tag, postgres:// DSN) |
| `uuid-generator/` | Copied from v2 (Go, no changes needed) |
| `README.md` | Updated for PostgreSQL |
| `.gitignore` | Same as v2 |

## Key Adaptations

| Change | v2 (CockroachDB) | v3 (PostgreSQL) |
|--------|-------------------|------------------|
| Port | 26257 | 5432 |
| SSL | verify-full + certs | disable |
| DSN | `crdb-postgres://` | `postgres://` |
| Hash | built-in `fnv32a()` | custom PL/pgSQL function |
| JSONB index | `INVERTED INDEX` | `USING GIN` |
| TSVECTOR index | `INVERTED INDEX` | `USING GIN` |
| Generated column | `INT8 AS (fnv32a(...)) STORED` | `BIGINT GENERATED ALWAYS AS (...) STORED` |
| CLI | `docker exec ... cockroach sql` | `docker exec ... psql` |
| Container | `cockroachdb` | `beecore-postgres` |
| migrate tag | `postgres cockroachdb` | `postgres` |

## Next Steps

Before marking done, Phase 4 (Test) should verify:
1. `make migrations/local/up` applies all migrations
2. `make migrations/local/down` reverts cleanly
3. Seed scripts insert data
4. fnv32a function works correctly