-- FNV-1a 32-bit hash function for PostgreSQL
-- Provides equivalent functionality to CockroachDB's builtin fnv32a()
--
-- The FNV-1a hash is a 32-bit non-cryptographic hash function.
-- This implementation returns BIGINT with unsigned 32-bit range (0 to 4294967295),
-- matching Go's hash/fnv.New32a().Sum32().
--
-- Usage:
--   SELECT fnv32a('some_string');  -- returns bigint
--
-- Source: https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function#FNV-1a_hash

CREATE OR REPLACE FUNCTION fnv32a(input_text TEXT)
RETURNS BIGINT
IMMUTABLE STRICT LEAKPROOF PARALLEL SAFE
LANGUAGE plpgsql
AS $$
DECLARE
    hash_val  BIGINT := 2166136261;
    i         INT;
    byte_val  BYTEA;
BEGIN
    byte_val := convert_to(input_text, 'UTF8');
    FOR i IN 1..length(byte_val) LOOP
        hash_val := hash_val # get_byte(byte_val, i - 1);
        hash_val := hash_val * 16777619;
        hash_val := hash_val & 4294967295;
    END LOOP;
    RETURN hash_val;
END;
$$;

-- Wrapper to convert bytea (UTF8 JSON) to jsonb for GIN index use.
-- PostgreSQL requires IMMUTABLE for index expressions; convert_from
-- is categorized STABLE, so we wrap it in an explicit IMMUTABLE function.
CREATE OR REPLACE FUNCTION bytea_to_jsonb_utf8(data BYTEA)
RETURNS JSONB
IMMUTABLE STRICT LEAKPROOF PARALLEL SAFE
LANGUAGE SQL AS $$
  SELECT convert_from(data, 'UTF8')::jsonb;
$$;
