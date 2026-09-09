-- Shared data for the six asteroid classes: size tables, vanilla shading data, sprite variation
-- lists, the two graphics helpers copied from space-age's asteroid.lua, and the class table.
-- Defines no prototype. Satisfies DESIGN.md sections 2 and 6.

local graphics = {}

graphics.asteroid_sizes = {"chunk", "small", "medium", "big", "huge"}
graphics.letter = {"a", "b", "c", "d", "e"}

graphics.shared_resistances =
{
  physical =
  {
    decrease = {0, 0, 0, 2000, 3000},
    percent = {0, 0, 10, 10, 10}
  },
  explosion =
  {
    decrease = {0, 0, 0, 0, 0},
    percent = {0, 50, 30, 10, 99}
  },
  laser =
  {
    decrease = {0, 0, 0, 0, 0},
    percent = {0, 20, 90, 95, 99}
  }
}
graphics.shared_health = {0, 100, 400, 2000, 5000}
graphics.shared_damage_per_hp = {0, 5, 8, 12, 15}

graphics.collision_radiuses = {0.4, 0.5, 1, 2, 4.5}
graphics.graphics_scale = {0.5, 0.5, 0.5, 0.6, 0.75}
graphics.sizes_resolution = {{50, 1}, {128, 1}, {230, 0}, {304, 6}, {512, 0}}

-- Vanilla shading data per sprite source. lights[2] is the light each class recolours.
graphics.shading_data =
{
  metallic =
  {
    normal_strength = 1.2,
    light_width = 0,
    brightness = 0.9,
    specular_strength = 2,
    specular_power = 2,
    specular_purity = 0,
    sss_contrast = 1,
    sss_amount = 0,
    lights = {
      { color = {0.96,1,0.99}, direction = {0.7,0.6,-1} },
      { color = {0.57,0.33,0.23}, direction = {-0.72,-0.46,1} },
      { color = {0.1,0.1,0.1}, direction = {-0.4,-0.25,-0.5} },
    },
    ambient_light = {0.01, 0.01, 0.01},
  },
  carbonic =
  {
    normal_strength = 1,
    light_width = 0,
    brightness = 0.9,
    specular_strength = 2.5,
    specular_power = 0.8,
    specular_purity = 0,
    sss_contrast = 1,
    sss_amount = 0,
    lights = {
      { color = {1,1,1}, direction = {0.7,0.6,-1} },
      { color = {0.16,0.14,0.22}, direction = {-1,-1, 1} },
    },
    ambient_light = {0.01, 0.01, 0.01}
  },
  oxide =
  {
    normal_strength = 1,
    light_width = 0,
    brightness = 0.5,
    specular_strength = 3.5,
    specular_power = 2,
    specular_purity = 0.6,
    sss_contrast = 1,
    sss_amount = 0.25,
    lights = {
      { color = {1,1,1}, direction = {0.7,0.4,-1} },
      { color = {0.05,0.3,0.3}, direction = {-1,-1,0} },
      { color = {0.05,0.2,0.25}, direction = {-0.4,-0.1,-1} },
    },
    ambient_light = {0.01, 0.020, 0.027},
  },
}

-- Vanilla overrides the chunk backlight direction on two sprite sources after generation.
graphics.chunk_backlight_direction =
{
  metallic = {-1,-45,0.1},
  oxide = {-1,-1,0.1},
}

-- Sprite file suffixes that exist per sprite source and size.
graphics.variation_suffixes =
{
  metallic =
  {
    chunk = {"01", "02", "03", "04", "05", "06", "07", "08"},
    small = {"01", "02", "03", "04", "05", "06", "07", "08"},
    medium = {"01", "02", "03", "04", "05", "06"},
    big = {"01", "02", "03", "04", "05", "06"},
    huge = {"01", "02", "03", "04", "05", "06"},
  },
  carbonic =
  {
    chunk = {"01", "02", "03", "04", "05", "06", "09"},
    small = {"01", "02", "03", "04", "05", "06"},
    medium = {"01", "02", "03", "04", "05", "06"},
    big = {"01", "02", "03", "04", "05", "06"},
    huge = {"01", "02", "03", "04", "05", "06", "07"},
  },
  oxide =
  {
    chunk = {"01", "02", "03", "04", "05", "06"},
    small = {"01", "02", "03", "04", "05", "06", "07"},
    medium = {"01", "02", "03", "04", "05"},
    big = {"01", "02", "03", "04", "05"},
    huge = {"01", "02", "03", "04", "05", "06", "07"},
  },
}

