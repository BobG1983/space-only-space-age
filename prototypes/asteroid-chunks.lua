-- The six asteroid-chunk prototypes s m c v e d, size index 1 of the vanilla asteroid generator,
-- on borrowed sprites with the class colour on lights[2]. Satisfies DESIGN.md section 2.

local graphics = require("__space-only-space-age__.prototypes.asteroid-graphics")

local asteroid_size = 1
local asteroid_size_name = graphics.asteroid_sizes[asteroid_size]

for _, class in ipairs(graphics.classes) do
  local asteroid_name = class.name .. "-asteroid-chunk"
  local dying_trigger_effects =
  {
    {
      type = "create-entity",
      entity_name = class.sprite .. "-asteroid-explosion-" .. asteroid_size,
      only_when_visible = true
    }
  }

  data:extend
  {
    {
      type = "asteroid-chunk",
      name = asteroid_name,
      localised_name = {"entity-name." .. asteroid_name},
      localised_description = {"entity-description." .. class.name .. "-asteroid"},
      icons = graphics.icons(class, class.sprite .. "-asteroid-chunk"),
      graphics_set = graphics.asteroid_graphics_set(0.0003 * (6 - asteroid_size), graphics.shading(class), graphics.variations(class, asteroid_size)),
      dying_trigger_effect = dying_trigger_effects,

      subgroup = "space-material",
      order = class.order .. "[" .. class.name .. "]-" .. graphics.letter[asteroid_size] .. "[" .. asteroid_size_name .. "]",

      minable = {mining_time = 0.2, result = asteroid_name, mining_particle = class.sprite .. "-asteroid-chunk-particle-medium"},
    }
  }
end

-- chunk backlight overrides, the vanilla pattern with the class colour
for _, class in ipairs(graphics.classes) do
  local direction = graphics.chunk_backlight_direction[class.sprite]
  if direction then
    data.raw["asteroid-chunk"][class.name .. "-asteroid-chunk"].graphics_set.lights[2] = { color = table.deepcopy(class.color), direction = table.deepcopy(direction) }
  end
end
