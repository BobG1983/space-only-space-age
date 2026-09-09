-- In-place edits of vanilla recipes (DESIGN.md sections 5 and 9): the rewrites, the silicon and
-- nickel additions, the tier-0 re-costs, the start-enabled list, and the two entity fields those
-- recipes depend on. Every edit touches fields; no vanilla recipe is replaced whole.

local function recipe(name)
  local found = data.raw.recipe[name]
  if not found then
    error("recipe-rewrites: no recipe named " .. name)
  end
  return found
end

local function item(name, amount)
  return {type = "item", name = name, amount = amount}
end

local function fluid(name, amount)
  return {type = "fluid", name = name, amount = amount}
end

-- Rewrites: steel is iron plus carbon; carbon fiber, stack inserter, solid fuel and the
-- promethium pack lose their planet ingredients.
local steel_plate = recipe("steel-plate")
steel_plate.categories = {"smelting"}
steel_plate.energy_required = 16
steel_plate.ingredients = {item("iron-plate", 5), item("carbon", 1)}

local carbon_fiber = recipe("carbon-fiber")
carbon_fiber.categories = {"crafting-with-fluid"}
carbon_fiber.subgroup = "intermediate-product"
carbon_fiber.order = "c[advanced-intermediates]-d[carbon-fiber]"
carbon_fiber.ingredients = {item("carbon", 2), fluid("petroleum-gas", 10)}

recipe("stack-inserter").ingredients =
{
  item("bulk-inserter", 1),
  item("processing-unit", 1),
  item("carbon-fiber", 2)
}

local small_electric_pole = recipe("small-electric-pole")
small_electric_pole.categories = {"crafting"}
small_electric_pole.ingredients = {item("iron-stick", 1), item("copper-cable", 2)}
small_electric_pole.results = {item("small-electric-pole", 2)}

local solid_fuel_from_ammonia = recipe("solid-fuel-from-ammonia")
solid_fuel_from_ammonia.categories = {"chemistry"}
solid_fuel_from_ammonia.ingredients = {fluid("ammonia", 15), fluid("petroleum-gas", 10)}

-- Keeps its gravity 0 surface condition.
local promethium_science_pack = recipe("promethium-science-pack")
promethium_science_pack.categories = {"crafting"}
promethium_science_pack.ingredients =
{
  item("promethium-asteroid-chunk", 25),
  item("quantum-processor", 1),
  item("volatiles-science-pack", 5)
}
promethium_science_pack.results = {item("promethium-science-pack", 10)}

-- Silicon from E-type chunks goes into circuits and solar panels.
table.insert(recipe("advanced-circuit").ingredients, item("silicon", 1))
table.insert(recipe("processing-unit").ingredients, item("silicon", 2))
recipe("solar-panel").ingredients =
{
  item("silicon", 5),
  item("electronic-circuit", 15),
  item("copper-plate", 5)
}

-- Nickel from M-type chunks goes into turbine blades and aerospace structure.
recipe("low-density-structure").ingredients =
{
  item("steel-plate", 2),
  item("nickel-plate", 2),
  item("plastic-bar", 5)
}
table.insert(recipe("steam-turbine").ingredients, item("nickel-plate", 10))
table.insert(recipe("heat-exchanger").ingredients, item("nickel-plate", 5))

-- Tier-0 re-costs: everything hand-craftable from S-type and C-type basic output.
recipe("space-platform-foundation").ingredients = {item("iron-plate", 2), item("stone-brick", 2)}
recipe("asteroid-collector").ingredients =
{
  item("iron-plate", 20),
  item("iron-gear-wheel", 5),
  item("electronic-circuit", 5)
}
recipe("crusher").ingredients =
{
  item("iron-plate", 20),
  item("iron-gear-wheel", 10),
  item("electronic-circuit", 5)
}
recipe("cargo-bay").ingredients = {item("iron-plate", 20), item("stone-brick", 10)}
recipe("electric-furnace").ingredients =
{
  item("iron-plate", 20),
  item("stone", 10),
  item("electronic-circuit", 5)
}
recipe("heat-pipe").ingredients = {item("iron-plate", 5), item("copper-plate", 5)}
recipe("thruster").ingredients =
{
  item("steel-plate", 20),
  item("iron-gear-wheel", 10),
  item("electronic-circuit", 5)
}
recipe("storage-tank").ingredients = {item("iron-plate", 20)}

-- Rails are gone, so the purple pack is built from furnace, module, steel and sticks.
local production_science_pack = recipe("production-science-pack")
production_science_pack.ingredients =
{
  item("electric-furnace", 1),
  item("productivity-module", 1),
  item("steel-plate", 15),
  item("iron-stick", 15)
}
production_science_pack.results = {item("production-science-pack", 3)}

-- Back to the base three-ingredient forms: no biter egg, no spoilage.
recipe("productivity-module-3").ingredients =
{
  item("productivity-module-2", 4),
  item("advanced-circuit", 5),
  item("processing-unit", 5)
}
recipe("efficiency-module-3").ingredients =
{
  item("efficiency-module-2", 4),
  item("advanced-circuit", 5),
  item("processing-unit", 5)
}

-- The melter runs ice melting from the start; a chemical plant can still run it too.
local ice_melting = recipe("ice-melting")
ice_melting.categories = {"melting", "chemistry"}
ice_melting.enabled = true

-- The electric furnace needs a second source slot for steel (iron plus carbon) and carbon baking.
data.raw.furnace["electric-furnace"].source_inventory_size = 2

-- Recipes available before any research (DESIGN.md section 9). iron-stick is added because the
-- start-enabled small electric pole is made from it.
local start_enabled =
{
  "s-asteroid-crushing", "c-asteroid-crushing",
  "crusher", "asteroid-collector", "cargo-bay", "space-platform-foundation", "electric-furnace",
  "iron-plate", "copper-plate", "stone-brick", "iron-gear-wheel", "iron-stick",
  "pipe", "pipe-to-ground", "copper-cable", "electronic-circuit",
  "inserter", "transport-belt", "small-electric-pole",
  "heating-panel", "heat-boiler", "melter", "ice-melting", "steam-engine",
  "lab", "automation-science-pack", "assembling-machine-1",
  "gun-turret", "firearm-magazine", "iron-chest"
}

-- Tolerant on purpose: the crushing recipes come from another file, and this loop must not
-- decide whether the mod loads. A missing name is written to the log.
for _, name in ipairs(start_enabled) do
  local found = data.raw.recipe[name]
  if found then
    found.enabled = true
  else
    log("recipe-rewrites: start-enabled recipe " .. name .. " does not exist")
  end
end

-- The starter pack item stays although its recipe is removed, so it must not be recyclable.
data.raw["space-platform-starter-pack"]["space-platform-starter-pack"].auto_recycle = false
