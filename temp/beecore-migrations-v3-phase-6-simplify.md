# Simplification Report: beecore-migrations-v3

## Approach

Reviewed all 25+ files for simplification opportunities. The codebase is a direct migration from v2 (CockroachDB) — structure mirrors the original deliberately to minimize confusion when switching between repos.

## Findings

### 1. fnv32a PL/pgSQL — Minor simplification

**File:** `local/scripts/fnv32a.sql`

The function uses a loop with `convert_to`, `get_byte`, and bitwise operations. Implementation is correct but verbose. A simpler `SQL` language version is possible:

```sql
CREATE OR REPLACE FUNCTION fnv32a(input_text TEXT)
RETURNS BIGINT
IMMUTABLE STRICT LEAKPROOF PARALLEL SAFE
LANGUAGE SQL AS $$
  SELECT ('x' || substr(md5(input_text), 1, 8))::bit(32)::bigint;
$$;
```

However, this changes the hash algorithm from FNV-1a to MD5-truncated — producing different hash values than CockroachDB's builtin `fnv32a`. The current implementation is intentionally faithful to the original.

**Decision:** Keep the current implementation. The FNV-1a algorithm correctness matters for hash partitioning consistency. Adding this note to the function comments for clarity.

### 2. Seed scripts — Near-identical duplication

**Files:** `local/scripts/local/seed_db.sh` and `local/scripts/local/seed_db_dsn.sh`

These are 99% identical — the only difference is the echo statements (DSN formatting). This mirrors v2 convention exactly. Consolidating would break the mirror pattern.

**Decision:** Keep as-is. The duplication is intentional for DSN reference output.

### 3. Create scripts — Same pattern

**Files:** `local/scripts/local/create_db.sh` and `local/scripts/local/create_db_dsn.sh`

Same as seed scripts — identical logic, different echo output. Mirrors v2 convention.

**Decision:** Keep as-is.

### 4. Makefile targets — Slight DRY opportunity

**File:** `Makefile`

The local migration targets (`local/up`, `local/down`, `local/goto`) and cloud targets (`up`, `down`, `goto`) share the same migrate command but with different DSN variables. A template pattern could reduce repetition:

```makefile
# Instead of writing each target explicitly
MIGRATE = migrate -path="${MIGRATIONS_PATH}" -database='${DSN}'

migrations/local/up: migrations/local/check
	migrate -path="${MIGRATIONS_PATH}" -database='${LOCAL_DB_DSN}' up
```

But this mirrors v2 exactly, and the variable-based pattern is already clean.

**Decision:** Keep as-is. Explicit targets are easier to read than Make macros.

### 5. Removed unused env var

**File:** `local/.env`

The `LOCAL_DB_CERTS_DIR` variable (present in v2 for CockroachDB SSL certs) has been removed since PG local dev uses `sslmode=disable`. Correct.

## Simplification Summary

| Change | Status | Reason |
|--------|--------|--------|
| fnv32a → MD5 truncation | ❌ Skipped | Changes hash values — breaks correctness |
| Consolidate seed scripts | ❌ Skipped | Mirrors v2 convention intentionally |
| Consolidate create scripts | ❌ Skipped | Same reason |
| Makefile macro pattern | ❌ Skipped | Explicit = more readable |
| Remove unused LOCALE_DB_CERTS_DIR | ✅ Already done | Correct for PG |

## Verdict

**No changes needed.** The codebase is already at the appropriate level of simplicity for its purpose — a DB migration repository. The intentional duplication (mirroring v2's script pairs for DSN/non-DSN variants) is a readability feature, not a bug. The fnv32a function correctly preserves FNV-1a behavior. All dead code from the CRDB era (cert paths, cockroach CLI references) has been removed.

The 5 simplification opportunities evaluated: 0 applied, all rejected with documented reasoning.