-- Cross-reference checks over data.raw. Loaded by tools/load.lua --check.
-- Every check is a named function; every problem is
--   <check-name>: <owner type>.<owner name> -> <field> = <missing name>
-- and the whole file assumes the 2.1.17 prototype shapes (recipe.categories, results only,
-- independent_probability, mine-entity.entities, ambient-sound.planets ...).

local M = {checks = {}}

local function add(name, fn) M.checks[#M.checks + 1] = {name = name, fn = fn} end

function M.format(p)
  return string.format("%s: %s.%s -> %s = %s", p.check, p.owner_type, p.owner_name, p.field, p.missing)
end

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------
local function find_node(node, name)
  for k, v in pairs(node) do
    if k ~= "_abstract" then
      if k == name then return v end
      local found = find_node(v, name)
      if found then return found end
    end
  end
  return nil
end

local function types_under(node, name, out)
  out = out or {}
  out[#out + 1] = name
  for k, v in pairs(node) do
    if k ~= "_abstract" then types_under(v, k, out) end
  end
  return out
end

local function set_of(raw, types)
  local set = {}
  for _, t in ipairs(types) do
    for name in pairs(raw[t] or {}) do set[name] = true end
  end
  return set
end

local function each(raw, types, fn)
  for _, t in ipairs(types) do
    for name, proto in pairs(raw[t] or {}) do fn(t, name, proto) end
  end
end

local function each_all(raw, fn)
  for t, cat in pairs(raw) do
    if type(cat) == "table" then
      for name, proto in pairs(cat) do
        if type(proto) == "table" then fn(t, name, proto) end
      end
    end
  end
end

local function is_list(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n == #t
end

-- C.need(check, ptype, pname, field, value, set): report when value is a string missing from set
local function make_need(C)
  return function(check, ptype, pname, field, value, set)
    if type(value) == "string" and not set[value] then
      C.report(check, ptype, pname, field, value)
      return false
    end
    return true
  end
end

-- product / ingredient entry: {type=, name=, amount=} or the short {"name", n} form
local function entry_name_type(e)
  if type(e) ~= "table" then return nil, nil end
  return e.name or e[1], e.type or "item"
end

-- ---------------------------------------------------------------------------
-- recipes
-- ---------------------------------------------------------------------------
add("recipe-ingredient", function(C)
  for name, r in pairs(C.recipes) do
    for i, ing in ipairs(r.ingredients or {}) do
      local n, t = entry_name_type(ing)
      C.need("recipe-ingredient", "recipe", name, "ingredients[" .. i .. "]", n, t == "fluid" and C.fluids or C.items)
    end
  end
end)

add("recipe-result", function(C)
  for name, r in pairs(C.recipes) do
    for i, res in ipairs(r.results or {}) do
      local n, t = entry_name_type(res)
      C.need("recipe-result", "recipe", name, "results[" .. i .. "]", n, t == "fluid" and C.fluids or C.items)
    end
  end
end)

add("recipe-removed-field", function(C)
  -- 2.1.7 removed RecipePrototype::category and additional_categories (categories replaced them);
  -- 2.0 removed result / result_count (results only) and ItemProductPrototype::probability
  -- became independent_probability in 2.1.7.
  for name, r in pairs(C.recipes) do
    if r.category ~= nil then C.report("recipe-removed-field", "recipe", name, "category", tostring(r.category) .. " (removed in 2.1; use categories)") end
    if r.additional_categories ~= nil then C.report("recipe-removed-field", "recipe", name, "additional_categories", "(removed in 2.1; use categories)") end
    if r.result ~= nil then C.report("recipe-removed-field", "recipe", name, "result", tostring(r.result) .. " (removed in 2.0; use results)") end
    if r.result_count ~= nil then C.report("recipe-removed-field", "recipe", name, "result_count", "(removed in 2.0; use results)") end
    if r.always_show_products ~= nil then C.report("recipe-removed-field", "recipe", name, "always_show_products", "(removed in 2.1)") end
    for i, res in ipairs(r.results or {}) do
      if type(res) == "table" and res.probability ~= nil then
        C.report("recipe-removed-field", "recipe", name, "results[" .. i .. "].probability", "(removed in 2.1; use independent_probability)")
      end
    end
  end
end)

add("recipe-category", function(C)
  for name, r in pairs(C.recipes) do
    for i, c in ipairs(r.categories or {}) do
      C.need("recipe-category", "recipe", name, "categories[" .. i .. "]", c, C.recipe_categories)
    end
  end
end)

add("recipe-main-product", function(C)
  for name, r in pairs(C.recipes) do
    local mp = r.main_product
    if type(mp) == "string" and mp ~= "" then
      local found = false
      for _, res in ipairs(r.results or {}) do
        if entry_name_type(res) == mp then found = true end
      end
      if not found then C.report("recipe-main-product", "recipe", name, "main_product", mp) end
    end
  end
end)

add("recipe-category-crafter", function(C)
  -- every category a recipe uses is crafted by some machine or by the character
  local crafted = {}
  each_all(C.raw, function(_, _, proto)
    for _, c in ipairs(proto.crafting_categories or {}) do crafted[c] = true end
  end)
  -- Loosened: parameter recipes (parameter = true, category "parameters") are blueprint
  -- placeholders nothing crafts, so they are skipped.
  for name, r in pairs(C.recipes) do
    for i, c in ipairs(r.categories or {}) do
      if C.recipe_categories[c] and not crafted[c] and not r.parameter then
        C.report("recipe-category-crafter", "recipe", name, "categories[" .. i .. "]", c .. " (no prototype lists it in crafting_categories)")
      end
    end
  end
end)

-- ---------------------------------------------------------------------------
-- technologies and labs
-- ---------------------------------------------------------------------------
add("technology-prerequisite", function(C)
  for name, t in pairs(C.technologies) do
    for i, p in ipairs(t.prerequisites or {}) do
      C.need("technology-prerequisite", "technology", name, "prerequisites[" .. i .. "]", p, C.technologies)
    end
  end
end)

add("technology-effect", function(C)
  local rules = {
    ["unlock-recipe"] = {"recipe", "recipes"},
    ["change-recipe-productivity"] = {"recipe", "recipes"},
    ["unlock-space-location"] = {"space_location", "locations"},
    ["unlock-quality"] = {"quality", "qualities"},
    ["ammo-damage"] = {"ammo_category", "ammo_categories"},
    ["gun-speed"] = {"ammo_category", "ammo_categories"},
    ["turret-attack"] = {"turret_id", "entities"},
    ["give-item"] = {"item", "items"},
  }
  for name, t in pairs(C.technologies) do
    for i, e in ipairs(t.effects or {}) do
      local rule = type(e) == "table" and rules[e.type]
      if rule then
        C.need("technology-effect", "technology", name, "effects[" .. i .. "]." .. rule[1], e[rule[1]], C[rule[2]])
      end
    end
  end
end)

add("technology-unit-ingredient", function(C)
  for name, t in pairs(C.technologies) do
    local unit = t.unit
    for i, ing in ipairs(unit and unit.ingredients or {}) do
      local n = entry_name_type(ing)
      C.need("technology-unit-ingredient", "technology", name, "unit.ingredients[" .. i .. "]", n, C.items)
    end
  end
end)

add("technology-research-trigger", function(C)
  for name, t in pairs(C.technologies) do
    local tr = t.research_trigger
    if type(tr) == "table" then
      local kind = tr.type
      if kind == "craft-item" or kind == "send-item-to-orbit" then
        C.need("technology-research-trigger", "technology", name, "research_trigger.item", tr.item, C.items)
      elseif kind == "craft-fluid" then
        C.need("technology-research-trigger", "technology", name, "research_trigger.fluid", tr.fluid, C.fluids)
      elseif kind == "mine-entity" then
        if tr.entity ~= nil then
          C.report("technology-research-trigger", "technology", name, "research_trigger.entity", tostring(tr.entity) .. " (renamed to entities in 2.1)")
        end
        for i, e in ipairs(tr.entities or {}) do
          C.need("technology-research-trigger", "technology", name, "research_trigger.entities[" .. i .. "]", e, C.entities)
        end
      elseif kind == "build-entity" or kind == "capture-spawner" then
        C.need("technology-research-trigger", "technology", name, "research_trigger.entity", tr.entity, C.entities)
      end
    end
  end
end)

add("lab-input", function(C)
  each(C.raw, {"lab"}, function(t, name, lab)
    for i, item in ipairs(lab.inputs or {}) do
      C.need("lab-input", t, name, "inputs[" .. i .. "]", item, C.items)
    end
  end)
end)

-- ---------------------------------------------------------------------------
-- items
-- ---------------------------------------------------------------------------
add("item-place-result", function(C)
  each(C.raw, C.item_types, function(t, name, item)
    C.need("item-place-result", t, name, "place_result", item.place_result, C.entities)
  end)
end)

add("item-place-as-tile", function(C)
  each(C.raw, C.item_types, function(t, name, item)
    if type(item.place_as_tile) == "table" then
      C.need("item-place-as-tile", t, name, "place_as_tile.result", item.place_as_tile.result, C.tiles)
    end
  end)
end)

add("item-place-as-equipment", function(C)
  each(C.raw, C.item_types, function(t, name, item)
    C.need("item-place-as-equipment", t, name, "place_as_equipment_result", item.place_as_equipment_result, C.equipment)
  end)
end)

add("item-fuel-category", function(C)
  each(C.raw, C.item_types, function(t, name, item)
    C.need("item-fuel-category", t, name, "fuel_category", item.fuel_category, C.fuel_categories)
  end)
end)

add("item-result-links", function(C)
  each(C.raw, C.item_types, function(t, name, item)
    C.need("item-result-links", t, name, "burnt_result", item.burnt_result, C.items)
    C.need("item-result-links", t, name, "spoil_result", item.spoil_result, C.items)
    C.need("item-result-links", t, name, "plant_result", item.plant_result, C.entities)
    for i, p in ipairs(item.rocket_launch_products or {}) do
      local n = entry_name_type(p)
      C.need("item-result-links", t, name, "rocket_launch_products[" .. i .. "]", n, C.items)
    end
  end)
end)

add("default-import-location", function(C)
  each_all(C.raw, function(t, name, proto)
    C.need("default-import-location", t, name, "default_import_location", proto.default_import_location, C.planets)
  end)
end)

add("module-category", function(C)
  each(C.raw, {"module"}, function(t, name, m)
    C.need("module-category", t, name, "category", m.category, C.module_categories)
  end)
end)

add("subgroup", function(C)
  each_all(C.raw, function(t, name, proto)
    if t ~= "item-subgroup" then
      C.need("subgroup", t, name, "subgroup", proto.subgroup, C.subgroups)
    end
  end)
  each(C.raw, {"item-subgroup"}, function(t, name, sg)
    C.need("subgroup", t, name, "group", sg.group, C.groups)
  end)
end)

-- ---------------------------------------------------------------------------
-- equipment
-- ---------------------------------------------------------------------------
add("equipment", function(C)
  each(C.raw, C.equipment_types, function(t, name, eq)
    C.need("equipment", t, name, "take_result", eq.take_result, C.items)
    for i, c in ipairs(eq.categories or {}) do
      C.need("equipment", t, name, "categories[" .. i .. "]", c, C.equipment_categories)
    end
  end)
  each(C.raw, {"equipment-grid"}, function(t, name, g)
    for i, c in ipairs(g.equipment_categories or {}) do
      C.need("equipment", t, name, "equipment_categories[" .. i .. "]", c, C.equipment_categories)
    end
  end)
  each_all(C.raw, function(t, name, proto)
    C.need("equipment", t, name, "equipment_grid", proto.equipment_grid, C.equipment_grids)
  end)
end)

-- ---------------------------------------------------------------------------
-- entities (and anything else mined or upgraded)
-- ---------------------------------------------------------------------------
add("minable", function(C)
  each_all(C.raw, function(t, name, proto)
    local m = proto.minable
    if type(m) == "table" then
      C.need("minable", t, name, "minable.result", m.result, C.items)
      for i, res in ipairs(m.results or {}) do
        local n, rt = entry_name_type(res)
        C.need("minable", t, name, "minable.results[" .. i .. "]", n, rt == "fluid" and C.fluids or C.items)
      end
      C.need("minable", t, name, "minable.required_fluid", m.required_fluid, C.fluids)
    end
  end)
end)

add("entity-next-upgrade", function(C)
  each(C.raw, C.entity_types, function(t, name, e)
    if type(e.next_upgrade) == "string" and not (C.raw[t] or {})[e.next_upgrade] then
      local other = C.entities[e.next_upgrade] and " (exists, but not as type " .. t .. ")" or ""
      C.report("entity-next-upgrade", t, name, "next_upgrade", e.next_upgrade .. other)
    end
  end)
end)

add("entity-corpse", function(C)
  -- Loosened: corpse resolves against every entity type, not only corpse prototypes. In 2.1.17
  -- the demolisher segments (space-age/prototypes/entity/enemies.lua) name a simple-entity as
  -- their corpse so it can be mined, and the game accepts it.
  each(C.raw, C.entity_types, function(t, name, e)
    local c = e.corpse
    if type(c) == "string" then
      C.need("entity-corpse", t, name, "corpse", c, C.entities)
    elseif type(c) == "table" then
      for i, v in ipairs(c) do C.need("entity-corpse", t, name, "corpse[" .. i .. "]", v, C.entities) end
    end
    C.need("entity-corpse", t, name, "character_corpse", e.character_corpse, C.raw["character-corpse"] or {})
  end)
end)

add("entity-dying-explosion", function(C)
  each(C.raw, C.entity_types, function(t, name, e)
    local d = e.dying_explosion
    if type(d) == "string" then
      C.need("entity-dying-explosion", t, name, "dying_explosion", d, C.entities)
    elseif type(d) == "table" then
      for i, v in ipairs(d) do
        local n = type(v) == "table" and v.name or v
        C.need("entity-dying-explosion", t, name, "dying_explosion[" .. i .. "]", n, C.entities)
      end
    end
  end)
end)

add("entity-links", function(C)
  each(C.raw, C.entity_types, function(t, name, e)
    local r = e.remains_when_mined
    if type(r) == "string" then
      C.need("entity-links", t, name, "remains_when_mined", r, C.entities)
    elseif type(r) == "table" then
      for i, v in ipairs(r) do C.need("entity-links", t, name, "remains_when_mined[" .. i .. "]", v, C.entities) end
    end
    local pb = e.placeable_by
    if type(pb) == "table" then
      if pb.item then
        C.need("entity-links", t, name, "placeable_by.item", pb.item, C.items)
      else
        for i, v in ipairs(pb) do C.need("entity-links", t, name, "placeable_by[" .. i .. "].item", v.item, C.items) end
      end
    end
    for i, l in ipairs(e.loot or {}) do
      local n = entry_name_type(l)
      C.need("entity-links", t, name, "loot[" .. i .. "]", n, C.items)
    end
    C.need("entity-links", t, name, "fixed_recipe", e.fixed_recipe, C.recipes)
    for i, u in ipairs(e.result_units or {}) do
      local n = type(u) == "table" and (u.unit or u[1]) or u
      C.need("entity-links", t, name, "result_units[" .. i .. "]", n, C.entities)
    end
  end)
  each(C.raw, {"resource"}, function(t, name, r)
    C.need("entity-links", t, name, "category", r.category, C.resource_categories)
  end)
  each(C.raw, {"tile"}, function(t, name, tile)
    C.need("entity-links", t, name, "next_direction", tile.next_direction, C.tiles)
    C.need("entity-links", t, name, "transition_merges_with_tile", tile.transition_merges_with_tile, C.tiles)
  end)
  each(C.raw, {"quality"}, function(t, name, q)
    C.need("entity-links", t, name, "next", q.next, C.qualities)
  end)
  each(C.raw, {"fluid"}, function(t, name, f)
    C.need("entity-links", t, name, "spent_fluid", f.spent_fluid, C.fluids)
  end)
end)

add("factoriopedia-alternative", function(C)
  -- Loosened: the alternative may be any prototype of the same base class (any entity for an
  -- entity, any item for an item). Vanilla curved rails name "straight-rail", a different type.
  local base_of = {}
  for _, t in ipairs(C.entity_types) do base_of[t] = C.entities end
  for _, t in ipairs(C.item_types) do base_of[t] = C.items end
  each_all(C.raw, function(t, name, proto)
    C.need("factoriopedia-alternative", t, name, "factoriopedia_alternative", proto.factoriopedia_alternative, base_of[t] or C.raw[t] or {})
  end)
end)

-- ---------------------------------------------------------------------------
-- space
-- ---------------------------------------------------------------------------
add("space-connection", function(C)
  each(C.raw, {"space-connection"}, function(t, name, c)
    C.need("space-connection", t, name, "from", c.from, C.locations)
    C.need("space-connection", t, name, "to", c.to, C.locations)
  end)
end)

add("asteroid-spawn", function(C)
  each(C.raw, {"planet", "space-location", "space-connection"}, function(t, name, p)
    for i, d in ipairs(p.asteroid_spawn_definitions or {}) do
      if type(d) == "table" then
        local set = d.type == "asteroid-chunk" and C.asteroid_chunks or C.asteroids
        C.need("asteroid-spawn", t, name, "asteroid_spawn_definitions[" .. i .. "].asteroid", d.asteroid, set)
      end
    end
  end)
end)

add("location", function(C)
  each(C.raw, {"planet", "space-location"}, function(t, name, p)
    C.need("location", t, name, "pollutant_type", p.pollutant_type, C.raw["airborne-pollutant"] or {})
    for k in pairs(p.surface_properties or {}) do
      C.need("location", t, name, "surface_properties." .. tostring(k), k, C.surface_properties)
    end
    for _, setname in ipairs{"planet_procession_set", "platform_procession_set"} do
      local set = p[setname]
      if type(set) == "table" then
        for _, dir in ipairs{"arrival", "departure"} do
          for i, v in ipairs(set[dir] or {}) do
            C.need("location", t, name, setname .. "." .. dir .. "[" .. i .. "]", v, C.raw.procession or {})
          end
        end
      end
    end
    local mgs = p.map_gen_settings
    if type(mgs) == "table" then
      for k in pairs(mgs.autoplace_controls or {}) do
        C.need("location", t, name, "map_gen_settings.autoplace_controls." .. tostring(k), k, C.raw["autoplace-control"] or {})
      end
      local sets = {entity = C.entities, tile = C.tiles, decorative = C.decoratives}
      for kind, set in pairs(sets) do
        local as = mgs.autoplace_settings and mgs.autoplace_settings[kind]
        for k in pairs(as and as.settings or {}) do
          C.need("location", t, name, "map_gen_settings.autoplace_settings." .. kind .. ".settings." .. tostring(k), k, set)
        end
      end
    end
  end)
end)

add("ambient-sound-planet", function(C)
  each(C.raw, {"ambient-sound"}, function(t, name, s)
    if s.planet ~= nil then
      C.report("ambient-sound-planet", t, name, "planet", tostring(s.planet) .. " (renamed to planets in 2.1)")
    end
    for _, field in ipairs{"planets", "exclude_planets"} do
      for i, v in ipairs(s[field] or {}) do
        C.need("ambient-sound-planet", t, name, field .. "[" .. i .. "]", v, C.locations)
      end
    end
  end)
end)

add("starter-pack", function(C)
  each(C.raw, {"space-platform-starter-pack"}, function(t, name, p)
    for i, it in ipairs(p.initial_items or {}) do
      local n = entry_name_type(it)
      C.need("starter-pack", t, name, "initial_items[" .. i .. "]", n, C.items)
    end
    for i, tl in ipairs(p.tiles or {}) do
      C.need("starter-pack", t, name, "tiles[" .. i .. "].tile", type(tl) == "table" and tl.tile or tl, C.tiles)
    end
    C.need("starter-pack", t, name, "surface", p.surface, C.raw.surface or {})
    C.walk_triggers("starter-pack-trigger", t, name, p.trigger, "trigger")
  end)
end)

add("asteroid-collector-exists", function(C)
  if next(C.raw["asteroid-collector"] or {}) == nil then
    C.report("asteroid-collector-exists", "asteroid-collector", "*", "data.raw", "no asteroid-collector prototype")
  end
end)

add("crusher-exists", function(C)
  local found = false
  each_all(C.raw, function(_, _, proto)
    for _, c in ipairs(proto.crafting_categories or {}) do
      if c == "crushing" then found = true end
    end
  end)
  if not found then
    C.report("crusher-exists", "recipe-category", "crushing", "crafting_categories", "no crafting machine lists crushing")
  end
end)

-- ---------------------------------------------------------------------------
-- tips and tricks
-- ---------------------------------------------------------------------------
add("tips-and-tricks", function(C)
  local function trigger(t, name, tr, field)
    if type(tr) ~= "table" then return end
    C.need("tips-and-tricks", t, name, field .. ".technology", tr.technology, C.technologies)
    C.need("tips-and-tricks", t, name, field .. ".entity", tr.entity, C.entities)
    C.need("tips-and-tricks", t, name, field .. ".item", tr.item, C.items)
    C.need("tips-and-tricks", t, name, field .. ".recipe", tr.recipe, C.recipes)
    C.need("tips-and-tricks", t, name, field .. ".surface", tr.surface, C.surfaces)
    for i, sub in ipairs(tr.triggers or {}) do trigger(t, name, sub, field .. ".triggers[" .. i .. "]") end
  end
  each(C.raw, {"tips-and-tricks-item"}, function(t, name, tip)
    C.need("tips-and-tricks", t, name, "category", tip.category, C.raw["tips-and-tricks-item-category"] or {})
    for i, d in ipairs(tip.dependencies or {}) do
      C.need("tips-and-tricks", t, name, "dependencies[" .. i .. "]", d, C.raw["tips-and-tricks-item"])
    end
    trigger(t, name, tip.trigger, "trigger")
    trigger(t, name, tip.skip_trigger, "skip_trigger")
  end)
end)

-- ---------------------------------------------------------------------------
-- one walk over every prototype: trigger effects, surface conditions, rich text, ...
-- ---------------------------------------------------------------------------
local RICH_TEXT = {
  item = "items", entity = "entities", fluid = "fluids", tile = "tiles", planet = "locations",
  ["space-location"] = "locations", technology = "technologies", recipe = "recipes",
  ["virtual-signal"] = "virtual_signals", ["item-group"] = "groups", quality = "qualities",
  ["asteroid-chunk"] = "asteroid_chunks", armor = "items", shortcut = "shortcuts",
}

local EFFECTS = {
  ["create-entity"] = {"entity_name", "entities"},
  ["create-explosion"] = {"entity_name", "entities"},
  ["create-fire"] = {"entity_name", "entities"},
  ["create-smoke"] = {"entity_name", "entities"},
  ["create-sticker"] = {"sticker", "entities"},
  ["create-trivial-smoke"] = {"smoke_name", "trivial_smokes"},
  ["create-particle"] = {"particle_name", "particles"},
  ["create-decorative"] = {"decorative", "decoratives"},
  ["create-asteroid-chunk"] = {"asteroid_name", "asteroid_chunks"},
  ["set-tile"] = {"tile_name", "tiles"},
  ["insert-item"] = {"item", "items"},
  projectile = {"projectile", "entities"},
  beam = {"beam", "entities"},
  stream = {"stream", "entities"},
  artillery = {"projectile", "entities"},
  chain = {"chain", "chain_triggers"},
  delayed = {"delayed_trigger", "delayed_triggers"},
}

local MASK_KEYS = {collision_mask = true, underground_collision_mask = true, required_tiles = true, colliding_tiles = true}
local LIST_KEYS = {
  fuel_categories = {"fuel-category", "fuel_categories"},
  ammo_categories = {"ammo-category", "ammo_categories"},
  allowed_module_categories = {"module-category", "module_categories"},
  crafting_categories = {"crafting-category", "recipe_categories"},
  resource_categories = {"resource-category", "resource_categories"},
}

add("walk", function(C)
  local seen = {}
  local function visit(check_owner_t, owner, t, path, key)
    if seen[t] then return end
    seen[t] = true
    -- trigger effects and deliveries
    local rule = type(t.type) == "string" and EFFECTS[t.type]
    if rule and type(t[rule[1]]) == "string" then
      C.need("trigger-effect", check_owner_t, owner, path .. "." .. rule[1], t[rule[1]], C[rule[2]])
    end
    if t.type == "damage" and type(t.damage) == "table" then
      C.need("damage-type", check_owner_t, owner, path .. ".damage.type", t.damage.type, C.damage_types)
    end
    if key == "resistances" then
      for i, r in ipairs(t) do
        if type(r) == "table" then C.need("damage-type", check_owner_t, owner, path .. "[" .. i .. "].type", r.type, C.damage_types) end
      end
    end
    if key == "surface_conditions" then
      for i, sc in ipairs(t) do
        if type(sc) == "table" then C.need("surface-condition", check_owner_t, owner, path .. "[" .. i .. "].property", sc.property, C.surface_properties) end
      end
    end
    if MASK_KEYS[key] and type(t.layers) == "table" then
      for layer in pairs(t.layers) do
        C.need("collision-layer", check_owner_t, owner, path .. ".layers." .. tostring(layer), layer, C.collision_layers)
      end
    end
    local lk = LIST_KEYS[key]
    if lk then
      for i, v in ipairs(t) do C.need(lk[1], check_owner_t, owner, path .. "[" .. i .. "]", v, C[lk[2]]) end
    end
    if key == "energy_source" or t.type == "burner" then
      if t.fuel_category ~= nil then
        C.report("fuel-category", check_owner_t, owner, path .. ".fuel_category", tostring(t.fuel_category) .. " (removed in 2.0; use fuel_categories)")
      end
    end
    if type(t.ammo_category) == "string" and key ~= "ammo-category" then
      C.need("ammo-category", check_owner_t, owner, path .. ".ammo_category", t.ammo_category, C.ammo_categories)
    end
    if type(t.volume) == "number" and type(t.filter) == "string" then
      C.need("fluid-box-filter", check_owner_t, owner, path .. ".filter", t.filter, C.fluids)
    end
    if key == "autoplace" and type(t.control) == "string" then
      C.need("autoplace-control", check_owner_t, owner, path .. ".control", t.control, C.raw["autoplace-control"] or {})
    end
    if (key == "simulation" or key == "factoriopedia_simulation") and type(t.planet) == "string" then
      C.need("simulation-planet", check_owner_t, owner, path .. ".planet", t.planet, C.locations)
    end
    for k, v in pairs(t) do
      local kp
      if type(k) == "number" then kp = path .. "[" .. k .. "]"
      elseif path == "" then kp = tostring(k)
      else kp = path .. "." .. tostring(k) end
      if type(v) == "table" then
        visit(check_owner_t, owner, v, kp, type(k) == "number" and key or k)
      elseif type(v) == "string" then
        -- Loosened: a ref holding a quote is Lua concatenation inside a simulation init string
        -- ([item="..module_name.."] in quality's tips) and is skipped.
        for kind, ref in v:gmatch("%[([%w%-]+)=([^%],%]]+)") do
          local set = RICH_TEXT[kind]
          if set and not ref:find('"', 1, true) and not C[set][ref] then
            C.report("rich-text", check_owner_t, owner, kp, "[" .. kind .. "=" .. ref .. "]")
          end
        end
      end
    end
  end
  each_all(C.raw, function(t, name, proto)
    if t ~= "space-platform-starter-pack" then visit(t, name, proto, "", nil) end
  end)
end)

-- ---------------------------------------------------------------------------
-- harness-level facts
-- ---------------------------------------------------------------------------
add("missing-require", function(C)
  for _, name in ipairs(C.stub_order or {}) do
    local rec = C.stubs[name]
    if not rec.asset then
      C.report("missing-require", "file", rec.from, "require", name)
    end
  end
end)

add("function-value", function(C)
  for _, path in ipairs(C.functions or {}) do
    C.report("function-value", "data", "raw", path, "a function (cannot be serialised into a prototype)")
  end
end)

-- ---------------------------------------------------------------------------
-- runner
-- ---------------------------------------------------------------------------
function M.run(raw, ctx)
  local problems = {}
  local C = {raw = raw, stubs = ctx.stubs or {}, stub_order = ctx.stub_order or {}, functions = ctx.functions or {}}
  C.report = function(check, owner_type, owner_name, field, missing)
    problems[#problems + 1] = {check = check, owner_type = tostring(owner_type), owner_name = tostring(owner_name),
                               field = tostring(field), missing = tostring(missing)}
  end
  C.need = make_need(C)
  local hier = ctx.hierarchy
  C.item_types = types_under(hier.item, "item")
  C.entity_types = types_under(hier.entity, "entity")
  C.equipment_types = types_under(hier.equipment, "equipment")
  C.items = set_of(raw, C.item_types)
  C.entities = set_of(raw, C.entity_types)
  C.equipment = set_of(raw, C.equipment_types)
  C.corpses = set_of(raw, types_under(find_node(hier.entity, "corpse") or {}, "corpse"))
  C.particles = set_of(raw, {"optimized-particle", "particle"})
  C.decoratives = set_of(raw, {"optimized-decorative"})
  C.trivial_smokes = raw["trivial-smoke"] or {}
  C.asteroids = raw.asteroid or {}
  C.asteroid_chunks = raw["asteroid-chunk"] or {}
  C.planets = raw.planet or {}
  C.locations = set_of(raw, {"planet", "space-location"})
  C.surfaces = set_of(raw, {"surface", "planet", "space-location"})
  C.fluids = raw.fluid or {}
  C.tiles = raw.tile or {}
  C.recipes = raw.recipe or {}
  C.technologies = raw.technology or {}
  C.qualities = raw.quality or {}
  C.recipe_categories = raw["recipe-category"] or {}
  C.fuel_categories = raw["fuel-category"] or {}
  C.ammo_categories = raw["ammo-category"] or {}
  C.module_categories = raw["module-category"] or {}
  C.resource_categories = raw["resource-category"] or {}
  C.equipment_categories = raw["equipment-category"] or {}
  C.equipment_grids = raw["equipment-grid"] or {}
  C.surface_properties = raw["surface-property"] or {}
  C.collision_layers = raw["collision-layer"] or {}
  C.damage_types = raw["damage-type"] or {}
  C.subgroups = raw["item-subgroup"] or {}
  C.groups = raw["item-group"] or {}
  C.virtual_signals = raw["virtual-signal"] or {}
  C.shortcuts = raw.shortcut or {}
  C.chain_triggers = raw["chain-active-trigger"] or {}
  C.delayed_triggers = raw["delayed-active-trigger"] or {}

  -- walk a trigger tree under one named check (used by the starter pack)
  C.walk_triggers = function(check, t, name, node, path, seen)
    seen = seen or {}
    if type(node) ~= "table" or seen[node] then return end
    seen[node] = true
    local rule = type(node.type) == "string" and EFFECTS[node.type]
    if rule and type(node[rule[1]]) == "string" then
      C.need(check, t, name, path .. "." .. rule[1], node[rule[1]], C[rule[2]])
    end
    for k, v in pairs(node) do
      local kp = type(k) == "number" and (path .. "[" .. k .. "]") or (path .. "." .. tostring(k))
      C.walk_triggers(check, t, name, v, kp, seen)
    end
  end

  for _, c in ipairs(M.checks) do
    local ok, err = pcall(c.fn, C)
    if not ok then C.report(c.name, "check", c.name, "crashed", tostring(err)) end
  end
  table.sort(problems, function(a, b)
    if a.check ~= b.check then return a.check < b.check end
    if a.owner_type ~= b.owner_type then return a.owner_type < b.owner_type end
    if a.owner_name ~= b.owner_name then return a.owner_name < b.owner_name end
    return a.field < b.field
  end)
  return problems
end

return M
