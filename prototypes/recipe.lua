local WT = require('__WaterTurret__/common')("WaterTurret")
local MOD_PIX = WT.mod_root .. "graphics/"

------------------------------------------------------------------------------------
--                                     Recipe                                     --
------------------------------------------------------------------------------------
local waterrecipe = util.table.deepcopy(data.raw["recipe"]["flamethrower-turret"])
waterrecipe.name = WT.water_turret_name
waterrecipe.localised_name = {"entity-name." .. WT.water_turret_name}
waterrecipe.localised_description = {"entity-description." .. WT.water_turret_name}
--~ waterrecipe.icon = MOD_PIX .. "water-turret-icon.png"
waterrecipe.icons = {
  {icon = MOD_PIX .."turret-icon.png"},
  {icon = MOD_PIX .. "turret-icon-raw.png", tint = WT.water_turret_tint}
}
waterrecipe.icon_size = 64
waterrecipe.icon_mipmaps = 0
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
data:extend({ waterrecipe })


local extinguisherrecipe = util.table.deepcopy(data.raw["recipe"][WT.water_turret_name])
extinguisherrecipe.name = WT.extinguisher_turret_name
extinguisherrecipe.localised_name = WT.hardened_pipes and
  {"entity-name." .. WT.extinguisher_turret_name .. "-hardened"} or
  {"entity-name." .. WT.extinguisher_turret_name}
extinguisherrecipe.localised_description = WT.hardened_pipes and
  {"entity-description." .. WT.extinguisher_turret_name .. "-hardened"} or
  {"entity-description." .. WT.extinguisher_turret_name}
WT.dprint("Hardened pipes: %s\tlocalised name: %s", {WT.hardened_pipes, extinguisherrecipe.localised_name})

extinguisherrecipe.icons = {
  {icon = MOD_PIX .."turret-icon.png"},
  {icon = MOD_PIX .. "turret-icon-raw.png", tint = WT.extinguisher_turret_tint}
}extinguisherrecipe.category = "crafting-with-fluid"

recipe_data = {
  ["name"] = WT.extinguisher_turret_name,
  ["enabled"] = false,
  ["ingredients"] = {
    {WT.water_turret_name, 1},
    {"steel-plate", 15},
    {"iron-gear-wheel", 30},
    {"advanced-circuit", 5},
    {type = "fluid", name = "lubricant", amount = 50},
  },
  ["result"] = WT.extinguisher_turret_name,
  ["result_count"] = 1,
  ["energy_required"] = extinguisherrecipe.energy_required * 3
}

extinguisherrecipe = WT.compile_recipe(extinguisherrecipe, recipe_data)

data:extend({extinguisherrecipe})

--~ WT.dprint("Recipe: %s", {data.raw.recipe[WT.extinguisher_turret_name]})
