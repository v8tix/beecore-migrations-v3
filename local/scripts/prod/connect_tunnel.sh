#!/usr/bin/env bash
# Opens a tunnel from localhost:5433 to the production Postgres instance
# (postgres-standalone.postgres-standalone.svc.cluster.local:5432 inside the
# microk8s cluster at 192.168.100.60).
#
# The in-cluster Service DNS name isn't resolvable outside the cluster, so a
# single SSH connection does double duty: `-L` tunnels localhost:5433 to a
# port on the remote server, and the remote command run over that same SSH
# session is `microk8s kubectl port-forward`, which bridges that server-local
# port into the cluster. One `ssh` process, no separate tunnel processes to
# keep in sync.
#
# Idempotent — safe to re-run; kills any stale tunnel first.
#
# Usage: ./connect_tunnel.sh
# Override via env vars: SSH_KEY, SSH_HOST, LOCAL_PORT, REMOTE_PORT

set -euo pipefail

SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519_v8tix}"
SSH_HOST="${SSH_HOST:-v8tix@192.168.100.60}"
LOCAL_PORT="${LOCAL_PORT:-5433}"
REMOTE_PORT="${REMOTE_PORT:-5433}"
PF_LOG="/tmp/pf-postgres-prod-tunnel.log"
PF_PID_FILE="/tmp/pf-postgres-prod-tunnel.pid"

echo "==> Restarting production Postgres tunnel on localhost:${LOCAL_PORT}..."
pkill -f "ssh.*-L ${LOCAL_PORT}:localhost:${REMOTE_PORT}.*${SSH_HOST}" 2>/dev/null || true
sleep 1

nohup ssh -i "${SSH_KEY}" -L "${LOCAL_PORT}:localhost:${REMOTE_PORT}" "${SSH_HOST}" \
  "microk8s kubectl -n postgres-standalone port-forward svc/postgres-standalone ${REMOTE_PORT}:5432" \
  > "${PF_LOG}" 2>&1 &
disown
echo $! > "${PF_PID_FILE}"
sleep 3

if ! grep -q "Forwarding from" "${PF_LOG}"; then
  echo "ERROR: tunnel did not start cleanly — see ${PF_LOG}:" >&2
  cat "${PF_LOG}" >&2
  exit 1
fi

echo "==> Verifying localhost:${LOCAL_PORT}..."
if ! (exec 3<>"/dev/tcp/localhost/${LOCAL_PORT}") 2>/dev/null; then
  echo "WARNING: could not open a TCP connection to localhost:${LOCAL_PORT} — check ${PF_LOG}" >&2
else
  exec 3<&- 3>&-
fi

echo "==> Ready: localhost:${LOCAL_PORT} -> production postgres-standalone"
