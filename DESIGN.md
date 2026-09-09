# Space-Only Space Age — Design Document

**Premise.** No planets. Every surface is a space platform. All matter comes from asteroids classified by their real spectral type. Progression is *which routes you can survive*, and each asteroid class unlocks a science tier.
**Fixed decisions**

- Six asteroid classes: S, M, C, V, E, D. Promethium unchanged.
- Crushing outputs are probabilistic (recycler-style). Copper trickles from S/M basic before the advanced tier.
- Stone is a byproduct of every rocky class; platform foundation consumes it.
- No crude oil. Carbon → coal (baking) → simple coal liquefaction (bootstrap) → coal liquefaction (upgrade). Methane from D-type is a second petroleum route.
- Tier-0 power is solar thermal: heating panel → heat boiler → steam engine. PV solar needs silicon (E-type).
- Electric furnace only. No burner devices, no stone/steel furnaces, no vehicles, no rails, no roboports.
- Silicon (E-type) in advanced circuits, processing units, PV panels.
- Steel = iron + carbon, unlocked at green. Nickel (M-type) is for alloys later, not steel.
- Volatiles science (D-type) replaces agricultural. No spoilage anywhere.
- Gleba, biters, Fulgora scrap, Vulcanus lava, Aquilo fluids: removed.
- Quantum research center (quantum processors) replaces biolab.
- Player starts on a platform with the platform tech unlocked and a starter kit in the hub.

---

## 1. The map

The engine needs `data.raw.planet.nauvis` to exist and `create_space_platform` needs a planet to orbit. Keep `nauvis` as a **stub**: void map-gen, hidden, locale name "Home Orbit". The player never lands (§10). Everything else is a `space-location`.

| Location | Type | Spawn mix (by weight) | Gate |
|---|---|---|---|
| Home Orbit | planet stub | S 75 · C 25 (small/medium only) | start |
| Inner Belt | space-location | S 50 · M 25 · E 25 | thruster |
| Psyche Field | space-location | M 70 · S 20 · E 10, big/huge | military 2 |
| Vesta Family | space-location | V 60 · S 30 · C 10 | military 2 |
| Outer Belt | space-location | C 50 · D 40 · S 10 | steam turbine / better thrusters |
| Trojan Cloud | space-location | D 80 · C 20, dense | rocket turret |
| Solar System Edge | vanilla | vanilla | vanilla |
| Shattered Planet | vanilla | promethium | vanilla |
Connections: Home–Inner, Inner–Psyche, Inner–Vesta, Home–Outer, Outer–Trojan, Vesta–Edge, Edge–Shattered. Each `space-connection` carries its own `asteroid_spawn_definitions` ramping from the origin mix to the destination mix (copy the shape of `space-age/prototypes/planet/asteroid-spawn-definitions.lua`).
Distance from the star, for `solar_power_in_space`: Home 100%, Inner 120%, Psyche 110%, Vesta 90%, Outer 50%, Trojan 30%, Edge 10%. Thermal panels are flat (void energy) — PV is what varies.

---

## 2. Asteroid classes

Each class is: one `asteroid-chunk` item + four `asteroid` entities (small / medium / big / huge). Reuse vanilla sprites with a per-class `tint` to start; replace art later.

| Class | Real analogue | Tint | Yields |
|---|---|---|---|
| **S** | ordinary chondrite (H/L/LL) | grey-brown | iron, stone, copper trickle, sulfur trickle, phosphate trace |
| **M** | iron / stony-iron (Psyche) | steel | iron (dense), nickel, tungsten, copper trickle |
| **C** | carbonaceous (CI/CM; Bennu, Ryugu) | near-black | ice, carbon, calcite, sulfur, hydrated silicate (→ lithium brine + ammonia) |
| **V** | HED / eucrite (Vesta) | pale grey | stone, phosphate rock (→ fluorine + uranium + holmium), calcite |
| **E** | enstatite chondrite / aubrite | white | sulfur, silicon, stone |
| **D** | outer-belt / Trojan, cometary | red-black | ice, carbon, volatile ice (→ ammonia + methane) |

---

## 3. New items and fluids

