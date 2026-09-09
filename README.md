# Space-Only Space Age

A Factorio 2.1 Space Age overhaul. There are no planets. Every surface is a space platform, and all matter comes from asteroids classified by their real spectral type (S, M, C, V, E, D). Progression is which routes you can survive.

The design is in [DESIGN.md](DESIGN.md). The implementation plan and the register of places where the 2.1.17 data forced a change to the design are in [PLAN.md](PLAN.md).

## Layout

- `info.json`, `data.lua`, `data-updates.lua`, `control.lua`: the mod.
- `prototypes/`: one file per area.
- `locale/en/`: names and descriptions.
- `tools/`: a Lua 5.2 harness that runs the Factorio data stage against a checkout of `wube/factorio-data`, so the mod can be load-checked without the game. See `tools/README.md`.

## Load check

```
lua5.2 tools/load.lua --data /path/to/factorio-data --mod . --check
```
