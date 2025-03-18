------------------------------------------------------------------------------------
-- In this version, dummies are automatically created when a new fire is spawned.
-- Thus, turrets won't have to search the surface for fires, but can look up
-- dummies directly in the global table. However, for this to work, we must be able
-- to quickly look up the positions of dummies (and possibly fires as well), so we
-- need to update our global tables.
------------------------------------------------------------------------------------

local WT = require('__WaterTurret__/common')("WaterTurret")
local ignore_or_acid = require('__WaterTurret__/ignore_fires')
local old_dummy_type = "simple-entity-with-force"

log("global.fire_dummies table: " .. serpent.block(global.fire_dummies))
-- Make sure we have the global tables initialized!
global = global or {}
global.dummy_positions = global.dummy_positions or {}
global.WT_turrets = global.WT_turrets or {}
--~ global.fire_positions = {}

-- Discard data from old lists
global.fire_dummies = {}
global.fires =  {}

local fire_dummy, fire_entity, x, y

local function make_new_lists(data)
  --~ local dummy_id = data.dummy_id
  --~ local fire_id = data.fire_id
log("data: " .. serpent.block(data))
  local dummy = data.dummy_entity

log("data.dummy_entity: " .. tostring(dummy and dummy.valid))
log("dummy position: " .. serpent.block(dummy.position))

  local x = dummy.position.x or dummy.position[1]
  local y = dummy.position.y or dummy.position[2]
  global.dummy_positions[x] = global.dummy_positions[x] or {}
  global.dummy_positions[x][y] = data.dummy_id

  global.fire_dummies[data.dummy_id] = data
  global.fires[data.fire_id] = data

end

-- Remove fire and dummy data from turret lists!
local cnt = 0
local turret_cnt = 0

for t, turret in pairs(global.WT_turrets) do
  -- Remove invalid turrets
  if not turret.entity and turret.entity.valid then
    global.WT_turrets[t] = nil
    turret_cnt = turret_cnt + 1
  end
  turret.fires = nil
  turret.fire_dummies = nil
  cnt = cnt + 1
end
log(string.format("Removed %g obsolete turret entries.", turret_cnt))
log(string.format("Removed fire and dummy lists from %g turrets.", cnt))

local create, dummies, dummy, fires, fire_id
local acid_types = ignore_or_acid.get_acid()

-- Recreate dummies
for s, surface in pairs(game.surfaces) do
  dummies = surface.find_entities_filtered({
    type = {WT.dummy_type, old_dummy_type},
    name = WT.dummy_list
  }) or {}
--~ log("dummies: " .. serpent.block(dummies))
  -- Remove all dummies
  for d, dummy in pairs(dummies) do
--~ log("d: " .. d .. "\tdummy: " .. dummy.name)
    dummy.destroy()
    cnt = cnt + 1
  end
log("Removed " .. tostring(cnt or 0) .. " dummies.")


  -- Search for fires on all surfaces
  fires = surface.find_entities_filtered({ type = "fire" }) or {}

  for f, fire in ipairs(fires) do
    fire_id = script.register_on_entity_destroyed(fire)

    dummy = surface.create_entity({
      name = acid_types[fire] and WT.acid_dummy_name or WT.fire_dummy_name,
      position = fire.position,
      force = WT.dummy_force,
      raise_built = false,
    })
    if dummy and dummy.valid then
      dummy.active = false
log("dummy position: " .. serpent.block(dummy.position))
      make_new_lists({
        dummy_entity = dummy,
        dummy_id = dummy.unit_number,
        fire_entity = fire,
        fire_id = fire_id
      })
    end
  end

  --~ log("global.fire_dummies: " .. serpent.block(global.fire_dummies))
  --~ log("global.fires: " .. serpent.block(global.fires))
  --~ log("global.dummy_positions: " .. serpent.block(global.dummy_positions))
  --~ log("global.fire_positions: " .. serpent.block(global.fire_positions))
end


-- For quicker look-up, add global table of turrets that should be checked at a certain tick.
global.turret_ticks = {}
local tick
for id, turret in pairs(global.WT_turrets) do
  tick = turret.tick or game.tick
  global.turret_ticks[tick] = global.turret_ticks[tick] or {}
  global.turret_ticks[tick][id] = true
end