| Name | Type | Source | Consumed by |
|---|---|---|---|
| `s/m/c/v/e/d-asteroid-chunk` | item | collector | crusher |
| `nickel-ore` | item | M advanced | furnace → nickel plate |
| `nickel-plate` | item | furnace | LDS, steam turbine, heat exchanger |
| `silicon` | item | E advanced | advanced circuit, processing unit, solar panel |
| `phosphate-rock` | item | V advanced (S trace) | phosphate processing |
| `hydrated-silicate` | item | C advanced | lithium leaching |
| `volatile-ice` | item | D advanced | volatile separation |
| `methane` | fluid | volatile separation | methane cracking |
| `volatiles-science-pack` | tool | recipe | labs |
| `heating-panel`, `heat-boiler`, `melter`, `quantum-research-center` | item + entity | recipes | — |
Existing items re-sourced, no prototype change: iron-ore, copper-ore, stone, carbon, sulfur, ice, calcite, tungsten-ore, uranium-ore, holmium-ore, lithium-brine, fluorine, ammonia, coal.

---

## 4. Crushing recipes

Category `crushing`. Basic 2 s, advanced 5 s. Chunk return carries `ignored_by_productivity = 1, ignored_by_stats = 1`. Every recipe `allow_productivity = true`, `main_product` set.

### S-type

| Tier | Outputs |
|---|---|
| basic | 16 iron-ore · 8 stone · copper-ore 2–4 @0.5 · sulfur 1 @0.1 · chunk @0.3 |
| advanced | 12 iron-ore · 6 copper-ore · 3 stone · sulfur 2 @0.5 · phosphate-rock 1 @0.05 · chunk @0.1 |

### M-type

| Tier | Outputs |
|---|---|
| basic | 24 iron-ore · nickel-ore 2 @0.3 · copper-ore 1 @0.2 · chunk @0.3 |
| advanced | 16 iron-ore · 6 nickel-ore · tungsten-ore 2 @0.4 · copper-ore 2 @0.3 · chunk @0.1 |
| refining (8 s, metallurgic) | 8 iron-ore · 8 nickel-ore · 4 tungsten-ore · chunk @0.05 |

### C-type

| Tier | Outputs |
|---|---|
| basic | 5 ice · 8 carbon · 2 stone · chunk @0.3 |
| advanced | 3 ice · 5 carbon · 2 calcite · 2 sulfur · hydrated-silicate 1 @0.5 · chunk @0.1 |

### V-type

| Tier | Outputs |
|---|---|
| basic | 16 stone · 4 iron-ore · phosphate-rock 1 @0.3 · chunk @0.3 |
| advanced | 8 stone · 3 phosphate-rock · 2 calcite · 2 iron-ore · copper-ore 1 @0.2 · chunk @0.1 |

### E-type

| Tier | Outputs |
|---|---|
| basic | 12 stone · 6 sulfur · 2 iron-ore · chunk @0.3 |
| advanced | 6 silicon · 6 sulfur · 4 stone · 4 iron-ore · chunk @0.1 |

### D-type

| Tier | Outputs |
|---|---|
| basic | 10 ice · 4 carbon · chunk @0.3 |
| advanced | 6 ice · 3 carbon · 2 volatile-ice · chunk @0.1 |

### Reprocessing (ring S–M–E–V–C–D–S, 2 s)

Each chunk → same class @0.4, each ring neighbour @0.2. Lets a route with the wrong mix limp along; never efficient.

### Copper note

S basic averages ~1.5 copper per 16 iron. Red science and circuits are copper-starved until S advanced — that is the tier-0 pressure. If it plays too slow, raise `probability` on the S basic copper line; don't add copper elsewhere
---

## 5. New processing recipes

