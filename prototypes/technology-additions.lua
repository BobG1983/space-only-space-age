-- The seventeen new technologies of DESIGN.md section 9 "Added", built by one helper, and the
-- in-place overwrite of the vanilla asteroid-reprocessing technology (it already exists at
-- metallurgic tier). Field shapes copy space-age/prototypes/technology.lua. Counts are placeholders.

-- Science pack codes used in the unit tables below.
local packs =
{
  R = "automation-science-pack",
  G = "logistic-science-pack",
  M = "military-science-pack",
  B = "chemical-science-pack",
  P = "production-science-pack",
  U = "utility-science-pack",
  W = "space-science-pack",
  Mt = "metallurgic-science-pack",
  V = "volatiles-science-pack",
  E = "electromagnetic-science-pack",
  C = "cryogenic-science-pack"
}

local function unlock(recipe)
  return {type = "unlock-recipe", recipe = recipe}
end

-- overlay is true when the technology icon carries the planet overlay constant, as the vanilla
-- planet discoveries do; promethium-science-pack omits it for its plain icon.
local function location(name, overlay)
  return {type = "unlock-space-location", space_location = name, use_icon_overlay_constant = overlay}
end

local function planet_icon(file)
  return util.technology_icon_constant_planet("__space-age__/graphics/technology/" .. file)
end

-- icon is a "__mod__/path.png" string or an icons table from planet_icon.
-- pack_codes is a list of keys into packs. extra takes time (default 30) and essential.
local function tech(name, icon, prereqs, pack_codes, count, effects, extra)
  extra = extra or {}
  local ingredients = {}
  for _, code in ipairs(pack_codes) do
    table.insert(ingredients, {packs[code], 1})
  end
  local technology =
  {
    type = "technology",
    name = name,
    icon_size = 256,
    essential = extra.essential,
    effects = effects,
    prerequisites = prereqs,
    unit =
    {
      count = count,
      ingredients = ingredients,
      time = extra.time or 30
    }
  }
  if type(icon) == "table" then
    technology.icons = icon
  else
    technology.icon = icon
  end
  return technology
end

local function technology_icon(file)
  return "__space-age__/graphics/technology/" .. file
end

data:extend(
{
  tech("s-type-advanced-crushing", technology_icon("advanced-asteroid-processing.png"),
    {}, {"R"}, 50,
    {unlock("advanced-s-asteroid-crushing")},
    {time = 15}),

  tech("carbonaceous-processing", technology_icon("asteroid-reprocessing.png"),
    {}, {"R"}, 50,
    {unlock("advanced-c-asteroid-crushing")},
    {time = 15}),

  tech("space-flight", technology_icon("space-platform-thruster.png"),
    {"steel-processing"}, {"R", "G"}, 100,
    {unlock("thruster"), unlock("thruster-fuel"), unlock("thruster-oxidizer")}),

  tech("carbon-baking", technology_icon("tungsten-carbide.png"),
    {"carbonaceous-processing", "logistic-science-pack"}, {"R", "G"}, 75,
    {unlock("carbon-baking")}),

  tech("inner-belt-navigation", planet_icon("vulcanus.png"),
    {"space-flight"}, {"R", "G"}, 100,
    {location("inner-belt", true), unlock("e-asteroid-crushing"), unlock("m-asteroid-crushing")},
    {essential = true}),

  tech("silicon-processing", technology_icon("calcite-processing.png"),
    {"inner-belt-navigation"}, {"R", "G"}, 100,
    {unlock("advanced-e-asteroid-crushing")}),

  tech("metallic-refining", technology_icon("tungsten-steel.png"),
    {"inner-belt-navigation"}, {"R", "G", "W"}, 200,
    {unlock("advanced-m-asteroid-crushing"), location("psyche-field")},
    {essential = true}),

  tech("basaltic-processing", planet_icon("gleba.png"),
    {"military-2", "inner-belt-navigation"}, {"R", "G", "W"}, 200,
    {unlock("v-asteroid-crushing"), unlock("advanced-v-asteroid-crushing"), location("vesta-family", true)},
    {essential = true}),

  tech("nickel-processing", technology_icon("foundry.png"),
    {"metallic-refining", "chemical-science-pack"}, {"R", "G", "B"}, 200,
    {unlock("nickel-plate")}),

  tech("lithium-leaching", technology_icon("lithium-processing.png"),
    {"carbonaceous-processing", "sulfur-processing", "chemical-science-pack"}, {"R", "G", "B"}, 200,
    {unlock("lithium-leaching"), unlock("ice-platform"), unlock("ammonia-rocket-fuel")}),

  tech("outer-belt-navigation", planet_icon("aquilo.png"),
    {"nuclear-power"}, {"R", "G", "B"}, 200,
    {
      location("outer-belt", true),
      unlock("d-asteroid-crushing"),
      unlock("advanced-thruster-fuel"),
      unlock("advanced-thruster-oxidizer")
    },
    {essential = true}),

  tech("volatile-processing", technology_icon("bioflux-processing.png"),
    {"outer-belt-navigation"}, {"R", "G", "B", "W"}, 300,
    {
      unlock("advanced-d-asteroid-crushing"),
      unlock("volatile-separation"),
      unlock("methane-cracking"),
      unlock("solid-fuel-from-ammonia")
    }),

  tech("volatiles-science-pack", technology_icon("agricultural-science-pack.png"),
    {"volatile-processing", "carbon-fiber"}, {"R", "G", "B", "W"}, 300,
    {unlock("volatiles-science-pack")},
    {essential = true}),

  tech("trojan-navigation", planet_icon("solar-system-edge.png"),
    {"rocket-turret", "volatiles-science-pack"}, {"R", "G", "B", "W", "V"}, 500,
    {location("trojan-cloud", true)},
    {essential = true, time = 60}),

  tech("phosphate-processing", technology_icon("holmium-processing.png"),
    {"basaltic-processing", "sulfur-processing", "utility-science-pack"}, {"R", "G", "B", "U"}, 300,
    {unlock("phosphate-processing")}),

  tech("metallic-deep-refining", technology_icon("big-mining-drill.png"),
    {"metallurgic-science-pack"}, {"R", "G", "B", "W", "Mt"}, 500,
    {unlock("m-asteroid-refining")},
    {time = 60}),

  tech("quantum-research-center", technology_icon("biolab.png"),
    {"quantum-processor"}, {"R", "G", "B", "P", "U", "W", "Mt", "E", "C"}, 1000,
    {unlock("quantum-research-center")},
    {time = 60})
})

-- asteroid-reprocessing keeps its vanilla icon and name; it moves to the white tier behind
-- space-flight and unlocks the six ring recipes instead of the three vanilla ones.
local reprocessing = data.raw.technology["asteroid-reprocessing"]
reprocessing.prerequisites = {"space-flight"}
reprocessing.unit =
{
  count = 200,
  ingredients =
  {
    {"automation-science-pack", 1},
    {"logistic-science-pack", 1},
    {"space-science-pack", 1}
  },
  time = 30
}
reprocessing.effects =
{
  unlock("s-asteroid-reprocessing"),
  unlock("m-asteroid-reprocessing"),
  unlock("e-asteroid-reprocessing"),
  unlock("v-asteroid-reprocessing"),
  unlock("c-asteroid-reprocessing"),
  unlock("d-asteroid-reprocessing")
}
