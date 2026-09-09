-- Turns nauvis into the void anchor the home platform orbits: a 64x64 out-of-map surface with
-- no pollution, no wind, and no globe drawn behind the platform. Satisfies DESIGN.md sections
-- 1 and 12. The planet stays visible so a platform schedule can still target it.

local nauvis = data.raw.planet.nauvis

nauvis.map_gen_settings =
{
  width = 64,
  height = 64,
  autoplace_controls = {},
  autoplace_settings =
  {
    entity = {settings = {}},
    decorative = {settings = {}},
    tile = {settings = {["out-of-map"] = {}}}
  },
  property_expression_names = {},
  starting_area = 0,
  peaceful_mode = true
}

nauvis.pollutant_type = nil
nauvis.persistent_ambient_sounds = nil
nauvis.solar_power_in_space = 300

-- Space dust stays; the planet behind a parked platform goes.
if nauvis.platform_surface_render_parameters then
  nauvis.platform_surface_render_parameters.platform_backdrop = nil
end