| Recipe | Machine | Inputs | Outputs | Tier |
|---|---|---|---|---|
| `steel-plate` (rewrite) | electric furnace, 16 s | 5 iron-plate + 1 carbon | 1 steel-plate | green |
| `nickel-plate` | electric furnace, 3.2 s | 1 nickel-ore | 1 nickel-plate | blue |
| `silicon` smelting | none — silicon comes out of E advanced directly | | | green |
| `carbon-baking` | electric furnace, 4 s | 4 carbon + 1 ice | 2 coal | green |
| `lithium-leaching` | chemical plant, 5 s | 5 hydrated-silicate + 50 water | 20 lithium-brine + 20 ammonia + 2 stone | blue |
| `volatile-separation` | chemical plant, 3 s | 5 volatile-ice | 30 ammonia + 30 methane + 10 water | volatiles |
| `methane-cracking` | chemical plant, 2 s | 20 methane + 10 steam | 20 petroleum-gas | volatiles |
| `phosphate-processing` | chemical plant, 8 s | 10 phosphate-rock + 30 sulfuric-acid | 10 fluorine + 3 uranium-ore + holmium-ore 1 @0.5 + 5 stone | yellow |
| `carbon-fiber` (rewrite) | assembler | 2 carbon + 10 petroleum-gas | 1 carbon-fiber | volatiles |
| `stack-inserter` (rewrite) | assembler | bulk-inserter + processing-unit + 2 carbon-fiber | 1 | volatiles |
| `small-electric-pole` (rewrite) | assembler | 1 iron-stick + 2 copper-cable | 2 | start |
| `solid-fuel-from-ammonia` (rewrite) | chemical plant | 15 ammonia + 10 petroleum-gas | 1 solid-fuel | volatiles |
| `volatiles-science-pack` | assembler, 10 s | 10 ammonia + 1 carbon-fiber + 20 methane | 1 | volatiles |
| `quantum-research-center` | assembler | 1 lab + 4 quantum-processor + 10 superconductor + 25 refined-concrete | 1 | cryogenic |
| `promethium-science-pack` (rewrite) | assembler | 25 promethium chunk + 1 quantum-processor + 5 volatiles-science-pack | 10 | promethium |
**Recipes gaining silicon:** advanced-circuit (+1 silicon), processing-unit (+2 silicon), solar-panel (5 silicon + 15 electronic-circuit + 5 copper, steel removed).
**Recipes gaining nickel:** low-density-structure (2 copper → 2 nickel-plate), steam-turbine (+10 nickel-plate), heat-exchanger (+5 nickel-plate).
**Tier-0 re-costs (everything must be hand-craftable from S/C basic output):**
| Recipe | New cost |
|---|---|
| space-platform-foundation | 2 iron-plate + 2 stone-brick |
| asteroid-collector | 20 iron-plate + 5 iron-gear + 5 electronic-circuit |
| crusher | 20 iron-plate + 10 iron-gear + 5 electronic-circuit |
| cargo-bay | 20 iron-plate + 10 stone-brick |
| electric-furnace | 20 iron-plate + 10 stone + 5 electronic-circuit |
| heating-panel | 10 iron-plate + 10 copper-plate + 4 pipe |
| heat-boiler | 10 iron-plate + 4 pipe |
| melter | 10 iron-plate + 4 pipe |
| heat-pipe | 5 iron-plate + 5 copper-plate |
| thruster | 20 steel-plate + 10 iron-gear + 5 electronic-circuit (green) |
| storage-tank | 20 iron-plate (steel removed) |
Vanilla-cost collector/crusher/thruster (LDS, engines, processing units) can return as `-2` upgrades under metallurgic if you want them.

---

## 6. New entities

| Entity | Prototype | Notes |
|---|---|---|
| `heating-panel` | `reactor`, `energy_source = {type="void"}`, `consumption = "1MW"`, `heat_buffer = {max_temperature=250, specific_heat="1MJ", max_transfer="1GW"}` | 2×2. Flat output regardless of location. |
| `heat-boiler` | `boiler`, `energy_source = {type="heat", max_temperature=250}`, `target_temperature = 165`, `energy_consumption = "1.8MW"` | Vanilla heat exchanger shape at 165 °C so the steam engine gets full value. |
| `melter` | `assembling-machine`, `energy_source = {type="void"}`, `fixed_recipe = "ice-melting"`, one fluid output | Change `ice-melting.categories` to `{"melting","chemistry"}`. Hand-feedable — this is the bootstrap. |
| `quantum-research-center` | `lab`, `researching_speed = 3`, `science_pack_drain_rate_percent = 50`, 4 module slots | Biolab replacement. |
| `s/m/c/v/e/d-asteroid` × small/medium/big/huge | `asteroid` | Copy the vanilla metallic definitions; set `tint`, `dying_trigger_effect` to drop the class chunk. |
The vanilla `boiler`, `steam-engine`, `electric-furnace`, `steam-turbine`, `heat-exchanger`, `nuclear-reactor` entities are unmodified except recipe cost.

