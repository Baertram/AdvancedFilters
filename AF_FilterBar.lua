AdvancedFilters = AdvancedFilters or {}
local AF = AdvancedFilters

local util = AF.util
local BuildDropdownCallbacks = AF.util.BuildDropdownCallbacks
local showChatDebug = AF.showChatDebug

--Subfilter bar class
AF.AF_FilterBar = ZO_Object:Subclass()
local AF_FilterBar = AF.AF_FilterBar

function AF_FilterBar:New(inventoryName, tradeSkillname, groupName, subfilterNames, excludeTheseButtons)
    local obj = ZO_Object.New(self)
    obj:Initialize(inventoryName, tradeSkillname, groupName, subfilterNames, excludeTheseButtons)
    return obj
end

function AF_FilterBar:Initialize(inventoryName, tradeSkillname, groupName, subfilterNames, excludeTheseButtons)
    if AF.settings.debugSpam then d("=============================================\n[AF]AF_FilterBarInitialize - inventoryName: " .. tostring(inventoryName) .. ", tradeSkillname: " .. tostring(tradeSkillname) .. ", groupName: " ..tostring(groupName) .. ", subfilterNames: " .. tostring(subfilterNames)) end
    --get upper anchor position for subfilter bar
    local _,_,_,_,_,offsetY = ZO_PlayerInventorySortBy:GetAnchor()

    --parent for the subfilter bar control
    local parents = AF.filterBarParents
    local parent = parents[inventoryName]
    if parent == nil then
        d("[AdvancedFilters] ERROR: Parent for subfilterbar missing! InventoryName: " .. tostring(inventoryName) .. ", tradeSkillname: " .. tostring(tradeSkillname) .. ", groupName: " ..tostring(groupName) .. ", subfilterNames: " .. tostring(subfilterNames))
--[[
    else
        if parent.GetName then
            d(">parent name: " ..tostring(parent:GetName()))
        end
]]
    end

    --unique identifier
    self.name = inventoryName .. tradeSkillname .. groupName
    self.control = WINDOW_MANAGER:CreateControlFromVirtual("AF_FilterBar" .. self.name, parent, "AF_Base")
    self.control:SetAnchor(TOPLEFT, parent, TOPLEFT, 0, offsetY)

    self.label = self.control:GetNamedChild("Label")
    self.label:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
	local allText = AF_CONST_ALL
    if AF.strings and AF.strings[AF_CONST_ALL] then
        allText = AF.strings[AF_CONST_ALL]
    else
        showChatDebug("AF_FilterBar:Initialize", "AF.strings missing for: " ..tostring(AF_CONST_ALL) .. ", language: " .. tostring(AF.clientLang) .. ", inventoryName: " .. tostring(inventoryName) .. ", tradeSkillname: " ..tostring(tradeSkillname) .. ",groupName: " ..tostring(groupName))
    end
    self.label:SetText(allText)

    self.divider = self.control:GetNamedChild("Divider")

    self.subfilterButtons = {}
    self.activeButton = nil

    self.dropdown = WINDOW_MANAGER:CreateControlFromVirtual("AF_FilterBar" .. self.name .. "DropdownFilter", self.control, "ZO_ComboBox")
    self.dropdown:SetAnchor(RIGHT, self.control, RIGHT)
    self.dropdown:SetHeight(24)
    self.dropdown:SetWidth(104)
    --Function for the Mouse right click on the dropdown box (filter plugins) of the subfilterBar
    local function DropdownOnMouseUpHandler(dropdown, mouseButton, upInside)
        local comboBox = dropdown.m_comboBox
        if not upInside then return end
        --Left mouse button
        if mouseButton == MOUSE_BUTTON_INDEX_LEFT then
            if comboBox.m_isDropdownVisible then
                comboBox:HideDropdownInternal()
            else
                comboBox:ShowDropdownInternal()
            end
        --Right mouse button
        elseif mouseButton == MOUSE_BUTTON_INDEX_RIGHT then
            --Get the current LibFilters filterPanelId
            local filterPanelIdActive = util.GetCurrentFilterTypeForInventory(AF.currentInventoryType)
