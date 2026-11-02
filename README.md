# Little Pond

A cheerful, low-poly, endless fish-eating game for Roblox. All assets are built from Roblox primitives; no downloaded models, plugins, or paid assets are required.

## Play

Open **Little Pond.rbxlx** in Roblox Studio and press **Play**. Click **Let’s make a splash!** or press Enter. The server always contains 20 active fish: players plus replacement bots.

- **W / S (up / down arrows):** paddle forward / reverse. **A / D (left / right arrows):** turn your fish. Steering follows its nose, independent of the camera.
- **Space / E:** rise. **Q / Control:** dive.
- **Shift / controller X / Zoom! button:** spend 20% of the current tier’s bar for a 1.2-second, 1.8× speed boost. Not enough progress means no boost. Boosts cannot stack, never lower your tier, and preserve your accumulated score. The whale bar holds refillable boost fuel from further eating.
- **Right mouse drag:** orbit the camera. **Scroll:** zoom.
- **Gamepad:** left stick turns and paddles, right stick rotates, shoulder buttons rise/dive, A starts.
- **Touch:** on-screen directional and rise/dive buttons.

Start by diving to the green seaweed on the sandy floor. Eat it by touching it. Open **Pond book → Map** for the radar: you are dark teal, threats are coral, and other fish are green. Dots indicate positions, not depth. A dot after a leaderboard name indicates a bot.

## Rules

| Tier | Total growth required | Diet |
| --- | ---: | --- |
| Minnow | 0 | Seaweed |
| Perch | 8 | Minnows + seaweed |
| Bass | 30 | Lower tiers + seaweed |
| Tuna | 75 | Lower tiers + seaweed |
| Marlin | 160 | Lower tiers + seaweed |
| Shark | 310 | Lower tiers + seaweed |
| Whale | 550 | Lower tiers, seaweed, lower-score whales |

Touching lower-tier fish eats them. Same-tier fish cannot eat each other, except whales: the higher accumulated score wins, and exact ties are safe. Smaller prey gives diminishing growth and score. Seaweed respawns after 11 seconds. There is no timer, final round, or victory reset.

Getting eaten resets **growth and tier** to minnow while preserving **accumulated session score**. Scores are intentionally session-only and reset upon leaving the server; no DataStore access is needed. Spawns have 5 seconds of protection. Players on the welcome screen remain protected until starting.

The irregular pond spans roughly 527 × 492 studs, with a deep pocket, raised shelves, and banks that slope up to the waterline. Water is a visual surface; swimming is custom server-controlled movement, so there is no avatar, oxygen meter, or realistic buoyancy.

## Multiplayer and publishing

The local place is ready for Studio playtesting. Publishing is not performed by the build script.

1. Use Studio's **File → Publish to Roblox** when ready.
2. In the published place's Creator Dashboard settings, set **Maximum Players to 20**. This Roblox matchmaking setting cannot be changed by a normal game script. The server also rejects admission above 20 as a fallback.
3. Choose the desired audience/access permissions.
4. Use Studio's **Server & Clients** test with 2 or more clients to inspect joining, leaving, and replication before making the experience public.

Bots fill empty slots, leave when humans join, and return when humans leave. Bots forage, pursue edible fish, flee predators, evolve, and respawn under the same rules as players. Initial bots are distributed across tiers to make the ecosystem interesting immediately.

## Development

- `src/shared/Config.luau`: tier names, sizes, speeds, thresholds, reward and eating rules.
- `src/shared/FishFactory.luau`: procedural faceted fish, fins, eyes, and species features.
- `src/server/Game.server.luau`: authoritative fixed-step simulation, collision eating, bots, spawns, remote validation.
- `src/client/Game.client.luau`: camera, keyboard/touch/gamepad input, HUD, radar, tutorial.
- `tools/build.py`: deterministic scenery and self-contained place generation.
- `tests/Rules.luau`: engine assertions for tier boundaries, eating matrix, diminishing rewards, pond bounds, and population.

Rebuild from source using Python 3 (standard library only):

```sh
python3 tools/build.py
```

Close the existing Studio tab before reopening a rebuilt file. Rebuilding replaces the generated place, so preserve any hand-made scene edits in a separate copy or add them to the generator.

