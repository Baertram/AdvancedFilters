AdvancedFilters = AdvancedFilters or {}
local AF = AdvancedFilters

local tos = tostring

local util = AF.util
local BuildDropdownCallbacks = AF.util.BuildDropdownCallbacks
local showChatDebug = AF.showChatDebug

local getCurrentFilterTypeForInventory =        util.GetCurrentFilterTypeForInventory
local getSubFilterGroupsLibFiltersFilterType =  util.GetSubFilterGroupsLibFiltersFilterType
local checkSpecialInventoryTypesAndUpdateCurrentInventoryType = util.CheckSpecialInventoryTypesAndUpdateCurrentInventoryType
local checkIfNoSubfilterBarShouldBeShown = util.CheckIfNoSubfilterBarShouldBeShown
local applyFilter = util.ApplyFilter

local universalDeconSelectedTabToAFInventoryType = AF.universalDeconSelectedTabToAFInventoryType
local mapGroupNameToFilterType = util.MapGroupNameToFilterType
local mapMultipleGroupSubfiltersToCombinedSubfilter = util.MapMultipleGroupSubfiltersToCombinedSubfilter


--Subfilter bar class
AF.AF_FilterBar = ZO_Object:Subclass()
local AF_FilterBar = AF.AF_FilterBar

--Update control tier/layer/level
local function updateControlZ(selfCtrl, tier, layer, level)
    selfCtrl:SetDrawTier(tier)
    selfCtrl:SetDrawLayer(layer)
    selfCtrl:SetDrawLevel(level)
end

--SubfilterBar dropdown pulse animation
local pulseControl = AF_DropdownPulse
local pulseBackground = pulseControl:GetNamedChild("BG")
local pulseTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("AF_SubFilterBarDropdownPulse", pulseBackground)

local function ShowPulse(control)
    pulseControl:ClearAnchors()
    pulseControl:SetAnchorFill(control)
    pulseControl:SetHidden(false)
    pulseTimeline:PlayFromStart()
end

local function HidePulse()
    pulseControl:SetHidden(true)
    pulseTimeline:Stop()
end

function AF_FilterBar:New(libFiltersFiltertype, inventoryName, tradeSkillname, groupName, subfilterNames, excludeTheseButtons)
    local obj = ZO_Object.New(self)
    obj.libFilters_filterType = libFiltersFiltertype
    obj:Initialize(inventoryName, tradeSkillname, groupName, subfilterNames, excludeTheseButtons)
    return obj
end

function AF_FilterBar:Initialize(inventoryName, tradeSkillname, groupName, subfilterNames, excludeTheseButtons)
    local settings = AF.settings
    if settings.debugSpam then d("=============================================\n[AF]AF_FilterBarInitialize - inventoryName: " .. tos(inventoryName) .. ", tradeSkillname: " .. tos(tradeSkillname) .. ", groupName: " ..tos(groupName) .. ", subfilterNames: " .. tos(subfilterNames)) end

    --get upper anchor position for subfilter bar
    --Fix for patch 6.2.7 2020-11-23 ZOs added their own subFilter bars with Markarth patch and thus the subfilterbars are
    --movin the inventory sort header down.
    --local _,_,_,_,_,offsetY = ZO_PlayerInventorySortBy:GetAnchor()
    local offsetY = 0

    --parent for the subfilter bar control
    local parents = AF.filterBarParents
    local parent = parents[inventoryName]
    if parent == nil then
        d("[AdvancedFilters] ERROR: Parent for subfilterbar missing! InventoryName: " .. tos(inventoryName) .. ", tradeSkillname: " .. tos(tradeSkillname) .. ", groupName: " ..tos(groupName) .. ", subfilterNames: " .. tos(subfilterNames))
        --[[
            else
                if parent.GetName then
                    d(">parent name: " ..tos(parent:GetName()))
                end
        ]]
    end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
    local selfVar = self
    --unique identifier
    self.name = inventoryName .. tradeSkillname .. groupName
    local AF_FilterBarName = self.name
    self.control = WINDOW_MANAGER:CreateControlFromVirtual("AF_FilterBar" .. self.name, parent, "AF_Base")
    self.control:SetAnchor(TOPLEFT, parent, TOPLEFT, 0, offsetY)

    self.label = self.control:GetNamedChild("Label")
    self.label:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
    local allText = AF_CONST_ALL
    if AF.strings and AF.strings[AF_CONST_ALL] then
        allText = AF.strings[AF_CONST_ALL]
    else
        showChatDebug("AF_FilterBar:Initialize", "AF.strings missing for: " ..tos(AF_CONST_ALL) .. ", language: " .. tos(AF.clientLang) .. ", inventoryName: " .. tos(inventoryName) .. ", tradeSkillname: " ..tos(tradeSkillname) .. ",groupName: " ..tos(groupName))
    end
    self.label:SetText(allText)

    self.divider = self.control:GetNamedChild("Divider")

    self.subfilterButtons = {}
    self.activeButton = nil

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
    --The dropdown box (combobox) for the filter plugins
    self.dropdown = WINDOW_MANAGER:CreateControlFromVirtual("AF_FilterBar" .. self.name .. "DropdownFilter", self.control, "ZO_ComboBox")
    self.dropdown:SetAnchor(RIGHT, self.control, RIGHT, -10, 0) -- -10 pixels left of the right screen edge
    self.dropdown:SetHeight(24)
    self.dropdown:SetWidth(104)

------------------------------------------------------------------------------------------------------------------------
    --Function for the mouse right click on the dropdown box (filter plugins) of the subfilterBar
    local function DropdownOnMouseUpHandler(dropdown, mouseButton, upInside)
        local comboBox = dropdown.m_comboBox
        AF.currentCombobox = comboBox
        AF.currentComboboxSelectedItem = nil

        if not upInside then return end
        --Get the current subfilterBar button
        local button = selfVar:GetCurrentButton()
        if not button then return end
        --Get the current LibFilters filterPanelId
        local filterPanelIdActive = getCurrentFilterTypeForInventory(AF.currentInventoryType)

        --Build a new dropdown entry based on given submenu data (mapping filterCallback -> callback func etc.).
        --Will re-use the existing dropdown entry if not-inverted, else it will create a new copy for the inverted data
        local function buildNewDropdownEntry(currentlySelectedDropdownItem, filterCallback)
            --d("[AF]buildNewDropdownEntry")
            --Build the now new selected item of the dropdown with the inverted data
            local newSelectedItem = {}
            --[[
            newSelectedItem = ZO_ShallowTableCopy(currentlySelectedDropdownItem)
            newSelectedItem = currentlySelectedDropdownItem
            newSelectedItem.filterResetAtStart = currentlySelectedDropdownItem.filterResetAtStart  -- For AF.util.ApplyFilter
            newSelectedItem.filterResetAtStartDelay = currentlySelectedDropdownItem.filterResetAtStartDelay  -- For AF.util.ApplyFilter
            --d("[AF]invertFilter at dropdown-filterResetAtStart: " ..tos(newSelectedItem.filterResetAtStart) .. ", filterResetAtStartDelay: " ..tos(currentlySelectedDropdownItem.filterResetAtStartDelay))

            newSelectedItem.filterStartCallback = currentlySelectedDropdownItem.filterStartCallback -- For AF.util.ApplyFilter
            newSelectedItem.filterEndCallback = currentlySelectedDropdownItem.filterEndCallback -- For AF.util.ApplyFilter
            ]]
            newSelectedItem.callback = filterCallback
            newSelectedItem.filterCallback = filterCallback
            return newSelectedItem
        end

        --Invert the dropdown box entry's callback function and call it afterwards
        local function invertDropdownEntryAndCallCallback(skipReset, overrideToInvert)
