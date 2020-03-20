AdvancedFilters = AdvancedFilters or {}
local AF = AdvancedFilters

local util = AF.util

local debugSpam = AF.debugSpam

--Local variables from global addon namespace
local filterTypeToGroupName = AF.filterTypeNames
local normalFilterNames = AF.normalFilterNames
local normalFilter2CraftingFilter = AF.normalFilter2CraftingFilter

local itemIds = AF.itemIds
------------------------------------------------------------------------------------------------------------------------
-- Other helper functions
---------------------------------------------------------------------------------------------------------------------------
--NO filter types are given, and we need to check for junkable items
local function checkNoFilterTypesOrIsJunk(slot, junkCheck)
    --Shall we check only junk items?
    if junkCheck and slot.bagId and slot.slotIndex then
        return IsItemJunk(slot.bagId, slot.slotIndex)
    end
    --No junk but must be junk, and no slot data to check: Disallow/Filter out
    if junkCheck then return false end
    --No filtertypes, no junk or no slot data: Allow/Show
    return true
end


------------------------------------------------------------------------------------------------------------------------
-- Subfilter callback functions
---------------------------------------------------------------------------------------------------------------------------
--Check if the first parameter "slot" is the bagId of a crafting station item row, or the dataEntry.data table of another
--inventory row and prepare the slot variable then properly for the filter functions
local function checkCraftingStationSlot(slot, slotIndex)
    if util.prepareSlot and slotIndex ~= nil and type(slot) ~= "table" then
        slot = util.prepareSlot(slot, slotIndex)
    end
    return slot
end
AF.checkCraftingStationSlot = checkCraftingStationSlot

local function GetFilterCallbackForWeaponType(filterTypes, checkOnlyJunk)
    checkOnlyJunk = checkOnlyJunk or false
    return function(slot, slotIndex)
        slot = checkCraftingStationSlot(slot, slotIndex)
        if checkOnlyJunk == true then if not checkNoFilterTypesOrIsJunk(slot, true) then return false end end
        local itemLink = util.GetItemLink(slot)
        if not itemLink then return false end
        local weaponType = GetItemLinkWeaponType(itemLink)
        for i=1, #filterTypes do
            if(filterTypes[i] == weaponType) then
                return true
            end
        end
        return false
    end
end

local function GetFilterCallbackForArmorType(filterTypes, checkOnlyJunk)
    checkOnlyJunk = checkOnlyJunk or false
    return function(slot, slotIndex)
        slot = checkCraftingStationSlot(slot, slotIndex)
        if checkOnlyJunk == true then if not checkNoFilterTypesOrIsJunk(slot, true) then return false end end
        local itemLink = util.GetItemLink(slot)
        if not itemLink then return false end
        local armorType = GetItemLinkArmorType(itemLink)
        for i=1, #filterTypes do
            if(filterTypes[i] == armorType) then return true end
        end
        return false
    end
end

local function GetFilterCallbackForGear(filterTypes, armorTypes, checkOnlyJunk)
    checkOnlyJunk = checkOnlyJunk or false
    return function(slot, slotIndex)
        slot = checkCraftingStationSlot(slot, slotIndex)
        local itemLink = util.GetItemLink(slot)
        if not itemLink then return false end
        local goOn = false
        if checkOnlyJunk == true then if not checkNoFilterTypesOrIsJunk(slot, true) then return false end end
        if armorTypes ~= nil then
            local armorType = GetItemLinkArmorType(itemLink)
            for i=1, #armorTypes do
                if armorTypes[i] == armorType then
                    goOn = true
                    break
                end
            end
        else
            goOn = true
        end
        if goOn then
            local _, _, _, equipType = GetItemLinkInfo(itemLink)

            for i=1, #filterTypes do
                if filterTypes[i] == equipType then return true end
            end
        end
        return false
    end
end

local function GetFilterCallbackForJewelry(filterTypes, itemTraitType, checkOnlyJunk)
    checkOnlyJunk = checkOnlyJunk or false
    return function(slot, slotIndex)
        slot = checkCraftingStationSlot(slot, slotIndex)
        if checkOnlyJunk == true then if not checkNoFilterTypesOrIsJunk(slot, true) then return false end end
        local itemLink = util.GetItemLink(slot)
        if not itemLink then return false end
        local _, _, _, equipType = GetItemLinkInfo(itemLink)
        for i=1, #filterTypes do
            if filterTypes[i] == equipType then
                local checkItemTraitType = GetItemLinkTraitInfo(itemLink)
                if itemTraitType == checkItemTraitType then return true end
            end
        end
        return false
    end
end

local function GetFilterCallbackForClothing(checkOnlyJunk)
    checkOnlyJunk = checkOnlyJunk or false
    return function(slot, slotIndex)
        slot = checkCraftingStationSlot(slot, slotIndex)
        if checkOnlyJunk == true then if not checkNoFilterTypesOrIsJunk(slot, true) then return false end end
        local itemLink = util.GetItemLink(slot)
        if not itemLink then return false end
        local armorType = GetItemLinkArmorType(itemLink)
        local _, _, _, equipType = GetItemLinkInfo(itemLink)
        if((armorType == ARMORTYPE_NONE) and
          (equipType ~= EQUIP_TYPE_NECK) and (equipType ~= EQUIP_TYPE_MAIN_HAND) and
          (equipType ~= EQUIP_TYPE_OFF_HAND) and (equipType ~= EQUIP_TYPE_ONE_HAND) and
          (equipType ~= EQUIP_TYPE_TWO_HAND) and (equipType ~= EQUIP_TYPE_RING)
            --and (equipType ~= EQUIP_TYPE_COSTUME) !!!Disabled as Clothing was disabled in Armor, and Vanity was moved to Miscelaneous
           and (equipType ~= EQUIP_TYPE_INVALID)) then
            return true
        end
        return false
    end
end

