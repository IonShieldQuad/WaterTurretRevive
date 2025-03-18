return function(mod_name)
  local common = {}

  -- Set mod name and base path
  common.mod_name = common.mod_name or "WaterTurret"
  common.mod_root = "__" .. common.mod_name .. "__"
  common.action_delay = settings.startup["WT-action-delay"].value * 60

  common.turret_type = "fluid-turret"
  common.steam_turret_name = "WT-steam-turret"
  common.water_turret_name = "WT-water-turret"

  common.steam_damage_name = "WT-steam"
  common.water_damage_name = "WT-water"

  common.fire_dummy_name = "fire-dummy"
  --~ common.fire_dummy_type = "simple-entity-with-force"
  common.fire_dummy_type = "combat-robot"
  common.fire_dummy_force = "WT-fire-dummy"
  -- Extinguish fires in that radius around dummy if dummy dies
  common.fire_dummy_radius = settings.startup["WT-fire-extinguish-radius"].value

  -- Just define these to avoid tests not working because of a typo!
  common.spawner_type = "unit-spawner"
  common.worm_type = "turret"
  common.artillery_type = "artillery-turret"

  ------------------------------------------------------------------------------------
  --                                   Debugging                                    --
  ------------------------------------------------------------------------------------
  common.debug_in_log = false
  --~ common.debug_in_game = false
  -- Hide "mods" from eradicator's "Find (undefined) local vars in global context" code
  -- at the end of the control file.
  if (game and game.active_mods["_debug"]) or (not game and mods and mods["_debug"]) then
    common.debug_in_log = true
  end
--~ log("debug_in_log: " .. tostring(common.debug_in_log))
  -- Output debugging text
  common.dprint = function(msg)
    if common.debug_in_log then
      log({"", msg})
    end
  end

  -- Simple helper to show values
  common.show = function(desc, term)
    common.dprint(tostring(desc) .. ": " .. serpent.block(term))
  end

  -- Print "entityname (id)"
  common.print_name_id = function(entity)

    return tostring(entity and entity.valid and entity.name) .. " (" ..
           tostring(entity and entity.valid and entity.unit_number) .. ")"
  end

  -- Print "entityname"
  common.print_name = function(entity)
    return tostring(entity and entity.valid and entity.name)
  end

  ------------------------------------------------------------------------------------
  --                                     Recipe                                     --
  ------------------------------------------------------------------------------------
  common.compile_recipe = function(recipe, recipe_data_normal, recipe_data_expensive)

    -- recipe is required
    --~ if recipe and recipe.valid then
    if recipe then
      recipe.normal = recipe.normal or {}
      recipe.expensive = recipe.expensive or {}
    else
      error("Recipe " .. tostring(recipe) .. " is not valid!")
    end
    -- recipe_data is required, recipe_data_expensive is optional
    if not recipe_data_normal then
      error("Missing recipe data!")
    end


    for k, v in pairs(recipe_data_normal) do
        --~ recipe[k] = v
        --~ recipe.normal[k] = v
        if k ~= "ingredients" then
          recipe[k] = v
          recipe.normal[k] = v
        else
          recipe[k] = {}
          recipe.normal[k] = {}
          for _, i in pairs(recipe_data_normal.ingredients) do
--~ common.dprint("item: " .. tostring(i[1]) .. "\tamount: " .. tostring(i[2]))
            table.insert(recipe[k], {["type"] = "item", ["name"] = i[1], ["amount"] = i[2]})
            table.insert(recipe.normal[k], {["type"] = "item", ["name"] = i[1], ["amount"] = i[2]})
          end
        end
    end

    -- recipe_data_expensive may be complete or partial recipe data, so we copy
    -- the normal recipe and replace the settings explicitly passed to this function.
    recipe.expensive = table.deepcopy(recipe.normal)

    -- Replace settings that are given in recipe_data_expensive
    if recipe_data_expensive then
      for k, v in pairs(recipe_data_expensive) do
        recipe.expensive[k] = v
      end
    -- If recipe_data_expensive doesn't exist, double the amount of all ingredients
    else
