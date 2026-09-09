# PLAN.md — space-only-space-age 0.1.0, built against factorio-data 2.1.17

How to read this file:

- `D-nn` is a deviation-register entry (section 2). `Q-nn` is an open question (section 6).
- A path with a line number is in `/home/user/factorio-data` unless it starts with `DESIGN.md`.
- The rule: follow DESIGN.md. Deviate only where the 2.1.17 data makes the design impossible or
  wrong, take the closest equivalent, and say why. Each deviation is marked **mechanical** (a
  rename or field change that leaves the design intact) or **design** (the user should confirm).
- "Removed" always means `data.raw[type][name] = nil` in the mod's `data.lua` (D-18), never in
  `data-updates.lua`.

---

## 1. File layout

```
space-only-space-age/
  info.json
  data.lua
  data-updates.lua
  control.lua
  locale/en/items.cfg
  locale/en/entities.cfg
  locale/en/recipes.cfg
  locale/en/technologies.cfg
  locale/en/locations.cfg
  prototypes/
    categories.lua
    fluids.lua
    items.lua
    asteroid-graphics.lua
    asteroid-chunks.lua
    asteroids.lua
    asteroid-spawn-lib.lua
    asteroid-spawn-routes.lua
    crushing-recipes.lua
    reprocessing-recipes.lua
    processing-recipes.lua
    recipe-rewrites.lua
    entities/heating-panel.lua
    entities/heat-boiler.lua
    entities/melter.lua
    entities/quantum-research-center.lua
    space-locations.lua
    space-connections.lua
    technology-additions.lua
    technology-modifications.lua
    removals-recipes.lua
    removals-entities.lua
    removals-technologies.lua
    removals-planets.lua
    surface-conditions.lua
    starter-pack.lua
    nauvis-stub.lua
  tools/   (harness, already present)
```

No `data-final-fixes.lua`: nothing in this mod has to run after another mod's data-updates, and
`space-age/data-final-fixes.lua` is empty (0 bytes). No `settings.lua`. No `migrations/` at 0.1.0.

### info.json

```json
{
  "name": "space-only-space-age",
  "version": "0.1.0",
  "title": "Space-Only Space Age",
  "author": "bob",
  "factorio_version": "2.1",
  "dependencies": [
    "base >= 2.1.0",
    "space-age >= 2.1.0",
    "elevated-rails >= 2.1.0",
    "recycler >= 2.1.0",
    "? quality >= 2.1.0"
  ]
}
```

- `space-age` is required (every removal edits its prototypes). It hard-depends on `recycler` and
  `elevated-rails` and only recommends `quality` (`space-age/info.json:8`, `changelog.txt:466,529`).
