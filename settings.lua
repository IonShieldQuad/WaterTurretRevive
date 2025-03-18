data:extend({
-- Startup settings
    {   -- Interval for checking turrets (per turret)
        type = "int-setting",
        name = "WT-action-delay",
        setting_type = "startup",
        default_value = 10,
        minimum_value = 5,
        maximum_value = 30,
        order = "[WT_a-a]"
    },
    {   -- Damage modifier for steam
        type = "int-setting",
        name = "WT-steam-damage-modifier",
        setting_type = "startup",
        default_value = 10,
        minimum_value = 5,
        maximum_value = 20,
        order = "[WT_b-a]"
    },
    {   -- Make spawners immune to steam/water damage?
        type = "bool-setting",
        name = "WT-immunity-spawner",
        setting_type = "startup",
        default_value = true,
        order = "[WT_c-a]"
    },
    {   -- Make turrets immune to steam/water damage?
        type = "bool-setting",
        name = "WT-immunity-turret",
        setting_type = "startup",
        default_value = true,
        order = "[WT_c-b]"
    },
    {   -- Set radius in which fires are extinguished around a fire dummy
        type = "double-setting",
        name = "WT-fire-extinguish-radius",
        setting_type = "startup",
        allowed_values = {1, 1.5, 2, 2.5, 3, 3.5, 4},
        default_value = 2.5,
        order = "[WT_d-a]"
    }
})