--~ common.dprint ("expensive ingredients: " .. serpent.block(recipe.expensive.ingredients))
      for k, v in pairs(recipe.expensive.ingredients) do
        v.amount = v.amount * 2
      end
    end

    return recipe
  end

  ------------------------------------------------------------------------------------
  --             Check if unlock technology already contains our recipe             --
  ------------------------------------------------------------------------------------
  common.unlocked_already = function(tech, recipe)

    if not (tech) then
      error("Technology " .. tostring(tech) .. " is not valid!")
    elseif not (recipe) then
      error("\"" .. tostring(recipe) .. "\" is not a valid recipe!")
    end


    local defined = false

    for _, effect in pairs(tech.effects) do
      if effect.type == "unlock-recipe" and effect.recipe == recipe then
        common.dprint(recipe .. " is already unlocked by technology \"" .. tech .. "\"!")
        defined = true
        break
      end
    end

    return defined
  end



  ------------------------------------------------------------------------------------
  --         Get the rectangular area in the direction the turret is facing         --
  ------------------------------------------------------------------------------------
  common.get_turret_area = function(turret)
      common.dprint("Entered function get_turret_area(" .. common.print_name_id(turret) .. ").")

      local x, y = turret.position.x, turret.position.y
  common.show("x", x)
  common.show("y", y)
  common.show("direction", turret.direction)
      local left_top, right_bottom
      local range = turret.prototype.attack_parameters.range
      local min_range = turret.prototype.attack_parameters.min_range
  common.show("range", range)

      -- Turret facing North
      if turret.direction == defines.direction.north then
          left_top = {x - range, y - range}
          right_bottom = {x  + range, y-min_range}
      -- Turret facing South
      elseif turret.direction == defines.direction.south then
          left_top = {x - range, y+min_range}
          right_bottom = {x  + range, y + range}
      -- Turret facing East
      elseif turret.direction == defines.direction.east then
          left_top = {x + min_range, y - range}
          right_bottom = {x  + range, y + range}
      -- Turret facing West
      elseif turret.direction == defines.direction.west then
          left_top = {x - range, y - range}
          right_bottom = {x - min_range, y + range}
      -- This should never be reached!
      else
          error("Something unexpected has happened: " .. common.print_name_id(turret) ..
                  " has direction " .. tostring(turret.direction) ..
                  ", which is not a cardinal direction.")
      end

      common.dprint("End of function get_turret_area(" .. common.print_name_id(turret) ..
                  "): Return " .. serpent.block({left_top, right_bottom}) .. ".")
  --~ if global.WT_turrets[turret.unit_number].render_area then
    --~ rendering.destroy(global.WT_turrets[turret.unit_number].render_area)
  --~ end
  --~ global.WT_turrets[turret.unit_number].render_area = rendering.draw_rectangle{left_top = left_top, right_bottom = right_bottom, color = {r = 0.5, a = 0.001}, filled = true, surface = turret.surface}
  --~ rendering.draw_circle{color= {g = 0.5, a=0.001}, radius = range, filled = true, target = turret.position, surface = turret.surface}
      return {left_top, right_bottom}
  end


  ------------------------------------------------------------------------------------
  --        Exchange steam and water turrets if fluidbox contains wrong ammo        --
  --        (Returns nil for invalid turrets, or id (unit_number) of turret)        --
  ------------------------------------------------------------------------------------
  common.swap_turrets = function(id)
    common.dprint("Entered function swap_turrets(" .. tostring(id) .. ").")

    ------------------------------------------------------------------------------------
    --                               Bail out on errors                               --
    ------------------------------------------------------------------------------------
    -- Invalid argument
    if (not id) or (type(id) ~= "number") then
      error("\"" .. tostring(id) .. "\" is not a valid turret id!")
    -- No turret stored with this ID
    elseif not global.WT_turrets[id] then
      error("No turret with id " .. tostring(id) .. " has been registered!")
    -- Invalid turret
    elseif not global.WT_turrets[id].entity.valid then
      global.WT_turrets[id] = nil
      common.dprint("Removed expired id " .. tostring(id) .. " from list of registered turrets.")
      return nil
    end

    ------------------------------------------------------------------------------------
    --                                Local definitions                               --
    ------------------------------------------------------------------------------------

