#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
RCON_PASS=$(grep '^PZ_RCONPassword=' .env | cut -d= -f2-)
RCON_PORT=$(grep '^PZ_RCONPort=' .env | cut -d= -f2-)
rcon-cli -a "127.0.0.1:${RCON_PORT:-27015}" -p "$RCON_PASS" "$@"
