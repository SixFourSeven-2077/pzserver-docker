# build rcon-cli
FROM golang:1.23-alpine AS rcon-builder
ARG RCON_VERSION=0.10.3
WORKDIR /build
RUN apk add --no-cache git \
 && git clone --branch v${RCON_VERSION} --depth 1 \
      https://github.com/gorcon/rcon-cli.git . \
 && CGO_ENABLED=0 go build -o /rcon-cli ./cmd/gorcon

# actual server image
FROM debian:12-slim

ARG PZ_APPID=380870
# empty = stable (b42 right now), or "legacy41" for old b41 saves
ARG PZ_BRANCH=""
ARG GOSU_VERSION=1.17
ARG DEPOT_DOWNLOADER_VERSION=3.4.0

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      curl ca-certificates unzip tar gettext-base tini jq procps \
 && curl -sSL -o /usr/local/bin/gosu \
      "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64" \
 && chmod +x /usr/local/bin/gosu \
 && curl -sL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
 && chmod +x /tmp/dotnet-install.sh \
 && /tmp/dotnet-install.sh --channel 8.0 --runtime dotnet --install-dir /usr/share/dotnet \
 && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
 && rm /tmp/dotnet-install.sh \
 && curl -sL \
      "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_${DEPOT_DOWNLOADER_VERSION}/DepotDownloader-linux-x64.zip" \
      -o /tmp/dd.zip \
 && mkdir -p /depotdownloader && unzip /tmp/dd.zip -d /depotdownloader \
 && chmod +x /depotdownloader/DepotDownloader && rm /tmp/dd.zip \
 && rm -rf /var/lib/apt/lists/*

COPY --from=rcon-builder /rcon-cli /usr/local/bin/rcon-cli

RUN useradd -m -u 1000 -d /home/pzuser -s /bin/bash pzuser
USER pzuser
WORKDIR /home/pzuser
RUN mkdir -p pzserver

RUN args="-app ${PZ_APPID} -dir /home/pzuser/pzserver -validate"; \
    if [ -n "${PZ_BRANCH}" ]; then args="$args -branch ${PZ_BRANCH}"; fi; \
    /depotdownloader/DepotDownloader $args

USER root
COPY entrypoint.sh server.ini.template sandboxvars.lua.template /home/pzuser/
COPY presets/ /home/pzuser/presets/
RUN chmod +x /home/pzuser/entrypoint.sh \
 && chmod +x /home/pzuser/pzserver/start-server.sh /home/pzuser/pzserver/ProjectZomboid64 2>/dev/null \
 && find /home/pzuser/pzserver/jre64/bin -type f -exec chmod +x {} + 2>/dev/null || true

ENV PUID=1000 \
    PGID=1000 \
    PZ_ADMIN_USERNAME=admin \
    PZ_ADMIN_PASSWORD="" \
    MEMORY_XMX_GB=8 \
    MEMORY_XMS_GB=""

VOLUME /home/pzuser/Zomboid

EXPOSE 16261/udp 16262/udp 27015/tcp

HEALTHCHECK --start-period=5m --interval=30s \
  CMD pgrep -f ProjectZomboid64 > /dev/null || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "/home/pzuser/entrypoint.sh"]
