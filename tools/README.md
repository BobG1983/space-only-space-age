# tools/ — data-stage harness

`load.lua` runs the Factorio 2.1 prototype stage (settings, then data / data-updates /
data-final-fixes) in plain Lua 5.2 against a checkout of
[wube/factorio-data](https://github.com/wube/factorio-data), with this mod loaded last.
It needs no Factorio binary. `check.lua` then cross-references `data.raw` and prints one
line per dangling reference. Together they catch the errors the game raises at load time
("recipe X names unknown item Y", "technology X prerequisite Y does not exist", ...) and
several that the game only reports later.

Written and tuned against factorio-data **2.1.17**.

## Commands

```
lua5.2 tools/load.lua --data /path/to/factorio-data                      # vanilla only
lua5.2 tools/load.lua --data /path/to/factorio-data --mod . --check      # this mod, checked
lua5.2 tools/load.lua --data ... --mod . --dump tools/out/raw.json       # data.raw as JSON
lua5.2 tools/load.lua --data ... --mod . --dump r.json --dump-types recipe,technology
lua5.2 tools/load.lua --data ... --mod . --find-string vulcanus gleba    # every path holding the word
lua5.2 tools/load.lua --data ... --mod . --verbose                       # every log() and every stub
```

| Option | Meaning |
| --- | --- |
| `--data DIR` | the factorio-data checkout: `core/`, `base/`, `elevated-rails/`, `recycler/`, `quality/`, `space-age/` |
| `--mod DIR` | mod to load after space-age; its `info.json` gives the name used by `__name__/` requires |
| `--check` | run every check in `check.lua`; exit 1 when any problem is found |
| `--dump FILE` | write `data.raw` as JSON: keys sorted, functions skipped, NaN and infinities as `null`, empty tables as `[]` |
| `--dump-types a,b` | limit `--dump` to those `data.raw` categories |
| `--find-string N ...` | print `category.name.field...` for every string equal to N or containing N as a whole word (letters, digits and `_` are word characters, so a hyphen is a boundary: `iron-ore` matches inside `iron-ore-melting`), and every table key that matches |
| `--verbose` | print each `log()` call and each stubbed require as it fires |

Exit codes: 0 loaded (and no problems with `--check`); 1 `--check` found problems; 2 a stage
file raised an error (printed with the game-style `__mod__/file.lua:line` traceback); 3 bad
command line.

The first line of output is the load summary:

```
loaded 5174 prototypes in 251 types from 9 stage files; stubs fired 3089 times for 1636 missing files; log() called 0 times; functions left in data.raw: 0
```

Problem lines from `--check` read `<check-name>: <owner type>.<owner name> -> <field> = <missing name>`, for example
`technology-prerequisite: technology.harness-bad-tech -> prerequisites[2] = no-such-tech`.

## How the stage is modelled

- Mod order is fixed: `core/data.lua`, then `base`, `elevated-rails`, `recycler`, `quality`,
  `space-age`, then `--mod`, for each of `data.lua`, `data-updates.lua`,
  `data-final-fixes.lua` in turn. That is the game's dependency order with alphabetical
  tie-breaks; `info.json` dependencies are not resolved.
- The settings stage (`settings.lua`, `settings-updates.lua`, `settings-final-fixes.lua`)
  runs first in its own Lua state when any mod has one of those files. `settings.startup`,
  `settings.global` and `settings.player` are built from each setting prototype's
  `default_value`.
- The data stage runs in **one shared Lua state** for every mod and every phase, with one
  `require` cache. This is what the game does: `base/data-updates.lua` uses `util` and
  `elevated-rails/data.lua` uses `kg` without requiring `core/lualib/util.lua`; both only
  exist because `base/data.lua` ran `require "util"` earlier in the same state.
- `require` resolves `__mod__/a/b`, `__mod__.a.b`, `a.b` and `a/b`. A plain name is tried
  against the current mod's root, then the requiring file's directory, then `core/lualib`
  (so `util`, `meld`, `circuit-connector-sprites` work as bare names). The current mod is
  tracked per file, so a `__space-age__` file that requires a plain name resolves inside
  space-age. A file that returns nothing yields `true`, as in Lua.
- Globals provided: `data` (from `core/lualib/dataloader.lua`), `mods` (name to version for
  the five vanilla mods and the `--mod`; `core` is not listed), `feature_flags` (all true:
  `space_travel`, `spoiling`, `freezing`, `segmented_units`, `expansion_shaders`, `quality`,
  `rail_bridges`, `expansion`), `settings`, `defines`, `log` (to stderr with `--verbose`),
  `localised_print` (to stderr, prefixed `print:`), `table_size`, `unpack`, `serpent`
  (`block`, `line`, `dump`), `math.pow`, `bit32`. No `io`, `os` or `package`.
- `defines.direction` and `defines.constant.default_icon_size` (64) carry the game's real
  values. `defines.prototypes` is built from `core/lualib/prototype-hierarchy.lua` as
  `defines.prototypes[base][type] = 0` for every concrete type, which is the shape
  `core/lualib/prototype-info.lua` asserts. Every other `defines.x.y` is an auto-populated
  distinct integer, stable within a run and different from the game's.
- `pairs` is a sorted snapshot of the keys. Lua 5.2 seeds its string hash per process, so
  native order changes between runs; `recycler/data-updates.lua` inserts into
  `data.raw.recipe` while iterating it, and two barrel-recycling recipes came and went with
  the seed. The game's order is fixed but different from either. Code that depends on
  iteration order can behave differently here than in the game.
- A required file that is absent from the checkout is stubbed: a warning is logged, the
  require returns a table, and the count is reported. The checkout ships no `graphics/`
  sprite-data Lua, no `sound/` Lua and no `menu-simulations/`, so vanilla stubs 1636 files
  (summarised per mod and folder in the load output). A `graphics/` stub carries
  `width`, `height`, `shift`, `line_length` and `frames` because `util.sprite_load` indexes
  them; a `sound/ambient/` stub is an `ambient-sound` prototype because
  `space-age/prototypes/ambient-sounds.lua` puts the required value straight into
  `data:extend`, and its `name` is a guess (`<planet>-<track>`); everything else is an empty
  table. Each stub carries `harness_stub = <requested name>`. A stub outside those folders is
  printed in full and reported by `--check` as `missing-require`.

## Limits

- No engine validation. Field types, required fields, value ranges, sprite sizes, fluid box
  layouts, collision boxes, locale keys and everything the C++ side checks are not checked.
  A clean run here means the Lua ran and the names resolve, not that the game loads.
- The control stage (`control.lua`) is not run. Migrations are not run.
- Prototype fields the checks read are the 2.1.17 shapes: `recipe.categories`, `results`
  only, `independent_probability`, `research_trigger.entities`, `ambient-sound.planets`.
  The `recipe-removed-field`, `technology-research-trigger` and `ambient-sound-planet` checks
  flag the 2.0 spellings.
- Runtime checks (`--check`) cover what is listed below and nothing else. Rich-text tags in
  strings are checked; free-text names inside simulation `init` code are not, use
  `--find-string` for those.

## Checks (`check.lua`)

| Check | What must exist |
| --- | --- |
| `recipe-ingredient`, `recipe-result` | every ingredient and result names an item (any item type from the prototype hierarchy) or a fluid |
| `recipe-removed-field` | no `category`, `additional_categories`, `result`, `result_count`, `always_show_products`, or product `probability` |
| `recipe-category` | every `categories[i]` is a `recipe-category` |
| `recipe-main-product` | `main_product` names one of the results |
| `recipe-category-crafter` | every category a recipe uses appears in some prototype's `crafting_categories` |
| `technology-prerequisite` | prerequisites exist |
| `technology-effect` | `unlock-recipe` / `change-recipe-productivity` recipe, `unlock-space-location` planet or space-location, `unlock-quality` quality, `ammo-damage` / `gun-speed` ammo category, `turret-attack` entity, `give-item` item |
| `technology-unit-ingredient` | `unit.ingredients` name items |
| `technology-research-trigger` | `craft-item` / `send-item-to-orbit` item, `craft-fluid` fluid, `mine-entity` entities, `build-entity` / `capture-spawner` entity; flags the removed `entity` field |
| `lab-input` | lab `inputs` are items |
| `item-place-result`, `item-place-as-tile`, `item-place-as-equipment` | `place_result` entity, `place_as_tile.result` tile, `place_as_equipment_result` equipment |
| `item-fuel-category`, `fuel-category` | item `fuel_category` and energy-source `fuel_categories` exist; flags the removed energy-source `fuel_category` |
| `item-result-links` | `burnt_result`, `spoil_result`, `plant_result`, `rocket_launch_products` |
| `default-import-location` | names a planet |
| `module-category`, `equipment`, `subgroup` | module category; equipment `categories`, `take_result`, grid `equipment_categories`, any `equipment_grid`; every `subgroup` and each subgroup's `group` |
| `minable` | `minable.result` / `results` / `required_fluid` on any prototype |
| `entity-next-upgrade` | exists with the same prototype type |
| `entity-corpse`, `entity-dying-explosion`, `entity-links` | corpse, `character_corpse`, `dying_explosion`, `remains_when_mined`, `placeable_by`, `loot`, `fixed_recipe`, spawner `result_units`, resource `category`, tile `next_direction` / `transition_merges_with_tile`, `quality.next`, `fluid.spent_fluid` |
| `factoriopedia-alternative` | exists within the same base class |
| `space-connection`, `asteroid-spawn` | `from` / `to` are planets or space-locations; each spawn definition names an `asteroid` entity, or an `asteroid-chunk` when `type = "asteroid-chunk"` |
| `location` | `pollutant_type`, `surface_properties` keys, procession sets, `map_gen_settings.autoplace_controls` keys, `autoplace_settings.{entity,tile,decorative}.settings` keys |
| `ambient-sound-planet` | `planets[i]` / `exclude_planets[i]` exist; flags the removed `planet` |
| `starter-pack`, `starter-pack-trigger` | `initial_items` items, `tiles[i].tile` tiles, `surface`, and every create-entity in `trigger` |
| `asteroid-collector-exists`, `crusher-exists` | an `asteroid-collector` prototype exists; some prototype crafts `crushing` |
| `tips-and-tricks` | category, dependencies, trigger / skip_trigger technology, entity, item, recipe, surface |
| `trigger-effect` | every `create-entity`, `create-explosion`, `create-fire`, `create-smoke`, `create-sticker`, `create-trivial-smoke`, `create-particle`, `create-decorative`, `create-asteroid-chunk`, `set-tile`, `insert-item`, `projectile`, `beam`, `stream`, `artillery`, `chain`, `delayed` effect anywhere in any prototype |
| `damage-type`, `surface-condition`, `collision-layer`, `ammo-category`, `crafting-category`, `resource-category`, `fluid-box-filter`, `autoplace-control`, `simulation-planet`, `rich-text` | resistances and damage effects; `surface_conditions[i].property`; `collision_mask.layers` keys; `ammo_category` / `ammo_categories`; `crafting_categories`; `resource_categories`; fluid box `filter`; `autoplace.control`; `simulation.planet`; `[item=…]`, `[entity=…]`, `[fluid=…]`, `[tile=…]`, `[planet=…]`, `[space-location=…]`, `[technology=…]`, `[recipe=…]`, `[virtual-signal=…]`, `[item-group=…]`, `[quality=…]`, `[asteroid-chunk=…]`, `[shortcut=…]` in any string |
| `missing-require` | a stubbed require outside `graphics/`, `sound/`, `menu-simulations/` |
| `function-value` | a function left in `data.raw` |

### Checks loosened so that vanilla 2.1.17 is clean

Each of these hides a narrower mistake a mod could make; the reason is recorded so it can be
tightened again if the data changes.

- `entity-corpse` accepts any entity, not only `corpse` prototypes. The demolisher segments
  in `space-age/prototypes/entity/enemies.lua` set `corpse = "big-demolisher-corpse"`, which
  is a `simple-entity` so it can be mined, and the game loads it.
- `recipe-category-crafter` skips recipes with `parameter = true`. The ten `parameter-N`
  recipes use category `parameters`, which no machine crafts.
- `factoriopedia-alternative` resolves within the base class (any entity for an entity, any
  item for an item) instead of the same type. `curved-rail-a` names `straight-rail`.
- `rich-text` skips a reference holding a `"`. The quality mod's tips build
  `[item="..module_name.."]` by concatenation inside a simulation `init` string.

## Scratch tests

Three throwaway mods were used to prove the mod path (kept outside the repository): one
with settings, relative and mod-prefixed requires, a missing require and twenty seeded
dangling references (`--check` reported every one, exit 1); one that raises in `data.lua`
(exit 2 with `__harness-crash__/data.lua:3: attempt to index local 't' (a nil value)`); one
with no `info.json` (warning, then loads under its directory name).
