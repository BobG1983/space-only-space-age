-- The quantum research center: the biolab copied, freed from its planet condition and
-- pollution, sped up to 3, and given the lab's pack list. Satisfies DESIGN.md section 6.
local center = table.deepcopy(data.raw.lab.biolab)

center.name = "quantum-research-center"
center.icon = nil
center.icons = {{icon = "__space-age__/graphics/icons/biolab.png", tint = {0.7, 0.8, 1}}}
center.minable.result = "quantum-research-center"
center.order = "z-z[z-quantum-research-center]"
center.researching_speed = 3
center.science_pack_drain_rate_percent = 50
center.module_slots = 4
-- The lab's list has already swapped the agricultural pack for the volatiles pack.
center.inputs = table.deepcopy(data.raw.lab.lab.inputs)
center.surface_conditions = nil
center.energy_source.emissions_per_minute = nil

data:extend({center})
