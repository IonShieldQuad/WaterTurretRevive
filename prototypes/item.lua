local WT = require('common')()

local MOD_PIX = WT.mod_root .. "/graphics"

------------------------------------------------------------------------------------
--                                      Item                                      --
------------------------------------------------------------------------------------
local wateritem = util.table.deepcopy(data.raw["item"]["flamethrower-turret"])
wateritem.name = WT.water_turret_name
wateritem.place_result = WT.water_turret_name
wateritem.icon = MOD_PIX .. "/waterthrower-turret.png"
wateritem.icon_size = 32
wateritem.icon_mipmaps = 1

data:extend({wateritem})
