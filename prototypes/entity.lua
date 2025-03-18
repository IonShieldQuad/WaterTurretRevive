local WT = require('common')()

local MOD_PIX = WT.mod_root .. "/graphics"
local BASE_PIX = "__base__/graphics/entity/flamethrower-turret"

------------------------------------------------------------------------------------
--                              Make new damage type                              --
------------------------------------------------------------------------------------
data:extend({
    {
        type = "damage-type",
        name = WT.steam_damage_name,
        order = "WaterTurret"
    },
    {
        type = "damage-type",
        name = WT.water_damage_name,
        order = "WaterTurret"
    },

})


------------------------------------------------------------------------------------
--                                     Entities                                   --
------------------------------------------------------------------------------------
-- Dummy placed over fire

--~ local fire_dummy = {
    --~ type = WT.fire_dummy_type,
    --~ name = WT.fire_dummy_name,
    --~ picture = {
        --~ filename = mods["_debug"] and MOD_PIX .. "/red_dot.png" or MOD_PIX .. "/blank.png",
        --~ size = 64
    --~ },
    --~ healing_per_tick = 0,
    --max_health = 2,
    --~ max_health = 200,
    --~ -- Resistances will be added later in data-updates.lua, when we know about all defined damage-types
    --resistances = r,
    --~ allow_copy_paste = false,
    --~ --collision_box = {{-0.4, -0.4}, {0.4, 0.4}},
    --~ collision_box = {{0, 0}, {0, 0}},
    --~ flags = {
        --~ "placeable-off-grid",
        --~ "not-repairable",
        --~ "not-on-map",
        --~ "not-blueprintable",
        --~ "not-deconstructable",
        --~ "hidden",
        --~ "not-flammable",
        --~ "no-copy-paste",
        --~ "not-selectable-in-game"
    --~ }
--~ }
local fire_dummy = util.table.deepcopy(data.raw[WT.fire_dummy_type]["defender"])

--~ WT.show("Defender", data.raw[WT.fire_dummy_type]["defender"])
fire_dummy.name = WT.fire_dummy_name

fire_dummy.attack_parameters.ammo_type.action.action_delivery = nil
fire_dummy.attack_parameters.range = 0
fire_dummy.damaged_trigger_effect = {
    damage_type_filters = WT.water_damage_name,
    type = "create-trivial-smoke",
    smoke_name = "soft-fire-smoke",
    color = {r = 0.75, g = 0.75, b = 0.75, a = 0.75}
}
fire_dummy.destroy_action = nil
fire_dummy.dying_explosion = nil
fire_dummy.dying_trigger_effect = nil
fire_dummy.flags = {
    "placeable-off-grid",
    "not-repairable",
    "not-on-map",
    "not-blueprintable",
    "not-deconstructable",
    "hidden",
    "not-flammable",
    "no-copy-paste",
    "not-selectable-in-game"
}
fire_dummy.follows_player = false
fire_dummy.icon = mods["_debug"] and MOD_PIX .. "/red_dot.png" or MOD_PIX .. "/blank.png"
fire_dummy.icon_mipmaps = 4
fire_dummy.icon_size = 64
fire_dummy.max_health = 2
fire_dummy.max_speed = 0
fire_dummy.max_to_charge = 0
fire_dummy.speed = 0
fire_dummy.speed_multiplier_when_out_of_energy = 1
fire_dummy.water_reflection = nil
fire_dummy.working_sound = nil

WT.show("fire pictures", data.raw["fire"]["fire-flame"].pictures)
for _, picture in ipairs({"idle", "shadow_idle", "in_motion", "shadow_in_motion"}) do
    fire_dummy[picture] = {
        frame_count = 1,
        direction_count = 1,
        filename = mods["_debug"] and MOD_PIX .. "/red_dot.png" or MOD_PIX .. "/blank.png",
        size = 64,
        mipmap_count = mods["_debug"] and 4 or 1,
    }

--~ WT.show(picture, fire_dummy[picture])
end

data:extend({ fire_dummy })
--~ WT.dprint("fire-dummy:" .. serpent.block(data.raw[WT.fire_dummy_type][WT.fire_dummy_name]))