local function GetFilterCallbackForTrophy(checkOnlyJunk)
    checkOnlyJunk = checkOnlyJunk or false
    return function(slot, slotIndex)
        slot = checkCraftingStationSlot(slot, slotIndex)
        if checkOnlyJunk == true then if not checkNoFilterTypesOrIsJunk(slot, true) then return false end end
        local itemLink = util.GetItemLink(slot)
        if not itemLink then return false end
        local itemType = GetItemLinkItemType(itemLink)
        --if not IsItemLinkStolen(itemLink) and (itemType == ITEMTYPE_TROPHY
        if (itemType == ITEMTYPE_TROPHY
                or itemType == ITEMTYPE_COLLECTIBLE or itemType == ITEMTYPE_FISH
                or itemType == ITEMTYPE_TREASURE) then
            return true
        end
        return false
    end
end

local function GetFilterCallbackForFence(checkOnlyJunk)
    checkOnlyJunk = checkOnlyJunk or false
    return function(slot, slotIndex)
        slot = checkCraftingStationSlot(slot, slotIndex)
        if checkOnlyJunk == true then if not checkNoFilterTypesOrIsJunk(slot, true) then return false end end
        local itemLink = util.GetItemLink(slot)
        if not itemLink then return false end
        local itemType = GetItemLinkItemType(itemLink)
        if IsItemLinkStolen(itemLink) and not (itemType == ITEMTYPE_GLYPH_ARMOR
          or itemType == ITEMTYPE_GLYPH_JEWELRY
          or itemType == ITEMTYPE_GLYPH_WEAPON or itemType == ITEMTYPE_SOUL_GEM
          or itemType == ITEMTYPE_SIEGE or itemType == ITEMTYPE_LURE
          or itemType == ITEMTYPE_TOOL or itemType == ITEMTYPE_TRASH) then
            return true
        end
        return false
    end
end

local function GetFilterCallbackForStolen(checkOnlyJunk)
    checkOnlyJunk = checkOnlyJunk or false
    return function(slot, slotIndex)
        slot = checkCraftingStationSlot(slot, slotIndex)
        if checkOnlyJunk == true then if not checkNoFilterTypesOrIsJunk(slot, true) then return false end end
        local itemLink = util.GetItemLink(slot)
        if not itemLink then return false end
        if IsItemLinkStolen(itemLink) then
d("[AF]GetFilterCallbackForStolen: " ..itemLink)
            return true
        end
        return false
    end
end

local function GetFilterCallbackForProvisioningIngredient(ingredientType)
    return function(slot, slotIndex)
        slot = checkCraftingStationSlot(slot, slotIndex)
        local lookup = {
            --meats (health)
            ["28609"] = "Food", --Game
            ["33752"] = "Food", --Red Meat
            ["33753"] = "Food", --Fish
            ["33754"] = "Food", --White Meat
            ["33756"] = "Food", --Small Game
            ["34321"] = "Food", --Poultry
            --fruits (magicka)
            ["28603"] = "Food", --Tomato
            ["28610"] = "Food", --Jazbay Grapes
            ["33755"] = "Food", --Bananas
            ["34308"] = "Food", --Melon
            ["34311"] = "Food", --Apples
            ["34305"] = "Food", --Pumpkin
            --vegetables (stamina)
            ["28604"] = "Food", --Greens
            ["33758"] = "Food", --Potato
            ["34307"] = "Food", --Radish
            ["34309"] = "Food", --Beets
            ["34323"] = "Food", --Corn
            ["34324"] = "Food", --Carrots
            --dish additives
            ["26954"] = "Food", --Garlic
            ["27057"] = "Food", --Cheese
            ["27058"] = "Food", --Seasoning
            ["27063"] = "Food", --Saltrice
            ["27064"] = "Food", --Millet
            ["27100"] = "Food", --Flour
            --rare dish additive
            ["26802"] = "Food", --Frost Mirriam
            --alcoholic (health)
            ["28639"] = "Drink", --Rye
            ["29030"] = "Drink", --Rice
            ["33774"] = "Drink", --Yeast
            ["34329"] = "Drink", --Barley
            ["34345"] = "Drink", --Surilie Grapes
            ["34348"] = "Drink", --Wheat
            --tea (magicka)
            ["28636"] = "Drink", --Rose
            ["33768"] = "Drink", --Comberry
            ["33771"] = "Drink", --Jasmine
            ["33773"] = "Drink", --Mint
            ["34330"] = "Drink", --Lotus
            ["34334"] = "Drink", --Bittergreen
            --tonic (stamina)
            ["33772"] = "Drink", --Coffee
            ["34333"] = "Drink", --Guarana
            ["34335"] = "Drink", --Yerba Mate
            ["34346"] = "Drink", --Gingko
            ["34347"] = "Drink", --Ginseng
            ["34349"] = "Drink", --Acai Berry
            --drink additives
            ["27035"] = "Drink", --Isinglass
            ["27043"] = "Drink", --Honey
            ["27048"] = "Drink", --Metheglin
            ["27049"] = "Drink", --Lemon
            ["27052"] = "Drink", --Ginger
            ["28666"] = "Drink", --Seaweed
            --rare drink additive
            ["27059"] = "Drink", --Bervez Juice
            --old ingredients
            ["26962"] = "Old", --Old Pepper
            ["26966"] = "Old", --Old Drippings
            ["26974"] = "Old", --Old Cooking Fat
            ["26975"] = "Old", --Old Suet
            ["26976"] = "Old", --Old Lard
            ["26977"] = "Old", --Old Fatback
            ["26978"] = "Old", --Old Pinguis
            ["26986"] = "Old", --Old Thin Broth
            ["26987"] = "Old", --Old Broth
            ["26988"] = "Old", --Old Stock
            ["26989"] = "Old", --Old Jus
            ["26990"] = "Old", --Old Glace Viande
            ["26998"] = "Old", --Old Imperial Stock
            ["26999"] = "Old", --Old Meal
            ["27000"] = "Old", --Old Milled Flour
            ["27001"] = "Old", --Old Sifted Flour
            ["27002"] = "Old", --Old Cake Flour
            ["27003"] = "Old", --Old Baker's Flour
            ["27004"] = "Old", --Old Imperial Flour
            ["27044"] = "Old", --Old Saaz Hops
            ["27051"] = "Old", --Old Jazbay Grapes
            ["27053"] = "Old", --Old Canis Root
            ["28605"] = "Old", --Old Scuttle Meat
            ["28606"] = "Old", --Old Plump Worms^p
            ["28607"] = "Old", --Old Plump Rodent Toes^p
            ["28608"] = "Old", --Old Plump Maggots^p
            ["28632"] = "Old", --Old Snake Slime
            ["28634"] = "Old", --Old Snake Venom
            ["28635"] = "Old", --Old Wild Honey
            ["28637"] = "Old", --Old Sujamma Berries^P
            ["28638"] = "Old", --Old River Grapes^p
            ["33757"] = "Old", --Old Venison
            ["33767"] = "Old", --Old Shornhelm Grains^p
            ["33769"] = "Old", --Old Tangerine
            ["33770"] = "Old", --Old Wasp Squeezings
            ["34304"] = "Old", --Old Pork
            ["34306"] = "Old", --Old Sweetmeats^p
            ["34312"] = "Old", --Old Saltrice
            ["34322"] = "Old", --Old Shank
            ["34331"] = "Old", --Old Ripe Apple
            ["34332"] = "Old", --Old Wisp Floss
            ["34336"] = "Old", --Old Spring Essence
            ["40260"] = "Old", --Old Brown Malt
            ["40261"] = "Old", --Old Amber Malt
            ["40262"] = "Old", --Old Caramalt
            ["40263"] = "Old", --Old Wheat Malt
            ["40264"] = "Old", --Old White Malt
            ["40265"] = "Old", --Old Wine Grapes^p
            ["40266"] = "Old", --Old Grasa Grapes^p
            ["40267"] = "Old", --Old Lado Grapes^p
            ["40268"] = "Old", --Old Camaralet Grapes^p
            ["40269"] = "Old", --Old Ribier Grapes^p
            ["40270"] = "Old", --Old Corn Mash
            ["40271"] = "Old", --Old Wheat Mash
            ["40272"] = "Old", --Old Oat Mash
            ["40273"] = "Old", --Old Barley Mash
            ["40274"] = "Old", --Old Rice Mash
            ["40276"] = "Old", --Old Mutton Flank
            ["45522"] = "Old", --Old Golden Malt
            ["45523"] = "Old", --Old Emperor Grapes^p
            ["45524"] = "Old", --Old Imperial Mash
        }
        local itemLink = util.GetItemLink(slot)
        if not itemLink then return false end
        if GetItemLinkItemType(itemLink) ~= ITEMTYPE_INGREDIENT then return false end
        local itemId = GetItemLinkItemId(itemLink)
        if lookup[itemId] == ingredientType then return true end
        return false
    end
end

local function GetFilterCallbackForStyleMaterial(categoryConst, checkOnlyJunk)
    checkOnlyJunk = checkOnlyJunk or false
    return function(slot, slotIndex)
        slot = checkCraftingStationSlot(slot, slotIndex)
        if checkOnlyJunk == true then if not checkNoFilterTypesOrIsJunk(slot, true) then return false end end
        local itemLink = util.GetItemLink(slot)
        if not itemLink then return false end
        if categoryConst == AF.util.LibMotifCategories:GetMotifCategory(itemLink) then
            return true
        end
        return false
    end
end

local function GetFilterCallbackForItemTypeAndSpecializedItemtype(sItemTypes, sSpecializedItemTypes, checkOnlyJunk, needsItemTypeAndSpecializedItemType)
    checkOnlyJunk = checkOnlyJunk or false
    needsItemTypeAndSpecializedItemType = needsItemTypeAndSpecializedItemType or false

    return function(slot, slotIndex)
        slot = checkCraftingStationSlot(slot, slotIndex)
        if(not sItemTypes and not sSpecializedItemTypes) then return checkNoFilterTypesOrIsJunk(slot, checkOnlyJunk) end
        if checkOnlyJunk == true then if not checkNoFilterTypesOrIsJunk(slot, true) then return false end end
        local itemLink = util.GetItemLink(slot)
        if not itemLink then return false end
        local itemType, specializedItemType = GetItemLinkItemType(itemLink)
        for i = 1, #sItemTypes do
            if sItemTypes[i] == itemType then
                if needsItemTypeAndSpecializedItemType == true then
                    for j = 1, #sSpecializedItemTypes do
                        if sSpecializedItemTypes[j] == specializedItemType then
                            return true
                        end
                    end
                else
                    return true
                end
            end
        end
        return false
    end
end

local function GetFilterCallbackForSpecializedItemtype(sSpecializedItemTypes, checkOnlyJunk, checkItemTypeToo)
    return function(slot, slotIndex)
        checkOnlyJunk = checkOnlyJunk or false
        checkItemTypeToo = checkItemTypeToo or false
        slot = checkCraftingStationSlot(slot, slotIndex)
        if(not sSpecializedItemTypes) then return checkNoFilterTypesOrIsJunk(slot, checkOnlyJunk) end
        if checkOnlyJunk == true then if not checkNoFilterTypesOrIsJunk(slot, true) then return false end end
        local itemLink = util.GetItemLink(slot)
        if not itemLink then return false end
        local itemType, specializedItemType = GetItemLinkItemType(itemLink)

        for i = 1, #sSpecializedItemTypes do
            if sSpecializedItemTypes[i] == specializedItemType then
                return true
            else
                if checkItemTypeToo and sSpecializedItemTypes[i] == itemType then
                    return true
                end
            end
        end
        return false
    end
end

local function GetFilterCallback(filterTypes, checkOnlyJunk, excludeThisItemIds)
    return function(slot, slotIndex)
        checkOnlyJunk = checkOnlyJunk or false
        slot = checkCraftingStationSlot(slot, slotIndex)
        if(not filterTypes) then return checkNoFilterTypesOrIsJunk(slot, checkOnlyJunk) end
        if checkOnlyJunk == true then if not checkNoFilterTypesOrIsJunk(slot, true) then return false end end
        local itemLink = util.GetItemLink(slot)
        if not itemLink then return false end
        local itemId = GetItemLinkItemId(itemLink)
        local itemType = GetItemLinkItemType(itemLink)
        for i=1, #filterTypes do
            if filterTypes[i] == itemType then
                if excludeThisItemIds then
                    if type(excludeThisItemIds) == "table" then
                        for _, itemIdToExclude in ipairs(excludeThisItemIds) do
                            if itemId == itemIdToExclude then return false end
                        end
                    else
                        if itemId == excludeThisItemIds then return false end
                    end
                end
                return true
            end
        end
        return false
    end
end

--OTHER ADDONS CALLBACK functions
local function GetFilterCallbackForOtherAddon(itemFilterTypeOfTheOtherAddon, checkOnlyJunk)
    return function(slot, slotIndex)
        return true
        --[[
        if AF.settings.debugSpam then d("Other addons filter callback func") end
        if not itemFilterTypeOfTheOtherAddon then return end
        local invType = util.GetCurrentFilterTypeForInventory(AF.currentInventoryType)
        if not invType then return end
        local activeInventoryFilterBarButton = util.GetActiveInventoryFilterBarButtonData(invType)
        if not activeInventoryFilterBarButton then return end
        --Get the original callback of the button
        local buttonData = activeInventoryFilterBarButton.m_buttonData
        if not buttonData then return false end
        local origButtonCallback = buttonData.filterType
        if not origButtonCallback or type(origButtonCallback) ~= "function" then return false end
        --Check for junk and prepare the crafting station slot
        checkOnlyJunk = checkOnlyJunk or false
        slot = checkCraftingStationSlot(slot, slotIndex)
        --Call the original filter function
        local origCallbackResult = origButtonCallback(slot, slotIndex)
        if(not origCallbackResult) then return checkNoFilterTypesOrIsJunk(slot, checkOnlyJunk) end
        if checkOnlyJunk == true then if not checkNoFilterTypesOrIsJunk(slot, true) then return false end end
        --Return the original callback function result
        return origCallbackResult
        ]]
    end
end


------------------------------------------------------------------------------------------------------------------------
-- Subfilter callback setup table
---------------------------------------------------------------------------------------------------------------------------
local subfilterCallbacks = {
--=============================================================================================================================================================================================
--=============================================================================================================================================================================================
--=============================================================================================================================================================================================
-- -v- Inventory main filters subfilter bars                                                                         -v-
--=============================================================================================================================================================================================
    --All
    [AF_CONST_ALL] = {
        addonDropdownCallbacks = {},
        dropdownCallbacks = {
            {name = AF_CONST_ALL,
             filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(true, nil) end,
             filterCallback = GetFilterCallback(nil),
            },
        },
        [AF_CONST_ALL] = {
            filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(true, nil) end,
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
    },
--=============================================================================================================================================================================================
    --Weapons
    Weapons = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        OneHand = {
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_AXE, WEAPONTYPE_HAMMER, WEAPONTYPE_SWORD, WEAPONTYPE_DAGGER}),
            dropdownCallbacks = {
                {name = "Axe", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_AXE})},
                {name = "Hammer", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_HAMMER})},
                {name = "Sword", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_SWORD})},
                {name = "Dagger", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_DAGGER})},
            },
        },
        TwoHand = {
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_TWO_HANDED_AXE, WEAPONTYPE_TWO_HANDED_HAMMER, WEAPONTYPE_TWO_HANDED_SWORD}),
            dropdownCallbacks = {
                {name = "TwoHandAxe", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_TWO_HANDED_AXE})},
                {name = "TwoHandHammer", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_TWO_HANDED_HAMMER})},
                {name = "TwoHandSword", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_TWO_HANDED_SWORD})},
            },
        },
        Bow = {
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_BOW}),
            dropdownCallbacks = {},
        },
        DestructionStaff = {
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_FIRE_STAFF, WEAPONTYPE_FROST_STAFF, WEAPONTYPE_LIGHTNING_STAFF}),
            dropdownCallbacks = {
                {name = "Fire", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_FIRE_STAFF})},
                {name = "Frost", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_FROST_STAFF})},
                {name = "Lightning", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_LIGHTNING_STAFF})},
            },
        },
        HealStaff = {
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_HEALING_STAFF}),
            dropdownCallbacks = {},
        },
    },
--=============================================================================================================================================================================================
    --Armor
    Armor = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        Heavy = {
            filterCallback = GetFilterCallbackForArmorType({ARMORTYPE_HEAVY}),
            dropdownCallbacks = {},
        },
        Medium = {
            filterCallback = GetFilterCallbackForArmorType({ARMORTYPE_MEDIUM}),
            dropdownCallbacks = {},
        },
        LightArmor = {
            filterCallback = GetFilterCallbackForArmorType({ARMORTYPE_LIGHT}),
            dropdownCallbacks = {},
        },
        --[[
        --Moved to Miscelaneous
        Clothier = {
            filterCallback = GetFilterCallbackForClothing(),
        },
        ]]
        Body = {
            dropdownCallbacks = {
                {name = "Head", showIcon=true, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_HEAD})},
                {name = "Chest", showIcon=true, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_CHEST})},
                {name = "Shoulders", showIcon=true, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_SHOULDERS})},
                {name = "Hand", showIcon=true, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_HAND})},
                {name = "Waist", showIcon=true, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_WAIST})},
                {name = "Legs", showIcon=true, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_LEGS})},
                {name = "Feet", showIcon=true, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_FEET})},
            },
        },
        Shield = {
            filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_OFF_HAND}),
            dropdownCallbacks = {
                {name = "Shield", showIcon=true, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_OFF_HAND})},
            },
        },
        --[[
        --Moved to Miscelaneous
        Vanity = {
            filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_DISGUISE, EQUIP_TYPE_COSTUME}),
            dropdownCallbacks = {},
        },
        ]]
    },
