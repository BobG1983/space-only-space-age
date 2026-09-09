-- Deletes the four planets and everything that names them or a removed prototype: connections,
-- tips and their emptied categories, achievements, ambient sounds, the main menu simulations and
-- the lightning factoriopedia simulation (DESIGN.md section 12, PLAN.md section 3.5, D-16, D-17).

local dead_planets = {"vulcanus", "gleba", "fulgora", "aquilo"}
local dead_set = {}
for _, name in ipairs(dead_planets) do
  dead_set[name] = true
end

local function remove_named(type_name, names)
  local category = data.raw[type_name]
  if not category then
    return
  end
  for _, name in ipairs(names) do
    category[name] = nil
  end
end

-- Connections first, then the planets they touch. Kept: solar-system-edge-shattered-planet.
remove_named("space-connection",
{
  "nauvis-vulcanus", "nauvis-gleba", "nauvis-fulgora", "vulcanus-gleba",
  "gleba-fulgora", "gleba-aquilo", "fulgora-aquilo", "aquilo-solar-system-edge"
})
remove_named("planet", dead_planets)

-- Tips whose trigger, tag or simulation names a removed prototype, plus the ones that depend
-- on those. z-dropping depends on entity-transfers, so it goes with it.
remove_named("tips-and-tricks-item",
{
  "active-provider-chest", "agriculture", "aquilo-briefing", "asteroid-defense", "buffer-chest",
  "burner-inserter-refueling", "connect-switch", "construction-robots", "copy-paste", "copy-paste-filters",
  "copy-paste-requester-chest", "copy-paste-spidertron", "copy-paste-trains", "electric-network",
  "electric-pole-connections", "elevated-rails", "entity-flip", "entity-transfers", "fast-replace",
  "fast-replace-belt-splitter", "fast-replace-belt-underground", "fulgora-briefing", "gate-over-rail",
  "ghost-building", "ghost-rail-planner", "gleba-briefing", "heating-mechanics", "insertion-limits",
  "lava-processing", "lightning-mechanics", "limit-chests", "logistic-network", "low-power", "orbital-logistics",
  "passive-provider-chest", "personal-logistics", "pump-connection", "rail-building", "rail-signals-advanced",
  "rail-signals-basic", "removing-trash-in-space", "requester-chest", "space-platform", "space-science",
  "spidertron-control", "spoilables", "spoilables-research", "spoilables-result", "stack-transfers", "steam-power",
  "storage-chest", "train-stop-same-name", "train-stops", "trains", "vulcanus-briefing", "z-dropping"
})

-- Guard: a surviving tip that depends on a deleted one goes too, until none is left.
local tips = data.raw["tips-and-tricks-item"] or {}
local function tips_depending_on_missing()
  local found = {}
  for name, tip in pairs(tips) do
    for _, dependency in ipairs(tip.dependencies or {}) do
      if not tips[dependency] then
        table.insert(found, name)
        break
      end
    end
  end
  return found
end
local orphans = tips_depending_on_missing()
while #orphans > 0 do
  for _, name in ipairs(orphans) do
    tips[name] = nil
  end
  orphans = tips_depending_on_missing()
end

-- Categories no surviving tip uses.
local categories_in_use = {}
for _, tip in pairs(tips) do
  categories_in_use[tip.category] = true
end
local tip_categories = data.raw["tips-and-tricks-item-category"] or {}
for _, name in ipairs({"electric-network", "ghost-building", "logistic-network", "space-age", "space-platform", "spoilables", "trains"}) do
  if not categories_in_use[name] then
    tip_categories[name] = nil
  end
end

-- Achievements naming a removed planet, entity, item or science pack. Each achievement type is
-- its own data.raw category, so every type under the achievement base is searched.
local dead_achievements =
{
  "arachnophilia", "getting-on-track", "getting-on-track-like-a-pro",
  "visit-aquilo", "visit-fulgora", "visit-gleba", "visit-vulcanus",
  "logistic-network-embargo", "get-off-my-lawn", "it-stinks-and-they-do-like-it", "it-stinks-and-they-dont-like-it",
  "art-of-siege", "if-it-bleeds", "pest-control", "size-doesnt-matter", "we-need-bigger-guns", "watch-your-step",
  "research-with-agriculture", "todays-fish-is-trout-a-la-creme", "trans-factorio-express"
}
for type_name in pairs(defines.prototypes.achievement) do
  remove_named(type_name, dead_achievements)
end

local rush_to_space = data.raw["dont-research-before-researching-achievement"]
rush_to_space = rush_to_space and rush_to_space["rush-to-space"]
if rush_to_space then
  rush_to_space.research_with = {"metallurgic-science-pack", "electromagnetic-science-pack", "volatiles-science-pack"}
end

-- Ambient sounds bound to a dead planet, by field rather than by name: the shipped game has
-- tracks this checkout only sees as stubs. Nauvis and space tracks stay.
local function names_dead_planet(list)
  for _, planet in ipairs(list or {}) do
    if dead_set[planet] then
      return true
    end
  end
  return false
end
local sounds = data.raw["ambient-sound"] or {}
local dead_sounds = {}
for name, sound in pairs(sounds) do
  if names_dead_planet(sound.planets) or names_dead_planet(sound.exclude_planets) then
    table.insert(dead_sounds, name)
  end
end
for _, name in ipairs(dead_sounds) do
  sounds[name] = nil
end

-- Every main menu simulation runs on a planet or a vanilla platform.
data.raw["utility-constants"].default.main_menu_simulations = {}

-- The lightning entity stays; its factoriopedia simulation ran on Fulgora.
if data.raw.lightning and data.raw.lightning.lightning then
  data.raw.lightning.lightning.factoriopedia_simulation = nil
end
