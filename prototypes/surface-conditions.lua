-- Strips surface conditions so vanilla recipes and machines work on a platform (DESIGN.md
-- section 11). Recipes keep only the space-only gravity 0 condition; entities keep theirs only on
-- the four platform machines named below (D-60). iron-chest and steel-chest are covered by the loop.

-- Recipes: strip everything except the gravity 0 (space-only) ones.
for _, recipe in pairs(data.raw.recipe) do
  local conditions = recipe.surface_conditions
  if conditions and not (conditions[1] and conditions[1].property == "gravity" and conditions[1].max == 0) then
    recipe.surface_conditions = nil
  end
end

-- Entities: strip everything except the space-only ones. Only entity types are walked, so the
-- recipe conditions kept above survive.
local keep =
{
  crusher = true,
  ["space-platform-hub"] = true,
  ["asteroid-collector"] = true,
  thruster = true
}
for type_name in pairs(defines.prototypes.entity) do
  local category = data.raw[type_name]
  if category then
    for name, prototype in pairs(category) do
      if prototype.surface_conditions and not keep[name] then
        prototype.surface_conditions = nil
      end
    end
  end
end
