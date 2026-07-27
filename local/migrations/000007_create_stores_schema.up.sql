CREATE TABLE stores.stores
(
    id            TEXT NOT NULL,
    name          TEXT NOT NULL,
    participating BOOLEAN NOT NULL DEFAULT FALSE,
    user_id       TEXT,
    address_id    TEXT,
    img_url       TEXT,
    website       TEXT,
    description   TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id)
);

CREATE INDEX participating_stores_idx ON stores.stores (participating) WHERE participating;
CREATE INDEX stores_user_id_idx ON stores.stores (user_id);

CREATE TABLE stores.products
(
    id                   TEXT NOT NULL,
    store_id             TEXT NOT NULL,
    name                 TEXT NOT NULL,
    description          TEXT NOT NULL,
    sku                  TEXT NOT NULL,
    price                DECIMAL(9,2) NOT NULL,
    category             TEXT,
    img_url              TEXT,
    video_url            TEXT,
    status               TEXT,
    quantity             INT,
    weight               DECIMAL(9,2),
    width                DECIMAL(9,2),
    height               DECIMAL(9,2),
    depth                DECIMAL(9,2),
    discount_percentage  INT,
    discount_description TEXT,
    subtotal             DECIMAL(9,2),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Single combined tsvector: name weighted 'A' (1.0), description weighted 'B'
    -- (0.4) via setweight, per Postgres's standard full-text ranking pattern.
    -- One GIN index instead of two — cheaper to maintain, same relative
    -- name-outranks-description ordering as the previous two-column design.
    lexemes              TSVECTOR GENERATED ALWAYS AS (
                             setweight(to_tsvector('spanish', COALESCE(name, '')), 'A') ||
                             setweight(to_tsvector('spanish', COALESCE(description, '')), 'B')
                         ) STORED,
    PRIMARY KEY (id)
);

CREATE INDEX store_products_idx ON stores.products (store_id);
CREATE INDEX idx_products_store_id_updated_at ON stores.products (store_id, updated_at DESC);
CREATE INDEX idx_stores_products_lexemes ON stores.products USING GIN (lexemes);

CREATE TABLE stores.events
(
    stream_id      TEXT        NOT NULL,
    stream_name    TEXT        NOT NULL,
    stream_version INT         NOT NULL,
    event_id       TEXT        NOT NULL,
    event_name     TEXT        NOT NULL,
    event_data     BYTEA       NOT NULL,
    occurred_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    causation_id   TEXT        NOT NULL,
    correlation_id TEXT        NOT NULL,
    caused_by      TEXT,
    PRIMARY KEY (stream_id, stream_name, stream_version)
);

CREATE INDEX idx_events_stream_version_event_name ON stores.events (stream_version, event_name);
CREATE INDEX idx_events_event_name_stream_id ON stores.events (event_name, stream_id);
CREATE INDEX idx_events_event_data_jsonb ON stores.events USING GIN (bytea_to_jsonb_utf8(event_data));
CREATE INDEX idx_events_causation_id ON stores.events (causation_id);
CREATE INDEX idx_events_correlation_id ON stores.events (correlation_id);
CREATE INDEX idx_events_caused_by ON stores.events (caused_by);

CREATE TABLE stores.snapshots
(
    stream_id        TEXT        NOT NULL,
    stream_name      TEXT        NOT NULL,
    stream_version   INT         NOT NULL,
    snapshot_name    TEXT        NOT NULL,
    snapshot_data    BYTEA       NOT NULL,
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (stream_id, stream_name)
);

CREATE TABLE stores.inbox
(
    id          TEXT NOT NULL,
    name        TEXT NOT NULL,
    subject     TEXT NOT NULL,
    data        BYTEA NOT NULL,
    received_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE stores.outbox
(
    id             TEXT NOT NULL,
    name           TEXT NOT NULL,
    subject        TEXT NOT NULL,
    data           BYTEA NOT NULL,
    retry_count    INT DEFAULT 0,
    last_retry_at  TIMESTAMPTZ,
    next_retry_at  TIMESTAMPTZ,
    failed         BOOLEAN NOT NULL DEFAULT FALSE,
    published_at   TIMESTAMPTZ,
    aggregate_id   TEXT NOT NULL DEFAULT '',
    id_hash        BIGINT GENERATED ALWAYS AS (fnv32a(aggregate_id)) STORED,
    PRIMARY KEY (id)
);

CREATE INDEX stores_unpublished_idx ON stores.outbox (published_at) WHERE published_at IS NULL;
CREATE INDEX stores_partition_unpublished_idx ON stores.outbox (id_hash, id) WHERE published_at IS NULL;
CREATE INDEX stores_failed_idx ON stores.outbox (aggregate_id) WHERE failed = TRUE;