-- Water turret
local waterentity = util.table.deepcopy(data.raw[WT.turret_type]["flamethrower-turret"])
waterentity.name = WT.water_turret_name
--~ waterentity.icon = MOD_PIX .. "/waterthrower-turret.png"
--~ waterentity.icon_size = 32
--~ waterentity.icon_mipmaps = 1
waterentity.icon = MOD_PIX .. "/waterthrower-turret_64.png"
waterentity.icon_size = 64
waterentity.icon_mipmaps = 4
waterentity.minable = {mining_time = 0.5, result = WT.water_turret_name}
waterentity.max_health = 900
waterentity.fluid_buffer_size = 200
waterentity.fluid_buffer_input_flow = 250 / 60 / 5 -- 5s to fill the buffer
waterentity.activation_buffer_ratio = 0.25
waterentity.muzzle_animation =
    {
      filename = BASE_PIX .. "/flamethrower-turret-muzzle-fire.png",
      line_length = 8,
      width = 1, -- 17
      height = 1, -- 41
      frame_count = 32,
      axially_symmetrical = false,
      direction_count = 1,
      blend_mode = "additive",
      scale = 0.5,
      shift = {0.015625 * 0.5, -0.546875 * 0.5 + 0.05}
    }
waterentity.muzzle_light = {intensity = 0.7, size = 3}
waterentity.prepare_range = 60
waterentity.shoot_in_prepare_state = false
waterentity.base_picture =
    {
      north =
      {
        layers =
        {
          -- diffuse
          {
            filename = MOD_PIX .. "/waterthrower-turret-base-north.png",
            line_length = 1,
            width = 80,
            height = 96,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(-2, 14),
            hr_version =
            {
              filename = MOD_PIX .. "/hr-waterthrower-turret-base-north.png",
              line_length = 1,
              width = 158,
              height = 196,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(-1, 13),
              scale = 0.5
            }
          },
          -- mask
          {
            filename = BASE_PIX .. "/flamethrower-turret-base-north-mask.png",
            flags = { "mask" },
            line_length = 1,
            width = 36,
            height = 38,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(0, 32),
            apply_runtime_tint = true,
            hr_version =
            {
              filename = BASE_PIX .. "/hr-flamethrower-turret-base-north-mask.png",
              flags = { "mask" },
              line_length = 1,
              width = 74,
              height = 70,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(-1, 33),
              apply_runtime_tint = true,
              scale = 0.5
            }
          },
          -- shadow
          {
            filename = BASE_PIX .. "/flamethrower-turret-base-north-shadow.png",
            draw_as_shadow = true,
            line_length = 1,
            width = 70,
            height = 78,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(2, 14),
            hr_version =
            {
              filename = BASE_PIX .. "/hr-flamethrower-turret-base-north-shadow.png",
              draw_as_shadow = true,
              line_length = 1,
              width = 134,
              height = 152,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(3, 15),
              scale = 0.5
            }
          }
        }
      },
      east =
      {
        layers =
        {
          -- diffuse
          {
            filename = MOD_PIX .. "/waterthrower-turret-base-east.png",
            line_length = 1,
            width = 106,
            height = 72,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(-6, 2),
            hr_version =
            {
              filename = MOD_PIX .. "/hr-waterthrower-turret-base-east.png",
              line_length = 1,
              width = 216,
              height = 146,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(-6, 3),
              scale = 0.5
            }
          },
          -- mask
          {
            filename = BASE_PIX .. "/flamethrower-turret-base-east-mask.png",
            flags = { "mask" },
            apply_runtime_tint = true,
            line_length = 1,
            width = 32,
            height = 42,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(-32, 0),
            hr_version =
            {
              filename = BASE_PIX .. "/hr-flamethrower-turret-base-east-mask.png",
              flags = { "mask" },
              apply_runtime_tint = true,
              line_length = 1,
              width = 66,
              height = 82,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(-33, 1),
              scale = 0.5
            }
          },
          -- shadow
          {
            filename = BASE_PIX .. "/flamethrower-turret-base-east-shadow.png",
            draw_as_shadow = true,
            line_length = 1,
            width = 72,
            height = 46,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(14, 8),
            hr_version =
            {
              filename = BASE_PIX .. "/hr-flamethrower-turret-base-east-shadow.png",
              draw_as_shadow = true,
              line_length = 1,
              width = 144,
              height = 86,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(14, 9),
              scale = 0.5
            }
          }
        }
      },
      south =
      {
        layers =
        {
          -- diffuse
          {
            filename = MOD_PIX .. "/waterthrower-turret-base-south.png",
            line_length = 1,
            width = 64,
            height = 84,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(0, -8),
            hr_version =
            {
              filename = MOD_PIX .. "/hr-waterthrower-turret-base-south.png",
              line_length = 1,
              width = 128,
              height = 166,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(0, -8),
              scale = 0.5
            }
          },
          -- mask
          {
            filename = BASE_PIX .. "/flamethrower-turret-base-south-mask.png",
            flags = { "mask" },
            apply_runtime_tint = true,
            line_length = 1,
            width = 36,
            height = 38,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(0, -32),
            hr_version =
            {
              filename = BASE_PIX .. "/hr-flamethrower-turret-base-south-mask.png",
              flags = { "mask" },
              apply_runtime_tint = true,
              line_length = 1,
              width = 72,
              height = 72,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(0, -31),
              scale = 0.5
            }
          },
          -- shadow
          {
            filename = BASE_PIX .. "/flamethrower-turret-base-south-shadow.png",
            draw_as_shadow = true,
            line_length = 1,
            width = 70,
            height = 52,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(2, 8),
            hr_version =
            {
              filename = BASE_PIX .. "/hr-flamethrower-turret-base-south-shadow.png",
              draw_as_shadow = true,
              line_length = 1,
              width = 134,
              height = 98,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(3, 9),
              scale = 0.5
            }
          }
        }

      },
      west =
      {
        layers =
        {
          -- diffuse
          {
            filename = MOD_PIX .. "/waterthrower-turret-base-west.png",
            line_length = 1,
            width = 100,
            height = 74,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(8, -2),
            hr_version =
            {
              filename = MOD_PIX .. "/hr-waterthrower-turret-base-west.png",
              line_length = 1,
              width = 208,
              height = 144,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(7, -1),
              scale = 0.5
            }
          },
          -- mask
          {
            filename = BASE_PIX .. "/flamethrower-turret-base-west-mask.png",
            flags = { "mask" },
            apply_runtime_tint = true,
            line_length = 1,
            width = 32,
            height = 40,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(32, -2),
            hr_version =
            {
              filename = BASE_PIX .. "/hr-flamethrower-turret-base-west-mask.png",
              flags = { "mask" },
              apply_runtime_tint = true,
              line_length = 1,
              width = 64,
              height = 74,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(32, -1),
              scale = 0.5
            }
          },
          -- shadow
          {
            filename = BASE_PIX .. "/flamethrower-turret-base-west-shadow.png",
            draw_as_shadow = true,
            line_length = 1,
            width = 104,
            height = 44,
            frame_count = 1,
            axially_symmetrical = false,
            direction_count = 1,
            shift = util.by_pixel(14, 4),
            hr_version =
            {
              filename = BASE_PIX .. "/hr-flamethrower-turret-base-west-shadow.png",
              draw_as_shadow = true,
              line_length = 1,
              width = 206,
              height = 88,
              frame_count = 1,
              axially_symmetrical = false,
              direction_count = 1,
              shift = util.by_pixel(15, 4),
              scale = 0.5
            }
          }
        }
      }
    }
