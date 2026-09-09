-- Runtime side of the platform start: one home platform per force, every player kept on it,
-- and the freeplay scenario told to skip its intro and crash site. Satisfies DESIGN.md
-- section 10. State lives in storage.home, force name to home platform index.

local HOME_NAME = "Home"
local HOME_PLANET = "nauvis"
local STARTER_PACK = "space-platform-starter-pack"
local START_TECHNOLOGY = "space-platform"
local SPAWN_SEARCH_RADIUS = 20

local function starting_items()
  return {pistol = 1, ["firearm-magazine"] = 10}
end

-- Freeplay registers its interface at file load, so it is visible from on_init. Any of its
-- functions may be missing on an older scenario; each call checks for its own name.
local function call_freeplay(name, ...)
  local interface = remote.interfaces.freeplay
  if interface and interface[name] then
    remote.call("freeplay", name, ...)
  end
end

local function configure_freeplay()
  call_freeplay("set_skip_intro", true)
  call_freeplay("set_disable_crashsite", true)
  call_freeplay("set_created_items", starting_items())
  call_freeplay("set_respawn_items", starting_items())
end

local function unlock_platforms(force)
  force.unlock_space_platforms()
  force.unlock_travel_to_space_platforms = true
  local technology = force.technologies[START_TECHNOLOGY]
  if technology then
    technology.researched = true
  end
end

-- The stored index is the first choice. A platform renamed or recreated by hand is found by
-- name over force.platforms, which is keyed by platform index.
local function find_home(force)
  local index = storage.home[force.name]
  if index then
    local platform = force.platforms[index]
    if platform and platform.valid then
      return platform
    end
  end
  for _, platform in pairs(force.platforms) do
    if platform.valid and platform.name == HOME_NAME then
      storage.home[force.name] = platform.index
      return platform
    end
  end
  return nil
end

local function ensure_home(force)
  if not (force and force.valid) then
    return nil
  end
  storage.home = storage.home or {}
  unlock_platforms(force)
  local platform = find_home(force)
  if platform then
    return platform
  end
  platform = force.create_space_platform
  {
    name = HOME_NAME,
    planet = HOME_PLANET,
    starter_pack = STARTER_PACK
  }
  if not (platform and platform.valid) then
    return nil
  end
  platform.apply_starter_pack()
  storage.home[force.name] = platform.index
  return platform
end

local function home_surface(force)
  local platform = ensure_home(force)
  if not platform then
    return nil
  end
  local surface = platform.surface
  if surface and surface.valid then
    return surface
  end
  return nil
end

local function send_home(player)
  if not (player and player.valid) then
    return
  end
  local surface = home_surface(player.force)
  if not surface then
    return
  end
  local position = surface.find_non_colliding_position("character", {0, 0}, SPAWN_SEARCH_RADIUS, 1) or {0, 0}
  local character = player.character
  if character and character.valid then
    character.teleport(position, surface)
  else
    player.teleport(position, surface)
  end
end

-- player.surface follows remote view; physical_surface is where the body is.
local function body_is_on_planet(player)
  local surface = player.physical_surface
  return surface ~= nil and surface.valid and surface.name == HOME_PLANET
end

local function player_from_event(event)
  local player = game.get_player(event.player_index)
  if player and player.valid then
    return player
  end
  return nil
end

script.on_init(function()
  storage.home = {}
  configure_freeplay()
  ensure_home(game.forces.player)
  for _, player in pairs(game.players) do
    send_home(player)
  end
end)

-- A save that gains the mod, or changes version, must still have a home platform per force
-- with players, and nobody left standing on the planet.
script.on_configuration_changed(function()
  storage.home = storage.home or {}
  configure_freeplay()
  ensure_home(game.forces.player)
  for _, player in pairs(game.players) do
    if player.valid then
      ensure_home(player.force)
      if body_is_on_planet(player) then
        send_home(player)
      end
    end
  end
end)

script.on_event(defines.events.on_force_created, function(event)
  ensure_home(event.force)
end)

script.on_event(defines.events.on_player_created, function(event)
  send_home(player_from_event(event))
end)

script.on_event(defines.events.on_player_respawned, function(event)
  send_home(player_from_event(event))
end)

script.on_event(defines.events.on_player_changed_surface, function(event)
  local player = player_from_event(event)
  if player and body_is_on_planet(player) then
    send_home(player)
  end
end)

remote.add_interface("space-only-space-age",
{
  get_home_platform_index = function(force_name)
    local force = game.forces[force_name or "player"]
    if not (force and force.valid and storage.home) then
      return nil
    end
    return storage.home[force.name]
  end
})
