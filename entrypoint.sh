#!/usr/bin/env bash
set -euo pipefail

: "${PUID:=1000}"
: "${PGID:=1000}"
groupmod -o -g "$PGID" pzuser
usermod -o -u "$PUID" pzuser

SERVER_NAME="${PZ_SERVERNAME:-pzserver}"
INI_DIR="/home/pzuser/Zomboid/Server"
INI_FILE="$INI_DIR/${SERVER_NAME}.ini"
SANDBOX_FILE="$INI_DIR/${SERVER_NAME}_SandboxVars.lua"
RCON_CONF="/home/pzuser/rcon.yml"
RCON_PORT="${PZ_RCONPort:-27015}"

mkdir -p "$INI_DIR"

# env_file already puts every PZ_* / PZ_SBX_* var into this process's
# environment, so envsubst picks all of them up with no explicit list
if [ ! -f "$INI_FILE" ]; then
  echo "[entrypoint] first run: generating $INI_FILE from template"
  envsubst < /home/pzuser/server.ini.template > "$INI_FILE"
fi

PRESET="${PZ_SANDBOX_PRESET:-Custom}"
if [ ! -f "$SANDBOX_FILE" ]; then
  if [ "$PRESET" = "Custom" ]; then
    echo "[entrypoint] first run: generating $SANDBOX_FILE from template"
    envsubst < /home/pzuser/sandboxvars.lua.template > "$SANDBOX_FILE"
  else
    echo "[entrypoint] first run: using the $PRESET preset as-is"
    cp "/home/pzuser/presets/${PRESET}.lua" "$SANDBOX_FILE"
  fi
fi

cat > "$RCON_CONF" <<EOF
default:
  address: "127.0.0.1:${RCON_PORT}"
  password: "${PZ_RCONPassword}"
EOF

# memory settings
JSON=/home/pzuser/pzserver/ProjectZomboid64.json
jq --arg xmx "-Xmx${MEMORY_XMX_GB:-8}G" \
   '.vmArgs |= (map(select(startswith("-Xmx") | not)) + [$xmx])' "$JSON" > "$JSON.tmp" && mv "$JSON.tmp" "$JSON"
if [ -n "${MEMORY_XMS_GB:-}" ]; then
  jq --arg xms "-Xms${MEMORY_XMS_GB}G" \
     '.vmArgs |= (map(select(startswith("-Xms") | not)) + [$xms])' "$JSON" > "$JSON.tmp" && mv "$JSON.tmp" "$JSON"
fi

chown -R pzuser:pzuser /home/pzuser/Zomboid /home/pzuser/pzserver "$RCON_CONF"

cd /home/pzuser/pzserver
gosu pzuser ./start-server.sh \
  -servername "$SERVER_NAME" \
  -adminusername "${PZ_ADMIN_USERNAME:-admin}" \
  -adminpassword "${PZ_ADMIN_PASSWORD}" &
PZ_PID=$!

term_handler() {
  echo "[entrypoint] got sigterm, trying rcon save+quit"
  if gosu pzuser rcon-cli -c "$RCON_CONF" save && gosu pzuser rcon-cli -c "$RCON_CONF" quit; then
    echo "[entrypoint] rcon shutdown ok"
  else
    echo "[entrypoint] rcon shutdown failed, killing it"
    kill -TERM "$PZ_PID" 2>/dev/null || true
  fi
  wait "$PZ_PID"
}
trap term_handler SIGTERM SIGINT

wait "$PZ_PID"
