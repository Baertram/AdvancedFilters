AdvancedFilters = AdvancedFilters or {}
local AF = AdvancedFilters

--Utilities
AF.util = AF.util or {}
local util = AF.util

local controlsForChecks = AF.controlsForChecks

--======================================================================================================================
-- -v- Filter plugin functions                                                                                    -v-
--======================================================================================================================
--Slot is the bagId, coming from libFilters, helper function (e.g. deconstruction).
--Prepare the slot variable with bagId and slotIndex
function util.prepareSlot(bagId, slotIndex)
    local slot = {}
    slot.bagId = bagId
    slot.slotIndex = slotIndex
    return slot
end
--======================================================================================================================
-- -^- Filter plugin functions                                                                                    -^-
--======================================================================================================================

--======================================================================================================================
-- -v- Helper functions                                                                                              -v-
--======================================================================================================================
--Get the language of the client
function util.GetLanguage()
    local lang = GetCVar("language.2")
    local supported = {
        de = 1,
        en = 2,
        es = 3,
        fr = 4,
        ru = 5,
        jp = 6,
    }

    --check for supported languages
    if(supported[lang] ~= nil) then return lang end

    --return english if not supported
    return "en"
end

--Localization helper
function util.Localize(text)
    if type(text) == 'number' then
        -- get the string from this constant
        text = GetString(text)
    end
    -- clean up suffixes such as ^F or ^S
    return zo_strformat(SI_TOOLTIP_ITEM_NAME, text) or " "
end

--Run a function throttled (check if it should run already and overwrite the old call then with a new one to
--prevent running it multiple times in a short time)
function util.ThrottledUpdate(callbackName, timer, callback, ...)
    if not callbackName or callbackName == "" or not callback then return end
    local args
    if ... ~= nil then
        args = {...}
    end
    local function Update()
        if AF.settings.debugSpam then d("--->[AF]ThrottledUpdate, callbackName: " ..tostring(callbackName)) end
        EVENT_MANAGER:UnregisterForUpdate(callbackName)
        if args then
            callback(unpack(args))
        else
            callback()
        end
    end
    EVENT_MANAGER:UnregisterForUpdate(callbackName)
    EVENT_MANAGER:RegisterForUpdate(callbackName, timer, Update)
end
--======================================================================================================================
-- -^- Helper functions                                                                                              -^-
--======================================================================================================================

--======================================================================================================================
-- -v Itemlink functions                                                                                           -v-
--======================================================================================================================
function util.GetItemLink(slot)
    --Supporrt for AutoCategory AddOn ->
    -- Collapsable headers in the inventories & crafting stations
    if slot == nil or type(slot) ~= "table" or (slot.isHeader ~= nil and slot.isHeader) then return end
    if slot.bagId and slot.slotIndex then
        return GetItemLink(slot.bagId, slot.slotIndex)
    elseif slot.slotIndex then
        return GetStoreItemLink(slot.slotIndex)
    end
    return
end

--Build an itemlink from an itemId
function util.BuildItemLink(itemId)
    if itemId == nil then return nil end
    return string.format("|H1:item:%d:%d:50:0:0:0:0:0:0:0:0:0:0:0:0:%d:%d:0:0:%d:0|h|h", itemId, 364, ITEMSTYLE_NONE, 0, 10000)
end
--======================================================================================================================
-- -^- Itemlink functions                                                                                           -^-
--======================================================================================================================

--======================================================================================================================
-- -v- Inventory filter functions                                                                                  -v-
--======================================================================================================================
function util.GetCurrentFilterTypeForInventory(invType, forLibFiltersRegister)
    if invType == nil then return end
    forLibFiltersRegister = forLibFiltersRegister or false
    local filterType
    local curInvType = AF.currentInventoryType
    --Check if a custom invetory filterBar button was added and we are trying to show the subfilterBar etc. for it
    --[[
    if curInvType and util.CheckIfIsCustomAddonInventoryFilterButtonItemFilterType(curInvType) then
        --Used to add/update the subfilterBars of AdvancedFilters at first
        filterType = util.GetCurrentFilter(curInvType)

        --Then check: Used for adding the filters to LibFilters properly?
        --We cannot use the custom itemFilterTypes here as LibFilters does not work with them, and only uses
        --the filter constants LF_*
        --So map the custom itemFilterType to the LibFiltersPanelId here
        if forLibFiltersRegister then
            local libFiltersPanelIdForCustomAddonItemFilterType = util.MapCustomAddonItemFilterType2LibFiltersPanelId(filterType)
            if libFiltersPanelIdForCustomAddonItemFilterType then
                filterType = libFiltersPanelIdForCustomAddonItemFilterType
            end
        end
    else
    ]]
        --Check all other normal inventory types
        if invType == INVENTORY_TYPE_VENDOR_BUY then
            filterType = LF_VENDOR_BUY
        elseif util.IsCraftingStationInventoryType(invType) then
            filterType = curInvType
        else
            filterType = util.LibFilters:GetCurrentFilterTypeForInventory(invType)
        end
    --end
    if AF.settings.debugSpam then  d("[AF]util.GetCurrentFilterTypeForInventory - invType: " ..tostring(invType) .. ", filterType: " ..tostring(filterType)) end
    if not filterType then return end
    return filterType
end

--Get the currentFilter of an inventory type
function util.GetCurrentFilter(invType)
    if not invType then return end
    local currentFilter

    --Crafting
    local isCraftingInventoryType = false
    local subfilterGroup = AF.subfilterGroups[invType]
    local craftingType = util.GetCraftingType()
    local subfilterBarBase = subfilterGroup[craftingType]
    local subfilterBar = subfilterBarBase[currentFilter]
    if util.IsCraftingPanelShown() and subfilterBar then
        isCraftingInventoryType = util.IsCraftingStationInventoryType(subfilterBar.inventoryType)
    end

    if invType == INVENTORY_TYPE_VENDOR_BUY then
        currentFilter = controlsForChecks.store.currentFilter
    elseif isCraftingInventoryType then
        if isCraftingInventoryType then
            local craftingInv = subfilterBar and util.GetInventoryFromCraftingPanel(subfilterBar.inventoryType)
            if not craftingInv then return end
            currentFilter = craftingInv.currentFilter
        end
    else
        --Get the player inventory for the inventory type
        local playerInv = PLAYER_INVENTORY.inventories[invType]
        if not playerInv then return end
        --Get the currentFilter of the inventory
        currentFilter = playerInv.currentFilter
        if not currentFilter then return end
    end
    return currentFilter
end

--Update the currentFilter to the current inventory or crafting inventory
function util.UpdateCurrentFilter(invType, currentFilter, isCraftingInventoryType, craftingInv)
    if AF.settings.debugSpam then d("[AF]util.UpdateCurrentFilter - invType: " .. tostring(invType) .. ", currentFilter: " ..tostring(currentFilter).. ", isCraftingInventoryType: " ..tostring(isCraftingInventoryType)) end
    if invType == nil or currentFilter == nil then return nil end
    isCraftingInventoryType = isCraftingInventoryType or false
    if isCraftingInventoryType and craftingInv == nil then
        if AF.settings.debugSpam then d("<<ABORT[AF]util.UpdateCurrentFilter - is crafting but craftingInv var missing!") end
        return false
    end
    --set currentFilter since we need it before the original ChangeFilter updates it
    if invType == INVENTORY_TYPE_VENDOR_BUY then
        controlsForChecks.store.currentFilter = currentFilter
    elseif isCraftingInventoryType then
        craftingInv.currentFilter = currentFilter
    else
        if not PLAYER_INVENTORY.inventories[invType] then
            if AF.settings.debugSpam then d("<<ABORT[AF]util.UpdateCurrentFilter - invType missing in PLAYER_INVENTORY.inventories!") end
            return false
        end
        PLAYER_INVENTORY.inventories[invType].currentFilter = currentFilter
    end
end

--Get the current inventory filterBar button's data
function AF.util.GetActiveInventoryFilterBarButtonData(invType)
    if AF.settings.debugSpam then d("[AF]GetActiveInventoryFilterBarButtonData-invType: "..tostring(invType)) end
    if not invType then return end
    local playerInv = PLAYER_INVENTORY.inventories[invType]
    if not playerInv then return end
    local filterBar = playerInv.filterBar
    if not filterBar then return end
    local currentlySelectedInventoryFilterBarButton = filterBar.m_object.m_clickedButton
    return currentlySelectedInventoryFilterBarButton
end

--======================================================================================================================
-- -^- Inventory filter functions                                                                                  -^-
--======================================================================================================================

--======================================================================================================================
-- -v- Mapping functions                                                                                            -v-
--======================================================================================================================
--Map the groupName to it's filterType
function util.MapGroupNameToFilterType(groupName)
    if not groupName then return end
    local filterTypeNames = AF.filterTypeNames
    if not filterTypeNames then return end
    for filterType, groupNameToCompare in pairs(filterTypeNames) do
        if groupNameToCompare == groupName then
            return filterType
        end
    end
    return
end

function util.MapLibFiltersInventoryTypeToRealInventoryType(inventoryType)
    --One Libfilters inventoryType can have up to 4 different real inventory types:
    --e.g. Crafting deconstruction can happen for bagpack, bank and house_bank items
    -- whereas crafting creation can use bagpack, bank, house_bank and craftabg items, etc.
    if inventoryType == nil then return nil end
    local mapLibFiltersInvToRealInvType1 = {
        [LF_RETRAIT]                = INVENTORY_BACKPACK,
        [LF_SMITHING_REFINE]        = INVENTORY_BACKPACK,
        [LF_SMITHING_CREATION]      = INVENTORY_BACKPACK,
        [LF_SMITHING_DECONSTRUCT]   = INVENTORY_BACKPACK,
        [LF_SMITHING_IMPROVEMENT]   = INVENTORY_BACKPACK,
        [LF_SMITHING_RESEARCH]      = INVENTORY_BACKPACK,
        [LF_ENCHANTING_CREATION]    = INVENTORY_BACKPACK,
        [LF_ENCHANTING_EXTRACTION]  = INVENTORY_BACKPACK,
        [LF_JEWELRY_REFINE]         = INVENTORY_BACKPACK,
        [LF_JEWELRY_CREATION]       = INVENTORY_BACKPACK,
        [LF_JEWELRY_DECONSTRUCT]    = INVENTORY_BACKPACK,
        [LF_JEWELRY_IMPROVEMENT]    = INVENTORY_BACKPACK,
        [LF_JEWELRY_IMPROVEMENT]    = INVENTORY_BACKPACK,
        [LF_JEWELRY_RESEARCH]      = INVENTORY_BACKPACK,
    }
    local mapLibFiltersInvToRealInvType2 = {
        [LF_RETRAIT]                = INVENTORY_BANK,
        [LF_SMITHING_REFINE]        = INVENTORY_BANK,
        [LF_SMITHING_CREATION]      = INVENTORY_BACKPACK,
        [LF_SMITHING_DECONSTRUCT]   = INVENTORY_BANK,
        [LF_SMITHING_IMPROVEMENT]   = INVENTORY_BANK,
        [LF_SMITHING_RESEARCH]      = INVENTORY_BANK,
        [LF_ENCHANTING_CREATION]    = INVENTORY_BANK,
        [LF_ENCHANTING_EXTRACTION]  = INVENTORY_BANK,
        [LF_JEWELRY_REFINE]         = INVENTORY_BANK,
        [LF_JEWELRY_CREATION]       = INVENTORY_BANK,
        [LF_JEWELRY_DECONSTRUCT]    = INVENTORY_BANK,
        [LF_JEWELRY_IMPROVEMENT]    = INVENTORY_BANK,
        [LF_JEWELRY_RESEARCH]       = INVENTORY_BANK,
    }
    local mapLibFiltersInvToRealInvType3 = {
        [LF_RETRAIT]                = INVENTORY_HOUSE_BANK,
        [LF_SMITHING_REFINE]        = INVENTORY_HOUSE_BANK,
        [LF_SMITHING_CREATION]      = INVENTORY_BACKPACK,
        [LF_SMITHING_DECONSTRUCT]   = INVENTORY_HOUSE_BANK,
        [LF_SMITHING_IMPROVEMENT]   = INVENTORY_HOUSE_BANK,
        [LF_ENCHANTING_CREATION]    = INVENTORY_HOUSE_BANK,
        [LF_ENCHANTING_EXTRACTION]  = INVENTORY_HOUSE_BANK,
        [LF_JEWELRY_REFINE]         = INVENTORY_HOUSE_BANK,
        [LF_JEWELRY_CREATION]       = INVENTORY_HOUSE_BANK,
        [LF_JEWELRY_DECONSTRUCT]    = INVENTORY_HOUSE_BANK,
        [LF_JEWELRY_IMPROVEMENT]    = INVENTORY_HOUSE_BANK,
    }
    local mapLibFiltersInvToRealInvType4 = {
        [LF_SMITHING_REFINE]        = INVENTORY_CRAFT_BAG,
        [LF_SMITHING_CREATION]      = INVENTORY_CRAFT_BAG,
        [LF_ENCHANTING_CREATION]    = INVENTORY_CRAFT_BAG,
        [LF_JEWELRY_REFINE]         = INVENTORY_CRAFT_BAG,
        [LF_JEWELRY_CREATION]       = INVENTORY_CRAFT_BAG,
    }
    local realInvType1 = mapLibFiltersInvToRealInvType1[inventoryType] or nil
    local realInvType2 = mapLibFiltersInvToRealInvType2[inventoryType] or nil
    local realInvType3 = mapLibFiltersInvToRealInvType3[inventoryType] or nil
    local realInvType4 = mapLibFiltersInvToRealInvType4[inventoryType] or nil
    local realInvTypes = {}
    if realInvType1 ~= nil then table.insert(realInvTypes, realInvType1) end
    if realInvType2 ~= nil then table.insert(realInvTypes, realInvType2) end
    if realInvType3 ~= nil then table.insert(realInvTypes, realInvType3) end
    if realInvType4 ~= nil then table.insert(realInvTypes, realInvType4) end
    return realInvTypes
