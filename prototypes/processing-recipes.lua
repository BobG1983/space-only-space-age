-- The new processing recipes of DESIGN.md section 5: nickel smelting, carbon baking, the four
-- chemical plant recipes, the volatiles science pack and the four machine recipes. Field shapes
-- copy the nearest vanilla recipe (iron-plate, coal-synthesis, heavy-oil-cracking, biolab).

local function item(name, amount)
  return {type = "item", name = name, amount = amount}
end

local function fluid(name, amount)
  return {type = "fluid", name = name, amount = amount}
end

data:extend(
{
  {
    type = "recipe",
    name = "nickel-plate",
    categories = {"smelting"},
    auto_recycle = false,
    enabled = false,
    energy_required = 3.2,
    ingredients = {item("nickel-ore", 1)},
    results = {item("nickel-plate", 1)},
    allow_productivity = true
  },
  -- Two ingredients in a furnace: recipe-rewrites.lua gives the electric furnace a second source slot.
  {
    type = "recipe",
    name = "carbon-baking",
    localised_name = {"recipe-name.carbon-baking"},
    localised_description = {"recipe-description.carbon-baking"},
    icon = "__space-age__/graphics/icons/coal-synthesis.png",
    categories = {"smelting"},
    subgroup = "raw-material",
    order = "m[carbon-baking]",
    auto_recycle = false,
    enabled = false,
    energy_required = 4,
    ingredients =
    {
      item("carbon", 4),
      item("ice", 1)
    },
    results = {item("coal", 2)},
    allow_productivity = true,
    allow_decomposition = false
  },
  {
    type = "recipe",
    name = "lithium-leaching",
    localised_name = {"recipe-name.lithium-leaching"},
    localised_description = {"recipe-description.lithium-leaching"},
    icons = {{icon = "__space-age__/graphics/icons/fluid/lithium-brine.png"}},
    categories = {"chemistry"},
    subgroup = "fluid-recipes",
    order = "d[other-chemistry]-d[lithium-leaching]",
    auto_recycle = false,
    enabled = false,
    energy_required = 5,
    ingredients =
    {
      item("hydrated-silicate", 5),
      fluid("water", 50)
    },
    results =
    {
      fluid("lithium-brine", 20),
      fluid("ammonia", 20),
      item("stone", 2)
    },
    allow_productivity = true,
    allow_decomposition = false,
    crafting_machine_tint =
    {
      primary = {r = 0.455, g = 0.837, b = 0.563, a = 1.000},
      secondary = {r = 0.643, g = 0.668, b = 0.739, a = 1.000},
      tertiary = {r = 0.800, g = 0.850, b = 0.800, a = 1.000},
      quaternary = {r = 0.600, g = 0.650, b = 0.600, a = 1.000}
    }
  },
  {
    type = "recipe",
    name = "volatile-separation",
    localised_name = {"recipe-name.volatile-separation"},
    localised_description = {"recipe-description.volatile-separation"},
    icons = {{icon = "__space-age__/graphics/icons/fluid/ammoniacal-solution-separation.png"}},
    categories = {"chemistry"},
    subgroup = "fluid-recipes",
    order = "d[other-chemistry]-e[volatile-separation]",
    auto_recycle = false,
    enabled = false,
    energy_required = 3,
    ingredients = {item("volatile-ice", 5)},
    results =
    {
      fluid("ammonia", 30),
      fluid("methane", 30),
      fluid("water", 10)
    },
    allow_productivity = true,
    allow_decomposition = false,
    crafting_machine_tint =
    {
      primary = {r = 0.596, g = 0.764, b = 0.780, a = 1.000},
      secondary = {r = 0.551, g = 0.762, b = 0.844, a = 1.000},
      tertiary = {r = 0.596, g = 0.773, b = 0.895, a = 1.000},
      quaternary = {r = 0.290, g = 0.734, b = 1.000, a = 1.000}
    }
  },
  {
    type = "recipe",
    name = "methane-cracking",
    localised_name = {"recipe-name.methane-cracking"},
    localised_description = {"recipe-description.methane-cracking"},
    icons = {{icon = "__base__/graphics/icons/fluid/light-oil-cracking.png", tint = {0.9, 0.75, 0.55}}},
    categories = {"chemistry"},
    subgroup = "fluid-recipes",
    order = "b[fluid-chemistry]-c[methane-cracking]",
    auto_recycle = false,
    enabled = false,
    energy_required = 2,
    ingredients =
    {
      fluid("methane", 20),
      fluid("steam", 10)
    },
    results = {fluid("petroleum-gas", 20)},
    main_product = "",
    allow_productivity = true,
    allow_decomposition = false,
    crafting_machine_tint =
    {
      primary = {r = 0.900, g = 0.750, b = 0.550, a = 1.000},
      secondary = {r = 0.850, g = 0.700, b = 0.500, a = 1.000},
      tertiary = {r = 0.700, g = 0.600, b = 0.500, a = 1.000},
      quaternary = {r = 0.950, g = 0.800, b = 0.600, a = 1.000}
    }
  },
  {
    type = "recipe",
    name = "phosphate-processing",
    localised_name = {"recipe-name.phosphate-processing"},
    localised_description = {"recipe-description.phosphate-processing"},
    icons = {{icon = "__space-age__/graphics/icons/fluid/fluorine.png", tint = {1, 0.9, 0.7}}},
    categories = {"chemistry"},
    subgroup = "fluid-recipes",
    order = "d[other-chemistry]-f[phosphate-processing]",
    auto_recycle = false,
    enabled = false,
    energy_required = 8,
    ingredients =
    {
      item("phosphate-rock", 10),
      fluid("sulfuric-acid", 30)
    },
    results =
    {
      fluid("fluorine", 10),
      item("uranium-ore", 3),
      {type = "item", name = "holmium-ore", amount = 1, independent_probability = 0.5},
      item("stone", 5)
    },
    allow_productivity = true,
    allow_decomposition = false,
    crafting_machine_tint =
    {
      primary = {r = 0.100, g = 0.700, b = 0.400, a = 1.000},
      secondary = {r = 0.850, g = 0.800, b = 0.600, a = 1.000},
      tertiary = {r = 0.500, g = 0.550, b = 0.450, a = 1.000},
      quaternary = {r = 0.200, g = 0.800, b = 0.500, a = 1.000}
    }
  },
  {
    type = "recipe",
    name = "volatiles-science-pack",
    categories = {"crafting-with-fluid"},
    subgroup = "science-pack",
    auto_recycle = false,
    enabled = false,
    energy_required = 10,
    ingredients =
    {
      fluid("ammonia", 10),
      item("carbon-fiber", 1),
      fluid("methane", 20)
    },
    results = {item("volatiles-science-pack", 1)},
    allow_productivity = true,
    crafting_machine_tint =
    {
      primary = {r = 0.750, g = 0.850, b = 1.000, a = 1.000},
      secondary = {r = 0.550, g = 0.700, b = 0.900, a = 1.000}
    }
  },
  {
    type = "recipe",
    name = "quantum-research-center",
    categories = {"crafting"},
    enabled = false,
    energy_required = 10,
    ingredients =
    {
      item("lab", 1),
      item("quantum-processor", 4),
      item("superconductor", 10),
      item("refined-concrete", 25)
    },
    results = {item("quantum-research-center", 1)}
  },
  -- The three tier-0 machines are available from the start and hand-craftable.
  {
    type = "recipe",
    name = "heating-panel",
    categories = {"crafting"},
    enabled = true,
    energy_required = 5,
    ingredients =
    {
      item("iron-plate", 10),
      item("copper-plate", 10),
      item("pipe", 4)
    },
    results = {item("heating-panel", 1)}
  },
  {
    type = "recipe",
    name = "heat-boiler",
    categories = {"crafting"},
    enabled = true,
    energy_required = 3,
    ingredients =
    {
      item("iron-plate", 10),
      item("pipe", 4)
    },
    results = {item("heat-boiler", 1)}
  },
  {
    type = "recipe",
    name = "melter",
    categories = {"crafting"},
    enabled = true,
    energy_required = 5,
    ingredients =
    {
      item("iron-plate", 10),
      item("pipe", 4)
    },
    results = {item("melter", 1)}
  }
})
