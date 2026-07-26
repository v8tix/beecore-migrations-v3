CREATE TABLE ordering.orders
(
    id          TEXT NOT NULL,
    user_id     TEXT NOT NULL,
    payment_id  TEXT NOT NULL,
    basket_id   TEXT NOT NULL,
    items       BYTEA NOT NULL,
    status      TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id)
);

CREATE TABLE ordering.events
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

CREATE INDEX idx_events_stream_version_event_name ON ordering.events (stream_version, event_name);
CREATE INDEX idx_events_event_name_stream_id ON ordering.events (event_name, stream_id);
CREATE INDEX idx_events_stream_name_occurred_at ON ordering.events (stream_name, stream_id, occurred_at DESC);
CREATE INDEX idx_events_event_data_jsonb ON ordering.events USING GIN (bytea_to_jsonb_utf8(event_data));
CREATE INDEX idx_events_causation_id ON ordering.events (causation_id);
CREATE INDEX idx_events_correlation_id ON ordering.events (correlation_id);
CREATE INDEX idx_events_caused_by ON ordering.events (caused_by);

CREATE TABLE ordering.snapshots
(
    stream_id        TEXT        NOT NULL,
    stream_name      TEXT        NOT NULL,
    stream_version   INT         NOT NULL,
    snapshot_name    TEXT        NOT NULL,
    snapshot_data    BYTEA       NOT NULL,
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (stream_id, stream_name)
);

CREATE TABLE ordering.inbox
(
    id          TEXT NOT NULL,
    name        TEXT NOT NULL,
    subject     TEXT NOT NULL,
    data        BYTEA NOT NULL,
    received_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE ordering.outbox
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

CREATE INDEX ordering_unpublished_idx ON ordering.outbox (published_at) WHERE published_at IS NULL;
CREATE INDEX ordering_partition_unpublished_idx ON ordering.outbox (id_hash, id) WHERE published_at IS NULL;
CREATE INDEX ordering_failed_idx ON ordering.outbox (aggregate_id) WHERE failed = TRUE;