CREATE TABLE users.users
(
    id            TEXT NOT NULL,
    dni           TEXT,
    first_name    TEXT NOT NULL,
    last_name     TEXT NOT NULL,
    email         TEXT NOT NULL UNIQUE,
    password      TEXT NOT NULL,
    birthday      TEXT,
    genre         TEXT,
    phone         TEXT,
    img_url       TEXT,
    website       TEXT,
    enabled       BOOLEAN NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id)
);

CREATE TABLE users.addresses (
    id                  TEXT NOT NULL,
    user_id             TEXT NOT NULL REFERENCES users.users(id) ON DELETE CASCADE,
    type                TEXT NOT NULL,
    country             TEXT NOT NULL,
    state               TEXT NOT NULL,
    city                TEXT NOT NULL,
    postal_code         TEXT NOT NULL,
    main_street         TEXT NOT NULL,
    secondary_street    TEXT NOT NULL,
    numeration          TEXT NOT NULL,
    phone               TEXT NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id)
);

CREATE INDEX idx_addresses_user_id ON users.addresses (user_id);
CREATE INDEX idx_addresses_user_id_id ON users.addresses (user_id, id);

CREATE TABLE users.inbox
(
    id          TEXT NOT NULL,
    name        TEXT NOT NULL,
    subject     TEXT NOT NULL,
    data        BYTEA NOT NULL,
    received_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE users.outbox
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

CREATE INDEX users_unpublished_idx ON users.outbox (published_at) WHERE published_at IS NULL;
CREATE INDEX users_partition_unpublished_idx ON users.outbox (id_hash, id) WHERE published_at IS NULL;
CREATE INDEX users_failed_idx ON users.outbox (aggregate_id) WHERE failed = TRUE;

CREATE TABLE users.roles
(
    id         TEXT NOT NULL PRIMARY KEY,
    name       TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE users.permissions
(
    id         TEXT NOT NULL PRIMARY KEY,
    name       TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE users.user_roles
(
    user_id    TEXT REFERENCES users.users (id),
    role_id    TEXT REFERENCES users.roles (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE users.role_permissions
(
    role_id       TEXT REFERENCES users.roles (id),
    permission_id TEXT REFERENCES users.permissions (id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (role_id, permission_id)
);

CREATE INDEX IF NOT EXISTS idx_role_permissions_role ON users.role_permissions(role_id);
CREATE INDEX IF NOT EXISTS idx_role_permissions_permission ON users.role_permissions(permission_id);

CREATE TABLE users.role_hierarchy
(
    parent_role_id TEXT REFERENCES users.roles (id),
    child_role_id  TEXT REFERENCES users.roles (id),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (parent_role_id, child_role_id)
);

CREATE INDEX IF NOT EXISTS idx_role_hierarchy_parent ON users.role_hierarchy(parent_role_id);
CREATE INDEX IF NOT EXISTS idx_role_hierarchy_child ON users.role_hierarchy(child_role_id);

CREATE TABLE users.resources
(
    id         TEXT NOT NULL PRIMARY KEY,
    name       TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE users.audit_logs
(
    id          TEXT NOT NULL PRIMARY KEY,
    user_id     TEXT REFERENCES users.users (id),
    action      TEXT,
    resource_id TEXT REFERENCES users.resources (id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE users.tokens
(
    id         TEXT NOT NULL PRIMARY KEY,
    user_id    TEXT NOT NULL REFERENCES users.users (id) ON DELETE CASCADE,
    token      TEXT NOT NULL UNIQUE,
    scope      TEXT NOT NULL,
    expiry     TIMESTAMPTZ NOT NULL,
    is_revoked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_user_token_type UNIQUE (user_id, scope)
);

CREATE INDEX idx_tokens_user_id ON users.tokens (user_id);
CREATE INDEX idx_tokens_type ON users.tokens (scope);
CREATE INDEX idx_tokens_is_revoked ON users.tokens (is_revoked);