--d("[AF]invertDropdownEntryAndCallCallback-skipReset: " ..tos(skipReset) .. ", overrideToInvert: " ..tos(overrideToInvert))
            skipReset = skipReset or false
            --Reset the external filter plugin isFiltered variable. They will be set again as the filter plugin is used
            --again, or a dropdown value is re-applied via ActivateButton function
            --[[
            if not skipReset then
                util.ResetExternalDropdownFilterPluginsIsFiltering()
            end
            ]]
--AF._lastFilterButton = button
            local l_filterPanelIdActive = getCurrentFilterTypeForInventory(AF.currentInventoryType)
            local filterType = getCurrentFilterTypeForInventory(selfVar:GetInventoryType())
--d(">[AF]l_filterPanelIdActive: " ..tos(l_filterPanelIdActive) .. ", filterType: " ..tos(filterType))
            local lastSelectedItem = (button.previousDropdownSelection ~= nil and button.previousDropdownSelection[l_filterPanelIdActive]) or nil
            local currentlySelectedDropdownItem = comboBox:GetSelectedItemData()
            if not currentlySelectedDropdownItem then return end
            local originalCallback = util.LibFilters:GetFilterCallback(AF_CONST_DROPDOWN_FILTER, filterType)
            if originalCallback == nil then
                d("[AdvancedFilters] ERROR - Original callback function of dropdown entry was not found for filterType "..tos(filterType).."!")
                return
            end
            local filterCallback


            if overrideToInvert ~= nil then
                --Use inverted filter callback
                if overrideToInvert == true then
                    filterCallback = function(slot, slotIndex)
                        return not originalCallback(slot, slotIndex)
                    end
                else
                    --Use non inverted filter callback
                    filterCallback = originalCallback
                end
            else
                --Invert the filter callback function
                filterCallback = function(slot, slotIndex)
                    return not originalCallback(slot, slotIndex)
                end
            end

            --Remove all old <> (unequal) signs
            currentlySelectedDropdownItem.name = string.gsub(currentlySelectedDropdownItem.name, "≠", "")

            --Build the now new selected item of the dropdown with the inverted data
            local newSelectedItem = buildNewDropdownEntry(currentlySelectedDropdownItem, filterCallback)

            if overrideToInvert ~= nil then
                --Use inverted filter callback
                if overrideToInvert == true then
                    newSelectedItem.isInverted = true
                    newSelectedItem.name = "≠" .. currentlySelectedDropdownItem.name
                else
                    --Use non inverted filter callback
                    newSelectedItem.isInverted = false
                    newSelectedItem.name = currentlySelectedDropdownItem.name
                end
            else
                if lastSelectedItem and lastSelectedItem.isInverted then
                    newSelectedItem.isInverted = false
                    newSelectedItem.name = currentlySelectedDropdownItem.name
                else
                    newSelectedItem.isInverted = true
                    newSelectedItem.name = "≠" .. currentlySelectedDropdownItem.name
                end
            end
