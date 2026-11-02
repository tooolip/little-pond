# Little Pond

An endless, low-poly fish-eating game for Roblox. Start as a minnow, eat your way up to a whale, and explore a pond filled with procedural fish, seaweed, lily coves, and other players.

All scenery and fish are built from Roblox primitives. The project needs no downloaded models, paid plugins, or external art assets.

## Play locally

1. Clone or download the repository.
2. Open **Little Pond.rbxlx** in Roblox Studio.
3. Press **Play**, then choose **Let’s make a splash!** or press Enter.

The pond maintains 20 active fish. Bots fill empty places and leave as players join.

## Controls

| Input | Action |
| --- | --- |
| W / S or up / down arrows | Paddle forward / reverse |
| A / D or left / right arrows | Turn |
| Space / E | Rise |
| Q / Control | Dive |
| Shift | Boost when enough growth is available |
| Right mouse drag / scroll | Orbit camera / zoom |
| Tab | Open the Pond book with tips, scores, and map |

Gamepad and touch controls are included. Steering follows the fish's direction, independently of the camera.

## How it works

Eat seaweed and smaller fish to grow through seven tiers: minnow, perch, bass, tuna, marlin, shark, and whale. Same-tier fish cannot eat each other, except whales: the whale with the higher score wins.

Getting eaten resets your size while retaining your session score. Leaving the server resets that score; the game does not use persistent DataStore progress. Boosting spends growth progress without lowering your tier. There is no round timer or victory reset.

The server owns movement rules, growth, scores, and eating decisions. Clients submit bounded input and render their fish with prediction and interpolation. Bots use the same gameplay rules.

## Build from source

Requires Python 3 with its standard library. Roblox Studio is required for playtesting.

```sh
python3 tools/build.py
```

This regenerates `Little Pond.rbxlx`. Close its Studio tab before reopening the rebuilt file. The place is generated: preserve manual Studio edits in a separate copy or add them to the generator.

`default.project.json` is an optional Rojo source-sync configuration. Rojo is not required for the Python build.

## Test

In Studio, use **Play** for a single client and **Server & Clients** for multiplayer checks. Local test servers run the rule and gameplay integration checks automatically. Look for:

```text
LITTLE POND TESTS PASSED
LITTLE POND INTEGRATION PASSED
```

See [VALIDATION.md](VALIDATION.md) for recorded validation and its limits. A full 20-human network test, physical touch/controller checks, and published matchmaking remain release checks.

## Publish

Publish through Roblox Studio, then set **Maximum Players to 20** in the Creator Dashboard. Choose the intended audience and test multiplayer before opening access. The build script does not publish anything.

## Project layout

| Path | Purpose |
| --- | --- |
| `src/shared/Config.luau` | Tiers, speeds, thresholds, and rewards |
| `src/shared/BotBrain.luau` | Bot decisions |
| `src/shared/Swimming.luau` | Movement rules |
| `src/shared/FishFactory.luau`, `FishRenderer.luau` | Procedural fish and rendering |
| `src/server/Game.server.luau` | Authoritative simulation and validation |
| `src/client/` | Input, camera, HUD, and water effects |
| `tools/` | Place and landscape generators |
| `tests/Rules.luau` | Rule assertions |
