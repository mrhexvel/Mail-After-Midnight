# Mail After Midnight

Rojo project for a mobile-first Roblox sorting game. The current implementation covers development stage 0: a static test room, shared tuning configuration, and runnable client/server entry points.

## Prerequisites

- Roblox Studio with the Rojo plugin.
- Rojo 7.7.0 and Wally 0.3.2. They are pinned in `rokit.toml`.

Install the toolchain and dependencies from the repository root:

```bash
rokit install
wally install
```

## Build A Place File

```bash
rojo build default.project.json -o Mail_After_Midnight.rbxlx
```

Open `Mail_After_Midnight.rbxlx` in Roblox Studio. This is a local build and does not publish the experience.

## Live Sync With Studio

Open the **Mail After Midnight** place (`placeId: 112851981010774`) in Studio, then run:

```bash
rojo serve default.project.json
```

Connect the Studio Rojo plugin to `localhost:34872`. The project restricts live sync to the place ID above to reduce the risk of syncing into the wrong experience.

## Stage 0 Manual Test

1. Build the place or connect the Rojo plugin.
2. Confirm `Workspace.SortingRoom` contains the incoming table, rules board, three decision zones, walls, lights, and `PlayerSpawn`.
3. Press **Play**. Confirm the character spawns inside the room and can walk between the table, rules board, and all three zones.
4. Confirm the board text and the `SEND`, `RETURN`, and `ISOLATE` labels are readable without relying only on pad color.
5. Open **View > Output**. Confirm both `Client ready` and `Stage 0 room ready` appear without red errors.
6. Stop the playtest and use Studio's device emulator with a narrow phone preset. Repeat the visibility and movement checks.

Stage 0 contains no parcel interaction or round loop yet. The box on the table is a visual placeholder.

## Multiplayer Test Setup

Multiplayer gameplay starts in later stages, but the Studio setup is:

1. Open the **Test** tab.
2. Select **Server & Clients**.
3. Choose between one and four clients.
4. Start the session and inspect each client separately.

Set the experience's maximum player count to four in Creator Dashboard before multiplayer acceptance testing.

## Data Store Safety

Persistent profiles are not implemented in stage 0. When they are added, use a separate unpublished or private test experience. Do not enable Studio access to API services for the production experience's live data.

## Test Publication

Use **File > Publish to Roblox As...** and select a private test experience owned by the intended account or group. Keep it private and grant access only to invited testers until the release checklist is complete.

## Project Layout

```text
src/client/init.client.luau  Client entry point
src/server/init.server.luau  Server entry point
src/shared/Config.luau       Central gameplay tuning
src/world.project.json       Static sorting-room model
```

Wally installs shared packages into `Packages` and server-only packages into `ServerPackages`. Both generated directories are ignored by Git.