--d("[AF]filterPanelIdActive at filter plugin dropdown right click: " ..tostring(filterPanelIdActive))
            --Add the currently active filtername to the dropdown "Invert" entry
            local button = self:GetCurrentButton()
            if not button then return end
            --if AF.settings.debugSpam then d("[AF]AF_FilterBar:Initialize - DropdownOnMouseUpHandler, 2: " .. tostring(button.name) .. ", filterPanelId: " ..tostring(filterPanelIdActive)) end
            local previousDropdownSelection = (button.previousDropdownSelection ~= nil and button.previousDropdownSelection[filterPanelIdActive]) or nil
            local currentActiveFilterName = previousDropdownSelection.name or ""
            local invertFilterText = string.format(AF.strings.InvertDropdownFilter, currentActiveFilterName)
            local entries = {
                [1] = {
                    name = AF.strings.ResetToAll,
                    callback = function()
                        --Reset the external filter plugin isFiltered variable. They will be set again as the filter plugin is used again or a dropdown value is reapllied via ActivateButton function
                        util.ResetExternalDropdownFilterPluginsIsFiltering()
                        comboBox:SelectFirstItem()
                        filterPanelIdActive = util.GetCurrentFilterTypeForInventory(AF.currentInventoryType)
                        button.previousDropdownSelection[filterPanelIdActive] = comboBox.m_sortedItems[1]

                        PlaySound(SOUNDS.MENU_BAR_CLICK)

                        local filterType = util.GetCurrentFilterTypeForInventory(self:GetInventoryType())
                        util.LibFilters:RequestUpdate(filterType)
                    end,
                },

                [2] = {
                    name = invertFilterText,
                    callback = function()
                        --Reset the external filter plugin isFiltered variable. They will be set again as the filter plugin is used again or a dropdown value is reapllied via ActivateButton function
                        util.ResetExternalDropdownFilterPluginsIsFiltering()
                        filterPanelIdActive = util.GetCurrentFilterTypeForInventory(AF.currentInventoryType)
                        local filterType = util.GetCurrentFilterTypeForInventory(self:GetInventoryType())
                        local lastSelectedItem = (button.previousDropdownSelection ~= nil and button.previousDropdownSelection[filterPanelIdActive]) or nil
                        local currentlySelectedDropdownItem = comboBox.m_selectedItemData
                        if not currentlySelectedDropdownItem then return end
                        local originalCallback = util.LibFilters:GetFilterCallback(AF_CONST_DROPDOWN_FILTER, filterType)
                        local filterCallback = function(slot, slotIndex)
                            return not originalCallback(slot, slotIndex)
                        end
                        --Build the now new selected item of the dropdown with the inverted data
                        local newSelectedItem = {}
                        newSelectedItem.filterResetAtStart = currentlySelectedDropdownItem.filterResetAtStart  -- For AF.util.ApplyFilter
                        newSelectedItem.filterResetAtStartDelay = currentlySelectedDropdownItem.filterResetAtStartDelay  -- For AF.util.ApplyFilter
                        --d("[AF]invertFilter at dropdown-filterResetAtStart: " ..tostring(newSelectedItem.filterResetAtStart) .. ", filterResetAtStartDelay: " ..tostring(currentlySelectedDropdownItem.filterResetAtStartDelay))

                        newSelectedItem.filterStartCallback = currentlySelectedDropdownItem.filterStartCallback -- For AF.util.ApplyFilter
                        newSelectedItem.callback = filterCallback
                        newSelectedItem.filterCallback = filterCallback -- For AF.util.ApplyFilter (as it needs filterCallback and not callback)
                        newSelectedItem.filterEndCallback = currentlySelectedDropdownItem.filterEndCallback -- For AF.util.ApplyFilter
                        --Remove all old <> (unequal) signs
                        currentlySelectedDropdownItem.name = string.gsub(currentlySelectedDropdownItem.name, "≠", "")
                        if lastSelectedItem and lastSelectedItem.isInverted then
                            newSelectedItem.isInverted = false
                            newSelectedItem.name = currentlySelectedDropdownItem.name
                        else
                            newSelectedItem.isInverted = true
                            newSelectedItem.name = "≠" .. currentlySelectedDropdownItem.name
                        end
                        button.previousDropdownSelection[filterPanelIdActive] = newSelectedItem
                        comboBox.m_selectedItemText:SetText(newSelectedItem.name)

                        PlaySound(SOUNDS.MENU_BAR_CLICK)

                        util.ApplyFilter(newSelectedItem, AF_CONST_DROPDOWN_FILTER, true, filterType)
                    end,
                },
            }
            ClearMenu()
            for _, entry in ipairs(entries) do
                AddCustomMenuItem(entry.name, entry.callback, MENU_ADD_OPTION_LABEL)
            end
            ShowMenu(dropdown)
        end
    end
    self.dropdown:SetHandler("OnMouseUp", DropdownOnMouseUpHandler)

    local comboBox = self.dropdown.m_comboBox

    local function DropdownOnMouseEnterHandler()
        local tooltipText = comboBox.m_selectedItemText:GetText()
        if tooltipText and string.len(tooltipText) > 12 then
            ZO_Tooltips_ShowTextTooltip(self.dropdown, LEFT, tooltipText)
        end
    end
    self.dropdown:SetHandler("OnMouseEnter", DropdownOnMouseEnterHandler)
    local function DropdownOnMouseExitHandler()
        ZO_Tooltips_HideTextTooltip()
    end
    self.dropdown:SetHandler("OnMouseExit", DropdownOnMouseExitHandler)

    comboBox:SetSortsItems(false)
    comboBox.AddMenuItems = function(comboBox)
        local button = self:GetCurrentButton()
        local self = comboBox

        for i = 1, #self.m_sortedItems do
            -- The variable item must be defined locally here, otherwise it won't work as an upvalue to the selection helper
            local item = self.m_sortedItems[i]

            local function OnSelect()
                ZO_ComboBox_Base_ItemSelectedClickHelper(self, item)
                --Get the current LibFilters filterPanelId
                local filterPanelIdActive = util.GetCurrentFilterTypeForInventory(AF.currentInventoryType)
                button.previousDropdownSelection = button.previousDropdownSelection or {}
                button.previousDropdownSelection[filterPanelIdActive] = item

                PlaySound(SOUNDS.MENU_BAR_CLICK)
            end

            AddCustomMenuItem(item.name, OnSelect, nil, self.m_font,
                    self.m_normalColor, self.m_highlightColor)
        end

        local submenuCandidates = self.submenuCandidates

        for _, submenuCandidate in ipairs(submenuCandidates) do
            local entries = {}
            for _, callbackEntry in ipairs(submenuCandidate.callbackTable) do
                local entry = {
                    label = AF.strings[callbackEntry.name],
                    callback = function()
                        util.ApplyFilter(callbackEntry, AF_CONST_DROPDOWN_FILTER, true)
                        button.forceNextDropdownRefresh = true
                        self.m_selectedItemText:SetText(AF.strings[callbackEntry.name])
                        self.m_selectedItemData = self:CreateItemEntry(AF.strings[callbackEntry.name],
                                function(comboBox, itemName, item, selectionChanged)
                                    util.ApplyFilter(callbackEntry,
                                            AF_CONST_DROPDOWN_FILTER,
                                            selectionChanged or button.forceNextDropdownRefresh)
                                end)
                        self.m_selectedItemData.filterResetAtStartDelay = callbackEntry.filterResetAtStartDelay
                        self.m_selectedItemData.filterResetAtStart      = callbackEntry.filterResetAtStart
                        self.m_selectedItemData.filterStartCallback     = callbackEntry.filterStartCallback
                        self.m_selectedItemData.filterEndCallback       = callbackEntry.filterEndCallback
                        --Get the current LibFilters filterPanelId
                        local filterPanelIdActive = util.GetCurrentFilterTypeForInventory(AF.currentInventoryType)
                        button.previousDropdownSelection = button.previousDropdownSelection or {}
                        button.previousDropdownSelection[filterPanelIdActive] = self.m_selectedItemData

                        PlaySound(SOUNDS.MENU_BAR_CLICK)

                        ClearMenu()
                    end,
                }
                table.insert(entries, entry)
            end
            AddCustomSubMenuItem(AF.strings[submenuCandidate.submenuName], entries, "ZoFontGameSmall")
        end
    end

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
            --elseif AF.settings.debugSpam then d(">>>Not adding button: " .. tostring(subfilterName) .. ", at inventory: " .. tostring(inventoryName) .. ", groupName: " .. tostring(groupName))
        end
    end
