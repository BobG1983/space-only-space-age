-- In-place edits of kept vanilla technologies: DESIGN.md section 9 "Modified" and section 14, with
-- the science pack sweep that turns every agricultural pack into a volatiles pack. The removals
-- files run later and strip names this file does not touch; the lists here are the final state.

local technologies = data.raw.technology

local function unlock(recipe)
  return {type = "unlock-recipe", recipe = recipe}
end

local function unlocks(recipes)
  local effects = {}
  for _, recipe in ipairs(recipes) do
    table.insert(effects, unlock(recipe))
  end
  return effects
end

-- Removes every effect that names one of the given recipes (unlock-recipe or
-- change-recipe-productivity); every other effect stays in order.
local function drop_recipe_effects(technology, recipes)
  local dropped = {}
  for _, recipe in ipairs(recipes) do
    dropped[recipe] = true
  end
  local kept = {}
  for _, effect in ipairs(technology.effects) do
    if not (effect.recipe and dropped[effect.recipe]) then
      table.insert(kept, effect)
    end
  end
  technology.effects = kept
end

local function unit(count, time, pack_names)
  local ingredients = {}
  for _, pack in ipairs(pack_names) do
    table.insert(ingredients, {pack, 1})
  end
  return {count = count, ingredients = ingredients, time = time}
end

local function craft_item(item)
  return {type = "craft-item", item = item}
end

-- Pack sweep first, so the explicit prerequisite lists below are the final word.
local old_pack = "agricultural-science-pack"
local new_pack = "volatiles-science-pack"
for _, technology in pairs(technologies) do
  if technology.prerequisites then
    for i, prerequisite in ipairs(technology.prerequisites) do
      if prerequisite == old_pack then
        technology.prerequisites[i] = new_pack
      end
    end
  end
  if technology.unit and technology.unit.ingredients then
    for _, ingredient in ipairs(technology.unit.ingredients) do
      if ingredient[1] == old_pack then
        ingredient[1] = new_pack
      end
    end
  end
end

-- Start of the tree. The platform technology keeps its trigger and carries the two platform
-- modifiers rocket-silo and the planet discoveries used to carry; control.lua marks it researched.
technologies["space-platform"].prerequisites = {}
technologies["space-platform"].effects =
{
  {type = "unlock-space-platforms", modifier = true, hidden = true},
  {type = "unlock-travel-to-space-platforms", modifier = true}
}

technologies["space-science-pack"].prerequisites = {"space-flight"}
technologies["space-science-pack"].research_trigger = craft_item("thruster")

-- Everything else these three unlocked is a start recipe.
technologies["steam-power"].effects = unlocks({"heat-pipe"})
technologies["electronics"].effects = {}
technologies["automation"].effects = unlocks({"long-handed-inserter"})

-- Green tier.
technologies["steel-processing"].prerequisites = {"carbonaceous-processing", "logistic-science-pack"}
technologies["steel-processing"].unit = unit(50, 5, {"automation-science-pack", "logistic-science-pack"})

technologies["sulfur-processing"].prerequisites = {"carbonaceous-processing", "logistic-science-pack"}
table.insert(technologies["sulfur-processing"].effects, unlock("chemical-plant"))

technologies["concrete"].prerequisites = {"steel-processing", "automation-2"}
technologies["solar-energy"].prerequisites = {"silicon-processing"}
technologies["advanced-circuit"].prerequisites = {"plastics", "silicon-processing"}

-- Coal, not crude. oil-processing is named "Coal liquefaction" in locale and takes over the
-- cracking and solid fuel recipes that advanced-oil-processing used to hold.
technologies["oil-processing"].prerequisites = {"carbon-baking", "sulfur-processing", "calcite-processing"}
technologies["oil-processing"].research_trigger = craft_item("coal")
technologies["oil-processing"].effects = unlocks(
{
  "oil-refinery",
  "simple-coal-liquefaction",
  "solid-fuel-from-petroleum-gas",
  "heavy-oil-cracking",
  "light-oil-cracking",
  "solid-fuel-from-heavy-oil",
  "solid-fuel-from-light-oil"
})

technologies["calcite-processing"].prerequisites = {"carbonaceous-processing"}
technologies["calcite-processing"].research_trigger = craft_item("calcite")
technologies["calcite-processing"].effects = unlocks({"acid-neutralisation", "steam-condensation"})

