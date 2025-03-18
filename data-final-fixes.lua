local WT = require('__WaterTurret__/common')("WaterTurret")
local prototypes_with_health = require('prototypes_with_health')

------------------------------------------------------------------------------------
--                               Utility functions                                --
------------------------------------------------------------------------------------
-- Returns true if the "damage" isn't in "tab" yet
local function can_insert(tab, damage)
  WT.dprint("Entered function can_insert(%s, %s)", { tab, damage }, "line")
  if not (tab and damage) then
    error("Missing argument! (Table: " .. tostring(not tab and "missing") ..
          ", Damage: " .. tostring(not damage and "missing"))
  end

  local insert = true
  for k, v in pairs(tab) do
    if v.type == damage then
      insert = false
      break
    end
  end

  WT.dprint("End of function can_insert(%s, %s). Return: %s", { tab, damage, insert }, "line")
  return insert
end

-- Change resistance against "damage" if it's already among the resistancies
local function replace_resistance(tab, damage)
  WT.dprint("Entered function replace_resistance(%s, %s)", { tab, damage }, "line")

  if not (tab and damage) then
    error("Missing argument! (Table: " .. tostring(not tab and "missing") ..
          ", Damage: " .. tostring(not damage and "missing"))
  end

  for k, v in pairs(tab) do
    if v.type == damage.type then
      tab[k] = damage
    end
  end

  WT.dprint("End of function replace_resistance(%s, %s)", { tab, damage }, "line")
end


------------------------------------------------------------------------------------
--                         Get default_trigger_target_mask                        --
------------------------------------------------------------------------------------
local default_target_masks =
  data.raw["utility-constants"].default.default_trigger_target_mask_by_type


------------------------------------------------------------------------------------
--      Add immunity to all entities with health that we never want to hurt.      --
--     Entities that are vulnerable to splash damage will get no resistances.     --
--       Entities that we want to attack will be marked as targets later on.      --
------------------------------------------------------------------------------------
local resistances = {
  { type = WT.steam_damage_name, decrease = 0, percent = 100 },
  { type = WT.water_damage_name, decrease = 0, percent = 100 },
  { type = WT.fire_ex_damage_name, decrease = 0, percent = 100 },
}

-- Check all prototypes of entities_with_health
for _, prototypes in ipairs(prototypes_with_health.immune) do

  -- Don't give immunity to entities that should take damage!
  if not (prototypes_with_health.vulnerable[prototypes] or
            --~ prototypes_with_health.attack[prototypes]) then
            prototypes_with_health.attack(prototypes)) then
    for p, prototype in pairs(data.raw[prototypes]) do
WT.dprint("Type: %s\tPrototype: %s", { prototypes, prototype.name })
      -- Ignore dummies
      if not (WT.dummy_types[prototype] and prototypes == WT.dummy_type) then
        prototype["resistances"] = prototype["resistances"] or {}
        for r, resistance in ipairs(resistances) do
          -- Add resistance if entity has no resistance against this damage yet!
          if can_insert(prototype["resistances"], resistance.type) then
            table.insert(prototype.resistances, resistance)
          -- Replace resistance if prototype already is resistant to this damage type!
          else
            replace_resistance(prototype.resistances, resistance)
          end
        end
      end
--~ WT.show("Resistances", prototype.resistances)
    end
  end

end


------------------------------------------------------------------------------------
--  Allow attacking mobile targets (this may include spawners and worms/turrets)  --
------------------------------------------------------------------------------------
--~ resistances = {
  --~ WT.steam_damage_name,
  --~ WT.water_damage_name,
  --~-- WT.fire_ex_damage_name,
--~ }
--~ local vulnerability, decrease

for e, entitytype in pairs(prototypes_with_health.attack("get_list")) do
WT.dprint("entitytype: %s\te: %s", { entitytype, e })
  -- Mark prototype class as target
  default_target_masks[entitytype] = default_target_masks[entitytype] or { "common" }
  table.insert(default_target_masks[entitytype], WT.trigger_target_mobile)

  --~ -- Make individual prototypes vulnerable: The turrets do only small damage per
  --~ -- tick, and if the target's healing_per_tick is higher than the damage, turrets
  --~ -- won't have a chance to ever defeat it. So let's cancel out healing_per_tick!
  --~ for p, prototype in pairs(data.raw[entitytype]) do
--~ WT.dprint("prototype: %s\tp: %s", { prototype.name, p })
    --~ for r, resistance in ipairs(resistances) do
      --~ -- Define a negative resistance
      --~ decrease = prototype.healing_per_tick
--~ WT.show("decrease", decrease)
      --~ decrease = decrease and (
                                --~ (decrease > 0 and decrease * -1) or
                                --~ (decrease < 0 and decrease) or
                                --~ 0
                              --~ ) or 0
      --~ if decrease < 0 then
        --~ decrease = decrease - 0.5
      --~ end

      --~ vulnerability = {
        --~ type = resistance,
        --~ decrease = decrease,
        --~ percent = 0
      --~ }
