local WT = require('common')()


------------------------------------------------------------------------------------
--                         Set resistances for fire dummy                         --
------------------------------------------------------------------------------------
local resistances = {}
-- Make this a table so we're ready if we ever need to exclude more damage types
-- from the immunity list
local vulnerable = {WT.water_damage_name}

WT.dprint("Damage types known to the game: " .. serpent.block(data.raw["damage-type"]))
--~ -- Look for every damage type known to the game to list of resistances
for _, damage in pairs(data.raw["damage-type"]) do
  for _, vul in ipairs(vulnerable) do
    -- Add damage type unless we want the entity to be vulnerable to it
    if damage.name ~= vul then
      resistances[#resistances + 1] = {
        type = damage.name,
        decrease = 0,
        percent = 100
      }
    end
  end
end
WT.show("Resistances of \"fire-dummy\"", resistances)
data.raw[WT.fire_dummy_type][WT.fire_dummy_name].resistances = {{
        type = "fire",
        decrease = 0,
        percent = 100
      }}

WT.dprint("Final fire dummy: " .. serpent.block(data.raw[WT.fire_dummy_type][WT.fire_dummy_name]))

-- Returns true if the "damage" isn't in "table" yet
local function can_insert(table, damage)
  WT.dprint("Entered function can_insert(" .. tostring(table) .. ", " .. serpent.block(damage) .. ")")
  if not (table and damage) then
    error("Missing argument! (Table: " .. tostring(not table and "missing") ..
          ", Damage: " .. tostring(not damage and "missing"))
  end

  local insert = true
  for k, v in pairs(table) do
    if v.type == damage then
      insert = false
      break
    end
  end

  WT.show("Return", insert)
  WT.dprint("End of function can_insert(" .. tostring(table) .. ", " .. serpent.block(damage) .. ")")
  return insert
end

-- Change resistance against "damage" if it's already among the resistancies
local function replace_resistance(table, damage)
  WT.dprint("Entered function replace_resistance(" .. tostring(table) .. ", " .. serpent.block(damage) .. ")")

  if not (table and damage) then
    error("Missing argument! (Table: " .. tostring(not table and "missing") ..
          ", Damage: " .. tostring(not damage and "missing"))
  end

  for k, v in pairs(table) do
    if v.type == damage.type then
      table[k] = damage
    end
  end

  WT.dprint("End of function replace_resistance(" .. tostring(table) .. ", " .. serpent.block(damage) .. ")")
end

--~ ------------------------------------------------------------------------------------
--~ --                Make spawners and turrets immune to our damages                 --
--~ ------------------------------------------------------------------------------------
--~ for _, damage in ipairs({"WT-steam", "WT-water"}) do
  --~ local r = {
        --~ type = damage,
        --~ decrease = 0,
        --~ percent = 100
  --~ }

--~ WT.dprint(serpent.block(r))
  --~ -- Spawners
  --~ if settings.startup["WT-immunity-spawner"].value then

    --~ for _, spawner in pairs(data.raw[WT.spawner_type]) do
      --~ -- Add resistance to damage if
      --~ if can_insert(spawner.resistances, damage) then
        --~ table.insert(spawner.resistances, r)
      --~ else
        --~ replace_resistance(spawner.resistances, r)
      --~ end
      --WT.show("Resistances of " .. tostring(spawner and spawner.name), spawner.resistances)
    --~ end
  --~ end

  --~ -- Turrets
  --~ if settings.startup["WT-immunity-turret"].value then
    --~ for _, turret_type in pairs({WT.worm_type, WT.artillery_type}) do
      --~ for _, turret in pairs(data.raw[turret_type]) do
        --~ if can_insert(turret.resistances, damage) then
          --~ table.insert(turret.resistances, r)
        --~ else
          --~ replace_resistance(turret.resistances, r)
        --~ end
      --WT.show("Resistances of " .. tostring(turret and turret.name), turret.resistances)
      --~ end
    --~ end
  --~ end
--~ end


------------------------------------------------------------------------------------
--                 Set time_to_live of fire dummy to that of fire                 --
------------------------------------------------------------------------------------
local time_to_live = 0
for _, fire in pairs(data.raw["fire"]) do
WT.show("fire.name", fire.name)
WT.show("fire.maximum_lifetime", fire.maximum_lifetime)
  local t = fire.maximum_lifetime or 0
  time_to_live = ( t > time_to_live) and t or time_to_live
end
data.raw[WT.fire_dummy_type][WT.fire_dummy_name].time_to_live = time_to_live

WT.show("Fire dummy", data.raw[WT.fire_dummy_type][WT.fire_dummy_name])


------------------------------------------------------------------------------------
--                          Compatibility with other mods                         --
------------------------------------------------------------------------------------

-- "Amator Phasma's Coal & Steam"
require('mod_compatibility.apm_power')


log("Recipe Water turret: " .. serpent.block(data.raw.recipe[WT.water_turret_name]))