--=============================================================================================================================================================================================
    --Jewelry
    Jewelry = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(true, nil) end,
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        Neck = {
            filterForAll = {
                equipTypes = {EQUIP_TYPE_NECK},
            },
            filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_NECK, nil) end,
            filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_NECK}),
            dropdownCallbacks = {
                {name = "Arcane", showIcon=true, addString = "Neck",        filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_NECK, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_ARCANE)},
                {name = "Bloodthirsty", showIcon=true, addString = "Neck",  filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_NECK, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY)},
                {name = "Harmony", showIcon=true, addString = "Neck",       filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_NECK, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_HARMONY)},
                {name = "Healthy", showIcon=true, addString = "Neck",       filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_NECK, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_HEALTHY)},
                {name = "Infused", showIcon=true, addString = "Neck",       filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_NECK, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_INFUSED)},
                {name = "Intricate", showIcon=true, addString = "Neck",     filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_NECK, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_INTRICATE)},
                {name = "Ornate", showIcon=true, addString = "Neck",        filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_NECK, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_ORNATE)},
                {name = "Protective", showIcon=true, addString = "Neck",    filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_NECK, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE)},
                {name = "Robust", showIcon=true, addString = "Neck",        filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_NECK, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_ROBUST)},
                {name = "Swift", showIcon=true, addString = "Neck",         filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_NECK, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_SWIFT)},
                {name = "Triune", showIcon=true, addString = "Neck",        filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_NECK, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_TRIUNE)},
            },
        },
        Ring = {
            filterForAll = {
                equipTypes = {EQUIP_TYPE_RING},
            },
            filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_RING, nil) end,
            filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_RING}),
            dropdownCallbacks = {
                {name = "Arcane", showIcon=true, addString = "Ring",        filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_RING, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_ARCANE)},
                {name = "Bloodthirsty", showIcon=true, addString = "Ring",  filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_RING, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY)},
                {name = "Harmony", showIcon=true, addString = "Ring",       filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_RING, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_HARMONY)},
                {name = "Healthy", showIcon=true, addString = "Ring",       filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_RING, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_HEALTHY)},
                {name = "Infused", showIcon=true, addString = "Ring",       filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_RING, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_INFUSED)},
                {name = "Intricate", showIcon=true, addString = "Ring",     filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_RING, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_INTRICATE)},
                {name = "Ornate", showIcon=true, addString = "Ring",        filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_RING, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_ORNATE)},
                {name = "Protective", showIcon=true, addString = "Ring",    filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_RING, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE)},
                {name = "Robust", showIcon=true, addString = "Ring",        filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_RING, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_ROBUST)},
                {name = "Swift", showIcon=true, addString = "Ring",         filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_RING, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_SWIFT)},
                {name = "Triune", showIcon=true, addString = "Ring",        filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_RING, nil) end, filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_TRIUNE)},
            },
        },
    },
--=============================================================================================================================================================================================
    --Consumables
    Consumables = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        Crown = {
            filterCallback = GetFilterCallback({ITEMTYPE_CROWN_ITEM}),
            dropdownCallbacks = {},
        },
        Food = {
            filterCallback = GetFilterCallback({ITEMTYPE_FOOD}),
            dropdownCallbacks = {},
        },
        Drink = {
            filterCallback = GetFilterCallback({ITEMTYPE_DRINK}),
            dropdownCallbacks = {},
        },
        Recipe = {
            filterCallback = GetFilterCallback({ITEMTYPE_RECIPE}),
            dropdownCallbacks = {},
        },
        Potion = {
            filterCallback = GetFilterCallback({ITEMTYPE_POTION}),
            dropdownCallbacks = {},
        },
        Poison = {
            filterCallback = GetFilterCallback({ITEMTYPE_POISON}),
            dropdownCallbacks = {},
        },
        Motif = {
            filterCallback = GetFilterCallback({ITEMTYPE_RACIAL_STYLE_MOTIF}),
            dropdownCallbacks = {},
        },
        Writ = {
            filterCallback = GetFilterCallback({ITEMTYPE_MASTER_WRIT}),
            dropdownCallbacks = {},
        },
        Container = {
            filterCallback = GetFilterCallbackForItemTypeAndSpecializedItemtype(
                    {ITEMTYPE_CONTAINER, ITEMTYPE_CONTAINER_CURRENCY},
                    {SPECIALIZED_ITEMTYPE_CONTAINER, SPECIALIZED_ITEMTYPE_CONTAINER_CURRENCY, SPECIALIZED_ITEMTYPE_CONTAINER_EVENT, SPECIALIZED_ITEMTYPE_CONTAINER_STYLE_PAGE}, false, false)
                    or GetFilterCallbackForItemTypeAndSpecializedItemtype(
                    {ITEMFILTERTYPE_PROVISIONING},
                    {SPECIALIZED_ITEMTYPE_CONTAINER}, false, true),
            dropdownCallbacks = {},
        },
        Repair = {
            filterCallback = GetFilterCallback({ITEMTYPE_AVA_REPAIR, ITEMTYPE_TOOL, ITEMTYPE_CROWN_REPAIR}),
            dropdownCallbacks = {},
        },
        Trophy = {
            filterCallback = GetFilterCallbackForTrophy(),
            dropdownCallbacks = {
                {name = "KeyFragment", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_TROPHY_KEY_FRAGMENT})},
                {name = "RecipeFragment", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_TROPHY_RECIPE_FRAGMENT})},
                {name = "Scroll", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_TROPHY_SCROLL})},
                {name = "CollectibleFragment", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_TROPHY_COLLECTIBLE_FRAGMENT})},
                {name = "Key", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_TROPHY_KEY})},
                {name = "MaterialUpgrader", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_TROPHY_MATERIAL_UPGRADER})},
                {name = "RuneboxFragment", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_TROPHY_RUNEBOX_FRAGMENT})},
                {name = "Toy", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_TROPHY_TOY})},
                {name = "UpgradeFragment", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_TROPHY_UPGRADE_FRAGMENT})},
                {name = "Fish", showIcon=true, filterCallback = GetFilterCallbackForItemTypeAndSpecializedItemtype({ITEMTYPE_FISH}, {}, false, false)},
            },
        },
    },
--=============================================================================================================================================================================================
    --Materials
    Crafting = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        Blacksmithing = {
            filterCallback = GetFilterCallback({ITEMTYPE_BLACKSMITHING_MATERIAL, ITEMTYPE_BLACKSMITHING_RAW_MATERIAL, ITEMTYPE_BLACKSMITHING_BOOSTER}),
            dropdownCallbacks = {},
        },
        Clothier = {
            filterCallback = GetFilterCallback({ITEMTYPE_CLOTHIER_MATERIAL, ITEMTYPE_CLOTHIER_RAW_MATERIAL, ITEMTYPE_CLOTHIER_BOOSTER}),
            dropdownCallbacks = {},
        },
        Woodworking = {
            filterCallback = GetFilterCallback({ITEMTYPE_WOODWORKING_MATERIAL, ITEMTYPE_WOODWORKING_RAW_MATERIAL, ITEMTYPE_WOODWORKING_BOOSTER}),
            dropdownCallbacks = {},
        },
        Alchemy = {
            filterCallback = GetFilterCallback({ITEMTYPE_REAGENT, ITEMTYPE_POTION_BASE, ITEMTYPE_POISON_BASE}),
            dropdownCallbacks = {
                {name = "Reagent", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_REAGENT})},
                {name = "Water", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_POTION_BASE})},
                {name = "Oil", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_POISON_BASE})},
            },
        },
        Enchanting = {
            filterCallback = GetFilterCallback({ITEMTYPE_ENCHANTING_RUNE_ASPECT, ITEMTYPE_ENCHANTING_RUNE_ESSENCE, ITEMTYPE_ENCHANTING_RUNE_POTENCY}),
            dropdownCallbacks = {
                {name = "Aspect", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_ENCHANTING_RUNE_ASPECT})},
                {name = "Essence", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_ENCHANTING_RUNE_ESSENCE})},
                {name = "Potency", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_ENCHANTING_RUNE_POTENCY})},
            },
        },
        Provisioning = {
            filterCallback = GetFilterCallback({ITEMTYPE_INGREDIENT}),
            dropdownCallbacks = {
                {name = "FoodIngredient", showIcon=true, filterCallback = GetFilterCallbackForProvisioningIngredient("Food")},
                {name = "DrinkIngredient", showIcon=true, filterCallback = GetFilterCallbackForProvisioningIngredient("Drink")},
                {name = "OldIngredient", showIcon=true, filterCallback = GetFilterCallbackForProvisioningIngredient("Old")},
                {name = "RareIngredient", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_INGREDIENT_RARE})},
            },
        },
        JewelryCrafting = {
            filterCallback = GetFilterCallback({
                ITEMTYPE_JEWELRYCRAFTING_BOOSTER,
                ITEMTYPE_JEWELRYCRAFTING_MATERIAL,
                ITEMTYPE_JEWELRYCRAFTING_RAW_BOOSTER,
                ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL,
            }),
            dropdownCallbacks = {
                {name = "Plating", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_JEWELRYCRAFTING_BOOSTER})},
                {name = "RefinedMaterialJewelry", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_JEWELRYCRAFTING_MATERIAL})},
                {name = "RawPlating", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_JEWELRYCRAFTING_RAW_BOOSTER})},
                {name = "RawMaterialJewelry", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL})},
            },
        },
        Style = {
            filterCallback = GetFilterCallback({ITEMTYPE_STYLE_MATERIAL, ITEMTYPE_RAW_MATERIAL}),
            dropdownCallbacks = {
                {name = "RawMaterialStyle", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_RAW_MATERIAL})},
                {name = "NormalStyle", showIcon=true, filterCallback = GetFilterCallbackForStyleMaterial(LMC_MOTIF_CATEGORY_NORMAL)},
                {name = "RareStyle", showIcon=true, filterCallback = GetFilterCallbackForStyleMaterial(LMC_MOTIF_CATEGORY_RARE)},
                {name = "AllianceStyle", showIcon=true, filterCallback = GetFilterCallbackForStyleMaterial(LMC_MOTIF_CATEGORY_ALLIANCE)},
                {name = "ExoticStyle", showIcon=true, filterCallback = GetFilterCallbackForStyleMaterial(LMC_MOTIF_CATEGORY_EXOTIC)},
                {name = "CrownStyle", showIcon=true, filterCallback = GetFilterCallbackForStyleMaterial(LMC_MOTIF_CATEGORY_CROWN)},
            },
        },
        --[[
        WeaponTrait = {
            filterCallback = GetFilterCallback({ITEMTYPE_WEAPON_TRAIT}),
            dropdownCallbacks = {},
        },
        ArmorTrait = {
            filterCallback = GetFilterCallback({ITEMTYPE_ARMOR_TRAIT}),
            dropdownCallbacks = {},
        },
        JewelryAllTrait = {
            filterCallback = GetFilterCallback({ITEMTYPE_JEWELRY_TRAIT, ITEMTYPE_JEWELRY_RAW_TRAIT}),
            dropdownCallbacks = {
                {name = "RawMaterialJewelryTrait", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_JEWELRY_RAW_TRAIT})},
                {name = "RefinedMaterialJewelry", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_JEWELRY_TRAIT})},
            },
        },
        ]]
        AllTraits = {
            filterCallback = GetFilterCallback({ITEMTYPE_WEAPON_TRAIT, ITEMTYPE_ARMOR_TRAIT, ITEMTYPE_JEWELRY_TRAIT, ITEMTYPE_JEWELRY_RAW_TRAIT}),
            dropdownCallbacks = {
                {name = "WeaponTrait", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_WEAPON_TRAIT})},
                {name = "ArmorTrait", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_ARMOR_TRAIT})},
                {name = "JewelryAllTrait", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_JEWELRY_TRAIT, ITEMTYPE_JEWELRY_RAW_TRAIT})},
                {name = "JewelryRawTrait", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_JEWELRY_RAW_TRAIT})},
                {name = "JewelryRefinedTrait", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_JEWELRY_TRAIT})},
            },
        },
        FurnishingMat = {
            filterCallback = GetFilterCallback({ITEMTYPE_FURNISHING_MATERIAL}),
            dropdownCallbacks = {},
        },
    },