--AF._newSelectedItem = newSelectedItem
            button.previousDropdownSelection[l_filterPanelIdActive] = newSelectedItem
            comboBox.m_selectedItemData = newSelectedItem
            comboBox.m_selectedItemText:SetText(newSelectedItem.name)

            PlaySound(SOUNDS.MENU_BAR_CLICK)

            applyFilter(newSelectedItem, AF_CONST_DROPDOWN_FILTER, true, filterType)
            selfVar:UpdateLastSelectedDropdownEntries(button, "invertDropdownEntryAndCallCallback")
            return true
        end

        --Select a dropdown entry via it's name
        local function selectDropdownEntry(entry)
            if entry == nil or entry == "" then return end
            --AF._lastSelectedEntry = entry
            local filterType = getCurrentFilterTypeForInventory(selfVar:GetInventoryType())
            local l_filterPanelIdActive = getCurrentFilterTypeForInventory(AF.currentInventoryType)

            --Is the entry inverted?
            if entry.isInverted == true then
                --We wont find any entry with the leading ≠ so remove this char first to search for the non-inverted name
                entry.name = string.gsub(entry.name, "≠", "")
            end

            --Select all? Then select first entry
            if entry == AF_CONST_ALL or (entry.name == AF_CONST_ALL or entry.name == util.Localize(SI_ITEMFILTERTYPE0)) then
                --d("[AF]Reset combobox to ALL")
                --Reset the external filter plugin isFiltered variable. They will be set again as the filter plugin is used again or a dropdown value is reapllied via ActivateButton function
                --util.ResetExternalDropdownFilterPluginsIsFiltering()
                comboBox:SelectFirstItem()
                --Get the first entry of the dropdownbox (should be "All")
                local firstItem = comboBox.m_sortedItems[1]
                --Is the current firstItem inverted, or the supplied entry (history of dropdown box selections) was an inverted "≠All"?
                if firstItem.isInverted or entry.isInverted then
                    --Set the first item to "not" inverted, so it will be inverted with the next call to "invertDropdownEntryAndCallCallback"
                    firstItem.isInverted = false
                    local prevSelectionAtButtonBackup = button.previousDropdownSelection[l_filterPanelIdActive]
                    button.previousDropdownSelection[l_filterPanelIdActive] = firstItem
                    if not invertDropdownEntryAndCallCallback(true) then
                        firstItem.isInverted = true
                        button.previousDropdownSelection[l_filterPanelIdActive] = prevSelectionAtButtonBackup
                    end
                else
                    button.previousDropdownSelection[l_filterPanelIdActive] = firstItem

                    PlaySound(SOUNDS.MENU_BAR_CLICK)

                    util.LibFilters:RequestUpdate(filterType)
                end
            else
                --Search combobox cbox with function evalFunc
                local function comboBox_GetItemByEval(cbox, evalFunc, ignoreCallback)
                    --Sorted items of combobox
                    for i, item in ipairs(cbox.m_sortedItems) do
                        if evalFunc(item) then
                            cbox:SelectItemByIndex(i, ignoreCallback)
                            return item
                        end
                    end
                    --Submenu candidates
                    if cbox.submenuCandidates then
                        for _, submenuCandidatesItem in ipairs(cbox.submenuCandidates) do
                            for j, submenuCallbackTableItem in ipairs(submenuCandidatesItem.callbackTable) do
                                if evalFunc(submenuCallbackTableItem) then
                                    return submenuCallbackTableItem
                                end
                            end
                        end
                    end
                    return nil
                end
                --Select the dropdown entry by the eval function (comparing the name) and do not ignore the callback function
                local oldItem = comboBox_GetItemByEval(comboBox, function(item)
                    --d("[AF]Compared: \'" ..tos(entry.name) .. "\' and \'" .. tos(item.name) .. "\'")
                    if entry.name == item.name then
                        return item
                    end
                end, true)
                if oldItem ~= nil then
                    --d("[AF]found oldItem")
                    --AF._oldItem = oldItem
                    local newSelectedItem
                    local isSubMenuItem = false
                    if oldItem.callback ~= nil and type(oldItem.callback) == "function" then
                        --d(">oldItem is dropdown entry")
                        --Re-Use the original dropdown entry data
                        newSelectedItem = oldItem
                    elseif oldItem.filterCallback then
                        --d(">oldItem is dropdown's submenu candidate")
                        isSubMenuItem = true
                        --Build the new dropdown entry from the submenu data
                        newSelectedItem = buildNewDropdownEntry(oldItem, oldItem.filterCallback)
                    end
                    if newSelectedItem ~= nil then
                        if isSubMenuItem == true then
                            comboBox:SelectItem(newSelectedItem, false)
                            button.previousDropdownSelection[l_filterPanelIdActive] = newSelectedItem
                            comboBox.m_selectedItemText:SetText(newSelectedItem.name)

                            PlaySound(SOUNDS.MENU_BAR_CLICK)
                            selfVar:UpdateLastSelectedDropdownEntries(button, "selectDropdownEntry-SubMenuItem")
                        end
                        if newSelectedItem.isInverted == true then
                            --d(">history item was inverted")
                            --Invert the item's callback function again now
                            local originalCallback = oldItem.callback or oldItem.filterCallback
                            local filterCallback = function(slot, slotIndex)
                                return not originalCallback(slot, slotIndex)
                            end
                            newSelectedItem.callback = filterCallback
                        end
                        --AF._newItem = newSelectedItem
                        --Apply the filter of the now selected itemdata and apply the callback
                        applyFilter(newSelectedItem, AF_CONST_DROPDOWN_FILTER, true, filterType)
                    end
                end
            end
        end

        --[Show/Hide the combobox dropdown entries]
        local anchorZOMenuToControl = selfVar.anchorZOMenuOfDropdownFiltersToControl or dropdown
        local anchorToDropdown = anchorZOMenuToControl == dropdown or false
        --Left mouse button
        if mouseButton == MOUSE_BUTTON_INDEX_LEFT then
            if comboBox.m_isDropdownVisible then
                comboBox:HideDropdownInternal()
            else
                if IsShiftKeyDown() then
                    --Select All entry
                    selectDropdownEntry(AF_CONST_ALL)
                else
                    --Show menu to select an entry
                    comboBox:ShowDropdownInternal()
                    if not anchorToDropdown then
                        comboBox:SetVisible(false)
                        AnchorMenu(anchorZOMenuToControl, 5)
                        comboBox:SetVisible(true)
                    end
                end
            end
        --Right mouse button
        elseif mouseButton == MOUSE_BUTTON_INDEX_RIGHT then
            --Add the context menu dropdown filter box menu for "All" and "Invert" and "last selected history" entries
            --d("[AF]filterPanelIdActive at filter plugin dropdown right click: " ..tos(filterPanelIdActive))
            --Add the currently active filtername to the dropdown "Invert" entry
            --if settings.debugSpam then d("[AF]AF_FilterBar:Initialize - DropdownOnMouseUpHandler, 2: " .. tos(button.name) .. ", filterPanelId: " ..tos(filterPanelIdActive)) end
            local previousDropdownSelection = (button.previousDropdownSelection ~= nil and button.previousDropdownSelection[filterPanelIdActive]) or nil
            local currentActiveFilterName = previousDropdownSelection.name or ""
            local invertFilterText = string.format(AF.strings.InvertDropdownFilter, currentActiveFilterName)
            local entries = {
                --"Show all" items filter dropdown context menu entry
                [1] = {
                    name = AF.strings.ResetToAll,
                    callback = function()
                        selectDropdownEntry(AF_CONST_ALL)
                    end,
                },
                --"Invert current filter" filter dropdown context menu entry
                [2] = {
                    name = invertFilterText,
                    callback = function()
                        invertDropdownEntryAndCallCallback(false)
                    end,
                },
            }
            ClearMenu()
            for _, entry in ipairs(entries) do
                AddCustomMenuItem(entry.name, entry.callback, MENU_ADD_OPTION_LABEL)
            end
            --[[
            -->Last 10 selected entries history (if enabled in the settings)
            if settings.showDropdownLastSelectedEntries == true then
                if filterPanelIdActive ~= nil then
                    local lastSelectedHistoryAtFilterPanel = settings.subfilterBarDropdownLastSelectedEntries[filterPanelIdActive]
                    if lastSelectedHistoryAtFilterPanel ~= nil and #lastSelectedHistoryAtFilterPanel > 0 then
                        local lastSelectedHistoryContextMenuEntries = {}
                        for _, lastSelectedHistoryEntry in ipairs(lastSelectedHistoryAtFilterPanel) do
                            --Precheck the last selected entries and filter the ones not usable
                            if lastSelectedHistoryEntry.name and lastSelectedHistoryEntry.name ~= "" then
                                --As the anonymous filterCallback functions are not saved in the SavedVariables we need to select the entry in the dropdown with the given name
                                table.insert(lastSelectedHistoryContextMenuEntries, lastSelectedHistoryEntry)
                            end
                        end
                        if lastSelectedHistoryContextMenuEntries and #lastSelectedHistoryContextMenuEntries > 0 then
                            --Add a divider into the contextmenu
                            AddCustomMenuItem("-", nil, MENU_ADD_OPTION_LABEL)
                            for _, lastSelectedHistoryEntryUsable in ipairs(lastSelectedHistoryContextMenuEntries) do
                                --Then add the up to 10 entries of the last selected entries history
                                AddCustomMenuItem(lastSelectedHistoryEntryUsable.name, function() selectDropdownEntry(lastSelectedHistoryEntryUsable) end, MENU_ADD_OPTION_LABEL)
                            end
                        end
                    end

                end
            end
            ]]

            --Anchor the ZO_Menu of the dropdown to a control specified, or to the dropdown control
            ShowMenu(anchorZOMenuToControl)
        end
    end
    self.dropdown:SetHandler("OnMouseUp", DropdownOnMouseUpHandler)
    self.dropdown.dropdownOnMouseUpHandlerFunc = DropdownOnMouseUpHandler
------------------------------------------------------------------------------------------------------------------------

    local comboBox = self.dropdown.m_comboBox

    local function DropdownOnMouseEnterHandler()
        local selectedItemText = comboBox.m_selectedItemText
        if selectedItemText ~= nil and selectedItemText:WasTruncated() == true then
            local tooltipText = selectedItemText:GetText()
            if tooltipText and tooltipText ~= "" then
                ZO_Tooltips_ShowTextTooltip(self.dropdown, LEFT, tooltipText)
            end
        end
    end
    self.dropdown:SetHandler("OnMouseEnter", DropdownOnMouseEnterHandler)
