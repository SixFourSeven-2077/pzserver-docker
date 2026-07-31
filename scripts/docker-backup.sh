#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
STAMP=$(date +%Y%m%d-%H%M)
DEST="$(pwd)/backups"
mkdir -p "$DEST"

# server should be stopped here, safe to read the volume
docker run --rm \
  -v pzserver-docker_pzdata:/data:ro \
  -v "$DEST":/backup \
  alpine tar czf "/backup/zomboid-$STAMP.tar.gz" -C /data .

find "$DEST" -name 'zomboid-*.tar.gz' -mtime +7 -delete
echo "[$(date -Is)] backup written: zomboid-$STAMP.tar.gz" >> "$(pwd)/scripts/maintenance.log"