end

function AF_FilterBar:AddSubfilter(groupName, subfilterName)
    local iconPath = AF.textures[subfilterName]
    if iconPath == nil then
        d("[AdvancedFilters] ERROR - AddSubfilter: Texture for subfilter " .. tostring(subfilterName) .. " is missing! Please add textures." .. tostring(subfilterName) .. " to file textures.lua.")
        return
    end
    local icon = {
        up      = string.format(iconPath, "up"),
        down    = string.format(iconPath, "down"),
        over    = string.format(iconPath, "over"),
    }
    if AF.settings.debugSpam then d("[AF_FilterBar:AddSubfilter]groupName: " ..tostring(groupName) .. ", subfilterName: " ..tostring(subfilterName)) end
    if AF.subfilterCallbacks[groupName] == nil then
        d("[AdvancedFilters] ERROR - AddSubfilter: Subfilter callback \'data\' missing for group \'" ..tostring(groupName).."\'")
        return nil
    end
    if AF.subfilterCallbacks[groupName][subfilterName] == nil then
        --Check if the groupName's filterType got a replacement subfilterName and thus the data is missing
        --e.g. LightArmor, Heavy, Clothing, ... -> Body
        local filterType = util.MapGroupNameToFilterType(groupName)
        local showError = true
        if filterType then
            local replacementSubfilterName = util.MapMultipleGroupSubfiltersToCombinedSubfilter(filterType, subfilterName)
            if replacementSubfilterName and replacementSubfilterName ~= "" then showError = false end
        end
        if showError then
            d("[AdvancedFilters] ERROR - AddSubfilter: Subfilter callback \'data\' missing for group \'" ..tostring(groupName) .. "\', subFilter: \'" ..tostring(subfilterName).."\'")
        end
        return nil
    end
    local subfilterButtonData = AF.subfilterCallbacks[groupName][subfilterName]
    --Set the button's callback functions for start, start with delay, normal and end
    local callback = subfilterButtonData.filterCallback
    if callback == nil then
        d("[AdvancedFilters] ERROR - AddSubfilter: Subfilter callback \'function\' missing for group \'" ..tostring(groupName) .. "\', subFilter: \'" ..tostring(subfilterName).."\'")
        return nil
    end
    local filterResetAtStartDelay = subfilterButtonData.filterResetAtStartDelay
    local filterStartCallback = subfilterButtonData.filterStartCallback
    local filterEndCallback = subfilterButtonData.filterEndCallback

    local anchorX = -116 + #self.subfilterButtons * -32

    local button = WINDOW_MANAGER:CreateControlFromVirtual(self.control:GetName() .. subfilterName .. "Button", self.control, "AF_Button")
    local texture = button:GetNamedChild("Texture")
    local highlight = button:GetNamedChild("Highlight")

    texture:SetTexture(icon.up)
    highlight:SetTexture(icon.over)

    button:SetAnchor(RIGHT, self.control, RIGHT, anchorX, 0)
    button:SetClickSound(SOUNDS.MENU_BAR_CLICK)

    local function OnClicked(thisButton)
        if(not thisButton.clickable) then return end
        self:ActivateButton(thisButton)
    end

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

    button:SetHandler("OnClicked", OnClicked)
    button:SetHandler("OnMouseEnter", OnMouseEnter)
    button:SetHandler("OnMouseExit", OnMouseExit)

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

    table.insert(self.subfilterButtons, button)
