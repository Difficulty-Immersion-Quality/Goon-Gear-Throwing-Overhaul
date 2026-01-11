local THROW_SPELL = "Throw_Throw"
local TECH_STATUS = "GOON_FINESSE_THROWING_MASTER_TECHNICAL"

-- Helpers
local function HasStatus(character, status)
    return Osi.HasActiveStatus(character, status) == 1
end

local function ApplyTechStatus(character)
    if not HasStatus(character, TECH_STATUS) then
        Osi.ApplyStatus(character, TECH_STATUS, -1.0, 1, character)
    end
end

local function RemoveTechStatus(character)
    if HasStatus(character, TECH_STATUS) then
        Osi.RemoveStatus(character, TECH_STATUS, character)
    end
end

-- Apply when previewing Throw
Ext.Osiris.RegisterListener("StartedPreviewingSpell", 4, "after",
function(caster, spell, isMostPowerful, hasMultipleLevels)
    if spell ~= THROW_SPELL then
        return
    end

    ApplyTechStatus(caster)
end)

-- Remove when Throw is actually used
Ext.Osiris.RegisterListener("UsingSpell", 3, "after",
function(caster, spell, storyActionID)
    if spell ~= THROW_SPELL then
        return
    end

    RemoveTechStatus(caster)
end)

-- Remove when Throw fails
Ext.Osiris.RegisterListener("CastSpellFailed", 5, "after",
function(caster, spell, spellType, spellElement, storyActionID)
    if spell ~= THROW_SPELL then
        return
    end

    RemoveTechStatus(caster)
end)

-- Safety: remove if preview switches to another spell
Ext.Osiris.RegisterListener("StartedPreviewingSpell", 4, "after",
function(caster, spell)
    if spell == THROW_SPELL then
        return
    end

    RemoveTechStatus(caster)
end)
