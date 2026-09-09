-- The heat boiler: the heat exchanger copied and turned down to 165 C steam at 1.8 MW, fed
-- from a 250 degree heat network so one boiler runs two steam engines. Satisfies DESIGN.md
-- section 6.
local boiler = table.deepcopy(data.raw.boiler["heat-exchanger"])

boiler.name = "heat-boiler"
boiler.icon = nil
boiler.icons = {{icon = "__base__/graphics/icons/heat-boiler.png", tint = {1, 0.8, 0.6}}}
boiler.minable.result = "heat-boiler"
boiler.fast_replaceable_group = "heat-boiler"
boiler.target_temperature = 165
boiler.energy_consumption = "1.8MW"

-- The exchanger only works from 500 degrees; the boiler must work from its own target.
boiler.energy_source.max_temperature = 250
boiler.energy_source.min_working_temperature = 165
boiler.energy_source.minimum_glow_temperature = 100

data:extend({boiler})
