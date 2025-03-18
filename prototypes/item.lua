local WT = require('__WaterTurret__/common')("WaterTurret")

local MOD_PIX = WT.mod_root .. "graphics/"

------------------------------------------------------------------------------------
--                                      Item                                      --
------------------------------------------------------------------------------------
local wateritem = util.table.deepcopy(data.raw["item"]["flamethrower-turret"])
wateritem.name = WT.water_turret_name
wateritem.localised_name = {"entity-name.WT-water-turret"}
wateritem.localised_description = {"entity-description.WT-water-turret"}

wateritem.place_result = WT.water_turret_name
--~ wateritem.icon = MOD_PIX .. "water-turret-icon.png"
wateritem.icons = {
  {icon = MOD_PIX .."turret-icon.png"},
  {icon = MOD_PIX .. "turret-icon-raw.png", tint = WT.water_turret_tint}
}
wateritem.icon_size = 64
wateritem.icon_mipmaps = 0

local extinguisheritem = util.table.deepcopy(data.raw["item"]["flamethrower-turret"])
extinguisheritem.name = WT.extinguisher_turret_name
extinguisheritem.localised_name = WT.hardened_pipes and
  {"entity-name." .. WT.extinguisher_turret_name .. "-hardened"} or
  {"entity-name." .. WT.extinguisher_turret_name}
extinguisheritem.localised_description = WT.hardened_pipes and
  {"entity-description." .. WT.extinguisher_turret_name .. "-hardened"} or
  {"entity-description." .. WT.extinguisher_turret_name}

WT.dprint("Hardened pipes: %s\tlocalised name: %s", {WT.hardened_pipes, extinguisheritem.localised_name})

extinguisheritem.place_result = WT.extinguisher_turret_name
--~ extinguisheritem.icon = MOD_PIX .. "extinguisher-turret-icon.png"
extinguisheritem.icons = {
  {icon = "__base__/graphics/icons/flamethrower-turret.png"},
  {icon = MOD_PIX .. "turret-icon-raw.png", tint = WT.extinguisher_turret_tint}
}
extinguisheritem.icon_size = 64
extinguisheritem.icon_mipmaps = 0

data:extend({ wateritem, extinguisheritem })


------------------------------------------------------------------------------------
--                                      Fluid                                     --
------------------------------------------------------------------------------------

local extinguisherfluid = {
    type = "fluid",
    name = WT.fire_ex_fluid,
    icon = MOD_PIX .. "biomass.png",
    icon_size = 64,
    icons = {
      {
        icon = MOD_PIX .. "biomass.png",
        icon_size = 64,
      }
    },
    default_temperature = 25,
    max_temperature = 100,
    heat_capacity = "1KJ",
    base_color = {r = 0, g = 0, b = 0},
    flow_color = {r = 0.1, g = 1.0, b = 0.0},
    pressure_to_speed_ratio = 0.4,
    flow_to_energy_ratio = 0.59,
    order = "a[fluid]-b[biomass]"
  }
data:extend({ extinguisherfluid })
