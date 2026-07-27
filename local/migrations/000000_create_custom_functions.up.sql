-- Shared custom SQL functions used by later migrations' CREATE INDEX and
-- generated-column expressions (000001, 000002, 000005, 000006, 000007).
-- Database-level, not schema-scoped, so creating them once here — first,
-- before anything that references them — is enough for every schema that
-- follows. See README "Custom SQL Functions" for what each does.
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

CREATE OR REPLACE FUNCTION bytea_to_jsonb_utf8(data BYTEA)
RETURNS JSONB
IMMUTABLE STRICT LEAKPROOF PARALLEL SAFE
LANGUAGE SQL AS $$
  SELECT convert_from(data, 'UTF8')::jsonb;
$$;