------------------------------------------------------------------------------------------------------------------------
    local function DropdownOnMouseExitHandler()
        ZO_Tooltips_HideTextTooltip()
    end
    self.dropdown:SetHandler("OnMouseExit", DropdownOnMouseExitHandler)
------------------------------------------------------------------------------------------------------------------------

    comboBox:SetSortsItems(false)
    comboBox.AddMenuItems = function(p_comboBox)
        local button = selfVar:GetCurrentButton()
        --local self = p_comboBox

        --Get the current LibFilters filterPanelId
        local filterPanelIdActive = getCurrentFilterTypeForInventory(AF.currentInventoryType)

        for i = 1, #p_comboBox.m_sortedItems do
            -- The variable item must be defined locally here, otherwise it won't work as an upvalue to the selection helper
            local item = p_comboBox.m_sortedItems[i]

            local function OnSelect()
                AF.currentCombobox = p_comboBox
                AF.currentComboboxSelectedItem = item

                ZO_ComboBox_Base_ItemSelectedClickHelper(p_comboBox, item)
                button.previousDropdownSelection = button.previousDropdownSelection or {}
                button.previousDropdownSelection[filterPanelIdActive] = item

                PlaySound(SOUNDS.MENU_BAR_CLICK)
            end
            local itemCallbackFunc
            local itemType = item.itemType
            if itemType ~= MENU_ADD_OPTION_HEADER then
                itemCallbackFunc = OnSelect
            end
            AddCustomMenuItem(item.name, itemCallbackFunc, itemType, p_comboBox.m_font, p_comboBox.m_normalColor, p_comboBox.m_highlightColor)
        end

        --Add the dropdown filter box context menu entries
        -->Normal filters via AF and plugins
        local submenuCandidates = p_comboBox.submenuCandidates
        for _, submenuCandidate in ipairs(submenuCandidates) do
            local entries = {}
            for _, callbackEntry in ipairs(submenuCandidate.callbackTable) do
                local nameOfEntry = AF.strings[callbackEntry.name]
                local nameOfEntryWithIcon = callbackEntry.nameWithIcon
                local nameOfEntryWithoutIcon = callbackEntry.nameWithoutIcon
                if not nameOfEntryWithIcon or nameOfEntryWithIcon == "" then
                    nameOfEntryWithIcon = nameOfEntry
                end
                if not nameOfEntry or nameOfEntry == "" then
                    d("[AdvancedFilters] ERROR - FilterBar init - SubmenuCandidates -  Name is missing! InventoryName: " .. tos(inventoryName) .. ", tradeSkillname: " .. tos(tradeSkillname) .. ", groupName: " ..tos(groupName) .. ", subfilterNames: " .. tos(subfilterNames))
                end
                local entry
                if callbackEntry.itemType ~= nil and callbackEntry.itemType == MENU_ADD_OPTION_HEADER then
                    entry = {
                        itemType = MENU_ADD_OPTION_HEADER,
                        label = nameOfEntryWithIcon or nameOfEntryWithoutIcon or nameOfEntry,
                        --disabled = true,
                    }
                else
                    entry = {
                        label = nameOfEntryWithIcon,
                        callback = function()
                            applyFilter(callbackEntry, AF_CONST_DROPDOWN_FILTER, true)
                            selfVar:UpdateLastSelectedDropdownEntries(button, "AF_FilterBar '"..tos(AF_FilterBarName).."', SubMenu-NameOfEntry: " ..tos(nameOfEntry))
                            button.forceNextDropdownRefresh = true
                            p_comboBox.m_selectedItemText:SetText(nameOfEntryWithIcon)
                            p_comboBox.m_selectedItemData = p_comboBox:CreateItemEntry(nameOfEntryWithIcon,
                                    function(p_l_comboBox, itemName, item, selectionChanged)
                                        applyFilter(callbackEntry,
                                                AF_CONST_DROPDOWN_FILTER,
                                                selectionChanged or button.forceNextDropdownRefresh)
                                        selfVar:UpdateLastSelectedDropdownEntries(button, "AF_FilterBar '"..tos(p_comboBox.name).."-ComboBoxEntry SelectedItemData: " ..tos(nameOfEntry))
                                    end)
                            p_comboBox.m_selectedItemData.filterResetAtStartDelay = callbackEntry.filterResetAtStartDelay
                            p_comboBox.m_selectedItemData.filterResetAtStart      = callbackEntry.filterResetAtStart
                            p_comboBox.m_selectedItemData.filterStartCallback     = callbackEntry.filterStartCallback
                            p_comboBox.m_selectedItemData.filterEndCallback       = callbackEntry.filterEndCallback
                            p_comboBox.m_selectedItemData.nameWithoutIcon         = nameOfEntryWithoutIcon
                            --Get the current LibFilters filterPanelId
                            local filterPanelIdActiveAsContextMenuEntryCallbackFires = getCurrentFilterTypeForInventory(AF.currentInventoryType)
                            button.previousDropdownSelection = button.previousDropdownSelection or {}
                            button.previousDropdownSelection[filterPanelIdActiveAsContextMenuEntryCallbackFires] = p_comboBox.m_selectedItemData

                            PlaySound(SOUNDS.MENU_BAR_CLICK)

                            ClearMenu()
                        end,
                    }
                end
                table.insert(entries, entry)
            end
            AddCustomSubMenuItem(AF.strings[submenuCandidate.submenuName], entries, "ZoFontGameSmall")
        end
    end
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
    --Add the buttons to the subfilterBar now
    for _, subfilterName in ipairs(subfilterNames) do
        --Check if this subfilterName (button) is excluded at the current groupName
        local doNotAddButtonNow = false
        if excludeTheseButtons ~= nil then
            if type(excludeTheseButtons) == "table" then
                local buttonNamesToExclude = excludeTheseButtons[1]
                for _, buttonNameToExclude in pairs(buttonNamesToExclude) do
                    doNotAddButtonNow = (buttonNameToExclude == subfilterName) or false
                    if doNotAddButtonNow then
                        break
                    end
                end
            elseif type(excludeTheseButtons) == "string" then
                doNotAddButtonNow = (excludeTheseButtons == subfilterName) or false
            end
        end
        if not doNotAddButtonNow then
            self:AddSubfilter(groupName, subfilterName)
            --elseif settings.debugSpam then d(">>>Not adding button: " .. tos(subfilterName) .. ", at inventory: " .. tos(inventoryName) .. ", groupName: " .. tos(groupName))
        end
    end

    updateControlZ(self.control,    DT_MEDIUM, DL_CONTROLS, 1)
    updateControlZ(self.dropdown,   DT_MEDIUM, DL_CONTROLS, 1)
end