-- The six classes. sprite names the vanilla asteroid whose sprites, explosions and particles
-- are borrowed; color goes into shading_data.lights[2]; icon_tint tints the borrowed icon.
graphics.classes =
{
  {name = "s", sprite = "metallic", order = "a", color = {0.55, 0.45, 0.35}, icon_tint = {0.85, 0.75, 0.65}},
  {name = "m", sprite = "metallic", order = "b", color = {0.80, 0.85, 0.90}, icon_tint = {0.85, 0.88, 0.92}},
  {name = "c", sprite = "carbonic", order = "c", color = {0.16, 0.14, 0.22}},
  {name = "v", sprite = "oxide", order = "d", color = {0.75, 0.75, 0.75}, brightness = 0.7, icon_tint = {0.9, 0.9, 0.9}},
  {name = "e", sprite = "oxide", order = "e", color = {1, 1, 1}, brightness = 1.0, ambient_light = {0.03, 0.03, 0.03}, icon_tint = {1, 1, 1}},
  {name = "d", sprite = "carbonic", order = "f", color = {0.55, 0.12, 0.06}, icon_tint = {0.75, 0.45, 0.4}},
}

function graphics.asteroid_variation(asteroid_type, suffix, scale, size)
  local asteroid_sizes = graphics.asteroid_sizes
  local sizes_resolution = graphics.sizes_resolution
  return
  {
    color_texture =
    {
      filename = "__space-age__/graphics/entity/asteroid/".. asteroid_type .."/"..asteroid_sizes[size].."/".."asteroid-" .. asteroid_type .. "-" .. asteroid_sizes[size] .. "-colour-" .. suffix .. ".png",
      size =  sizes_resolution[size][1],
      scale = scale
    },

    shadow_shift = { 0.25 * size, 0.25 * size },

    normal_map =
    {
      filename = "__space-age__/graphics/entity/asteroid/".. asteroid_type .."/"..asteroid_sizes[size].."/".."asteroid-" .. asteroid_type .. "-" .. asteroid_sizes[size] .. "-normal-" .. suffix .. ".png",
      premul_alpha = false,
      size = sizes_resolution[size][1],
      scale = scale
    },

    roughness_map =
    {
      filename = "__space-age__/graphics/entity/asteroid/".. asteroid_type .."/"..asteroid_sizes[size].."/".."asteroid-" .. asteroid_type .. "-" .. asteroid_sizes[size] .. "-roughness-" .. suffix .. ".png",
      premul_alpha = false,
      size = sizes_resolution[size][1],
      scale = scale
    }
  }
end

function graphics.asteroid_graphics_set(rotation_speed, shading_data, variations)
  local result = table.deepcopy(shading_data)
  result.rotation_speed = rotation_speed
  result.variations = variations
  return result
end

-- Every sprite variation of a class at one size index (1 = chunk .. 5 = huge).
function graphics.variations(class, size)
  local variations = {}
  local suffixes = graphics.variation_suffixes[class.sprite][graphics.asteroid_sizes[size]]
  for _, suffix in ipairs(suffixes) do
    table.insert(variations, graphics.asteroid_variation(class.sprite, suffix, graphics.graphics_scale[size], size))
  end
  return variations
end

-- The borrowed sprite source's shading data with the class colour on lights[2].
function graphics.shading(class)
  local shading = table.deepcopy(graphics.shading_data[class.sprite])
  shading.lights[2].color = table.deepcopy(class.color)
  if class.brightness then shading.brightness = class.brightness end
  if class.ambient_light then shading.ambient_light = table.deepcopy(class.ambient_light) end
  return shading
end

-- The borrowed vanilla icon, tinted for the class. vanilla_name is the vanilla prototype name.
function graphics.icons(class, vanilla_name)
  return
  {
    {
      icon = "__space-age__/graphics/icons/" .. vanilla_name .. ".png",
      icon_size = 64,
      tint = class.icon_tint and table.deepcopy(class.icon_tint) or nil
    }
  }
end

return graphics
