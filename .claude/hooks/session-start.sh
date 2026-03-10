#!/bin/bash
set -euo pipefail

POSTGRES_DATA="/var/lib/paperclip/db"
POSTGRES_PORT=54329
POSTGRES_LOG="/var/lib/paperclip/postgres.log"
COMPANY_ID="ecbdbf73-50ed-40a1-8625-b756c3e58d15"
PAPERCLIP_URL="http://localhost:3100"

# ── 1. Start system PostgreSQL if not running ────────────────────────────────
if su -s /bin/bash postgres -c \
    "/usr/lib/postgresql/16/bin/pg_ctl -D $POSTGRES_DATA status" &>/dev/null; then
  echo "[paperclip] PostgreSQL already running"
else
  echo "[paperclip] Starting PostgreSQL..."
  su -s /bin/bash postgres -c \
    "/usr/lib/postgresql/16/bin/pg_ctl -D $POSTGRES_DATA -l $POSTGRES_LOG -o '-p $POSTGRES_PORT' start"
  sleep 2
fi

# ── 2. Start Paperclip server if not responding ──────────────────────────────
if curl -sf "$PAPERCLIP_URL/api/health" &>/dev/null; then
  echo "[paperclip] Server already running at $PAPERCLIP_URL"
else
  echo "[paperclip] Starting Paperclip server..."
  cd /home/user/paperclip
  PAPERCLIP_MIGRATION_PROMPT=never nohup pnpm dev:once \
    > /root/.paperclip/instances/default/logs/server.log 2>&1 &
  # Wait up to 20s for it to be ready
  for i in $(seq 1 20); do
    sleep 1
    if curl -sf "$PAPERCLIP_URL/api/health" &>/dev/null; then
      echo "[paperclip] Server ready"
      break
    fi
  done
fi

# ── 3. Export PAPERCLIP_* env vars for this session ──────────────────────────
# These are the ClaudeCoder agent credentials (the agent this session runs as)
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  cat >> "$CLAUDE_ENV_FILE" << EOF
export PAPERCLIP_API_URL='$PAPERCLIP_URL'
export PAPERCLIP_COMPANY_ID='$COMPANY_ID'
export PAPERCLIP_AGENT_ID='89e3b16f-c260-46b6-8d78-384ef3a98a52'
export PAPERCLIP_API_KEY='pcp_a8ac569498482d4b39de1d8c9858610eb77081c34d67a223'
EOF
  echo "[paperclip] Exported PAPERCLIP_* env vars for ClaudeCoder agent"
fi

echo "[paperclip] Session ready — Paperclip UI: $PAPERCLIP_URL"