end

function AF_FilterBar:ActivateButton(newButton)
    if not newButton then return end
    if AF.settings.debugSpam then
        d("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!>")
        d("[AF]ActivateButton: " ..tostring(newButton.name))
    end
    --------------------------------------------------------------------------------------------------------------------
    local function PopulateDropdown(p_newButton)
        local comboBox = self.dropdown.m_comboBox
        p_newButton.dropdownCallbacks = BuildDropdownCallbacks(p_newButton.groupName, p_newButton.name)

        comboBox.submenuCandidates = {}
        local textures = AF.textures
        local texturesReSize = AF.texturesReSize
        for _, v in ipairs(p_newButton.dropdownCallbacks) do
            if v.submenuName then
                table.insert(comboBox.submenuCandidates, v)
            else
                local dropdownEntryName = v.name
                if v.addString ~= nil and v.addString ~= "" then
                    dropdownEntryName = dropdownEntryName .. "_" .. v.addString
                end
                local iconForDropdownCallbackEntry = ""
                if AF.settings.showIconsInFilterDropdowns and v.showIcon ~= nil and v.showIcon == true then
                    local textureName = textures[v.name] or ""
                    if textureName ~= "" then
                        --Remove the placeholder %s
                        textureName = string.format(textureName, "up")
                        local width, height = 28, 28
                        if texturesReSize then
                            local textureReSizeData = texturesReSize[v.name]
                            if textureReSizeData and textureReSizeData.width and textureReSizeData.height then
                                width, height = textureReSizeData.width, textureReSizeData.height
                            end
                        end
                        iconForDropdownCallbackEntry = zo_iconFormat(textureName, width, height)
                    end
                end
                local itemEntryName = AF.strings[dropdownEntryName] or ""
                if itemEntryName == "" then
                    d("[AdvancedFilters] ERROR - Translation missing for dropdown filter entry: " .. tostring(dropdownEntryName))
                else
                    if AF.settings.showIconsInFilterDropdowns and iconForDropdownCallbackEntry ~= "" then
                        itemEntryName = iconForDropdownCallbackEntry .. " " .. itemEntryName
                    end
                    local itemEntry = ZO_ComboBox:CreateItemEntry(itemEntryName,
                            function(comboBox, itemName, item, selectionChanged)
                                util.ApplyFilter(v, AF_CONST_DROPDOWN_FILTER, selectionChanged or p_newButton.forceNextDropdownRefresh)
                            end)
                    itemEntry.filterResetAtStartDelay   = v.filterResetAtStartDelay
                    itemEntry.filterResetAtStart        = v.filterResetAtStart
                    itemEntry.filterStartCallback       = v.filterStartCallback
                    itemEntry.filterEndCallback         = v.filterEndCallback
                    comboBox:AddItem(itemEntry)
                end
            end
        end
        comboBox:SetSelectedItemFont("ZoFontGameSmall")
        comboBox:SetDropdownFont("ZoFontGameSmall")
    end
    --------------------------------------------------------------------------------------------------------------------
    local inventoryTypeOfFilterBar = self:GetInventoryType()

    --Should the subfilterBar be shown?
    if util.CheckIfNoSubfilterBarShouldBeShown(nil, inventoryTypeOfFilterBar) then
        if AF.settings.debugSpam then d(">[AF]ActivateButton - ABORT: CheckIfNoSubfilterBarShouldBeShown: true") end
        return
    end

    local name = newButton.name
    local nameText
    if AF.strings and AF.strings[name] then
        nameText = AF.strings[name]
    else
        showChatDebug("AF_FilterBar:ActivateButton", "AF.strings missing for name: " ..tostring(name) .. ", language: " .. tostring(AF.clientLang))
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
    util.ApplyFilter(newButton, AF_CONST_BUTTON_FILTER, true) --let the filterType be determined in the function AF.util.ApplyFilter

    --set new active button reference
    self.activeButton = newButton

    --clear old dropdown data
    self.dropdown.m_comboBox.m_sortedItems = {}
    --Get the current LibFilters filterPanelId
    if inventoryTypeOfFilterBar == nil then
        d("===============================================")
        d("[AdvancedFilters]AF_FilterBar:ActivateButton: " .. tostring(newButton.name))
        d(">ERROR - inventoryType is NIL!")
        d("===============================================")
    end
    --Get the current's inventory filterType
    local filterPanelIdActive = util.GetCurrentFilterTypeForInventory(inventoryTypeOfFilterBar)
    if filterPanelIdActive == nil then
        d("===============================================")
        d("[AdvancedFilters]AF_FilterBar:ActivateButton: " .. tostring(newButton.name))
        d(">ERROR - filterPanelId is NIL!")
        d("===============================================")
    end
    --add new dropdown data
    PopulateDropdown(newButton)
    --re-select the previous selected/first entry of the dropdown box
    if inventoryTypeOfFilterBar and filterPanelIdActive then
        self:ApplyDropdownSelection(newButton)
    end
