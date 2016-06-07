--[[----------------------------------------------------------------------------
    The anonymous function returned by this function handles the actual
		filtering.
	Use whatever parameters for "GetFilterCallback..." and whatever logic you
		need to in "function(slot)".
	"slot" is a table of item data. A typical slot can be found in
		PLAYER_INVENTORY.inventories[bagId].slots[slotIndex]
	A return value of true means the item in question will be shown while the
		filter is active. False means the item will be hidden while the filter
		is active.
--]]----------------------------------------------------------------------------
local function GetFilterCallbackForLevel(minLevel, maxLevel)
	return function(slot)
		local link = GetItemLink(slot.bagId, slot.slotIndex)
		local level = GetItemLinkRequiredLevel(link)
		local vetLevel = GetItemLinkRequiredVeteranRank(link)

		if vetLevel > 0 then
			level = level + vetLevel
		end
		return false or ((level >= minLevel) and (level <= maxLevel))
	end
end

--[[----------------------------------------------------------------------------
    This table is processed within Advanced Filters and its contents are added
		to Advanced Filters'  master callback table.
	The string value for name is the relevant key for the language table.
--]]----------------------------------------------------------------------------
local fullLevelDropdownCallbacks = {
	[1] = {name = "1-10", filterCallback = GetFilterCallbackForLevel(1, 10)},
	[2] = {name = "11-20", filterCallback = GetFilterCallbackForLevel(11, 20)},
	[3] = {name = "21-30", filterCallback = GetFilterCallbackForLevel(21, 30)},
	[4] = {name = "31-40", filterCallback = GetFilterCallbackForLevel(31, 40)},
	[5] = {name = "41-50", filterCallback = GetFilterCallbackForLevel(41, 50)},
	[6] = {name = "V1-V2", filterCallback = GetFilterCallbackForLevel(51, 52)},
	[7] = {name = "V3-V4", filterCallback = GetFilterCallbackForLevel(53, 54)},
	[8] = {name = "V5-V6", filterCallback = GetFilterCallbackForLevel(55, 56)},
	[9] = {name = "V7-V8", filterCallback = GetFilterCallbackForLevel(57, 58)},
	[10] = {name = "V9-V10", filterCallback = GetFilterCallbackForLevel(59, 60)},
	[11] = {name = "V11-V12", filterCallback = GetFilterCallbackForLevel(61, 62)},
	[12] = {name = "V13-V14", filterCallback = GetFilterCallbackForLevel(63, 64)},
	[13] = {name = "V15-V16", filterCallback = GetFilterCallbackForLevel(65, 66)},
}

--[[----------------------------------------------------------------------------
    There are five potential tables for this section each covering either
		English, German, French, Russian, or Spanish. Only English is required.
	If other language tables are not included, the English table will
		automatically be used for those languages.
	All languages must share common keys.
--]]----------------------------------------------------------------------------
local strings = {
	["LevelFilters"] = "Level Filters",
	["1-10"] = "1-10",
	["11-20"] = "11-20",
	["21-30"] = "21-30",
	["31-40"] = "31-40",
	["41-50"] = "41-50",
	["V1-V2"] = "V1-V2",
	["V3-V4"] = "V3-V4",
	["V5-V6"] = "V5-V6",
	["V7-V8"] = "V7-V8",
	["V9-V10"] = "V9-V10",
	["V11-V12"] = "V11-V12",
	["V13-V14"] = "V13-V14",
	["V15-V16"] = "V15-V16",
}

--[[----------------------------------------------------------------------------
    This section packages the data for Advanced Filters to use.
    All keys are required except for deStrings, frStrings, ruStrings, and
	    esStrings as they correspond to optional languages. All language keys
		are assigned the same table here only to demonstrate the key names. You
		do not need to do this.
    The filterType key expects an ITEMFILTERTYPE constant provided by the game.
	The values for key/value pairs in the "subfilters" table can be any of the
		string keys from the "masterSubfilterData" table in data.lua such as
		"All", "OneHanded", "Body", or "Blacksmithing".
    If your filterType is ITEMFILTERTYPE_ALL then the "subfilters" table must
		only contain the value "All".
	If the field "submenuName" is defined, your filters will be placed into a
		submenu in the dropdown list rather then in the root dropdown list
		itself. "submenuName" takes a string which matches a key in your strings
		table(s).
--]]----------------------------------------------------------------------------
local filterInformation = {
	submenuName = "LevelFilters",
	callbackTable = fullLevelDropdownCallbacks,
	filterType = ITEMFILTERTYPE_WEAPONS,
	subfilters = {
		[1] = "All",
	},
	enStrings = strings,
	deStrings = strings,
	frStrings = strings,
	ruStrings = strings,
	esStrings = strings,
}

--[[----------------------------------------------------------------------------
    Register your filters by passing your filter information to this function.
--]]----------------------------------------------------------------------------
if INVENTORY_CRAFT_BAG == nil then
	AdvancedFilters_RegisterFilter(filterInformation)
end

--[[----------------------------------------------------------------------------
	If you want your filters to show up under more than one main filter,
		redefine filterInformation to use the new filterType.
	The shorthand version (not including optional languages) is shown here.
--]]----------------------------------------------------------------------------
filterInformation = {
	submenuName = "LevelFilters",
	callbackTable = fullLevelDropdownCallbacks,
	filterType = ITEMFILTERTYPE_ARMOR,
	subfilters = {
		[1] = "All",
	},
	enStrings = strings,
}

--[[----------------------------------------------------------------------------
	Again, register your filters by passing your new filter information to this
		function.
--]]----------------------------------------------------------------------------
if INVENTORY_CRAFT_BAG == nil then
	AdvancedFilters_RegisterFilter(filterInformation)
end

--[[----------------------------------------------------------------------------
	If you only need to redefine some fields for the next registration, you can
	    do that as well.
--]]----------------------------------------------------------------------------
filterInformation.filterType = ITEMFILTERTYPE_CONSUMABLE
filterInformation.subfilters = {
	[1] = "Food",
	[2] = "Drink",
	[3] = "Potion",
	[4] = "Poison",
}

if INVENTORY_CRAFT_BAG == nil then
	AdvancedFilters_RegisterFilter(filterInformation)
end