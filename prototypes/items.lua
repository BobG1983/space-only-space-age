-- Every new item (DESIGN.md sections 3 and 6): the six asteroid chunks, the new ores and
-- intermediates, the volatiles science pack and the four machine items. Ends by putting the
-- volatiles pack into the lab's inputs in place of the agricultural pack.
local item_sounds = require("__base__.prototypes.item_sounds")
local space_age_item_sounds = require("__space-age__.prototypes.item_sounds")
local item_tints = require("__base__.prototypes.item-tints")

-- One row per class: which vanilla chunk icon it borrows, how that icon is tinted, and the
-- inventory tint. Order letters a..f match the crushing recipes.
local chunk_classes =
{
  {class = "s", order = "a", sprite = "metallic", icon_tint = {0.85, 0.75, 0.65}, tint = {0.85, 0.75, 0.65, 1}},
  {class = "m", order = "b", sprite = "metallic", icon_tint = {0.85, 0.88, 0.92}, tint = {0.85, 0.88, 0.92, 1}},
  {class = "c", order = "c", sprite = "carbonic", icon_tint = nil,                tint = item_tints.yellowing_coal},
  {class = "v", order = "d", sprite = "oxide",    icon_tint = {0.9, 0.9, 0.9},    tint = {0.9, 0.9, 0.9, 1}},
  {class = "e", order = "e", sprite = "oxide",    icon_tint = {1, 1, 1},          tint = {1, 1, 1, 1}},
  {class = "d", order = "f", sprite = "carbonic", icon_tint = {0.75, 0.45, 0.4},  tint = {0.7, 0.4, 0.35, 1}}
}

local function chunk_item(row)
  return
  {
    type = "item",
    name = row.class .. "-asteroid-chunk",
    icons = {{icon = "__space-age__/graphics/icons/" .. row.sprite .. "-asteroid-chunk.png", tint = row.icon_tint}},
    subgroup = "space-material",
    order = row.order .. "[" .. row.class .. "-type]-e[chunk]",
    inventory_move_sound = space_age_item_sounds.rock_inventory_move,
    pick_sound = space_age_item_sounds.rock_inventory_pickup,
    drop_sound = space_age_item_sounds.rock_inventory_move,
    stack_size = 1,
    weight = 100 * kg,
    random_tint_color = row.tint
  }
end

local items = {}
for _, row in ipairs(chunk_classes) do
  table.insert(items, chunk_item(row))
end

-- Ores and rocks: shape of iron-ore in base/prototypes/item.lua.
local function raw_resource(name, order, icon, icon_tint, weight)
  return
  {
    type = "item",
    name = name,
    icons = {{icon = icon, tint = icon_tint}},
    subgroup = "raw-resource",
    order = order,
    inventory_move_sound = item_sounds.resource_inventory_move,
    pick_sound = item_sounds.resource_inventory_pickup,
    drop_sound = item_sounds.resource_inventory_move,
    stack_size = 50,
    weight = weight
  }
end

-- Plates and the like: shape of iron-plate in base/prototypes/item.lua.
local function raw_material(name, order, icon, icon_tint)
  return
  {
    type = "item",
    name = name,
    icons = {{icon = icon, tint = icon_tint}},
    subgroup = "raw-material",
    order = order,
    inventory_move_sound = item_sounds.metal_small_inventory_move,
    pick_sound = item_sounds.metal_small_inventory_pickup,
    drop_sound = item_sounds.metal_small_inventory_move,
    stack_size = 100,
    weight = 1 * kg
  }
end

table.insert(items, raw_resource("nickel-ore", "k[nickel-ore]",
  "__base__/graphics/icons/iron-ore.png", {0.8, 0.88, 0.8}, 2 * kg))
table.insert(items, raw_material("nickel-plate", "a[smelting]-d[nickel-plate]",
  "__base__/graphics/icons/iron-plate.png", {0.85, 0.92, 0.85}))
table.insert(items, raw_material("silicon", "a[smelting]-e[silicon]",
  "__space-age__/graphics/icons/tungsten-plate.png", {0.6, 0.65, 0.75}))
table.insert(items, raw_resource("phosphate-rock", "l[phosphate-rock]",
  "__base__/graphics/icons/stone.png", {0.85, 0.8, 0.6}, 2 * kg))