common.dprint ("Looking for turret with id " .. tostring(id))
common.dprint(serpent.block(global.WT_turrets[id]))

    local turret = global.WT_turrets[id].entity
    local new_turret = nil
    local input = nil
    local output = nil
    local neighbours = turret.neighbours and turret.neighbours[1] or nil
    local t_fluid = turret.get_fluid_contents()
    -- Set neighbours to nil if it's an empty table -- otherwise tests won't work!
    if neighbours and table_size(neighbours) == 0 then neighbours = nil end

--~ common.dprint ("Neighbours of " .. turret.name .. ": " .. serpent.block(neighbours))

--~ common.dprint("t_fluid: " .. serpent.block(t_fluid))
--~ common.dprint("t_fluid.steam and turret.name == \"" .. common.water_turret_name .. "\": " .. serpent.block(t_fluid.steam and turret.name == common.water_turret_name and true or false))
--~ common.dprint("t_fluid.water and turret.name == \"".. common.steam_turret_name .. "\": " .. serpent.block(t_fluid.water and turret.name == common.steam_turret_name and true or false))
    ------------------------------------------------------------------------------------
    --                        Leave early if everything is OK                         --
    ------------------------------------------------------------------------------------
    -- Turret is not connected to a pipe -- wait until it is hooked up and useful!
    if not neighbours then
      common.dprint("Leave early: " .. common.print_name_id(turret) .. " is not hooked up!")
      return id
    end

    -- Turret is connected, now get contents of adjacent pipes!
    input = neighbours[1] and neighbours[1].get_fluid_contents()
    output = neighbours[2] and neighbours[2].get_fluid_contents()
    -- Set vars to nil if they contain empty tables -- otherwise tests won't work!
    if input and table_size(input) == 0 then input = nil end
    if output and table_size(output) == 0 then output = nil end
