-- Credit to Ninjoma, original code sourced from Returning Weapon QOL.
-- Reworked to detect any throw spell by SpellType rather than hardcoded spell IDs, and to match thrown items by identity/GUID rather than template, since bonded/scaled items regenerate their template on re-instancing (a fresh GUID gets assigned each time their stats are reapplied, so the template seen at throw time won't match the one seen on landing).
-- _ReplaceItemReturnToOwner.lua handles the distribution of the return tag, replacing the ItemReturnToOwner() boost wherever it is found.
-- The tag itself is in Goon's Library.
-- TODO: Known issues -
-- Comeback Handaxe seems to bug out, "you can't use this right now" or some such after throwing it, you can still throw it though, just not equip or drop? Was able to then equip it on a different character.
-- For some reason the only thing firing after loading the save for the first time is the cast print. Throwing is vanilla until reload.
-- Dual wielding 2 of the same weapon shuffles them in the logic when one is thrown. Not really a problem unless you have a specific enchant, poison, etc. on off or main.

local DEBUG = false
-- local DEBUG = true
local function log(m) if DEBUG then Ext.Utils.Print("[ReturnFix] "..m) end end

local V = {
  ACTIVE        = "RET_ACTIVE",        -- 1 after snapshot until OnThrown clears
  MAIN_TEMPL    = "RET_MAIN_TEMPL",    -- template in main slot at snapshot
  OFF_TEMPL     = "RET_OFF_TEMPL",     -- template in off slot  at snapshot
  MAIN_ITEM     = "RET_MAIN_ITEM",     -- item GUID in main slot at snapshot
  OFF_ITEM      = "RET_OFF_ITEM",      -- item GUID in off slot  at snapshot
  HAD_OFFHAND   = "RET_HAD_OFFHAND",   -- 1 if off-hand was occupied at snapshot
  HAD_MAIN      = "RET_HAD_MAIN",      -- 1 if main hand was occupied at snapshot
}
local NULL_UUID = "00000000-0000-0000-0000-000000000000"

-- Note: HAD_OFFHAND/HAD_MAIN exist as separate integer flags rather than inferring "was empty" from MAIN_ITEM/MAIN_TEMPL == NULL_UUID, because SetVarUUID appears to silently drop writes of the null-UUID sentinel over a previously-real value — a slot that goes from occupied to empty between throws can be left holding stale data from an earlier throw. Integers don't show this issue, so they're the source of truth for "was this slot occupied," and the UUID vars are only ever compared when their matching had-flag says the slot was actually occupied.

local function IsReturning(it)
  if not it then return false end
  return Osi.IsTagged(it, "b5b9303d-a3cb-435b-b8d6-a5560cd48815") == 1
end

-- Check SpellType via stats.
local function IsThrowSpell(spellId)
  if not spellId then return false end
  local st = Ext.Stats.Get(spellId)
  return st ~= nil and st.SpellType == "Throw"
end

local function ClearVars(c)
  for _,k in pairs{V.ACTIVE,V.HAD_OFFHAND,V.HAD_MAIN} do
    Osi.SetVarInteger(c,k,0) end
  for _,k in pairs{V.MAIN_TEMPL,V.OFF_TEMPL,V.MAIN_ITEM,V.OFF_ITEM} do
    Osi.SetVarUUID(c,k,NULL_UUID) end
end

-- ================== 0. Clear on manual gear changes (skip while a throw is in flight) ==================
for _,ev in ipairs{"Equipped","Unequipped"} do
  Ext.Osiris.RegisterListener(ev,2,"after",function(_,c)
    if Osi.GetVarInteger(c,V.ACTIVE)==0 then ClearVars(c) end
  end)
end

-- ================== 1. Snapshot both hand slots the moment a throw spell is cast ==================
Ext.Osiris.RegisterListener("UsingSpell",5,"after",
function(c,s,st)
  if IsThrowSpell(s) then
    ClearVars(c)

    local main = Osi.GetEquippedItem(c,"Melee Main Weapon")
    local off  = Osi.GetEquippedItem(c,"Melee Offhand Weapon")
    local mainTempl = main and Osi.GetTemplate(main) or NULL_UUID
    local offTempl  = off  and Osi.GetTemplate(off)  or NULL_UUID

    Osi.SetVarUUID(c,V.MAIN_TEMPL, mainTempl)
    Osi.SetVarUUID(c,V.OFF_TEMPL,  offTempl)
    Osi.SetVarUUID(c,V.MAIN_ITEM,  main or NULL_UUID)
    Osi.SetVarUUID(c,V.OFF_ITEM,   off  or NULL_UUID)
    Osi.SetVarInteger(c,V.HAD_OFFHAND, off and 1 or 0)
    Osi.SetVarInteger(c,V.HAD_MAIN, main and 1 or 0)
    Osi.SetVarInteger(c,V.ACTIVE,1)

    log(("Snapshot  main:%s(%s)  off:%s(%s)"):format(tostring(main),mainTempl,tostring(off),offTempl))
  end
end)

-- ================== 2. OnThrown: work out where the item came from, then act ==================

-- Four possible outcomes, mutually exclusive:
-- A. Thrown from a hand slot (fromMain/fromOff)  → re-equip it there. If thrown from main hand while dual-wielding, the off-hand weapon gets unequipped and re-equipped around the returning item — needed for it to seat back in the main-hand slot correctly.
-- B. Thrown from backpack, both hands occupied   → leave it in the bag.
-- C. Thrown from backpack, unarmed (hadMain==0)  → equip into main hand.
-- D. Thrown from backpack, main occupied but off-hand empty (hadOff==0) → equip into the empty off-hand (e.g. throwing a returning shield from inventory while a one-handed weapon is already equipped). 

-- C and D both need an explicit ToInventory first: unlike a re-thrown equipped weapon, the item was never part of the character's inventory tree, so Equip alone doesn't reliably pick it up off the ground.

Ext.Osiris.RegisterListener("OnThrown", 7, "after",
function(item, itemTemplate, char)

    if not IsReturning(item) then
        ClearVars(char)
        return
    end

    local mainTempl = Osi.GetVarUUID(char,V.MAIN_TEMPL)
    local offTempl  = Osi.GetVarUUID(char,V.OFF_TEMPL)
    local mainItem  = Osi.GetVarUUID(char,V.MAIN_ITEM)
    local offItem   = Osi.GetVarUUID(char,V.OFF_ITEM)
    local hadOff    = Osi.GetVarInteger(char,V.HAD_OFFHAND)
    local hadMain   = Osi.GetVarInteger(char,V.HAD_MAIN)

    -- Identity match (item GUID) takes priority over template match, since bonded items' templates don't survive the throw. Gated on had*==1 so an empty slot's stale/leftover vars can never produce a false match.
    local fromMain = (hadMain==1) and ((item == mainItem) or (itemTemplate == mainTempl))
    local fromOff  = (hadOff==1)  and ((item == offItem)  or (itemTemplate == offTempl))

    -- Attempted a stricter version below to stop two identical dual-wielded weapons from both matching a single thrown item (template-only ambiguity), but it broke matching entirely for that case — the "exact identity" half of the check may never actually succeed in practice, since `item` from OnThrown appears to print with a name prefix ("TemplateName_GUID") while mainItem/offItem sometimes print as a bare GUID, meaning `item == mainItem` could be comparing two differently-formatted strings that never equal each other even for the same physical item. If revisiting, extract the raw 36-char UUID substring from both sides before comparing, rather than comparing the full identifier strings as-is.
    -- Left here as a jumping-off point, not currently in use:
    --[[
    local mainExact = (hadMain==1) and (item == mainItem)
    local offExact  = (hadOff==1)  and (item == offItem)

    local fromMain, fromOff
    if mainExact or offExact then
        fromMain, fromOff = mainExact, offExact
    else
        local mainTemplMatch = (hadMain==1) and (itemTemplate == mainTempl)
        local offTemplMatch  = (hadOff==1)  and (itemTemplate == offTempl)
        if mainTemplMatch and not offTemplMatch then
            fromMain, fromOff = true, false
        elseif offTemplMatch and not mainTemplMatch then
            fromMain, fromOff = false, true
        else
            fromMain, fromOff = false, false
        end
    end
    --]]

    log(("OnThrown match  item:%s main:%s/%s(had:%s) off:%s/%s(had:%s)  fromMain:%s fromOff:%s")
        :format(tostring(item), tostring(mainItem), tostring(mainTempl), tostring(hadMain),
                tostring(offItem), tostring(offTempl), tostring(hadOff),
                tostring(fromMain), tostring(fromOff)))

    if not (fromMain or fromOff) and hadMain == 1 and hadOff == 1 then
        -- Case B: backpack throw, both hands occupied → stays in the bag.
        Osi.ToInventory(item, char, 1, 1, 0)
        ClearVars(char)
        return
    end

    -- Cases A and C both end with the item equipped. C additionally needs ToInventory first since the item isn't yet owned by the character.
    if not (fromMain or fromOff) then
        Osi.ToInventory(item, char, 1, 1, 0)
    end

    -- Dual-wield case: throwing the main-hand weapon while an off-hand weapon is equipped needs an explicit unequip/re-equip cycle around the returning item, or the engine doesn't reliably seat it back in the main-hand slot.
    -- log(("Hand re-equip  main?%s off?%s"):format(fromMain,fromOff))
    local slid = Osi.GetEquippedItem(char,"Melee Main Weapon")
    if fromMain and slid then Osi.Unequip(char,slid) end

    Osi.Equip(char,item,1,1,0)

    if fromMain and hadOff==1 and slid
       and Osi.IsInInventoryOf(slid,char)==1 then
        Osi.Equip(char,slid,1,1,0)
    end

    ClearVars(char)
end)
