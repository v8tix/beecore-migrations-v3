#!/usr/bin/env bash
# Prints the production Postgres password, URL-encoded, by reading it live
# from the server over SSH — never stored in this repo. Used by the
# `migrations/prod/*` Makefile targets to build the DSN at the point of use.
#
# URL-encoded because the generated password is base64 (openssl rand
# -base64) and can contain '/', '+', '=' — all meaningful in a postgres://
# URI (e.g. '/' reads as a path separator, breaking host:port parsing).
set -euo pipefail

SSH_KEY="${PROD_SSH_KEY:-$HOME/.ssh/id_ed25519_v8tix}"
SSH_HOST="${PROD_SSH_HOST:-v8tix@192.168.100.60}"

RAW_PASSWORD="$(ssh -i "${SSH_KEY}" -o ConnectTimeout=10 "${SSH_HOST}" "cat /home/v8tix/passwords/postgres-standalone-password.txt")"
python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "${RAW_PASSWORD}"