--~ common.show("input", input)
--~ common.show("output", output)

    -- Pipes are empty -- wait until they are filled up!
    if not input and not output then
      common.dprint("Leave early: " .. common.print_name_id(turret) .. " is connected to empty pipes!")
      return id
    -- Pipes contain some other fluid than steam or water
    elseif (input and not (input.steam or input.water)) or
       (output and not (output.steam or output.water)) then
      common.dprint("Leave early: Neighbours of " .. common.print_name_id(turret) ..
                      " contain wrong fluid(s)! (Input: " ..
                      tostring((input and input.steam and input.steam.name) or
                               (input and input.water and input.water.name)) ..
                               ", output: " ..
                      tostring((output and output.steam and output.steam.name) or
                               (output and output.water and output.water.name)) .. ")")
      return id
    -- Connected to 2 pipes with different fluids
    elseif (input and output) and
            ((input.steam and output.water) or
             (input.water and output.steam)) then
      common.dprint("Leave early: Neighbours of " .. common.print_name_id(turret)..
                      " contain different fluids! (Input: " ..
                      tostring(input and input.steam and "steam" or
                               input and input.water and "water") .. ", output: " ..
                      tostring(output and output.steam and "steam" or
                               output and output.water and "water") .. ")")
      return id
    end
    -- Connected to 2 pipes filled with same fluid as turret
    -- (Both pipes contain the same fluid, so we need to check just one pipe!)
    if (input and output) and (
            (turret.name == common.steam_turret_name and t_fluid.steam and input.steam) or
            (turret.name == common.water_turret_name and t_fluid.water and input.water)
          ) then
      common.dprint("Leave early: " .. common.print_name_id(turret) .. " is connected to " ..
                    tostring(input.steam and "steam" or input.water and "water"))
      return id
    -- Connected to 1 pipe filled with same fluid as turret
    elseif (
            (input and input.steam and turret.name == common.steam_turret_name) or
            (input and input.water and turret.name == common.water_turret_name)
          ) or (
            (output and output.steam and turret.name == common.steam_turret_name) or
            (output and output.water and turret.name == common.water_turret_name)
          ) then
      common.dprint("Leave early: " .. common.print_name_id(turret) .. " is connected to " ..
                    tostring(
                      (input and input.steam and "steam") or
                      (input and input.water and "water") or
                      (output and output.steam and "steam") or
                      (output and output.water and "water")
                    )
      )
      return id
    end


    ------------------------------------------------------------------------------------
    --                       We should replace the old turret!                        --
    ------------------------------------------------------------------------------------
    -- Replace steam turret?
    if  turret.name == common.steam_turret_name and
        (input and input.water) or
        (output and output.water) then
      new_turret = common.water_turret_name
    -- Replace water turret?
    elseif turret.name == common.water_turret_name and
           (input and input.steam) or
           (output and output.steam) then
      new_turret = common.steam_turret_name
    -- This should never be called!
    else
      error("Something is wrong with " .. tostring(turret and turret.name or "unknown turret") ..
            "!\nInput: " .. serpent.block(input) .. "\nOutput: " .. serpent.block(output))
    end
    common.dprint("Replacing " .. common.print_name_id(turret) .. " with " .. new_turret .. "!")


    -- Swap entities
    if new_turret then
      --~ common.dprint("Creating new " .. new_turret .. " to replace: " ..
                      --~ turret.name .. " (" .. turret.unit_number .. ").")
      --~ -- Store connecting entities (pipes and other enitities with fluidbox, including water turrets)
      --~ local connectors = neighbours
      local properties = {
        ["surface"] = turret.surface,
        ["position"] = turret.position,
        ["direction"] = turret.direction,
        ["force"] = turret.force,
        ["target"] = turret.shooting_target,
        ["damage_dealt"] = turret.damage_dealt,
        ["kills"] = turret.kills,
      }
      --~ common.show("Stored properties of " .. common.print_name_id(turret), properties)
      -- Remove old turret
      turret.destroy()
      -- Create new turret
      local t = properties.surface.create_entity{
        name = new_turret,
        position = properties.position,
        direction = properties.direction,
        force = properties.force,
        target = properties.shooting_target,
      }
      if t then
        common.dprint("Created " .. t.name .. " (" .. t.unit_number .. ").")
        -- Register new turret (new turrets will keep "tick", "enemies", and "fire_dummies"
        -- of the turret they replaced)
        global.WT_turrets[t.unit_number] = {
          ["entity"] = t,
          ["tick"] = global.WT_turrets[id].tick,
          ["area"] = global.WT_turrets[id].area,
          --~ ["original_position"] = global.WT_turrets[id].original_position,
        }
        -- Transfer damage dealt by this turret and number of kills to new turret
        global.WT_turrets[t.unit_number].entity.damage_dealt = properties.damage_dealt
        global.WT_turrets[t.unit_number].entity.kills = properties.kills
  common.dprint("global.WT_turrets[" .. tostring(t.unit_number) .. "].entity: " ..
                  serpent.block(global.WT_turrets[t.unit_number].entity))
  --~ common.show("New turret list: ", global.WT_turrets)
      else
        error("Something bad happened: Couldn't create " .. new_turret .. "!")
      end

      turret = global.WT_turrets[t.unit_number].entity

    end
    common.dprint("Contents of " .. turret.name .. ": " .. serpent.block(t_fluid))
    common.dprint("End of function swap_turrets(" .. tostring(id) .. ").")

    return turret.unit_number
  end

  ------------------------------------------------------------------------------------
  --                                       EOF                                      --
  ------------------------------------------------------------------------------------
  return common
end
