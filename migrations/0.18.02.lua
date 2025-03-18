local WT = require('common')()

------------------------------------------------------------------------------------
-- Register all existing water turrets

WT.dprint("Entered migration script \"0.18.02.lua\"")

WT.show("global.WT_turrets", global.WT_turrets)
if not global.WT_turrets or table_size(global.WT_turrets) == 0 then

  ------------------------------------------------------------------------------------
  --                              Register all turrets                              --
  ------------------------------------------------------------------------------------
  global = global or {}
  global.WT_turrets = global.WT_turrets or {}

  local turrets = {}
  local tick = game.tick

  for name, surface in pairs(game.surfaces) do
    -- Find all entities on surface
    for _, ent in ipairs({WT.steam_turret_name, WT.water_turret_name}) do
      WT.dprint("Searching for " .. ent .. " on surface " .. name .. ".")

      turrets = surface.find_entities_filtered{
        type = WT.turret_type,
        name = ent
      }
----~ WT.dprint ("Found turrets: " .. serpent.block(turrets))

      -- Register turrets
      for _, turret in pairs(turrets) do
        global.WT_turrets[turret.unit_number] = {
          -- Store the entity.
          ["entity"] = turret,
          --~ -- We keep a list of the fire dummies in reach so we will always continue
          --~ -- extinguishing one fire before moving on to the next one.
          --~ ["fire_dummies"] = {},
          -- Calculate the rectangular area (2*range x range) in the direction the
          -- turret is facing. It will be intersected with the circular area around
          -- the turret (radius = range) when searching for enemies or fires.
          -- (Recalculate when turret is rotated or moved.)
          ["area"] = WT.get_turret_area(turret),
          --~ -- We store the original position so we can detect if the turret has been
          --~ -- moved (e.g. with the "Picker Dollies" mod), and recalculate the area
          --~ -- it attacks.
          --~ ["original_position"] = turret.position,
          -- We act a random number of ticks from now. The factor 36000 is used
          -- to spread initialization of turrets that existed before version
          -- 0.18.2 of this mod over a period of 10 minutes.
          ["tick"] = tick + math.floor(math.random() * 36000),
          --~ ["tick"] = tick + math.floor(math.random() * 360),
        }

        WT.dprint(_ .. ": Registered " .. WT.print_name_id(turret) .. ".")
      end
      WT.dprint("Done. (" .. ent .. ")")
    end
  end
WT.dprint ("global: " .. serpent.block(global))
end

-- Check that turrets can use the fluid they're hooked up to, exchange them otherwise.
for id, turret in pairs(global.WT_turrets) do
    local new_id = WT.swap_turrets(id)

    if new_id and global.WT_turrets[new_id].entity.valid then
        if new_id == id then
            WT.dprint("Kept " .. WT.print_name_id(turret.entity) .. ".")
        else
            WT.dprint("Replaced turret " .. tostring(id) .. " with " ..
                        WT.print_name_id(global.WT_turrets[new_id].entity) .. ".")

            -- Remove old turret from list
            global.WT_turrets[id] = nil
        end
    end
end

WT.dprint("Swapped turrets. Checking ticks!")
for id, turret in pairs(global.WT_turrets) do
    if turret.entity and turret.entity.valid then
        WT.dprint("ID " .. tostring(id) .. ": " .. WT.print_name(turret.entity) ..
                " acting on tick " .. turret.tick)
    else
        WT.dprint("ID " .. tostring(id) .. ": Turret doesn't exist!")
    end
end

-- Create force for fire dummy
if not game.forces[WT.fire_dummy_force] then
    game.create_force(WT.fire_dummy_force)
end

WT.dprint("End of migration script \"0.18.02.lua\"")
