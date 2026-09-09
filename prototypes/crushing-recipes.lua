-- The twelve crushing recipes (basic and advanced for S, M, C, V, E, D) and m-asteroid-refining,
-- built by one helper from the DESIGN.md section 4 tables. Field shapes copy
-- metallic-asteroid-crushing in space-age/prototypes/recipe.lua.

-- One row per class: which vanilla crushing icon it borrows and how that icon is tinted.
-- Order letters a..f match the chunk items.
local classes =
{
  {class = "s", order = "a", sprite = "metallic", tint = {0.85, 0.75, 0.65}},
  {class = "m", order = "b", sprite = "metallic", tint = {0.85, 0.88, 0.92}},
  {class = "c", order = "c", sprite = "carbonic", tint = nil},
  {class = "v", order = "d", sprite = "oxide",    tint = {0.9, 0.9, 0.9}},
  {class = "e", order = "e", sprite = "oxide",    tint = {1, 1, 1}},
  {class = "d", order = "f", sprite = "carbonic", tint = {0.75, 0.45, 0.4}}
}

-- Basic crushing takes 2 s and returns the chunk 30% of the time, advanced 5 s and 10%,
-- refining 8 s and 5%. Refining has no icon of its own and borrows the advanced one.
local tiers =
{
  basic    = {prefix = "",          suffix = "crushing", icon_prefix = "",          energy = 2, chunk = 0.3,  order = "a"},
  advanced = {prefix = "advanced-", suffix = "crushing", icon_prefix = "advanced-", energy = 5, chunk = 0.1,  order = "b"},
  refining = {prefix = "",          suffix = "refining", icon_prefix = "advanced-", energy = 8, chunk = 0.05, order = "c"}
}

-- Product rows: {name, amount} for a fixed amount, {name, amount, p = chance} for a chance,
-- {name, min = a, max = b, p = chance} for a range. The chunk return is added by the helper.
local yields =
{
  s =
  {
    basic    = {{"iron-ore", 16}, {"stone", 8}, {"copper-ore", min = 2, max = 4, p = 0.5}, {"sulfur", 1, p = 0.1}},
    advanced = {{"iron-ore", 12}, {"copper-ore", 6}, {"stone", 3}, {"sulfur", 2, p = 0.5}, {"phosphate-rock", 1, p = 0.05}}
  },
  m =
  {
    basic    = {{"iron-ore", 24}, {"nickel-ore", 2, p = 0.3}, {"copper-ore", 1, p = 0.2}},
    advanced = {{"iron-ore", 16}, {"nickel-ore", 6}, {"tungsten-ore", 2, p = 0.4}, {"copper-ore", 2, p = 0.3}},
    refining = {{"iron-ore", 8}, {"nickel-ore", 8}, {"tungsten-ore", 4}}
  },
  c =
  {
    basic    = {{"ice", 5}, {"carbon", 8}, {"stone", 2}},
    advanced = {{"ice", 3}, {"carbon", 5}, {"calcite", 2}, {"sulfur", 2}, {"hydrated-silicate", 1, p = 0.5}}
  },
  v =
  {
    basic    = {{"stone", 16}, {"iron-ore", 4}, {"phosphate-rock", 1, p = 0.3}},
    advanced = {{"stone", 8}, {"phosphate-rock", 3}, {"calcite", 2}, {"iron-ore", 2}, {"copper-ore", 1, p = 0.2}}
  },
  e =
  {
    basic    = {{"stone", 12}, {"sulfur", 6}, {"iron-ore", 2}},
    advanced = {{"silicon", 6}, {"sulfur", 6}, {"stone", 4}, {"iron-ore", 4}}
  },
  d =
  {
    basic    = {{"ice", 10}, {"carbon", 4}},
    advanced = {{"ice", 6}, {"carbon", 3}, {"volatile-ice", 2}}
  }
}

-- Only these two are available before any research (DESIGN.md section 9).
local start_enabled =
{
  ["s-asteroid-crushing"] = true,
  ["c-asteroid-crushing"] = true
}

local function product(row)
  local result = {type = "item", name = row[1]}
  if row.min then
    result.amount_min = row.min
    result.amount_max = row.max
  else
    result.amount = row[2]
  end
  if row.p then
    result.independent_probability = row.p
  end
  return result
end

local function crushing_recipe(row, tier, rows)
  local name = tier.prefix .. row.class .. "-asteroid-" .. tier.suffix
  local chunk = row.class .. "-asteroid-chunk"
  local results = {}
  for _, product_row in ipairs(rows) do
    table.insert(results, product(product_row))
  end
  table.insert(results, {type = "item", name = chunk, amount = 1, independent_probability = tier.chunk, ignored_by_stats = 1})
  return
  {
    type = "recipe",
    name = name,
    localised_name = {"recipe-name." .. name},
    localised_description = {"recipe-description." .. name},
    icons = {{icon = "__space-age__/graphics/icons/" .. tier.icon_prefix .. row.sprite .. "-asteroid-crushing.png", tint = row.tint}},
    categories = {"crushing"},
    subgroup = "space-crushing",
    order = row.order .. "[" .. row.class .. "]-" .. tier.order,
    auto_recycle = false,
    enabled = start_enabled[name] == true,
    ingredients = {{type = "item", name = chunk, amount = 1, ignored_by_stats = 1}},
    energy_required = tier.energy,
    results = results,
    main_product = results[1].name,
    allow_productivity = true,
    allow_decomposition = false
  }
end

local recipes = {}
for _, row in ipairs(classes) do
  for _, tier_name in ipairs({"basic", "advanced", "refining"}) do
    local rows = yields[row.class][tier_name]
    if rows then
      table.insert(recipes, crushing_recipe(row, tiers[tier_name], rows))
    end
  end
end

data:extend(recipes)
