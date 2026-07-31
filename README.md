# pzserver-docker

## What is this
Dockerized Project Zomboid (Build 42) dedicated server.
### Main features
- RCON `save`+`quit` on `docker stop`, never a raw signal to the game process
- Every `server.ini` and `SandboxVars.lua` setting exposed as its own env var
- 6 sandbox presets: Apocalypse, Outbreak, Extinction, Rising, SixTunedOutbreak, SixTunedOutbreakLite
- Crash auto-restart, no restart on intentional stop
- Healthcheck, non-root process, PUID/PGID mapping

### Usage
## Build locally
```bash
docker compose build
docker compose up -d
```

Ports: `16261/udp`, `16262/udp` (game). `27015/tcp` rcon, localhost only.

## Config
`.env.example` covers every setting in pzwiki.net/wiki/Server_settings. ini keys: `PZ_<key>`. SandboxVars top level: `PZ_SBX_<key>`. Nested: `PZ_SBX_<Table>_<key>`.

Applies on first boot only. Edit the generated file directly after, or wipe the volume.

### Presets
`PZ_SANDBOX_PRESET`: `Apocalypse` / `Outbreak` / `Extinction` / `Rising` / `SixTunedOutbreak` / `SixTunedOutbreakLite` / `Custom`. Presets use the shipped file as-is. `Custom` uses the `PZ_SBX_*` vars, ignored otherwise.

#### SixTunedOutbreak
Outbreak base, tuned for 4-6 players:

- `PopulationMultiplier` 0.65 -> 1.5, `PopulationStartMultiplier` 1.0 -> 1.2, `PopulationPeakMultiplier` 1.5 -> 2.0
- Loot categories 0.6-1.2 -> 1.5, `WeaponLootNew` -> 2.0
- `CarSpawnRate` 4 -> 5, `BloodLevel` 3 -> 5
- `GeneratorFuelConsumption` 0.1 -> 0.03
- `MinutesPerPage` 2.0 -> 0.5
- `MetaEvent` 2 -> 3, `CarAlarm` 3 -> 4, `VehicleStoryChance`/`ZoneStoryChance` 3 -> 4
- `Helicopter`/`SirenShutoffHours`: stock, off

Full file: `presets/SixTunedOutbreak.lua`

#### SixTunedOutbreakLite
Same as SixTunedOutbreak, but zombie population stays at vanilla Outbreak intensity (`PopulationMultiplier`/`PopulationStartMultiplier`/`PopulationPeakMultiplier` untouched). Loot, reading speed, cars, etc. stay tuned.

Full file: `presets/SixTunedOutbreakLite.lua`

## Sizing
B42 baseline ~6GB, +0.5GB/player, grows with playtime. 2-4 players: 8GB+. 5-6: 10-12GB. `MEMORY_XMX_GB` caps usage, the server crashes if it needs more. Leave 1-2GB for OS/docker.

## Shutdown
`docker stop` triggers rcon `save` then `quit` from the entrypoint. See `entrypoint.sh`.

