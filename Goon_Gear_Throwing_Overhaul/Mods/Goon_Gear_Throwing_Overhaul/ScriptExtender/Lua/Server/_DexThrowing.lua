local THROW_SPELL = "Throw_Throw"
local TECHNICAL_STATUS = "GOON_FINESSE_THROWING_MASTER_TECHNICAL"

-- Helpers
local function HasStatus(character, status)
    return Osi.HasActiveStatus(character, status) == 1
end

local function ApplyTechnicalStatus(character)
    if not HasStatus(character, TECHNICAL_STATUS) then
        Osi.ApplyStatus(character, TECHNICAL_STATUS, -1.0, 1, character)
    end
end

local function RemoveTechnicalStatus(character)
    if HasStatus(character, TECHNICAL_STATUS) then
        Osi.RemoveStatus(character, TECHNICAL_STATUS, character)
    end
end

-- Apply when previewing Throw
Ext.Osiris.RegisterListener("StartedPreviewingSpell", 4, "after",
function(caster, spell, isMostPowerful, hasMultipleLevels)
    if spell ~= THROW_SPELL then
        return
    end
    ApplyTechnicalStatus(caster)
end)

-- Remove when Throw is committed
Ext.Osiris.RegisterListener("CastSpell", 5, "after",
function(caster, spell, spellType, spellElement, storyActionID)
    if spell ~= THROW_SPELL then
        return
    end
    RemoveTechnicalStatus(caster)
end)

-- Remove when Throw fails
Ext.Osiris.RegisterListener("CastSpellFailed", 5, "after",
function(caster, spell, spellType, spellElement, storyActionID)
    if spell ~= THROW_SPELL then
        return
    end
    RemoveTechnicalStatus(caster)
end)

-- Safety: remove if preview switches to another spell
Ext.Osiris.RegisterListener("StartedPreviewingSpell", 4, "after",
function(caster, spell)
    if spell == THROW_SPELL then
        return
    end
    RemoveTechnicalStatus(caster)
end)
