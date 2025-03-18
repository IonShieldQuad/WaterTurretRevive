data:extend({
  -- Startup settings

  ------------------------------------------------------------------------------------
  --                               Turret properties                                --
  ------------------------------------------------------------------------------------
  {   -- Interval for checking turrets (per turret)
    type = "int-setting",
    name = "WT-action-delay",
    setting_type = "startup",
    default_value = 10,
    minimum_value = 5,
    maximum_value = 30,
    order = "WT-[_entity]-[action-delay]"
  },
  {   -- Color of water turrets
    type = "string-setting",
    name = "WT-water-turret-color",
    setting_type = "startup",
    default_value = "40adbf",
    order = "WT-[_entity]-[color]-1"
  },
  {   -- Color of fire extinguisher turrets
    type = "string-setting",
    name = "WT-fire-ex-turret-color",
    setting_type = "startup",
    default_value = "fa0f0f",
    order = "WT-[_entity]-[color]-2"
  },
  {   -- Range of water turrets
    type = "int-setting",
    name = "WT-water-turret-range",
    setting_type = "startup",
    default_value = 50,
    minimum_value = 30,
    maximum_value = 100,
    order = "WT-[_entity]-[attack]-[range]-1"
  },
  {   -- Range of fire extinguisher turrets
    type = "int-setting",
    name = "WT-extinguisher-turret-range",
    setting_type = "startup",
    default_value = 50,
    minimum_value = 30,
    maximum_value = 100,
    order = "WT-[_entity]-[attack]-[range]-2"
  },
  {   -- Speed/pressure/consumption of water turrets
    type = "int-setting",
    name = "WT-water-turret-pressure",
    setting_type = "startup",
    default_value = 2,
    minimum_value = 1,
    maximum_value = 5,
    order = "WT-[_entity]-[pressure]-1"
  },
  {   -- Speed/pressure/consumption of extinguisher turrets
    type = "int-setting",
    name = "WT-extinguisher-turret-pressure",
    setting_type = "startup",
    default_value = 2,
    minimum_value = 1,
    maximum_value = 5,
    order = "WT-[_entity]-[pressure]-1"
  },
  {     -- Turrets can clean up acid splashes (they are based on "fire" prototype!)
    type = "bool-setting",
    name = "WT-turrets_clean_acid",
    setting_type = "startup",
    default_value = true,
    order = "WT-[_entity]-[attack]-[clean_acid]"
  },
  {     -- Consider enemy health when choosing between different targets?
    type = "string-setting",
    name = "WT-preferred-target",
    setting_type = "startup",
    allowed_values = {
      "high-health",
      "low-health",
      "ignore-health"
    },
    default_value = "ignore-health",
    order = "WT-[_entity]-[attack]-[target-by-health]"
  },



  ------------------------------------------------------------------------------------
  --                                     Damage                                     --
  ------------------------------------------------------------------------------------
  {   -- Damage modifier for steam
    type = "int-setting",
    name = "WT-steam-damage-modifier",
    setting_type = "startup",
    default_value = 10,
    minimum_value = 5,
    maximum_value = 20,
    order = "WT-[damage]-a-[steam]"
  },
  {   -- Damage modifier for fire-extinguisher fluids
    type = "int-setting",
    name = "WT-extinguisher-damage-modifier",
    setting_type = "startup",
    default_value = 5,          -- About  80 ticks/fire dummy
    minimum_value = 2,          -- About 400 ticks/fire dummy (like water)
    maximum_value = 10,         -- About  40 ticks/fire dummy
    order = "WT-[damage]-a-[extinguisher-fluid]"
  },
  {   -- Slowdown factor turrets
    type = "int-setting",
    name = "WT-target-slowdown-factor",
    setting_type = "startup",
    default_value = 50,         -- Value of the vanilla slowdown-sticker: 25
    minimum_value = 10,         -- Reduce speed to 10 %
    maximum_value = 100,        -- Targets won't be slowed down at all
    order = "WT-[damage]-b-[slowdown]"
  },



  ------------------------------------------------------------------------------------
  --                                    Immunity                                    --
  ------------------------------------------------------------------------------------
  {   -- Make spawners immune to steam/water damage?
    type = "bool-setting",
    name = "WT-immunity-spawner",
    setting_type = "startup",
    default_value = true,
    order = "WT-[immunity]-[spawners]"
  },
  {   -- Make turrets immune to steam/water damage?
    type = "bool-setting",
    name = "WT-immunity-turret",
    setting_type = "startup",
    default_value = true,
    order = "WT-[immunity]-[worms]"
  },
})


-- Map settings
data:extend({
  {     -- Turrets will slow down friendly targets as well as enemies
    type = "bool-setting",
    name = "WT-friendly_target_slow_down",
    setting_type = "runtime-global",
    default_value = true,
    order = "WT-[misc]-[slow-down-friends]"
  },
  {     -- Water turrets prioritize fire, enemies, or nothing
    type = "string-setting",
    name = "WT-waterturret_preferred_target",
    setting_type = "runtime-global",
    allowed_values = {
      "fire",
      "enemy",
      "default"
    },
    default_value = "default",
    order = "WT-[misc]-[waterturret-target-priority]"

  },
  {   -- Set radius in which fires are extinguished around a fire dummy
    type = "double-setting",
    name = "WT-fire-extinguish-radius",
    setting_type = "runtime-global",
    allowed_values = {1, 1.5, 2, 2.5, 3, 3.5, 4},
    default_value = 2.5,
    order = "WT-[misc]-[fire-extinguishing-radius]"
  },

  -- Debugging
  {   -- Enable extensive logging
    type = "bool-setting",
    name = "WT-debug_to_log",
    setting_type = "runtime-global",
    default_value = false,
    order = "WT-[debugging]-[debug-to-log]"
  },
})


  -- Hardened pipes must be active for this!
if mods["hardened_pipes"] then
  data:extend({
    {   -- Use hardened pipes in recipe?
      type = "bool-setting",
      name = "WT-fire-extinguish-hardened",
      setting_type = "startup",
      default_value = true,
      order = "WT-[_entity]-[recipe-hardened-pipes]"
    }
  })
end

  -- GVV must be active for this!
if mods["gvv"] then
  data:extend({
    {   -- Enable remote interface?
      type = "bool-setting",
      name = "WT-enable_gvv_support",
      setting_type = "startup",
      default_value = false,
      order = "WT-[debugging]-[gvv]"
    }
  })
end