--Add a subfilter bar button
function AF_FilterBar:AddSubfilter(groupName, subfilterName)
    local iconPath = AF.textures[subfilterName]
    if iconPath == nil then
        d("[AdvancedFilters] ERROR - AddSubfilter: Texture for subfilter " .. tos(subfilterName) .. " is missing! Please add textures." .. tos(subfilterName) .. " to file textures.lua.")
        return
    end
    local icon = {
        up      = string.format(iconPath, "up"),
        down    = string.format(iconPath, "down"),
        over    = string.format(iconPath, "over"),
    }
    local settings = AF.settings
    if settings.debugSpam then d("[AF_FilterBar:AddSubfilter]groupName: " ..tos(groupName) .. ", subfilterName: " ..tos(subfilterName)) end
    if AF.subfilterCallbacks[groupName] == nil then
        d("[AdvancedFilters] ERROR - AddSubfilter: Subfilter callback \'data\' missing for group \'" ..tos(groupName).."\'")
        return nil
    end
    if AF.subfilterCallbacks[groupName][subfilterName] == nil then
        --Check if the groupName's filterType got a replacement subfilterName and thus the data is missing
        --e.g. LightArmor, Heavy, Clothing, ... -> Body
        local filterType = mapGroupNameToFilterType(groupName)
        local showError = true
        if filterType then
            local replacementSubfilterName = mapMultipleGroupSubfiltersToCombinedSubfilter(filterType, subfilterName)
            if replacementSubfilterName and replacementSubfilterName ~= "" then showError = false end
        end
        if showError then
            d("[AdvancedFilters] ERROR - AddSubfilter: Subfilter callback \'data\' missing for group \'" ..tos(groupName) .. "\', subFilter: \'" ..tos(subfilterName).."\'")
        end
        return nil
    end
    local subfilterButtonData = AF.subfilterCallbacks[groupName][subfilterName]
    --Set the button's callback functions for start, start with delay, normal and end
    local callback = subfilterButtonData.filterCallback
    if callback == nil then
        d("[AdvancedFilters] ERROR - AddSubfilter: Subfilter callback \'function\' missing for group \'" ..tos(groupName) .. "\', subFilter: \'" ..tos(subfilterName).."\'")
        return nil
    end
    local showFilterDropdownMenuOnRightMouseAtSubFilterButton = settings.showFilterDropdownMenuOnRightMouseAtSubFilterButton

    local filterResetAtStartDelay = subfilterButtonData.filterResetAtStartDelay
    local filterStartCallback = subfilterButtonData.filterStartCallback
    local filterEndCallback = subfilterButtonData.filterEndCallback

    local subfilterBarButtonSize = 32
    local anchorX = -116 + #self.subfilterButtons * (subfilterBarButtonSize*-1)

    local button = WINDOW_MANAGER:CreateControlFromVirtual(self.control:GetName() .. subfilterName .. "Button", self.control, "AF_Button")
    local texture = button:GetNamedChild("Texture")
    local highlight = button:GetNamedChild("Highlight")

    texture:SetTexture(icon.up)
    highlight:SetTexture(icon.over)

    button:SetAnchor(RIGHT, self.control, RIGHT, anchorX, 0)
    button:SetClickSound(SOUNDS.MENU_BAR_CLICK)

    --[[
    local function OnClicked(thisButton)
        if(not thisButton.clickable) then return end
        self:ActivateButton(thisButton)
    end
    ]]

    local function OnMouseEnter(thisButton)
        ZO_Tooltips_ShowTextTooltip(thisButton, TOP, AF.strings[subfilterName])

        local clickable = thisButton.clickable
        local active = self:GetCurrentButton() == thisButton

        if clickable and not active then
            highlight:SetHidden(false)
        end
    end

    local function OnMouseExit()
        ZO_Tooltips_HideTextTooltip()

        highlight:SetHidden(true)
    end

    button:SetHandler("OnMouseEnter", OnMouseEnter)
    button:SetHandler("OnMouseExit", OnMouseExit)

    local function OnMouseUp(thisButton, mouseButton, upInside, ctrl, alt, shift, command)
        if upInside then
            local clickable = thisButton.clickable
            if clickable then
                --local doClearMenu = false
                local active = self:GetCurrentButton() == thisButton
                local isLeftMouseUp = (mouseButton == MOUSE_BUTTON_INDEX_LEFT) or false
                local isRightMouseUp = (mouseButton == MOUSE_BUTTON_INDEX_RIGHT) or false

                --Is the dropdown plugin filter combobox open, but not anchored to the dropdown but some other
                --control (of the subfilterBar)? Hide it
                local dropdown = self.dropdown
                --local comboBox = dropdown.m_comboBox
                if isLeftMouseUp or isRightMouseUp then
                --[[
                    local menuVisible = IsMenuVisible()
                    local menuOwner = GetMenuOwner()
AF._menuOwner = menuOwner
AF._menuVisible = menuVisible
AF._comboBox = comboBox
AF._dropdown = dropdown
                    if menuVisible == true then
d("[AF]Menu shown. Anchored to: " ..tos(menuOwner:GetName()))
                        if menuOwner ~= dropdown then
                            doClearMenu = true
                        end
                    end
                    --Hide currently opened menu
                    if doClearMenu == true then
d(">>clearing menu!")
                        ClearMenu()
                    end
                    ]]
                    ClearMenu()
                end
                if isLeftMouseUp then
                    if not active and not ctrl and not alt and not shift and not command then
                        --Activate the button first
                        self:ActivateButton(thisButton)
                    end

                elseif isRightMouseUp then
                    if showFilterDropdownMenuOnRightMouseAtSubFilterButton == true then
                        if not active then
                            --Activate the button first
                            self:ActivateButton(thisButton)
                        end
                        -->This below will show the left/right click menu of the filter dropdown
                        --Set the anchor control for the dropdown to the current subfilterButton
                        --Show the context menu of the filter plugins dropdown: Left mouse button click on the dropdown
                        zo_callLater(function()
                            self.anchorZOMenuOfDropdownFiltersToControl = thisButton
                            local mouseButtonToUse = (shift == true and MOUSE_BUTTON_INDEX_RIGHT) or MOUSE_BUTTON_INDEX_LEFT
                            self.dropdown.dropdownOnMouseUpHandlerFunc(dropdown, mouseButtonToUse, true)
                            --Remove the anchor control again so next dropdown opens at the combobox control
                            self.anchorZOMenuOfDropdownFiltersToControl = nil
                        end, 50)
                    end

                end
            end
        end
    end
    local function OnClicked(thisButton)
        --OnMouseUp handles this alone!
        if showFilterDropdownMenuOnRightMouseAtSubFilterButton == true then return end
        OnMouseUp(thisButton, MOUSE_BUTTON_INDEX_LEFT, true, IsControlKeyDown(), IsAltKeyDown(), IsShiftKeyDown(), IsCommandKeyDown())
    end
    button:SetHandler("OnMouseUp", OnMouseUp)
    button:SetHandler("OnClicked", OnClicked)

    button.name = subfilterName
    button.groupName = groupName
    button.texture = texture
    button.clickable = true
    button.filterCallback = callback
    button.filterStartCallback = filterStartCallback
    button.filterResetAtStartDelay = filterResetAtStartDelay
    button.filterEndCallback = filterEndCallback

    button.up = icon.up
    button.down = icon.down

    self.activeButton = button

    updateControlZ(button,   DT_MEDIUM, DL_CONTROLS, 1)

    table.insert(self.subfilterButtons, button)