- `elevated-rails` is a **dependency**, not an incompatibility (D-19): space-age requires it, so it
  cannot be absent; listing it makes the load order explicit, and `removals-entities.lua` deletes
  everything it adds (rail-ramp, rail-support, the four elevated rail types, tech `elevated-rail`,
  space-age's `rail-support-foundations`).
- `recycler` is required and its data-updates run after this mod's `data.lua` (D-18).
- `quality` is optional (`?`); nothing in the mod names a quality-mod prototype. `quality_min =
  "normal"` on the starter pack uses base's `normal` quality (`base/prototypes/categories/quality.lua:3-15`).

### data.lua (wiring only; this order)

```lua
require("prototypes.categories")
require("prototypes.fluids")
require("prototypes.items")
require("prototypes.asteroid-chunks")        -- requires prototypes.asteroid-graphics
require("prototypes.asteroids")              -- same
require("prototypes.entities.heating-panel")
require("prototypes.entities.heat-boiler")
require("prototypes.entities.melter")
require("prototypes.entities.quantum-research-center")
require("prototypes.crushing-recipes")
require("prototypes.reprocessing-recipes")
require("prototypes.processing-recipes")
require("prototypes.recipe-rewrites")
require("prototypes.space-locations")        -- requires asteroid-spawn-lib + asteroid-spawn-routes
require("prototypes.space-connections")
require("prototypes.technology-additions")
require("prototypes.technology-modifications")
require("prototypes.removals-recipes")
require("prototypes.removals-entities")
require("prototypes.removals-technologies")  -- ends with the generic scrub pass
require("prototypes.removals-planets")
require("prototypes.surface-conditions")
require("prototypes.starter-pack")
require("prototypes.nauvis-stub")
```

Why data.lua and not data-updates.lua (D-18): `recycler/data-updates.lua:1-25` generates
`<item>-recycling` for every recipe and item that exists when it runs, and appends a hidden
`unlock-recipe` for each to `technology.recycling.effects` (`recycler/recycling.lua:191-197`). Our
`data.lua` runs after `space-age/data.lua` (which already ran `base-data-updates.lua`, `space-age/data.lua:65`)
and before every mod's `data-updates.lua`, so a removal made here is never seen by the recycler, and a
rewritten recipe gets a correct recycling recipe for free. The only later vanilla code that touches a
name we care about is `base/data-updates.lua:105-107`, which sets `fluoroketone-cold-barrel.default_import_location = "aquilo"`
on the barrel it generates; `data-updates.lua` clears it.

### data-updates.lua

```lua
-- 1. dead-planet import locations, including the barrel base/data-updates.lua just generated
for _, cat in pairs(data.raw) do
  for _, p in pairs(cat) do
    if type(p) == "table" and p.default_import_location then p.default_import_location = nil end
  end
end
-- 2. safety net: a recycling recipe whose ingredient or result no longer exists
--    (should be empty after D-18; the harness --check proves it)
```

### control.lua

Satisfies DESIGN.md §10, with D-22/D-23/D-24/D-25/D-26. Shape (from the control reader's skeleton,
`core/lualib/event_handler.lua:89-115` lifecycle):

- `on_init`: `storage.home = {}`; if `remote.interfaces["freeplay"]` then `set_skip_intro(true)`,
  `set_disable_crashsite(true)`, `set_created_items({pistol=1, ["firearm-magazine"]=10})`,
  `set_respawn_items(same)` (function names beyond `get_skip_intro` are from memory, Q-04); for the
  `player` force call `ensure_home(force)`; then `send_home(player)` for every player.
- `ensure_home(force)`: `force.unlock_space_platforms()`; `force.unlock_travel_to_space_platforms = true`
  (`changelog.txt:744`); `force.technologies["space-platform"].researched = true`;
  `force.create_space_platform{name="Home", planet="nauvis", starter_pack="space-platform-starter-pack"}`
  (the only call shape in vanilla, `space-age/prototypes/tips-and-tricks-simulations.lua:431`);
  `platform.apply_starter_pack()`; `storage.home[force.name] = platform.index`.
- `send_home(player)`: look the platform up by stored index (`force.platforms[index]`, keyed by
  index since 2.0.48, `changelog.txt:1857`), fall back to `force.get_space_platforms()` by name
  (2.1.13, `changelog.txt:164`); `surface.find_non_colliding_position("character", {0,0}, 20, 1)`;
  teleport `player.character` when it exists, else `player`.
- Events: `on_player_created`, `on_player_respawned`, `on_force_created` → `ensure_home`,
  `on_player_changed_surface` → if `player.physical_surface.name == "nauvis"` then `send_home`
  (`physical_surface` since 2.0.7, `changelog.txt:4463`; `teleport` no longer leaves remote view,
  `changelog.txt:772`).
- Victory: untouched (D-26). `core/lualib/space-finish-script.lua:4` keeps `solar-system-edge` as
  the win, `can_continue = true`.
- `remote.add_interface("space-only-space-age", { get_home_platform_index = ... })`.

### prototypes/ files

Every file stays under 400 lines; the two generator files and the technology files are the ones
that would grow, and they are split below.

| File | Defines / edits (exact names) | DESIGN.md |
|---|---|---|
| `categories.lua` | `recipe-category` **`melting`** (`base/prototypes/categories/recipe-category.lua:1-38` shape; no vanilla `melting` exists, D-07) | §6 melter |
| `fluids.lua` | `fluid` **`methane`**: `default_temperature=15`, `gas_temperature=15`, `base_color/flow_color` grey-orange, `icons={{icon="__base__/graphics/icons/fluid/petroleum-gas.png", tint=...}}`, `subgroup="fluid"`, `order="a[fluid]-d[methane]"`. `auto_barrel` left default so `base/data-updates.lua` makes `methane-barrel` / `empty-methane-barrel` | §3 |
| `items.lua` | `item`: **`s-asteroid-chunk` `m-asteroid-chunk` `c-asteroid-chunk` `v-asteroid-chunk` `e-asteroid-chunk` `d-asteroid-chunk`** (copy `space-age/prototypes/item.lua:342-353`: `subgroup="space-material"`, `stack_size=1`, `weight=100*kg`, `space_age_item_sounds.rock_*`, per-class `random_tint_color`, `icons` = vanilla chunk icon + tint), **`nickel-ore`** (`raw-resource`, stack 50, weight 2*kg), **`nickel-plate`** (`raw-material`, stack 100, weight 1*kg), **`silicon`** (`raw-material`, stack 100), **`phosphate-rock`** (`raw-resource`, stack 50, weight 2*kg), **`hydrated-silicate`** (`raw-resource`, stack 50), **`volatile-ice`** (`raw-resource`, stack 50, `auto_recycle=false` not needed), **`volatiles-science-pack`** (`type="item"`, D-06; copy `base/prototypes/item.lua:683-697`: `subgroup="science-pack"`, `color_hint={text="V"}`, `order="i[volatiles-science-pack]"`, `stack_size=200`, `weight=1*kg`, `item_sounds.science_*`, `random_tint_color=item_tints.bluish_science`), **`heating-panel`** (`subgroup="energy"`, `order="b[steam-power]-a[heating-panel]"`, `place_result`), **`heat-boiler`** (`energy`, `b[steam-power]-b[heat-boiler]`, icon `__base__/graphics/icons/heat-boiler.png`), **`melter`** (`production-machine`, `e[melter]`), **`quantum-research-center`** (`production-machine`, `z[z-quantum-research-center]`, stack 5). Then `table.insert(data.raw.lab.lab.inputs, "volatiles-science-pack")` and remove `"agricultural-science-pack"` from that list (`base/prototypes/entity/entities.lua:3914-3923`; space-age appends at `base-data-updates.lua:275-279`). Requires: `__base__.prototypes.item_sounds`, `__space-age__.prototypes.item_sounds`, `__base__.prototypes.item-tints` (`space-age/prototypes/item.lua:1-5`) | §3, §6 |
| `asteroid-graphics.lua` | Returns a table, defines no prototype. Copies the file-local helpers `asteroid_variation` and `asteroid_graphics_set` (`space-age/prototypes/entity/asteroid.lua:193-228`), the size tables `collision_radiuses {0.4,0.5,1,2,4.5}`, `graphics_scale {0.5,0.5,0.5,0.6,0.75}`, `sizes_resolution`, `shared_health {0,100,400,2000,5000}`, `shared_damage_per_hp {0,5,8,12,15}`, `shared_resistances` (`:46-66,165-191`), the three vanilla `shading_data` blocks (`:75-138`) and the per-type variation suffix lists (`:303-480`) as data tables, plus the class table below | §2, §6 |
| `asteroid-chunks.lua` | `asteroid-chunk` **`s-asteroid-chunk` … `d-asteroid-chunk`** (size index 1 of the vanilla loop, `asteroid.lua:482-510`: `minable={mining_time=0.2, result=<name>, mining_particle="<sprite-type>-asteroid-chunk-particle-medium"}`, `dying_trigger_effect` = `create-entity "<sprite-type>-asteroid-explosion-1"`, `subgroup="space-material"`, `localised_description={"entity-description.<class>-asteroid"}`) and the `graphics_set.lights[2]` override per class (`:514-516`) | §2 |
| `asteroids.lua` | `asteroid` **`small-s-asteroid` `medium-s-asteroid` `big-s-asteroid` `huge-s-asteroid`** and the same four for `m c v e d` (24 entities), sizes 2..5 of the vanilla loop: small drops two chunks by `create-asteroid-chunk`, medium/big/huge spawn three of the next size down, every size fires `create-explosion "<sprite-type>-asteroid-explosion-<n>"` (`asteroid.lua:238-279`); `damage_per_hp`, `max_health`, resistances built from `data.raw["damage-type"]` (`:282-292`); `factoriopedia_simulation = nil` (D-08). Naming follows vanilla so the spawn helper's name builder works unchanged | §2, §6 |
| `asteroid-spawn-lib.lua` | Returns the helper table. Verbatim copy of `space-age/prototypes/planet/asteroid-spawn-definitions.lua:239-442` with `asteroid_types = {"s","m","c","v","e","d"}` (+`"promethium"` when `has_promethium_asteroids`), the id switch replaced by position-in-list, `normalize_ratio` unchanged, `interpolate_point_ratio` default `ratios` widened to seven `1`s (D-09) | §1 |
| `asteroid-spawn-routes.lua` | Returns the constants and route tables: `standard_speed = 1*meter/second`, the five `*_angle`, the density constants and ratio vectors of section 1.1 below, and routes `home_inner`, `inner_psyche`, `inner_vesta`, `home_outer`, `outer_trojan`, `vesta_edge`, `edge_shattered` (shape of `asteroid-spawn-definitions.lua:35-53`; origin 0.1, destination 0.9, medium peak ×3 at 0.5) | §1 |
| `crushing-recipes.lua` | `recipe` **`s-asteroid-crushing` `advanced-s-asteroid-crushing`** and the same pair for `m c v e d` (12) plus **`m-asteroid-refining`** (8 s), built by one helper from the §4 tables; `categories={"crushing"}`, `subgroup="space-crushing"`, `order="<a..f>[<class>]-<a|b|c>"`, `icons` = vanilla crushing icon + class tint, `auto_recycle=false`, `enabled=false` except `s-asteroid-crushing` and `c-asteroid-crushing`, chunk ingredient and chunk result carry `ignored_by_stats=1`, `independent_probability` on every `@p` line, `amount_min/amount_max` on ranges, `allow_productivity=true`, `allow_decomposition=false`, no `main_product` (D-01..D-05) | §4 |
| `reprocessing-recipes.lua` | `recipe` **`s-asteroid-reprocessing` `m-asteroid-reprocessing` `e-asteroid-reprocessing` `v-asteroid-reprocessing` `c-asteroid-reprocessing` `d-asteroid-reprocessing`** on the ring S–M–E–V–C–D–S: self chunk `shared_probability={min=0,max=0.4}, ignored_by_stats=1`, ring neighbours `{0.4,0.6}` and `{0.6,0.8}`, `energy_required=2`, `allow_productivity=false`, `allow_quality=false`, `allow_decomposition=false`, `auto_recycle=false` (`space-age/prototypes/recipe.lua:1028-1048`, D-03) | §4 |
| `processing-recipes.lua` | `recipe` **`nickel-plate`** (`{"smelting"}`, 3.2 s, 1 nickel-ore), **`carbon-baking`** (`{"smelting"}`, 4 s, 4 carbon + 1 ice → 2 coal, D-47), **`lithium-leaching`** (`{"chemistry"}`, 5 s, 5 hydrated-silicate + 50 water → 20 lithium-brine + 20 ammonia + 2 stone; own `icons`, `subgroup="fluid-recipes"`), **`volatile-separation`** (`{"chemistry"}`, 3 s, 5 volatile-ice → 30 ammonia + 30 methane + 10 water), **`methane-cracking`** (`{"chemistry"}`, 2 s, 20 methane + 10 steam → 20 petroleum-gas), **`phosphate-processing`** (`{"chemistry"}`, 8 s, 10 phosphate-rock + 30 sulfuric-acid → 10 fluorine + 3 uranium-ore + holmium-ore `independent_probability=0.5` + 5 stone), **`volatiles-science-pack`** (`{"crafting-with-fluid"}`, 10 s, 10 ammonia + 1 carbon-fiber + 20 methane → 1; `auto_recycle=false`), **`quantum-research-center`** (`{"crafting"}`, 1 lab + 4 quantum-processor + 10 superconductor + 25 refined-concrete), **`heating-panel`** (10 iron-plate + 10 copper-plate + 4 pipe, `enabled=true`), **`heat-boiler`** (10 iron-plate + 4 pipe, `enabled=true`), **`melter`** (10 iron-plate + 4 pipe, `enabled=true`). Every recipe uses `categories=`; multi-product ones set `icons`, `subgroup`, `order` and get a `recipe-name` locale line | §5 |
| `recipe-rewrites.lua` | In-place edits of vanilla recipes: **`steel-plate`** 5 iron-plate + 1 carbon (`{"smelting"}`, 16 s); **`carbon-fiber`** 2 carbon + 10 petroleum-gas (`{"crafting-with-fluid"}`, `subgroup="intermediate-product"`); **`stack-inserter`** bulk-inserter + processing-unit + 2 carbon-fiber; **`small-electric-pole`** 1 iron-stick + 2 copper-cable → 2 (`categories={"crafting"}`; drop space-age's `electromagnetics`); **`solid-fuel-from-ammonia`** 15 ammonia + 10 petroleum-gas (`{"chemistry"}`); **`promethium-science-pack`** 25 promethium-asteroid-chunk + 1 quantum-processor + 5 volatiles-science-pack → 10 (`{"crafting"}`; keep `surface_conditions` gravity 0); **`advanced-circuit`** +1 silicon; **`processing-unit`** +2 silicon; **`solar-panel`** 5 silicon + 15 electronic-circuit + 5 copper-plate; **`low-density-structure`** 2 steel-plate + 2 nickel-plate + 5 plastic-bar (the 20 copper-plate line becomes 2 nickel-plate, Q-14); **`steam-turbine`** +10 nickel-plate; **`heat-exchanger`** +5 nickel-plate; tier-0 re-costs **`space-platform-foundation`** 2 iron-plate + 2 stone-brick, **`asteroid-collector`** 20 iron-plate + 5 iron-gear-wheel + 5 electronic-circuit, **`crusher`** 20 iron-plate + 10 iron-gear-wheel + 5 electronic-circuit, **`cargo-bay`** 20 iron-plate + 10 stone-brick, **`electric-furnace`** 20 iron-plate + 10 stone + 5 electronic-circuit, **`heat-pipe`** 5 iron-plate + 5 copper-plate, **`thruster`** 20 steel-plate + 10 iron-gear-wheel + 5 electronic-circuit, **`storage-tank`** 20 iron-plate; **`production-science-pack`** 1 electric-furnace + 1 productivity-module + 15 steel-plate + 15 iron-stick → 3 (D-35); **`productivity-module-3`** and **`efficiency-module-3`** back to the base three-ingredient forms (D-54); **`ice-melting`** `categories={"melting","chemistry"}`, `enabled=true`; `data.raw.furnace["electric-furnace"].source_inventory_size = 2` (D-47); the start-enabled list of §9 set `enabled=true`: `s-asteroid-crushing c-asteroid-crushing crusher asteroid-collector cargo-bay space-platform-foundation electric-furnace iron-plate copper-plate stone-brick iron-gear-wheel pipe pipe-to-ground copper-cable electronic-circuit inserter transport-belt small-electric-pole heating-panel heat-boiler melter ice-melting steam-engine lab automation-science-pack assembling-machine-1 gun-turret firearm-magazine iron-chest`; `data.raw["space-platform-starter-pack"]["space-platform-starter-pack"].auto_recycle = false` | §5, §9 |
| `entities/heating-panel.lua` | `reactor` **`heating-panel`**: 2×2 (`collision_box {{-0.9,-0.9},{0.9,0.9}}`, `selection_box {{-1,-1},{1,1}}`), `consumption="1MW"`, `energy_source={type="void"}`, `neighbour_bonus=0`, no `neighbour_connectable` (`space-age/prototypes/entity/entities.lua:2213-2215`), `heat_buffer={max_temperature=250, specific_heat="1MJ", max_transfer="1GW", minimum_glow_temperature=100, connections=` the eight edge-tile pairs at ±0.5 `, heat_picture=apply_heat_pipe_glow(util.sprite_load("__space-age__/graphics/entity/heating-tower/heating-tower-glow",{scale=0.333, blend_mode="additive"}))}`, `connection_patches_*` / `heat_connection_patches_*` reusing the heating-tower sheets at scale 0.333, `picture` = `heating-tower-main` + shadow at scale 0.333 (placeholder art), `temperature_to_suppress_energy_icons=800`, `default_temperature_signal signal-T`, `circuit_connector=circuit_connector_definitions["heating-tower"]`, `minable={mining_time=0.2,result="heating-panel"}`, `corpse="solar-panel-remnants"`, `dying_explosion="solar-panel-explosion"`, `max_health=200`, `flags={"placeable-neutral","player-creation"}`, `icons`=solar-panel tinted (D-48) | §6 |
| `entities/heat-boiler.lua` | `boiler` **`heat-boiler`** = `table.deepcopy(data.raw.boiler["heat-exchanger"])` (`base/prototypes/entity/entities.lua:9214-9534`) with `name`, `icon="__base__/graphics/icons/heat-boiler.png"` + tint, `minable.result`, `fast_replaceable_group="heat-boiler"`, `target_temperature=165`, `energy_consumption="1.8MW"`, `energy_source.max_temperature=250`, `energy_source.min_working_temperature=165`, `energy_source.minimum_glow_temperature=100`; keep `connections`, `pipe_covers`, `heat_pipe_covers`, `heat_picture`, `fluid_box`, `output_fluid_box`, `pictures`, `corpse="heat-exchanger-remnants"`, `dying_explosion="heat-exchanger-explosion"` (D-49) | §6 |
| `entities/melter.lua` | `assembling-machine` **`melter`** = deepcopy of `data.raw["assembling-machine"]["chemical-plant"]` (`base/prototypes/entity/entities.lua:8437-8811`) with `name`, `icons` (chemical-plant tinted ice-blue), `minable.result`, `crafting_categories={"melting"}`, `fixed_recipe="ice-melting"`, `show_recipe_icon=false`, `energy_source={type="void"}`, `energy_usage="50kW"`, `module_slots=0`, `allowed_effects={}`, `fluid_boxes` = one output `{production_type="output", pipe_covers=pipecoverspictures(), volume=100, pipe_connections={{flow_direction="output", direction=defines.direction.south, position={0,1}}}}`, `fluid_boxes_off_when_no_fluid_recipe=false`, `surface_conditions=nil`, `heating_energy=nil`, `corpse="chemical-plant-remnants"`, `dying_explosion="chemical-plant-explosion"`, `fast_replaceable_group="melter"` (D-50) | §6 |
| `entities/quantum-research-center.lua` | `lab` **`quantum-research-center`** = deepcopy of `data.raw.lab.biolab` (`space-age/prototypes/entity/entities.lua:1689-1813`) with `name`, `icons` (biolab tinted), `minable.result`, `researching_speed=3`, `science_pack_drain_rate_percent=50`, `module_slots=4`, `inputs = table.deepcopy(data.raw.lab.lab.inputs)` (after items.lua edited it), `surface_conditions=nil`, `energy_source.emissions_per_minute=nil`, `corpse="biolab-remnants"`, `dying_explosion="biolab-explosion"`, `order="z-z[z-quantum-research-center]"` (D-51). biolab itself is removed later, its corpse/explosion stay | §6 |
| `space-locations.lua` | `space-location` **`inner-belt`** (distance 20, orientation 0.30), **`psyche-field`** (26, 0.36), **`vesta-family`** (24, 0.22), **`outer-belt`** (34, 0.30), **`trojan-cloud`** (42, 0.20); each: `subgroup="planets"`, `gravity_pull=-10`, `magnitude=1.0`, `label_orientation`, `starmap_icon_size=512`, `asteroid_spawn_influence=1`, `asteroid_spawn_definitions=lib.spawn_definitions(routes.<route>, 0.9)`, `solar_power_in_space` per D-11, `icon`/`starmap_icon` placeholders (inner-belt ← `__space-age__/graphics/icons/vulcanus.png`+`starmap-planet-vulcanus.png`, psyche-field ← fulgora, vesta-family ← gleba, outer-belt ← aquilo, trojan-cloud ← `promethium-asteroid-chunk.png` with `starmap_icon_size=64`). Edits: `data.raw.planet.nauvis.asteroid_spawn_definitions = lib.spawn_definitions(routes.home_inner, 0.1)`, `solar-system-edge.asteroid_spawn_definitions = lib.spawn_definitions(routes.vesta_edge, 0.9)`, `solar-system-edge.solar_power_in_space = 30`, `shattered-planet.asteroid_spawn_definitions = lib.spawn_definitions(routes.edge_shattered, 0.8)` (vanilla shapes `space-age/prototypes/planet/planet.lua:706-739`) | §1 |
| `space-connections.lua` | `space-connection` **`nauvis-inner-belt`** (length 15000, order "a"), **`inner-belt-psyche-field`** (15000, "b"), **`inner-belt-vesta-family`** (15000, "c"), **`nauvis-outer-belt`** (30000, "d"), **`outer-belt-trojan-cloud`** (30000, "e"), **`vesta-family-solar-system-edge`** (100000, "f"); each `subgroup="planet-connections"`, `from`, `to`, `asteroid_spawn_definitions=lib.spawn_definitions(routes.<route>)`. Edit: `data.raw["space-connection"]["solar-system-edge-shattered-planet"].asteroid_spawn_definitions = lib.spawn_definitions(routes.edge_shattered)` (kept: three achievements track it, `space-age/prototypes/achievements.lua:97-126`). Icons are generated by `space-age/data-updates.lua:1-13` because these exist before it runs | §1 |
| `technology-additions.lua` | `technology` **`s-type-advanced-crushing` `carbonaceous-processing` `space-flight` `carbon-baking` `inner-belt-navigation` `silicon-processing` `metallic-refining` `basaltic-processing` `nickel-processing` `lithium-leaching` `outer-belt-navigation` `volatile-processing` `volatiles-science-pack` `trojan-navigation` `phosphate-processing` `metallic-deep-refining` `quantum-research-center`** (17 new) and the in-place overwrite of **`asteroid-reprocessing`** (it already exists at metallurgic tier, `space-age/prototypes/technology.lua:1761-1795`). One helper `tech(name, icon, prereqs, packs, count, effects, extra)`; details in section 1.2 | §9 Added |
| `technology-modifications.lua` | In-place edits listed in section 1.3: `space-platform space-science-pack steam-power electronics automation steel-processing sulfur-processing oil-processing calcite-processing coal-liquefaction solar-energy advanced-circuit processing-unit low-density-structure nuclear-power uranium-processing kovarex-enrichment-process uranium-ammo military military-4 tungsten-carbide tungsten-steel foundry lithium-processing recycling holmium-processing carbon-fiber stack-inserter promethium-science-pack stellar-discovery-solar-system-edge productivity-module-3 efficiency-module-3 epic-quality health stronger-explosives-7 plastic-bar-productivity asteroid-productivity concrete production-science-pack lubricant` plus the pack sweep (every `unit.ingredients` and `prerequisites` entry `agricultural-science-pack` → `volatiles-science-pack`) | §9 Modified |
| `removals-recipes.lua` | The list in section 3.1 (`data.raw.recipe[n] = nil`) | §7 |
| `removals-entities.lua` | The lists in sections 3.2 and 3.3 (items, entities, shortcuts) | §8 |
| `removals-technologies.lua` | The list in section 3.4, then the scrub pass: strip removed names from every `prerequisites`; drop `unlock-recipe` / `change-recipe-productivity` effects whose recipe is gone; drop `turret-attack` effects whose `turret_id` is gone; drop `research_trigger`s that name a removed entity/item (none should remain after section 1.3, the pass is a guard) | §9 Removed |
| `removals-planets.lua` | Section 3.5: planets `vulcanus gleba fulgora aquilo`, connections, tips, achievements, ambient sounds, `main_menu_simulations = {}`, `data.raw.lightning.lightning.factoriopedia_simulation = nil` | §12 |
| `surface-conditions.lua` | DESIGN.md §11 verbatim (recipes keep only `gravity 0..0`; entities keep the name list `crusher space-platform-hub asteroid-collector thruster`, D-60); `iron-chest` and `steel-chest` are covered by the loop (`space-age/base-data-updates.lua:218-231`) | §8, §11 |
| `starter-pack.lua` | Edits `data.raw["space-platform-starter-pack"]["space-platform-starter-pack"]`: copy `make_tile_area` (`space-age/prototypes/item.lua:10-24`, D-53), `tiles = make_tile_area({{-10,-10},{9,9}}, "space-platform-foundation")`, `initial_items` = the §13 table with `{type="item", name=..., amount=...}` rows and `quality_min/quality_max="normal"` on the foundation row, `create_electric_network=true`; `surface`, `trigger` untouched | §13 |
| `nauvis-stub.lua` | Edits `data.raw.planet.nauvis`: `map_gen_settings` = the §12 void table (`width=64, height=64, autoplace_controls={}, autoplace_settings={entity={settings={}}, decorative={settings={}}, tile={settings={["out-of-map"]={}}}}, property_expression_names={}, starting_area=0, peaceful_mode=true`), `pollutant_type=nil`, `persistent_ambient_sounds=nil`, `platform_surface_render_parameters.platform_backdrop=nil` (D-14), `solar_power_in_space=300`; **not** `hidden` (D-13); the `map_seed_settings` and `player_effects` lines are dropped (no such fields, `base/prototypes/planet/planet.lua:7-60`) | §1, §12 |

#### 1.1 Asteroid classes: sprite source, colour, spawn constants

| Class | Sprites + explosions + particle borrowed from | `shading_data.lights[2].color` (item `random_tint_color`) | Icon tint |
|---|---|---|---|
| S | metallic | `{0.55,0.45,0.35}` grey-brown (`{0.85,0.75,0.65,1}`) | `{0.85,0.75,0.65}` |
| M | metallic | `{0.80,0.85,0.90}` steel (`{0.85,0.88,0.92,1}`) | `{0.85,0.88,0.92}` |
| C | carbonic | vanilla carbonic `{0.16,0.14,0.22}` (`item_tints.yellowing_coal`) | none |
| V | oxide | `{0.75,0.75,0.75}` pale grey, `brightness=0.7` (`{0.9,0.9,0.9,1}`) | `{0.9,0.9,0.9}` |
| E | oxide | `{1,1,1}`, `brightness=1.0`, `ambient_light={0.03,0.03,0.03}` (`{1,1,1,1}`) | `{1,1,1}` |
| D | carbonic | `{0.55,0.12,0.06}` red-black (`{0.7,0.4,0.35,1}`) | `{0.75,0.45,0.4}` |

The vanilla per-type light override (`asteroid.lua:514-516`) is the recolouring lever; `tint` is
not a field on the asteroid graphics set (D-08). The explosions `metallic|carbonic|oxide-asteroid-explosion-1..5`
and particles `*-asteroid-chunk-particle-medium` are separate prototypes that survive the removal
of the vanilla asteroid entities (`space-age/prototypes/entity/explosions.lua:2616,3110`).

Ratio vectors are 7-wide `{s, m, c, v, e, d, promethium}` (D-09). Densities are vanilla constants
(`asteroid-spawn-definitions.lua:17-33`) reassigned; every number here is a placeholder to tune (D-10):

| Location (position on its route) | ratios | chunk | small | medium | big | huge |
|---|---|---|---|---|---|---|
| Home Orbit (0.1 of home_inner and home_outer) | `{75,0,25,0,0,0,0}` | 0.0125 | 0.0008 | 0.0003 | – | – |
| Inner Belt (0.9 of home_inner; 0.1 of inner_psyche, inner_vesta) | `{50,25,0,0,25,0,0}` | 0.0030 | – | 0.0025 | – | – |
| Psyche Field (0.9 of inner_psyche) | `{20,70,0,0,10,0,0}` | 0.0025 | – | – | 0.0025 | 0.0005 |
| Vesta Family (0.9 of inner_vesta; 0.1 of vesta_edge) | `{30,0,10,60,0,0,0}` | 0.0025 | – | 0.0025 | 0.0010 | – |
| Outer Belt (0.9 of home_outer; 0.1 of outer_trojan) | `{10,0,50,0,0,40,0}` | 0.0015 | – | 0.0025 | 0.0020 | – |
| Trojan Cloud (0.9 of outer_trojan) | `{0,0,20,0,0,80,0}` | 0.0030 | – | – | 0.0030 | 0.0015 |
| Solar System Edge (0.9 of vesta_edge; 0.001 of edge_shattered) | `{3,0,5,0,0,2,0}` (vanilla `{3,5,2,0}` mapped by D-12) | 0.0005 | – | – | – | 0.00125 |
| Shattered Planet trip | vanilla `shattered_planet_trip` rows (`:216-237`) with each 4-vector `{a,b,c,p}` rewritten as `{a,0,b,0,0,c,p}` | – | – | – | – | 0.00125 → 0.111 |

Medium/big peaks ×3 at position 0.5 of every route as vanilla does (`:44-48`).

#### 1.2 Added technologies (counts are placeholders, D-61)

Packs: R red, G green, M military, B blue, P production, U utility, W space, Mt metallurgic,
V volatiles, E electromagnetic, C cryogenic.

| Name | Icon (placeholder) | Prerequisites | Unit | Effects |
|---|---|---|---|---|
| `s-type-advanced-crushing` | `__space-age__/graphics/technology/advanced-asteroid-processing.png` | – | 50×R, 15 s | unlock `advanced-s-asteroid-crushing` |
| `carbonaceous-processing` | `asteroid-reprocessing.png` | – | 50×R, 15 s | unlock `advanced-c-asteroid-crushing` |
| `space-flight` | `space-platform-thruster.png` | `steel-processing` | 100×RG, 30 s | unlock `thruster`, `thruster-fuel`, `thruster-oxidizer` |
| `carbon-baking` | `tungsten-carbide.png` | `carbonaceous-processing`, `logistic-science-pack` | 75×RG, 30 s | unlock `carbon-baking` |
| `inner-belt-navigation` | `util.technology_icon_constant_planet("…/technology/vulcanus.png")`, `essential=true` | `space-flight` | 100×RG, 30 s | `unlock-space-location inner-belt` (`use_icon_overlay_constant=true`), unlock `e-asteroid-crushing`, `m-asteroid-crushing` |
| `silicon-processing` | `calcite-processing.png` | `inner-belt-navigation` | 100×RG, 30 s | unlock `advanced-e-asteroid-crushing` |
| `asteroid-reprocessing` (overwrite) | vanilla | `space-flight` | 200×RGW, 30 s | unlock the six `*-asteroid-reprocessing` |
| `metallic-refining` | `tungsten-steel.png`, essential | `inner-belt-navigation` | 200×RGW, 30 s | unlock `advanced-m-asteroid-crushing`, `unlock-space-location psyche-field` |
| `basaltic-processing` | `…/technology/gleba.png` (planet overlay), essential | `military-2`, `inner-belt-navigation` (D-59) | 200×RGW, 30 s | unlock `v-asteroid-crushing`, `advanced-v-asteroid-crushing`, `unlock-space-location vesta-family` |
| `nickel-processing` | `foundry.png` | `metallic-refining`, `chemical-science-pack` | 200×RGB, 30 s | unlock `nickel-plate` |
| `lithium-leaching` | `lithium-processing.png` | `carbonaceous-processing`, `sulfur-processing`, `chemical-science-pack` | 200×RGB, 30 s | unlock `lithium-leaching` |
| `outer-belt-navigation` | `…/technology/aquilo.png` (planet overlay), essential | `nuclear-power` (D-38) | 200×RGB, 30 s | `unlock-space-location outer-belt`, unlock `d-asteroid-crushing`, `advanced-thruster-fuel`, `advanced-thruster-oxidizer` (D-39) |
| `volatile-processing` | `bioflux-processing.png` | `outer-belt-navigation` | 300×RGBW, 30 s | unlock `advanced-d-asteroid-crushing`, `volatile-separation`, `methane-cracking` |
| `volatiles-science-pack` | `agricultural-science-pack.png`, essential | `volatile-processing`, `carbon-fiber` (D-40) | 300×RGBW, 30 s | unlock `volatiles-science-pack` |
| `trojan-navigation` | `solar-system-edge.png` (planet overlay), essential | `rocket-turret`, `volatiles-science-pack` | 500×RGBWV, 60 s | `unlock-space-location trojan-cloud` |
| `phosphate-processing` | `holmium-processing.png` | `basaltic-processing`, `sulfur-processing`, `utility-science-pack` | 300×RGBU, 30 s | unlock `phosphate-processing` |
| `metallic-deep-refining` | `big-mining-drill.png` | `metallurgic-science-pack` | 500×RGBW Mt, 60 s | unlock `m-asteroid-refining` |
| `quantum-research-center` | `biolab.png` | `quantum-processor` | 1000×RGBPUW Mt E C, 60 s | unlock `quantum-research-center` |

#### 1.3 Modified technologies (final state)

| Tech | Prerequisites | Unit / trigger | Effects |
|---|---|---|---|
| `space-platform` | `{}` | keep `research_trigger={type="create-space-platform"}`; set `researched=true` from control.lua | `{type="unlock-space-platforms", modifier=true, hidden=true}`, `{type="unlock-travel-to-space-platforms", modifier=true}` (D-22, D-23) |
| `space-science-pack` | `{"space-flight"}` | `research_trigger={type="craft-item", item="thruster"}` | unchanged (unlock `space-science-pack`) |
| `steam-power` | – | trigger unchanged | `heat-pipe` only (pipe, pipe-to-ground, steam-engine are start recipes; boiler, offshore-pump removed) |
| `electronics` | – | trigger unchanged | `{}` (all five unlocks are start recipes; vanilla ships effect-less techs, `base/prototypes/technology.lua:2922-2937`) |
| `automation-science-pack` | unchanged | unchanged | unchanged |
| `automation` | unchanged | unchanged | `long-handed-inserter` only |
| `steel-processing` | `{"carbonaceous-processing","logistic-science-pack"}` | 50×RG, 5 s (D-33) | unchanged |
| `sulfur-processing` | `{"carbonaceous-processing","logistic-science-pack"}` | unchanged 150×RG | + unlock `chemical-plant` (D-31) |
| `oil-processing` | `{"carbon-baking","sulfur-processing","calcite-processing"}` | `research_trigger={type="craft-item", item="coal"}` | `oil-refinery`, `simple-coal-liquefaction`, `solid-fuel-from-petroleum-gas`, `heavy-oil-cracking`, `light-oil-cracking`, `solid-fuel-from-heavy-oil`, `solid-fuel-from-light-oil` (D-32); locale name "Coal liquefaction" |
| `calcite-processing` | `{"carbonaceous-processing"}` | `craft-item calcite` | `acid-neutralisation`, `steam-condensation` (`simple-coal-liquefaction` moved to oil-processing) |
| `coal-liquefaction` | `{"oil-processing","production-science-pack"}` | 200×RGBP, 30 s (D-28) | unchanged |
| `solar-energy` | `{"silicon-processing"}` | unchanged | unchanged |
| `advanced-circuit` | `{"plastics","silicon-processing"}` | unchanged RG (D-29) | unchanged |
| `processing-unit` | unchanged | unchanged RGB (D-30) | unchanged |
| `low-density-structure` | `{"nickel-processing","chemical-science-pack"}` | unchanged | unchanged |
| `nuclear-power` | `{"nickel-processing"}` (D-37) | unchanged 800×RGB | `nuclear-reactor`, `heat-exchanger`, `steam-turbine` |
| `uranium-processing` | `{"phosphate-processing"}` | `craft-item uranium-ore` | `centrifuge`, `uranium-processing`, `uranium-fuel-cell` |
| `kovarex-enrichment-process` | unchanged | unchanged | minus `nuclear-fuel` |
| `uranium-ammo` | `{"uranium-processing","military-4"}` | unchanged | `uranium-rounds-magazine` only |
| `military` | unchanged | unchanged | `submachine-gun` only |
| `military-4` | unchanged | unchanged | minus `combat-shotgun` |
| `tungsten-carbide` | `{"metallic-refining"}` | `craft-item tungsten-ore` | unchanged (`carbon`, `tungsten-carbide`) |
| `tungsten-steel` | `{"foundry"}` | `craft-item foundry` (D-34) | unchanged |
| `foundry` | unchanged | unchanged | minus `molten-iron-from-lava`, `molten-copper-from-lava` |
| `lithium-processing` | `{"lithium-leaching"}` | `{type="craft-fluid", fluid="lithium-brine"}` (D-41, Q-06) | unchanged |
| `recycling` | `{"production-science-pack","processing-unit","concrete"}` | `unit` restored from `recycler/data.lua:71-96` (5000×RGBP, 15 s), `research_trigger=nil` (D-42) | minus `scrap-recycling` |
| `holmium-processing` | `{"phosphate-processing"}` | unchanged `craft-item holmium-ore` | unchanged |
| `carbon-fiber` | `{"volatile-processing"}` | 500×RGBW, 60 s (D-40) | unchanged |
| `stack-inserter` | unchanged | pack sweep | unchanged |
| `promethium-science-pack` | `{"stellar-discovery-solar-system-edge"}` | pack sweep (D-21) | unchanged |
| `stellar-discovery-solar-system-edge` | unchanged `{"fusion-reactor","railgun"}` | pack sweep | unchanged |
| `productivity-module-3` | `{"productivity-module-2","volatiles-science-pack"}` | pack sweep | unchanged |
| `efficiency-module-3`, `epic-quality`, `health`, `stronger-explosives-7` | `agricultural-science-pack` → `volatiles-science-pack` | pack sweep | unchanged |
| `plastic-bar-productivity` | `{"volatiles-science-pack","production-science-pack"}` | pack sweep | minus `bioplastic` |
| `asteroid-productivity` | `{"volatiles-science-pack"}` | pack sweep | `change-recipe-productivity 0.1` on the 12 crushing recipes and `m-asteroid-refining` |
| `concrete` | `{"steel-processing","automation-2"}` | unchanged | unchanged |
| `production-science-pack` | `{"productivity-module","concrete"}` | unchanged | unchanged |
| `lubricant` | `{"oil-processing"}` | unchanged | unchanged |
| pack sweep (also `foundation fusion-reactor fusion-reactor-equipment legendary-quality quantum-processor railgun railgun-damage-1 research-productivity rocket-turret toolbelt-equipment transport-belt-capacity-1 transport-belt-capacity-2`) | – | every `{"agricultural-science-pack",1}` → `{"volatiles-science-pack",1}` (23 techs, `space-age/prototypes/technology.lua`, first at 317) | – |

---

## 2. Deviation register

Kind: **M** = mechanical, **D** = design (user confirms).

| # | DESIGN.md | 2.1.17 data | Decision | Kind |
|---|---|---|---|---|
| D-01 | §4 "Category `crushing`", §5, §6 | `RecipePrototype::category` removed; field is the array `categories` (`changelog.txt:609`; every vanilla recipe, `space-age/prototypes/recipe.lua:892`) | Every recipe the mod writes or edits uses `categories = {...}` | M |
| D-02 | §4 `@p` and "raise `probability`" | `probability` replaced by `independent_probability`; `shared_probability={min,max}` added (`changelog.txt:668-669`, `recipe.lua:905`) | `@p` → `independent_probability = p`; `2–4` → `amount_min=2, amount_max=4` | M |
| D-03 | §4 reprocessing "same @0.4, neighbours @0.2" | Vanilla uses one shared roll `{0,0.4},{0.4,0.6},{0.6,0.8}`, `allow_productivity=false`, `allow_quality=false` (`recipe.lua:1028-1048`; 2.1.7 forbids quality modules on reprocessing, `changelog.txt:414`) | Shared roll. Same expected 0.8 chunks per craft, at most one chunk out, quality and productivity off | M |
| D-04 | §4 chunk return `ignored_by_productivity=1, ignored_by_stats=1` | Vanilla marks `ignored_by_stats=1` on the chunk ingredient and the chunk result, never `ignored_by_productivity` (`recipe.lua:899,905`; 2.1.7 "lossy catalyst" fix, `changelog.txt:433`) | Copy vanilla exactly. `ignored_by_productivity` is not written (Q-09) | M |
| D-05 | §4 "`main_product` set" | No vanilla crushing recipe sets `main_product`; six recipes sharing `iron-ore` as main product would all be named "Iron ore" | Leave `main_product` unset; each recipe gets `icons`, `subgroup`, `order` and a `recipe-name` locale line | D |
| D-06 | §3 `volatiles-science-pack` type `tool` | All packs are `type="item"`; labs accept any item (`changelog.txt:535`, `base/prototypes/item.lua:683-697`) | `type="item"`, appended to `data.raw.lab.lab.inputs` and copied into the research center's `inputs` | M |
| D-07 | §6 `ice-melting.categories = {"melting","chemistry"}` | No `melting` recipe-category exists (base + space-age category lists) | `categories.lua` defines it first | M |
| D-08 | §2/§6 "copy the vanilla metallic definitions; set `tint`" | `AsteroidPrototype::mass` removed, `damage_per_hp` required (`changelog.txt:554`); no `tint` field, colour lives in `shading_data.lights` (`asteroid.lua:75-161,514-516`); only the small size drops chunks, medium/big/huge spawn the next size down (`:238-279`); names are `<size>-<type>-asteroid` / `<type>-asteroid-chunk` | Copy the whole generator; names `small-s-asteroid`, `s-asteroid-chunk`; colour through `lights[2]`, icon tint and item `random_tint_color`; reuse vanilla explosion and particle prototypes | M |
| D-09 | §1 "copy the shape of asteroid-spawn-definitions.lua" | The helper hard-codes three types and a 4-slot ratio vector (`asteroid-spawn-definitions.lua:10-15,371-393`); a planet position must be a data point (`:333,421`) | Own copy with a 7-slot vector; locations pass exactly 0.1 or 0.9 (0.8/0.001 on the shattered trip as vanilla) | M |
| D-10 | §1 Home "S 75 · C 25 (small/medium only)" | Vanilla nauvis orbit spawns chunks only; no vanilla route spawns small asteroids (`:35-53`) | Read as "chunks, small and medium, nothing bigger": chunk 0.0125 (vanilla nauvis), small 0.0008, medium 0.0003. Numbers are placeholders | D |
| D-11 | §1 `solar_power_in_space` as percentages | Absolute numbers: nauvis 300, vulcanus 600, gleba 200, fulgora 120, aquilo 60 (`base/prototypes/planet/planet.lua:22`, `space-age/prototypes/planet/planet.lua:30,132,300,625`) | Home 300 (= vanilla Nauvis orbit), Inner 360, Psyche 330, Vesta 270, Outer 150, Trojan 90, Edge 30 | D |
| D-12 | §1 Edge and Shattered "vanilla" spawn | Vanilla ratios are `{metallic, carbonic, oxide, promethium}` and name the three removed classes | Map metallic→S, carbonic→C, oxide→D (ice) on the Edge and the shattered trip | D |
| D-13 | §1/§12 `nauvis.hidden = true` | No vanilla location sets `hidden`; 2.0.33 made hidden locations disappear from the platform schedule and creation GUI (`changelog.txt`, version 2.0.33) | Do not hide nauvis. It is "Home Orbit" through locale; the control.lua teleport keeps players off its surface | D |
| D-14 | §12 step 5 `map_seed_settings`, `player_effects`; §10 "player never sees a planet" | Neither field exists on nauvis; the real seed field is `map_seed_offset` (`base/prototypes/planet/planet.lua:19`); 2.1.7 draws Nauvis behind any platform parked there via `platform_surface_render_parameters.platform_backdrop` (`space-age/base-data-updates.lua:1280-1330`) | Drop the two lines; set `platform_backdrop = nil` (dust stays) | D (backdrop) / M (fields) |
| D-15 | §8/§12 "removing resources kills the autoplace controls" and step 4 deletes resource/enemy controls | `autoplace-control` prototypes are independent (`base/prototypes/autoplace-controls.lua`, `space-age/prototypes/autoplace-controls.lua`) and `base/prototypes/map-gen-presets.lua:18-25` names nine of them | Leave all 28 controls in place; the void nauvis `autoplace_controls = {}` never uses them. Listed in 3.6 as an untouched set | M |
| D-16 | §12 "expect load errors naming a procession, surface-property or locale" | Processions and surface-properties never name a planet; locale is absent and cannot fail a load. What does name dead planets: 35+ ambient sounds through the 2.1.7 `planets` list (`changelog.txt:550`, `space-age/prototypes/ambient-sounds.lua`), 10 tips, 4 achievements, `default_import_location` on 58 items, `factoriopedia_simulation.planet` on kept `lightning` | Explicit delete lists in section 3.5; ambient sounds removed by field, not by name | M |
| D-17 | §12 step 4 "tips, factoriopedia sims" | 46 tips name a removed prototype in a trigger, tag or simulation and 10 more depend on them; 20 achievements name removed prototypes; menu simulations run on dead planets (`space-age/data.lua:67-95`) | Delete the 56 tips, 20 achievements, edit `rush-to-space`, set `main_menu_simulations = {}` | M |
| D-18 | §12 "do all of this in data-updates.lua" | Recycler generates recycling recipes in its data-updates from whatever exists (`recycler/data-updates.lua:1-25`) | Everything in `data.lua`; only the `default_import_location` scrub in `data-updates.lua` | M |
| D-19 | (unstated) elevated-rails | space-age hard-depends on it (`space-age/info.json:8`) | Explicit dependency; its content is deleted by the mod | M |
| D-20 | (unstated) quality | Optional-recommended for space-age (`changelog.txt:466`); crusher's `allowed_effects` includes "quality" with quality optional in vanilla | `? quality`; `allow_quality=false` on reprocessing; crusher untouched | M |
| D-21 | §1/§9 Edge and promethium "vanilla"; §14 volatiles replaces agricultural | Edge unlock is `stellar-discovery-solar-system-edge` (`space-age/prototypes/technology.lua:2001-2034`, `changelog.txt:477`); `promethium-science-pack` needs `biter-egg-handling` (`:2053`); 23 techs cost agricultural packs; `rush-to-space.research_with` and the lab inputs name it | Keep the stellar tech as the Edge gate; drop `biter-egg-handling`; sweep the pack everywhere (1.3) | M |
| D-22 | §10 teleport is enough | 2.1.7 locks character travel to platforms until a tech grants `unlock-travel-to-space-platforms` (`changelog.txt:463`, `technology.lua:378-381`); all three carriers are removed | Effect on `space-platform`; `force.unlock_travel_to_space_platforms = true` in control.lua | M |
| D-23 | §9 `space-platform` "start; unlocks nothing; drop rocket-silo prereq" | No data field pre-researches a tech; `unlock-space-platforms` lives on removed `rocket-silo` (`space-age/base-data-updates.lua:54-58`) | Keep the tech with `prerequisites={}`, both modifiers, its trigger; `researched = true` in `on_init`/`on_force_created` | M |
| D-24 | §10 `on_player_created` creates a platform; `force.platforms[1]` | One platform per player in multiplayer; `platforms` is keyed by index (`changelog.txt:1857`) | One platform per force, index in `storage`, `physical_surface` test, `on_player_respawned` | M |
| D-25 | §10 (unstated) freeplay | Scenario handlers run first (`changelog.txt:14001`); freeplay's crash site and intro fire on nauvis | `on_init` remote calls to freeplay (skip intro, disable crash site, replace created items) | M |
| D-26 | (unstated) victory | `space-finish-script.lua:4` wins the game at `solar-system-edge`, `can_continue=true` | Unchanged: the Edge is "vanilla" in §1. Alternative if unwanted: `remote.call("space_finish_script","set_no_victory",true)` | D |
| D-27 | §7/§9 `rail-signals`, `nuclear-fuel`, `satellite` | `rail-signals` and `nuclear-fuel` are not technologies; `satellite` is already deleted by space-age (`base-data-updates.lua:25-26`) | Signals go with `automated-rail-transportation`; `nuclear-fuel` recipe removed and stripped from `kovarex-enrichment-process`; satellite ignored | M |
| D-28 | §9 `coal-liquefaction` "purple, unchanged" | Space Age made it metallurgic (`base-data-updates.lua:658-671`) | Restore base: `{oil-processing, production-science-pack}`, 200×RGBP | M |
| D-29 | §9 `advanced-circuit` "blue" | It is a prerequisite of `chemical-science-pack` (`base/prototypes/technology.lua:2596`) — a cycle | Stays RG; gains prerequisite `silicon-processing` | D |
| D-30 | §9 `processing-unit` "yellow" | Prerequisite of `utility-science-pack` (`:2674`) — a cycle | Stays RGB | D |
| D-31 | §9 oil-processing prereq `sulfur-processing` | `sulfur-processing` has prerequisite `oil-processing` (`:4702`) — a cycle; sulfuric acid (needed by `simple-coal-liquefaction`) needs a chemical plant, which `oil-processing` unlocks | `sulfur-processing` ← `carbonaceous-processing` + green and it unlocks `chemical-plant`; `oil-processing` keeps the refinery | D |
| D-32 | §7 removes `advanced-oil-processing`; "everything else stays" | Cracking and solid-fuel-from-heavy/light-oil are unlocked only there (`:4635-4674`); `lubricant` depends on it | Move the four recipes to `oil-processing`; `lubricant` ← `oil-processing` | D |
| D-33 | §9 steel-processing prereq only; §14 "green, same as vanilla" | Vanilla steel is red-only (`:1983-2005`) | Green: prereqs `{carbonaceous-processing, logistic-science-pack}`, 50×RG, per §14's wording | D |
| D-34 | §9 removes `big-mining-drill` | `tungsten-steel` needs it and triggers on crafting it (`space-age/prototypes/technology.lua:783-800`) | `tungsten-steel` ← `foundry`, trigger `craft-item foundry` | M |
| D-35 | §7 "all rail recipes"; §9 removes `advanced-material-processing-2`, `railway` | `production-science-pack` recipe needs 30 `rail` (`base/prototypes/recipe.lua:2000-2010`) and the tech needs both removed techs | Recipe: 1 electric-furnace + 1 productivity-module + 15 steel-plate + 15 iron-stick → 3; tech ← `{productivity-module, concrete}` | D |
| D-36 | §9 removes `advanced-material-processing` | `concrete` and `low-density-structure` depend on it | `concrete` ← `{steel-processing, automation-2}`; LDS ← `{nickel-processing, chemical-science-pack}` (§9 already says nickel) | M |
| D-37 | §9 `nuclear-power` "prereq nickel-processing"; `uranium-processing` trigger only | `nuclear-power` ← `uranium-processing` ← `uranium-mining` (mining-with-fluid, useless); uranium arrives at yellow (`phosphate-processing`) while §9 puts `outer-belt-navigation` at blue behind `nuclear-power` | `nuclear-power` ← `{nickel-processing}` only; `uranium-fuel-cell` moves to `uranium-processing`; `uranium-mining` removed; `uranium-processing` ← `phosphate-processing` | D |
| D-38 | §9 `outer-belt-navigation` prereq "nuclear-power or solar-2" | Prerequisites are AND-lists; no `solar-2` tech exists | `{nuclear-power}` | M |
| D-39 | §9 silent on `advanced-asteroid-processing`, `asteroid-productivity` | The former unlocks the vanilla advanced crushing plus `advanced-thruster-fuel/oxidizer` and costs agricultural; the latter names the six vanilla recipes (`technology.lua:1797-1841,2108-2160`) | Delete the former; advanced thruster fuel/oxidizer unlock on `outer-belt-navigation` (§1: "better thrusters" gate the Outer Belt); `asteroid-productivity` rewritten to the 13 new recipes, prereq `volatiles-science-pack` | D |
| D-40 | §9 `carbon-fiber` "move to volatiles"; §5 pack needs carbon-fiber | Circular | `carbon-fiber` tech ← `volatile-processing`, 500×RGBW; `volatiles-science-pack` tech ← `{volatile-processing, carbon-fiber}` | D |
| D-41 | §9 `lithium-processing` trigger `craft-fluid lithium-brine` | No vanilla tech uses `craft-fluid`; the checkout cannot confirm or deny it (harness accepts it) | Follow the design; if the game rejects the trigger type, fall back to `{type="craft-item", item="hydrated-silicate"}` (Q-06) | D |
| D-42 | §7 removes `scrap-recycling`; recycler unmentioned | `recycling` tech is gated on `planet-discovery-fulgora` and mining `fulgoran-ruin-vault` (`base-data-updates.lua:925-936`); `holmium-processing` depends on it | Restore the recycler mod's own tech (`recycler/data.lua:71-96`), strip `scrap-recycling`; `holmium-processing` ← `phosphate-processing` | D |
| D-43 | §9 `calcite-processing`, `tungsten-carbide` "trigger only" | Both have prerequisite `planet-discovery-vulcanus` (`technology.lua:648,671`) | `calcite-processing` ← `carbonaceous-processing`; `tungsten-carbide` ← `metallic-refining` | M |
| D-44 | §9 removes `construction-robotics`; §15 Q2 personal roboports | `personal-roboport-equipment` ← `construction-robotics`; no construction-robot recipe | Remove both personal-roboport techs, items, recipes, equipment (§ fixed decision "no roboports") | D |
| D-45 | §7/§8 predate 2.1.7 | `landing-pad-unloading-bay` item, recipe, entity (`cargo-bay` type), tech added in 2.1.7 (`changelog.txt:393`) | Removed with `cargo-landing-pad` | M |
| D-46 | §5 `carbon-baking`; §9 removes `bioflux-processing` | `coal-synthesis` (5 carbon + 1 sulfur + 10 water → 1 coal) is unlocked only by `bioflux-processing` (`changelog.txt:476`) | Remove `coal-synthesis`; `carbon-baking` is the coal route. The vanilla `carbon` recipe (coal + sulfuric acid) stays on `tungsten-carbide` | D |
| D-47 | §5 `steel-plate` and `carbon-baking` in the electric furnace | `electric-furnace.source_inventory_size = 1` (`base/prototypes/entity/entities.lua:4334`); every vanilla smelting recipe has one ingredient | Set `source_inventory_size = 2` and keep `{"smelting"}`. If the furnace refuses two-ingredient recipes in-game (Q-07), switch both to `{"crafting"}` | D |
| D-48 | §6 heating-panel three-field `heat_buffer`, void source | Every reactor also carries `connections`, `heat_picture`, `minimum_glow_temperature`, patches (`entities.lua:8931-8996`; heating tower `space-age/.../entities.lua:2262-2297`); no vanilla reactor uses `{type="void"}` (only offshore-pump and spidertron, `:1965,9982`) | Full heating-tower shape shrunk to 2×2, `neighbour_bonus=0`; void source kept as designed (Q-08 fallback: burner with a hidden free fuel) | M |
| D-49 | §6 heat-boiler "heat exchanger shape, `max_temperature=250`" | The heat source also has `min_working_temperature=500` (`entities.lua:9271-9276`); a copy at 250 never runs. Vanilla `boiler` gets `pressure >= 10` from space-age (`base-data-updates.lua:187`) | Deepcopy `heat-exchanger`, set `min_working_temperature=165`, `minimum_glow_temperature=100` | M |
| D-50 | §6 melter `fixed_recipe` + one fluid output; ice-melting available at start | No vanilla crafter combines `fixed_recipe` with `fluid_boxes` (rocket-silo and captive-biter-spawner have none); `ice-melting` is `enabled=false` and unlocked by removed `space-platform-thruster` | Build it anyway (Q-10); `ice-melting.enabled=true`; `show_recipe_icon=false` | M |
| D-51 | §6 research center "biolab replacement" | biolab has `surface_conditions pressure 1000..1000` (`:1710-1717`), pollution 8, and lists `agricultural-science-pack` | Deepcopy biolab, nil the condition and emissions, copy the edited lab inputs | M |
| D-52 | §6 "vanilla boiler … unmodified" vs §7/§8 remove `boiler` | Contradiction | `boiler` is removed; `heat-boiler` derives from `heat-exchanger` | M |
| D-53 | §13 `make_tile_area`, `initial_items` rows | `make_tile_area` is file-local (`space-age/prototypes/item.lua:10-24`); rows need `type="item"` (`:336`) | Copy the helper; every row `{type="item", name, amount}`; item `auto_recycle=false` (recipe removed, item kept) | M |
| D-54 | §7 "no spoilage anywhere" | `productivity-module-3` needs 1 biter-egg, `efficiency-module-3` 5 spoilage (`base-data-updates.lua:262,267`) | Restore the base three-ingredient recipes; `productivity-module-3` tech ← `{productivity-module-2, volatiles-science-pack}` | D |
| D-55 | §7 removes `tank`, `shotgun`, `combat-shotgun` | `uranium-ammo` needs `tank` and unlocks two cannon shells; shotgun shells and the vehicles' hidden guns remain | `uranium-ammo` ← `{uranium-processing, military-4}`, magazine only; remove `cannon-shell explosive-cannon-shell uranium-cannon-shell explosive-uranium-cannon-shell shotgun-shell piercing-shotgun-shell` and the hidden guns `tank-cannon tank-flamethrower tank-machine-gun vehicle-machine-gun artillery-wagon-cannon spidertron-rocket-launcher-1..4` | M |
| D-56 | §9 start list | `gun-turret` tech would unlock nothing and has no dependents; `electronics` is a prerequisite of `automation-science-pack` | Delete `gun-turret` tech; keep `electronics` with `effects={}` | M |
| D-57 | §9 removes `flamethrower`, `rocket-fuel` (the users of `flammables`) | `rocketry` also requires `flammables` (`base/prototypes/technology.lua:4746`) | Keep `flammables` | M |
| D-58 | §9 silent | `rocket-fuel-productivity` (targets rocket-fuel, rocket-fuel-from-jelly), `rocket-part-productivity`, `scrap-recycling-productivity` name removed recipes; nothing consumes rocket-fuel once `rocket-part` and `nuclear-fuel` are gone | Delete the three; `plastic-bar-productivity` keeps `plastic-bar` only | M |
| D-59 | §9 `basaltic-processing` prereq "military-2" | The Vesta connection starts at the Inner Belt | Add `inner-belt-navigation` | M |
| D-60 | §11 entity keep-list | Hub, collector and thruster use `pressure 0..0`; only the crusher uses `gravity` (`space-age/.../entities.lua:232-236,696-700,841-845,917-921`) | Keep the name list exactly as written | M |
| D-61 | §9 Added table has no counts | – | Counts in 1.2 are placeholders | D |
| D-62 | §15.5 "2.0.11 hub recipe behaviour" | Not in the 2.0.11 changelog section (`changelog.txt:3730-3780`); crusher has no `fixed_recipe` | Keep the question, drop the citation (Q-12) | M |
| D-63 | §9 rename `oil-processing` to "Coal liquefaction" | The `coal-liquefaction` tech already carries that name | `coal-liquefaction` locale becomes "Advanced coal liquefaction" | D |
| D-64 | §9 `advanced-material-processing-2` "fold into start" | Its only effect is `electric-furnace` | `electric-furnace.enabled=true`; tech removed | M |
| D-65 | §9 oil-processing "unlocks … tank" | `storage-tank` is unlocked by `fluid-handling` (`:4556-4583`), which stays | No duplicate unlock; the kit ships one tank | M |
| D-66 | §7 wording "wood / fish" | `wood`, `raw-fish`, `scrap`, `spoilage`, `nutrients`, `jelly`, `yumako`, `yumako-mash`, `jellynut`, seeds, `bioflux`, `biter-egg`, `pentapod-egg` have no source and some spawn units when they spoil (`spoil_to_trigger_result`) | All removed (3.2) | M |
| D-67 | §12 tips/sims | Shortcuts `give-artillery-targeting-remote`, `give-spidertron-remote`, `toggle-personal-roboport`, `toggle-tall-entity-visibility` name removed items/techs; `copy cut paste undo redo give-blueprint give-blueprint-book give-deconstruction-planner give-upgrade-planner import-string` unlock with removed `construction-robotics` | Delete the first four; set `technology_to_unlock = nil` on the rest (blueprints and undo available from the start) | M |
| D-68 | §9 pack ordering "white before blue" | Kept vanilla white-tier techs (speed-module-2, kovarex, …) also list `chemical-science-pack` | Accepted for vanilla techs; the mod's own white techs cost RGW | M |

---

## 3. Removal lists (2.1.17 names)

### 3.1 Recipes (`data.raw.recipe`, 106)

Planet chains (12): `basic-oil-processing advanced-oil-processing molten-iron-from-lava molten-copper-from-lava ammoniacal-solution-separation scrap-recycling biolubricant bioplastic biosulfur burnt-spoilage rocket-fuel-from-jelly coal-synthesis`

Gleba / biters / wood / fish (34): `agricultural-tower agricultural-science-pack artificial-jellynut-soil artificial-yumako-soil overgrowth-jellynut-soil overgrowth-yumako-soil biochamber bioflux biolab captive-biter-spawner capture-robot-rocket copper-bacteria copper-bacteria-cultivation iron-bacteria iron-bacteria-cultivation fish-breeding jellynut-processing yumako-processing nutrients-from-bioflux nutrients-from-biter-egg nutrients-from-fish nutrients-from-spoilage nutrients-from-yumako-mash pentapod-egg tree-seed biter-egg spidertron wooden-chest shotgun combat-shotgun shotgun-shell piercing-shotgun-shell flamethrower-ammo flamethrower`

Burners / vehicles / launch / logistics (51): `boiler stone-furnace steel-furnace burner-mining-drill burner-inserter electric-mining-drill big-mining-drill pumpjack offshore-pump car tank cannon-shell explosive-cannon-shell uranium-cannon-shell explosive-uranium-cannon-shell rail rail-ramp rail-support rail-signal rail-chain-signal train-stop locomotive cargo-wagon fluid-wagon artillery-wagon artillery-shell artillery-turret rocket-silo cargo-landing-pad landing-pad-unloading-bay rocket-part space-platform-starter-pack nuclear-fuel rocket-fuel landfill cliff-explosives land-mine flamethrower-turret lightning-rod lightning-collector roboport construction-robot logistic-robot active-provider-chest passive-provider-chest storage-chest buffer-chest requester-chest heating-tower personal-roboport-equipment personal-roboport-mk2-equipment`

Vanilla asteroid recipes (9): `metallic-asteroid-crushing carbonic-asteroid-crushing oxide-asteroid-crushing advanced-metallic-asteroid-crushing advanced-carbonic-asteroid-crushing advanced-oxide-asteroid-crushing metallic-asteroid-reprocessing carbonic-asteroid-reprocessing oxide-asteroid-reprocessing`

Not recipes, resolved: `satellite` (already gone), `artillery-targeting-remote` (no recipe; item and shortcut in 3.2/3.3). `railgun railgun-ammo railgun-turret` are **kept** (not rails). Kept and re-homed instead of removed: `heavy-oil-cracking light-oil-cracking solid-fuel-from-heavy-oil solid-fuel-from-light-oil` (→ `oil-processing`), `solid-fuel-from-ammonia ammonia-rocket-fuel ice-platform` (were on `planet-discovery-aquilo`; `solid-fuel-from-ammonia` is rewritten and unlocks on `volatile-processing`, `ice-platform` and `ammonia-rocket-fuel` on `lithium-leaching`), `advanced-thruster-fuel advanced-thruster-oxidizer` (→ `outer-belt-navigation`), `thruster thruster-fuel thruster-oxidizer` (→ `space-flight`), `ice-melting` (start), `electric-furnace space-platform-foundation asteroid-collector crusher cargo-bay` (start), `uranium-fuel-cell` (→ `uranium-processing`), `lubricant` (tech re-parented).

### 3.2 Items (`data.raw.item` unless noted, 100)

Vanilla chunks (3): `metallic-asteroid-chunk carbonic-asteroid-chunk oxide-asteroid-chunk`

Gleba / biters / wood / fish (36): item `agricultural-science-pack agricultural-tower artificial-jellynut-soil artificial-yumako-soil overgrowth-jellynut-soil overgrowth-yumako-soil biochamber biolab captive-biter-spawner copper-bacteria iron-bacteria jellynut-seed yumako-seed nutrients spoilage pentapod-egg biter-egg tree-seed wood wooden-chest scrap`; capsule `bioflux jelly jellynut yumako yumako-mash raw-fish`; ammo `capture-robot-rocket flamethrower-ammo shotgun-shell piercing-shotgun-shell`; gun `shotgun combat-shotgun flamethrower`; item-with-entity-data `spidertron`; spidertron-remote `spidertron-remote`

Burners / vehicles / launch / logistics (61): item `boiler stone-furnace steel-furnace burner-mining-drill burner-inserter electric-mining-drill big-mining-drill pumpjack offshore-pump rail-signal rail-chain-signal train-stop rail-support artillery-turret rocket-silo cargo-landing-pad landing-pad-unloading-bay rocket-part nuclear-fuel land-mine flamethrower-turret lightning-rod lightning-collector roboport construction-robot logistic-robot active-provider-chest passive-provider-chest storage-chest buffer-chest requester-chest heating-tower personal-roboport-equipment personal-roboport-mk2-equipment infinity-cargo-wagon`; item-with-entity-data `car tank locomotive cargo-wagon fluid-wagon artillery-wagon`; rail-planner `rail rail-ramp`; ammo `cannon-shell explosive-cannon-shell uranium-cannon-shell explosive-uranium-cannon-shell artillery-shell`; capsule `cliff-explosives artillery-targeting-remote`; gun `tank-cannon tank-flamethrower tank-machine-gun vehicle-machine-gun artillery-wagon-cannon spidertron-rocket-launcher-1 spidertron-rocket-launcher-2 spidertron-rocket-launcher-3 spidertron-rocket-launcher-4`; roboport-equipment `personal-roboport-equipment personal-roboport-mk2-equipment`

Kept on purpose: `rocket-fuel` (made by `ammonia-rocket-fuel`), `landfill` (tile cover), `solid-fuel`, `carbon`, `sulfur`, `coal`, `calcite`, `ice`, `holmium-ore`, `tungsten-ore`, `uranium-ore`, `space-platform-starter-pack` (recipe gone, `auto_recycle=false`).

### 3.3 Entities, whole prototype types unless a name list is given (~330)

- `unit` (14), `unit-spawner` (4), `turret` (4 worms), `segmented-unit` (3), `segment` (60), `capture-robot` (1) and projectile `capture-robot-rocket`; `spider-unit` except `dummy-spider-unit` (6); `spider-leg` (14: six pentapod legs and `spidertron-leg-1..8`)
- `tree` (32), `plant` (3), `fish` (1), `cliff` (5), `resource` (12), `lightning-attractor` (3: `fulgoran-ruin-attractor lightning-rod lightning-collector`)
- `simple-entity` except `parameter-0..9` and `wube-logo-space-platform` (34): `big-demolisher-corpse medium-demolisher-corpse small-demolisher-corpse big-fulgora-rock big-rock big-sand-rock big-stomper-shell medium-stomper-shell small-stomper-shell big-volcanic-rock big-volcanic-rock-hot huge-rock huge-volcanic-rock huge-volcanic-rock-hot copper-stromatolite iron-stromatolite fulgora-sunk-ruin-big fulgora-sunk-ruin-medium-tall fulgoran-ruin-big fulgoran-ruin-colossal fulgoran-ruin-huge fulgoran-ruin-medium fulgoran-ruin-small fulgoran-ruin-stonehenge fulgoran-ruin-vault fulgurite fulgurite-small lithium-iceberg-big lithium-iceberg-huge vulcanus-chimney vulcanus-chimney-cold vulcanus-chimney-faded vulcanus-chimney-short vulcanus-chimney-truncated`
- Rails and trains, whole types: `straight-rail curved-rail-a curved-rail-b half-diagonal-rail legacy-straight-rail legacy-curved-rail elevated-straight-rail elevated-curved-rail-a elevated-curved-rail-b elevated-half-diagonal-rail rail-ramp rail-support rail-signal rail-chain-signal train-stop locomotive cargo-wagon fluid-wagon artillery-wagon infinity-cargo-wagon rail-remnants car spider-vehicle` (the `dummy-*` twins go with their types)
- Burners / launch / logistics, whole types: `mining-drill` (4), `offshore-pump`, `rocket-silo`, `cargo-landing-pad`, `land-mine`, `artillery-turret`, `fluid-turret`, `roboport`, `construction-robot`, `logistic-robot`, `logistic-container` (5), `agricultural-tower`, `roboport-equipment` (2); by name: boiler `boiler`, furnace `stone-furnace steel-furnace`, inserter `burner-inserter`, reactor `heating-tower`, assembling-machine `biochamber captive-biter-spawner`, lab `biolab`, container `wooden-chest`, cargo-bay `landing-pad-unloading-bay`
- Vanilla asteroids: asteroid `small|medium|big|huge-metallic|carbonic|oxide-asteroid` (12); asteroid-chunk `metallic-asteroid-chunk carbonic-asteroid-chunk oxide-asteroid-chunk` (3). Never `parameter-0..9`, `asteroid-chunk-unknown`, or the four promethium asteroids
- Kept: every `corpse`, `explosion`, `particle`, `trivial-smoke`, `projectile` (except `capture-robot-rocket`), decoratives, tiles, `lightning` (its `factoriopedia_simulation` set to nil), `crash-site-*` (freeplay may still reference them), `character`, `dummy-spider-unit`
- Shortcuts (`data.raw.shortcut`): delete `give-artillery-targeting-remote give-spidertron-remote toggle-personal-roboport toggle-tall-entity-visibility`; `technology_to_unlock = nil` on `copy cut paste undo redo give-blueprint give-blueprint-book give-deconstruction-planner give-upgrade-planner import-string` (D-67)

### 3.4 Technologies (86) and prerequisite rewiring

Removed: `planet-discovery-vulcanus planet-discovery-fulgora planet-discovery-gleba planet-discovery-aquilo agricultural-science-pack agriculture artificial-soil bacteria-cultivation biochamber bioflux bioflux-processing jellynut yumako overgrowth-soil heating-tower fish-breeding tree-seeding captivity biter-egg-handling captive-biter-spawner biolab spidertron railway automated-rail-transportation elevated-rail fluid-wagon rail-support-foundations braking-force-1 braking-force-2 braking-force-3 braking-force-4 braking-force-5 braking-force-6 braking-force-7 artillery artillery-shell-range-1 artillery-shell-speed-1 artillery-shell-damage-1 automobilism tank landfill cliff-explosives land-mine flamethrower refined-flammables-1 refined-flammables-2 refined-flammables-3 refined-flammables-4 refined-flammables-5 refined-flammables-6 refined-flammables-7 advanced-oil-processing oil-gathering advanced-material-processing advanced-material-processing-2 construction-robotics logistic-robotics logistic-system personal-roboport-equipment personal-roboport-mk2-equipment worker-robots-speed-1 worker-robots-speed-2 worker-robots-speed-3 worker-robots-speed-4 worker-robots-speed-5 worker-robots-speed-6 worker-robots-speed-7 worker-robots-storage-1 worker-robots-storage-2 worker-robots-storage-3 rocket-silo rocket-fuel big-mining-drill electric-mining-drill mining-productivity-1 mining-productivity-2 mining-productivity-3 lightning-collector uranium-mining gun-turret landing-pad-unloading-bay advanced-asteroid-processing space-platform-thruster rocket-part-productivity scrap-recycling-productivity rocket-fuel-productivity`

Not removed although §9 names them: `rail-signals`, `nuclear-fuel` (not techs, D-27), `flammables` (D-57).

Prerequisite rewiring, every removed tech that still has a kept dependent (computed from the dump):

| Removed tech | Kept dependents → new prerequisite |
|---|---|
| `planet-discovery-vulcanus` | `calcite-processing` → `carbonaceous-processing`; `tungsten-carbide` → `metallic-refining` |
| `planet-discovery-fulgora` | `recycling` → `production-science-pack, processing-unit, concrete` |
| `planet-discovery-aquilo` | `lithium-processing` → `lithium-leaching` |
| `planet-discovery-gleba` | none kept (`agriculture`, `heating-tower` removed) |
| `agricultural-science-pack` | `carbon-fiber` → `volatile-processing`; `efficiency-module-3 epic-quality health plastic-bar-productivity stronger-explosives-7` → `volatiles-science-pack` |
| `advanced-asteroid-processing` | `asteroid-productivity` → `volatiles-science-pack` |
| `advanced-material-processing` | `concrete` → `steel-processing` (keeps `automation-2`); `low-density-structure` → `nickel-processing` (keeps `chemical-science-pack`) |
| `advanced-material-processing-2`, `railway` | `production-science-pack` → `productivity-module, concrete` |
| `advanced-oil-processing` | `lubricant` → `oil-processing` |
| `oil-gathering` | `oil-processing` → `carbon-baking, sulfur-processing, calcite-processing` |
| `biter-egg-handling` | `productivity-module-3` → `productivity-module-2, volatiles-science-pack`; `promethium-science-pack` → `stellar-discovery-solar-system-edge` only |
| `rocket-silo` | `space-platform` → `{}` |
| `big-mining-drill` | `tungsten-steel` → `foundry` |
| `tank` | `uranium-ammo` → `uranium-processing, military-4` |
| `uranium-mining` | `uranium-processing` → `phosphate-processing` |
| `space-platform-thruster` | dependents were the four planet discoveries (removed); `space-science-pack` → `space-flight` |
| `elevated-rail`, `flamethrower`, `construction-robotics`, `logistic-robotics`, `heating-tower`, `captivity`, `tree-seeding`, `electric-mining-drill`, the `worker-robots-*`, `mining-productivity-*`, `braking-force-*`, `refined-flammables-*`, `artillery-*` chains | every dependent is itself removed |
| `gun-turret landing-pad-unloading-bay lightning-collector landfill cliff-explosives land-mine automobilism spidertron fluid-wagon rocket-fuel rocket-fuel-productivity rocket-part-productivity scrap-recycling-productivity personal-roboport-*` | no dependents |

Kept techs whose effects lose entries (the scrub pass does it, listed so the builder can check): `space-platform` (three vanilla crushing recipes, collector, crusher, cargo-bay), `steam-power` (`boiler`, `offshore-pump`), `oil-processing` (`basic-oil-processing`), `foundry` (two lava recipes), `kovarex-enrichment-process` (`nuclear-fuel`), `military` (`shotgun`, `shotgun-shell`), `military-4` (`combat-shotgun`), `uranium-ammo` (two cannon shells), `recycling` (`scrap-recycling`), `plastic-bar-productivity` (`bioplastic`), `asteroid-reprocessing` and `asteroid-productivity` (overwritten), `electronics`, `automation`, `advanced-material-processing-2`'s `electric-furnace` (tech removed, recipe start).

Kept techs whose `research_trigger` names a removed entity and gets replaced (1.3): `calcite-processing` (mined `calcite`), `oil-processing` (`crude-oil`), `lithium-processing` (icebergs), `recycling` (`fulgoran-ruin-vault`), `tungsten-carbide` (volcanic rocks, demolisher corpses), `tungsten-steel` (`big-mining-drill`), `uranium-processing` (`uranium-ore`).

### 3.5 Planets, connections, tips, simulations, achievements, sounds

- Planets: `vulcanus gleba fulgora aquilo` (`data.raw.planet`). Their `procession_graphic_catalogue` tables go with them; no `procession` prototype names a planet (`space-age/prototypes/planet/procession-common.lua`, `planet-to-platform.lua`), so **no procession is removed**. No `surface-property` names a planet; **none removed**.
- Connections (8): `nauvis-vulcanus nauvis-gleba nauvis-fulgora vulcanus-gleba gleba-fulgora gleba-aquilo fulgora-aquilo aquilo-solar-system-edge`. Kept and rewritten: `solar-system-edge-shattered-planet`.
- Tips (`tips-and-tricks-item`, 56 = 46 direct + 10 dependency cascade): `active-provider-chest agriculture aquilo-briefing asteroid-defense buffer-chest burner-inserter-refueling connect-switch construction-robots copy-paste copy-paste-filters copy-paste-requester-chest copy-paste-spidertron copy-paste-trains electric-network electric-pole-connections elevated-rails entity-flip entity-transfers fast-replace fast-replace-belt-splitter fast-replace-belt-underground fulgora-briefing gate-over-rail ghost-building ghost-rail-planner gleba-briefing heating-mechanics insertion-limits lava-processing lightning-mechanics limit-chests logistic-network low-power orbital-logistics passive-provider-chest personal-logistics pump-connection rail-building rail-signals-advanced rail-signals-basic removing-trash-in-space requester-chest space-platform space-science spidertron-control spoilables spoilables-research spoilables-result stack-transfers steam-power storage-chest train-stop-same-name train-stops trains vulcanus-briefing`. Then delete the emptied `tips-and-tricks-item-category` entries `electric-network ghost-building logistic-network space-age space-platform spoilables trains`. 25 tips survive; nine of them (`bulk-crafting drag-building e-confirm fast-obstacle-traversing inserters long-handed-inserters pipette shoot-targeting show-info`) mention removed entities only inside their simulation `init` strings, which is not a load error (Q-13).
- Simulations: `data.raw["utility-constants"].default.main_menu_simulations = {}` (the vanilla table names `vulcanus_* gleba_* fulgora_* aquilo_* nauvis_* platform_*` scripts, `space-age/data.lua:67-95`, whose bodies are not in the checkout). `factoriopedia_simulation = nil` on `data.raw.lightning.lightning` (planet fulgora); every other simulation with a dead `planet` sits on a removed prototype.
- Achievements (20 deleted): `arachnophilia getting-on-track getting-on-track-like-a-pro visit-aquilo visit-fulgora visit-gleba visit-vulcanus logistic-network-embargo get-off-my-lawn it-stinks-and-they-do-like-it it-stinks-and-they-dont-like-it art-of-siege if-it-bleeds pest-control size-doesnt-matter we-need-bigger-guns watch-your-step research-with-agriculture todays-fish-is-trout-a-la-creme trans-factorio-express`. Edited: `rush-to-space.research_with = {"metallurgic-science-pack","electromagnetic-science-pack","volatiles-science-pack"}`. Kept although unreachable (they name no removed prototype): `keeping-your-hands-clean steamrolled mining-with-determination terraformer automated-construction automated-cleanup delivery-service you-have-got-a-package you-are-doing-it-right lazy-bastard no-time-for-chitchat there-is-no-spoon smoke-me-a-kipper-i-will-be-back-for-breakfast raining-bullets steam-all-the-way pyromaniac run-forrest-run`.
- Ambient sounds: remove every `ambient-sound` whose `planets` or `exclude_planets` contains a dead planet. In the checkout that is 35 inline tracks (`vulcanus-1 vulcanus-2 vulcanus-3 vulcanus-3-hero vulcanus-4 vulcanus-5 vulcanus-6 vulcanus-7 vulcanus-8 gleba-1 gleba-1-hero gleba-2 gleba-3 gleba-4 gleba-5 gleba-6 gleba-8 gleba-9 gleba-10 fulgora-1 fulgora-2 fulgora-3 fulgora-4 fulgora-6 fulgora-7 fulgora-8 fulgora-9 fulgora-hero aquilo-2 aquilo-3 aquilo-3-hero aquilo-4 aquilo-6 aquilo-8 aquilo-9`) plus 26 tracks the harness only sees as stubs (`vulcanus-9 vulcanus-10 vulcanus-interlude-1/2 gleba-11 gleba-interlude-1/4 fulgora-5 fulgora-interlude-1..6 aquilo-1 aquilo-5 aquilo-7 aquilo-10 aquilo-interlude-1..4`, `space-age/prototypes/ambient-sounds.lua:358-404`) whose `planets` field exists only in the shipped game. The loop is by field so both sets go. Nauvis tracks and the `space-*` tracks stay.
- Processions: none. Surface properties: none.

### 3.6 Autoplace controls (left in place, D-15)

Orphaned once the resources and planets are gone, but not deleted: resource `iron-ore copper-ore coal stone uranium-ore crude-oil calcite tungsten_ore scrap sulfuric_acid_geyser lithium_brine fluorine_vent vulcanus_coal gleba_stone aquilo_crude_oil`; enemy `enemy-base gleba_enemy_base`; cliff `nauvis_cliff fulgora_cliff gleba_cliff`; terrain `water trees rocks starting_area_moisture vulcanus_volcanism gleba_water gleba_plants fulgora_islands`.

---

## 4. Locale keys (`locale/en/*.cfg`)

`items.cfg`

```
[item-name]
s-asteroid-chunk=S-type asteroid chunk
m-asteroid-chunk=M-type asteroid chunk
c-asteroid-chunk=C-type asteroid chunk
v-asteroid-chunk=V-type asteroid chunk
e-asteroid-chunk=E-type asteroid chunk
d-asteroid-chunk=D-type asteroid chunk
nickel-ore=Nickel ore
nickel-plate=Nickel plate
silicon=Silicon
phosphate-rock=Phosphate rock
hydrated-silicate=Hydrated silicate
volatile-ice=Volatile ice
volatiles-science-pack=Volatiles science pack
heating-panel=Heating panel
heat-boiler=Heat boiler
melter=Melter
quantum-research-center=Quantum research center
[item-description]
s-asteroid-chunk=Ordinary chondrite. Iron, stone, a trickle of copper and sulfur.
m-asteroid-chunk=Iron-nickel. Iron, nickel, tungsten.
c-asteroid-chunk=Carbonaceous. Ice, carbon, calcite, sulfur, hydrated silicate.
v-asteroid-chunk=Basaltic. Stone, phosphate rock, calcite.
e-asteroid-chunk=Enstatite. Sulfur, silicon, stone.
d-asteroid-chunk=Cometary. Ice, carbon, volatile ice.
volatiles-science-pack=__ITEM__volatiles-science-pack__ replaces agricultural science.
[fluid-name]
methane=Methane
```

`entities.cfg`

```
[entity-name]
heating-panel=Heating panel
heat-boiler=Heat boiler
melter=Melter
quantum-research-center=Quantum research center
s-asteroid-chunk=S-type asteroid chunk
... (m c v e d)
small-s-asteroid=Small S-type asteroid
medium-s-asteroid=Medium S-type asteroid
big-s-asteroid=Big S-type asteroid
huge-s-asteroid=Huge S-type asteroid
... (the same four for m c v e d: 24 keys)
[entity-description]
heating-panel=Turns sunlight into heat at a flat 1 MW wherever it is.
heat-boiler=Boils water to 165 °C steam from a heat network.
melter=Melts ice into water. Hand-feed it to bootstrap.
quantum-research-center=Fast lab that accepts every science pack.
s-asteroid=Ordinary chondrite (H/L/LL).
m-asteroid=Iron or stony-iron.
c-asteroid=Carbonaceous chondrite.
v-asteroid=HED / eucrite.
e-asteroid=Enstatite chondrite / aubrite.
d-asteroid=Outer-belt and Trojan, cometary.
```

(The generator sets `localised_description = {"entity-description.<class>-asteroid"}` on every size
and on the chunk, `asteroid.lua:488`, so the six `<class>-asteroid` description keys are the ones read.)

`recipes.cfg`

```
[recipe-name]
s-asteroid-crushing=S-type asteroid crushing
advanced-s-asteroid-crushing=Advanced S-type asteroid crushing
... (m c v e d: 12 keys)
m-asteroid-refining=M-type asteroid refining
s-asteroid-reprocessing=S-type asteroid reprocessing
... (m e v c d: 6 keys)
carbon-baking=Carbon baking
lithium-leaching=Lithium leaching
volatile-separation=Volatile separation
methane-cracking=Methane cracking
phosphate-processing=Phosphate processing
[recipe-description]
s-asteroid-crushing=Iron ore, stone, a chance of copper ore and sulfur.
... (one line per crushing/refining/reprocessing recipe)
lithium-leaching=Hydrated silicate and water into lithium brine, ammonia and stone.
volatile-separation=Volatile ice into ammonia, methane and water.
methane-cracking=Methane and steam into petroleum gas.
phosphate-processing=Phosphate rock and sulfuric acid into fluorine, uranium ore, stone and sometimes holmium ore.
```

Single-product recipes (`nickel-plate`, `volatiles-science-pack`, `quantum-research-center`, `heating-panel`, `heat-boiler`, `melter`) take their name from the product and need no key.

`technologies.cfg`

```
[technology-name]
s-type-advanced-crushing=Advanced S-type crushing
carbonaceous-processing=Carbonaceous processing
space-flight=Space flight
carbon-baking=Carbon baking
inner-belt-navigation=Inner Belt navigation
silicon-processing=Silicon processing
asteroid-reprocessing=Asteroid reprocessing
metallic-refining=Metallic refining
basaltic-processing=Basaltic processing
nickel-processing=Nickel processing
lithium-leaching=Lithium leaching
outer-belt-navigation=Outer Belt navigation
volatile-processing=Volatile processing
volatiles-science-pack=Volatiles science pack
trojan-navigation=Trojan navigation
phosphate-processing=Phosphate processing
metallic-deep-refining=Deep metallic refining
quantum-research-center=Quantum research center
oil-processing=Coal liquefaction
coal-liquefaction=Advanced coal liquefaction
[technology-description]
s-type-advanced-crushing=Copper and phosphate from S-type chunks.
carbonaceous-processing=Calcite, sulfur and hydrated silicate from C-type chunks.
space-flight=Thrusters and the fuel to run them.
carbon-baking=Bake carbon and ice into coal.
inner-belt-navigation=Opens the route to the Inner Belt. M-type and E-type chunks can be crushed.
silicon-processing=Silicon from E-type chunks.
asteroid-reprocessing=Turn one chunk class into a neighbouring class, at a loss.
metallic-refining=Nickel and tungsten from M-type chunks. Opens the route to the Psyche Field.
basaltic-processing=V-type chunks. Opens the route to the Vesta Family.
nickel-processing=Smelt nickel plate.
lithium-leaching=Lithium brine and ammonia from hydrated silicate.
outer-belt-navigation=Opens the route to the Outer Belt. D-type chunks, advanced thruster fuel and oxidizer.
volatile-processing=Ammonia, methane and petroleum gas from volatile ice.
volatiles-science-pack=The science pack made from D-type volatiles.
trojan-navigation=Opens the route to the Trojan Cloud.
phosphate-processing=Fluorine, uranium ore and holmium ore from phosphate rock.
metallic-deep-refining=Slow, dense M-type refining.
quantum-research-center=A lab built around quantum processors.
oil-processing=Heavy oil from coal, calcite and sulfuric acid. Oil refinery and cracking.
```

`locations.cfg`

```
[planet-name]
nauvis=Home Orbit
[planet-description]
nauvis=The orbit the first platform is parked in. Nobody goes down.
[space-location-name]
inner-belt=Inner Belt
psyche-field=Psyche Field
vesta-family=Vesta Family
outer-belt=Outer Belt
trojan-cloud=Trojan Cloud
[space-location-description]
inner-belt=S, M and E-type asteroids.
psyche-field=Dense M-type field. Big and huge asteroids.
vesta-family=V-type asteroids with S and C.
outer-belt=C and D-type asteroids. Far out.
trojan-cloud=Dense D-type cloud.
[space-connection-name]
nauvis-inner-belt=Home Orbit – Inner Belt
inner-belt-psyche-field=Inner Belt – Psyche Field
inner-belt-vesta-family=Inner Belt – Vesta Family
nauvis-outer-belt=Home Orbit – Outer Belt
outer-belt-trojan-cloud=Outer Belt – Trojan Cloud
vesta-family-solar-system-edge=Vesta Family – Solar System Edge
```

No `recipe-category-name` is needed for `melting` in 2.1 (categories are not shown by name in vanilla
locale as far as the checkout shows; add `[recipe-category-name] melting=Melting` if the GUI shows a raw key, Q-15).

---

## 5. Verification

The harness (`tools/README.md`) is the only loader available offline. Usage, quoted:

```
lua5.2 tools/load.lua --data /path/to/factorio-data                      # vanilla only
lua5.2 tools/load.lua --data /path/to/factorio-data --mod . --check      # this mod, checked
lua5.2 tools/load.lua --data ... --mod . --dump tools/out/raw.json       # data.raw as JSON
lua5.2 tools/load.lua --data ... --mod . --dump r.json --dump-types recipe,technology
lua5.2 tools/load.lua --data ... --mod . --find-string vulcanus gleba    # every path holding the word
lua5.2 tools/load.lua --data ... --mod . --verbose                       # every log() and every stub
```

Exit codes: `0` loaded (and no problems with `--check`); `1` `--check` found problems; `2` a stage file
raised an error; `3` bad command line.

Acceptance, all run from `/home/user/space-only-space-age` with `--data /home/user/factorio-data`:

1. `lua5.2 tools/load.lua --data /home/user/factorio-data --mod . ` exits 0. The first line reports the
   stage files that ran (`data.lua`, `data-updates.lua` of this mod are among them) and `functions left in data.raw: 0`.
2. `lua5.2 tools/load.lua --data /home/user/factorio-data --mod . --check` prints `check: 0 problems` and exits 0.
   That covers every check in `tools/check.lua`: dangling recipe ingredients/results, categories, prerequisites,
   effects, unit ingredients, triggers, lab inputs, place results, connections, spawn definitions, locations,
   ambient-sound planets, starter pack, tips, trigger effects, rich text, and the 2.0-spelling flags
   (`recipe-removed-field`, `technology-research-trigger`, `ambient-sound-planet`).
3. `--find-string` over the removed prototype names finds no reference outside a filename. Run it with this
   list (every hit must be a string ending in `.png`, `.ogg` or `.lua`, or absent):
   `metallic-asteroid-chunk carbonic-asteroid-chunk oxide-asteroid-chunk small-metallic-asteroid agricultural-science-pack biter-egg spoilage nutrients scrap rail locomotive cargo-wagon train-stop roboport construction-robot logistic-robot requester-chest boiler stone-furnace steel-furnace burner-inserter burner-mining-drill offshore-pump pumpjack rocket-silo cargo-landing-pad landing-pad-unloading-bay rocket-part heating-tower biochamber biolab captive-biter-spawner agricultural-tower spidertron car tank artillery-turret flamethrower-turret lightning-rod lightning-collector land-mine cliff biter-spawner small-biter small-demolisher planet-discovery-vulcanus planet-discovery-gleba planet-discovery-fulgora planet-discovery-aquilo space-platform-thruster advanced-asteroid-processing`.
   For the four planet words `vulcanus gleba fulgora aquilo` the allowed residue is: filenames; tile and
   decorative names; the subgroups `vulcanus-processes fulgora-processes aquilo-processes`; the explosions
   `nuke-effects-vulcanus nuke-effects-aquilo`; the autoplace controls of 3.6; core noise-expression names.
   Any hit in a `planets`, `planet`, `surface`, `space_location`, `from`, `to`, `default_import_location`,
   `technology`, `prerequisites` or `research_with` field is a failure.
4. `--dump --dump-types technology,recipe,space-location,space-connection,planet` and confirm by reading the
   JSON: 17 new technologies exist; `asteroid-reprocessing` unlocks six `*-asteroid-reprocessing`; no
   technology lists `agricultural-science-pack`; `data.raw.lab.lab.inputs` ends with `volatiles-science-pack`;
   every start-enabled recipe of 1.3 has `enabled = true`; `nauvis.hidden` is nil; the seven connections exist.
5. `git status` shows only the files in section 1 plus `tools/`.

Done means all five hold. The harness cannot prove the game loads (no engine validation, no control stage);
section 6 lists what only the game can answer.

---

## 6. Open questions for an in-game test

Carried from DESIGN.md §15:

- Q-01 (§15.1) Does `force.create_space_platform{planet=...}` accept a space-location name? Every vanilla call passes `"nauvis"` (`tips-and-tricks-simulations.lua:121,431,589,610,638`). If yes, Home Orbit can become a space-location and the nauvis stub shrinks to an engine requirement. Fallback: create at nauvis, then write `platform.space_location` (read/write since 2.0.34, `changelog.txt:2569`).
- Q-02 (§15.2) Personal roboports: removed by D-44; retest only if the user wants them back, in which case `construction-robot` recipe and `personal-roboport-equipment` need a new home.
- Q-03 (§15.3) Does a nauvis with no `resource` prototypes and the void `map_gen_settings` generate? If the game objects, keep one dummy resource with `autoplace = nil`, or replace the tile block with `autoplace_settings = {}` (the space reader's alternative).
- Q-04 (§15.4) `hidden` on a planet is not used (D-13). If the user wants nauvis hidden, prove first that a hidden planet can still be a platform schedule target (2.0.33 says it cannot).
- Q-05 (§15.5) Does the hub or the crusher auto-select a recipe from hub contents with 13 probabilistic crushing recipes? The 2.0.11 citation is unverified (D-62).

New:

- Q-06 Is `research_trigger = {type="craft-fluid", fluid="lithium-brine"}` accepted? No vanilla tech uses it. Fallback in D-41.
- Q-07 Does the electric furnace with `source_inventory_size = 2` craft `steel-plate` (5 iron + 1 carbon) and `carbon-baking` (4 carbon + 1 ice), including recipe auto-selection on the first inserted item? Fallback in D-47.
- Q-08 Does a `reactor` accept `energy_source = {type="void"}` and produce `consumption` worth of heat? Fallback in D-48.
- Q-09 Is `ignored_by_productivity` still accepted on a product in 2.1.17, and does productivity mint chunk returns without it? Vanilla leaves it off (D-04).
- Q-10 Does an `assembling-machine` accept `fixed_recipe` together with `fluid_boxes`, and does the melter run its fixed recipe with the recipe start-enabled?
- Q-11 Does the 2.1.7 travel lock block a scripted `teleport` before `unlock_travel_to_space_platforms` is set, and does a scripted `create_space_platform` fire the `create-space-platform` trigger? control.lua sets the flag and the researched bit before teleporting either way.
- Q-12 Where does a character respawn after dying on the platform, and does `on_player_respawned` fire before the body exists? control.lua teleports on that event.
- Q-13 The nine surviving tips whose simulation scripts mention removed entities (`bulk-crafting drag-building e-confirm fast-obstacle-traversing inserters long-handed-inserters pipette shoot-targeting show-info`): do they error when opened? If so, delete them too.
- Q-14 `low-density-structure` "2 copper → 2 nickel-plate": the vanilla line is 20 copper-plate. Is the intent 2 nickel-plate replacing all 20 copper, or 2 nickel-plate added and copper reduced? The plan writes 2 steel + 2 nickel-plate + 5 plastic-bar.
- Q-15 Does the GUI show a raw key for the new `melting` recipe category anywhere (crafting-machine tooltips)? Add `[recipe-category-name]` if it does.
- Q-16 Is `solar_power_in_space` honoured on a `space-location` (vanilla only sets it on planets), and what does a location that omits it get?
- Q-17 Does an empty `main_menu_simulations` table give a static main menu, or must one simulation remain?
- Q-18 The freeplay remote function names beyond `get_skip_intro` (`changelog.txt:5916`) and the crash-site setters (`changelog.txt:6039`) come from memory: read `data/base/scenarios/freeplay/freeplay.lua` in the installed game and correct `on_init`.
- Q-19 Does the asteroid shader honour a per-class `lights[2]` colour strongly enough to tell S from M and V from E at a glance? If not, add `tint` on `color_texture` and test whether the shader reads it.
- Q-20 Home Orbit spawn rates (D-10): are small and medium asteroids at a parked starting platform survivable with four gun turrets and 200 magazines? Since 2.1.13 asteroids do less damage to a stationary platform (`changelog.txt:103`).
- Q-21 With the Edge victory left in place (D-26), reaching Solar System Edge mid-tree shows the victory screen once. Is that wanted, or should `set_no_victory(true)` be called?