waterentity.attack_parameters =
    {
      type = "stream",
      cooldown = 10,
      range = 50, --30
      min_range = 6,

      turn_range = 1.0 / 3.0,
      fire_penalty = 15,

      -- lead_target_for_projectile_speed = 0.2* 0.75 * 1.5, -- this is same as particle horizontal speed of flamethrower fire stream

      fluids =
      {
        {type = "water"},
        -- Moved over to new entity "steam-turret"
        --~ {type = "steam", damage_modifier = 5}
        --~ {type = "steam", damage_modifier = 20}
      },
      fluid_consumption = 1,

      gun_center_shift =
      {
         north = {0,-1.7},
         east = {0.4,-1},
         south = {0,-1},
         west = {-0.4,-1.2}
      },
      gun_barrel_length = 0.4,

      ammo_type =
      {
        category = "flamethrower",
        action =
        {
          type = "direct",
          action_delivery =
          {
            type = "stream",
            stream = "water-stream",
            source_offset = {0.15, -0.5}
          }
        }
      },

      cyclic_sound =
      {
        begin_sound =
        {
          {
            filename = "__base__/sound/fight/flamethrower-start.ogg",
            volume = 0 -- 0.7
          }
        },
        middle_sound =
        {
          {
            filename = "__base__/sound/fight/flamethrower-mid.ogg",
            volume = 0 -- 0.7
          }
        },
        end_sound =
        {
          {
            filename = "__base__/sound/fight/flamethrower-end.ogg",
            volume = 0 -- 0.7
          }
        }
      }
    }
