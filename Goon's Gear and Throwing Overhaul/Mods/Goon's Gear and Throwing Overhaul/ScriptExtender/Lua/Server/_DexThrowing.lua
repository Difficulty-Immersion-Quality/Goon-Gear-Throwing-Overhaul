-- TODO: A more NPC friendly implementation
-- TODO: Find things that need blacklisting
-- TODO: Finesse weapon and light object restrictions
-- (keep such restrictions consistent with "MartialArts_DextrousUnarmedAttacks" too, because Larian just lets it fly all DEX bby)

local THROWING_TECHNICAL_STATUS = "GOON_DEXTERITY_THROWING_TECHNICAL"

-- Blacklist of throw spells to ignore
local THROW_SPELL_BLACKLIST = {
    [""] = true,
    -- Add more spell names here as needed
}

-- ==================================== Helpers
local function HasStatus(character, status)
    return Osi.HasActiveStatus(character, status) == 1
end

local function HasMonkWeaponAttackOverride(character)
    return Osi.HasPassive(character, "MartialArts_DextrousUnarmedAttacks") == 1
end

local function ApplyTechnicalStatus(character)
    if not HasStatus(character, THROWING_TECHNICAL_STATUS) then
        Osi.ApplyStatus(character, THROWING_TECHNICAL_STATUS, -1.0, 1, character)
    end
end

local function RemoveTechnicalStatus(character)
    if HasStatus(character, THROWING_TECHNICAL_STATUS) then
        Osi.RemoveStatus(character, THROWING_TECHNICAL_STATUS, character)
    end
end

-- ==================================== Listeners
-- Apply when previewing Throw (passive check only)
Ext.Osiris.RegisterListener("StartedPreviewingSpell", 4, "after",
function(caster, spell, isMostPowerful, hasMultipleLevels)
    if THROW_SPELL_BLACKLIST[spell] then 
        return 
    end

    if HasMonkWeaponAttackOverride(caster) then 
        return 
    end

    if Ext.Stats.Get(spell).SpellType == "Throw" then
        ApplyTechnicalStatus(caster)
    end
end)

-- Apply technical status when Throw is actually cast
Ext.Osiris.RegisterListener("CastSpell", 5, "after",
function(caster, spell, spellType, spellElement, storyActionID)
    RemoveTechnicalStatus(caster)
end)

-- Remove technical status if Throw fails
Ext.Osiris.RegisterListener("CastSpellFailed", 5, "after",
function(caster, spell, spellType, spellElement, storyActionID)
    RemoveTechnicalStatus(caster)
end)

-- Safety: remove statuses if preview switches to another spell
Ext.Osiris.RegisterListener("StartedPreviewingSpell", 4, "after",
function(caster, spell, isMostPowerful, hasMultipleLevels)
    RemoveTechnicalStatus(caster)
end)
