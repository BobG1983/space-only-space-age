-- Deletes the items, entities and shortcuts that have no place on a platform-only map
-- (DESIGN.md section 8; names from PLAN.md sections 3.2 and 3.3, shortcuts per D-67).
-- A prototype type is dropped whole only where every member goes; otherwise names are listed.

local function remove_named(type_name, names)
  local category = data.raw[type_name]
  if not category then
    return
  end
  for _, name in ipairs(names) do
    category[name] = nil
  end
end

local function remove_types(type_names)
  for _, type_name in ipairs(type_names) do
    data.raw[type_name] = nil
  end
end

-- Items (PLAN.md section 3.2). Kept on purpose: rocket-fuel, landfill, solid-fuel, carbon,
-- sulfur, coal, calcite, ice, holmium-ore, tungsten-ore, uranium-ore, space-platform-starter-pack.
remove_named("item",
{
  "metallic-asteroid-chunk", "carbonic-asteroid-chunk", "oxide-asteroid-chunk",
  "agricultural-science-pack", "agricultural-tower", "artificial-jellynut-soil", "artificial-yumako-soil",
  "overgrowth-jellynut-soil", "overgrowth-yumako-soil", "biochamber", "biolab", "captive-biter-spawner",
  "copper-bacteria", "iron-bacteria", "jellynut-seed", "yumako-seed", "nutrients", "spoilage", "pentapod-egg",
  "biter-egg", "tree-seed", "wood", "wooden-chest", "scrap",
  "boiler", "stone-furnace", "steel-furnace", "burner-mining-drill", "burner-inserter", "electric-mining-drill",
  "big-mining-drill", "pumpjack", "offshore-pump", "rail-signal", "rail-chain-signal", "train-stop", "rail-support",
  "artillery-turret", "rocket-silo", "cargo-landing-pad", "landing-pad-unloading-bay", "rocket-part", "nuclear-fuel",
  "land-mine", "flamethrower-turret", "lightning-rod", "lightning-collector", "roboport", "construction-robot",
  "logistic-robot", "active-provider-chest", "passive-provider-chest", "storage-chest", "buffer-chest",
  "requester-chest", "heating-tower", "personal-roboport-equipment", "personal-roboport-mk2-equipment",
  "infinity-cargo-wagon"
})
remove_named("capsule", {"bioflux", "jelly", "jellynut", "yumako", "yumako-mash", "raw-fish", "cliff-explosives", "artillery-targeting-remote"})
remove_named("ammo",
{
  "capture-robot-rocket", "flamethrower-ammo", "shotgun-shell", "piercing-shotgun-shell",
  "cannon-shell", "explosive-cannon-shell", "uranium-cannon-shell", "explosive-uranium-cannon-shell", "artillery-shell"
})
remove_named("gun",
{
  "shotgun", "combat-shotgun", "flamethrower",
  "tank-cannon", "tank-flamethrower", "tank-machine-gun", "vehicle-machine-gun", "artillery-wagon-cannon",
  "spidertron-rocket-launcher-1", "spidertron-rocket-launcher-2", "spidertron-rocket-launcher-3", "spidertron-rocket-launcher-4"
})
remove_named("item-with-entity-data", {"spidertron", "car", "tank", "locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon"})
remove_named("spidertron-remote", {"spidertron-remote"})
remove_named("rail-planner", {"rail", "rail-ramp"})

-- Entities removed as whole types (PLAN.md section 3.3). Corpses, explosions, particles, smoke,
-- projectiles, decoratives, tiles, lightning, the crash site and the character all stay.
remove_types(
{
  -- Enemies and their parts
  "unit", "unit-spawner", "turret", "segmented-unit", "segment", "capture-robot",
  -- Nature and ground resources
  "tree", "plant", "fish", "cliff", "resource", "lightning-attractor",
  -- Rails and trains, including the dummy twins that share these types
  "straight-rail", "curved-rail-a", "curved-rail-b", "half-diagonal-rail", "legacy-straight-rail", "legacy-curved-rail",
  "elevated-straight-rail", "elevated-curved-rail-a", "elevated-curved-rail-b", "elevated-half-diagonal-rail",
  "rail-ramp", "rail-support", "rail-signal", "rail-chain-signal", "train-stop",
  "locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon", "infinity-cargo-wagon", "rail-remnants",
  "car", "spider-vehicle",
  -- Burners, rockets and robot logistics
  "mining-drill", "offshore-pump", "rocket-silo", "cargo-landing-pad", "land-mine", "artillery-turret", "fluid-turret",
  "roboport", "construction-robot", "logistic-robot", "logistic-container", "agricultural-tower", "roboport-equipment"
})

