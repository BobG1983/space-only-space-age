-- The methane fluid (DESIGN.md section 3): made by volatile separation, cracked into
-- petroleum gas. auto_barrel is left on so base/data-updates.lua makes its barrel items.
data:extend(
{
  {
    type = "fluid",
    name = "methane",
    -- icon_size is explicit because the barrel generator combines this table with its own icons.
    icons = {{icon = "__base__/graphics/icons/fluid/petroleum-gas.png", icon_size = 64, tint = {0.9, 0.75, 0.55}}},
    subgroup = "fluid",
    order = "a[fluid]-d[methane]",
    default_temperature = 15,
    gas_temperature = 15,
    base_color = {0.45, 0.35, 0.25},
    flow_color = {0.85, 0.7, 0.5}
  }
})
