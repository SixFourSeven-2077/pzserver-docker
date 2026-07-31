#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
LOG="$(pwd)/scripts/maintenance.log"

echo "[$(date -Is)] starting nightly save+stop" >> "$LOG"
./scripts/pz-cmd.sh 'servermsg "Server restarting in 5 minutes for nightly maintenance."'
sleep 240
./scripts/pz-cmd.sh 'servermsg "Restarting now, saving and stopping."'
sleep 45

# entrypoint.sh catches the stop signal and does rcon save+quit itself
docker stop pzserver

echo "[$(date -Is)] docker stop issued" >> "$LOG"
