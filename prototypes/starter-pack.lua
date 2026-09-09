-- Rewrites the space-platform-starter-pack kit: a 20x20 foundation pad, the section 13 item
-- list, and a live electric network. Satisfies DESIGN.md section 13. The pack's surface and
-- hub trigger are left as vanilla wrote them.

-- Copy of the file-local helper in space-age/prototypes/item.lua.
local make_tile_area = function(area, name)
  local result = {}
  local left_top = area[1]
  local right_bottom = area[2]
  for x = left_top[1], right_bottom[1] do
    for y = left_top[2], right_bottom[2] do
      table.insert(result,
      {
        position = {x, y},
        tile = name
      })
    end
  end
  return result
end

local pack = data.raw["space-platform-starter-pack"]["space-platform-starter-pack"]

pack.tiles = make_tile_area({{-10, -10}, {9, 9}}, "space-platform-foundation")

-- Quality tiles cannot be placed, so the foundation row is pinned to normal quality.
pack.initial_items =
{
  {type = "item", name = "space-platform-foundation", amount = 200, quality_min = "normal", quality_max = "normal"},
  {type = "item", name = "asteroid-collector", amount = 4},
  {type = "item", name = "crusher", amount = 4},
  {type = "item", name = "electric-furnace", amount = 2},
  {type = "item", name = "assembling-machine-1", amount = 2},
  {type = "item", name = "lab", amount = 1},
  {type = "item", name = "heating-panel", amount = 6},
  {type = "item", name = "heat-boiler", amount = 3},
  {type = "item", name = "melter", amount = 2},
  {type = "item", name = "steam-engine", amount = 3},
  {type = "item", name = "heat-pipe", amount = 10},
  {type = "item", name = "pipe", amount = 30},
  {type = "item", name = "pipe-to-ground", amount = 6},
  {type = "item", name = "storage-tank", amount = 1},
  {type = "item", name = "inserter", amount = 20},
  {type = "item", name = "transport-belt", amount = 100},
  {type = "item", name = "small-electric-pole", amount = 20},
  {type = "item", name = "iron-chest", amount = 4},
  {type = "item", name = "gun-turret", amount = 4},
  {type = "item", name = "firearm-magazine", amount = 200},
  {type = "item", name = "ice", amount = 100},
  {type = "item", name = "iron-plate", amount = 200},
  {type = "item", name = "copper-plate", amount = 100},
  {type = "item", name = "stone", amount = 100},
  {type = "item", name = "iron-gear-wheel", amount = 50},
  {type = "item", name = "electronic-circuit", amount = 20}
}

pack.create_electric_network = true
