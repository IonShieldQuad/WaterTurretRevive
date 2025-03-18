log("Entered migration script \"1.0.0.lua\"")

local WT = require('__WaterTurret__/common')("WaterTurret")

--~ log("Global table before migration" .. serpent.block(global))

-- Initialize global tables
global.fires = {}
global.fire_dummies = {}

local dummies

--~ WT.show("game.surfaces", game.surfaces)

-- Remove all fire dummies
for s, surface in pairs(game.surfaces) do

  dummies = surface.find_entities_filtered({
    name = WT.fire_dummy_name,
    type = WT.dummy_type
  })

  WT.dprint("Found %g dummies on surface %s", { table_size(dummies), s })

  for d, dummy in pairs(dummies) do
    dummy.destroy()
  end
end

-- Fix turrets
WT.show("Number of turrets", table_size(global.WT_turrets))
for t, turret in pairs(global.WT_turrets) do
  -- Remove invalid turrets
  if not turret.entity and turret.entity.valid then
    global.WT_turrets[t] = nil
  else

    -- Add an id to the data for easier debugging
    global.WT_turrets[t].id = t

    -- Add range/min_range
    global.WT_turrets[t].min_range = turret.entity.prototype.attack_parameters.min_range
    global.WT_turrets[t].range = turret.entity.prototype.turret_range
    WT.dprint("Added min_range and range to data of %s.", { WT.print_name_id(turret.entity) })

    -- Fix format of bounding boxes of area
    global.WT_turrets[t].area = WT.get_turret_area(turret.entity)
    WT.dprint("Added area to data of %s", { WT.print_name_id(turret.entity) })

      -- Write data of dummies and fires to turret and global lists
    if turret.entity.name ~= WT.steam_turret_name then
      global.WT_turrets[t].fire_dummies = {}
      global.WT_turrets[t].fires = {}

      --~ WT.find_fire(turret.entity)

    -- Remove entity.fires and entity.fire_dummies from steam turrets
    else
      global.WT_turrets[t].fire_dummies = nil
      global.WT_turrets[t].fires = nil
    end

    -- Remove unused value original_position from all turrets
    global.WT_turrets[t].original_position = nil

  end

end
--~ WT.show("Global table after migration", global)
--~ WT.show("Number of turrets", table_size(global.WT_turrets))

WT.dprint("End of migration script \"1.0.0.lua\".")
