#!/usr/bin/env bash
set -euo pipefail
if [ "$(docker inspect -f '{{.State.Running}}' pzserver 2>/dev/null)" != "true" ]; then
  docker start pzserver
  echo "[$(date -Is)] pzserver container started" >> "$(dirname "$0")/maintenance.log"
fi