--=============================================================================================================================================================================================
    --Furnishing
    Furnishings = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        CraftingStation = {
            filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_FURNISHING_CRAFTING_STATION}),
            dropdownCallbacks = {},
        },
        Light = {
            filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_FURNISHING_LIGHT}),
            dropdownCallbacks = {},
        },
        Ornamental = {
            filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_FURNISHING_ORNAMENTAL}),
            dropdownCallbacks = {},
        },
        Seating = {
            filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_FURNISHING_SEATING}),
            dropdownCallbacks = {},
        },
        TargetDummy = {
            filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_FURNISHING_TARGET_DUMMY}),
            dropdownCallbacks = {},
        },
    },
--=============================================================================================================================================================================================
    --Miscellaneous
    Miscellaneous = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        Glyphs = {
            filterCallback = GetFilterCallback({ITEMTYPE_GLYPH_ARMOR, ITEMTYPE_GLYPH_JEWELRY, ITEMTYPE_GLYPH_WEAPON}),
            dropdownCallbacks = {
                {name = "ArmorGlyph", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_GLYPH_ARMOR})},
                {name = "JewelryGlyph", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_GLYPH_JEWELRY})},
                {name = "WeaponGlyph", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_GLYPH_WEAPON})},
            },
        },
        SoulGem = {
            filterCallback = GetFilterCallback({ITEMTYPE_SOUL_GEM}),
            dropdownCallbacks = {},
        },
        Siege = {
            filterCallback = GetFilterCallback({ITEMTYPE_SIEGE}),
            dropdownCallbacks = {},
        },
        Bait = {
            filterCallback = GetFilterCallback({ITEMTYPE_LURE}),
            dropdownCallbacks = {},
        },
        Tool = {
            filterCallback = GetFilterCallback({ITEMTYPE_TOOL}),
            dropdownCallbacks = {},
        },
        Trophy = {
            filterCallback = GetFilterCallbackForTrophy(),
            dropdownCallbacks = {
                {name = "TreasureMaps", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_TROPHY_TREASURE_MAP})},
                {name = "SurveyReport", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_TROPHY_SURVEY_REPORT})},
                {name = "MuseumPiece", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_TROPHY_MUSEUM_PIECE})},
                {name = "Scroll", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_TROPHY_SCROLL})},
                {name = "RareFish", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_COLLECTIBLE_RARE_FISH})},
            },
        },
        Fence = {
            filterCallback = GetFilterCallbackForFence(),
            dropdownCallbacks = {},
        },
        Trash = {
            filterCallback = GetFilterCallback({ITEMTYPE_TRASH}),
            dropdownCallbacks = {},
        },
        Vanity = {
            filterCallback = GetFilterCallbackForClothing(),
            dropdownCallbacks = {
                {name = "Costume", showIcon=true,  filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_COSTUME})},
                {name = "Disguise", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_DISGUISE})},
                {name = "Tabard", showIcon=true,   filterCallback = GetFilterCallback({ITEMTYPE_TABARD})},
            },
        },
    },
--=============================================================================================================================================================================================
    --Junk -> See at the bottom of the table!
--=============================================================================================================================================================================================
-- -^- Inventory main filters subfilter bars                                                                         -^-
--=============================================================================================================================================================================================
--=============================================================================================================================================================================================
--=============================================================================================================================================================================================

--=============================================================================================================================================================================================
--=============================================================================================================================================================================================
--=============================================================================================================================================================================================
-- -v- Subfilters of the subfilterbars                                                                               -v-
--=============================================================================================================================================================================================

    --Collectibles
    Collectibles = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL]         = {
            filterCallback    = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
    },

--=============================================================================================================================================================================================
-- -v- Weapons & Crafting                                                                                            -v-
--=============================================================================================================================================================================================
    WeaponsSmithing = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(true, nil) end,
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        OneHand = {
            filterForAll = {
                filterTypes = {WEAPONTYPE_AXE, WEAPONTYPE_HAMMER, WEAPONTYPE_SWORD, WEAPONTYPE_DAGGER},
            },
            filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, {WEAPONTYPE_AXE, WEAPONTYPE_HAMMER, WEAPONTYPE_SWORD, WEAPONTYPE_DAGGER}) end,
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_AXE, WEAPONTYPE_HAMMER, WEAPONTYPE_SWORD, WEAPONTYPE_DAGGER}), {WEAPONTYPE_AXE, WEAPONTYPE_HAMMER, WEAPONTYPE_SWORD, WEAPONTYPE_DAGGER},
            dropdownCallbacks = {
                {name = "Axe", showIcon=true, filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, WEAPONTYPE_AXE) end, filterCallback=GetFilterCallbackForWeaponType({WEAPONTYPE_AXE})},
                {name = "Hammer", showIcon=true, filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, WEAPONTYPE_HAMMER) end, filterCallback=GetFilterCallbackForWeaponType({WEAPONTYPE_HAMMER})},
                {name = "Sword", showIcon=true, filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, WEAPONTYPE_SWORD) end, filterCallback=GetFilterCallbackForWeaponType({WEAPONTYPE_SWORD})},
                {name = "Dagger", showIcon=true, filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, WEAPONTYPE_DAGGER) end, filterCallback=GetFilterCallbackForWeaponType({WEAPONTYPE_DAGGER})},
            },
        },
        TwoHand = {
            filterForAll = {
                filterTypes = {WEAPONTYPE_TWO_HANDED_AXE, WEAPONTYPE_TWO_HANDED_HAMMER, WEAPONTYPE_TWO_HANDED_SWORD},
            },
            filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, {WEAPONTYPE_TWO_HANDED_AXE, WEAPONTYPE_TWO_HANDED_HAMMER, WEAPONTYPE_TWO_HANDED_SWORD}) end,
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_TWO_HANDED_AXE, WEAPONTYPE_TWO_HANDED_HAMMER, WEAPONTYPE_TWO_HANDED_SWORD}),
            dropdownCallbacks = {
                {name = "TwoHandAxe", showIcon=true, filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, WEAPONTYPE_TWO_HANDED_AXE) end, filterCallback=GetFilterCallbackForWeaponType({WEAPONTYPE_TWO_HANDED_AXE})},
                {name = "TwoHandHammer", showIcon=true, filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, WEAPONTYPE_TWO_HANDED_HAMMER) end, filterCallback=GetFilterCallbackForWeaponType({WEAPONTYPE_TWO_HANDED_HAMMER})},
                {name = "TwoHandSword", showIcon=true, filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, WEAPONTYPE_TWO_HANDED_SWORD) end, filterCallback=GetFilterCallbackForWeaponType({WEAPONTYPE_TWO_HANDED_SWORD})},
            },
        },
    },
--=============================================================================================================================================================================================
    WeaponsWoodworking = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(true, nil) end,
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        Bow = {
            filterForAll = {
                itemTypes = {WEAPONTYPE_BOW},
            },
            filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, WEAPONTYPE_BOW) end,
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_BOW}),
            dropdownCallbacks = {
                {name = "Bow", showIcon=true, filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, WEAPONTYPE_BOW) end, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_BOW})},
            },
        },
        DestructionStaff = {
            filterForAll = {
                itemTypes = {WEAPONTYPE_FIRE_STAFF, WEAPONTYPE_FROST_STAFF, WEAPONTYPE_LIGHTNING_STAFF},
            },
            filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, {WEAPONTYPE_FIRE_STAFF, WEAPONTYPE_FROST_STAFF, WEAPONTYPE_LIGHTNING_STAFF}) end,
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_FIRE_STAFF, WEAPONTYPE_FROST_STAFF, WEAPONTYPE_LIGHTNING_STAFF}),
            dropdownCallbacks = {
                {name = "Fire", showIcon=true, filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, WEAPONTYPE_FIRE_STAFF) end, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_FIRE_STAFF})},
                {name = "Frost", showIcon=true, filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, WEAPONTYPE_FROST_STAFF) end, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_FROST_STAFF})},
                {name = "Lightning", showIcon=true, filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, WEAPONTYPE_LIGHTNING_STAFF) end, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_LIGHTNING_STAFF})},
            },
        },
        HealStaff = {
            filterForAll = {
                itemTypes = {WEAPONTYPE_HEALING_STAFF},
            },
            filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, WEAPONTYPE_HEALING_STAFF) end,
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_HEALING_STAFF}),
            dropdownCallbacks = {
                {name = "HealStaff", showIcon=true, filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, WEAPONTYPE_HEALING_STAFF) end, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_HEALING_STAFF})},
            },
        },
    },
--=============================================================================================================================================================================================
-- -^- Weapons & Crafting                                                                                            -^-
--=============================================================================================================================================================================================

--=============================================================================================================================================================================================
-- -v- Armor & Crafting & Refine                                                                                     -v-
--=============================================================================================================================================================================================
    ArmorSmithing = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(true, nil) end,
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        Heavy = {
            filterForAll = {
                armorTypes = {ARMORTYPE_HEAVY},
            },
            filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, nil, ARMORTYPE_HEAVY) end,
            filterCallback = GetFilterCallbackForArmorType({ARMORTYPE_HEAVY}),
            dropdownCallbacks = {
                {name = "Head", showIcon=true,      filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_HEAD, ARMORTYPE_HEAVY) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_HEAD})},
                {name = "Chest", showIcon=true,     filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_CHEST, ARMORTYPE_HEAVY) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_CHEST})},
                {name = "Shoulders", showIcon=true, filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_SHOULDERS, ARMORTYPE_HEAVY) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_SHOULDERS})},
                {name = "Hand", showIcon=true,      filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_HAND, ARMORTYPE_HEAVY) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_HAND})},
                {name = "Waist", showIcon=true,     filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_WAIST, ARMORTYPE_HEAVY) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_WAIST})},
                {name = "Legs", showIcon=true,      filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_LEGS, ARMORTYPE_HEAVY) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_LEGS})},
                {name = "Feet", showIcon=true,      filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_FEET, ARMORTYPE_HEAVY) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_FEET})},
            },
        },
    },