end

function AF_FilterBar:ActivateButton(newButton)
    local settings              = AF.settings
    local doDebugOutput         = settings.doDebugOutput
    local debugSpam             = settings.debugSpam
    if not newButton then return end
    if debugSpam then
        d("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!>")
        d("[AF]ActivateButton: " ..tos(newButton.name))
    end
    --------------------------------------------------------------------------------------------------------------------
    local function PopulateDropdown(p_newButton)
        local comboBox = self.dropdown.m_comboBox
        p_newButton.dropdownCallbacks = BuildDropdownCallbacks(p_newButton.groupName, p_newButton.name)
        local showIconsInFilterDropdowns = AF.settings.showIconsInFilterDropdowns
        local textures = AF.textures
        local texturesReSize = AF.texturesReSize

        --Update the entry's text and texture
        local function updateDropdownEntry(v, isSubmenu)
            isSubmenu = isSubmenu or false
            local totalDropdownEntryWithIcon

            local dropdownEntryName = v.name
            if v.addString ~= nil and v.addString ~= "" then
                dropdownEntryName = dropdownEntryName .. "_" .. v.addString
            end
            local iconForDropdownCallbackEntry = ""
            if showIconsInFilterDropdowns and v.showIcon ~= nil and v.showIcon == true then
                --d(">v.name: " ..tos(v.name))
                local textureName = textures[v.name] or ""
                if textureName ~= "" then
                    --Remove the placeholder %s
                    textureName = string.format(textureName, "up")
                    local width, height = 28, 28
                    if isSubmenu then
                        width, height = 18, 18
                    end
                    if texturesReSize then
                        local textureReSizeData = texturesReSize[v.name]
                        if textureReSizeData and textureReSizeData.width and textureReSizeData.height then
                            width, height = textureReSizeData.width, textureReSizeData.height
                            if isSubmenu then
                                width = width -10
                                height = height -10
                                if width < 8 then width = 8 end
                                if height < 8 then height = 8 end
                            end
                        end
                    end
                    if textureName ~= "" then
                        iconForDropdownCallbackEntry = zo_iconFormat(textureName, width, height)
                    end
                end
            end
            local itemEntryName = AF.strings[dropdownEntryName] or ""

            if itemEntryName == "" then
                d("[AdvancedFilters] ERROR - Translation missing for dropdown filter entry: " .. tos(dropdownEntryName))
                return nil, nil, nil, nil
            else
                if showIconsInFilterDropdowns and iconForDropdownCallbackEntry ~= "" then
                    totalDropdownEntryWithIcon = iconForDropdownCallbackEntry .. " " .. itemEntryName
                else
                    totalDropdownEntryWithIcon = itemEntryName
                end
            end
            return dropdownEntryName, itemEntryName, iconForDropdownCallbackEntry, totalDropdownEntryWithIcon
        end

        comboBox.submenuCandidates = {}
        for _, v in ipairs(p_newButton.dropdownCallbacks) do
            if v.submenuName then
                --Check each of the callbackTable entries if an icon should be shown or a pre/suffix text needs to be added
                if v.callbackTable and #v.callbackTable > 0 then
                    for idx,cbTableDataTab in ipairs(v.callbackTable) do
                        if (cbTableDataTab.addString ~= nil and cbTableDataTab.addString ~= "") or cbTableDataTab.showIcon == true then
                            local dropdownEntryName, itemEntryName, iconForDropdownCallbackEntry, totalDropdownEntryWithIcon = updateDropdownEntry(cbTableDataTab, true)
                            if dropdownEntryName ~= nil and totalDropdownEntryWithIcon ~= nil and totalDropdownEntryWithIcon ~= "" then
                                v.callbackTable[idx].nameWithIcon = totalDropdownEntryWithIcon
                                v.callbackTable[idx].nameWithoutIcon = itemEntryName
                            end
                        end
                    end
                end
                table.insert(comboBox.submenuCandidates, v)
            else
                local dropdownEntryName, itemEntryName, iconForDropdownCallbackEntry, totalDropdownEntryWithIcon = updateDropdownEntry(v, false)
                if dropdownEntryName ~= nil and totalDropdownEntryWithIcon ~= nil and totalDropdownEntryWithIcon ~= "" then
                    local itemEntry = ZO_ComboBox:CreateItemEntry(totalDropdownEntryWithIcon,
                            function(comboBox, itemName, item, selectionChanged)
                                applyFilter(v, AF_CONST_DROPDOWN_FILTER, selectionChanged or p_newButton.forceNextDropdownRefresh)
                                self:UpdateLastSelectedDropdownEntries(p_newButton, "PopulateDropdown-DropdownName: " ..tos(dropdownEntryName) .. ", itemName: " ..tos(itemName))
                            end)
                    itemEntry.filterResetAtStartDelay   = v.filterResetAtStartDelay
                    itemEntry.filterResetAtStart        = v.filterResetAtStart
                    itemEntry.filterStartCallback       = v.filterStartCallback
                    itemEntry.filterEndCallback         = v.filterEndCallback
                    itemEntry.nameWithoutIcon           = itemEntryName
                    comboBox:AddItem(itemEntry)
                end
            end
        end
        comboBox:SetSelectedItemFont("ZoFontGameSmall")
        comboBox:SetDropdownFont("ZoFontGameSmall")
    end
    --------------------------------------------------------------------------------------------------------------------
    local inventoryTypeOfFilterBar = self:GetInventoryType()
    checkSpecialInventoryTypesAndUpdateCurrentInventoryType(inventoryTypeOfFilterBar)

    --Should the subfilterBar be shown?
    if checkIfNoSubfilterBarShouldBeShown(nil, inventoryTypeOfFilterBar) then
        if debugSpam then d(">[AF]ActivateButton - ABORT: CheckIfNoSubfilterBarShouldBeShown: true") end
        return
    end

    local name = newButton.name
    local nameText
    if AF.strings and AF.strings[name] then
        nameText = AF.strings[name]
    else
        showChatDebug("AF_FilterBar:ActivateButton", "AF.strings missing for name: " ..tos(name) .. ", language: " .. tos(AF.clientLang))
        nameText = "ERROR: n/a"
    end
    self.label:SetText(nameText)
    local settings = AF.settings
    self.label:SetHidden(settings.hideSubFilterLabel)

    local oldButton = self.activeButton

    --hide old down texture
    oldButton:GetNamedChild("Texture"):SetTexture(oldButton.up)
    oldButton:SetEnabled(true)

    --show new down texture
    newButton:GetNamedChild("Texture"):SetTexture(newButton.down)
    newButton:SetEnabled(false)

    --refresh filters
    applyFilter(newButton, AF_CONST_BUTTON_FILTER, true, nil, inventoryTypeOfFilterBar) --let the filterType be determined in the function AF.util.ApplyFilter

    --set new active button reference
    self.activeButton = newButton

    --clear old dropdown data
    self.dropdown.m_comboBox.m_sortedItems = {}
    --Get the current LibFilters filterPanelId
    if inventoryTypeOfFilterBar == nil then
        --if doDebugOutput or debugSpam then
            d("===============================================")
            d("[AdvancedFilters]AF_FilterBar:ActivateButton: " .. tos(newButton.name))
            d(">ERROR - inventoryType is NIL!")
            d("===============================================")
        --end
    end
    --Get the current's inventory filterType
    local filterPanelIdActive = getCurrentFilterTypeForInventory(inventoryTypeOfFilterBar)
    if filterPanelIdActive == nil then
        --if doDebugOutput or debugSpam then
            d("===============================================")
            d("[AdvancedFilters]AF_FilterBar:ActivateButton: " .. tos(newButton.name))
            d(">ERROR - filterPanelId is NIL!")
            d("===============================================")
        --end
    end
    --add new dropdown data
    PopulateDropdown(newButton)
    --re-select the previous selected/first entry of the dropdown box
    if inventoryTypeOfFilterBar and filterPanelIdActive then
        self:ApplyDropdownSelection(newButton)
        --Check if the settings to show an animationa round the dropdown entry, if any selection is active, is enabled
        --and show the rectangle around the box then
        self:ShowDropdownSelectedAnimation(newButton)
    end
