-- Runs after every mod's data.lua, including the barrel generator in base/data-updates.lua
-- and the recycler's recipe generator. Clears dead-planet import locations (DESIGN.md
-- section 11) and drops any recycling recipe left pointing at something that no longer exists.

-- 1. Import locations name the four removed planets, including the fluoroketone-cold barrel
--    that base/data-updates.lua generates after our data.lua ran.
for _, category in pairs(data.raw) do
  for _, prototype in pairs(category) do
    if type(prototype) == "table" and prototype.default_import_location then
      prototype.default_import_location = nil
    end
  end
end

-- 2. Safety net. Removals happen in data.lua so the recycler never sees a removed item, and
--    this loop should find nothing. It exists so a stale recycling recipe cannot fail the load.
local function item_exists(name)
  for type_name in pairs(defines.prototypes.item) do
    local items = data.raw[type_name]
    if items and items[name] then
      return true
    end
  end
  return false
end

local function fluid_exists(name)
  return data.raw.fluid ~= nil and data.raw.fluid[name] ~= nil
end

local function entry_exists(entry)
  if entry.type == "fluid" then
    return fluid_exists(entry.name)
  end
  return item_exists(entry.name)
end

local function every_entry_exists(list)
  for _, entry in ipairs(list or {}) do
    if not entry_exists(entry) then
      return false
    end
  end
  return true
end

local suffix = "-recycling"
local doomed = {}
for name, recipe in pairs(data.raw.recipe) do
  local is_recycling = #name > #suffix and name:sub(-#suffix) == suffix
  if is_recycling and not (every_entry_exists(recipe.ingredients) and every_entry_exists(recipe.results)) then
    table.insert(doomed, name)
  end
end

local doomed_set = {}
for _, name in ipairs(doomed) do
  data.raw.recipe[name] = nil
  doomed_set[name] = true
end

-- The recycler unlocks every generated recipe from technology.recycling; an unlock naming a
-- deleted recipe would dangle, so it goes with the recipe.
local recycling_technology = data.raw.technology and data.raw.technology.recycling
if #doomed > 0 and recycling_technology and recycling_technology.effects then
  local kept = {}
  for _, effect in ipairs(recycling_technology.effects) do
    if not (effect.type == "unlock-recipe" and doomed_set[effect.recipe]) then
      table.insert(kept, effect)
    end
  end
  recycling_technology.effects = kept
end