--=============================================================================================================================================================================================
    --Smithing refine
    RefineSmithing = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        RawMaterialSmithing = {
            filterCallback = GetFilterCallback({ITEMTYPE_BLACKSMITHING_RAW_MATERIAL, ITEMTYPE_RAW_MATERIAL}),
            dropdownCallbacks = {},
        },
    },
--=============================================================================================================================================================================================
    ArmorClothier = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(true, nil) end,
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        LightArmor = {
            filterForAll = {
                armorTypes = {ARMORTYPE_LIGHT},
            },
            filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, nil, ARMORTYPE_LIGHT) end,
            filterCallback = GetFilterCallbackForArmorType({ARMORTYPE_LIGHT}),
            dropdownCallbacks = {
                {name = "Head", showIcon=true, addString="Light", filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_HEAD, ARMORTYPE_LIGHT) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_HEAD}, {ARMORTYPE_LIGHT})},
                {name = "Chest", showIcon=true, addString="Light", filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_CHEST, ARMORTYPE_LIGHT) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_CHEST}, {ARMORTYPE_LIGHT})},
                {name = "Shoulders", showIcon=true, addString="Light", filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_SHOULDERS, ARMORTYPE_LIGHT) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_SHOULDERS}, {ARMORTYPE_LIGHT})},
                {name = "Hand", showIcon=true, addString="Light", filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_HAND, ARMORTYPE_LIGHT) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_HAND}, {ARMORTYPE_LIGHT})},
                {name = "Waist", showIcon=true, addString="Light", filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_WAIST, ARMORTYPE_LIGHT) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_WAIST}, {ARMORTYPE_LIGHT})},
                {name = "Legs", showIcon=true, addString="Light", filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_LEGS, ARMORTYPE_LIGHT) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_LEGS}, {ARMORTYPE_LIGHT})},
                {name = "Feet", showIcon=true, addString="Light", filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_FEET, ARMORTYPE_LIGHT) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_FEET}, {ARMORTYPE_LIGHT})},
            },
        },
        Medium = {
            filterForAll = {
                armorTypes = {ARMORTYPE_MEDIUM},
            },
            filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, nil, ARMORTYPE_MEDIUM) end,
            filterCallback = GetFilterCallbackForArmorType({ARMORTYPE_MEDIUM}),
            dropdownCallbacks = {
                {name = "Head", showIcon=true, addString="Medium", filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_HEAD, ARMORTYPE_MEDIUM) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_HEAD}, {ARMORTYPE_MEDIUM})},
                {name = "Chest", showIcon=true, addString="Medium", filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_CHEST, ARMORTYPE_MEDIUM) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_CHEST}, {ARMORTYPE_MEDIUM})},
                {name = "Shoulders", showIcon=true, addString="Medium", filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_SHOULDERS, ARMORTYPE_MEDIUM) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_SHOULDERS}, {ARMORTYPE_MEDIUM})},
                {name = "Hand", showIcon=true, addString="Medium", filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_HAND, ARMORTYPE_MEDIUM) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_HAND}, {ARMORTYPE_MEDIUM})},
                {name = "Waist", showIcon=true, addString="Medium", filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_WAIST, ARMORTYPE_MEDIUM) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_WAIST}, {ARMORTYPE_MEDIUM})},
                {name = "Legs", showIcon=true, addString="Medium", filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_LEGS, ARMORTYPE_MEDIUM) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_LEGS}, {ARMORTYPE_MEDIUM})},
                {name = "Feet", showIcon=true, addString="Medium", filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_FEET, ARMORTYPE_MEDIUM) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_FEET}, {ARMORTYPE_MEDIUM})},
            },
        },
    },
--=============================================================================================================================================================================================
    --Clothier refine
    RefineClothier = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        RawMaterialClothier = {
            filterCallback = GetFilterCallback({ITEMTYPE_CLOTHIER_RAW_MATERIAL, ITEMTYPE_RAW_MATERIAL}),
            dropdownCallbacks = {},
        },
    },
--=============================================================================================================================================================================================
    ArmorWoodworking = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(true, nil) end,
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        Shield = {
            filterForAll = {
                equipTypes = {EQUIP_TYPE_OFF_HAND},
            },
            filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_OFF_HAND) end,
            filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_OFF_HAND}),
            dropdownCallbacks = {
                {name = "Shield", showIcon=true, filterStartCallback = function() util.CheckForResearchPanelAndRunFilterFunction(false, EQUIP_TYPE_OFF_HAND) end, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_OFF_HAND})},
            },
        },
    },
--=============================================================================================================================================================================================
    --Woodworking refine
    RefineWoodworking = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        RawMaterialWoodworking = {
            filterCallback = GetFilterCallback({ITEMTYPE_WOODWORKING_RAW_MATERIAL, ITEMTYPE_RAW_MATERIAL}),
            dropdownCallbacks = {},
        },
    },
--=============================================================================================================================================================================================
-- -^- Armor & Crafting & Refine                                                                                     -^-
--=============================================================================================================================================================================================

--=============================================================================================================================================================================================
-- -v- Jewelry & Crafting & Refine                                                                                   -v-
--=============================================================================================================================================================================================
    --JewelryCrafting
    JewelryCrafting = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        Plating = {
            filterCallback = GetFilterCallback({ITEMTYPE_JEWELRYCRAFTING_BOOSTER}),
            dropdownCallbacks = {},
        },
        RefinedMaterialJewelry = {
            filterCallback = GetFilterCallback({ITEMTYPE_JEWELRYCRAFTING_MATERIAL}),
            dropdownCallbacks = {},
        },
        RawPlating = {
            filterCallback = GetFilterCallback({ITEMTYPE_JEWELRYCRAFTING_RAW_BOOSTER}),
            dropdownCallbacks = {},
        },
        RawMaterialJewelry = {
            filterCallback = GetFilterCallback({ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL}),
            dropdownCallbacks = {},
        },
        FurnishingMat = {
            filterCallback = GetFilterCallback({ITEMTYPE_FURNISHING_MATERIAL}),
            dropdownCallbacks = {},
        },
    },

    --Jewelry crafting refine
    RefineJewelryCraftingStation = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        RawPlating = {
            filterCallback = GetFilterCallback({ITEMTYPE_JEWELRYCRAFTING_RAW_BOOSTER}),
            dropdownCallbacks = {},
        },
        RawMaterialJewelry = {
            filterCallback = GetFilterCallback({ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL}),
            dropdownCallbacks = {},
        },
        JewelryRawTrait = {
            filterCallback = GetFilterCallback({ITEMTYPE_JEWELRY_RAW_TRAIT}),
            dropdownCallbacks = {},
        },
    },
--=============================================================================================================================================================================================
-- -^- Jewelry & Crafting & Refine                                                                                   -^-
--=============================================================================================================================================================================================

--=============================================================================================================================================================================================
-- -v- CraftBag & Materials                                                                                          -v-
--=============================================================================================================================================================================================
    --Blacksmithing
    Blacksmithing = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        RawMaterialSmithing = {
            filterCallback = GetFilterCallback({ITEMTYPE_BLACKSMITHING_RAW_MATERIAL, ITEMTYPE_RAW_MATERIAL}),
            dropdownCallbacks = {},
        },
        RefinedMaterialSmithing = {
            filterCallback = GetFilterCallback({ITEMTYPE_BLACKSMITHING_MATERIAL}),
            dropdownCallbacks = {},
        },
        Temper = {
            filterCallback = GetFilterCallback({ITEMTYPE_BLACKSMITHING_BOOSTER}),
            dropdownCallbacks = {},
        },
        FurnishingMat = {
            filterCallback = GetFilterCallback({ITEMTYPE_FURNISHING_MATERIAL}),
            dropdownCallbacks = {},
        },
    },
--=============================================================================================================================================================================================
    --Clothing
    Clothing = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        RawMaterialClothier = {
            filterCallback = GetFilterCallback({ITEMTYPE_CLOTHIER_RAW_MATERIAL, ITEMTYPE_RAW_MATERIAL}),
            dropdownCallbacks = {},
        },
        RefinedMaterialClothier = {
            filterCallback = GetFilterCallback({ITEMTYPE_CLOTHIER_MATERIAL}),
            dropdownCallbacks = {},
        },
        Tannin = {
            filterCallback = GetFilterCallback({ITEMTYPE_CLOTHIER_BOOSTER}),
            dropdownCallbacks = {},
        },
        FurnishingMat = {
            filterCallback = GetFilterCallback({ITEMTYPE_FURNISHING_MATERIAL}),
            dropdownCallbacks = {},
        },
    },
--=============================================================================================================================================================================================
    --Woodworking
    Woodworking = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        RawMaterialWoodworking = {
            filterCallback = GetFilterCallback({ITEMTYPE_WOODWORKING_RAW_MATERIAL, ITEMTYPE_RAW_MATERIAL}),
            dropdownCallbacks = {},
        },
        RefinedMaterialWoodworking = {
            filterCallback = GetFilterCallback({ITEMTYPE_WOODWORKING_MATERIAL}),
            dropdownCallbacks = {},
        },
        Resin = {
            filterCallback = GetFilterCallback({ITEMTYPE_WOODWORKING_BOOSTER}),
            dropdownCallbacks = {},
        },
        FurnishingMat = {
            filterCallback = GetFilterCallback({ITEMTYPE_FURNISHING_MATERIAL}),
            dropdownCallbacks = {},
        },
    },
--=============================================================================================================================================================================================
    --Alchemy
    Alchemy = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        Reagent = {
            filterCallback = GetFilterCallback({ITEMTYPE_REAGENT}),
            dropdownCallbacks = {},
        },
        Water = {
            filterCallback = GetFilterCallback({ITEMTYPE_POTION_BASE}),
            dropdownCallbacks = {},
        },
        Oil = {
            filterCallback = GetFilterCallback({ITEMTYPE_POISON_BASE}),
            dropdownCallbacks = {},
        },
        FurnishingMat = {
            filterCallback = GetFilterCallback({ITEMTYPE_FURNISHING_MATERIAL}),
            dropdownCallbacks = {},
        },
    },
--=============================================================================================================================================================================================
    --Enchanting
    Enchanting = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        Aspect = {
            filterCallback = GetFilterCallback({ITEMTYPE_ENCHANTING_RUNE_ASPECT}),
            dropdownCallbacks = {},
        },
        Essence = {
            filterCallback = GetFilterCallback({ITEMTYPE_ENCHANTING_RUNE_ESSENCE}),
            dropdownCallbacks = {},
        },
        Potency = {
            filterCallback = GetFilterCallback({ITEMTYPE_ENCHANTING_RUNE_POTENCY}),
            dropdownCallbacks = {},
        },
        FurnishingMat = {
            filterCallback = GetFilterCallback({ITEMTYPE_FURNISHING_MATERIAL}),
            dropdownCallbacks = {},
        },
    },
--=============================================================================================================================================================================================
    --Runes
    Runes = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
    },
--=============================================================================================================================================================================================
    --Glyphs
    Glyphs = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        WeaponGlyph = {
            filterCallback = GetFilterCallback({ITEMTYPE_GLYPH_WEAPON}),
            dropdownCallbacks = {},
        },
        ArmorGlyph = {
            filterCallback = GetFilterCallback({ITEMTYPE_GLYPH_ARMOR}),
            dropdownCallbacks = {},
        },
        JewelryGlyph = {
            filterCallback = GetFilterCallback({ITEMTYPE_GLYPH_JEWELRY}),
            dropdownCallbacks = {},
        },
    },
