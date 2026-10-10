CREATE TABLE stores.taxonomies
(
    id         TEXT NOT NULL,
    name       TEXT NOT NULL,
    parent_id  TEXT REFERENCES stores.taxonomies (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id)
);

CREATE UNIQUE INDEX taxonomies_sibling_name_idx ON stores.taxonomies (COALESCE(parent_id, ''), lower(name));
CREATE INDEX taxonomies_parent_id_idx ON stores.taxonomies (parent_id);

ALTER TABLE stores.products ADD COLUMN category_id TEXT REFERENCES stores.taxonomies (id);
ALTER TABLE stores.products ADD COLUMN category_name TEXT;