table.insert(items, raw_resource("hydrated-silicate", "m[hydrated-silicate]",
  "__space-age__/graphics/icons/calcite.png", {0.7, 0.85, 0.75}, 2 * kg))

-- Volatile ice keeps the ice sounds of its parent.
local volatile_ice = raw_resource("volatile-ice", "n[volatile-ice]",
  "__space-age__/graphics/icons/ice.png", {0.8, 0.85, 1}, 1 * kg)
volatile_ice.inventory_move_sound = space_age_item_sounds.ice_inventory_move
volatile_ice.pick_sound = space_age_item_sounds.ice_inventory_pickup
volatile_ice.drop_sound = space_age_item_sounds.ice_inventory_move
table.insert(items, volatile_ice)

-- Science packs are plain items in 2.1: shape of automation-science-pack in base/prototypes/item.lua.
table.insert(items,
{
  type = "item",
  name = "volatiles-science-pack",
  icons = {{icon = "__space-age__/graphics/icons/agricultural-science-pack.png", tint = {0.75, 0.85, 1}}},
  subgroup = "science-pack",
  color_hint = { text = "V" },
  order = "i[volatiles-science-pack]",
  inventory_move_sound = item_sounds.science_inventory_move,
  pick_sound = item_sounds.science_inventory_pickup,
  drop_sound = item_sounds.science_inventory_move,
  stack_size = 200,
  weight = 1 * kg,
  random_tint_color = item_tints.bluish_science
})

-- Machine items. Icons borrow the vanilla machine each entity is derived from, tinted.
table.insert(items,
{
  type = "item",
  name = "heating-panel",
  icons = {{icon = "__base__/graphics/icons/solar-panel.png", tint = {1, 0.85, 0.6}}},
  subgroup = "energy",
  order = "b[steam-power]-a[heating-panel]",
  inventory_move_sound = item_sounds.electric_large_inventory_move,
  pick_sound = item_sounds.electric_large_inventory_pickup,
  drop_sound = item_sounds.electric_large_inventory_move,
  place_result = "heating-panel",
  stack_size = 50
})

table.insert(items,
{
  type = "item",
  name = "heat-boiler",
  icons = {{icon = "__base__/graphics/icons/heat-boiler.png", tint = {1, 0.8, 0.6}}},
  subgroup = "energy",
  order = "b[steam-power]-b[heat-boiler]",
  inventory_move_sound = item_sounds.steam_inventory_move,
  pick_sound = item_sounds.steam_inventory_pickup,
  drop_sound = item_sounds.steam_inventory_move,
  place_result = "heat-boiler",
  stack_size = 50,
  random_tint_color = item_tints.iron_rust
})

table.insert(items,
{
  type = "item",
  name = "melter",
  icons = {{icon = "__base__/graphics/icons/chemical-plant.png", tint = {0.7, 0.9, 1}}},
  subgroup = "production-machine",
  order = "e[melter]",
  inventory_move_sound = item_sounds.fluid_inventory_move,
  pick_sound = item_sounds.fluid_inventory_pickup,
  drop_sound = item_sounds.fluid_inventory_move,
  place_result = "melter",
  stack_size = 10
})

table.insert(items,
{
  type = "item",
  name = "quantum-research-center",
  icons = {{icon = "__space-age__/graphics/icons/biolab.png", tint = {0.7, 0.8, 1}}},
  subgroup = "production-machine",
  order = "z[z-quantum-research-center]",
  inventory_move_sound = item_sounds.mechanical_inventory_move,
  pick_sound = item_sounds.mechanical_inventory_pickup,
  drop_sound = item_sounds.mechanical_inventory_move,
  place_result = "quantum-research-center",
  stack_size = 5
})

data:extend(items)

-- The lab lists accepted packs by name. The agricultural pack goes, the volatiles pack comes in
-- last so the list order matches the research GUI.
local lab_inputs = data.raw.lab.lab.inputs
for i = #lab_inputs, 1, -1 do
  if lab_inputs[i] == "agricultural-science-pack" then
    table.remove(lab_inputs, i)
  end
end
table.insert(lab_inputs, "volatiles-science-pack")
