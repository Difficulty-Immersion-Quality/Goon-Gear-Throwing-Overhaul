-- ==================================== Stinky canned fish code ====================================
-- Credit to WtfBengt for this Swedish treat

local function ReplaceItemReturnToOwner()
    for _, statType in ipairs({"StatusData", "PassiveData"}) do
        for _, statName in ipairs(Ext.Stats.GetStats(statType)) do
            local success, result = xpcall(function()
                local stat = Ext.Stats.Get(statName)
                if stat and stat.Boosts and stat.Boosts:find("ItemReturnToOwner%(%)") then
                    stat.Boosts = stat.Boosts:gsub("ItemReturnToOwner%(%)", "Tag(RETURNING_ITEM)")
                end
            end, debug.traceback)
            
            if not success then
                _P("Surströmming", statName, ":\n", result)
            end
        end
    end
    
    for _, statType in ipairs({"Weapon", "Armor"}) do
        for _, statName in ipairs(Ext.Stats.GetStats(statType)) do
            local success, result = xpcall(function()
                local stat = Ext.Stats.Get(statName)
                if stat and stat.DefaultBoosts and stat.DefaultBoosts:find("ItemReturnToOwner%(%)") then
                    stat.DefaultBoosts = stat.DefaultBoosts:gsub("ItemReturnToOwner%(%)", "Tag(RETURNING_ITEM)")
                end
            end, debug.traceback)
            
            if not success then
                _P("Surströmming", statName, ":\n", result)
            end
        end
    end
end

Ext.Events.StatsLoaded:Subscribe(ReplaceItemReturnToOwner)