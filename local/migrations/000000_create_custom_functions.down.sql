-- migrate applies down migrations in strict reverse order (7,6,5,4,2,1,0),
-- so every table in 000001/000002/000005/000006/000007 that references
-- these functions in a generated column is already gone by the time this
-- (the very last) down migration runs.
DROP FUNCTION IF EXISTS bytea_to_jsonb_utf8(BYTEA);
DROP FUNCTION IF EXISTS fnv32a(TEXT);