-- Entities removed by name because the rest of their type stays. The strafer projectiles
-- go too: only the removed strafer pentapods fire them, and they spawn removed units on hit.
remove_named("projectile", {"capture-robot-rocket", "small-strafer-projectile", "medium-strafer-projectile", "big-strafer-projectile"})
remove_named("spider-unit",
{
  "small-strafer-pentapod", "medium-strafer-pentapod", "big-strafer-pentapod",
  "small-stomper-pentapod", "medium-stomper-pentapod", "big-stomper-pentapod"
})
-- spidertron-leg-1 stays: base's hidden dummy-spider-unit mounts it, and that unit is kept.
remove_named("spider-leg",
{
  "small-strafer-pentapod-leg", "medium-strafer-pentapod-leg", "big-strafer-pentapod-leg",
  "small-stomper-pentapod-leg", "medium-stomper-pentapod-leg", "big-stomper-pentapod-leg",
  "spidertron-leg-2", "spidertron-leg-3", "spidertron-leg-4", "spidertron-leg-5",
  "spidertron-leg-6", "spidertron-leg-7", "spidertron-leg-8"
})
-- parameter-0..9 and wube-logo-space-platform stay.
remove_named("simple-entity",
{
  "big-demolisher-corpse", "medium-demolisher-corpse", "small-demolisher-corpse",
  "big-fulgora-rock", "big-rock", "big-sand-rock", "big-stomper-shell", "medium-stomper-shell", "small-stomper-shell",
  "big-volcanic-rock", "big-volcanic-rock-hot", "huge-rock", "huge-volcanic-rock", "huge-volcanic-rock-hot",
  "copper-stromatolite", "iron-stromatolite",
  "fulgora-sunk-ruin-big", "fulgora-sunk-ruin-medium-tall", "fulgoran-ruin-big", "fulgoran-ruin-colossal",
  "fulgoran-ruin-huge", "fulgoran-ruin-medium", "fulgoran-ruin-small", "fulgoran-ruin-stonehenge", "fulgoran-ruin-vault",
  "fulgurite", "fulgurite-small", "lithium-iceberg-big", "lithium-iceberg-huge",
  "vulcanus-chimney", "vulcanus-chimney-cold", "vulcanus-chimney-faded", "vulcanus-chimney-short", "vulcanus-chimney-truncated"
})
remove_named("boiler", {"boiler"})
remove_named("furnace", {"stone-furnace", "steel-furnace"})
remove_named("inserter", {"burner-inserter"})
remove_named("reactor", {"heating-tower"})
remove_named("assembling-machine", {"biochamber", "captive-biter-spawner"})
remove_named("lab", {"biolab"})
remove_named("container", {"wooden-chest"})
remove_named("cargo-bay", {"landing-pad-unloading-bay"})

-- The three vanilla asteroid classes. The promethium asteroids, asteroid-chunk-unknown and the
-- parameter chunks stay.
local vanilla_asteroids = {}
for _, class in ipairs({"metallic", "carbonic", "oxide"}) do
  for _, size in ipairs({"small", "medium", "big", "huge"}) do
    table.insert(vanilla_asteroids, size .. "-" .. class .. "-asteroid")
  end
end
remove_named("asteroid", vanilla_asteroids)
remove_named("asteroid-chunk", {"metallic-asteroid-chunk", "carbonic-asteroid-chunk", "oxide-asteroid-chunk"})

-- Loose ends the removals above leave behind.

-- The four Gleba soil tiles stay as tiles, but the items they were mined into are gone.
local tiles = data.raw.tile or {}
for _, name in ipairs({"artificial-yumako-soil", "artificial-jellynut-soil", "overgrowth-yumako-soil", "overgrowth-jellynut-soil"}) do
  if tiles[name] then
    tiles[name].minable = nil
  end
end

-- The biochamber was the only crafter of the "organic" category. Recipes that listed it next
-- to another category drop it; a recipe with no other category is left for its own rewrite.
for _, recipe in pairs(data.raw.recipe) do
  local categories = recipe.categories
  if categories and #categories > 1 then
    local kept = {}
    for _, category in ipairs(categories) do
      if category ~= "organic" then
        table.insert(kept, category)
      end
    end
    recipe.categories = kept
  end
end

-- Autoplace controls stay (D-15), but their names open with an icon tag of the resource entity
-- that is now gone. Drop that element and keep the plain name.
local function entity_exists(name)
  for type_name in pairs(defines.prototypes.entity) do
    local category = data.raw[type_name]
    if category and category[name] then
      return true
    end
  end
  return false
end
for _, control in pairs(data.raw["autoplace-control"] or {}) do
  local localised_name = control.localised_name
  if type(localised_name) == "table" then
    local kept = {}
    for _, part in ipairs(localised_name) do
      local tagged = type(part) == "string" and part:match("^%[entity=([^%]]+)%]%s*$")
      if not (tagged and not entity_exists(tagged)) then
        table.insert(kept, part)
      end
    end
    control.localised_name = kept
  end
end

-- Shortcuts (D-67). Four give or toggle something that is gone. The rest unlocked with
-- construction-robotics, which is gone, so blueprints and undo are available from the start.
remove_named("shortcut", {"give-artillery-targeting-remote", "give-spidertron-remote", "toggle-personal-roboport", "toggle-tall-entity-visibility"})
local shortcuts = data.raw.shortcut or {}
for _, name in ipairs({"copy", "cut", "paste", "undo", "redo", "give-blueprint", "give-blueprint-book", "give-deconstruction-planner", "give-upgrade-planner", "import-string"}) do
  if shortcuts[name] then
    shortcuts[name].technology_to_unlock = nil
  end
end