--=============================================================================================================================================================================================
    --Provisioning
    Provisioning = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        FoodIngredient = {
            filterCallback = GetFilterCallbackForProvisioningIngredient("Food"),
            dropdownCallbacks = {},
        },
        DrinkIngredient = {
            filterCallback = GetFilterCallbackForProvisioningIngredient("Drink"),
            dropdownCallbacks = {},
        },
        OldIngredient = {
            filterCallback = GetFilterCallbackForProvisioningIngredient("Old"),
            dropdownCallbacks = {},
        },
        RareIngredient = {
            filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_INGREDIENT_RARE}),
            dropdownCallbacks = {},
        },
        FurnishingMat = {
            filterCallback = GetFilterCallback({ITEMTYPE_FURNISHING_MATERIAL}),
            dropdownCallbacks = {},
        },
        Bait = {
            filterCallback = GetFilterCallback({ITEMTYPE_LURE}),
            dropdownCallbacks = {},
        },
    },
--=============================================================================================================================================================================================
    --Style
    Style = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        NormalStyle = {
            filterCallback = GetFilterCallbackForStyleMaterial(LMC_MOTIF_CATEGORY_NORMAL),
            dropdownCallbacks = {},
        },
        RareStyle = {
            filterCallback = GetFilterCallbackForStyleMaterial(LMC_MOTIF_CATEGORY_RARE),
            dropdownCallbacks = {},
        },
        AllianceStyle = {
            filterCallback = GetFilterCallbackForStyleMaterial(LMC_MOTIF_CATEGORY_ALLIANCE),
            dropdownCallbacks = {},
        },
        ExoticStyle = {
            filterCallback = GetFilterCallbackForStyleMaterial(LMC_MOTIF_CATEGORY_EXOTIC),
            dropdownCallbacks = {},
        },
        CrownStyle = {
            filterCallback = GetFilterCallbackForStyleMaterial(LMC_MOTIF_CATEGORY_CROWN),
            dropdownCallbacks = {},
        },
    },
--=============================================================================================================================================================================================
    --Traits
    Traits = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        WeaponTrait = {
            filterCallback = GetFilterCallback({ITEMTYPE_WEAPON_TRAIT}),
            dropdownCallbacks = {},
        },
        ArmorTrait = {
            filterCallback = GetFilterCallback({ITEMTYPE_ARMOR_TRAIT}),
            dropdownCallbacks = {},
        },
        JewelryAllTrait = {
            filterCallback = GetFilterCallback({ITEMTYPE_JEWELRY_TRAIT, ITEMTYPE_JEWELRY_RAW_TRAIT}),
            dropdownCallbacks = {
                {name = "RawMaterialJewelry", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_JEWELRY_RAW_TRAIT})},
                {name = "RefinedMaterialJewelry", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_JEWELRY_TRAIT})},
            },
        },
    },
--=============================================================================================================================================================================================
-- -^- CraftBag & Materials                                                                                          -^-
--=============================================================================================================================================================================================

--=============================================================================================================================================================================================
-- -v- Retrait                                                                                                       -v-
--=============================================================================================================================================================================================
    --Weapons retrait
    WeaponsRetrait = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        OneHand = {
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_AXE, WEAPONTYPE_HAMMER, WEAPONTYPE_SWORD, WEAPONTYPE_DAGGER}),
            dropdownCallbacks = {
                {name = "Axe", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_AXE})},
                {name = "Hammer", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_HAMMER})},
                {name = "Sword", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_SWORD})},
                {name = "Dagger", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_DAGGER})},
            },
        },
        TwoHand = {
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_TWO_HANDED_AXE, WEAPONTYPE_TWO_HANDED_HAMMER, WEAPONTYPE_TWO_HANDED_SWORD}),
            dropdownCallbacks = {
                {name = "TwoHandAxe", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_TWO_HANDED_AXE})},
                {name = "TwoHandHammer", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_TWO_HANDED_HAMMER})},
                {name = "TwoHandSword", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_TWO_HANDED_SWORD})},
            },
        },
        Bow = {
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_BOW}),
            dropdownCallbacks = {},
        },
        DestructionStaff = {
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_FIRE_STAFF, WEAPONTYPE_FROST_STAFF, WEAPONTYPE_LIGHTNING_STAFF}),
            dropdownCallbacks = {
                {name = "Fire", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_FIRE_STAFF})},
                {name = "Frost", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_FROST_STAFF})},
                {name = "Lightning", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_LIGHTNING_STAFF})},
            },
        },
        HealStaff = {
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_HEALING_STAFF}),
            dropdownCallbacks = {},
        },
    },
--=============================================================================================================================================================================================
    --Armor retrait
    ArmorRetrait = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        Heavy = {
            filterCallback = GetFilterCallbackForArmorType({ARMORTYPE_HEAVY}),
            dropdownCallbacks = {},
        },
        Medium = {
            filterCallback = GetFilterCallbackForArmorType({ARMORTYPE_MEDIUM}),
            dropdownCallbacks = {},
        },
        LightArmor = {
            filterCallback = GetFilterCallbackForArmorType({ARMORTYPE_LIGHT}),
            dropdownCallbacks = {},
        },
        Shield = {
            filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_OFF_HAND}),
            dropdownCallbacks = {
                {name = "Shield", showIcon=true, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_OFF_HAND})},
            },
        },
    },
--=============================================================================================================================================================================================
    --Jewelry retrait
    JewelryRetrait = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        Neck = {
            filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_NECK}),
            dropdownCallbacks = {
                {name = "Arcane", showIcon=true, addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_ARCANE)},
                {name = "Bloodthirsty", showIcon=true, addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY)},
                {name = "Harmony", showIcon=true, addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_HARMONY)},
                {name = "Healthy", showIcon=true, addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_HEALTHY)},
                {name = "Infused", showIcon=true, addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_INFUSED)},
                {name = "Intricate", showIcon=true, addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_INTRICATE)},
                {name = "Ornate", showIcon=true, addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_ORNATE)},
                {name = "Protective", showIcon=true, addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE)},
                {name = "Robust", showIcon=true, addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_ROBUST)},
                {name = "Swift", showIcon=true, addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_SWIFT)},
                {name = "Triune", showIcon=true, addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_TRIUNE)},
            },
        },
        Ring = {
            filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_RING}),
            dropdownCallbacks = {
                {name = "Arcane", showIcon=true, addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_ARCANE)},
                {name = "Bloodthirsty", showIcon=true, addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY)},
                {name = "Harmony", showIcon=true, addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_HARMONY)},
                {name = "Healthy", showIcon=true, addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_HEALTHY)},
                {name = "Infused", showIcon=true, addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_INFUSED)},
                {name = "Intricate", showIcon=true, addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_INTRICATE)},
                {name = "Ornate", showIcon=true, addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_ORNATE)},
                {name = "Protective", showIcon=true, addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE)},
                {name = "Robust", showIcon=true, addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_ROBUST)},
                {name = "Swift", showIcon=true, addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_SWIFT)},
                {name = "Triune", showIcon=true, addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_TRIUNE)},
            },
        },
    },

--=============================================================================================================================================================================================
-- -^- Retrait                                                                                                       -^-
--=============================================================================================================================================================================================

--=============================================================================================================================================================================================
--Not added yet
    --[[
    CreateArmorSmithing = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        Armor = {
            filterCallback = GetFilterCallbackForArmorType({ARMORTYPE_HEAVY}),
        },
    },
    CreateWeaponsSmithing = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        OneHand = {
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_AXE, WEAPONTYPE_HAMMER, WEAPONTYPE_SWORD, WEAPONTYPE_DAGGER}),
            dropdownCallbacks = {
                {name = "Axe", filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_AXE})},
                {name = "Hammer", filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_HAMMER})},
                {name = "Sword", filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_SWORD})},
                {name = "Dagger", filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_DAGGER})},
            },
        },
        TwoHand = {
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_TWO_HANDED_AXE, WEAPONTYPE_TWO_HANDED_HAMMER, WEAPONTYPE_TWO_HANDED_SWORD}),
            dropdownCallbacks = {
                {name = "TwoHandAxe", filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_TWO_HANDED_AXE})},
                {name = "TwoHandHammer", filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_TWO_HANDED_HAMMER})},
                {name = "TwoHandSword", filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_TWO_HANDED_SWORD})},
            },
        },
    },
    CreateArmorClothier = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        Medium = {
            filterCallback = GetFilterCallbackForArmorType({ARMORTYPE_MEDIUM}),
        },
        LightArmor = {
            filterCallback = GetFilterCallbackForArmorType({ARMORTYPE_LIGHT}),
        },
    },
    CreateWeaponsWoodworking = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        Bow = {
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_BOW}),
            dropdownCallbacks = {},
        },
        DestructionStaff = {
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_FIRE_STAFF, WEAPONTYPE_FROST_STAFF, WEAPONTYPE_LIGHTNING_STAFF}),
            dropdownCallbacks = {
                {name = "Fire", filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_FIRE_STAFF})},
                {name = "Frost", filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_FROST_STAFF})},
                {name = "Lightning", filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_LIGHTNING_STAFF})},
            },
        },
        HealStaff = {
            filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_HEALING_STAFF}),
            dropdownCallbacks = {},
        },
    },
    CreateArmorWoodworking = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        Shield = {
            filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_OFF_HAND}),
            dropdownCallbacks = {},
        },
    },
    CreateJewelryCraftingStation = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil),
            dropdownCallbacks = {},
        },
        Neck = {
            filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_NECK}),
            dropdownCallbacks = {
                {name = "Arcane", addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_ARCANE)},
                {name = "Bloodthirsty", addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY)},
                {name = "Harmony", addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_HARMONY)},
                {name = "Healthy", addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_HEALTHY)},
                {name = "Infused", addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_INFUSED)},
                {name = "Intricate", addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_INTRICATE)},
                {name = "Ornate", addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_ORNATE)},
                {name = "Protective", addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE)},
                {name = "Robust", addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_ROBUST)},
                {name = "Swift", addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_SWIFT)},
                {name = "Triune", addString = "Neck", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_NECK}, ITEM_TRAIT_TYPE_JEWELRY_TRIUNE)},
            },
        },
        Ring = {
            filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_RING}),
            dropdownCallbacks = {
                {name = "Arcane", addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_ARCANE)},
                {name = "Bloodthirsty", addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY)},
                {name = "Harmony", addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_HARMONY)},
                {name = "Healthy", addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_HEALTHY)},
                {name = "Infused", addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_INFUSED)},
                {name = "Intricate", addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_INTRICATE)},
                {name = "Ornate", addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_ORNATE)},
                {name = "Protective", addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE)},
                {name = "Robust", addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_ROBUST)},
                {name = "Swift", addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_SWIFT)},
                {name = "Triune", addString = "Ring", filterCallback = GetFilterCallbackForJewelry({EQUIP_TYPE_RING}, ITEM_TRAIT_TYPE_JEWELRY_TRIUNE)},
            },
        },
    },
    ]]