---

## 7. Removed recipes

Planet chain with a live alternative: `basic-oil-processing`, `advanced-oil-processing`, `molten-iron-from-lava`, `molten-copper-from-lava`, `ammoniacal-solution-separation`, `scrap-recycling`, `biolubricant`, `bioplastic`, `biosulfur`, `burnt-spoilage`, `rocket-fuel-from-jelly`.
Gleba / biters / wood / fish, nothing downstream: `agricultural-tower`, `agricultural-science-pack`, `artificial-*-soil`, `overgrowth-*-soil`, `biochamber`, `bioflux`, `biolab`, `captive-biter-spawner`, `capture-robot-rocket`, `copper-bacteria`, `copper-bacteria-cultivation`, `iron-bacteria`, `iron-bacteria-cultivation`, `fish-breeding`, `jellynut-processing`, `yumako-processing`, `nutrients-from-*`, `pentapod-egg`, `tree-seed`, `spidertron`, `wooden-chest`, `shotgun`, `combat-shotgun`, `flamethrower-ammo`.
Dead with burners / vehicles / launch: `boiler`, `stone-furnace`, `steel-furnace`, `burner-mining-drill`, `burner-inserter`, `electric-mining-drill`, `big-mining-drill`, `pumpjack`, `offshore-pump`, `car`, `tank`, all rail/train recipes, `rocket-silo`, `cargo-landing-pad`, `rocket-part`, `satellite`, `space-platform-starter-pack` (item kept, recipe removed), `nuclear-fuel`, `rocket-fuel`, `landfill`, `cliff-explosives`, `land-mine`, `artillery-*`, `flamethrower-turret`, `lightning-rod`, `lightning-collector`, `roboport`, `construction-robot`, `logistic-robot`, all logistic chests, `heating-tower`.
Everything else stays. `iron-ore-melting`, `copper-ore-melting`, `tungsten-carbide`, `tungsten-plate`, `uranium-processing`, `holmium-solution`, `lithium`, `fluoroketone`, `fusion-power-cell`, `simple-coal-liquefaction`, `coal-liquefaction`, `foundation`, `ice-platform`, `ammonia-rocket-fuel` all work unchanged once their inputs exist
---

## 8. Removed entities

Every entity in §7's third paragraph, plus: all asteroid entities and chunk items for `metallic`, `carbonic`, `oxide` (replaced by six classes); `biter-spawner`, all biter/spitter units and worms; `pentapod-*`, `demolisher-*`; all plants, trees, stromatolites, volcanic rocks, icebergs, lithium formations; all `resource` prototypes (`iron-ore`, `copper-ore`, `coal`, `stone`, `uranium-ore`, `crude-oil`, `tungsten-ore`, `calcite`, `scrap`, `sulfuric-acid-geyser`, `lithium-brine`, `fluorine-vent`); `fish`; cliffs. Removing `resource` prototypes also kills the autoplace controls, which is what you want.
Lift `surface_conditions` on: `iron-chest`, `steel-chest` (keep them), plus the recipe-side conditions listed in §11
---

## 9. Technologies

### Starting unlocked (`enabled = true`, no tech)

S basic crushing, C basic crushing, crusher, asteroid collector, cargo bay, platform foundation, electric furnace, iron/copper plate, stone brick, gears, pipe, cable, electronic circuit, inserter, transport belt, small pole, heating panel, heat boiler, melter, steam engine, lab, automation science pack, assembler 1, gun turret + firearm magazine, iron chest.

### Removed