data:extend({waterentity})

local waterstream = util.table.deepcopy(data.raw["stream"]["flamethrower-fire-stream"])
waterstream.name = "water-stream"
waterstream.stream_light = {intensity = 0, size = 0}
waterstream.ground_light = {intensity = 0, size = 0}
waterstream.smoke_sources =
    {
      {
        name = "soft-fire-smoke",
        frequency = 0, --0.25,
        position = {0.0, 0}, -- -0.8},
        starting_frame_deviation = 0
      }
    }
waterstream.action =
    {
      {
        type = "area",
        radius = 2.5,
        -- Next line is needed so that fire dummies (prototype "combat-robot") can actually be attacked!
        ignore_collision_condition = true,
        action_delivery =
        {
          type = "instant",
          target_effects =
          {
            {
              type = "create-sticker",
              --~ sticker = "stun-sticker"
              sticker = "slowdown-sticker"
            },
            {
              type = "damage",
              damage = { amount = 0.005, type = WT.water_damage_name },
              --~ damage = { amount = 2, type = "physical" },
              apply_damage_to_trees = false
            }
          }
        }
      },
    }
waterstream.spine_animation =
    {
      --~ filename = MOD_PIX .. "/flamethrower-fire-stream-spine.png",
      filename = MOD_PIX .. "/waterthrower-stream-spine-water.png",
      blend_mode = "additive",
      --tint = {r = 1, g = 1, b = 1, a = 0.5},
      line_length = 4,
      width = 32,
      height = 18,
      frame_count = 32,
      axially_symmetrical = false,
      direction_count = 1,
      animation_speed = 2,
      shift = {0, 0}
    }
waterstream.shadow =
    {
      filename = BASE_PIX .. "/../acid-projectile/projectile-shadow.png",
      line_length = 5,
      width = 28,
      height = 16,
      frame_count = 33,
      priority = "high",
      shift = {-0.09, 0.395}
    }
waterstream.particle =
    {
      --~ filename = MOD_PIX .. "/flamethrower-explosion.png",
      filename = MOD_PIX .. "/waterthrower-explosion-water.png",
      priority = "extra-high",
      width = 64,
      height = 64,
      frame_count = 32,
      line_length = 8
    }
data:extend({waterstream})


-- Copy to dummy-entity steam-turret
local steamentity = table.deepcopy(data.raw[WT.turret_type][WT.water_turret_name])
local steamstream = table.deepcopy(data.raw["stream"]["water-stream"])

steamentity.name = WT.steam_turret_name
steamentity.localised_name = {"entity-name.WT-water-turret"}
steamentity.localised_description = {"entity-description.WT-water-turret"}
steamentity.placeable_by = {item = WT.water_turret_name, count = 1}
steamentity.attack_parameters.fluids = {
    --~ {type = "steam", damage_modifier = 5}
    --~ {type = "steam", damage_modifier = 20}
    {type = "steam", damage_modifier = settings.startup["WT-steam-damage-modifier"].value}
}
steamentity.attack_parameters.ammo_type = {
    category = "flamethrower",
    action =
    {
        type = "direct",
        action_delivery =
        {
            type = "stream",
            stream = "steam-stream",
            source_offset = {0.15, -0.5}
        }
    }
}

steamstream.name = "steam-stream"
steamstream.spine_animation.filename = MOD_PIX .. "/waterthrower-stream-spine-steam.png"
steamstream.particle.filename = MOD_PIX .. "/waterthrower-explosion-steam.png"
--~ WT.dprint("action: " .. serpent.block(steamstream.action["action_delivery"]))
steamstream.action[1].action_delivery.target_effects[2] = {
              type = "damage",
              damage = { amount = 0.005, type = WT.steam_damage_name },
              apply_damage_to_trees = false
            }
data:extend({steamentity, steamstream})

--~ WT.dprint("Created entity " .. steamentity.name .. " " .. serpent.block(steamentity))
--~ WT.dprint("Created stream " .. steamstream.name .. " " .. serpent.block(steamstream))
--~ WT.dprint("Created entity " .. waterentity.name .. " " .. serpent.block(waterentity))
--~ WT.dprint("Created stream " .. waterstream.name .. " " .. serpent.block(waterstream))
