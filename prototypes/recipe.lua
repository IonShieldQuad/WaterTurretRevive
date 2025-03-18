local WT = require('common')()

------------------------------------------------------------------------------------
--                                     Recipe                                     --
------------------------------------------------------------------------------------
local waterrecipe = util.table.deepcopy(data.raw["recipe"]["flamethrower-turret"])
local recipe_data = {
  ["name"] = WT.water_turret_name,
  ["enabled"] = false,
  ["ingredients"] = {
    {"iron-plate", 30},
    {"iron-gear-wheel", 15},
    {"pipe", 10},
    {"offshore-pump", 1}
  },
  ["result"] = WT.water_turret_name,
  ["result_count"] = 1,
  ["energy_required"] = waterrecipe.energy_required
}

waterrecipe = WT.compile_recipe(waterrecipe, recipe_data)

data:extend({waterrecipe})

--~ WT.dprint("Recipe: " .. serpent.block(data.raw.recipe[WT.water_turret_name]) )
