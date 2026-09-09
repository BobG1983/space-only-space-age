-- The six new space connections, each carrying the spawn ramp of its route, and the vanilla
-- Edge to Shattered Planet connection rebuilt on the six-class trip. Satisfies DESIGN.md section 1.
-- Shape of space-age/prototypes/planet/planet.lua:741-830. Icons come from space-age's
-- data-updates, which composes one for every connection that exists by then.

local lib = require("__space-only-space-age__.prototypes.asteroid-spawn-lib")
local routes = require("__space-only-space-age__.prototypes.asteroid-spawn-routes")

data:extend(
{
  {
    type = "space-connection",
    name = "nauvis-inner-belt",
    subgroup = "planet-connections",
    from = "nauvis",
    to = "inner-belt",
    order = "a",
    length = 15000,
    asteroid_spawn_definitions = lib.spawn_definitions(routes.home_inner)
  },
  {
    type = "space-connection",
    name = "inner-belt-psyche-field",
    subgroup = "planet-connections",
    from = "inner-belt",
    to = "psyche-field",
    order = "b",
    length = 15000,
    asteroid_spawn_definitions = lib.spawn_definitions(routes.inner_psyche)
  },
  {
    type = "space-connection",
    name = "inner-belt-vesta-family",
    subgroup = "planet-connections",
    from = "inner-belt",
    to = "vesta-family",
    order = "c",
    length = 15000,
    asteroid_spawn_definitions = lib.spawn_definitions(routes.inner_vesta)
  },
  {
    type = "space-connection",
    name = "nauvis-outer-belt",
    subgroup = "planet-connections",
    from = "nauvis",
    to = "outer-belt",
    order = "d",
    length = 30000,
    asteroid_spawn_definitions = lib.spawn_definitions(routes.home_outer)
  },
  {
    type = "space-connection",
    name = "outer-belt-trojan-cloud",
    subgroup = "planet-connections",
    from = "outer-belt",
    to = "trojan-cloud",
    order = "e",
    length = 30000,
    asteroid_spawn_definitions = lib.spawn_definitions(routes.outer_trojan)
  },
  {
    type = "space-connection",
    name = "vesta-family-solar-system-edge",
    subgroup = "planet-connections",
    from = "vesta-family",
    to = "solar-system-edge",
    order = "f",
    length = 100000,
    asteroid_spawn_definitions = lib.spawn_definitions(routes.vesta_edge)
  }
})

-- Kept, not replaced: three achievements track this connection by name.
data.raw["space-connection"]["solar-system-edge-shattered-planet"].asteroid_spawn_definitions = lib.spawn_definitions(routes.edge_shattered)
