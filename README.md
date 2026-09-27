# Mail After Midnight

Rojo project for a mobile-first Roblox sorting game. The current implementation covers development stage 1: a server-authoritative round loop with five parcel templates, classification, temporary rewards, error limits, replay, and responsive UI.

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

## Stage 1 Manual Test

1. Build the place or connect the Rojo plugin.
2. Press **Play** and confirm the preparation countdown starts at ten seconds.
3. After the active shift starts, wait no more than ten seconds for a parcel to appear on the incoming table.
4. Approach the parcel and activate **Examine parcel**. Confirm the inspection card shows district, stamp field, seal, movement, and all three action buttons.
5. Resolve several parcels. A correct answer must add one personal correct result and two tokens. A wrong answer must add one error and display the rule that determined the answer.
6. Verify the priority cases: red seal plus missing stamp is isolated; movement plus an unknown district is isolated.
7. Make five incorrect choices. Confirm the office closes once, no completion bonus is awarded, and the results screen appears.
8. Select **Play Again** several times quickly. Confirm exactly one new preparation phase starts and all temporary counters and parcel objects reset.
9. Complete a shift by timer. Confirm the results include the ten-token completion bonus.
10. Open **View > Output** and confirm there are no red runtime errors.
11. Repeat the full interaction using Studio's device emulator with a narrow landscape phone preset. Confirm the HUD, parcel card, rules, results, and all action buttons remain visible and usable.

Stage 1 intentionally uses one active parcel at a time. Queueing up to three parcels, multi-user claims, atmospheric events, persistence, tutorial flow, and cosmetics belong to later stages.

## Unit Tests

The project includes isolated tests for parcel classification and reward rules under `ServerStorage.UnitTest`.

1. Start a Play session.
2. Open the server Command Bar.
3. Run:

```lua
require(game.ServerStorage.UnitTest.RunUnitTest)()
```

The expected summary is `11 run, 11 passed, 0 failed`. `ServerScriptService.UnitTestRunner` is disabled by default; it can be enabled temporarily to run the same suite at server startup.

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
src/client/                  Client controller and responsive UI
src/server/Data/             Server-only parcel templates
src/server/Logic/            Pure server reward rules
src/server/Services/         Networking, parcels, and round state
src/shared/                  Shared config, protocol, strings, and parcel rules
src/tests/                   Server-only unit-test harness and cases
src/world.project.json       Static sorting-room model
```

Wally installs shared packages into `Packages` and server-only packages into `ServerPackages`. Both generated directories are ignored by Git.
