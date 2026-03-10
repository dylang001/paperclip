#!/usr/bin/env bash
# Start Paperclip dev environment
# Handles the system PostgreSQL requirement when running as root

set -e

POSTGRES_DATA="/var/lib/paperclip/db"
POSTGRES_PORT=54329
POSTGRES_LOG="/var/lib/paperclip/postgres.log"

# Start system PostgreSQL if not running
if ! su -s /bin/bash postgres -c "/usr/lib/postgresql/16/bin/pg_ctl -D $POSTGRES_DATA status" &>/dev/null; then
  echo "[paperclip] Starting PostgreSQL..."
  su -s /bin/bash postgres -c "/usr/lib/postgresql/16/bin/pg_ctl -D $POSTGRES_DATA -l $POSTGRES_LOG -o '-p $POSTGRES_PORT' start"
  sleep 2
else
  echo "[paperclip] PostgreSQL already running"
fi

# Start Paperclip server
echo "[paperclip] Starting Paperclip server..."
PAPERCLIP_MIGRATION_PROMPT=never pnpm dev:once