end

function AF_FilterBar:ApplyDropdownSelection(newButton)
    newButton = newButton or self:GetCurrentButton()
    if newButton == nil then return end
    local inventoryTypeOfFilterBar = self:GetInventoryType()
    if inventoryTypeOfFilterBar == nil then return end
    local filterPanelIdActive = util.GetCurrentFilterTypeForInventory(inventoryTypeOfFilterBar)
    if filterPanelIdActive == nil then return end
    --Reset the external filter plugin isFiltered variable. They will be set again as the filter plugin is used again or a dropdown value is reapllied via ActivateButton function
    util.ResetExternalDropdownFilterPluginsIsFiltering()
    --select the first item if there is no previous selection or the setting to remember the last selection is disabled
    if not AF.settings.rememberFilterDropdownsLastSelection or not newButton.previousDropdownSelection or not newButton.previousDropdownSelection[filterPanelIdActive] then
        --Select the first entry
        self.dropdown.m_comboBox:SelectFirstItem()
        --util.LibFilters:UnregisterFilter(AF_CONST_DROPDOWN_FILTER, filterType)
        --util.LibFilters:RegisterFilter(AF_CONST_DROPDOWN_FILTER, filterType, filterCallback)
        --util.LibFilters:RequestUpdate(filterType)
        newButton.previousDropdownSelection = newButton.previousDropdownSelection or {}
        newButton.previousDropdownSelection[filterPanelIdActive] = self.dropdown.m_comboBox.m_sortedItems[1]
    else
        --restore previous dropdown selection if the settings is enabled for this
        local previousDropdownSelection = newButton.previousDropdownSelection[filterPanelIdActive]
        --Check if the previous selection was a right mouse context menu "invert" option
        if previousDropdownSelection.isInverted then
            --Reapply the filter of the inversion
            --local originalCallback = util.LibFilters:GetFilterCallback(AF_CONST_DROPDOWN_FILTER, filterType)
            local originalCallback = previousDropdownSelection.callback
            previousDropdownSelection.filterCallback = originalCallback
            util.ApplyFilter(previousDropdownSelection, AF_CONST_DROPDOWN_FILTER, true, filterPanelIdActive)
            --Select the dropdown entry but do not call the callback function as the filter was updated above already
            self.dropdown.m_comboBox:SelectItem(previousDropdownSelection, true)
        else
            if previousDropdownSelection.filterCallback ~= nil then
                util.ApplyFilter(previousDropdownSelection, AF_CONST_DROPDOWN_FILTER, true, filterPanelIdActive)
            end
            self.dropdown.m_comboBox:SelectItem(previousDropdownSelection, false)
        end
    end
