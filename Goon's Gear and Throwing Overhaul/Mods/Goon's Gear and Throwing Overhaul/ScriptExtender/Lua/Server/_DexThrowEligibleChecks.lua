-- ==================================== Swedish code ====================================
-- Credit to WtfBengt for this Swedish treat
-- TODO: Implement the checks

-- Ext.Entity.OnCreateDeferred("SpellCastTargetsChangedEvent", function(e)
--     local targets = e.SpellSyncTargeting and e.SpellSyncTargeting.Targets
--     if targets and targets[1] and targets[1].TargetingType == "Throw" then
--         local item = targets[1].Target2 and targets[1].Target2.Target
--         if item then
--             local name = item.DisplayName.Name:Get()
--             local template = item.ServerItem.Template.Name
--             _P("Throwing: " .. name .. " (" .. template .. ")")
--         end
--     end
-- end)

-- And from there you can get item.Data.StatsId for the stats entry, item.Data.Weight for weight even. you can even check if it's the player by checking:
-- local caster = e.SpellCastState.Caster
-- if caster.ServerCharacter.IsPlayer then
--    _P("indubitably, a player")
-- end

-- There's lots more. You can do:
-- Ext.IO.SaveFile("output.json", Ext.DumpExport(item:GetAllComponents()))
-- To see everything available.