end
--======================================================================================================================
-- -^- Mapping functions                                                                                            -^-
--======================================================================================================================

--======================================================================================================================
-- -v- Dropdown box functions                                                                                       -v-
--======================================================================================================================
--Check if the current panel should show the dropdown "addon filters" for "all" too
function util.checkIfPanelShouldShowAddonAllDropdownFilters(invType)
    if AF.settings.debugSpam then
        --d("[AF]checkIfPanelShouldShowAddonAllDropdownFilters - invType: " .. tostring(invType))
    end
    if invType == nil then return true end
    local inv2ShowAddonAllDropdownFilters = {
        [LF_ENCHANTING_CREATION]    = false,
        [LF_ENCHANTING_EXTRACTION]  = false,
        --[LF_SMITHING_REFINE]        = false,
        [LF_SMITHING_CREATION]      = false,
        [LF_JEWELRY_CREATION]       = false,
    }
    local showAtInv = true
    if inv2ShowAddonAllDropdownFilters[invType] ~= nil then
        showAtInv = inv2ShowAddonAllDropdownFilters[invType]
    end
    return showAtInv
end

--Build the subfilterBar's dropdown box filter callback tables and functions
function util.BuildDropdownCallbacks(groupName, subfilterName)
    local doDebugOutput = AF.settings.doDebugOutput
    local subfilterNameOrig = subfilterName
    if groupName == "Armor" and (subfilterName == "Heavy" or subfilterName == "Medium" or subfilterName == "LightArmor" or subfilterName == "Clothing") then subfilterName = "Body" end
    --if doDebugOutput or AF.settings.debugSpam then d("=========================\n[AF]]BuildDropdownCallbacks - groupName: " .. tostring(groupName) .. ", subfilterName: " .. tostring(subfilterName) .. ", subFilterNameOrig: " ..tostring(subfilterNameOrig)) end
    local callbackTable = {}
    local keys = AF.dropdownCallbackKeys
    local craftBagFilterGroups = AF.craftBagFilterGroups
    local subfilterCallbacks = AF.subfilterCallbacks
    local invOrFilterType = util.GetCurrentFilterTypeForInventory(AF.currentInventoryType)

    ------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------
    local function insertAddon(addonTable, groupNameLocal, subfilterNameLocal)
        groupNameLocal = groupNameLocal or ""
        subfilterNameLocal = subfilterNameLocal or subfilterNameLocal
        if AF.settings.doDebugOutput then
            AF._addonTable = AF._addonTable or {}
            table.insert(AF._addonTable, addonTable)
        end
        local addonName = ""
        if addonTable.name ~= nil and addonTable.name ~= "" then
            addonName = addonTable.name
        elseif addonTable.submenuName ~= nil and addonTable.submenuName ~= "" then
            addonName = addonTable.submenuName
        else
            addonName = addonTable.callbackTable[1].name
        end
        --if doDebugOutput or AF.settings.debugSpam then d("->insertAddon addonName: '" .. tostring(addonName) .."', groupNameLocal: '" .. tostring(groupNameLocal) .. "', subfilterNameLocal: '" .. tostring(subfilterNameLocal).. "'") end

        --generate information if necessary
        if addonTable.generator then
            local strings

            addonTable.callbackTable, strings = addonTable.generator()

            for key, string in pairs(strings) do
                AF.strings[key] = string
            end
        end

        --Is the addon filter not to be shown at some libFilter panels?
        if addonTable.excludeFilterPanels ~= nil then
            --if doDebugOutput or AF.settings.debugSpam then d(">>excludeFilterPanels: Yes") end
            if type(addonTable.excludeFilterPanels) == "table" then
                for _, filterPanelToExclude in pairs(addonTable.excludeFilterPanels) do
                    if invOrFilterType == filterPanelToExclude then
                        --if doDebugOutput or AF.settings.debugSpam then d(">>>insertAddon - filterPanelToExclude: " ..tostring(filterPanelToExclude)) end
                        return
                    else
                        --if doDebugOutput or AF.settings.debugSpam then d(">>>insertAddon - filterPanelToExclude: " ..tostring(filterPanelToExclude) .. " <> filterType: "..tostring(invOrFilterType)) end
                    end
                end
            else
                if invOrFilterType == addonTable.excludeFilterPanels then
                    --if doDebugOutput or AF.settings.debugSpam then d(">>>insertAddon - filterPanelToExclude: " ..tostring(addonTable.excludeFilterPanels)) end
                    return
                end
            end
        end

        --Only add the entries if the group name specified "to be used" are the given ones
        if groupNameLocal ~= AF_CONST_ALL and addonTable.onlyGroups ~= nil then
            --if doDebugOutput or AF.settings.debugSpam then d(">>onlyGroups: Yes") end
            if type(addonTable.onlyGroups) == "table" then
                local allowedgroupNameLocals = {}
                for _, groupNameLocalToCheck in pairs(addonTable.onlyGroups) do
                    --groupNameLocal "Craftbag" stands for several group names, so add them all
                    if groupNameLocalToCheck == "Craftbag" then
                        for _, craftBagGroup in pairs(craftBagFilterGroups) do
                            allowedgroupNameLocals[craftBagGroup] = true
                        end
                    end
                    allowedgroupNameLocals[groupNameLocalToCheck] = true
                end
                if not allowedgroupNameLocals[groupNameLocal] then
                    --if doDebugOutput or AF.settings.debugSpam then d("-->insertAddon - onlyGroups, not allowed group: " ..tostring(groupNameLocal)) end
                    return
                end
            else
                if addonTable.onlyGroups == "Craftbag" then
                    local allowedgroupNameLocals = {}
                    --groupNameLocal "Craftbag" stands for several group names, so add them all
                    for _, craftBagGroup in pairs(craftBagFilterGroups) do
                        allowedgroupNameLocals[craftBagGroup] = true
                    end
                    if not allowedgroupNameLocals[groupNameLocal] then
                        --if doDebugOutput or AF.settings.debugSpam then d("-->insertAddon - onlyGroups, not allowed group: " ..tostring(groupNameLocal)) end
                        return
                    end

                else
                    if groupNameLocal ~= addonTable.onlyGroups then
                        --if doDebugOutput or AF.settings.debugSpam then d("-->insertAddon - onlyGroups, not allowed group: " ..tostring(addonTable.onlyGroups)) end
                        return
                    end
                end
            end
        end

        --Should any subfilter be excluded?
        if addonTable.excludeSubfilters ~= nil then
            --if doDebugOutput or AF.settings.debugSpam then d(">>excludeSubfilters: Yes") end
            if type(addonTable.excludeSubfilters) == "table" then
                for _, subfilterNameLocalToExclude in pairs(addonTable.excludeSubfilters) do
                    if subfilterNameOrig == subfilterNameLocalToExclude or subfilterNameLocal == subfilterNameLocalToExclude then
                        --if doDebugOutput or AF.settings.debugSpam then d("--->insertAddon - excludeSubfilters: " ..tostring(subfilterNameLocalToExclude)) end
                        return
                    else
                        --if doDebugOutput or AF.settings.debugSpam then d("--->insertAddon - excludeSubfilter '" ..tostring(subfilterNameLocalToExclude) .. "' <> ' " ..tostring(subfilterNameOrig) .. "/" .. tostring(subfilterNameLocal)) end
                    end
                end
            else
                if subfilterNameOrig == addonTable.excludeSubfilters or subfilterNameLocal == addonTable.excludeSubfilters then
                    --if doDebugOutput or AF.settings.debugSpam then d("--->insertAddon - excludeSubfilters: " ..tostring(subfilterNameLocal)) end
                    return
                end
            end
        end

        --was the same addon filter already added before via the "ALL" type
        --only check if the groupNameLocal not equals "ALL", and if the duplicate checks should be done
        --e.g. they are not needed as the global addon filters get added
        if groupNameLocal ~= AF_CONST_ALL then --and subfilterNameLocal == AF_CONST_ALL then
            --Build names to compare
            local compareNames = {}
            if addonTable.submenuName then
                table.insert(compareNames, addonTable.submenuName)
            else
                if addonTable.callbackTable then
                    for _, callbackTableNameEntry in ipairs(addonTable.callbackTable) do
                        table.insert(compareNames, callbackTableNameEntry.name)
                    end
                end
            end
            --Compare names with the entries in dropdownbox now
            for _, compareName in ipairs(compareNames) do
                --Check the whole callback table for entries with the same name or submenuName
                for _, callbackTableEntry in ipairs(callbackTable) do
                    if callbackTableEntry.submenuName then
                        if callbackTableEntry.submenuName == compareName then
                            --if doDebugOutput or AF.settings.debugSpam then d(">Duplicate submenu entry: " .. tostring(callbackTableEntry.submenuName)) end
                            return
                        end
                    else
                        if callbackTableEntry.name and callbackTableEntry.name == compareName then
                            --if doDebugOutput or AF.settings.debugSpam then d(">Duplicate entry: " .. tostring(callbackTableEntry.name)) end
                            return
                        end
                    end
                end
            end
        end

        --check to see if addon is set up for a submenu
        if addonTable.submenuName then
            --insert whole package
            table.insert(callbackTable, addonTable)
        else
            --insert all callbackTable entries
            local currentAddonTable = addonTable.callbackTable
            for _, callbackEntry in ipairs(currentAddonTable) do
                table.insert(callbackTable, callbackEntry)
            end
        end
    end -- function "insertAddon"
    ------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------

    -- insert global AdvancedFilters "All" filters
    for _, callbackEntry in ipairs(subfilterCallbacks[AF_CONST_ALL].dropdownCallbacks) do
        callbackEntry.isStandardAFDropdownFilter = true
        table.insert(callbackTable, callbackEntry)
    end

    --insert filters that apply to a group, but not the ALL entry!
    if groupName ~= AF_CONST_ALL then
        --insert global "All" filters for a "group". e.g. Group "Jewelry", entry "All" -> subfilterCallbacks[Jewelry].All
        for _, callbackEntry in ipairs(subfilterCallbacks[groupName].All.dropdownCallbacks) do
            callbackEntry.isStandardAFDropdownFilter = true
            table.insert(callbackTable, callbackEntry)
        end
        --Subfilter is the ALL entry?
        if subfilterName == AF_CONST_ALL then
            local groupNameOfKeys = keys[groupName]
            if groupNameOfKeys == nil then
                d("[AdvancedFilters] ERROR - util.BuildDropdownCallbacks-GroupName is missing in keys: " ..tostring(groupName) .. ". Please contact the author of ".. tostring(AF.name) .. " at the website in the settings menu (link can be found at the top of the settings page)!")
                return
            --elseif AF.settings.debugSpam then d("[AF]util.BuildDropdownCallbacks-GroupName: " ..tostring(groupName))
            end
            --insert all default AdvancedFilters filters for each subfilter (see file data.lua -> table AF.subfilterCallbacks)
            for _, subfilterNameLoop in ipairs(groupNameOfKeys) do
                local currentSubfilterTable = subfilterCallbacks[groupName][subfilterNameLoop]
                for _, callbackEntry in ipairs(currentSubfilterTable.dropdownCallbacks) do
                    callbackEntry.isStandardAFDropdownFilter = true
                    table.insert(callbackTable, callbackEntry)
                end
            end

            --insert all filters provided by plugins / other addons
            --but check if the current panel should show the addon filters for "all" too
            if util.checkIfPanelShouldShowAddonAllDropdownFilters(invOrFilterType) then
                --if doDebugOutput or AF.settings.debugSpam then d(">add addon dropdown filters to group's '" .. tostring(groupName) .."' 'ALL' filters") end
                for _, addonTable in ipairs(subfilterCallbacks[groupName].addonDropdownCallbacks) do
                    insertAddon(addonTable, groupName, subfilterName)
                end
            end
            --Subfilter is NOT the ALL entry
        else
            --insert standard AdvancedFilters filters for provided subfilter
            local currentSubfilterTable = subfilterCallbacks[groupName][subfilterName]
            for _, callbackEntry in ipairs(currentSubfilterTable.dropdownCallbacks) do
                callbackEntry.isStandardAFDropdownFilter = true
                table.insert(callbackTable, callbackEntry)
            end

            --insert filters provided by addons for this subfilter
            for _, addonTable in ipairs(subfilterCallbacks[groupName].addonDropdownCallbacks) do
                --scan addon to see if it applies to given subfilter
                for _, subfilter in ipairs(addonTable.subfilters) do
                    if subfilter == subfilterName or subfilter == AF_CONST_ALL then
                        --add addon filters
                        insertAddon(addonTable, groupName, subfilterName)
                    end
                end
            end
        end
    end

    --insert global addon filters
    --but check if the current panel should show the addon filters for "all" too
    if util.checkIfPanelShouldShowAddonAllDropdownFilters(invOrFilterType) then
        --if AF.settings.debugSpam then d(">show addon dropdown 'ALL' filters") end
        for _, addonTable in ipairs(subfilterCallbacks.All.addonDropdownCallbacks) do
            insertAddon(addonTable, groupName, subfilterName)
        end
    end

    return callbackTable
