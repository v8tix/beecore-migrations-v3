CREATE TABLE payments.payments
(
    id                  TEXT NOT NULL,
    user_id             TEXT NOT NULL,
    status              TEXT NOT NULL,
    platform            TEXT NOT NULL,
    request             BYTEA,
    response            BYTEA,
    amount              DECIMAL(9, 2) NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id)
);

CREATE INDEX idx_payments_user_id_updated_at ON payments.payments (user_id, updated_at DESC);

CREATE TABLE payments.invoices
(
    id         TEXT NOT NULL,
    order_id   TEXT NOT NULL,
    amount     DECIMAL(9,2) NOT NULL,
    status     TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id)
);

CREATE INDEX invoices_order_id_idx ON payments.invoices (order_id);

CREATE TABLE payments.inbox
(
    id          TEXT NOT NULL,
    name        TEXT NOT NULL,
    subject     TEXT NOT NULL,
    data        BYTEA NOT NULL,
    received_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE payments.outbox
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

CREATE INDEX payments_unpublished_idx ON payments.outbox (published_at) WHERE published_at IS NULL;
CREATE INDEX payments_partition_unpublished_idx ON payments.outbox (id_hash, id) WHERE published_at IS NULL;
CREATE INDEX payments_failed_idx ON payments.outbox (aggregate_id) WHERE failed = TRUE;