`planet-discovery-vulcanus/fulgora/gleba/aquilo`, `agricultural-science-pack`, `agriculture`, `artificial-soil`, `bacteria-cultivation`, `biochamber`, `bioflux`, `bioflux-processing`, `jellynut`, `yumako`, `overgrowth-soil`, `heating-tower`, `fish-breeding`, `tree-seeding`, `captivity`, `biter-egg-handling`, `captive-biter-spawner`, `biolab`, `spidertron`, `railway`, `automated-rail-transportation`, `rail-signals`, `elevated-rail`, `fluid-wagon`, `artillery`, `artillery-shell-range/speed`, `automobilism`, `tank`, `landfill`, `cliff-explosives`, `land-mine`, `flamethrower`, `advanced-oil-processing`, `advanced-material-processing` (steel furnace), `advanced-material-processing-2` (fold into start), `construction-robotics`, `logistic-robotics`, `logistic-system`, `worker-robots-*`, `rocket-silo`, `rocket-fuel`, `nuclear-fuel`, `big-mining-drill`, `lightning-collector`, `electric-mining-drill` / `mining-productivity-*`.

### Modified

| Tech | Change |
|---|---|
| `space-platform` | start; unlocks nothing (its unlocks are start recipes). Drop `rocket-silo` prereq. |
| `space-science-pack` | trigger → `craft-item thruster`; prereq → `space-flight`. |
| `steam-power` | unlocks heat pipe + more steam engines; keep trigger. |
| `automation-science-pack` | unchanged (trigger: craft lab). |
| `steel-processing` | recipe now iron + carbon; prereq `carbonaceous-processing`. |
| `oil-processing` | rename locale "Coal liquefaction"; trigger → `craft-item coal`; unlocks simple-coal-liquefaction + oil refinery + tank. Prereq `carbon-baking`, `sulfur-processing`, `calcite-processing`. |
| `coal-liquefaction` | purple, unchanged. |
| `solar-energy` | green; prereq `silicon-processing`. |
| `advanced-circuit` | blue; recipe gains silicon. |
| `processing-unit` | yellow; recipe gains silicon. |
| `low-density-structure` | recipe gains nickel; prereq `nickel-processing`. |
| `nuclear-power` | unlocks reactor + heat exchanger (500 °C) + steam turbine; prereq `nickel-processing`. |
| `calcite-processing` | trigger → `craft-item calcite`. |
| `tungsten-carbide` | trigger → `craft-item tungsten-ore`. |
| `lithium-processing` | trigger → `craft-fluid lithium-brine`. |
| `uranium-processing` | trigger → `craft-item uranium-ore`. |
| `electric-energy-distribution-1` | medium pole needs steel — fine at green. |
| `carbon-fiber`, `stack-inserter`, `promethium-science-pack` | rewritten recipes; move to volatiles / promethium. |
| Foundry / EM plant / cryogenic plant / fusion / metallurgic / EM / cryogenic science | lift recipe `surface_conditions`, otherwise unchanged. |

### Added

| Tech | Pack | Prereqs | Unlocks |
|---|---|---|---|
| `s-type-advanced-crushing` | red | — | S advanced |
| `carbonaceous-processing` | red | — | C advanced, hydrated silicate |
| `space-flight` | red+green | steel | thruster, thruster fuel, thruster oxidizer |
| `carbon-baking` | green | carbonaceous-processing | carbon-baking |
| `inner-belt-navigation` | green | space-flight | Inner Belt route; E basic, M basic |
| `silicon-processing` | green | inner-belt | E advanced |
| `asteroid-reprocessing` | white | space-flight | all reprocessing recipes |
| `metallic-refining` | white | inner-belt | M advanced; Psyche route |
| `basaltic-processing` | white | military-2 | V basic + advanced; Vesta route |
| `nickel-processing` | blue | metallic-refining | nickel-plate, LDS rewrite, turbine/heat-exchanger rewrite |
| `lithium-leaching` | blue | carbonaceous-processing, sulfur-processing | lithium-leaching |
| `outer-belt-navigation` | blue | nuclear-power or solar-2 | Outer Belt route; D basic |
| `volatile-processing` | blue+white | outer-belt | D advanced, volatile-separation, methane-cracking |
| `volatiles-science-pack` | blue+white | volatile-processing | pack recipe |
| `trojan-navigation` | volatiles | rocket-turret | Trojan route |
| `phosphate-processing` | yellow | basaltic-processing, sulfur-processing | phosphate-processing (fluorine, uranium ore, holmium ore) |
| `metallic-deep-refining` | metallurgic | — | M refining tier |
| `quantum-research-center` | cryogenic | quantum-processor | the lab |

