-- The 24 asteroid entities: small, medium, big and huge of each class s m c v e d, sizes 2..5 of
-- the vanilla asteroid generator on borrowed sprites, explosions and particles, with the class
-- colour on lights[2]. Satisfies DESIGN.md sections 2 and 6.

local graphics = require("__space-only-space-age__.prototypes.asteroid-graphics")

for asteroid_size = 2, 5 do
  local asteroid_size_name = graphics.asteroid_sizes[asteroid_size]
  for _, class in ipairs(graphics.classes) do
    local collision_radius = graphics.collision_radiuses[asteroid_size]
    local selection_radius = collision_radius * 1.1 + 0.1
    local asteroid_name = asteroid_size_name .. "-" .. class.name .. "-asteroid"
    local spread = collision_radius * 0.5
    local dying_trigger_effects =
    {
      {
        type = "create-explosion",
        entity_name = class.sprite .. "-asteroid-explosion-" .. asteroid_size,
        only_when_visible = true
      }
    }

    if asteroid_size == 2 then
      table.insert(dying_trigger_effects,
      {
        type = "create-asteroid-chunk",
        asteroid_name = class.name .. "-asteroid-chunk",
        offset_deviation = {{-spread, -spread}, {spread, spread}},
        offsets =
        {
          {-spread/2, -spread/4},
          {spread/2, -spread/4}
        }
      })
    else
      table.insert(dying_trigger_effects,
      {
        type = "create-entity",
        entity_name = graphics.asteroid_sizes[asteroid_size-1] .. "-" .. class.name .. "-asteroid",
        offset_deviation = {{-spread, -spread}, {spread, spread}},
        offsets =
        {
          {-spread, -spread/4},
          {0, -spread/2},
          {spread, -spread/4}
        }
      })
    end

    local resistances = {}
    for damage_name, damage_type in pairs(data.raw["damage-type"]) do
      if graphics.shared_resistances[damage_name] then
        table.insert(resistances,
        {
          type = damage_name,
          decrease = graphics.shared_resistances[damage_name].decrease[asteroid_size],
          percent = graphics.shared_resistances[damage_name].percent[asteroid_size]
        })
      else
        if damage_name ~= "impact" and damage_name ~= "poison" and damage_name ~= "acid" then
          table.insert(resistances,
          {
            type = damage_name,
            percent = 100
          })
        end
      end
    end

    data:extend
    {
      {
        type = "asteroid",
        name = asteroid_name,
        overkill_fraction = 0.01,
        localised_description = {"entity-description." .. class.name .. "-asteroid"},
        icons = graphics.icons(class, asteroid_size_name .. "-" .. class.sprite .. "-asteroid"),
        selection_box = {{-selection_radius, -selection_radius}, {selection_radius, selection_radius}},
        collision_box = {{-collision_radius, -collision_radius}, {collision_radius, collision_radius}},
        collision_mask = {layers={object=true}, not_colliding_with_itself=true},
        graphics_set = graphics.asteroid_graphics_set(0.0003 * (6 - asteroid_size), graphics.shading(class), graphics.variations(class, asteroid_size)),
        dying_trigger_effect = dying_trigger_effects,

        subgroup = "space-environment",
        order = class.order .. "[" .. class.name .. "]-" .. graphics.letter[asteroid_size] .. "[" .. asteroid_size_name .. "]",

        flags = {"placeable-enemy", "placeable-off-grid", "not-repairable", "not-on-map"},
        max_health = graphics.shared_health[asteroid_size],
        damage_per_hp = graphics.shared_damage_per_hp[asteroid_size],
        resistances = resistances,
      }
    }
  end
end
