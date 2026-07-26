CREATE TABLE baskets.stores_cache
(
    id         TEXT NOT NULL,
    name       TEXT NOT NULL,
    user_id    TEXT NOT NULL,
    address_id TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id)
);

CREATE TABLE baskets.products_cache
(
    id                   TEXT NOT NULL,
    store_id             TEXT NOT NULL,
    name                 TEXT NOT NULL,
    price                DECIMAL(9,2) NOT NULL,
    description          TEXT,
    sku                  TEXT,
    category             TEXT,
    img_url              TEXT,
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
    PRIMARY KEY (id)
);

CREATE TABLE baskets.events
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

CREATE INDEX idx_events_stream_version_event_name ON baskets.events (stream_version, event_name);
CREATE INDEX idx_events_event_name_stream_id ON baskets.events (event_name, stream_id);
CREATE INDEX idx_events_event_data_jsonb ON baskets.events USING GIN (bytea_to_jsonb_utf8(event_data));
CREATE INDEX idx_events_causation_id ON baskets.events (causation_id);
CREATE INDEX idx_events_correlation_id ON baskets.events (correlation_id);
CREATE INDEX idx_events_caused_by ON baskets.events (caused_by);

CREATE TABLE baskets.snapshots
(
    stream_id        TEXT        NOT NULL,
    stream_name      TEXT        NOT NULL,
    stream_version   INT         NOT NULL,
    snapshot_name    TEXT        NOT NULL,
    snapshot_data    BYTEA       NOT NULL,
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (stream_id, stream_name)
);

CREATE TABLE baskets.inbox
(
    id          TEXT NOT NULL,
    name        TEXT NOT NULL,
    subject     TEXT NOT NULL,
    data        BYTEA NOT NULL,
    received_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE baskets.outbox
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

CREATE INDEX basket_unpublished_idx ON baskets.outbox (published_at) WHERE published_at IS NULL;
CREATE INDEX basket_partition_unpublished_idx ON baskets.outbox (id_hash, id) WHERE published_at IS NULL;
CREATE INDEX basket_failed_idx ON baskets.outbox (aggregate_id) WHERE failed = TRUE;

CREATE TABLE baskets.baskets
(
    id         TEXT NOT NULL,
    user_id    TEXT NOT NULL,
    status     TEXT NOT NULL CHECK (status IN ('open', 'canceled', 'checked_out')),
    payment_id TEXT,
    items      JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id)
);

CREATE INDEX baskets_user_id_idx ON baskets.baskets (user_id);
CREATE INDEX baskets_status_idx ON baskets.baskets (status);
CREATE INDEX baskets_open_by_user_idx ON baskets.baskets (user_id) WHERE status = 'open';