end

function AF_FilterBar:GetCurrentButton()
    return self.activeButton
end

function AF_FilterBar:SetHidden(shouldHide)
    self.control:SetHidden(shouldHide)
end

function AF_FilterBar:SetInventoryType(inventoryType)
    self.inventoryType = inventoryType
end

function AF_FilterBar:GetInventoryType()
    return self.inventoryType
end

------------------------------------------------------------------------------------------------------------------------
--Create the subfilter bars below the inventory's filters (e.g. the weapons filters from the game will get a subfilter bar with 1hd, 2hd, staffs, shields)
function AF.CreateSubfilterBars()
    --local variables for a speedUp on access on addon's global table variables
    local doDebugOutput         = AF.settings.doDebugOutput
    local inventoryNames        = AF.inventoryNames
    local tradeSkillNames       = AF.tradeSkillNames
    local filterTypeNames       = AF.filterTypeNames
    local subfilterGroups       = AF.subfilterGroups
    local subfilterButtonNames  = AF.subfilterButtonNames
    local excludeButtonNamesfromSubFilterBar
    --Build each subfilterBar for the parent game filter controls
    for inventoryType, tradeSkillTypeSubFilterGroup in pairs(subfilterGroups) do
        for tradeSkillType, subfilterGroup in pairs(tradeSkillTypeSubFilterGroup) do
            for itemFilterType, _ in pairs(subfilterGroup) do
                if inventoryType and tradeSkillType and itemFilterType then
                    --Exclusion check
                    local excludeTheseButtonsAtThisFilterBar
                    if excludeButtonNamesfromSubFilterBar and excludeButtonNamesfromSubFilterBar[inventoryType] and excludeButtonNamesfromSubFilterBar[inventoryType][tradeSkillType] and excludeButtonNamesfromSubFilterBar[inventoryType][tradeSkillType][itemFilterType] then
                        excludeTheseButtonsAtThisFilterBar = excludeButtonNamesfromSubFilterBar[inventoryType][tradeSkillType][itemFilterType]
                    end
                    if inventoryNames[inventoryType] and tradeSkillNames[tradeSkillType] and filterTypeNames[itemFilterType] and subfilterButtonNames[itemFilterType] then
                        --Build the subfilterBar with the buttons now
                        local subfilterBar = AF.AF_FilterBar:New(
                                inventoryNames[inventoryType],
                                tradeSkillNames[tradeSkillType],
                                filterTypeNames[itemFilterType],
                                subfilterButtonNames[itemFilterType],
                                excludeTheseButtonsAtThisFilterBar                     --subFilterButtons which should not be shown
                        )
                        subfilterBar:SetInventoryType(inventoryType)
                        subfilterGroups[inventoryType][tradeSkillType][itemFilterType] = subfilterBar
                    else
                        if doDebugOutput or AF.settings.debugSpam then d("[AF] ERROR - CreateSubfilterBars, missing names - inventoryName: " ..tostring(inventoryNames[inventoryType]) .. ", tradeSkillName: " .. tostring(tradeSkillNames[tradeSkillType]) .. ", filterTypeName: " .. tostring(filterTypeNames[itemFilterType]) .. ", subfilterButtonName: " .. tostring(subfilterButtonNames[itemFilterType])) end
                    end
                else
                    if doDebugOutput or AF.settings.debugSpam then d("[AF] ERROR - CreateSubfilterBars, missing data - inventoryType: " ..tostring(inventoryType) .. ", tradeSkillType: " .. tostring(tradeSkillType) .. ", itemFilterType: " .. tostring(itemFilterType)) end
                end
            end
        end
    end
end