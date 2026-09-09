-- The six reprocessing recipes on the ring S, M, E, V, C, D and back to S (DESIGN.md section 4).
-- One shared roll per craft: 40% the same chunk back, 20% each ring neighbour, 20% nothing.
-- Field shapes copy metallic-asteroid-reprocessing in space-age/prototypes/recipe.lua.

-- Ring order. Each class borrows a vanilla reprocessing icon, tinted like its chunk item.
local ring =
{
  {class = "s", sprite = "metallic", tint = {0.85, 0.75, 0.65}},
  {class = "m", sprite = "metallic", tint = {0.85, 0.88, 0.92}},
  {class = "e", sprite = "oxide",    tint = {1, 1, 1}},
  {class = "v", sprite = "oxide",    tint = {0.9, 0.9, 0.9}},
  {class = "c", sprite = "carbonic", tint = nil},
  {class = "d", sprite = "carbonic", tint = {0.75, 0.45, 0.4}}
}

local order_letters = {"a", "b", "c", "d", "e", "f"}

local function chunk(class)
  return class .. "-asteroid-chunk"
end

local function reprocessing_recipe(index)
  local row = ring[index]
  local next_row = ring[index % #ring + 1]
  local previous_row = ring[(index - 2) % #ring + 1]
  local name = row.class .. "-asteroid-reprocessing"
  return
  {
    type = "recipe",
    name = name,
    localised_name = {"recipe-name." .. name},
    localised_description = {"recipe-description." .. name},
    icons = {{icon = "__space-age__/graphics/icons/" .. row.sprite .. "-asteroid-reprocessing.png", tint = row.tint}},
    categories = {"crushing"},
    subgroup = "space-crushing",
    order = "g[reprocessing]-" .. order_letters[index] .. "[" .. row.class .. "]",
    auto_recycle = false,
    enabled = false,
    ingredients = {{type = "item", name = chunk(row.class), amount = 1, ignored_by_stats = 1}},
    energy_required = 2,
    results =
    {
      {type = "item", name = chunk(row.class), amount = 1, shared_probability = {min = 0.0, max = 0.4}, ignored_by_stats = 1},
      {type = "item", name = chunk(next_row.class), amount = 1, shared_probability = {min = 0.4, max = 0.6}},
      {type = "item", name = chunk(previous_row.class), amount = 1, shared_probability = {min = 0.6, max = 0.8}}
    },
    allow_productivity = false,
    allow_quality = false,
    allow_decomposition = false
  }
end

local recipes = {}
for index = 1, #ring do
  table.insert(recipes, reprocessing_recipe(index))
end

data:extend(recipes)
