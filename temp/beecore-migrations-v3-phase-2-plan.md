# Implementation Plan: beecore-migrations-v2 → v3 Migration

## Overview

Mirror all migrations, scripts, config, and tooling from `beecore-migrations-v2` (CockroachDB) into `beecore-migrations-v3/local` (PostgreSQL), adapting SQL syntax, CLI tools, and connection strings.

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| fnv32a replacement | Custom PL/pgSQL function | Same hash as CRDB, stable, documented |
| Local SSL | `sslmode=disable` | PostgreSQL in Docker, no certs needed |
| migrate tag | `postgres` only | No `cockroachdb` tag needed |
| Script CLI | `psql` via `docker exec` | PostgreSQL container, no cockroach CLI |
| Port | 5432 | PostgreSQL default |
| DSN format | `postgres://user:pass@host:port/db?sslmode=disable` | Standard PG DSN |

## Task List

### Phase 1: Foundation

- [ ] **Task 1: Create directory structure** — Mirror v2 directory layout under `local/`
- [ ] **Task 2: Create fnv32a PG function** — Write `local/scripts/fnv32a.sql` with `CREATE FUNCTION fnv32a(text) RETURNS bigint`
- [ ] **Task 3: Copy & adapt .env** — PostgreSQL port, sslmode=disable, postgres:// DSN

### Checkpoint: Foundation
- [ ] Directory structure matches v2 layout
- [ ] fnv32a function SQL is valid PostgreSQL
- [ ] .env has correct PG connection params

### Phase 2: SQL Migrations (6 schemas, 12 files)

- [ ] **Task 4: Migration 000001 — baskets** — Adapt baskets schema (INVERTED INDEX → GIN, fnv32a)
- [ ] **Task 5: Migration 000002 — users** — Adapt users schema (remove CRDB-specific comments)
- [ ] **Task 6: Migration 000004 — notifications** — Adapt notifications schema (minimal changes)
- [ ] **Task 7: Migration 000005 — ordering** — Adapt ordering schema (INVERTED INDEX → GIN, fnv32a)
- [ ] **Task 8: Migration 000006 — payments** — Adapt payments schema (fnv32a)
- [ ] **Task 9: Migration 000007 — stores** — Adapt stores schema (INVERTED INDEX → GIN, fnv32a, TSVECTOR)

### Checkpoint: Migrations
- [ ] All 12 migration files exist (6 up + 6 down)
- [ ] No CockroachDB-specific syntax remains
- [ ] All fnv32a references replaced with function call

### Phase 3: Scripts

- [ ] **Task 10: Local scripts — create_db** — Adapt create_db.sh + create_db_dsn.sh (cockroach sql → psql)
- [ ] **Task 11: Local scripts — seed_db** — Adapt seed_db.sh + seed_db_dsn.sh (same pattern)
- [ ] **Task 12: Local scripts — drop_db** — Adapt drop_db.sh + drop_db_dsn.sh (same pattern)
- [ ] **Task 13: Local scripts — grant_privileges** — Adapt grant_privileges_dsn.sh (PG equivalents)

### Checkpoint: Scripts
- [ ] All scripts use `psql` not `cockroach sql`
- [ ] No CRDB-specific commands (no certs-dir, no cockroach CLI)
- [ ] Schema creation matches PG syntax

### Phase 4: Tooling & Config

- [ ] **Task 14: Makefile** — Adapt for PG (postgres tag, postgres:// DSN, no CRDB commands)
- [ ] **Task 15: .envrc** — PostgreSQL env vars, postgres:// DSN format
- [ ] **Task 16: uuid-generator** — Copy as-is (pure Go, no DB dependencies)
- [ ] **Task 17: README + docs** — Update for PostgreSQL workflow

### Checkpoint: Tooling
- [ ] Makefile targets work with PG
- [ ] .envrc exports correct PG DSN
- [ ] uuid-generator builds

### Phase 5: Test & Verify

- [ ] **Task 18: Integration test** — Run `make migrations/local/up` against PG Docker, verify all schemas
- [ ] **Task 19: Rollback test** — Run `make migrations/local/down`, verify clean teardown

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| INVERTED INDEX on TSVECTOR not supported in PG | High | TSVECTOR uses GIN indexes natively — check compatibility |
| Generated column syntax differs | Medium | `INT8 AS (fnv32a(...)) STORED` → `BIGINT GENERATED ALWAYS AS (...) STORED` |
| \`convert_from(event_data, 'UTF8')\` AS JSONB same in PG | Low | Works in both, no change needed |
| Docker exec psql auth issues | Medium | Use trust auth or pass via PGPASSWORD env |

## Open Questions

- None — spec decisions confirmed in Phase 1