--~ WT.show("vulnerability", vulnerability)
      --~ -- Add resistance if entity has no resistance against this damage yet!
      --~ prototype.resistances = prototype.resistances or {}
      --~ if decrease and decrease ~= 0 then
        --~ if can_insert(prototype.resistances, vulnerability.type) then
          --~ table.insert(prototype.resistances, vulnerability)
  --~ WT.dprint("Added vulnerability to %s!", prototype.name)
        --~ -- Replace resistance if prototype already is resistant to this damage type!
        --~ else
          --~ replace_resistance(prototype.resistances, vulnerability)
  --~ WT.dprint("Changed resistance to %s for %s!", { vulnerability, prototype.name })
        --~ end
      --~ end
    --~ end
    --~ WT.dprint("Prototype %s:\tResistances: %s", { prototype.name, prototype.resistances })
  --~ end
end


------------------------------------------------------------------------------------
--                         Set resistances for fire dummy                         --
------------------------------------------------------------------------------------
resistances = {}
-- Make this a table so we're ready if we ever need to exclude more damage types
-- from the immunity list
local vulnerable = {
  --~ [WT.water_damage_name] = {decrease = -0.5, percent = 0},
  --~ [WT.fire_ex_damage_name] = {decrease = -0.5, percent = 0},
  [WT.water_damage_name] = true,
  [WT.fire_ex_damage_name] = true,
}

WT.show("Damage types known to the game", data.raw["damage-type"])
-- Look for every damage type known to the game to list of resistances
for _, damage in pairs(data.raw["damage-type"]) do
  -- Add damage type unless we want the entity to be vulnerable to it
  if not vulnerable[damage.name] then
    resistances[#resistances + 1] = {
      type = damage.name,
      decrease = 0,
      percent = 100
    }
  else
    resistances[#resistances + 1] = {
      type = damage.name,
      --~ decrease = vulnerable[damage.name].decrease or 0,
      --~ percent = vulnerable[damage.name].percent or 0
      decrease = 0,
      percent = 0
    }
  end
end
--~ WT.show("Resistances of \"fire-dummy\"", resistances)
data.raw[WT.dummy_type][WT.fire_dummy_name].resistances = resistances

WT.dprint("Final fire dummy: %s", { data.raw[WT.dummy_type][WT.fire_dummy_name] })
------------------------------------------------------------------------------------
--                         Set resistances for acid dummy                         --
------------------------------------------------------------------------------------
for r, resistance in pairs(resistances) do
  if resistance.type == WT.steam_damage_name then
    resistance.decrease = -0.5
    resistance.percent = 0
  end
end
WT.show("Resistances for acid dummy", resistances)
data.raw[WT.dummy_type][WT.acid_dummy_name].resistances = resistances
WT.dprint("Final acid dummy: %s", { data.raw[WT.dummy_type][WT.acid_dummy_name] })


------------------------------------------------------------------------------------
--                        Define attack targets for turrets                       --
------------------------------------------------------------------------------------
data.raw[WT.turret_type][WT.steam_turret_name].attack_target_mask = {
  WT.trigger_target_mobile,
  WT.trigger_target_acid_dummy,
}
data.raw[WT.turret_type][WT.water_turret_name].attack_target_mask = {
  WT.trigger_target_mobile,
  WT.trigger_target_fire_dummy,
  WT.trigger_target_acid_dummy,
}
data.raw[WT.turret_type][WT.extinguisher_turret_name].attack_target_mask = {
  WT.trigger_target_fire_dummy,
  WT.trigger_target_acid_dummy,
}

for turret, _ in pairs(WT.turret_names) do
  WT.dprint("%s ignore_target_mask: ",
            { turret, data.raw[WT.turret_type][turret].ignore_target_mask })
end

-- Remove our dummies from attack_target_masks of other turrets
for _, name in pairs({ "artillery", "ammo", "electric", "fluid" }) do
  for t, turret in pairs(data.raw[name .. "-turret"]) do
    if not (turret.type == WT.turret_type and WT.turret_names[turret.name]) then
      turret.ignore_target_mask = turret.ignore_target_mask or {}
      table.insert(turret.ignore_target_mask, WT.trigger_target_fire_dummy)
      table.insert(turret.ignore_target_mask, WT.trigger_target_acid_dummy)
    end
WT.dprint("Turret: %s\tignore targets: %s", { turret.name, turret.ignore_target_mask or {} })
  end
end



------------------------------------------------------------------------------------
--                          Compatibility with other mods                         --
------------------------------------------------------------------------------------

-- "Amator Phasma's Coal & Steam"
require('mod_compatibility.apm_power')

-- "Hardened pipes"
require('mod_compatibility.hardened_pipes')

---TESTIMG
--~ WT.show("Fluids", data.raw.fluid)

--~ WT.dprint("Fire prototypes:")
--~ for k, v in pairs(data.raw.fire) do
--~ WT.dprint("%s: %s", {k, v.name})
--~ end

--~ log("Waterturret: " .. serpent.block(data.raw[WT.turret_type][WT.water_turret_name]))
--~ for k, v in pairs(data.raw[WT.turret_type][WT.water_turret_name]) do
--~ WT.dprint("%s: %s", {k, v})
--~ end
--~ log("extinguisher turret remnants: " .. serpent.block(data.raw.corpse[WT.extinguisher_turret_name .. "-remnants"]))
--~ log("flamethrower turret remnants: " .. serpent.block(data.raw.corpse["flamethrower-turret-remnants"]))
--~ log("water turret remnants: " .. serpent.block(data.raw.corpse[WT.water_turret_name .. "-remnants"]))
