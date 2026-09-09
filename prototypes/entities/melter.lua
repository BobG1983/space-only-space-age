-- The melter: a chemical plant locked to ice-melting, powered by nothing, with one water
-- output on its south edge. Ice goes in by hand or inserter. Satisfies DESIGN.md section 6.
local melter = table.deepcopy(data.raw["assembling-machine"]["chemical-plant"])

melter.name = "melter"
melter.icon = nil
melter.icons = {{icon = "__base__/graphics/icons/chemical-plant.png", tint = {0.7, 0.9, 1}}}
melter.minable.result = "melter"
melter.fast_replaceable_group = "melter"
melter.crafting_categories = {"melting"}
melter.fixed_recipe = "ice-melting"
melter.show_recipe_icon = false
melter.energy_source =
{
  type = "void"
}
melter.energy_usage = "50kW"
melter.module_slots = 0
melter.allowed_effects = {}
melter.fluid_boxes =
{
  {
    production_type = "output",
    pipe_covers = pipecoverspictures(),
    volume = 100,
    pipe_connections =
    {
      {
        flow_direction = "output",
        direction = defines.direction.south,
        position = {0, 1}
      }
    }
  }
}
melter.fluid_boxes_off_when_no_fluid_recipe = false
melter.surface_conditions = nil
melter.heating_energy = nil

data:extend({melter})