end
--======================================================================================================================
-- -^- Dropdown box functions                                                                                       -^-
--======================================================================================================================

--======================================================================================================================
-- -v- Inventory count functions                                                                                    -v-
--======================================================================================================================
--Do not update the inventories itemCount as it got no count label or no value to update
--(e.g. smithing research panel)
function util.DoNotUpdateInventoryItemCount(filterTypeToUse)
    filterTypeToUse = filterTypeToUse or util.GetCurrentFilterTypeForInventory(AF.currentInventoryType)
    local doNotUpdateInventoryItemCountFilterPanels = {
        [LF_SMITHING_CREATION]          = true,
        [LF_SMITHING_RESEARCH]          = true,
        [LF_JEWELRY_CREATION]           = true,
        [LF_JEWELRY_RESEARCH]           = true,
        [LF_SMITHING_RESEARCH_DIALOG]   = true,
        [LF_JEWELRY_RESEARCH_DIALOG]    = true,
    }
    local doNotUpdateInventoryItemCountAtFilterPanel = doNotUpdateInventoryItemCountFilterPanels[filterTypeToUse] or false
    if AF.settings.debugSpam then d("[AF]util.DoNotUpdateInventoryItemCount, filterTypeToUse: " ..tostring(filterTypeToUse) .. ", doNotUpdate: " ..tostring(doNotUpdateInventoryItemCountAtFilterPanel)) end
    return doNotUpdateInventoryItemCountAtFilterPanel
end

--Add count of shown (filtered) items to the inventory: space/total (count)
function util.getInvItemCount(freeSlotType, isCraftingInvType)
    --if AF.settings.debugSpam then d("[AF]util.getInvItemCount-freeSlotType: " .. tostring(freeSlotType) .. ", isCraftingInvType: " .. tostring(isCraftingInvType)) end
    local itemCount
    local invType
    if freeSlotType ~= nil then
        invType = freeSlotType
    else
        invType = AF.currentInventoryType
    end
    if invType == nil then return nil end
    isCraftingInvType = isCraftingInvType or util.IsCraftingStationInventoryType(invType)
    if not isCraftingInvType then
        if PLAYER_INVENTORY.inventories[invType] == nil then return nil end
        local invListViewData = PLAYER_INVENTORY.inventories[invType].listView.data
        if invListViewData then
            itemCount = #invListViewData
        end
    else
        local craftingInvCtrl = util.GetInventoryFromCraftingPanel(freeSlotType) or nil
        if craftingInvCtrl == nil or craftingInvCtrl.list == nil then return nil end
        local craftingInvSlotCountCtrl = craftingInvCtrl.list.data or nil
        if craftingInvSlotCountCtrl == nil then return nil end
        itemCount = #craftingInvSlotCountCtrl
    end
    return itemCount
end

--Update the inventory infobar lFreeSlot label with the item filtered count
function util.updateInventoryInfoBarCountLabel(invType, isCraftingInvType, isCalledFromExternalAddon)
    invType = invType or AF.currentInventoryType
    if util.DoNotUpdateInventoryItemCount(invType) then return end
    isCraftingInvType = isCraftingInvType or util.IsCraftingStationInventoryType(invType)
    isCalledFromExternalAddon = isCalledFromExternalAddon or false
    if AF.settings.debugSpam then d("[AF]util.updateInventoryInfoBarCountLabel-invType: " ..tostring(invType) .. ", isCraftingInvType: " .. tostring(isCraftingInvType) .. ", isCalledFromExternalAddon: " .. tostring(isCalledFromExternalAddon)) end
    --Update the count of shown/filtered items in the inventory FreeSlots label
    if invType ~= nil then
        if not isCraftingInvType then
            --Call the update function for the player inventories
            if PLAYER_INVENTORY.inventories ~= nil and PLAYER_INVENTORY.inventories[invType] ~= nil then
                PLAYER_INVENTORY:UpdateFreeSlots(invType)
            end
        else
            --Call the update function for the crafting tables inventories now, see file "main.lua"
            -->Overwritten function UpdateInventorySlots(infoBar)
            --Ge the infoBar first
            local craftingInvCtrl = util.GetInventoryFromCraftingPanel(invType) or nil
            if craftingInvCtrl == nil then return nil end
            local craftingInvCtrlControl = craftingInvCtrl.control or nil
            if craftingInvCtrlControl == nil then return nil end
            local infoBar = craftingInvCtrlControl:GetNamedChild("InfoBar")
            --Now call update function
            if infoBar ~= nil then
                if UpdateInventorySlots then UpdateInventorySlots(infoBar) end
            end
        end
    end
end

--Update the crafting table's inventory item count etc. from external addons
function util.UpdateCraftingInventoryFilteredCount(invType)
    if AF.settings.debugSpam then d("[AF]util.UpdateCraftingInventoryFilteredCount - invType: " ..tostring(invType)) end
    util.updateInventoryInfoBarCountLabel(invType, nil, true)
end
--======================================================================================================================
-- -^- Inventory count functions                                                                                    -^-
--======================================================================================================================

--======================================================================================================================
-- -v- IsShown functions                                                                                            -v-
--======================================================================================================================
--Check if a game scene is shown
function util.IsSceneShown(sceneName)
    --if AF.settings.debugSpam then d("[AF]util.IsSceneShown, sceneName: " ..tostring(sceneName)) end
    if sceneName == nil then return false end
    local currentSceneName = SCENE_MANAGER.currentScene.name
    --d(">currentSceneName: " .. tostring(currentSceneName))
    if currentSceneName ~= nil and currentSceneName == sceneName then
        return true
    end
    return false
end

--Check if a LibFilters-3.0 filterPanelId (or a related control) is shown
function util.IsFilterPanelShown(libFiltersFilterPanelId)
    --if AF.settings.debugSpam then d("[AF]IsFilterPanelShown: " ..tostring(libFiltersFilterPanelId)) end
    if libFiltersFilterPanelId == nil then return false end
    local controlInventory = controlsForChecks.invList
    local controlVendorBuy = controlsForChecks.storeWindow
    local controlVendorBuyback = controlsForChecks.buyBackList
    local controlVendorRepair = controlsForChecks.repairWindow
    local controlBankDeposit = controlsForChecks.bankBackpack
    local controlGuildBankDeposit = controlsForChecks.guildBankBackpack
    local controlGuildStoreSell = controlsForChecks.guildStoreSellBackpack
    local controlsFence = controlsForChecks.fence
    local scenesForChecks = AF.scenesForChecks
    local sceneNameStoreVendor = scenesForChecks.storeVendor
    local sceneNameBankDeposit = scenesForChecks.bank
    local sceneNameGuildBankDeposit = scenesForChecks.guildBank
    local sceneNameGuildStoreSell = scenesForChecks.guildStoreSell
    local sceneNameFence = scenesForChecks.fence
    local filterPanelId2TrueControl = {
        [LF_VENDOR_BUY]         = function() return not controlVendorBuy:IsHidden() and controlInventory:IsHidden() and controlVendorBuyback:IsHidden() and controlVendorRepair:IsHidden() or false end,
        [LF_VENDOR_SELL]        = function() return controlVendorBuy:IsHidden() and not controlInventory:IsHidden() and controlVendorBuyback:IsHidden() and controlVendorRepair:IsHidden() or false end,
        [LF_VENDOR_BUYBACK]     = function() return controlVendorBuy:IsHidden() and controlInventory:IsHidden() and not controlVendorBuyback:IsHidden() and controlVendorRepair:IsHidden() or false end,
        [LF_VENDOR_REPAIR]      = function() return controlVendorBuy:IsHidden() and controlInventory:IsHidden() and controlVendorBuyback:IsHidden() and not controlVendorRepair:IsHidden() or false end,
        [LF_BANK_DEPOSIT]       = controlInventory,
        [LF_GUILDBANK_DEPOSIT]  = controlInventory,
        [LF_HOUSE_BANK_DEPOSIT] = controlInventory,
        [LF_GUILDSTORE_SELL]    = controlGuildStoreSell,
        [LF_FENCE_SELL]         = function() return (not controlsFence.control:IsHidden() and controlsFence.mode == ZO_MODE_STORE_SELL_STOLEN) or false end,
        [LF_FENCE_LAUNDER]      = function() return (not controlsFence.control:IsHidden() and controlsFence.mode == ZO_MODE_STORE_LAUNDER) or false end,
    }
    local filterPanelId2FalseControl = {
        [LF_BANK_DEPOSIT]       = controlBankDeposit,
        [LF_GUILDBANK_DEPOSIT]  = controlGuildBankDeposit,
        [LF_HOUSE_BANK_DEPOSIT] = controlBankDeposit,
    }
    local filterPanelId2SceneName = {
        [LF_VENDOR_BUY]         = sceneNameStoreVendor,
        [LF_VENDOR_SELL]        = sceneNameStoreVendor,
        [LF_VENDOR_BUYBACK]     = sceneNameStoreVendor,
        [LF_VENDOR_REPAIR]      = sceneNameStoreVendor,
        [LF_BANK_DEPOSIT]       = sceneNameBankDeposit,
        [LF_GUILDBANK_DEPOSIT]  = sceneNameGuildBankDeposit,
        [LF_HOUSE_BANK_DEPOSIT] = sceneNameBankDeposit,
        [LF_GUILDSTORE_SELL]    = sceneNameGuildStoreSell,
        [LF_FENCE_SELL]         = sceneNameFence,
        [LF_FENCE_LAUNDER]      = sceneNameFence,
    }
    local goOn = true
    local trueSceneName = filterPanelId2SceneName[libFiltersFilterPanelId] or nil
    --Check if a scene needs to be checked
    if trueSceneName ~= nil then
        goOn = false
        --Check the active scene
        if util.IsSceneShown(trueSceneName) then
            goOn = true
        else
            --No scene found but needs one. Abort!
            return false
        end
    end
    --Scene was checked, shall we go on?
    if not goOn then return false end
    --Check if a control needs to be shown
    goOn = false
    local trueControl
    local trueControlCheck = filterPanelId2TrueControl[libFiltersFilterPanelId] or nil
    if trueControlCheck ~= nil then
        if type(trueControlCheck) == "function" then
            trueControl = trueControlCheck() or false
        elseif type(trueControlCheck) == "boolean" then
            trueControl = trueControlCheck or false
        else
            trueControl = trueControlCheck.IsHidden ~= nil and not trueControlCheck:IsHidden() or false
        end
    end
    if trueControl ~= nil and trueControl == true then
        goOn = true
    else
        --Control(s) must be shown but isn't? Abort!
        return false
    end
    --True control was checked, shall we go on?
    if not goOn then return false end
    --Check if a control needs to be hidden
    goOn = false
    local falseControl
    local falseControlCheck = filterPanelId2FalseControl[libFiltersFilterPanelId] or nil
    if falseControlCheck ~= nil then
        if type(falseControlCheck) == "function" then
            falseControl = falseControlCheck() or nil
        elseif type(trueControlCheck) == "boolean" then
            trueControl = falseControlCheck or nil
        else
            if falseControlCheck.IsHidden ~= nil then
                falseControl = falseControlCheck:IsHidden() or nil
            end
        end
    end
    if falseControlCheck ~= nil and (falseControl == nil or falseControl == false) then
        --Control must be hidden but isn't? Abort!
        return false
        --else
        --    goOn = true
    end
    --False control was checked, shall we go on?
    --if not goOn then return false end
    --Panel was determined via scene name, true and/or false control!
    return true
