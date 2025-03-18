-- We need to simulate a fire on the dummy position so it doesn't look awkward if
-- turrets shoot at a dummy that apparently doesn't mark fire (could be in the
-- second phase, where the flame isn't visible anymore)

--~ log("fire-flame: " .. serpent.block(data.raw.fire["fire-flame"]))

local animation_name = "WT-fire-dummy-animation"

if not game then
  if not script then
    local layers = {}
    for l, layer in pairs(data.raw.fire["fire-flame"].pictures) do
      if layer.frame_count == 32 then
        layers[#layers + 1] = layer
      end
    end
    --~ log("Found " .. #layers .. " layers: " .. serpent.block(layers))
    data:extend({
      {
        type = "animation",
        name = animation_name,
        layers = layers
      }
    })
    --~ log("Made animation: " .. serpent.block(data.raw.animation[animation_name]))
  end
end

--~ local anim = data.raw.animation[animation_name]
return animation_name
