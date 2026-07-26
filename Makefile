# Load Make-safe local env vars
-include local/.env

# Export loaded vars to shell commands run by make recipes
export

# ==================================================================================== #
# HELPERS
# ==================================================================================== #

## help: print this help message
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'

# ==================================================================================== #
# Install Migrate
# ==================================================================================== #

## install: install migrate (postgres driver)
.PHONY: install
install:
	@go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# ==================================================================================== #
# LOCAL MIGRATIONS
# ==================================================================================== #

## migrations/local/check: verify local migration configuration is set
.PHONY: migrations/local/check
migrations/local/check:
	@if [ -z "${MIGRATIONS_PATH}" ]; then \
		echo "Error: MIGRATIONS_PATH is not set (expected in local/.env)"; \
		exit 1; \
	fi
	@if [ -z "${LOCAL_DB_DSN}" ]; then \
		echo "Error: LOCAL_DB_DSN is not set (expected in local/.env)"; \
		exit 1; \
	fi

## migrations/local/debug: show local migration configuration
.PHONY: migrations/local/debug
migrations/local/debug:
	@echo "=== Local Migration Configuration ==="
	@echo "MIGRATIONS_PATH: ${MIGRATIONS_PATH}"
	@echo "LOCAL_DB_USER: ${LOCAL_DB_USER}"
	@echo "LOCAL_DB_HOST: ${LOCAL_DB_HOST}"
	@echo "LOCAL_DB_PORT: ${LOCAL_DB_PORT}"
	@echo "LOCAL_DB: ${LOCAL_DB}"
	@echo ""
	@echo "=== Connection String ==="
	@echo "LOCAL_DB_DSN: postgres://${LOCAL_DB_USER}:****@${LOCAL_DB_HOST}:${LOCAL_DB_PORT}/${LOCAL_DB}?sslmode=disable"

## migrations/local/up: apply all migrations to local Docker PostgreSQL
.PHONY: migrations/local/up
migrations/local/up: migrations/local/check
	@echo "Running migrations on LOCAL Docker PostgreSQL..."
	@echo "Database: ${LOCAL_DB_HOST}:${LOCAL_DB_PORT}/${LOCAL_DB}"
	migrate -path="${MIGRATIONS_PATH}" -database='${LOCAL_DB_DSN}' up
	@echo "Local migrations completed"

## migrations/local/down: revert all migrations on local Docker PostgreSQL
.PHONY: migrations/local/down
migrations/local/down: migrations/local/check
	@echo "Reverting migrations on LOCAL Docker PostgreSQL..."
	migrate -path="${MIGRATIONS_PATH}" -database='${LOCAL_DB_DSN}' down

## migrations/local/goto: migrate to specific version on local Docker PostgreSQL
.PHONY: migrations/local/goto
migrations/local/goto: migrations/local/check
	migrate -path="${MIGRATIONS_PATH}" -database='${LOCAL_DB_DSN}' goto "${GOTO}"

## migrations/local/force: force migration version on local Docker PostgreSQL
.PHONY: migrations/local/force
migrations/local/force: migrations/local/check
	migrate -path="${MIGRATIONS_PATH}" -database='${LOCAL_DB_DSN}' force "${GOTO}"

## migrations/local/version: show current migration version on local Docker PostgreSQL
.PHONY: migrations/local/version
migrations/local/version: migrations/local/check
	migrate -path="${MIGRATIONS_PATH}" -database='${LOCAL_DB_DSN}' version

## migrations/local/grant-privileges: grant privileges to local user
.PHONY: migrations/local/grant-privileges
migrations/local/grant-privileges:
	@echo "Granting privileges to ${LOCAL_DB_USER}..."
	@chmod +x local/scripts/local/grant_privileges.sh
	@./local/scripts/local/grant_privileges.sh
	@echo "Privileges granted"