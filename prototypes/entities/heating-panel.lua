-- The heating panel: a 2x2 reactor on a void energy source that puts a flat 1 MW of heat
-- into its buffer wherever it stands. The heating tower shrunk to two tiles, its art borrowed
-- as a placeholder. Satisfies DESIGN.md section 6.
local sounds = require("__base__.prototypes.entity.sounds")
local hit_effects = require("__base__.prototypes.entity.hit-effects")

local art = "__space-age__/graphics/entity/heating-tower/"
-- The tower is drawn at 0.5 for three tiles; two thirds of that fits two tiles.
local scale = 0.333
local shift_multiplier = scale / 0.5

local function tower_sprite(name, extra)
  local sprite = {scale = scale, multiply_shift = shift_multiplier}
  for key, value in pairs(extra or {}) do
    sprite[key] = value
  end
  return util.sprite_load(art .. name, sprite)
end

-- The tower sheet holds one patch per side, north to west. Two copies give eight
-- variations, one per connection, so the connections below are listed side by side twice.
local function patch_sheets(name)
  return
  {
    sheets =
    {
      tower_sprite(name, {variation_count = 4}),
      tower_sprite(name, {variation_count = 4})
    }
  }
end

local function heat_patch_sheets(name)
  local sheets = patch_sheets(name)
  for i, sheet in ipairs(sheets.sheets) do
    sheets.sheets[i] = apply_heat_pipe_glow(sheet)
  end
  return sheets
end

data:extend(
{
  {
    type = "reactor",
    name = "heating-panel",
    icons = {{icon = "__base__/graphics/icons/solar-panel.png", tint = {1, 0.85, 0.6}}},
    flags = {"placeable-neutral", "player-creation"},
    minable = {mining_time = 0.2, result = "heating-panel"},
    fast_replaceable_group = "heating-panel",
    max_health = 200,
    corpse = "solar-panel-remnants",
    dying_explosion = "solar-panel-explosion",
    consumption = "1MW",
    neighbour_bonus = 0,
    energy_source =
    {
      type = "void"
    },
    collision_box = {{-0.9, -0.9}, {0.9, 0.9}},
    selection_box = {{-1, -1}, {1, 1}},
    damaged_trigger_effect = hit_effects.entity(),
    drawing_box_vertical_extension = 0.7,
    temperature_to_suppress_energy_icons = 800,
    picture =
    {
      layers =
      {
        tower_sprite("heating-tower-main"),
        tower_sprite("heating-tower-shadow", {draw_as_shadow = true})
      }
    },
    heat_buffer =
    {
      max_temperature = 250,
      specific_heat = "1MJ",
      max_transfer = "1GW",
      minimum_glow_temperature = 100,
      connections =
      {
        {position = {-0.5, -0.5}, direction = defines.direction.north},
        {position = {0.5, -0.5}, direction = defines.direction.east},
        {position = {0.5, 0.5}, direction = defines.direction.south},
        {position = {-0.5, 0.5}, direction = defines.direction.west},
        {position = {0.5, -0.5}, direction = defines.direction.north},
        {position = {0.5, 0.5}, direction = defines.direction.east},
        {position = {-0.5, 0.5}, direction = defines.direction.south},
        {position = {-0.5, -0.5}, direction = defines.direction.west}
      },
      heat_picture = apply_heat_pipe_glow(tower_sprite("heating-tower-glow", {blend_mode = "additive"}))
    },
    connection_patches_connected = patch_sheets("heating-tower-pipes"),
    connection_patches_disconnected = patch_sheets("heating-tower-pipes-disconnected"),
    heat_connection_patches_connected = heat_patch_sheets("heating-tower-pipes-heat"),
    heat_connection_patches_disconnected = heat_patch_sheets("heating-tower-pipes-heat-disconnected"),
    open_sound = sounds.steam_open,
    close_sound = sounds.steam_close,
    default_temperature_signal = {type = "virtual", name = "signal-T"},
    circuit_wire_max_distance = reactor_circuit_wire_max_distance,
    circuit_connector = circuit_connector_definitions["heating-tower"]
  }
})
