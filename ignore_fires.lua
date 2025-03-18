--------------------------------------------------------------------------------------
-- Turns out the acid splashes left on the ground by worms and spitters are         --
-- actually fires!                                                                  --
--------------------------------------------------------------------------------------
--~ log("Entered file 'ignore_fires'")
local fire_functions = {}


-- Define patterns for names of acid splashes. This list will be used to populate the
-- actual ignore/acid lists (based on the setting)
local patterns = {
  -- Vanilla
  "^acid%-splash%-.+$",
  -- Rampant
  "^.+acid%-fire%-rampant$"
}


local function make_list(patterns)
  local list = {}

  local fires = game and game.get_filtered_entity_prototypes({
    { filter = "type", type = "fire" }
  }) or {}

  for fire, _ in pairs(fires) do
    for p, pattern in pairs(patterns) do
      if string.match(fire, pattern) then
        list[fire] = true
        break
      end
    end
  end

  return list
end


fire_functions.get_ignorelist = function()
  return settings.startup["WT-turrets_clean_acid"].value and {} or make_list(patterns)
end

fire_functions.get_acid = function()
  return settings.startup["WT-turrets_clean_acid"].value and make_list(patterns) or {}
end


return fire_functions
