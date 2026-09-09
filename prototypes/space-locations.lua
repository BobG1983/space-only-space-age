-- The five new space locations, and the spawn tables of nauvis, solar-system-edge and
-- shattered-planet rebuilt on the six-class routes. Satisfies DESIGN.md section 1.
-- Shape of space-age/prototypes/planet/planet.lua:706-739. Icons are placeholders borrowed from
-- the removed planets; solar_power_in_space is the absolute number of D-11.

local lib = require("__space-only-space-age__.prototypes.asteroid-spawn-lib")
local routes = require("__space-only-space-age__.prototypes.asteroid-spawn-routes")

data:extend(
{
  {
    type = "space-location",
    name = "inner-belt",
    icon = "__space-age__/graphics/icons/vulcanus.png",
    starmap_icon = "__space-age__/graphics/icons/starmap-planet-vulcanus.png",
    starmap_icon_size = 512,
    order = "b-a[inner-belt]",
    subgroup = "planets",
    gravity_pull = -10,
    distance = 20,
    orientation = 0.30,
    magnitude = 1.0,
    label_orientation = 0.15,
    solar_power_in_space = 360,
    asteroid_spawn_influence = 1,
    asteroid_spawn_definitions = lib.spawn_definitions(routes.home_inner, 0.9)
  },
  {
    type = "space-location",
    name = "psyche-field",
    icon = "__space-age__/graphics/icons/fulgora.png",
    starmap_icon = "__space-age__/graphics/icons/starmap-planet-fulgora.png",
    starmap_icon_size = 512,
    order = "b-b[psyche-field]",
    subgroup = "planets",
    gravity_pull = -10,
    distance = 26,
    orientation = 0.36,
    magnitude = 1.0,
    label_orientation = 0.15,
    solar_power_in_space = 330,
    asteroid_spawn_influence = 1,
    asteroid_spawn_definitions = lib.spawn_definitions(routes.inner_psyche, 0.9)
  },
  {
    type = "space-location",
    name = "vesta-family",
    icon = "__space-age__/graphics/icons/gleba.png",
    starmap_icon = "__space-age__/graphics/icons/starmap-planet-gleba.png",
    starmap_icon_size = 512,
    order = "b-c[vesta-family]",
    subgroup = "planets",
    gravity_pull = -10,
    distance = 24,
    orientation = 0.22,
    magnitude = 1.0,
    label_orientation = 0.15,
    solar_power_in_space = 270,
    asteroid_spawn_influence = 1,
    asteroid_spawn_definitions = lib.spawn_definitions(routes.inner_vesta, 0.9)
  },
  {
    type = "space-location",
    name = "outer-belt",
    icon = "__space-age__/graphics/icons/aquilo.png",
    starmap_icon = "__space-age__/graphics/icons/starmap-planet-aquilo.png",
    starmap_icon_size = 512,
    order = "c-a[outer-belt]",
    subgroup = "planets",
    gravity_pull = -10,
    distance = 34,
    orientation = 0.30,
    magnitude = 1.0,
    label_orientation = 0.15,
    solar_power_in_space = 150,
    asteroid_spawn_influence = 1,
    asteroid_spawn_definitions = lib.spawn_definitions(routes.home_outer, 0.9)
  },
  {
    type = "space-location",
    name = "trojan-cloud",
    icon = "__space-age__/graphics/icons/promethium-asteroid-chunk.png",
    starmap_icon = "__space-age__/graphics/icons/promethium-asteroid-chunk.png",
    starmap_icon_size = 64,
    order = "c-b[trojan-cloud]",
    subgroup = "planets",
    gravity_pull = -10,
    distance = 42,
    orientation = 0.20,
    magnitude = 1.0,
    label_orientation = 0.15,
    solar_power_in_space = 90,
    asteroid_spawn_influence = 1,
    asteroid_spawn_definitions = lib.spawn_definitions(routes.outer_trojan, 0.9)
  }
})

-- Home Orbit sits at the origin end of the Home to Inner Belt route.
data.raw.planet.nauvis.asteroid_spawn_definitions = lib.spawn_definitions(routes.home_inner, 0.1)

local edge = data.raw["space-location"]["solar-system-edge"]
edge.asteroid_spawn_definitions = lib.spawn_definitions(routes.vesta_edge, 0.9)
edge.solar_power_in_space = 30

-- Vanilla samples the shattered trip at 0.8, a ratio row of that route.
data.raw["space-location"]["shattered-planet"].asteroid_spawn_definitions = lib.spawn_definitions(routes.edge_shattered, 0.8)