--=============================================================================================================================================================================================
    Junk = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback = GetFilterCallback(nil, true),
            dropdownCallbacks = {},
        },
        Weapon = {
            filterCallback = GetFilterCallback({ITEMTYPE_WEAPON}, true),
            dropdownCallbacks = {
                {name = "OneHand", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_AXE, WEAPONTYPE_HAMMER, WEAPONTYPE_SWORD, WEAPONTYPE_DAGGER}, true)},
                {name = "TwoHand", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_TWO_HANDED_AXE, WEAPONTYPE_TWO_HANDED_HAMMER, WEAPONTYPE_TWO_HANDED_SWORD}, true)},
                {name = "Bow", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_BOW}, true)},
                {name = "DestructionStaff", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_FIRE_STAFF, WEAPONTYPE_FROST_STAFF, WEAPONTYPE_LIGHTNING_STAFF}, true)},
                {name = "HealStaff", showIcon=true, filterCallback = GetFilterCallbackForWeaponType({WEAPONTYPE_HEALING_STAFF}, true)},
            },
        },
        Armor = {
            filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_HEAD, EQUIP_TYPE_CHEST, EQUIP_TYPE_SHOULDERS, EQUIP_TYPE_HAND, EQUIP_TYPE_WAIST, EQUIP_TYPE_LEGS, EQUIP_TYPE_FEET}, nil, true),
            dropdownCallbacks = {
                {name = "Heavy", showIcon=true, filterCallback = GetFilterCallbackForArmorType({ARMORTYPE_HEAVY}, true)},
                {name = "Medium", showIcon=true, filterCallback = GetFilterCallbackForArmorType({ARMORTYPE_MEDIUM}, true)},
                {name = "LightArmor", showIcon=true, filterCallback = GetFilterCallbackForArmorType({ARMORTYPE_LIGHT}, true)},
                --{name = "Clothier", filterCallback = GetFilterCallbackForClothing()},
                {name = "Shield", showIcon=true, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_OFF_HAND}, nil, true)},
                --{name = "Vanity", filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_DISGUISE, EQUIP_TYPE_COSTUME})},
                --{name = "Vanity", filterCallback = GetFilterCallbackForClothing(true)},
            },
        },
        Jewelry = {
            filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_RING, EQUIP_TYPE_NECK}, nil, true),
            dropdownCallbacks = {
                {name = "Ring", showIcon=true, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_RING}, nil, true)},
                {name = "Neck", showIcon=true, filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_NECK}), nil, true},
            },
        },
        Consumable = {
            filterCallback = GetFilterCallback({ITEMTYPE_CROWN_ITEM, ITEMTYPE_FOOD, ITEMTYPE_DRINK, ITEMTYPE_RECIPE, ITEMTYPE_POTION, ITEMTYPE_POISON, ITEMTYPE_RACIAL_STYLE_MOTIF,
                                                ITEMTYPE_CONTAINER, ITEMTYPE_CONTAINER_CURRENCY, ITEMTYPE_AVA_REPAIR, ITEMTYPE_TOOL, ITEMTYPE_CROWN_REPAIR, ITEMTYPE_TROPHY,
                                                ITEMTYPE_COLLECTIBLE, ITEMTYPE_FISH, ITEMTYPE_TREASURE}, true, itemIds.lockpick),
            dropdownCallbacks = {
                {name = "Crown", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_CROWN_ITEM}, true)},
                {name = "Food", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_FOOD}, true)},
                {name = "Drink", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_DRINK}, true)},
                {name = "Recipe", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_RECIPE}, true)},
                {name = "Potion", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_POTION}, true)},
                {name = "Poison", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_POISON}, true)},
                {name = "Motif", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_RACIAL_STYLE_MOTIF}, true)},
                {name = "Writ", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_MASTER_WRIT}, true)},
                {name = "Container", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_CONTAINER, ITEMTYPE_CONTAINER, ITEMTYPE_CONTAINER_CURRENCY}, true, true)},
                {name = "Repair", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_AVA_REPAIR, ITEMTYPE_TOOL, ITEMTYPE_CROWN_REPAIR}, true, itemIds.lockpick)},
                {name = "Trophy", showIcon=true, filterCallback = GetFilterCallbackForTrophy(true)},
            },
        },
        Materials = {
            filterCallback = GetFilterCallbackForSpecializedItemtype({ITEMTYPE_BLACKSMITHING_MATERIAL, ITEMTYPE_BLACKSMITHING_RAW_MATERIAL, ITEMTYPE_BLACKSMITHING_BOOSTER,
                                                ITEMTYPE_CLOTHIER_MATERIAL, ITEMTYPE_CLOTHIER_RAW_MATERIAL, ITEMTYPE_CLOTHIER_BOOSTER,
                                                ITEMTYPE_WOODWORKING_MATERIAL, ITEMTYPE_WOODWORKING_RAW_MATERIAL, ITEMTYPE_WOODWORKING_BOOSTER,
                                                ITEMTYPE_JEWELRYCRAFTING_BOOSTER, ITEMTYPE_JEWELRYCRAFTING_MATERIAL,
                                                ITEMTYPE_REAGENT, ITEMTYPE_POTION_BASE, ITEMTYPE_POISON_BASE,
                                                ITEMTYPE_ENCHANTING_RUNE_ASPECT, ITEMTYPE_ENCHANTING_RUNE_ESSENCE, ITEMTYPE_ENCHANTING_RUNE_POTENCY,
                                                ITEMTYPE_INGREDIENT, ITEMTYPE_STYLE_MATERIAL,
                                                ITEMTYPE_RAW_MATERIAL, ITEMTYPE_JEWELRY_RAW_TRAIT, ITEMTYPE_JEWELRYCRAFTING_RAW_BOOSTER, ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL,
                                                ITEMTYPE_WEAPON_TRAIT, ITEMTYPE_ARMOR_TRAIT, ITEMTYPE_JEWELRY_TRAIT,
                                                ITEMTYPE_FURNISHING_MATERIAL, SPECIALIZED_ITEMTYPE_FURNISHING_MATERIAL_ALCHEMY, SPECIALIZED_ITEMTYPE_FURNISHING_MATERIAL_BLACKSMITHING,
                                                SPECIALIZED_ITEMTYPE_FURNISHING_MATERIAL_CLOTHIER, SPECIALIZED_ITEMTYPE_FURNISHING_MATERIAL_ENCHANTING,
                                                SPECIALIZED_ITEMTYPE_FURNISHING_MATERIAL_JEWELRYCRAFTING, SPECIALIZED_ITEMTYPE_FURNISHING_MATERIAL_PROVISIONING,
                                                SPECIALIZED_ITEMTYPE_FURNISHING_MATERIAL_WOODWORKING,
            }, true, true),
            dropdownCallbacks = {
                {name = "Blacksmithing", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_BLACKSMITHING_MATERIAL, ITEMTYPE_BLACKSMITHING_RAW_MATERIAL, ITEMTYPE_BLACKSMITHING_BOOSTER}, true)},
                {name = "Clothier", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_CLOTHIER_MATERIAL, ITEMTYPE_CLOTHIER_RAW_MATERIAL, ITEMTYPE_CLOTHIER_BOOSTER}, true)},
                {name = "Woodworking", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_WOODWORKING_MATERIAL, ITEMTYPE_WOODWORKING_RAW_MATERIAL, ITEMTYPE_WOODWORKING_BOOSTER}, true)},
                {name = "JewelryCrafting", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_JEWELRYCRAFTING_BOOSTER, ITEMTYPE_JEWELRYCRAFTING_MATERIAL, ITEMTYPE_JEWELRYCRAFTING_RAW_BOOSTER, ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL}, true)},
                {name = "Alchemy", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_REAGENT, ITEMTYPE_POTION_BASE, ITEMTYPE_POISON_BASE}, true)},
                {name = "Enchanting", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_ENCHANTING_RUNE_ASPECT, ITEMTYPE_ENCHANTING_RUNE_ESSENCE, ITEMTYPE_ENCHANTING_RUNE_POTENCY}, true)},
                {name = "Provisioning", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_INGREDIENT}, true)},
                {name = "Style", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_STYLE_MATERIAL, ITEMTYPE_RAW_MATERIAL}, true)},
                {name = "ArmorTrait", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_ARMOR_TRAIT}, true)},
                {name = "WeaponTrait", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_WEAPON_TRAIT}, true)},
                {name = "JewelryAllTrait", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_JEWELRY_RAW_TRAIT, ITEMTYPE_JEWELRY_TRAIT}, true)},
                {name = "Furnishings", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({ITEMTYPE_FURNISHING_MATERIAL, SPECIALIZED_ITEMTYPE_FURNISHING_MATERIAL_ALCHEMY, SPECIALIZED_ITEMTYPE_FURNISHING_MATERIAL_BLACKSMITHING, SPECIALIZED_ITEMTYPE_FURNISHING_MATERIAL_CLOTHIER, SPECIALIZED_ITEMTYPE_FURNISHING_MATERIAL_ENCHANTING, SPECIALIZED_ITEMTYPE_FURNISHING_MATERIAL_JEWELRYCRAFTING, SPECIALIZED_ITEMTYPE_FURNISHING_MATERIAL_PROVISIONING, SPECIALIZED_ITEMTYPE_FURNISHING_MATERIAL_WOODWORKING})},
            },
        },
        Furnishings = {
            filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_FURNISHING_CRAFTING_STATION, SPECIALIZED_ITEMTYPE_FURNISHING_LIGHT, SPECIALIZED_ITEMTYPE_FURNISHING_ORNAMENTAL, SPECIALIZED_ITEMTYPE_FURNISHING_SEATING, SPECIALIZED_ITEMTYPE_FURNISHING_TARGET_DUMMY}, true),
            dropdownCallbacks = {
                {name = "CraftingStation", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_FURNISHING_CRAFTING_STATION})},
                {name = "Light", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_FURNISHING_LIGHT})},
                {name = "Ornamental", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_FURNISHING_ORNAMENTAL})},
                {name = "Seating", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_FURNISHING_SEATING})},
                {name = "TargetDummy", showIcon=true, filterCallback = GetFilterCallbackForSpecializedItemtype({SPECIALIZED_ITEMTYPE_FURNISHING_TARGET_DUMMY})},
            }
        },
        Miscellaneous = {
            filterCallback = GetFilterCallback({ITEMTYPE_GLYPH_ARMOR, ITEMTYPE_GLYPH_JEWELRY, ITEMTYPE_GLYPH_WEAPON, ITEMTYPE_SOUL_GEM, ITEMTYPE_SIEGE, ITEMTYPE_LURE, ITEMTYPE_TOOL, ITEMTYPE_TROPHY, ITEMTYPE_COLLECTIBLE, ITEMTYPE_FISH, ITEMTYPE_TREASURE, ITEMTYPE_TRASH, ITEMTYPE_DISGUISE, ITEMTYPE_TABARD}, true, itemIds.repairtools),
            dropdownCallbacks = {
                {name = "Glyphs", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_GLYPH_ARMOR, ITEMTYPE_GLYPH_JEWELRY, ITEMTYPE_GLYPH_WEAPON}, true)},
                {name = "SoulGem", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_SOUL_GEM}, true)},
                {name = "Siege", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_SIEGE}, true)},
                {name = "Bait", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_LURE}, true)},
                {name = "Tool", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_TOOL}, true, itemIds.repairtools)},
                {name = "Trophy", showIcon=true, filterCallback = GetFilterCallbackForTrophy(true)},
                {name = "Fence", showIcon=true, filterCallback = GetFilterCallbackForFence(true)},
                {name = "Trash", showIcon=true, filterCallback = GetFilterCallback({ITEMTYPE_TRASH}, true)},
                {name = "Vanity", showIcon=true, filterCallback = GetFilterCallbackForClothing(true)},
                --{name = "Costume",  filterCallback = GetFilterCallbackForGear({EQUIP_TYPE_COSTUME})},
            },
        },
    },