`default.project.json` is optional Rojo source-sync configuration for the already-generated place; the Python build is the complete, dependency-free build path.

## Architecture and tests

Clients submit only bounded steering, depth, and thrust inputs, at 20 Hz. The server rejects non-vectors, NaN/infinite/out-of-range values, and excessive packet rates. Detailed fish art renders locally every frame: your fish predicts tank movement and blends server corrections; other fish interpolate timestamped snapshots with a 100 ms buffer. Only invisible position markers and compact snapshots replicate, avoiding movement replication for every decorative fish part. The camera follows the rendered fish. The server owns positions, scores, food availability, tiers, and all eating decisions. Players cannot send a score, victim, or target position. An input timeout prevents stale input from continuing movement.

Simulation runs at 20 Hz with smoothed acceleration and a client-follow camera. Fish are anchored models; there is no client-owned physics to exploit. Scenery is static, and there are only 20 fish and 300 renewable seaweed patches.

In Studio, the server automatically runs the rule tests and integration checks for evolution, death/score retention, whale collisions/ties, spawn protection, seaweed contact, swimming, and bot replacement. Look for `LITTLE POND TESTS PASSED` and `LITTLE POND INTEGRATION PASSED` in Output. Production servers skip these checks.

A full 20-human network load test and physical touch/controller hardware tests remain release validation tasks.

Reference: [Roblox client/server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary) and [Players.MaxPlayers](https://create.roblox.com/docs/reference/engine/classes/Players#MaxPlayers).

## Swimming and bot behavior update

All fish accelerate gradually, turn in arcs, and coast to a stop with water drag. Larger fish turn more slowly. A small stroke cadence and body sway add life without changing the movement controls. Bot cruising is slower than pursuit, with continuous gentle weaving, approach slowing, and inward steering near the shore.

Bots keep a chosen prey target rather than choosing a new fish every thought tick. A chase lasts at most 7 seconds; 2.5 seconds without closing the gap also ends it. After giving up, the bot takes a 6-second hunting break and ignores that particular fish for 14 seconds. During that break it forages or wanders, and it can still flee predators. Losing a target, its respawning, or its leaving hunting range also ends the chase.

Tune these behaviors in `src/shared/BotBrain.luau` and `src/shared/Swimming.luau`. In Studio, a bot model's `Behavior` attribute reports chase, flee, forage, or wander.

## Landscape and water effects

The pond sits inside a continuous meadow with hills and uneven tree groves. Lily coves, reeds, flowering aquatic plants, driftwood, mossy arches, river stones, a dock, stepping stones, and a small boathouse provide landmarks.

`tools/landscape.py` generates an exact height grid used both by the faceted terrain and `src/shared/WorldMap.luau`. Swimming bounds account for the irregular shoreline and each fish's required water depth. Food and spawn locations follow the sculpted bed; the radar shows the new shoreline.

Visual effects use Roblox's native bloom, sun rays, atmosphere, color correction, and local animated surface glints, bubbles, and dappled light. They require no external shader injection or uploaded textures. `src/client/Water.client.luau` controls the local effects, updated at 10 Hz.

Post-processing reference: https://create.roblox.com/docs/environment/post-processing-effects

## Playful UI

The main HUD shows a fish sticker, friendly tier name, and a smooth next-evolution bar. Growth totals, population counts, and constant rankings are hidden. Snacks produce short messages such as “nom nom!” instead of numeric popups. Whale score remains visible because it determines whale encounters.

Open **Pond book** (or Tab / gamepad Y) for Tips, Friends/score, and Map. Closing the book restores the compact HUD. Opening the book stops directional input; the multiplayer pond continues running.

## Decoration and asset polish

`tools/decorations.py` adds composed landmarks: a terracotta flowerpot, hollow willow log, three shell gardens, two ribbon-plant gardens, mushroom/daisy patches, a bench, and a rowboat. Existing stones are rounded, pine foliage uses complete pyramidal crowns, and the boathouse has a pitched roof, corner trim, porch step, and door knob.

Fish have fuller snouts, rosy cheeks, split tail fins, a horizontal whale fluke, and adjusted eyes/markings. Nameplates fade out at a shorter distance to reduce distant clutter. These are visual changes; progression and collision rules remain unchanged.
