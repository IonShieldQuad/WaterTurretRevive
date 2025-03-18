local WT = require('common')()


require('prototypes.item')
require('prototypes.recipe')
require('prototypes.entity')


-- Set unlock recipe
local unlock_tech = data.raw.technology["turrets"]

if not WT.unlocked_already(unlock_tech, WT.water_turret_name) then

  table.insert(unlock_tech.effects, { ["recipe"] = WT.water_turret_name, ["type"] = "unlock-recipe" })
  WT.dprint("Added recipe for \"" .. WT.water_turret_name .. "\" to recipes unlocked by technology \"turrets\"!")

end