### Science pack ordering (what gates what)

red → green → **white** (thruster) → blue → purple / yellow → metallurgic (M) · electromagnetic (V) · volatiles (D) → cryogenic (C + V) → promethium
---

## 10. Starting on a platform

`control.lua`:

```lua
script.on_event(defines.events.on_player_created, function(e)
  local player = game.get_player(e.player_index)
  local force = player.force
  local platform = force.create_space_platform{
    name = "Home",
    planet = "nauvis",                       -- the stub; platforms must orbit a planet
    starter_pack = "space-platform-starter-pack",
  }
  platform.apply_starter_pack()
  local surface = platform.surface
  local pos = surface.find_non_colliding_position("character", {0, 0}, 20, 1) or {0, 0}
  player.teleport(pos, surface)
end)
-- nobody goes down
script.on_event(defines.events.on_player_changed_surface, function(e)
  local player = game.get_player(e.player_index)
  if player.surface.name == "nauvis" then
    local platform = player.force.platforms[1]
    if platform and platform.surface then player.teleport({0,0}, platform.surface) end
  end
end)
```

Keep the `space-platform-starter-pack` **item** prototype (remove its recipe). Its `initial_items`, `tiles`, and `create_electric_network` fields define the kit (§13). `apply_starter_pack()` places the hub and tiles and fills the hub with `initial_items`.
Check in-game: whether `create_space_platform` accepts a `space-location` name for `planet`. If it does, Home can be a pure space-location and the nauvis stub is only there to satisfy the engine
---

## 11. Removing surface conditions

`data-updates.lua`:

```lua
-- recipes: strip everything except the gravity=0 (space-only) ones
for _, r in pairs(data.raw.recipe) do
  local sc = r.surface_conditions
  if sc and not (sc[1] and sc[1].property == "gravity" and sc[1].max == 0) then
    r.surface_conditions = nil
  end
end
-- entities: strip everything except the space-only ones
local keep = {
  crusher = true, ["space-platform-hub"] = true, ["asteroid-collector"] = true, thruster = true,
}
for _, cat in pairs(data.raw) do
  for name, p in pairs(cat) do
    if type(p) == "table" and p.surface_conditions and not keep[name] then
      p.surface_conditions = nil
    end
  end
end
-- items pointing at dead planets
for _, cat in pairs(data.raw) do
  for _, p in pairs(cat) do
    if type(p) == "table" and p.default_import_location then p.default_import_location = nil end
  end
end
```

Then delete the entities you don't want back (§8) rather than leaving them ungated
---

## 12. Removing the planets

Order matters — dangling references crash at load, not at runtime.

```lua
local dead = { "vulcanus", "fulgora", "gleba", "aquilo" }
local deadset = {}
for _, n in ipairs(dead) do deadset[n] = true end
-- 1. technologies that discover them, and prerequisites pointing at those
for _, n in ipairs(dead) do data.raw.technology["planet-discovery-" .. n] = nil end
for _, t in pairs(data.raw.technology) do
  if t.prerequisites then
    for i = #t.prerequisites, 1, -1 do
      if t.prerequisites[i]:match("^planet%-discovery%-") then table.remove(t.prerequisites, i) end
    end
  end
end
-- 2. connections touching them
for name, c in pairs(data.raw["space-connection"]) do
  if deadset[c.from] or deadset[c.to] then data.raw["space-connection"][name] = nil end
end
-- 3. the planets
for _, n in ipairs(dead) do data.raw.planet[n] = nil end
-- 4. things that reference them by name: tips, factoriopedia sims, autoplace controls
for _, cat in ipairs({ "tips-and-tricks-item", "factoriopedia-simulations" }) do
  -- remove any whose simulation/planet text mentions a dead planet; simplest is a serpent.block scan
end
for name, ac in pairs(data.raw["autoplace-control"]) do
  if ac.category == "resource" or ac.category == "enemy" then data.raw["autoplace-control"][name] = nil end
end
-- 5. nauvis becomes a void orbit anchor
local nauvis = data.raw.planet.nauvis
nauvis.map_gen_settings = {
  width = 64, height = 64,
  autoplace_controls = {},
  autoplace_settings = {
    entity = { settings = {} }, decorative = { settings = {} },
    tile = { settings = { ["out-of-map"] = {} } },
  },
  property_expression_names = {},
  starting_area = 0,
  peaceful_mode = true,
}
nauvis.hidden = true
nauvis.map_seed_settings = nil
nauvis.player_effects = nil
nauvis.pollutant_type = nil
nauvis.persistent_ambient_sounds = nil
```

