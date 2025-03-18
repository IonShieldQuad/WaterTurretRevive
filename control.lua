log("Entered control.lua")

local WT = require("common")()
local math2d = require("math2d")
local ignore_or_acid = require("ignore_fires")

-- Make remote interface for "Lua API global Variable Viewer (gvv)" by x2605.
-- (https://mods.factorio.com/mod/gvv)
-- If that mod is active, one can inspect the global table of this mod at runtime.

WT.show("script.active_mods['gvv']", script.active_mods["gvv"])
WT.show("WT.debug_gvv", WT.debug_gvv)
if script.active_mods["gvv"] and WT.debug_gvv then
  require("__gvv__.gvv")()
  WT.dprint({"WT-misc.WT-gvv_enabled", script.mod_name, {"mod_name.gvv"}})
end



------------------------------------------------------------------------------------
--                               Fire extinguisher                                --
------------------------------------------------------------------------------------

-- Check if target belongs to us (own force, friends, allies) or is an enemy
-- (returns true or false)
local function is_enemy(turret, target)
  WT.dprint("Entered function is_enemy(%s, %s).", {
    WT.print_name(turret), WT.print_name(target)
  })

  -- Check arguments
  local args = {}
  local msg = nil

  if not (turret and turret.valid) then args[#args +1] = "Turret" end
  if not (target and target.valid) then args[#args +1] = "Target" end
  for _, arg in pairs(args) do msg = msg .. arg .. " is not valid!\n" end
  if msg then error("Wrong arguments for function is_enemy(turret, target):\n" .. msg) end

  -- Check forces of turret and target
  local f = target.force
  local other = (turret.force ~= f)

  -- Return true if target is an enemy of turret
  local ret = (
    other and
    not turret.force.get_friend(f) and
    not turret.force.get_cease_fire(f)
  ) and true or false

  WT.dprint("End of function is_enemy(%s, %s).", {
    WT.print_name(turret), WT.print_name(target)
  })
  return ret
end



-- Check whether fire dummy actually marks fires. (Returns boolean value)
local function dummy_marks_fire(dummy)
  WT.dprint("Entered function dummy_marks_fire(%s) on tick %g.", {
            WT.print_name_id(dummy), game.tick
  })

  local ret = false

  -- Check argument
  if dummy and dummy.valid then
WT.dprint("Dummy is valid!")


    local dummy_id = dummy.unit_number

    local fire_id = global.fire_dummies[dummy_id] and global.fire_dummies[dummy_id].fire_id

    local fire = fire_id and global.fires[fire_id] and
                    global.fires[fire_id].fire_entity and
                    global.fires[fire_id].fire_entity.valid

    if global.fire_dummies[dummy_id] and fire then
      ret = true
    end
  end

  WT.dprint("End of function dummy_marks_fire(%s) on tick %g. (Return: %s)", {
            WT.print_name_id(dummy), game.tick, ret
  })
  return ret
end


-- Search for enemies within the turret's range (returns nil or table of entities).
-- Expects: turret (entity)
local function find_enemies(turret)
  WT.dprint("Entered function find_enemies(%s) on tick %g.", {
    WT.print_name_id(turret), game.tick
  })

  -- Check arguments
  if not (turret and turret.valid) then
    error(serpent.line(turret) .. " is not a valid argument!")
  end

  if not global.WT_turrets[turret.unit_number] then
    WT.dprint("Turret is not in list!")
    return
  end

  -- Return value
  local enemies = {}

  -- Determine search area in the direction the turret is facing
  local area = global.WT_turrets[turret.unit_number].area or WT.get_turret_area(turret)

  enemies = turret.surface.find_entities_filtered{
    type = global.enemy_types,
    position = turret.position,
    radius = global.WT_turrets[turret.unit_number].range
  }
  WT.show("Enemies in radius", enemies)

  -- Compile final list: enemies must be in enemies_area and enemies_radius
  for e, enemy in pairs(enemies) do
    --~ WT.dprint("index: %g\tenemy: %s", { e, enemy })
    if not (
      is_enemy(turret, enemy) and
      math2d.bounding_box.contains_point(area, enemy.position) and
      WT.is_in_range(turret, enemy)
    ) then

      enemies[e] = nil
    end
  end
  WT.dprint("End of function find_enemies(%s) on tick %g (%s enemies found).", {
    WT.print_name_id(turret),
    game.tick,
    (#enemies > 0 and #enemies or "no")
  })
  return enemies
end


------------------------------------------------------------------------------------
-- Remove entry from lists
------------------------------------------------------------------------------------
local function remove_fire_and_dummy(entity_type, id)
WT.dprint("Entered function remove_fire_and_dummy(%s, %g).", { entity_type, id })

  if not (entity_type and type(entity_type) == "string" ) then
    error("Wrong entity (string expected): " .. serpent.line(entity_type))
  elseif not (id and type(id) == "number") then
    error("Wrong ID (number expected): " .. serpent.line(id))
  end

  if entity_type ~= "fire" and entity_type ~= "dummy" then
    WT.dprint("Nothing to do for entity %s!", { entity_type })
    return
  end

  ------------------------------------------------------------------------------------
  local fire, dummy, f_index, d_index

  -- Get entities
  if entity_type == "fire" and global.fires[id] then
WT.dprint("Looking for fire %s", { id })
    f_index     = id
    fire        = global.fires[f_index].fire_entity

    d_index     = f_index and global.fires[f_index].dummy_id
    dummy       = d_index and global.fire_dummies and
                  global.fire_dummies[d_index] and
                  global.fire_dummies[d_index].dummy_entity

  elseif entity_type == "dummy" and global.fire_dummies[id] then
WT.dprint("Looking for dummy %s", { id })
    d_index     = id
    dummy       = global.fire_dummies[d_index].dummy_entity

    f_index     = d_index and global.fire_dummies[d_index].fire_id
    fire        = f_index and global.fires and
                  global.fires[f_index] and
                  global.fires[f_index].fire_entity
  end
WT.dprint("fire[%s]:\t%s", {
  f_index, (fire and fire.valid and fire.name or "NIL")
})

  -- Remove from global tables
  if f_index then
    global.fires[f_index] = nil
WT.dprint("Removed fire " .. f_index .. " from global.fires!")
  end
  if d_index then
    global.fire_dummies[d_index] = nil
WT.dprint("Removed dummy " .. d_index .. " from global.fire_dummies!")
  end

  -- Destroy entities
  if fire and fire.valid then
    fire.destroy()
WT.show("DESTROYED FIRE", f_index)
  end

  if dummy and dummy.valid then
    dummy.destroy()
WT.show("DESTROYED DUMMY", d_index)
  end

--~ WT.dprint("global: " .. serpent.block(global))
WT.dprint("f_index: " .. tostring(f_index) .. "\td_index: " .. tostring(d_index))


  WT.dprint("End of function remove_fire_and_dummy(%s, %g).", { entity_type, id })
  return
end


-- Target enemies or fire
local function target_enemy_or_fire(turret)
  WT.dprint("Entered function target_enemy_or_fire(%s) on tick %s.", { turret, game.tick })
--~ WT.show("Number of turrets", table_size(global.WT_turrets))

  -- Check argument
  if type(turret) == "number" then
    turret = global.WT_turrets[turret] and global.WT_turrets[turret].entity

  elseif (not WT.is_WT_turret(turret)) or turret.name == WT.steam_turret_name then
    WT.show("Not a valid turret", turret)
    return
  end
--~ WT.show("turret", WT.print_name_id(turret))
--~ WT.show("Number of turrets", table_size(global.WT_turrets))

  ------------------------------------------------------------------------------------
  -- Leave early?
  ------------------------------------------------------------------------------------

  -- Return if there is no turret
  if not turret then
    return
  -- Remove invalid turret from list
  elseif not turret.valid then
    WT.dprint("%s is not valid!", { WT.print_name_id(turret) })
    global.WT_turrets[turret.unit_number] = nil
    return
  end

  -- No need to do anything if turret has no ammo!
  local ammo = turret.get_fluid_contents()
  if table_size(ammo) == 0  then
    WT.dprint("Leaving early: No ammo!")
    return
  end


  ------------------------------------------------------------------------------------
  -- Check if turret is busy already
  ------------------------------------------------------------------------------------
  WT.dprint("Check if %s is attacking something.", { WT.print_name_id(turret) })

  local target = turret.shooting_target

WT.show("Current target", WT.print_name_id(target))
  -- Turret attacks something.
  if target and target.valid then
    WT.dprint("%s: shooting at %s.", { WT.print_name_id(turret), WT.print_name_id(target) })

    -- Fire dummy was attacked
    if WT.is_WT_dummy(target) then
WT.show("Turret attacks fire (target)", WT.print_name_id(target))
        -- Remove dummy if it marks no fire!
      if not dummy_marks_fire(target) then
        WT.dprint("No fires at position of %s.", { WT.print_name_id(target) })
        remove_fire_and_dummy("dummy", target.unit_number)
        target.destroy()
      end
    end
  end

  -- Prune lists, as some of the stored dummies/fires may not exist anymore!
  -- Global entries will be removed in remove_fire_and_dummy(), so we just
  -- need to check if these lists still have entries for both dummy and fire.
  -- If at least one is missing, remove dummy and fire from turret data.
    local dummy_list = global.WT_turrets[turret.unit_number].fire_dummies or {}
WT.show("Pruning dummy list", dummy_list)
    for d, dummy in pairs(dummy_list) do
      if not (global.fire_dummies[d] and global.fires[dummy.fire_id]) then
        global.WT_turrets[turret.unit_number].fire_dummies[d] = nil
        global.WT_turrets[turret.unit_number].fires[dummy.fire_id] = nil
WT.dprint("Removed fire %g and dummy %g from turret list.", { dummy.fire_id, d })
      end
    end
WT.show("Pruned dummy list", dummy_list)

    -- All invalid fires should have been removed from the list already. But
    -- let's make sure there isn't any left!
    local fire_list = global.WT_turrets[turret.unit_number].fires or {}
WT.show("Pruning fire list", fire_list)
    for f, fire in pairs(fire_list) do
      if not (global.fires[f] and global.fire_dummies[fire.dummy_id]) then
        remove_fire_and_dummy("fire", f)
        global.WT_turrets[turret.unit_number].fire_dummies[fire.dummy_id] = nil
WT.dprint("Removed dummy %g from turret list.", { fire.dummy_id })
        global.WT_turrets[turret.unit_number].fires[f] = nil
        fire_list[f] = nil
WT.dprint("Removed fire %g from turret list.", { fire.dummy_id })
      end
    end
WT.show("Pruned fire list", fire_list)


    -- Do we know of any fires? Find fires if list is empty!
    if table_size(dummy_list) == 0 then

      -- This will overwrite the turrets list and create dummies!
      WT.find_fire(turret)
WT.show("RETURNED FROM find_fire! global.fires", {global.fires})
    end

  -- The following is only relevant for water turrets!
  if WT.is_WT_turret_name(turret, WT.water_turret_name) then

    -- Prioritize targets according to startup setting
WT.show("Prioritizing attack!\nglobal data", global)
    -- Attack fire!
WT.show("Priority setting", WT.waterturret_priority)
    if WT.waterturret_priority == "fire" then
WT.show("Looking for fire", global.WT_turrets[turret.unit_number].fire_dummies)
      if (not target) or (not WT.is_WT_dummy(target)) then

        for d, dummy in pairs(global.WT_turrets[turret.unit_number].fire_dummies or {}) do
          target = dummy_marks_fire(dummy.dummy_entity) and dummy.dummy_entity
          if target and target.valid then
WT.dprint("Setting %s as new target of %s.", { WT.print_name_id(target), WT.print_name_id(turret) })
            turret.shooting_target = target
            return
          else
WT.dprint("Removing invalid dummy %s.", { WT.print_name_id(turret) })
            remove_fire_and_dummy("dummy", d)
          end
        end
      end
    -- Attack enemies!
    elseif WT.waterturret_priority == "enemy" then
WT.show("Looking for enemies", { WT.print_name_id(turret) })
      if (not target) or WT.is_WT_dummy(target) then
        local enemies = find_enemies(turret)

        for e, enemy in pairs(enemies) do
          if enemy and enemy.valid then
            turret.shooting_target = enemy
            WT.show("Attacking enemy", WT.print_name_id(turret.shooting_target))
            return
          end
        end
      end
    -- Player doesn't care about priority, the game decides which entity to attack!
    else
      WT.dprint("Nothing to do -- automatic targetting is on!")
    end
  end

  -- Turret doesn't have a target. If water turrets prioritize enemies (there aren't
  -- any, or we would have returned already), check if there are fires. Also do this
  -- if the turret is a fire extinguisher turret. Turrets should look for targets
  -- automatically, but giving them an initial target may accelerate the process.
WT.dprint("Target of %s: %s\tDummies in list: %g", {
  WT.print_name_id(turret),
  WT.print_name_id(turret.shooting_target),
  table_size(global.WT_turrets[turret.unit_number].fire_dummies)
})
  if turret and not turret.shooting_target and
      table_size(global.WT_turrets[turret.unit_number].fire_dummies) > 0 then
--~ WT.dprint("Target of %s has %g dummies in list -- looking for fire!", {
  --~ WT.print_name_id(turret), table_size(global.WT_turrets[turret.unit_number].fire_dummies)
--~ })
--~ WT.show("Dummies in list", global.WT_turrets[turret.unit_number].fire_dummies)

    local target = next(global.WT_turrets[turret.unit_number].fire_dummies)
    target = target and global.fire_dummies[target].dummy_entity
    if target and target.valid then
      WT.show("target", WT.print_name_id(target))
      turret.shooting_target = target
    end
  end
  WT.dprint("End of function target_enemy_or_fire(%s) on tick %s.", {
    WT.print_name_id(turret), game.tick
  })
end



















------------------------------------------------------------------------------------
--                                 Event handlers                                 --
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
-- Act on turrets
local function on_tick(event)
  global.enemy_types = global.enemy_types or WT.enemies("get_list")
  global.acids = global.acids or WT.make_name_list(ignore_or_acid.get_acid())
  global.ignore_fires = global.ignore_fires or ignore_or_acid.get_ignorelist()
  global.acids = WT.make_name_list(ignore_or_acid.get_acid())
  global.ignore_fires = ignore_or_acid.get_ignorelist()
--~ WT.show("global.acids", global.acids)
--~ WT.show("global.ignore_fires", global.ignore_fires)

  for id, turret in pairs(global.WT_turrets or {}) do
WT.show("Turret data",  WT.print_name_id(turret.entity))
WT.show("event tick", event.tick)
WT.show("turret.tick", turret.tick)
WT.show("action_delay", WT.action_delay)
    -- Remove invalid turrets from list
    if not (turret.entity and turret.entity.valid) then
      global.WT_turrets[id] = nil
      WT.dprint("Removed turret %s from list because it was not valid.", { id })

      -- Don't act before the tick stored with turret
    elseif event.tick >= turret.tick then
WT.dprint("May act on turret")
WT.dprint("%s is not an extinguisher turret: %s", {turret.entity.name, turret.entity.name ~= WT.extinguisher_turret_name})
      local turret_id = turret.entity.name ~= WT.extinguisher_turret_name and
                        WT.swap_turrets(id) or id
WT.show("Returned from swap_turrets, got turret_id", turret_id)
      if turret_id and global.WT_turrets[turret_id].entity.valid then

        -- Set next action tick
        global.WT_turrets[turret_id].tick = event.tick + WT.action_delay

        -- Create turret tables for fire/dummies if turret can extinguish fire
        if global.WT_turrets[turret_id].entity.name ~= WT.steam_turret_name then
          global.WT_turrets[turret_id].fires = global.WT_turrets[id].fires or {}
          global.WT_turrets[turret_id].fire_dummies = global.WT_turrets[id].fire_dummies or {}
        end

        --~ -- Remove old turret
        --~ if turret_id ~= id then
          --~ WT.show("Removing", WT.print_name_id(global.WT_turrets[id].entity))
          --~ global.WT_turrets[id].entity.destroy({ raise_destroy = true })
        --~ end

        -- Check if we need to find fires or retarget
        if not WT.is_WT_turret_name(global.WT_turrets[turret_id].entity,
                                    WT.steam_turret_name) then
          WT.dprint("Not a steam turret -- going to target_enemy_or_fire!")
          target_enemy_or_fire(turret_id)
        else
          if WT.clean_acid_splashes then
            WT.dprint("Steam turret, looking for acid splashes!")
            WT.find_fire(global.WT_turrets[turret_id].entity)
          else
            WT.dprint("Steam turret -- nothing to do!")
          end
        end

      -- This should never be reached!
      else
        error("Something went wrong! Turret with id ".. tostring(turret_id) ..
              "doesn't exist!\n" .. serpent.block(global.WT_turrets))
      end
    else
WT.dprint("Nothing to do!")
--~ WT.show("global.WT_turrets", global.WT_turrets)
    end
  end
end


------------------------------------------------------------------------------------
-- Extinguish_fire
local function extinguish_fire(entity)
  WT.dprint("Entered function extinguish_fire(%s).", { WT.print_name_id(entity) })

  local id = (entity and type(entity) == "number" and entity) or entity.unit_number
  local dummy = id and global.fire_dummies[id] and global.fire_dummies[id].dummy_entity

  if dummy then
    local fires = dummy.surface.find_entities_filtered{
      type = "fire",
      position = dummy.position,
      radius = WT.fire_dummy_radius,
    }

    if fires then
      for f, fire in pairs(fires) do
        if (not global.ignore_fires[fire.name]) then
          -- Don't need to raise the event because register_on_entity_destroyed is used!
          fire.destroy()
        end
      end
    end
  WT.dprint("Extinguished %g fires around position %s.", { table_size(fires), entity.position })
  end

  WT.dprint("End of function extinguish_fire(%s).", { WT.print_name_id(entity) })
end


------------------------------------------------------------------------------------
-- Remove fire dummies without fire from surfaces
local function remove_fire_dummies_from_surface(event)
  WT.dprint("Entered function remove_fire_dummies_from_surface (tick %g).", { event and event.tick })

  local dummies = {}
  for s, surface in pairs(game.surfaces) do
    dummies = surface.find_entities_filtered({
      name = WT.fire_dummy_name,
      type = WT.dummy_type
    })
WT.dprint("Found %g dummies on surface \"%s\".", {#dummies, s})

    -- Destroy all dummies that are not in our global lists!
    for d, dummy in pairs(dummies) do
      if not global.fire_dummies[dummy.unit_number] then
WT.dprint("%s is not in global dummy list!", { WT.print_name_id(dummy) })
        dummy.destroy()
WT.dprint("Removed %s!", { WT.print_name_id(dummy) })
      end
    end
WT.dprint("Done!")
  end

  WT.dprint("End of function remove_fire_dummies_from_surface (tick %g).", { event and event.tick })
  return
end


------------------------------------------------------------------------------------
-- Remove fire dummies without fire from tables
local function remove_fire_dummies_from_table(event)
  WT.dprint("Entered function remove_fire_dummies_from_table (tick %g).",
            { event and event.tick })

  local dummies = {}
  local cnt

WT.dprint("Found %g dummies in global.fire_dummies.", { table_size(global.fire_dummies) })

  -- Destroy all dummies in our global list that don't mark fires!
  for d, dummy in pairs(global.fire_dummies) do
    if not dummy_marks_fire(dummy) then
WT.dprint("%s is in our table but doesn't mark fire.", { WT.print_name_id(dummy) })
      remove_fire_and_dummy("dummy", dummy.dummy_id)
WT.dprint("Removed %s!", { WT.print_name_id(dummy) })
    end
  end

  WT.dprint("End of function remove_fire_dummies_from_table (tick %g).",
            { event and event.tick })
  return
end


------------------------------------------------------------------------------------
-- on_built
local function on_built(event)
  WT.dprint("Entered function on_built(%s).", { WT.print_name_id(event.created_entity) })

  local entity = event.created_entity or event.entity

  if entity and entity.valid then
    global.WT_turrets[entity.unit_number] = {
      entity = entity,
      tick = event.tick,
      -- Calculate the rectangular area (2*range x range) in the direction the
      -- turret is facing. It will be intersected with the circular area around
      -- the turret (radius = range) when searching for enemies or fires.
      -- (Recalculate when turret is rotated or moved.)
      area = WT.get_turret_area(entity),
      id = entity.unit_number,
      min_range = entity.prototype.attack_parameters.min_range,
      range = entity.prototype.attack_parameters.range
    }
  end

  WT.dprint("End of function on_built(%s).", { WT.print_name_id(event.created_entity) })
end


------------------------------------------------------------------------------------
-- on_remove
local function on_remove(event)
  WT.dprint("Entered function on_remove(%s)", { WT.print_name_id(event.entity) })

  local entity = event.entity

    global.WT_turrets[entity.unit_number] = nil
    WT.show("Removed", WT.print_name_id(entity))

  WT.dprint("End of function on_remove(%s)", { WT.print_name_id(event.entity) })
end


------------------------------------------------------------------------------------
-- on_player_rotated_entity
local function on_player_rotated_entity(event)
  WT.dprint("Entered function on_player_rotated_entity(%s).", { WT.print_name_id(event.entity) })

  local entity = event.entity

  if WT.is_WT_turret(entity) then
    WT.dprint("%s has been moved: recalculating area!", { WT.print_name(entity) })
    global.WT_turrets[entity.unit_number].area = WT.get_turret_area(entity)
  end

  WT.dprint("End of function on_player_rotated_entity(%s).", { WT.print_name_id(event.entity) })
end


------------------------------------------------------------------------------------
-- Picker Dollies: on_moved
local function on_moved(event)
  WT.dprint("Entered function on_moved(%s).", { WT.print_name_id(event.moved_entity) })

  local entity = event.moved_entity

  if WT.is_WT_turret(entity) then
    WT.dprint("%s has been moved: recalculating area!", { WT.print_name(entity) })
    global.WT_turrets[entity.unit_number].area = WT.get_turret_area(entity)
  end

  WT.dprint("End of function on_moved(%s).", { WT.print_name_id(event.moved_entity) })
end


------------------------------------------------------------------------------------
-- Remove slow-down effect for friendly entities
local function remove_slowdown_sticker(event)
  WT.dprint("Entered event script for events.on_trigger_created_entity(%s).", { event }, "line")
  local sticker = event.entity
  local turret = event.source

  --~ WT.show("sticker", WT.print_name_id(sticker))
  --~ WT.show("turret", WT.print_name_id(turret))

  if sticker and sticker.name == WT.slowdown_sticker_name and
      turret and WT.is_WT_turret(turret) then

    local affected = sticker.sticked_to
    local turret_force = turret.force and turret.force.name
  --~ WT.show("Sticker is attached to", affected and affected.name)
  --~ WT.show("Stickers that affect the entity", affected and affected.stickers)
  --~ WT.show("Force of affected entity", affected and affected.force and affected.force.name)
  --~ WT.show("Force of turret", turret and turret.force and turret.force.name)
    if affected and affected.force and affected.force.name == turret_force then
      WT.dprint("%s affected %s with %s -- removing sticker!", {
        WT.print_name_id(turret), WT.print_name_id(affected), sticker.name
      })
      sticker.destroy()
    end
  end

  WT.dprint("End of event script for events.on_trigger_created_entity(%s).", { event }, "line")
end

------------------------------------------------------------------------------------
-- Init
local function init()
  WT.dprint("Entered function init().")
--~ game.check_prototype_translations()

  ------------------------------------------------------------------------------------
  -- Enable debugging if necessary
  WT.debug_in_log = settings.global["WT-debug_to_log"].value

  ------------------------------------------------------------------------------------
  -- Initialize global tables
  global = global or {}
  global.WT_turrets = global.WT_turrets or {}
--~ WT.show("global.WT_turrets", global.WT_turrets)
  global.fires = global.fires or {}
--~ WT.show("global.fires", global.fires)
  global.fire_dummies = global.fire_dummies or {}
--~ WT.show("global.fire_dummies", global.fire_dummies)

  global.acids = WT.make_name_list(ignore_or_acid.get_acid())
  WT.acid_types = ignore_or_acid.get_acid()
  global.enemy_types = WT.enemies("get_list")
  global.enemy_healing = WT.enemy_healing(global.enemy_types)
  global.ignore_fires = ignore_or_acid.get_ignorelist()

WT.show("global.acids", {global.acids})
WT.show("WT.acid_types", {WT.acid_types})
WT.show("global.ignore_fires", {global.ignore_fires})
WT.show("global.enemy_types", {global.enemy_types})
WT.show("global.enemy_healing", {global.enemy_healing})

WT.show("Number of turrets", table_size(global.WT_turrets))

  ------------------------------------------------------------------------------------
  -- Make sure our recipe is enabled if it should be
  for f, force in pairs(game.forces) do
    if force.technologies.turrets.researched then
      force.technologies.turrets.researched = false
      force.technologies.turrets.researched = true
      WT.dprint("Reset technology \"turrets\" for force %s.", { f })
    end
  end
WT.show("Number of turrets", table_size(global.WT_turrets))

  ------------------------------------------------------------------------------------
  -- Forces

  -- Create force for fire dummy if it doesn't exist yet.
  if not game.forces[WT.dummy_force] then
    game.create_force(WT.dummy_force)
  end

WT.show("Number of turrets", table_size(global.WT_turrets))

  -- Check all forces
  for name, force in pairs(game.forces) do
    WT.show(tostring(name), table_size(force.players))
    -- Ignore dummy force
    if force.name ~= WT.dummy_force then
      -- If force has players, make it an enemy of fire dummies
      if table_size(force.players) > 0 then
        force.set_friend(WT.dummy_force, false)
        force.set_cease_fire(WT.dummy_force, false)
      -- Forces without players are neutral to fire dummies
      else
        force.set_friend(WT.dummy_force, false)
        force.set_cease_fire(WT.dummy_force, true)
      end
    end
    WT.show(tostring(name .. " (friend)"), force.get_friend(WT.dummy_force))
    WT.show(tostring(name .. " (cease_fire)"), force.get_cease_fire(WT.dummy_force))
  end
WT.show("Number of turrets", table_size(global.WT_turrets))

  WT.dprint("End of function init().")
end

------------------------------------------------------------------------------------
-- on_load
local function on_load()
  log("Entered function on_load().")

  -- Turn debugging on or off
  WT.debug_in_log = settings.global["WT-debug_to_log"].value

  -- Turn event handler for on_trigger_created_entity (slow-down sticker) on or off
  WT.slow_down_all = settings.global["WT-friendly_target_slow_down"].value
  if WT.slow_down_all then
    log("Unregistering handler for event \"on_trigger_created_entity\"!")
    script.on_event(defines.events.on_trigger_created_entity, nil)
  else
    log("Registering handler for event \"on_trigger_created_entity\"!")
    script.on_event(defines.events.on_trigger_created_entity, remove_slowdown_sticker)
  end

--~ log("Number of turrets: " .. tostring(table_size(global.WT_turrets)))
--~ log("Debug in log: " .. tostring(WT.debug_in_log))
    --~ -- Compatibility with "Picker Dollies" -- add event handler
  --~ if remote.interfaces["PickerDollies"] and
    --~ remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then

    --~ script.on_event(remote.call("PickerDollies", "dolly_moved_entity_id"), on_moved)
    --~ WT.dprint("Registered handler for \"dolly_moved_entity_id\" from \"PickerDollies\".")
  --~ end

  log("End of function on_load().")
end

------------------------------------------------------------------------------------
-- ENTITY DAMAGED

local function on_entity_damaged(event)
  WT.dprint("Entered function on_entity_damaged(%s).", { WT.print_name_id(event.entity) })
--~ WT.show("event.cause.name", event.cause and event.cause.name)
--~ WT.show("event.entity.name", event.entity and event.entity.name)
--~ WT.show("event.entity.unit_number", event.entity and event.entity.unit_number)
WT.show("event.cause", WT.print_name_id(event.cause))
WT.show("event.entity", WT.print_name_id(event.entity))

WT.show("event.entity.health", event.entity and event.entity.health)
WT.show("event.entity.prototype.max_health", event.entity and event.entity.prototype.max_health)
WT.show("event.damage_type.name", event.damage_type and event.damage_type.name)
WT.show("event.final_damage_amount", event.final_damage_amount)
WT.show("event.final_health", event.final_health)
WT.show("event.force", event.force.name)
WT.show("event", event)


  ------------------------------------------------------------------------------------
  -- Fire/acid dummy was attacked -- remove it immediately if there is no fires/acid
  -- in its location!!
  local entity = event.entity
  local turret = event.cause

  if WT.is_WT_dummy(entity) then
    if not dummy_marks_fire(entity) then
      WT.dprint("Removing %s because it marks no fire.", { WT.print_name_id(entity) })
      remove_fire_and_dummy("dummy", entity.unit_number)

      WT.dprint("Done.")
      -- This may be useful if we have another turret that will always and only attack
      -- fires. (Scripted retargetting is needed only for water turrets!)
      if turret and turret.name ~= WT.steam_turret_name then
        target_enemy_or_fire(turret)
      end
    end
    return
  end

  ------------------------------------------------------------------------------------
  -- Return if we didn't do the damage -- shouldn't be necessary because of event
  -- filtering by damage type, but let's just play it safe!
  if not WT.is_WT_turret(turret) then
    WT.dprint("Leaving function on_entity_damaged(%s) early -- damage was caused by %s!", {
              WT.print_name(event.entity), (turret and WT.print_name_id(turret) or "something")
    })
    return
  end

  local ammo = turret.fluidbox[1]
  local damage = event.final_damage_amount
  local damage_type = event.damage_type

  ------------------------------------------------------------------------------------
  -- We damaged something that doesn't belong to us!
--~ WT.show("turret.force", turret.force.name)
--~ WT.show("entity.force", entity.force.name)
  if turret.force ~= entity.force then
    -- Our turrets do additional damage to dummies
    if WT.is_WT_dummy(entity) and
        -- Fire dummies are only vulnerable to water and fire extinguisher fluid
        (
          entity.name == WT.fire_dummy_name and
          (damage_type == WT.water_damage_name or damage_type == WT.fire_ex_damage_name)
        ) or
        -- Acid dummies are also vulnerable against steam
        (
          entity.name == WT.acid_dummy_name and (
            damage_type == WT.water_damage_name or
            damage_type == WT.fire_ex_damage_name or
            damage_type == WT.steam_damage_name
          )
        ) then
      entity.health = entity.health - 0.5
    end

    -- Modify steam damage according to its temperature (base temperature is 165 °C)
    -- Applying increased damage only makes sense if hot steam was used and
    -- if the damaged entity survived
    --~ if ammo and ammo.name == "steam" and ammo.temperature ~= 165 and entity.health > 0 then
    if ammo and ammo.name == "steam" and ammo.temperature ~= 165 then
WT.dprint("Adjusting damage and entity health for steam temperature %g (factor %s).", {
  ammo.temperature, ammo.temperature / 165
})
      -- Temporarily restore health because base damage has already been applied
      entity.health = entity.health + damage
      -- Calculate increased damage
      damage = damage * ammo.temperature / 165
      -- Subtract increased damage from health
      entity.health = entity.health - damage
    end

WT.show("entity.health after adjusting steam damage", entity.health)
    -- Damage from water and steam is so low that it may be instantly restored if
    -- the damaged entity has healing_per_tick. Not only would this cancel out all
    -- damage, it will also prevent turrets to switching to a new target. Therefore,
    -- we cancel out the healing effect.
    entity.health = entity.health - global.enemy_healing[entity.type][entity.name]
  end
WT.show("Entity health: ", entity.health)
  WT.dprint("End of function on_entity_damaged(%s).", { WT.print_name_id(event.entity) })
end


------------------------------------------------------------------------------------
--                           Registering event handlers                           --
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
-- Turret was created (for-loop is needed because filters can't be applied to an
-- array of events!)
for event_name, e in pairs({
  on_built_entity       = defines.events.on_built_entity,
  on_robot_built_entity = defines.events.on_robot_built_entity,
  script_raised_built   = defines.events.script_raised_built,
  script_raised_revive  = defines.events.script_raised_revive
}) do
--~ log("WT.turret_list: " .. serpent.block(WT.turret_list))
--~ log("event_name: " .. serpent.block(event_name) .. "\te: " .. serpent.block(e))
  script.on_event(e, function(event)
    WT.dprint("Entered event script for %s.", { event_name })
    on_built(event)
    WT.dprint("End of event script for %s.", { event_name })
  end, {
    {filter = "type", type = WT.turret_type},
    {filter = "name", name = WT.steam_turret_name, mode = "and"},

    {filter = "type", type = WT.turret_type, mode = "or"},
    {filter = "name", name = WT.water_turret_name, mode = "and"},

    {filter = "type", type = WT.turret_type, mode = "or"},
    {filter = "name", name = WT.extinguisher_turret_name, mode = "and"}
  })
end


------------------------------------------------------------------------------------
-- Turret was rotated
script.on_event(defines.events.on_player_rotated_entity, on_player_rotated_entity)

------------------------------------------------------------------------------------
-- Turret was removed  (for-loop is needed because filters can't be applied to an
-- array of events!)
for event_name, e in pairs({
  on_player_mined_entity        = defines.events.on_player_mined_entity,
  on_robot_mined_entity         = defines.events.on_robot_mined_entity,
  script_raised_destroy         = defines.events.script_raised_destroy,
}) do

  script.on_event(e, function(event)
    WT.dprint("Entered event script for %s.", { event_name })
    on_remove(event)
    WT.dprint("End of event script for %s.", { event_name })
  end, {
    {filter = "type", type = WT.turret_type},
    {filter = "name", name = WT.steam_turret_name, mode = "and"},

    {filter = "type", type = WT.turret_type, mode = "or"},
    {filter = "name", name = WT.water_turret_name, mode = "and"},

    {filter = "type", type = WT.turret_type, mode = "or"},
    {filter = "name", name = WT.extinguisher_turret_name, mode = "and"}
  })
end


------------------------------------------------------------------------------------
-- Entity died
script.on_event(defines.events.on_entity_died, function(event)
  WT.dprint("Entered event script for on_entity_died(%s).", {
    WT.print_name_id(event.entity)
  }, "line")

  local entity = event.entity
  local cause = event.cause
  local damage_type = event.damage_type
--~ WT.show("entity.name", entity and entity.name)
--~ WT.show("cause.name", cause and cause.name)
--~ WT.show("damage_type", damage_type and damage_type.name)

  WT.dprint("%s was killed by %s.", { WT.print_name_id(entity), WT.print_name_id(cause) })

  -- Turret died
  if WT.is_WT_turret(entity) then
    WT.dprint("Turret died!")
    on_remove(event)
    return

  -- Dummy died
  elseif WT.is_WT_dummy(entity) then
    WT.dprint("%s died! Check if there are fires to extinguish around it.", { WT.print_name_id(entity) })
    extinguish_fire(entity)
    remove_fire_and_dummy("dummy", entity.unit_number)
  end

  -- Retarget if a water turret did the killing and a target is prioritized
  if WT.waterturret_priority ~= "default" and cause and cause.valid and
        WT.is_WT_turret_name(cause, WT.water_turret_name) then

    WT.dprint("%s killed %s: Retarget!",
              {WT.print_name_id(cause),
              WT.print_name_id(entity) or "nil",
    })
    target_enemy_or_fire(cause)
  end

  WT.dprint("End of event script for on_entity_died(%s).", { event }, "line")
end, {
    { filter = "type", type = WT.dummy_type },
    { filter = "name", name = WT.fire_dummy_name, mode = "and" },

    { filter = "type", type = WT.turret_type, mode = "or" },
    { filter = "name", name = WT.steam_turret_name, mode = "and" },

    { filter = "type", type = WT.turret_type, mode = "or" },
    { filter = "name", name = WT.water_turret_name, mode = "and" },

    {filter = "type", type = WT.turret_type, mode = "or"},
    {filter = "name", name = WT.extinguisher_turret_name, mode = "and"}

})

------------------------------------------------------------------------------------
-- Fire or fire dummy has been destroyed
script.on_event(defines.events.on_entity_destroyed, function(event)
  WT.dprint("Entered event script for events.on_entity_destroyed(%s).", { event }, "line")

  local id = event.registration_number

  if id and global.fires[id] then
    WT.dprint("Removing fire %s from global list!", { id })
    remove_fire_and_dummy("fire", id)
  end

  WT.dprint("End of event script for events.on_entity_destroyed(%s).", { event }, "line")
end)

--~ ------------------------------------------------------------------------------------
--~ -- Slowdown sticker has been created
--~ if not WT.slow_down_all then
  --~ log("Registering event handler for on_trigger_created_entity." ..
      --~ "(Slow-down stickers applied to friendly entities will be removed!)")
  --~ script.on_event(defines.events.on_trigger_created_entity, remove_slowdown_sticker)
--~ end

------------------------------------------------------------------------------------
-- Initialize game (Also registers handler for entities moved with "Picker Dollies" if it's active)
script.on_init(init)
script.on_configuration_changed(function(event)
WT.dprint("Entered event script for on_configuration_changed(%s)", {event})
  -- Water Turret: Something has changed, maybe a setting?
  local WT_changes = event.mod_changes["WaterTurret"]
WT.show("event.mod_startup_settings_changed", event.mod_startup_settings_changed)
  -- Mod is installed now and was installed before, so a setting must have changed.
  if event.mod_startup_settings_changed then
WT.dprint("Mod setting must have changed")
    -- Read all start-up settings again
    WT.read_startup_settings()

    -- Reset target of turrets that shoot at spawners/turrets if these have been
    -- made immune by the changed settings
    local target
    for t, turret in pairs(global.WT_turrets) do
      target = turret.entity and turret.entity.valid and turret.entity.shooting_target
WT.show("target", WT.print_name_id(target))
      if target and not (target.valid and WT.enemies(target.type)) then
WT.dprint("Current target of %s: %s", { WT.print_name_id(turret.entity), WT.print_name_id(target) })
        turret.entity.shooting_target = {}
WT.dprint("New target of %s: %s", {
  WT.print_name_id(turret.entity),
  WT.print_name_id(turret.entity.shooting_target)
})

      end
    end

  end

  -- Hardened Pipes compatibility: Reset technology effects?
  if event.mod_changes["hardened_pipes"] or event.mod_startup_settings_changed then
    for t, tech in pairs({
        "turrets", "lubricant", "PCHP-hardened-pipes", "WT-fire-ex-turret"
    }) do

      for f, force in pairs(game.forces) do
        -- Only necessary if the tech has been researched already!
        if game.technology_prototypes[tech] and force.technologies[tech].researched then
WT.dprint("Tech exists and has been researched by force %s!", {force.name})
          -- Unresearch tech to remove effects
          force.technologies[tech].researched = false
          -- Check if all prerequisite techs have been researched
          local prereqs_found = true
          for p, prerequisite in pairs (game.technology_prototypes[tech].prerequisites) do
            if not force.technologies[p].researched then
WT.dprint("Prerequisite has not been researched yet by force %s!", {force.name})
              prereqs_found = false
              break
            end
          end
          -- Enable tech again if all requirements are met
          if prereqs_found then
WT.dprint("Reenabling tech %s for force %s!", {tech, force.name})
            force.technologies[tech].researched = true
          end
        end
      end
    end
  end

  -- Initialize game!
  init(event)
  WT.dprint("End of event script for on_configuration_changed(%s)", {event})
end)

for event_name, event in pairs({
  on_player_created              = defines.events.on_player_created,
  on_player_joined_game          = defines.events.on_player_joined_game,
  on_player_changed_force        = defines.events.on_player_changed_force,
  on_player_removed              = defines.events.on_player_removed,
  on_force_created               = defines.events.on_force_created,
  --~ on_runtime_mod_setting_changed = defines.events.on_runtime_mod_setting_changed
}) do

  script.on_event(event, function(event_args)
    WT.dprint("Entered event script for %s ( %s).", { event_name, event_args })
    init(event_args)
    WT.dprint("End of event script for %s ( %s).", { event_name, event_args })
  end)
end

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  WT.dprint("Entered event script for on_runtime_mod_setting_changed (%s).", { event })

  if event.setting_type == "runtime-global" then
    -- Turrets will slow down friendly targets as well as enemies
    if event.setting == "WT-friendly_target_slow_down" then
      WT.slow_down_all = settings.global["WT-friendly_target_slow_down"].value
      if WT.slow_down_all then
        WT.dprint("Unregistering handler for event \"on_trigger_created_entity\"!")
        script.on_event(defines.events.on_trigger_created_entity, nil)
      else
        WT.dprint("Registering handler for event \"on_trigger_created_entity\"!")
        script.on_event(defines.events.on_trigger_created_entity, remove_slowdown_sticker)
      end

    -- Water turrets prioritize fire, enemies, or nothing
    elseif event.setting == "WT-waterturret_preferred_target" then
      WT.waterturret_priority = settings.global["WT-waterturret_preferred_target"].value
      WT.show("Set waterturret_priority", WT.waterturret_priority)

    -- Set radius in which fires are extinguished around a fire dummy
    elseif event.setting == "WT-friendly_target_slow_down" then
      WT.fire_dummy_radius = settings.global["WT-fire-extinguish-radius"].value
      WT.show("Set fire_dummy_radius", WT.fire_dummy_radius)

    -- Enable logging of debugging output
    elseif event.setting == "WT-debug_to_log" then
      local setting = settings.global["WT-debug_to_log"].value
      WT.show("Set debug_in_log", setting)
      WT.debug_in_log = setting
    end

  end
  init(event)

  WT.dprint("End of event script for on_runtime_mod_setting_changed (%s).", { event })
end)

script.on_load(on_load)

------------------------------------------------------------------------------------
-- Entity damaged
script.on_event(defines.events.on_entity_damaged, on_entity_damaged, {
  -- Entities were damaged by our turrets. As most entities with health are immune
  -- to our damage, this will be an enemy or another entity intended to be damaged.
  -- (Check __WaterTurret__/prototypes_with_health.lua for prototypes listed in
  -- prototypes_with_health.attack and prototypes_with_health.vulnerable!)

  -- Increase steam damage for enemy entities; check if fire dummies mark fire!
  {filter = "final-damage-amount", comparison = ">", value = 0},
  {filter = "damage-type", type = WT.steam_damage_name, mode = "and"},

  {filter = "final-damage-amount", comparison = ">", value = 0, mode = "or"},
  {filter = "damage-type", type = WT.water_damage_name, mode = "and"},

  {filter = "final-damage-amount", comparison = ">", value = 0, mode = "or"},
  {filter = "damage-type", type = WT.fire_ex_damage_name, mode = "and"},
})

------------------------------------------------------------------------------------
-- Check turrets on every tick (will bail out immediately if turret's registered action tick
-- is in the future)
script.on_event(defines.events.on_tick, on_tick)

------------------------------------------------------------------------------------
-- Remove fire dummies that mark no fire from surfaces every 30 minutes
script.on_nth_tick(30*60*60, function(event)
  WT.dprint("Entered event script for on_nth_tick(%s).", { event }, "line")
  remove_fire_dummies_from_surface(event)
  WT.dprint("End of event script for on_nth_tick(%s).", { event }, "line")
end)


------------------------------------------------------------------------------------
-- Remove fire dummies that marking no fire from global table every 20 minutes
script.on_nth_tick(20*60*60, function(event)
  WT.dprint("Entered event script for on_nth_tick(%s).", { event }, "line")
  remove_fire_dummies_from_table(event)
  WT.dprint("End of event script for on_nth_tick(%s).", { event }, "line")
end)


------------------------------------------------------------------------------------
--                          Compatibility with other mods                         --
------------------------------------------------------------------------------------

-- Add event handler for "Picker Dollies"
if  remote.interfaces["PickerDollies"] and
    remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then

  script.on_event(remote.call("PickerDollies", "dolly_moved_entity_id"), function()
    WT.dprint("Entered event script for dolly_moved_entity_id(%s).", { event }, "line")
    on_moved(event)
    WT.dprint("End of event script for dolly_moved_entity_id(%s).", { event }, "line")
  end)

  log("Registered handler for \"dolly_moved_entity_id\" from \"PickerDollies\".")
end


------------------------------------------------------------------------------------
--                    FIND LOCAL VARIABLES THAT ARE USED GLOBALLY                 --
--                              (Thanks to eradicator!)                           --
------------------------------------------------------------------------------------
setmetatable(_ENV,{
  __newindex = function (self,key,value) --locked_global_write
    error('\n\n[ER Global Lock] Forbidden global *write*:\n'
      .. serpent.line{key = key or '<nil>',value = value or '<nil>'} .. '\n')
  end,
  __index   =function (self,key) --locked_global_read
    if not (key == "game" or key == "mods") then
      error('\n\n[ER Global Lock] Forbidden global *read*:\n'
        .. serpent.line{key = key or '<nil>'} .. '\n')
    end
  end ,
})