end

--Re-Apply the dropdown filter box to the subFilter bar and select the last chosen entry at the given filterPanel
--if the setting for this is enabled
function AF_FilterBar:ApplyDropdownSelection(newButton)
    if AF.settings.debugSpam then  d("[AF]FilterBar.ApplyDropdownSelection") end
    newButton = newButton or self:GetCurrentButton()
    if newButton == nil then return end
    local inventoryType = AF.currentInventoryType or self:GetInventoryType()
    checkSpecialInventoryTypesAndUpdateCurrentInventoryType(inventoryType)
    if inventoryType == nil then return end
    local filterPanelIdActive = getCurrentFilterTypeForInventory(inventoryType)
    if filterPanelIdActive == nil then return end
    --Reset the external filter plugin isFiltered variable. They will be set again as the filter plugin is used again or a dropdown value is reapllied via ActivateButton function
    --util.ResetExternalDropdownFilterPluginsIsFiltering()
    local currentlySelectedDropDownEntry
    --select the first item if there is no previous selection or the setting to remember the last selection is disabled
    if not AF.settings.rememberFilterDropdownsLastSelection or not newButton.previousDropdownSelection or not newButton.previousDropdownSelection[filterPanelIdActive] then
        --Select the first entry
        self.dropdown.m_comboBox:SelectFirstItem()
        local selectedItem = self.dropdown.m_comboBox.m_sortedItems[1]
        AF.currentlySelectedDropDownEntry = selectedItem
        --util.LibFilters:UnregisterFilter(AF_CONST_DROPDOWN_FILTER, filterType)
        --util.LibFilters:RegisterFilter(AF_CONST_DROPDOWN_FILTER, filterType, filterCallback)
        --util.LibFilters:RequestUpdate(filterType)
        newButton.previousDropdownSelection = newButton.previousDropdownSelection or {}
        newButton.previousDropdownSelection[filterPanelIdActive] = selectedItem
    else
        --restore previous dropdown selection if the settings is enabled for this
        local previousDropdownSelection = newButton.previousDropdownSelection[filterPanelIdActive]
        --Check if the previous selection was a right mouse context menu "invert" option
        if previousDropdownSelection.isInverted then
            --Reapply the filter of the inversion
            --local originalCallback = util.LibFilters:GetFilterCallback(AF_CONST_DROPDOWN_FILTER, filterType)
            local originalCallback = previousDropdownSelection.callback
            previousDropdownSelection.filterCallback = originalCallback
            applyFilter(previousDropdownSelection, AF_CONST_DROPDOWN_FILTER, true, filterPanelIdActive)
            --Select the dropdown entry but do not call the callback function as the filter was updated above already
            self.dropdown.m_comboBox:SelectItem(previousDropdownSelection, true)
        else
            if previousDropdownSelection.filterCallback ~= nil then
                applyFilter(previousDropdownSelection, AF_CONST_DROPDOWN_FILTER, true, filterPanelIdActive)
            end
            --Select the dropdown entry and call the callback function
            self.dropdown.m_comboBox:SelectItem(previousDropdownSelection, false)
        end
    end
end

--Update last selected history entries of the dropdown boxes?
function AF_FilterBar:UpdateLastSelectedDropdownEntries(subfilterBarButton, calledFrom)
--[[
    d("[AF]UpdateLastSelectedDropdownEntries("..tos(calledFrom)..") - subFilterBarButton: " ..tos(subfilterBarButton.name))
    subfilterBarButton = subfilterBarButton or self:GetCurrentButton()
    if subfilterBarButton == nil then return end
    if not AF.settings.showDropdownLastSelectedEntries then return end
    local inventoryType = AF.currentInventoryType or self:GetInventoryType()
    if inventoryType == nil then return end
    --d(">inventoryType: " ..tos(inventoryType))
    local filterPanelIdActive = getCurrentFilterTypeForInventory(inventoryType)
    if filterPanelIdActive == nil then return end
d(">filterPanelIdActive: " ..tos(filterPanelIdActive))
    AF.currentlySelectedDropDownEntry = AF.currentlySelectedDropDownEntry or util.GetActiveSubfilterBarSelectedDropdownFilterData(inventoryType)
    local nameToAddEntry = AF.currentlySelectedDropDownEntry
    if not nameToAddEntry then return end
    --Do not add "All" as history entry
d(">AF.currentlySelectedDropDownEntry: " ..tos(nameToAddEntry.name or "n/a"))
    if not nameToAddEntry.name or (nameToAddEntry.name and (nameToAddEntry.name == util.Localize(SI_ITEMFILTERTYPE0) or nameToAddEntry.name == AF_CONST_ALL)) then return end
    --Create table of last selected entries per LibFilters-3.0 filterPanelId
    AF.settings.subfilterBarDropdownLastSelectedEntries[filterPanelIdActive] = AF.settings.subfilterBarDropdownLastSelectedEntries[filterPanelIdActive] or {}
    local subfilterBarDropdownLastSelectedEntriesAtFilterPanel = AF.settings.subfilterBarDropdownLastSelectedEntries[filterPanelIdActive]
    --Check if the same entry is already in and remove it then
    for index, dropdownEntryTable in ipairs(subfilterBarDropdownLastSelectedEntriesAtFilterPanel) do
        if dropdownEntryTable.name and nameToAddEntry.name and dropdownEntryTable.name == nameToAddEntry.name then
            table.remove(subfilterBarDropdownLastSelectedEntriesAtFilterPanel, index)
d(">>removed \'" .. tos(dropdownEntryTable.name) .. "\' at index " ..tos(index))
        end
    end
    --Insert the current used one at the top
    -- Create a copy of the "entry" table and add it. Else the changes via "invert" context menu will change the entries in the SavedVariables as well!
    -- So we only should use the identifier "name" to compare and find the entries again.
    table.insert(subfilterBarDropdownLastSelectedEntriesAtFilterPanel, 1, ZO_ShallowTableCopy(nameToAddEntry))
d(">>inserted \'" .. tos(nameToAddEntry.name) .. "\' at index 1")
    --Only keep 10 entries in this history stack
    if #subfilterBarDropdownLastSelectedEntriesAtFilterPanel > 10 then
        table.remove(subfilterBarDropdownLastSelectedEntriesAtFilterPanel, 10)
d(">>removed all table entries > 10")
    end
    ]]
