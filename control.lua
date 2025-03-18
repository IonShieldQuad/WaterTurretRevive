------------------------------------------------------------------------------------
--               ENTITY DAMAGED (prevent damage from friendly fire)               --                 --
------------------------------------------------------------------------------------
script.on_event(defines.events.on_entity_damaged, function(event)
    --~ log("Entered event script on_entity_damaged for entity " .. event.entity.name)

    local entity = event.entity
    local turret = event.cause
    local damage = event.final_damage_amount


    -- Restore health to entity if it belongs to us
    if turret and turret.name == "water-turret" and     -- We did the damage and
        turret.force == entity.force and                -- we hit something that belongs to us
        entity.health ~= nil then                       -- and has the "health" property.

        entity.health = entity.health + damage

    end
end)

------------------------------------------------------------------------------------
--                    FIND LOCAL VARIABLES THAT ARE USED GLOBALLY                 --
--                              (Thanks to eradicator!)                           --
------------------------------------------------------------------------------------
--~ setmetatable(_ENV,{
  --~ __newindex=function (self,key,value) --locked_global_write
    --~ error('\n\n[ER Global Lock] Forbidden global *write*:\n'
      --~ .. serpent.line{key=key or '<nil>',value=value or '<nil>'}..'\n')
    --~ end,
  --~ __index   =function (self,key) --locked_global_read
    --~ error('\n\n[ER Global Lock] Forbidden global *read*:\n'
      --~ .. serpent.line{key=key or '<nil>'}..'\n')
    --~ end ,
  --~ })