end

--Check if the craftbag is shown as the groupName at the craftbag is different than non-craftbag
--e.g. the groupName "Alchemy" is the normal groupName "Crafting" with subfilterName "Alchemy"
function util.IsCraftBagShown()
    return not ZO_CraftBag:IsHidden()
end

--======================================================================================================================
-- -^- IsShown functions                                                                                            -^-
--======================================================================================================================

--======================================================================================================================
-- -v- Subfilter bar functions                                                                                      -v-
--======================================================================================================================
--Should the subfilter bar not be shown?
--e.g. ALWAYS do not show if special itemfilterType OR if the current inventory was closed again (automatic bank closing)
function util.CheckIfNoSubfilterBarShouldBeShown(currentFilter, invType, craftingType, filter)
    if AF.debug or AF.settings.debugSpam then
        d("[AF]util.CheckIfNoSubfilterBarShouldBeShown - currentFilter: " .. tostring(currentFilter) .. ", invType: " ..tostring(invType) .. ", craftingType: " ..tostring(craftingType) .. ", filter: " .. tostring(filter))
    end
    local doAbort = false
    local filterTypeToUse
    --Is the stable vendor shown? Abort, as there are no subfilter bars
    if currentFilter and currentFilter == ITEMFILTERTYPE_COLLECTIBLE and SCENE_MANAGER:GetCurrentScene() == STABLES_SCENE then doAbort = true end
    if not doAbort and invType ~= nil then
        --Check if the subfilterBar is still needed. Maybe the current inventory/panel was closed already again (automatic bank close check)
        if AF.fragmentStateHiding and AF.fragmentStateHiding[invType] then
            doAbort = true
        end
        --Is the subfilter bar some bad combination which the game creates but shouldn't be there as it will be updated right afterwards
        --properly with correct values? e.g. at the jewelry refinemant panel the filter will be first 6 (why?) + currentFilter =nil and
        --then corrected to 1 and correct currentFilter properly
        if not doAbort then
            if currentFilter == nil then
                if filter == nil then return false end
                craftingType = craftingType or util.GetCraftingType()
                if not craftingType then return false end
                local subfilterBarsShouldOnlyBeShownSpecial = AF.subfilterBarsShouldOnlyBeShownSpecial
                if subfilterBarsShouldOnlyBeShownSpecial[invType] and subfilterBarsShouldOnlyBeShownSpecial[invType][craftingType] then
                    local subfilterBarShouldOnlyBeShownSpecial = subfilterBarsShouldOnlyBeShownSpecial[invType][craftingType][filter] or false
                    doAbort = not subfilterBarShouldOnlyBeShownSpecial
                end
            end
        end
    end
    if AF.settings.debugSpam then d("[AF]util.CheckIfNoSubfilterBarShouldBeShown - doAbort: " .. tostring(doAbort) .." /currentFilter: " ..tostring(currentFilter) .. ", invType: " ..tostring(invType) .. ", filterTypeToUse: " ..tostring(filterTypeToUse) .. ", fragmentStateHiding: " ..tostring(AF.fragmentStateHiding[invType]) .. ", isBanking: " ..tostring(PLAYER_INVENTORY:IsBanking())) end
    --if AF.settings.debugSpam then d("[AF]util.CheckIfNoSubfilterBarShouldBeShown - currentFilter: " ..tostring(currentFilter) .. ", invType: " ..tostring(invType) .. ", abort: " ..tostring(doAbort)) end
    return doAbort
end

--Abort the subfilterbar refresh?
function util.AbortSubfilterRefresh(inventoryType)
    if inventoryType == nil then return true end
    local doAbort = false
    local subFilterRefreshAbortInvTypes = AF.abortSubFilterRefreshInventoryTypes
    --Abort the subfilter bar refresh at some panels (and always at crafting panels->they will be updated with their own update functions)
    if subFilterRefreshAbortInvTypes[inventoryType] or util.IsCraftingStationInventoryType(inventoryType) then
        doAbort = true
    end
    if AF.settings.debugSpam then d("[AF]util.AbortSubfilterRefresh - invType: " ..tostring(inventoryType) .. ", abort: " ..tostring(doAbort)) end
    return doAbort
end