technologies["coal-liquefaction"].prerequisites = {"oil-processing", "production-science-pack"}
technologies["coal-liquefaction"].unit = unit(200, 30,
{
  "automation-science-pack",
  "logistic-science-pack",
  "chemical-science-pack",
  "production-science-pack"
})

technologies["lubricant"].prerequisites = {"oil-processing"}

-- Blue tier and nuclear.
technologies["low-density-structure"].prerequisites = {"nickel-processing", "chemical-science-pack"}

technologies["nuclear-power"].prerequisites = {"nickel-processing"}
technologies["nuclear-power"].effects = unlocks({"nuclear-reactor", "heat-exchanger", "steam-turbine"})

technologies["uranium-processing"].prerequisites = {"phosphate-processing"}
technologies["uranium-processing"].research_trigger = craft_item("uranium-ore")
technologies["uranium-processing"].effects = unlocks({"centrifuge", "uranium-processing", "uranium-fuel-cell"})

drop_recipe_effects(technologies["kovarex-enrichment-process"], {"nuclear-fuel"})

technologies["uranium-ammo"].prerequisites = {"uranium-processing", "military-4"}
technologies["uranium-ammo"].effects = unlocks({"uranium-rounds-magazine"})

-- Military: no shotguns.
technologies["military"].effects = unlocks({"submachine-gun"})
drop_recipe_effects(technologies["military-4"], {"combat-shotgun"})

-- Metallurgic chain, re-rooted on M-type refining.
technologies["tungsten-carbide"].prerequisites = {"metallic-refining"}
technologies["tungsten-carbide"].research_trigger = craft_item("tungsten-ore")

technologies["tungsten-steel"].prerequisites = {"foundry"}
technologies["tungsten-steel"].research_trigger = craft_item("foundry")

drop_recipe_effects(technologies["foundry"], {"molten-iron-from-lava", "molten-copper-from-lava"})

-- Cryogenic chain, re-rooted on lithium leaching.
technologies["lithium-processing"].prerequisites = {"lithium-leaching"}
technologies["lithium-processing"].research_trigger = {type = "craft-fluid", fluid = "lithium-brine"}

-- Electromagnetic chain: the recycler's own unit technology comes back, without scrap.
technologies["recycling"].prerequisites = {"production-science-pack", "processing-unit", "concrete"}
technologies["recycling"].unit = unit(5000, 15,
{
  "automation-science-pack",
  "logistic-science-pack",
  "chemical-science-pack",
  "production-science-pack"
})
technologies["recycling"].research_trigger = nil
drop_recipe_effects(technologies["recycling"], {"scrap-recycling"})

technologies["holmium-processing"].prerequisites = {"phosphate-processing"}

-- Volatiles tier.
technologies["carbon-fiber"].prerequisites = {"volatile-processing"}
technologies["carbon-fiber"].unit = unit(500, 60,
{
  "automation-science-pack",
  "logistic-science-pack",
  "chemical-science-pack",
  "space-science-pack"
})

technologies["productivity-module-3"].prerequisites = {"productivity-module-2", "volatiles-science-pack"}

technologies["plastic-bar-productivity"].prerequisites = {"volatiles-science-pack", "production-science-pack"}
drop_recipe_effects(technologies["plastic-bar-productivity"], {"bioplastic"})

technologies["asteroid-productivity"].prerequisites = {"volatiles-science-pack"}
local productivity_effects = {}
for _, recipe in ipairs(
{
  "s-asteroid-crushing", "advanced-s-asteroid-crushing",
  "m-asteroid-crushing", "advanced-m-asteroid-crushing",
  "c-asteroid-crushing", "advanced-c-asteroid-crushing",
  "v-asteroid-crushing", "advanced-v-asteroid-crushing",
  "e-asteroid-crushing", "advanced-e-asteroid-crushing",
  "d-asteroid-crushing", "advanced-d-asteroid-crushing",
  "m-asteroid-refining"
}) do
  table.insert(productivity_effects, {type = "change-recipe-productivity", recipe = recipe, change = 0.1})
end
technologies["asteroid-productivity"].effects = productivity_effects

-- Purple and the end of the tree.
technologies["production-science-pack"].prerequisites = {"productivity-module", "concrete"}
technologies["promethium-science-pack"].prerequisites = {"stellar-discovery-solar-system-edge"}