--=============================================================================================================================================================================================
    --CUSTOM ADDON TABs
    --[[
    HarvensStolenFilter = {
        addonDropdownCallbacks = {},
        [AF_CONST_ALL] = {
            filterCallback     = GetFilterCallbackForOtherAddon(ITEMFILTERTYPE_AF_HARVENSSTOLENFILTER, false),
            dropdownCallbacks   = {},
        },
    },
    ]]
--=============================================================================================================================================================================================
} --subfilterCallbacks

--Clones of subfilterCallbacks
subfilterCallbacks.JewelryCraftingStation = subfilterCallbacks.Jewelry
--Global variable
AF.subfilterCallbacks = subfilterCallbacks

--Callback functions for external addons, used on AF.util.SubfilterRefresh() filter function to grey out subfilter buttons
AF.SubfilterRefreshCallbacks = {}


------------------------------------------------------------------------------------------------------------------------
-- Global addon/plugin API functions
---------------------------------------------------------------------------------------------------------------------------
local function BuildAddonInformation(filterInformation)
    if filterInformation == nil then return nil end
    local addonInformation = {
        submenuName         = filterInformation.submenuName,
        callbackTable       = filterInformation.callbackTable,
        subfilters          = filterInformation.subfilters,
        excludeSubfilters   = filterInformation.excludeSubfilters,
        generator           = filterInformation.generator,
        excludeFilterPanels = filterInformation.excludeFilterPanels,
        onlyGroups          = filterInformation.onlyGroups,
    }
    --Check the onlyGroups table for entries like Armor or Weapons and split them up into the normal armor + crafting armor filters (same for weapons)
    local onlyGroups = filterInformation.onlyGroups
    if onlyGroups ~= nil and #onlyGroups > 0 then
        local n2c = normalFilter2CraftingFilter
        local nfNames = normalFilterNames
        local aiOnlyGroups = addonInformation.onlyGroups
        if n2c ~= nil and nfNames ~= nil then
            for idx, filterPanelName in pairs(onlyGroups) do
                if nfNames[filterPanelName] then
                    local n2cByName = n2c[filterPanelName]
                    if n2cByName ~= nil then
                        for craftingFilterName, value in pairs(n2cByName) do
                            if value == true and craftingFilterName ~= nil and craftingFilterName ~= "" then
                                table.insert(aiOnlyGroups, craftingFilterName)
                            end
                        end
                    end
                end
            end
        end
    end
    return addonInformation
end

function AdvancedFilters_RemoveDuplicateAddonPlugin(filterInformation, groupName)
    if filterInformation == nil then return false end
    groupName = groupName or filterTypeToGroupName[filterInformation.filterType] or nil
    if groupName == nil then
        return
    end
    local addonInformation = BuildAddonInformation(filterInformation)
    if addonInformation == nil then return false end

    --Check if the same addon information is already in the callback tables for the filterType
    --and remove the old one, before adding the same/newer one again
    local removedDuplicate = false
    local subfilterCallBacksOfGroup = subfilterCallbacks[groupName]
    if subfilterCallBacksOfGroup ~= nil and subfilterCallBacksOfGroup.addonDropdownCallbacks ~= nil then
        local existingAFSubfilterCallbacksInfo = subfilterCallbacks[groupName].addonDropdownCallbacks
        for index, subfilterCallbacksInfo in pairs(existingAFSubfilterCallbacksInfo) do
            --FilterInformation got a submenu? Compare the submenu names and remove exisitng before re-adding this
            if addonInformation.submenuName ~= nil then
                if subfilterCallbacksInfo.submenuName ~= nil and subfilterCallbacksInfo.submenuName == addonInformation.submenuName then
                    --Remove this entry from the subfiltercallbacks as the same submenu will be added again
                    table.remove(existingAFSubfilterCallbacksInfo, index)
                    removedDuplicate = true
                end
            else
                --No submenu name is given: Compare the callbackTable contents
                local newPluginCallbackTable = addonInformation.callbackTable
                local existingSubfilterCallbacksTableAtGroup = subfilterCallbacksInfo.callbackTable
                if newPluginCallbackTable.name ~= nil and existingSubfilterCallbacksTableAtGroup ~= nil then
                    --Check each entry of the exisitng addon dropdown plugin callbackTable
                    for cbTabIndex, cbTabEntry in pairs(existingSubfilterCallbacksTableAtGroup) do
                        if cbTabEntry ~= nil and cbTabEntry.name ~= nil and cbTabEntry.name == newPluginCallbackTable.name then
                            --Same name of the callback plugin table was found: Remove the old plugin callbackTable completely
                            --Remove this entry from the subfiltercallbacks as the same submenu will be added again
                            table.remove(existingAFSubfilterCallbacksInfo, index)
                            removedDuplicate = true
                        end
                    end
                end
            end
        end
    end
    return removedDuplicate
end

function AdvancedFilters_RegisterFilter(filterInformationTable)
--local pluginName = filterInformationTable.callbackTable[1].name or filterInformationTable.submenuName
--zo_callLater(function() d("AdvancedFilters_RegisterFilter: " .. tostring(pluginName)) end, 3000)
    --make sure all necessary information is present
    if filterInformationTable == nil then
        d("[AdvancedFilters_RegisterFilter]No filter information provided. Filter not registered.")
        return
    end
    if filterInformationTable.callbackTable == nil and filterInformationTable.generator == nil then
        d("[AdvancedFilters_RegisterFilter]No callback information provided. Filter not registered.")
        return
    end
    if filterInformationTable.subfilters == nil then
        d("[AdvancedFilters_RegisterFilter]No subfilter type information provided. Filter not registered.")
        return
    end
    if filterInformationTable.filterType == nil then
        d("[AdvancedFilters_RegisterFilter]No base filter type information provided. Filter not registered.")
        return
    end
    if filterInformationTable.enStrings == nil and filterInformationTable.generator == nil then
        d("[AdvancedFilters_RegisterFilter]No English strings provided. Filter not registered.")
        return
    end

    --Parse the filterInformation now and add the plugin data to the dropdown filters
    local function parseFilterInformation(filterInformation)
        --get filter information from the calling addon and insert it into our callback table
        local addonInformation = BuildAddonInformation(filterInformation)
--        local filterTypeToGroupName = AF.filterTypeNames
        local groupName = filterTypeToGroupName[filterInformation.filterType] or nil
        if groupName == nil then
            d("[AdvancedFilters_RegisterFilter]Given \"filterType\" " .. tostring(filterInformation.filterType) .. " in the plugin's filterInformation is not known within the addon.\nPlease see file \"constants.lua\", table \"filterTypeNames\" for valid filterTypes!\nFilter not registered.")
            return
        else
            if subfilterCallbacks[groupName] == nil or subfilterCallbacks[groupName].addonDropdownCallbacks == nil then return end
        end

        --Check if the same addon information is already in the callback tables for the filterType
        --and remove the old one, before adding the same/newer one again
        AdvancedFilters_RemoveDuplicateAddonPlugin(filterInformation, groupName)

        --insert addon information
        table.insert(subfilterCallbacks[groupName].addonDropdownCallbacks, addonInformation)

        --if strings are going to be generated, end registration now
        if filterInformation.generator then return end

        --get string information from the calling addon and insert it into our string table
        --and support setmetatable!
        --> Overwrite exisiting strings with data from the same AF plugin strings, if re-apllied
        local function addStrings(lang, strings, langStrings)
            for key, string in pairs(strings) do
                AF.strings[key] = langStrings and langStrings[key] or string
            end
        end
        local lang = AF.util.GetLanguage()
        addStrings(lang, filterInformation.enStrings, filterInformation[lang .. "Strings"])
    end

    --Support for filterType = table, but not if it's a "generator" run!
    local filterTypes = filterInformationTable.filterType
    if not filterInformationTable.generator and type(filterTypes) == "table" then
        local filterInformationForEachFilterType
        --Call the parse function once for each filterType
        for _, filterInformationFilterType in pairs(filterTypes) do
            if filterInformationFilterType ~= nil and filterInformationFilterType ~= "" then
                --Everything else will be taken 1:1 from "filterInformationTable" table data!
                if filterInformationForEachFilterType == nil then
                    filterInformationForEachFilterType = ZO_DeepTableCopy(filterInformationTable)
                end
                --But just exchange the filterType on each call
                filterInformationForEachFilterType.filterType = filterInformationFilterType
                if filterInformationForEachFilterType ~= nil then
                    parseFilterInformation(filterInformationForEachFilterType)
                end
            end
        end
    else
        parseFilterInformation(filterInformationTable)
    end
end

--Register a filter function for the Subfilterbars buttons so they properly grey out if your addon
--changes filters as well (e.g. FCOCraftFilter will filter by the bagId to hide/only show bank items at crafting tables)
--> See function AF.util.RefreshSubfilterBar -> calling function AF.util.CheckIfOtherAddonsProvideSubfilterBarRefreshFilters
function AdvancedFilters_RegisterSubfilterbarRefreshFilter(filterInformationTable)
--d("[AF]AdvancedFilters_RegisterSubfilterbarRefreshFilter " .. tostring(filterInformationTable.filterName))
    --make sure all necessary information is present
    if filterInformationTable == nil then
        d("[AdvancedFilters_RegisterSubfilterbarRefreshFilter]No filter information provided. Filter not registered.")
        return
    end
    if filterInformationTable.inventoryType == nil then
        d("[AdvancedFilters_RegisterSubfilterbarRefreshFilter]No inventory type information provided. Filter not registered.")
        return
    end
    if filterInformationTable.craftingType == nil then
        d("[AdvancedFilters_RegisterSubfilterbarRefreshFilter]No crafting type information provided. Filter not registered.")
        return
    end
    if filterInformationTable.filterPanelId == nil then
        d("[AdvancedFilters_RegisterSubfilterbarRefreshFilter]No libFilters-2.0 panel Id (LF_ ...) provided. Filter not registered.")
        return
    end
    if filterInformationTable.filterName == nil then
        d("[AdvancedFilters_RegisterSubfilterbarRefreshFilter]No unique filter name provided. Filter not registered.")
        return
    end
    if filterInformationTable.callbackFunction == nil or type(filterInformationTable.callbackFunction) ~= "function" then
        d("[AdvancedFilters_RegisterSubfilterbarRefreshFilter]No callback function provided. Filter not registered.")
        return
    end
    --Register the filter callback function for each inventory type + each crafting type at the inventory type:
    local inventoryTypes = filterInformationTable.inventoryType
    local craftingTypes = filterInformationTable.craftingType
    for _, inventoryType in pairs(inventoryTypes) do
        for _, craftingType in pairs(craftingTypes) do
            --insert subfilterbar refresh filter information from external addon
            if AF.SubfilterRefreshCallbacks[inventoryType] == nil then AF.SubfilterRefreshCallbacks[inventoryType] = {} end
            if AF.SubfilterRefreshCallbacks[inventoryType][craftingType] == nil then AF.SubfilterRefreshCallbacks[inventoryType][craftingType] = {} end
            if AF.SubfilterRefreshCallbacks[inventoryType][craftingType][filterInformationTable.filterPanelId] == nil then AF.SubfilterRefreshCallbacks[inventoryType][craftingType][filterInformationTable.filterPanelId] = {} end
            AF.SubfilterRefreshCallbacks[inventoryType][craftingType][filterInformationTable.filterPanelId][tostring(filterInformationTable.filterName)] = filterInformationTable.callbackFunction
        end
    end
end