--Refresh the subfilter button bar and disable non-given/non-matching subfilter buttons ("grey-out" the buttons)
function util.RefreshSubfilterBar(subfilterBar, calledFromExternalAddonName)
    calledFromExternalAddonName = calledFromExternalAddonName or ""
    local inventoryType = subfilterBar.inventoryType
    local craftingType = util.GetCraftingType()
    local isNoCrafting = not util.IsCraftingPanelShown()
    local realInvTypes
    local inventory, inventorySlots
    local currentFilter
    local bagWornItemCache
    if AF.settings.debugSpam then
        d(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
        d("[AF]SubFilter refresh, calledFromExternalAddonName: " .. tostring(calledFromExternalAddonName) .. ", invType: " .. tostring(inventoryType) .. ", subfilterBar: " ..tostring(subfilterBar.name) .. ", craftingType: " .. tostring(craftingType) .. ", isNoCrafting: " .. tostring(isNoCrafting))
    end
    --AF._currentSubfilterBarAtRefreshCheck = subfilterBar

    --Abort the subfilterBar refresh method? Or check for crafting inventory types and return teh correct inventory types then
    if util.AbortSubfilterRefresh(inventoryType) then
        --Try to map the fake inventory type from LibFilters to the real ingame inventory type
        realInvTypes = util.MapLibFiltersInventoryTypeToRealInventoryType(inventoryType)
        if realInvTypes == nil then return end
        --Improvement panel: BAG_WORN needs to be checked as well later on!
        if inventoryType == LF_SMITHING_IMPROVEMENT or inventoryType == LF_JEWELRY_IMPROVEMENT or inventoryType == LF_RETRAIT then
            bagWornItemCache = SHARED_INVENTORY:GetOrCreateBagCache(BAG_WORN)
        end
        --d("<SubFilter refresh - go on: " .. tostring(#realInvTypes) .. ", subfilterBar: " ..tostring(subfilterBar) .. ", bagWornToo?: " ..tostring(bagWornItemCache ~= nil))
    else
        realInvTypes = {}
        table.insert(realInvTypes, inventoryType)
    end
    --Setting to gray out the buttons is enbaled?
    local grayOutSubFiltersWithNoItems  = AF.settings.grayOutSubFiltersWithNoItems
    --Check if a bank/guild bank/house storage is opened
    local isVendorPanel                 = util.IsFilterPanelShown(LF_VENDOR_SELL) or false
    local isFencePanel                  = util.IsFilterPanelShown(LF_FENCE_SELL) or false
    local isLaunderPanel                = util.IsFilterPanelShown(LF_FENCE_LAUNDER) or false
    local isBankDepositPanel            = AF.bankOpened and util.IsFilterPanelShown(LF_BANK_DEPOSIT) or false
    local isGuildBankDepositPanel       = AF.guildBankOpened  and util.IsFilterPanelShown(LF_GUILDBANK_DEPOSIT) or false
    local isHouseBankDepositPanel       = AF.houseBankOpened  and util.IsFilterPanelShown(LF_HOUSE_BANK_DEPOSIT) or false
    local isABankDepositPanel           = (isBankDepositPanel or isGuildBankDepositPanel or isHouseBankDepositPanel) or false
    local isGuildStoreSellPanel         = util.IsFilterPanelShown(LF_GUILDSTORE_SELL) or false
    local isRetraitStation              = util.IsRetraitPanelShown()
    local isJunkInvButtonActive         = subfilterBar.name == (AF.inventoryNames[INVENTORY_BACKPACK] .. "_" .. AF.filterTypeNames[ITEMFILTERTYPE_JUNK]) or false
    local libFiltersPanelId             = util.GetCurrentFilterTypeForInventory(inventoryType, true)
    if AF.settings.debugSpam then d(">isFencePanel: " .. tostring(isFencePanel) .. ", isLaunderPanel: " .. tostring(isLaunderPanel) .. ", isVendorPanel: " .. tostring(isVendorPanel) .. ", isBankDepositPanel: " .. tostring(isBankDepositPanel) .. ", isGuildBankDepositPanel: " .. tostring(isGuildBankDepositPanel) .. ", isHouseBankDepositPanel: " .. tostring(isHouseBankDepositPanel) .. ", isRetraitStation: " .. tostring(isRetraitStation) .. ", isJunkInvButtonActive: " .. tostring(isJunkInvButtonActive) .. ", libFiltersPanelId: " .. tostring(libFiltersPanelId) .. ", grayOutSubfiltersWithNoItems: " ..tostring(grayOutSubFiltersWithNoItems)) end
    local doEnableSubFilterButtonAgain = false
    local breakInventorySlotsLoopNow = false
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    --Check subfilterbutton for items, using the filter function and junk checks (only for non-crafting stations)
    local function checkBagContentsNow(bag, bagData, realInvType, button)
        if AF.settings.debugSpam then d(">checkBagContentsNow: " ..tostring(button.name)) end
        doEnableSubFilterButtonAgain = false
        breakInventorySlotsLoopNow = false
        local hasAnyJunkInBag = false
        if isNoCrafting and bag ~= BAG_WORN then
            hasAnyJunkInBag = HasAnyJunk(bag, false)
        end
        local bagDataToCheck = {}
        --Worn items? The given data is quite different then the PLAYER_INVENTORY data so one needs to map it
        if bag == BAG_WORN then
            bagDataToCheck[1] = bagData
        else
            bagDataToCheck = bagData
        end
        local itemsFound = 0
        for _, itemData in pairs(bagDataToCheck) do
            breakInventorySlotsLoopNow = false
            local isItemSellable = false
            local isItemStolen = false
            local isItemJunk = false
            local isItemBankAble = true
            local isBOPTradeable = false
            local isBound = false
            local passesCallback
            local passesFilter
            --Another addon uses filters on this LibFilters panelId?
            local otherAddonUsesFilters = util.CheckIfOtherAddonsProvideSubfilterBarRefreshFilters(itemData, realInvType, craftingType, libFiltersPanelId)
            if isNoCrafting then
                passesCallback = button.filterCallback(itemData)
                --Like crafting tables the junk inventory got different itemTypes in one section (ITEMFILTERTYPE_JUNK = 9). So the filter comparison does not work and the callback should be enough to check.
                passesFilter = passesCallback and ((isJunkInvButtonActive and currentFilter == ITEMFILTERTYPE_JUNK)
                        or (util.IsItemFilterTypeInItemFilterData(itemData.filterData, currentFilter)))
                        and otherAddonUsesFilters
            else
                passesCallback = button.filterCallback(itemData)
                --Todo: ItemData.filterData is not reliable at crafting stations as the items are collected from several different bags!
                --Todo: Thus the filter is always marked as "passed". Is this correct and does it work properly? To test!
                --> Set the currentFilter = itemData.filterData[1], which should be the itemType of the current item
                --currentFilter = itemData.filterData[1]
                passesFilter = passesCallback and otherAddonUsesFilters
                --Do more filter checks for the crafting types, if the filter passes until now
                if passesFilter then
                    --Jewelry crafting
                    if craftingType == CRAFTING_TYPE_JEWELRYCRAFTING then
                        --Jewelry deconstruction
                        if libFiltersPanelId == LF_JEWELRY_DECONSTRUCT then
                            local itemLink = GetItemLink(itemData.bagId, itemData.slotIndex)
                            passesFilter = passesFilter and not IsItemLinkForcedNotDeconstructable(itemLink)
                        end
                    --Retrait
                    elseif craftingType == CRAFTING_TYPE_NONE then
                        if libFiltersPanelId == LF_RETRAIT and isRetraitStation then
                            passesFilter = passesFilter and CanItemBeRetraited(itemData.bagId, itemData.slotIndex)
                        end
                    end
                end


                -- TODO: Check retrait station subfilter buttons greying out properly
                -- TODO: Check jewelry refine subfilter buttons greying out properly
                --if passesCallback and passesFilter then
                --if libFiltersPanelId == LF_JEWELRY_REFINE then
                --    local itemLink = GetItemLink(itemData.bagId, itemData.slotIndex)
                --    local itemType = GetItemLinkItemType(itemLink)
                --    if itemType == ITEMTYPE_JEWELRY_TRAIT or itemType == ITEMTYPE_JEWELRY_RAW_TRAIT or itemType == ITEMTYPE_JEWELRYCRAFTING_BOOSTER or
                --    itemType == ITEMTYPE_JEWELRYCRAFTING_MATERIAL or itemType == ITEMTYPE_JEWELRYCRAFTING_RAW_BOOSTER or itemType == ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL then
                --d("[AF]SubfilterRefresh: " .. itemLink .. ", passesCallback: " .. tostring(passesCallback) .. ", passesFilter: " ..tostring(passesFilter))
                --end
                --end
            end
            if passesCallback and passesFilter then
                --Check if item is junk and do not pass the callback then!
                if hasAnyJunkInBag then
                    isItemJunk = IsItemJunk(itemData.bagId, itemData.slotIndex)
                end
                --Check if the item can be sold
                if isVendorPanel or isFencePanel then
                    local itemSellInformation = GetItemLinkSellInformation(GetItemLink(itemData.bagId, itemData.slotIndex))
                    --[[
                    ItemSellInformation
                            * ITEM_SELL_INFORMATION_CANNOT_SELL = 4
                            * ITEM_SELL_INFORMATION_CAN_BE_RESEARCHED = 3
                            * ITEM_SELL_INFORMATION_INTRICATE = 2
                            * ITEM_SELL_INFORMATION_PRIORITY_SELL = 1
                            * ITEM_SELL_INFORMATION_NONE = 0
                    ]]
                    if itemSellInformation == ITEM_SELL_INFORMATION_CANNOT_SELL then
                        isItemSellable = false
                    else
                        isItemSellable = true
                    end
                end
                --Check if item is stolen (crafting or banks)
                if isABankDepositPanel or isVendorPanel or not isNoCrafting or isGuildStoreSellPanel or isFencePanel or isLaunderPanel then
                    isItemStolen = IsItemStolen(itemData.bagId, itemData.slotIndex)
                end
                --Checks for bound and BOP tradeable
                if isGuildBankDepositPanel or isGuildStoreSellPanel then
                    isBound         = IsItemBound(itemData.bagId, itemData.slotIndex)
                    isBOPTradeable  = IsItemBoPAndTradeable(itemData.bagId, itemData.slotIndex)
                end
                --Is an item below a subfilter but cannot be deposit/sold (bank, guild bank, vendor):
                --The subfilter button will be still enabled as there are no items to check (will be filtered by ESO vanilla UI BEFORE AF can check them)
                --if isBankDepositPanel or isHouseBankDepositPanel then
                --Check if items are not bankable:
                --isItemBankAble =
                --end
                if isGuildBankDepositPanel then
                    --Check if items are not guild bankable:
                    --Stolen items
                    --Bound items
                    --Bound but tradeable items
                    isItemBankAble = not isBound and not isBOPTradeable
                end
                ----------------------------------------------------------------------------------------
                --[No crafting panel] (e.g. inventory, bank, guild bank, mail, trade, craftbag):
                --Item is:
                -->no junk
                -->or at junk panel and item is junk
                if isNoCrafting then
                    --[Bank/Guild Bank deposit]
                    --Item is:
                    -->Not stolen
                    -->Bankable (unbound)
                    -->not junk
                    -->Or junk, and junk inventory filter button is active
                    if isABankDepositPanel then
                        doEnableSubFilterButtonAgain = not isItemStolen and isItemBankAble and (not isItemJunk or (isJunkInvButtonActive and isItemJunk))

                        --[Vendor]
                        --Item is:
                        -->Not stolen
                        -->not junk
                        -->Or junk, and junk inventory filter button is active
                        -->is sellable
                    elseif isVendorPanel then
                        doEnableSubFilterButtonAgain = not isItemStolen and (not isItemJunk or (isJunkInvButtonActive and isItemJunk)) and isItemSellable

                        --[Fence sell]
                        --Item is:
                        -->Stolen
                        -->not junk
                        -->Or junk, and junk inventory filter button is active
                        -->sellable at vendor
                    elseif isFencePanel then
                        doEnableSubFilterButtonAgain = isItemStolen and (not isItemJunk or (isJunkInvButtonActive and isItemJunk)) and isItemSellable

                        --[Fence launder]
                        --Item is:
                        -->Stolen
                        -->not junk
                        -->Or junk, and junk inventory filter button is active
                    elseif isLaunderPanel then
                        doEnableSubFilterButtonAgain = isItemStolen and (not isItemJunk or (isJunkInvButtonActive and isItemJunk))

                        --[Guild store list/sell]
                        --Item is:
                        -->Not stolen
                        -->not junk
                        -->not bound
                    elseif isGuildStoreSellPanel then
                        doEnableSubFilterButtonAgain = not isItemStolen and not isItemJunk and not isBound and not isBOPTradeable

                        --[Normal inventory, mail, trade, craftbag]
                        --Item is:
                        -->not junk
                        -->Or junk, and junk inventory filter button is active
                    else
                        doEnableSubFilterButtonAgain = (not isItemJunk or (isJunkInvButtonActive and isItemJunk))
                    end
                    ----------------------------------------------------------------------------------------
                    --[Crafting panel] (e.g. refine, creation, deconstruction, improvement, research, recipes, extraction, retrait):
                    --Item is:
                    -->Not stolen (currently deactivated!)
                else
                    --if isRetraitStation and button.name == "Shield" then
                    --d(">" .. GetItemLink(itemData.bagId, itemData.slotIndex) .. " passesCallback: " ..tostring(passesCallback) .. ", otherAddonUsesFilters: " .. tostring(otherAddonUsesFilters) .. ", passesFilter: " ..tostring(passesFilter) .. ", canBeRetraited: " .. tostring(CanItemBeRetraited(itemData.bagId, itemData.slotIndex)) .. " - doEnableSubFilterButtonAgain: " ..tostring(doEnableSubFilterButtonAgain))
                    --end
                    itemsFound = itemsFound +1
                    --d("<<< Crafting station: " ..tostring(itemsFound))
                    --doEnableSubFilterButtonAgain = not isItemStolen
                    doEnableSubFilterButtonAgain = (itemsFound > 0) or false
                end
                if doEnableSubFilterButtonAgain then
                    breakInventorySlotsLoopNow = true
                    break
                end
            else
                --d("<<< did not pass filter or callback!")
            end
        end -- for ... itemData in bagData
        --d(">breakInventorySlotsLoopNow: " ..tostring(breakInventorySlotsLoopNow) .. ", doEnableSubFilterButtonAgain: " .. tostring(doEnableSubFilterButtonAgain))
    end
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------

    --Check if filters apply to the subfilter and change the color of the subfilter button
    for _, button in ipairs(subfilterBar.subfilterButtons) do
        --if AF.settings.debugSpam then d(">==============================>\nButtonName: " .. tostring(button.name)) end
        if button.name ~= AF_CONST_ALL then
            --Setting to disable subfilter buttons with no items is enabled?
            if grayOutSubFiltersWithNoItems then
                --d("Gray out wished!")
                doEnableSubFilterButtonAgain = false
                breakInventorySlotsLoopNow = false
                --Disable button first (May be enabled further down again if checks allow it)
                if button.clickable then
                    --d(">disabling button!")
                    button.texture:SetColor(.3, .3, .3, .9)
                    button:SetEnabled(false)
                    button.clickable = false
                end
                --Check each inventory now
                for _, realInvType in pairs(realInvTypes) do
                    if breakInventorySlotsLoopNow then break end
                    breakInventorySlotsLoopNow = false
                    inventory = PLAYER_INVENTORY.inventories[realInvType]
                    if inventory ~= nil and inventory.slots ~= nil then
                        --Get the current filter. Normally this comes from the inventory. Crafting currentFilter determination is more complex!
                        if isNoCrafting then
                            currentFilter = inventory.currentFilter
                            --d(">currentFilter: " .. tostring(currentFilter))
                        else
                            --Todo: ItemData.filterData is not reliable at crafting stations as the items are collected from several different bags!
                            --Todo: Thus the filter is always marked as "passed". Is this correct and does it work properly? To test!
                            --Todo: Enable this section again if currentFilter is needed further down in this function!
                            --[[
                            local invType = util.GetCurrentFilterTypeForInventory(AF.currentInventoryType)
                            local craftingFilter = util.GetCraftingTablePanelFilter(invType)
                            currentFilter = util.MapCraftingStationFilterType2ItemFilterType(craftingFilter, invType, craftingType)
                            ]]
                        end
                        inventorySlots = inventory.slots
                        --Check subfilterbutton for items, using the filter function and junk checks (only for non-crafting stations)
                        for bag, bagData in pairs(inventorySlots) do
                            if breakInventorySlotsLoopNow then break end
                            checkBagContentsNow(bag, bagData, realInvType, button)
                            if doEnableSubFilterButtonAgain then
                                --d(">>> !!! subfilterButton got enabled again !!!")
                                breakInventorySlotsLoopNow = true
                            end
                        end
                    end
                    if doEnableSubFilterButtonAgain then
                        --d(">>>> !!!! subfilterButton got enabled again !!!!")
                        breakInventorySlotsLoopNow = true
                    end
                end
                --Check the worn items as well? (for LF_SMITHING_IMPROVEMENT e.g.)
                if not doEnableSubFilterButtonAgain and bagWornItemCache ~= nil then
                    for _, data in pairs(bagWornItemCache) do
                        checkBagContentsNow(BAG_WORN, data, INVENTORY_BACKPACK, button)
                        if doEnableSubFilterButtonAgain then
                            --d(">>>>> !!!!! BAG_WORN: subfilterButton got enabled again !!!!")
                            breakInventorySlotsLoopNow = true
                            break
                        end
                    end
                end
            else
                --d("No gray out wished!")
                --Setting to disable subfilter buttons with no items is disabled:
                --Enable all subfilter buttons again
                doEnableSubFilterButtonAgain = true
            end
            --Enable the subfilter button again now?
            if doEnableSubFilterButtonAgain then
                --d(">Enabling button again: " .. tostring(button.name))
                button.texture:SetColor(1, 1, 1, 1)
                button:SetEnabled(true)
                button.clickable = true
            end
        end
    end
end

--Get the list's control name for the subfilterBar reanchor
function util.GetListControlForSubfilterBarReanchor(inventoryType)
    local listControlsForSubfilterBarReanchor = AF.listControlForSubfilterBarReanchor
    local filterPanelId = util.GetCurrentFilterTypeForInventory(inventoryType)
    local listControlForSubfilterBarReanchor
    local listControlForSubfilterBarReanchorData = listControlsForSubfilterBarReanchor[filterPanelId]
    local moveInvBottomBarDown = false
    if listControlForSubfilterBarReanchorData then
        listControlForSubfilterBarReanchor = listControlForSubfilterBarReanchorData.control
        moveInvBottomBarDown = listControlForSubfilterBarReanchorData.moveInvBottomBarDown
    end
    return listControlForSubfilterBarReanchor, moveInvBottomBarDown
end

--Get the current subFilterBar's active button
function util.GetActiveSubfilterBarButton(invType)
    if not invType then return end
    local subfilterBarBase = AF.subfilterGroups[invType]
    if not subfilterBarBase then return end
    local currentSubfilterBar = subfilterBarBase.currentSubfilterBar
    if not currentSubfilterBar then return end
    local currentActiveSubfilterBarButton = currentSubfilterBar.activeButton
    return currentActiveSubfilterBarButton
end
--======================================================================================================================
-- -^- Subfilter bar functions                                                                                      -^-
--======================================================================================================================

--======================================================================================================================
-- -v- Filter functions                                                                                             -v-
--======================================================================================================================

--Apply the LIbFilters filter to the inventory now
function util.ApplyFilter(button, filterTag, requestUpdate, filterType)

    local currentInvType    = AF.currentInventoryType
    local LibFilters        = util.LibFilters
    local callback          = button.filterCallback
    local filterTypeToUse   = filterType or util.GetCurrentFilterTypeForInventory(currentInvType, true)
    local delay             = 0
    local buttonName        = button.name

    if AF.settings.debugSpam then d("----->[AF]ApplyFilter " .. tostring(buttonName) .. " from " .. tostring(filterTag) .. " for filterType " .. tostring(filterTypeToUse) .. " and inventoryType " .. tostring(currentInvType)) end
    --if something isn't right, abort
    local errorSuffix = "Tag \'" .. filterTag .. "\', button \'" .. tostring(buttonName) .. "\', filterType: \'" ..tostring(filterTypeToUse) .. "\', groupName: \'" .. tostring(button.groupName) .. "\'"
    if callback == nil then
        d("[AdvancedFilters] ERROR - ApplyFilter: Callback at inventory \'".. tostring(currentInvType) .. "\' was nil!\n" .. errorSuffix)
        return
    end
    if filterTypeToUse == nil then
        d("[AdvancedFilters] ERROR - ApplyFilter: FilterType at inventory \'".. tostring(currentInvType) .. "\'  was nil!\n" .. errorSuffix)
        return
    end

    --Check if the parameter to reset the current dropdown filter to "All" was registered
    -->This is needed if the dropdown filters rely on the currently "shown" (and thus already filtered) inventory items
    -->to only use these for their filter functions/comparisons, and not ALL items of the inventories involved
    if filterTag == AF_CONST_DROPDOWN_FILTER and button.filterResetAtStart then
        delay = button.filterResetAtStartDelay or 50 --Set delay so the next dropdown filter will be called AFTER evertyhing got updated
        --Clear the filters and refresh the visible inventory items now.
        --Do not change the dropdownbox entry to "ALL" or the "lastSelectedDropdownEntry" will be changed as well!
        --Clear current filters without an update
        LibFilters:UnregisterFilter(filterTag)
        --Update the inventory to show all items unfiltered again
        LibFilters:RequestUpdate(filterTypeToUse)
    end

    --Call deleyed if the dropdown filter was reset to all
    zo_callLater(function()
        --Check if a function should be executed before the filters get applied
        local filterStartCallback = button.filterStartCallback
        if filterStartCallback and type(filterStartCallback) == "function" then
            filterStartCallback()
        end
        --Only for the dropdown box filters and ONLY for non-standard AdvancedFilters dropdown entries
        -->(isStandardAFDropdownFilter is added in function AF.util.BuildDropdownCallbacks as AF_FilterBar:ActivateButton() is called)
        if filterTag == AF_CONST_DROPDOWN_FILTER and not button.isStandardAFDropdownFilter then
            --Check if the research panel is opened and build the prefilter data for the horizontal scroll list
            --depending on the currently selected subfilterBar button's name and group
            -->First parameter "true" will start the prefiltering
            --->Will check table AF.subfilterCallbacks with the group and name to get the entry of the selected button.
            --->Then it will use the data in the subTable "filterForAll" to prefiltzer some values like itemType, equipType, armorType or traitType
            util.CheckForResearchPanelAndRunFilterFunction(true, nil, nil, nil)
        end

        --first, clear current filters without an update
        -->if not cleared before!
        if not button.filterResetAtStart then
            LibFilters:UnregisterFilter(filterTag)
        end
        --then register new one and hand off update parameter
        LibFilters:RegisterFilter(filterTag, filterTypeToUse, callback)
        if requestUpdate == true then LibFilters:RequestUpdate(filterTypeToUse) end

        --Update the count of filtered/shown items in the inventory FreeSlot label
        --Delay this function call as the data needs to be filtered first!
        zo_callLater(function()
            --Update the shown filtered item count at the inventory bottom line, if the inventory got a label for it
            util.UpdateCraftingInventoryFilteredCount(currentInvType)

            --Run an end callback function now?
            local endCallback = button.filterEndCallback
            if endCallback and type(endCallback) == "function" then
                endCallback()
            end
        end, 50)
    end, delay)
end

--Remove all registered filters of buttons and dropdown boxes and update the inventory
function util.RemoveAllFilters()
    if AF.settings.debugSpam then d("[AF]util.RemoveAllFilters") end
    local LibFilters = util.LibFilters
    local filterType = util.GetCurrentFilterTypeForInventory(AF.currentInventoryType, true)

    LibFilters:UnregisterFilter(AF_CONST_BUTTON_FILTER)
    LibFilters:UnregisterFilter(AF_CONST_DROPDOWN_FILTER)

    if filterType ~= nil then LibFilters:RequestUpdate(filterType) end
end

--Check if an item's filterData contains an itemFilterType
function util.IsItemFilterTypeInItemFilterData(itemFilterData, itemFilterType)
    if itemFilterData == nil or itemFilterType == nil then return false end
    for _, itemFilterTypeInFilterData in ipairs(itemFilterData) do
        if itemFilterTypeInFilterData == itemFilterType then return true end
    end
end

--Filter a horizontal scroll list and run a filterFunction given to determine the entries to show in the
--horizontal list afterwards
function util.FilterHorizontalScrollList(runPrefilterForAllSelection, horizontalScrollList, filterOrEquipTypes, armorTypes, traitTypes)
    if not horizontalScrollList then return false end
    runPrefilterForAllSelection = runPrefilterForAllSelection or false
    --if AF.settings.debugSpam then d("[AF]util.FilterHorizontalScrollList") end

    --==================================================================================================================
    -- -v- SMITHING Research horizontal scrolllist?                                                                 -v-
    --==================================================================================================================
    if horizontalScrollList == controlsForChecks.researchLineList then
        local craftingType = util.GetCraftingType()
        if craftingType == CRAFTING_TYPE_INVALID then return false end
        local researchLineListArmorTypes = AF.researchLinesToArmorType[craftingType]
        local filterPanelId = util.GetCurrentFilterTypeForInventory(AF.currentInventoryType)
        local craftingStationFilter = util.GetCraftingTablePanelFilter(filterPanelId)
        local researchLineListIndicesOfWeaponOrArmorOrJewelryTypesBase = AF.researchLineListIndicesOfWeaponOrArmorOrJewelryTypes[craftingType]
        --local craftingPanel =  util.GetCraftingTablePanel(filterPanelId)
        --if AF.settings.debugSpam then d("[AF]util.FilterHorizontalScrollListcraftingType: " ..tostring(craftingType) .. ", craftingPanel: " .. tostring(craftingPanel.control:GetName()) .. ", craftingFilter: " ..tostring(craftingStationFilter)) end
        if not researchLineListIndicesOfWeaponOrArmorOrJewelryTypesBase then
            d("[AdvancedFilters] ERROR util.FilterHorizontalScrollList: Abort->Crafting table crafting type (".. tostring(craftingType) .. ") is not known in \'AF.researchLineListIndicesOfWeaponOrArmorOrJewelryTypes\'")
            return
        end
        local researchLineListIndicesOfWeaponOrArmorOrJewelryTypes = researchLineListIndicesOfWeaponOrArmorOrJewelryTypesBase[craftingStationFilter]
        if not researchLineListIndicesOfWeaponOrArmorOrJewelryTypes then
            d("[AdvancedFilters] ERROR util.FilterHorizontalScrollList: Abort->Crafting table filter type (".. tostring(craftingStationFilter) .. ") is not known in \'AF.researchLineListIndicesOfWeaponOrArmorOrJewelryTypes\'")
            return
        end
        local researchLineListIndexOfWeaponOrArmorOrJewelryType = 0
        --Rebuild the list but filter the items by applying new filter to the current libFilter filterPanelId
        --which then will be used inside the :Refresh() function of the panel

        --Prefilter some entries if the ALL button was chosen?
        local filterOrEquipTypesPreFiltered, armorTypesPreFiltered
        if runPrefilterForAllSelection then
            --Check which button is currently active. If it's not ALL then the ALL dropdown entry was selected.
            --Check which button is active and prefilter the list with the determined filterTypes, equipTypes and/or armorTypes
            filterOrEquipTypesPreFiltered, armorTypesPreFiltered = util.PreFilterWithSubfilterBarButtonFilterForAll()
        end
        --Add the prefilters to the current filters
        if filterOrEquipTypesPreFiltered then
            if not filterOrEquipTypes then
                filterOrEquipTypes = filterOrEquipTypesPreFiltered
            else
                if type(filterOrEquipTypes) == "table" then
                    for _, filterOrEquipType in ipairs(filterOrEquipTypesPreFiltered) do
                        table.insert(filterOrEquipTypes, filterOrEquipType)
                    end
                else
                    local filterOrEquipType = filterOrEquipTypes
                    filterOrEquipTypes = {}
                    filterOrEquipTypes = filterOrEquipTypesPreFiltered
                    table.insert(filterOrEquipTypes, filterOrEquipType)
                end
            end
        end
        if armorTypesPreFiltered then
            if not armorTypes then
                armorTypes = armorTypesPreFiltered
            else
                if type(armorTypes) == "table" then
                    for _, armorType in ipairs(armorTypesPreFiltered) do
                        table.insert(armorTypes, armorType)
                    end
                else
                    local armorType = armorTypes
                    armorTypes = {}
                    armorTypes = armorTypesPreFiltered
                    table.insert(armorTypes, armorType)
                end
            end
        end

        --Count the filterTypes
        local filterTypeCount = 0
        if filterOrEquipTypes ~= nil then
            if type(filterOrEquipTypes) == "table" then
                filterTypeCount = #filterOrEquipTypes
                if filterTypeCount == 1 then
                    researchLineListIndexOfWeaponOrArmorOrJewelryType = researchLineListIndicesOfWeaponOrArmorOrJewelryTypes[filterOrEquipTypes[1]]
                end
            else
                filterTypeCount = 1
                researchLineListIndexOfWeaponOrArmorOrJewelryType = researchLineListIndicesOfWeaponOrArmorOrJewelryTypes[filterOrEquipTypes]
            end
        end
        --Count the armorTypes
        local armorTypeCount = 0
        if armorTypes ~= nil then
            if type(armorTypes) == "table" then
                armorTypeCount = #armorTypes
            else
                armorTypeCount = 1
            end
        end
        --Count the traitTypes
        local traitTypeCount = 0
        if traitTypes ~= nil then
            if type(traitTypes) == "table" then
                traitTypeCount = #traitTypes
            else
                traitTypeCount = 1
            end
        end
        --if AF.settings.debugSpam then d("[AF]filterTypeCount: " ..tostring(filterTypeCount) .. ", armorTypeCount: " ..tostring(armorTypeCount) .. ", traitTypeCount: " ..tostring(traitTypeCount)) end
        --Nothing should be filtered? Abort here and allow all entries
        if filterTypeCount == 0 and armorTypeCount == 0 and traitTypeCount == 0 then
            return
        end
        --Check the researchLinIndices for their filterOrEquiupType, armorType and traitType at the current filterPanelId
        if filterPanelId then
            --Check the current crafting table's research line for the indices and build a "skip table" for LibFilters-3.0
            local fromResearchLineIndex = 1
            local toResearchLineIndex = GetNumSmithingResearchLines(craftingType)
            local skipTable = {}
            --Check for each possible researchLine at the given crafting station
            local researchLineAtCraftingStationToFilterType = AF.researchLinesToFilterTypes[craftingType]
            if researchLineAtCraftingStationToFilterType then
                for researchLineIndex = 1, toResearchLineIndex do
                    --d(">researchLineIndex: " ..tostring(researchLineIndex) .. ", name: " .. tostring(GetSmithingResearchLineInfo(craftingType, researchLineIndex)))
                    --Get the current filterType at the researchLineIndex
                    local researchLineIndexIsAllowed = false
                    --Check filterOrEquippmentTypes + armor types
                    if filterTypeCount > 0 then
                        --d(">check filterOrEquipType")
                        local filterTypeOfResearchLineIndex = researchLineAtCraftingStationToFilterType[researchLineIndex]
                        if filterTypeOfResearchLineIndex then
                            --d(">filterTypeOfResearchLineIndex: " ..tostring(filterTypeOfResearchLineIndex))
                            --Check each filterType
                            if type(filterOrEquipTypes) == "table" then
                                for _, filterType in ipairs(filterOrEquipTypes) do
                                    if filterType == filterTypeOfResearchLineIndex then
                                        researchLineIndexIsAllowed = true
                                        break --exit the inner filterOrEquipTyps for .. loop of filterTypes
                                    end
                                end
                            else
                                if filterOrEquipTypes == filterTypeOfResearchLineIndex then
                                    researchLineIndexIsAllowed = true
                                end
                            end
                        end
                    end
                    --Check armor types (if not checked within filterOrEquipType before)
                    if armorTypeCount > 0 and ((researchLineIndexIsAllowed and filterTypeCount > 0) or (not researchLineIndexIsAllowed and filterTypeCount == 0)) then
                        researchLineIndexIsAllowed = false
                        --d(">researchLineIndexIsAllowed: " .. tostring(researchLineIndexIsAllowed) .." -> check armorType")
                        if armorTypes and researchLineListArmorTypes then
                            local researchLineListArmorType = researchLineListArmorTypes[researchLineIndex]
                            if researchLineListArmorType then
                                --d(">researchLineListArmorType: " ..tostring(researchLineListArmorType))
                                if type(armorTypes) == "table" then
                                    for _, armorType in ipairs(armorTypes) do
                                        if armorType == researchLineListArmorType then
                                            researchLineIndexIsAllowed = true
                                            break --exit the inner inner armorTypes for .. loop
                                        end
                                    end
                                else
                                    if armorTypes == researchLineListArmorType then
                                        researchLineIndexIsAllowed = true
                                    end
                                end
                            end
                        else
                            researchLineIndexIsAllowed = true
                        end
                    end
                    --Check traits
                    --Is the researchLineIndex allowed so far because of the matching filterOrEquipType and/or armor type?
                    --Or not allowed as filterOrEquipType and armorType were not checked
                    if traitTypeCount > 0 and ((researchLineIndexIsAllowed and (filterTypeCount > 0 or armorTypeCount > 0)) or (not researchLineIndexIsAllowed and (filterTypeCount == 0 and armorTypeCount == 0)) )then
                        researchLineIndexIsAllowed = false
                        --d(">researchLineIndexIsAllowed: " .. tostring(researchLineIndexIsAllowed) .." -> check traitType")
                        local researchLineListTraitType = GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, 1)
                        --d(">researchLine trait: " ..tostring(researchLineListTraitType))
                        --Check if the traitTypes are given and mathcing as well
                        if type(traitTypes) == "table" then
                            for _, traitType in ipairs(traitTypes) do
                                if traitType == researchLineListTraitType then
                                    --d(">found matching trait: " ..tostring(traitType))
                                    researchLineIndexIsAllowed = true
                                    break --exit the inner inner traitTypes for .. loop
                                end
                            end
                        else
                            if traitTypes == researchLineListTraitType then
                                --d(">!!!found matching trait: " ..tostring(traitTypes))
                                researchLineIndexIsAllowed = true
                            end
                        end
                    end
                    --FilterType is not allowed? Add it to the skip table
                    if not researchLineIndexIsAllowed then
                        --if AF.settings.debugSpam then d("<<<<skipping researchLineIndex: " .. tostring(researchLineIndex) .. ", name: " ..tostring(GetSmithingResearchLineInfo(craftingType, researchLineIndex))) end
                        skipTable[researchLineIndex] = true
                    else
                        --if AF.settings.debugSpam then d(">>>>>adding researchLineIndex: " .. tostring(researchLineIndex) .. ", name: " ..tostring(GetSmithingResearchLineInfo(craftingType, researchLineIndex))) end
                    end
                end
                --local expectedTypeFilter = ZO_CraftingUtils_GetSmithingFilterFromTrait(GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, 1)) --returns 2 for weapons and 4 for armor, ? for jewelry

                --Set the from and to and the skipTable values for the loop "for researchLineIndex = 1, GetNumSmithingResearchLines(craftingType) do"
                --in function SMITHING.researchPanel.Refresh
                -->Was overwritten in LibFilters-3.0 helper functions and the function LibFilters3.SetResearchLineLoopValues(from, to, skipTable) was added
                -->to set the values for your needs
                util.LibFilters:SetResearchLineLoopValues(fromResearchLineIndex, toResearchLineIndex, skipTable)
                --Refresh -> rebuild and Commit the new list
                controlsForChecks.researchPanel:Refresh() --> Will rebuild the list entries and call list:Commit()
                --TODO: Somehow the researchPanel:Refresh() function is called twice, except for the "ALL" filter button?? WHY???
                --      Due to this we need to clear the variables delayed here and cannot do this within LibFilters3 as the 2nd call to Refresh would show
                --      all entries in the horizontal list again then :-(
                util.ThrottledUpdate("AF_ClearResearchPanelCustomFilters", 50, util.ClearResearchPanelCustomFilters)
            end

            --Scroll the list to the selected weapon or armorType
            if not researchLineListIndexOfWeaponOrArmorOrJewelryType then researchLineListIndexOfWeaponOrArmorOrJewelryType = 0 end
            zo_callLater(function()
                --d(">researchLineListIndexOfWeaponOrArmorType: " ..tostring(researchLineListIndexOfWeaponOrArmorType))
                horizontalScrollList:SetSelectedIndex(researchLineListIndexOfWeaponOrArmorOrJewelryType)
            end, 25)
        end
    end
    --==================================================================================================================
    -- -^- SMITHING Research horizontal scrolllist?                                                                 -^-
    --==================================================================================================================
end

--Get the current active subfilterBar's button name and then read the filterForAll entry of this button
--from the subfilterGroups to prefilter the list with some data (e.g. the horizontal research scroll list with EQUIPTYPE_NECK)
function util.PreFilterWithSubfilterBarButtonFilterForAll()
    --if AF.settings.debugSpam then d("[AF]util.PreFilterWithSubfilterBarButtonFilterForAll") end
    local subfilterGroups = AF.subfilterGroups[util.GetCurrentFilterTypeForInventory(AF.currentInventoryType)]
    if not subfilterGroups then return nil, nil end
    local currentActiveSubFilterBar = subfilterGroups.currentSubfilterBar
    if not currentActiveSubFilterBar then return nil, nil end
    local currentActiveButtonAtSubFilterBar = currentActiveSubFilterBar.activeButton
    if not currentActiveButtonAtSubFilterBar then return nil, nil end
    local activeButtonName = currentActiveButtonAtSubFilterBar.name
    --Stop if name of button is missing or if it's the ALL button
    if not activeButtonName or activeButtonName == AF_CONST_ALL then return nil, nil end
    --Get the subfilterCallbacks
    local subfilterCallbacks = AF.subfilterCallbacks
    if not subfilterCallbacks then return nil, nil end
    local activeButtonGroupName = currentActiveButtonAtSubFilterBar.groupName
    local subfilterCallbackForButtonGroup = subfilterCallbacks[activeButtonGroupName]
    if not subfilterCallbackForButtonGroup then return nil, nil end
    local subfilterCallbackForButton = subfilterCallbackForButtonGroup[activeButtonName]
    if not subfilterCallbackForButton then return nil, nil end
    local filterForAll = subfilterCallbackForButton.filterForAll
    if not filterForAll then return nil, nil end
    --[[
            filterForAll = {
                filterTypes = {}
                equipTypes  = {EQUIPTYPE_RING},
                armorTypes  = {},
            },
    ]]
    --Combine filterTypes and equipTypes in return table filterAndEquipTypes
    local filterAndEquipTypes
    local armorTypes
    if filterForAll.itemTypes then
        filterAndEquipTypes = filterAndEquipTypes or {}
        for _, filterType in pairs(filterForAll.itemTypes) do
            table.insert(filterAndEquipTypes, filterType)
        end
    end
    if filterForAll.equipTypes then
        filterAndEquipTypes = filterAndEquipTypes or {}
        for _, equipType in pairs(filterForAll.equipTypes) do
            table.insert(filterAndEquipTypes, equipType)
        end
    end
    if filterForAll.armorTypes then
        armorTypes = {}
        armorTypes = filterForAll.armorTypes
    end
    return filterAndEquipTypes, armorTypes
end

--Map different subfilterNames to one combined, e.g. te group Armor->subfilters LightArmor, Medium, Heavy, Clothing -> Body
function util.MapMultipleGroupSubfiltersToCombinedSubfilter(filterType, subFilterName)
    local subfilterButtonEntriesNotForDropdownCallback = AF.subfilterButtonEntriesNotForDropdownCallback
    if not subfilterButtonEntriesNotForDropdownCallback then return end
    local dataForFilterType = subfilterButtonEntriesNotForDropdownCallback[filterType]
    if not dataForFilterType then return end
    local doNotAdd = dataForFilterType["doNotAdd"]
    local replaceWith = dataForFilterType["replaceWith"]
    if not doNotAdd or not replaceWith then return end
    for _, subfilterNameToReplace in ipairs(doNotAdd) do
        if subfilterNameToReplace == subFilterName then
            return replaceWith
        end
    end
    return
end

--======================================================================================================================
-- -^- Filter functions                                                                                             -^-
--======================================================================================================================

--======================================================================================================================
-- -v- Crafting functions                                                                                           -v-
--======================================================================================================================
--Is the retrait panel shown?
function util.IsRetraitPanelShown()
    return ZO_RETRAIT_STATION_MANAGER:IsRetraitSceneShowing() or false
end

--Is any crafting table shown?
function util.IsCraftingPanelShown()
    return (ZO_CraftingUtils_IsCraftingWindowOpen() or util.IsRetraitPanelShown()) or false
end

--Get the crafting table of the filterType
function util.GetCraftingTable(filterType)
    if filterType == nil or not util.IsCraftingPanelShown() then return end
    local craftingTables = AF.craftingTables
    local craftingTable = craftingTables[filterType]
    return craftingTable
end

--Get the crafting panel of the filterType
function util.GetCraftingTablePanel(filterType)
    if filterType == nil or not util.IsCraftingPanelShown() then return end
    local craftingTablePanels = AF.craftingTablePanels
    local craftingPanel = craftingTablePanels[filterType]
    return craftingPanel
end

--Get the crafting panel of the filterType and it's inventory
function util.GetCraftingTablePanelInventory(filterType)
    if filterType == nil or not util.IsCraftingPanelShown() then return end
    local craftingPanel = util.GetCraftingTablePanel(filterType)
    if not craftingPanel then return end
    local craftingInv
    if craftingPanel.inventory then
        craftingInv = craftingPanel.inventory
        --For research panels
    else
        craftingInv = craftingPanel
    end
    return craftingInv
end

--Get the crafting panel of the filterType and it's currently selected filterType (e.g. weapons, or armor, or light armor or medium armor, or neck or ring, ...)
function util.GetCraftingTablePanelFilter(filterType)
    if filterType == nil or not util.IsCraftingPanelShown() then return end
    local craftingPanelInv = util.GetCraftingTablePanelInventory(filterType)
    if not craftingPanelInv then return end
    local filterTypeOfCraftingTable
    if craftingPanelInv.filterType then
        filterTypeOfCraftingTable = craftingPanelInv.filterType
        --For research panels
    elseif craftingPanelInv.typeFilter then
        filterTypeOfCraftingTable = craftingPanelInv.typeFilter
    end
    return filterTypeOfCraftingTable
end

--Get the crafting interaction type
function util.GetCraftingType()
    --[[
        TradeskillType
        CRAFTING_TYPE_ALCHEMY
        CRAFTING_TYPE_BLACKSMITHING
        CRAFTING_TYPE_CLOTHIER
        CRAFTING_TYPE_ENCHANTING
        CRAFTING_TYPE_INVALID
        CRAFTING_TYPE_PROVISIONING
        CRAFTING_TYPE_WOODWORKING
        CRAFTING_TYPE_JEWELRYCRAFTING
    ]]
    return GetCraftingInteractionType() or CRAFTING_TYPE_INVALID
end

--Get the inventory of the craftingPanel in "libFiltersFilterPanelId"
function util.GetInventoryFromCraftingPanel(libFiltersFilterPanelId)
    if libFiltersFilterPanelId == nil then return end
    local craftingPanelInv = util.GetCraftingTablePanelInventory(libFiltersFilterPanelId)
    return craftingPanelInv
end

--Get the crafting tables mode
function util.GetCraftingMode(inventoryType)
    inventoryType = inventoryType or util.GetCurrentFilterTypeForInventory(AF.currentInventoryType)
    local craftingMode
    local craftingTable = util.GetCraftingTable(inventoryType)
    if not craftingTable then return end
    craftingMode = craftingTable.mode or craftingTable.enchantingMode
    return craftingMode
end

--Check if the inventorytype is a crafting station
function util.IsCraftingStationInventoryType(inventoryType)
    local craftingTables = AF.craftingTables
    local retVar = (craftingTables[inventoryType] ~= nil) or false
    return retVar
end

--Function to return a boolean value if the craftingPanel is using the worn bag ID as well.
--Use the LibFilters filterPanelid as parameter
function util.GetCraftingPanelUsesBagWorn(libFiltersFilterPanelId)
    local craftingFilterPanelId2UsesBagWorn = AF.craftingFilterPanelId2UsesBagWorn
    local usesBagWorn = craftingFilterPanelId2UsesBagWorn[libFiltersFilterPanelId] or false
    return usesBagWorn
end

--Function to return the "predicate" and "filter" functions used at the different crafting types, as new inventory lists are build.
-->They will pre-filter and filter the inventory items.
--Use the LibFilters filterPanelId as parameter
function util.GetPredicateAndFilterFunctionFromCraftingPanel(libFiltersFilterPanelId)
    local craftingFilterPanelId2PredicateFunc = AF.craftingFilterPanelId2PredicateFunc
    local predicateFunc, filterFunc
    local funcs = craftingFilterPanelId2PredicateFunc[libFiltersFilterPanelId] or nil
    if funcs and funcs[1] and funcs[2] then
        predicateFunc, filterFunc = funcs[1], funcs[2]
    end
    return predicateFunc, filterFunc
end

function util.MapItemFilterType2CraftingStationFilterType(itemFilterType, filterPanelId, craftingType)
    if filterPanelId == nil then return end
    local mapIFT2CSFT = AF.mapIFT2CSFT
    if craftingType == nil then craftingType = util.GetCraftingType() end
    if itemFilterType == nil or craftingType == nil or mapIFT2CSFT[filterPanelId] == nil or mapIFT2CSFT[filterPanelId][craftingType] == nil or mapIFT2CSFT[filterPanelId][craftingType][itemFilterType] == nil then return end
    return mapIFT2CSFT[filterPanelId][craftingType][itemFilterType]
end

function util.MapCraftingStationFilterType2ItemFilterType(craftingStationFilterType, filterPanelId, craftingType)
    if filterPanelId == nil then return end
    local mapCSFT2IFT = AF.mapCSFT2IFT
    if craftingType == nil then craftingType = util.GetCraftingType() end
    if craftingStationFilterType == nil or craftingType == nil or mapCSFT2IFT[filterPanelId] == nil or mapCSFT2IFT[filterPanelId][craftingType] == nil or mapCSFT2IFT[filterPanelId][craftingType][craftingStationFilterType] == nil then return end
    local retVar = mapCSFT2IFT[filterPanelId][craftingType][craftingStationFilterType]
    return retVar
end

--Clear the custom variables used to filter the horizontal scrolling list entries
function util.ClearResearchPanelCustomFilters()
    --Reset the custom data for the loop now
    if controlsForChecks.researchPanel and controlsForChecks.researchPanel.LibFilters_3ResearchLineLoopValues then
        controlsForChecks.researchPanel.LibFilters_3ResearchLineLoopValues = nil
    end
end

--Check if the research panel is shown and do some special stuff with the horizontal scroll list then.
--If not: Run the filter function only
function util.CheckForResearchPanelAndRunFilterFunction(runPrefilterForAllSelection, filterOrEquipTypes, armorTypes, traitTypes)
    runPrefilterForAllSelection = runPrefilterForAllSelection or false
    --if AF.settings.debugSpam then d("[AF]util.CheckForResearchPanelAndRunFilterFunction") end
    --If the research panel is shown:
    --Clear the horizontal list and only show the entries which apply to the selected item type
    local researchHorizontalScrollList = AF.controlsForChecks.researchLineList
    if researchHorizontalScrollList and researchHorizontalScrollList.control and not researchHorizontalScrollList.control:IsHidden() then
        --Hide entries on the horizontal scroll list of the research panel
        util.FilterHorizontalScrollList(runPrefilterForAllSelection, researchHorizontalScrollList, filterOrEquipTypes, armorTypes, traitTypes)
    end
end
--======================================================================================================================
-- -^- Crafting functions                                                                                           -^-
--======================================================================================================================

--======================================================================================================================
-- -v- Other addons functions                                                                                       -v-
--======================================================================================================================
--Map the custom addon's itemFilterType defined in AdvancedFilters constants.lua to a LibFilters panelId LF_*
function util.MapCustomAddonItemFilterType2LibFiltersPanelId(customAddonItemFilterType)
    if not customAddonItemFilterType then return end
    local customAddonItemFilterTypes2LibFiltersPanelIds = AF.customAddonItemFilterType2LibFiltersPanelId
    if not customAddonItemFilterTypes2LibFiltersPanelIds then return end
    local filterPanelId = customAddonItemFilterTypes2LibFiltersPanelIds[customAddonItemFilterType]
    return filterPanelId
end

--Check if the itemFilterType of the current inventoryType is one added by a custom addon (e.g. "HarvensStolenFilter" filterTab button)
function util.CheckIfIsCustomAddonInventoryFilterButtonItemFilterType(invType)
    --if AF.settings.debugSpam then d("[AF]util.CheckIfIsCustomAddonInventoryFilterButtonItemFilterType - invType: " ..tostring(invType)) end
    local customInventoryFilterButton2ItemType = AF.customInventoryFilterButton2ItemType
    if not customInventoryFilterButton2ItemType then return false end
    --Get the currentFilter of the inventory
    local currentFilter = util.GetCurrentFilter(invType)
    if not currentFilter then return false end
    for otherAddonName, customItemFilterType in pairs(customInventoryFilterButton2ItemType) do
        if customItemFilterType == currentFilter then return true end
    end
    return false
end

--Check if the current filter is a function and then get the owning inventory filter bar's button to check for it's
--"descriptor" tag. If a descriptor is found use the mapping table AF.customInventoryFilterButton2ItemType to
--return a custom itemFilterType for this descriptor and use this itemFilterType addon wide (so the subfilterGroups and
--callback tables have a "key" to use!)
function util.CheckForCustomInventoryFilterBarButton(invType, currentFilter)
    if invType == nil or currentFilter == nil then return end
    --[[
    --Only if the currentFilter (which relates to PLAYER_INVENTORY.inventories[...].tabFilters[...].filterType) is a function
    -->All others would be numbers and can be used as is!
    if not type(currentFilter) == "function" then return end
    ]]
    local currentlySelectedInventoryFilterBarButton = util.GetActiveInventoryFilterBarButtonData(invType)
    --identification tag exists?
    if not currentlySelectedInventoryFilterBarButton or not currentlySelectedInventoryFilterBarButton.GetDescriptor then return end
    local customInventoryFilterButtons2ItemType = AF.customInventoryFilterButton2ItemType
    local descriptor = currentlySelectedInventoryFilterBarButton:GetDescriptor()
    if not descriptor or descriptor == "" or descriptor == 0 then return end
    local customInventoryFilterButton2ItemType = customInventoryFilterButtons2ItemType[descriptor]
    return customInventoryFilterButton2ItemType
end

--======================================================================================================================
-- -^- Other addons functions                                                                                       -^-
--======================================================================================================================

--======================================================================================================================
-- -v- API functions                                                                                               -v-
--======================================================================================================================
--Checks if other addons have registered filter functions which should be run on util.RefreshSubfilterBar as well
--to check if the subfilter bar button should be greyed out.
-->Will return true if no other addons have registered any filters for the inventoryType, craftingType and filterType
function util.CheckIfOtherAddonsProvideSubfilterBarRefreshFilters(slotData, inventoryType, craftingType, libFiltersPanelId)
    if slotData == nil or slotData.bagId == nil or slotData.slotIndex == nil
            or inventoryType == nil or craftingType == nil or libFiltersPanelId == nil then return true end
    --if AF.settings.debugSpam then
    --d("[AF]util.CheckIfOtherAddonsProvideSubfilterBarRefreshFilters, inventoryType: " ..tostring(inventoryType) .. ", craftingType: " .. tostring(craftingType) .. ", libFiltersPanelId: " .. tostring(libFiltersPanelId))
    --end
    --AF.SubfiltThrottledUpdateerRefreshCallbacks contain the externally registered filters, from other addons, for the refresh of subfilterBars
    local subfilterRefreshCallbacks
    if AF.SubfilterRefreshCallbacks == nil or AF.SubfilterRefreshCallbacks[inventoryType] == nil
            or AF.SubfilterRefreshCallbacks[inventoryType][craftingType] == nil or AF.SubfilterRefreshCallbacks[inventoryType][craftingType][libFiltersPanelId] == nil then
        return true
    end
    subfilterRefreshCallbacks = AF.SubfilterRefreshCallbacks[inventoryType][craftingType][libFiltersPanelId]
    if subfilterRefreshCallbacks == nil then return true end
    local retVar = true
    for externalAddonName, callbackFunc in pairs(subfilterRefreshCallbacks) do
        if callbackFunc ~= nil and type(callbackFunc) == "function" then
            local callbackFuncResult = callbackFunc(slotData)
            --d(">[AF]RefreshSubFilterbar, externalAddonName: " .. tostring(externalAddonName) .. ", result: " ..tostring(callbackFuncResult))
            retVar = callbackFuncResult
            if retVar == false then return false end
        end
    end
    return retVar
end
--======================================================================================================================
-- -^- API functions                                                                                               -^-
--======================================================================================================================