end

--Show the dropdown filter box's pulse animation if the setting is enabled and if an entry ~= "All" is selected
function AF_FilterBar:ShowDropdownSelectedAnimation()
    HidePulse()
    if not AF.settings.showDropdownSelectedReminderAnimation then return end
    local inventoryType = AF.currentInventoryType or self:GetInventoryType()
    if inventoryType == nil then return end
    AF.currentlySelectedDropDownEntry = AF.currentlySelectedDropDownEntry or util.GetActiveSubfilterBarSelectedDropdownFilterData(inventoryType)
    local nameToCheck = AF.currentlySelectedDropDownEntry
    if not nameToCheck then return end
    local allText = util.Localize(SI_ITEMFILTERTYPE0)
    --The selected filter dropdown entry's name (not text!) should not be "All". If it's "All": Check if the "name without icon" is given and if this is not "All"
    --If it's "All" as well -> Abort here. Else: Go on and flash the drodpwn box as a reminder that a filter was chosen
    if (nameToCheck.name and (nameToCheck.name == allText or nameToCheck.name == AF_CONST_ALL)) then
        if not nameToCheck.nameWithoutIcon or (nameToCheck.nameWithoutIcon and (nameToCheck.nameWithoutIcon == allText or nameToCheck.nameWithoutIcon == AF_CONST_ALL)) then
            return
        end
    end
    ShowPulse(self.dropdown)
    util.ThrottledUpdate("AF_SubfilterBarDropdownBoxPulse", 1599, HidePulse)
end

function AF_FilterBar:GetCurrentButton()
    return self.activeButton
end

function AF_FilterBar:SetHidden(shouldHide)
    local filterBarCtrl = self.control
    filterBarCtrl:SetHidden(shouldHide)

    --PerpectPixel "fix" - Increase the tier and layer and level and set to normal again afterwards
    --[[
    if not shouldHide and PP ~= nil then
--d("[AF]Showing filterBar - checking z tier/layer/level of child controls")
        for i=1, filterBarCtrl:GetNumChildren(), 1 do
            local childCtrlOfFilterBar = filterBarCtrl:GetChild(i)
            if childCtrlOfFilterBar ~= nil then
--d(">" ..tostring(childCtrlOfFilterBar:GetName()))
                updateControlZ(childCtrlOfFilterBar,   DT_MEDIUM,   DL_CONTROLS, 1)
            end
        end
    end
    ]]
end

function AF_FilterBar:SetInventoryType(inventoryType)
    self.inventoryType = inventoryType
end

function AF_FilterBar:GetInventoryType()
    return self.inventoryType
end

------------------------------------------------------------------------------------------------------------------------
--Create the subfilter bars below the inventory's filters (e.g. the weapons filters from the game will get a subfilter bar with 1hd, 2hd, staffs, shields)
-->Called at AdvancedFilters_Loaded in EVENT_ADD_ON_LOADED
function AF.CreateSubfilterBars()
    --local variables for a speedUp on access on addon's global table variables
    local doDebugOutput         = AF.settings.doDebugOutput
    local debugSpam             = AF.settings.debugSpam
    local inventoryNames        = AF.inventoryNames
    local tradeSkillNames       = AF.tradeSkillNames
    local filterTypeNames       = AF.filterTypeNames
    local subfilterGroups       = AF.subfilterGroups
    local subfilterButtonNames  = AF.subfilterButtonNames
    local excludeButtonNamesFromSubFilterBar --todo ? Where are those filled ?

    --Build each subfilterBar for the parent filter controls
    for inventoryType, tradeSkillTypeSubFilterGroup in pairs(subfilterGroups) do
        local doDebug = false
        if doDebug then
            d(">inv type: " ..tos(inventoryNames[inventoryType]))
        end
        for tradeSkillType, subfilterGroup in pairs(tradeSkillTypeSubFilterGroup) do
            for itemFilterType, _ in pairs(subfilterGroup) do
                if inventoryType and tradeSkillType and itemFilterType then
                    --Exclusion check
                    local excludeTheseButtonsAtThisFilterBar
                    if excludeButtonNamesFromSubFilterBar and excludeButtonNamesFromSubFilterBar[inventoryType]
                            and excludeButtonNamesFromSubFilterBar[inventoryType][tradeSkillType]
                            and excludeButtonNamesFromSubFilterBar[inventoryType][tradeSkillType][itemFilterType] then
                        excludeTheseButtonsAtThisFilterBar = excludeButtonNamesFromSubFilterBar[inventoryType][tradeSkillType][itemFilterType]
                    end
                    if inventoryNames[inventoryType] and tradeSkillNames[tradeSkillType] and filterTypeNames[itemFilterType] and subfilterButtonNames[itemFilterType] then
                        --Get the LibFilters filtertype of the currently active filterbar
                        local libFiltersFilterType = getSubFilterGroupsLibFiltersFilterType(inventoryType, tradeSkillType, subfilterGroup)
                        if doDebug then
                        d(">libFiltersFilterType: " ..tos(libFiltersFilterType))
                            d(inventoryNames[inventoryType])
                            d(tradeSkillNames[tradeSkillType])
                            d(filterTypeNames[itemFilterType])
                            d(subfilterButtonNames[itemFilterType])
                        end
                        --Build the subfilterBar with the buttons now
                        local subfilterBar = AF_FilterBar:New(
                                libFiltersFilterType,
                                inventoryNames[inventoryType],
                                tradeSkillNames[tradeSkillType],
                                filterTypeNames[itemFilterType],
                                subfilterButtonNames[itemFilterType],
                                excludeTheseButtonsAtThisFilterBar      --subFilterButtons which should not be shown
                        )
                        subfilterBar:SetInventoryType(inventoryType)
                        subfilterGroups[inventoryType][tradeSkillType][itemFilterType] = subfilterBar
                    else
                        if doDebugOutput or debugSpam then d("[AF] ERROR - CreateSubfilterBars, missing names - inventoryName: " ..tos(inventoryNames[inventoryType]) .. ", tradeSkillName: " .. tos(tradeSkillNames[tradeSkillType]) .. ", filterTypeName: " .. tos(filterTypeNames[itemFilterType]) .. ", subfilterButtonName: " .. tos(subfilterButtonNames[itemFilterType])) end
                    end
                else
                    if doDebugOutput or debugSpam then d("[AF] ERROR - CreateSubfilterBars, missing data - inventoryType: " ..tos(inventoryType) .. ", tradeSkillType: " .. tos(tradeSkillType) .. ", itemFilterType: " .. tos(itemFilterType)) end
                end
            end
        end
    end
end