Expect two or three load errors on the first run naming a `procession`, `surface-property`, or a locale-only reference. Delete each named prototype as it appears; there is no cleverer way. `wube/factorio-data` is the reference for what each planet file defines.
Do all of this in `data-updates.lua`. `data-final-fixes.lua` only if another mod re-adds something
---

## 13. Starter kit — `space-platform-starter-pack.initial_items`

Enough to run one collector-crusher loop, one furnace, one lab, one thermal loop, and grow.

| Item | Qty | Why |
|---|---|---|
| space-platform-foundation | 200 | ~14×14 footprint |
| asteroid-collector | 4 | |
| crusher | 4 | |
| electric-furnace | 2 | no starter furnace, so these are it |
| assembling-machine-1 | 2 | |
| lab | 1 | |
| heating-panel | 6 | |
| heat-boiler | 3 | |
| melter | 2 | hand-fed at first |
| steam-engine | 3 | |
| heat-pipe | 10 | |
| pipe | 30 · pipe-to-ground 6 | |
| storage-tank | 1 | |
| inserter | 20 | |
| transport-belt | 100 | |
| small-electric-pole | 20 | |
| iron-chest | 4 | |
| gun-turret | 4 · firearm-magazine 200 | |
| ice | 100 | bootstrap water — hand-feed the melters |
| iron-plate | 200 · copper-plate | 100 | first circuits, first science |
| stone | 100 | first foundation bricks |
| iron-gear-wheel | 50 · electronic-circuit | 20 | |
Set `create_electric_network = true` and `tiles = make_tile_area({{-10, -10}, {9, 9}}, "space-platform-foundation")` for a pre-laid 20×20 pad (vanilla is 10×10 with 10 loose tiles). Deliberately fat: there is no Nauvis to fall back on. `initial_items` entries need `quality_min/quality_max = "normal"` on the foundation line — quality tiles can't be placed.

---

## 14. Steel

Don't do a bad-steel recipe. Vanilla steel *is* carbon steel — "5 iron plate → 1 steel" already is Fe + C with the carbon hand-waved. Make it literal: **5 iron plate + 1 carbon → 1 steel**, electric furnace, green tier, prerequisite `carbonaceous-processing`. C-type is at Home at 25%, so carbon flows from minute one; steel arrives exactly when green science does, same as vanilla.
Nickel is not a steel ingredient. Alloy steels are, but there's no gameplay in a second steel item. Put nickel where it's actually load-bearing in real hardware: **turbine blades and aerospace structure** — steam turbine, heat exchanger, low-density structure. That makes M-type the gate for high-temperature power and for the rocket-era intermediates, which is the right place for it
---

## 15. Open questions to test in-game

1. `create_space_platform{planet=…}` with a space-location name.
2. Personal roboport on a platform surface.
3. Whether removing every `resource` prototype trips something in map-gen for the nauvis stub; if so, keep one dummy resource with `autoplace = nil`.
4. Whether `hidden = true` on a planet hides it from the platform route UI.
5. Whether four-way probability outputs on crushers make the "auto recipe select" logic in the hub misbehave — the crusher's `fixed_recipe` is nil; watch for the 2.0.11 behaviour where the recipe gets set from hub contents.
