-- Deletes the technologies of DESIGN.md section 9 "Removed" (names from PLAN.md section 3.4),
-- then scrubs every kept technology of references to anything that is now gone: prerequisites,
-- recipe unlocks and productivity effects, turret-attack effects and research triggers.

local removed =
{
  "planet-discovery-vulcanus", "planet-discovery-fulgora", "planet-discovery-gleba", "planet-discovery-aquilo",
  -- Gleba and biters
  "agricultural-science-pack", "agriculture", "artificial-soil", "bacteria-cultivation", "biochamber", "bioflux",
  "bioflux-processing", "jellynut", "yumako", "overgrowth-soil", "heating-tower", "fish-breeding", "tree-seeding",
  "captivity", "biter-egg-handling", "captive-biter-spawner", "biolab", "spidertron",
  -- Rails and trains
  "railway", "automated-rail-transportation", "elevated-rail", "fluid-wagon", "rail-support-foundations",
  "braking-force-1", "braking-force-2", "braking-force-3", "braking-force-4", "braking-force-5", "braking-force-6",
  "braking-force-7",
  -- Artillery, vehicles, ground weapons
  "artillery", "artillery-shell-range-1", "artillery-shell-speed-1", "artillery-shell-damage-1",
  "automobilism", "tank", "landfill", "cliff-explosives", "land-mine", "flamethrower",
  "refined-flammables-1", "refined-flammables-2", "refined-flammables-3", "refined-flammables-4",
  "refined-flammables-5", "refined-flammables-6", "refined-flammables-7",
  -- Oil wells, furnaces, robots
  "advanced-oil-processing", "oil-gathering", "advanced-material-processing", "advanced-material-processing-2",
  "construction-robotics", "logistic-robotics", "logistic-system",
  "personal-roboport-equipment", "personal-roboport-mk2-equipment",
  "worker-robots-speed-1", "worker-robots-speed-2", "worker-robots-speed-3", "worker-robots-speed-4",
  "worker-robots-speed-5", "worker-robots-speed-6", "worker-robots-speed-7",
  "worker-robots-storage-1", "worker-robots-storage-2", "worker-robots-storage-3",
  -- Rockets, mining, and the vanilla asteroid tier
  "rocket-silo", "rocket-fuel", "big-mining-drill", "electric-mining-drill",
  "mining-productivity-1", "mining-productivity-2", "mining-productivity-3",
  "lightning-collector", "uranium-mining", "gun-turret", "landing-pad-unloading-bay",
  "advanced-asteroid-processing", "space-platform-thruster",
  "rocket-part-productivity", "scrap-recycling-productivity", "rocket-fuel-productivity"
}

local technologies = data.raw.technology
for _, name in ipairs(removed) do
  technologies[name] = nil
end

-- Scrub pass. Existence is read from data.raw as it stands now, after every removal file
-- before this one has run, so it also covers anything another file deleted.
local function exists_in(base, name)
  for type_name in pairs(defines.prototypes[base]) do
    local category = data.raw[type_name]
    if category and category[name] then
      return true
    end
  end
  return false
end

local function entity_exists(name)
  return exists_in("entity", name)
end

local function item_exists(name)
  return exists_in("item", name)
end

local function recipe_exists(name)
  return data.raw.recipe[name] ~= nil
end

local function fluid_exists(name)
  return data.raw.fluid ~= nil and data.raw.fluid[name] ~= nil
end

local function keep_prerequisites(technology)
  if not technology.prerequisites then
    return
  end
  local kept = {}
  for _, prerequisite in ipairs(technology.prerequisites) do
    if technologies[prerequisite] then
      table.insert(kept, prerequisite)
    end
  end
  technology.prerequisites = kept
end

local function effect_is_valid(effect)
  if effect.type == "unlock-recipe" or effect.type == "change-recipe-productivity" then
    return recipe_exists(effect.recipe)
  end
  if effect.type == "turret-attack" then
    return entity_exists(effect.turret_id)
  end
  return true
end

local function keep_effects(technology)
  if not technology.effects then
    return
  end
  local kept = {}
  for _, effect in ipairs(technology.effects) do
    if effect_is_valid(effect) then
      table.insert(kept, effect)
    end
  end
  technology.effects = kept
end

-- A trigger naming one removed thing is dropped. A mine-entity list loses only its removed
-- entries and is dropped when none are left.
local function trigger_is_valid(trigger)
  if trigger.type == "craft-item" then
    return item_exists(trigger.item)
  end
  if trigger.type == "craft-fluid" then
    return fluid_exists(trigger.fluid)
  end
  if trigger.type == "build-entity" then
    return entity_exists(trigger.entity)
  end
  if trigger.type == "mine-entity" then
    local kept = {}
    for _, entity in ipairs(trigger.entities or {}) do
      if entity_exists(entity) then
        table.insert(kept, entity)
      end
    end
    trigger.entities = kept
    return #kept > 0
  end
  return true
end

local function keep_trigger(name, technology)
  local trigger = technology.research_trigger
  if trigger and not trigger_is_valid(trigger) then
    technology.research_trigger = nil
    log("space-only-space-age: dropped the research trigger of technology " .. name .. ", it named a removed prototype")
  end
end

for name, technology in pairs(technologies) do
  keep_prerequisites(technology)
  keep_effects(technology)
  keep_trigger(name, technology)
end
