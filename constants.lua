AdvancedFilters = AdvancedFilters or {}
local AF = AdvancedFilters

--Addon base variables
AF.name = "AdvancedFilters"
AF.author = "ingeniousclown, Randactyl, Baertram (current)"
AF.version = "1.6.0.0"
AF.savedVarsVersion = 1.511
AF.website = "http://www.esoui.com/downloads/info245-AdvancedFilters.html"
AF.feedback = "https://www.esoui.com/portal.php?id=136&a=faq"
AF.donation = "https://www.esoui.com/portal.php?id=136&a=faq&faqid=131"
AF.currentInventoryType = INVENTORY_BACKPACK
AF.currentlySelectedDropDownEntry = nil

AF.clientLang = GetCVar("language.2")

--SavedVariables default settings
AF.defaultSettings = {
    debugSpam                               = false, --Only for addon dev!
    doDebugOutput                           = false,
    hideItemCount                           = false,
    itemCountLabelColor = {
        ["r"] = 1,
        ["g"] = 1,
        ["b"] = 1,
        ["a"] = 1,
    },
    hideSubFilterLabel                      = false,
    grayOutSubFiltersWithNoItems            = true,
    showIconsInFilterDropdowns              = true,
    rememberFilterDropdownsLastSelection    = true,
    showDropdownSelectedReminderAnimation   = true,
    showDropdownLastSelectedEntries         = true,
    subfilterBarDropdownLastSelectedEntries = {},
}

--Libraries
AF.util = AF.util or {}
local util = AF.util

--Libraries: See file libraries.lua

--Constant for the "All" subfilters
AF_CONST_ALL                = 'All'
--Prefixes for filterGroups
--Quickslot
AF_QS_PREFIX                =   'QS'
--Constant for the dropdown filter box LibFilters filter
AF_CONST_BUTTON_FILTER      = "AF_ButtonFilter"
AF_CONST_DROPDOWN_FILTER    = "AF_DropdownFilter"

--Last known currentFilter
AF.lastCurrentFilter = {}

--Other addons
AF.otherAddons = {}

--Preventer veriables
AF.preventerVars = {}

--SCENE CHECKS
--Scene names for the SCENE_MANAGER.currentScene.name check
local scenesForChecks = {
    storeVendor     = "store",
    bank            = "bank",
    guildBank       = "guildBank",
    guildStoreSell  = "tradinghouse",
    fence           = "fence_keyboard"
}
AF.scenesForChecks = scenesForChecks
local sceneNameStoreVendor      = ""
local sceneNameBankDeposit      = ""
local sceneNameGuildBankDeposit = ""

--FRAGMENT changes
--The fragment's state is "hiding"= -> For the subfilter bars
AF.fragmentStateHiding = {}

--CONTROLS
--Bank inventory types
local bankInvTypes = {
    [INVENTORY_BANK]        = true,
    [INVENTORY_GUILD_BANK]  = true,
    [INVENTORY_HOUSE_BANK]  = true,
}
AF.bankInvTypes = bankInvTypes

--Include bank checkbox name
AF.ZOsControlNames = {
    includeBankedCheckbox   =   "IncludeBanked",
    filterDivider           =   "FilterDivider",
    buttonDivider           =   "ButtonDivider",
    searchDivider           =   "SearchDivider",
    searchFilters           =   "SearchFilters",
    textSearch              =   "TextSearch",
    title                   =   "Title",
    tabs                    =   "Tabs",
    subTabs                 =   "SubTabs",
    active                  =   "Active",
    questItemsOnly          =   "QuestItemsOnly",
}
local ZOsControlNames = AF.ZOsControlNames
local filterDividerSuffix = ZOsControlNames.filterDivider
local buttonDividerSuffix = ZOsControlNames.buttonDivider
local searchDividerSuffix = ZOsControlNames.searchDivider
local questItemsOnly      = ZOsControlNames.questItemsOnly

--Control names for the "which panel is shown" checks
local controlsForChecks = {
    playerInv               = PLAYER_INVENTORY,
    inv                     = ZO_PlayerInventory,
    invList                 = ZO_PlayerInventoryList,
    bank                    = ZO_PlayerBank,
    bankBackpack            = ZO_PlayerBankBackpack,
    guildBank               = ZO_GuildBank,
    guildBankBackpack       = ZO_GuildBankBackpack,
    storeWindow             = ZO_StoreWindow,
    buyBackList             = ZO_BuyBackListContents,
    repairWindow            = ZO_RepairWindowList,
    craftBag                = ZO_CraftBag,
    houseBank               = ZO_HouseBank,
    guildStoreSellBackpack  = ZO_PlayerInventory,
    quickslot               = QUICKSLOT_WINDOW,
    --Keyboard variables
    store                   = STORE_WINDOW,
    smithingBaseVar         = ZO_Smithing,
    smithing                = SMITHING,
    enchantingBaseVar       = ZO_Enchanting,
    enchanting              = ENCHANTING,
    retrait                 = ZO_RETRAIT_KEYBOARD, --ZO_RETRAIT_STATION_KEYBOARD -- needed for the other retrait related filter stuff (hooks, util functions)
    fence                   = FENCE_KEYBOARD,
}
--Smithing
controlsForChecks.refinementPanel       =   controlsForChecks.smithing.refinementPanel
controlsForChecks.creationPanel         =   controlsForChecks.smithing.creationPanel
controlsForChecks.deconstructionPanel   =   controlsForChecks.smithing.deconstructionPanel
controlsForChecks.improvementPanel      =   controlsForChecks.smithing.improvementPanel
controlsForChecks.researchPanel         =   controlsForChecks.smithing.researchPanel
controlsForChecks.researchLineList      =   controlsForChecks.researchPanel.researchLineList
--Enchanting
controlsForChecks.enchantCreatePanel    =   controlsForChecks.enchanting
controlsForChecks.enchantExtractPanel   =   controlsForChecks.enchanting
--Retrait
controlsForChecks.retraitPanel          =   controlsForChecks.retrait --old: controlsForChecks.retrait.retraitPanel
controlsForChecks.retraitControl        =   controlsForChecks.retraitPanel.control

AF.controlsForChecks = controlsForChecks

--INVENTORIES
--Inventories and their searchBox controls
local inventories = {
    [INVENTORY_BACKPACK]   = {
        searchBox = ZO_PlayerInventorySearchFiltersTextSearchBox,
    },
    [INVENTORY_QUEST_ITEM] = {
        searchBox = ZO_PlayerInventorySearchFiltersTextSearchBox,
    },
    [INVENTORY_BANK]       = {
        searchBox = ZO_PlayerBankSearchFiltersTextSearchBox,
    },
    [INVENTORY_HOUSE_BANK] = {
        searchBox = ZO_HouseBankSearchFiltersTextSearchBox,
    },
    [INVENTORY_GUILD_BANK] = {
        searchBox = ZO_GuildBankSearchFiltersTextSearchBox,
    },
    [INVENTORY_CRAFT_BAG]  = {
        searchBox = ZO_CraftBagSearchFiltersTextSearchBox,
    },
    [LF_QUICKSLOT] = {
        searchBox = ZO_QuickSlotSearchFiltersTextSearchBox,
    },
}
AF.inventories = inventories
--New defined vendor buy inventory type (only known by AdvancedFilters)
INVENTORY_TYPE_VENDOR_BUY = 900

--ITEMFILTERTYPES
--Get the current maximum itemFilterType
AF.maxItemFilterType = ITEMFILTERTYPE_MAX_VALUE -- 26 is the maximum at API 100028 "Scalebreaker"
--Build new "virtual" itemfiltertypes for crafting stations so one can distinguish the different subfilter bars
local itemFilterTypesDefinedForAdvancedFilters = {
    --Refine
    ITEMFILTERTYPE_AF_REFINE_CLOTHIER               = 0,
    ITEMFILTERTYPE_AF_REFINE_SMITHING               = 0,
    ITEMFILTERTYPE_AF_REFINE_WOODWORKING            = 0,
    ITEMFILTERTYPE_AF_REFINE_JEWELRY                = 0,
    --Create
    --ITEMFILTERTYPE_AF_CREATE_ARMOR_CLOTHIER         = 0,
    --ITEMFILTERTYPE_AF_CREATE_ARMOR_SMITHING         = 0,
    --ITEMFILTERTYPE_AF_CREATE_ARMOR_WOODWORKING      = 0,
    --ITEMFILTERTYPE_AF_CREATE_WEAPONS_SMITHING       = 0,
    --ITEMFILTERTYPE_AF_CREATE_WEAPONS_WOODWORKING    = 0,
    --ITEMFILTERTYPE_AF_CREATE_JEWELRY                = 0,
    ITEMFILTERTYPE_AF_RUNES_ENCHANTING              = 0,
    --Deconstruct / Improve / Research
    ITEMFILTERTYPE_AF_ARMOR_CLOTHIER                = 0,
    ITEMFILTERTYPE_AF_ARMOR_SMITHING                = 0,
    ITEMFILTERTYPE_AF_ARMOR_WOODWORKING             = 0,
    ITEMFILTERTYPE_AF_WEAPONS_SMITHING              = 0,
    ITEMFILTERTYPE_AF_WEAPONS_WOODWORKING           = 0,
    ITEMFILTERTYPE_AF_JEWELRY_CRAFTING              = 0,
    ITEMFILTERTYPE_AF_GLYPHS_ENCHANTING             = 0,
    --Retrait
    ITEMFILTERTYPE_AF_RETRAIT_ARMOR                 = 0,
    ITEMFILTERTYPE_AF_RETRAIT_WEAPONS               = 0,
    ITEMFILTERTYPE_AF_RETRAIT_JEWELRY               = 0,
}
local counter = AF.maxItemFilterType
for itemFilterTypeName, _ in pairs(itemFilterTypesDefinedForAdvancedFilters) do
    counter = counter + 1
    _G[itemFilterTypeName] = counter
end
--Update the maximum filterType number
AF.maxItemFilterType = counter

--Other addons itemFilterTypes
counter = AF.maxItemFilterType
counter = counter + 1
--Harven's Stolen Filter
ITEMFILTERTYPE_AF_STOLENFILTER = counter
AF.maxItemFilterType = counter

--NAME STRINGS (for the LibFilters filterTags)
--The names of the inventories. Needed to build the unique subfilter panel names.
local inventoryNames = {
    [INVENTORY_BACKPACK]        = "PlayerInventory",
    [INVENTORY_QUEST_ITEM]      = "PlayerInventoryQuest",
    [INVENTORY_BANK]            = "PlayerBank",
    [INVENTORY_GUILD_BANK]      = "GuildBank",
    [INVENTORY_CRAFT_BAG]       = "CraftBag",
    [INVENTORY_TYPE_VENDOR_BUY] = "VendorBuy",
    [LF_SMITHING_CREATION]      = "SmithingCreate",
    [LF_SMITHING_REFINE]        = "SmithingRefine",
    [LF_SMITHING_DECONSTRUCT]   = "SmithingDeconstruction",
    [LF_SMITHING_IMPROVEMENT]   = "SmithingImprovement",
    [LF_SMITHING_RESEARCH]      = "SmithingResearch",
    [LF_JEWELRY_CREATION]       = "JewelryCraftingCreate",
    [LF_JEWELRY_REFINE]         = "JewelryCraftingRefine",
    [LF_JEWELRY_DECONSTRUCT]    = "JewelryCraftingDeconstruction",
    [LF_JEWELRY_IMPROVEMENT]    = "JewelryCraftingImprovement",
    [LF_JEWELRY_RESEARCH]       = "JewelryCraftingResearch",
    [LF_ENCHANTING_CREATION]    = "EnchantingCreation",
    [LF_ENCHANTING_EXTRACTION]  = "EnchantingExtraction",
    [INVENTORY_HOUSE_BANK]      = "HouseBankWithdraw",
    [LF_RETRAIT]                = "Retrait",
    [LF_QUICKSLOT]              = "QuickSlot",
}
AF.inventoryNames = inventoryNames

--The names of the trade skills. Needed to build the unique subfilter panel names.
local tradeSkillNames = {
    [CRAFTING_TYPE_INVALID]         = "_",
    [CRAFTING_TYPE_ALCHEMY]         = "_ALCHEMY_",
    [CRAFTING_TYPE_BLACKSMITHING]   = "_BLACKSMITH_",
    [CRAFTING_TYPE_CLOTHIER]        = "_CLOTHIER_",
    [CRAFTING_TYPE_ENCHANTING]      = "_ENCHANTING_",
    [CRAFTING_TYPE_PROVISIONING]    = "_PROVISIONING_",
    [CRAFTING_TYPE_WOODWORKING]     = "_WOODWORKING_",
    [CRAFTING_TYPE_JEWELRYCRAFTING] = "_JEWELRY_",
}
AF.tradeSkillNames = tradeSkillNames

--FILTERTYPE NAMES
--The names of the filter types. Needed to build the unique subfilter panel names.
local filterTypeNames = {
    [ITEM_TYPE_DISPLAY_CATEGORY_ALL]                = AF_CONST_ALL,
    [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS]            = "Weapons",
    [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR]              = "Armor",
    [ITEMFILTERTYPE_COLLECTIBLE]                    = "Collectibles",
    [ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE]         = "Consumables",
    [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING]           = "Crafting",
    [ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS]      = "Miscellaneous",
    [ITEM_TYPE_DISPLAY_CATEGORY_QUEST]              = "Quest",
    [ITEM_TYPE_DISPLAY_CATEGORY_JUNK]               = "Junk",
    [ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING]      = "Blacksmithing",
    [ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING]           = "Clothing",
    [ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING]        = "Woodworking",
    [ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY]            = "Alchemy",
    [ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING]         = "Enchanting",
    [ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING]       = "Provisioning",
    [ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL]     = "Style",
    [ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM]         = "Traits",
    [ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING]         = "Furnishings",
    [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING]    = "JewelryCrafting",
    [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY]            = "Jewelry",
    [ITEMFILTERTYPE_AF_WEAPONS_SMITHING]            = "WeaponsSmithing",
    --[ITEMFILTERTYPE_AF_CREATE_ARMOR_SMITHING]       = "CreateArmorSmithing",
    [ITEMFILTERTYPE_AF_REFINE_SMITHING]             = "RefineSmithing",
    [ITEMFILTERTYPE_AF_ARMOR_WOODWORKING]           = "ArmorWoodworking",
    --[ITEMFILTERTYPE_AF_CREATE_WEAPONS_SMITHING]     = "CreateWeaponsSmithing",
    [ITEMFILTERTYPE_AF_GLYPHS_ENCHANTING]           = "Glyphs",
    [ITEMFILTERTYPE_AF_REFINE_WOODWORKING]          = "RefineWoodworking",
    --[ITEMFILTERTYPE_AF_CREATE_ARMOR_CLOTHIER]       = "CreateArmorClothier",
    [ITEMFILTERTYPE_AF_REFINE_CLOTHIER]             = "RefineClothier",
    [ITEMFILTERTYPE_AF_JEWELRY_CRAFTING]            = "JewelryCraftingStation",
    [ITEMFILTERTYPE_AF_RUNES_ENCHANTING]            = "Runes",
    [ITEMFILTERTYPE_AF_ARMOR_SMITHING]              = "ArmorSmithing",
    [ITEMFILTERTYPE_AF_WEAPONS_WOODWORKING]         = "WeaponsWoodworking",
    --[ITEMFILTERTYPE_AF_CREATE_WEAPONS_WOODWORKING]  = "CreateWeaponsWoodworking",
    --[ITEMFILTERTYPE_AF_CREATE_ARMOR_WOODWORKING]    = "CreateArmorWoodworking",
    [ITEMFILTERTYPE_AF_ARMOR_CLOTHIER]              = "ArmorClothier",
    --[ITEMFILTERTYPE_AF_CREATE_JEWELRY]              = "CreateJewelryCraftingStation",
    [ITEMFILTERTYPE_AF_REFINE_JEWELRY]              = "RefineJewelryCraftingStation",
    [ITEMFILTERTYPE_AF_RETRAIT_ARMOR]               = "ArmorRetrait",
    [ITEMFILTERTYPE_AF_RETRAIT_WEAPONS]             = "WeaponsRetrait",
    [ITEMFILTERTYPE_AF_RETRAIT_JEWELRY]             = "JewelryRetrait",
    [AF_QS_PREFIX..ITEMFILTERTYPE_QUICKSLOT]        = "QuickSlot",
    [AF_QS_PREFIX..ITEMFILTERTYPE_QUEST_QUICKSLOT]  = "QuickSlotQuest",
    --CUSTOM ADDON TABs
    --[[
    [ITEMFILTERTYPE_AF_STOLENFILTER]         = "HarvensStolenFilter",
    ]]
}
AF.filterTypeNames = filterTypeNames
--Mapping for filter types to crafting AdvancedFilter types
local normalFilterNames = {
    [filterTypeNames[ITEM_TYPE_DISPLAY_CATEGORY_ARMOR]]   = true, -- Armor
    [filterTypeNames[ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS]] = true, -- Weapons
    [filterTypeNames[ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY]] = true, -- Jewelry
}
AF.normalFilterNames = normalFilterNames
local normalFilter2CraftingFilter = {
    [filterTypeNames[ITEM_TYPE_DISPLAY_CATEGORY_ARMOR]] = {
        [filterTypeNames[ITEMFILTERTYPE_AF_ARMOR_WOODWORKING]]    = true, --ArmorWoodworking
        [filterTypeNames[ITEMFILTERTYPE_AF_ARMOR_SMITHING]]       = true, --ArmorSmithing
        [filterTypeNames[ITEMFILTERTYPE_AF_ARMOR_CLOTHIER]]       = true, --ArmorClothier
        [filterTypeNames[ITEMFILTERTYPE_AF_RETRAIT_ARMOR]]        = true, --ArmorRetrait
    },
    [filterTypeNames[ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS]] = {
        [filterTypeNames[ITEMFILTERTYPE_AF_WEAPONS_WOODWORKING]]  = true, --WeaponsWoodworking
        [filterTypeNames[ITEMFILTERTYPE_AF_WEAPONS_SMITHING]]     = true, --WeaponsSmithing
        [filterTypeNames[ITEMFILTERTYPE_AF_RETRAIT_WEAPONS]]      = true, --WeaponsRetrait
    },
    [filterTypeNames[ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY]] = {
        [filterTypeNames[ITEMFILTERTYPE_AF_JEWELRY_CRAFTING]]     = true, --JewelryCraftingStation
        [filterTypeNames[ITEMFILTERTYPE_AF_RETRAIT_JEWELRY]]      = true, --JewelryRetrait
    },
}
AF.normalFilter2CraftingFilter = normalFilter2CraftingFilter

--SUBFILTER BARS
--The list controls for the reanchoring of subfilter bars
local reanchorDataSmithingResearch = {
    --The timer icon at the top left edge at the SMITHING reasearch panel
    {
        --The researching text at the top left edge at the SMITHING reasearch panel
        control         = ZO_SmithingTopLevelResearchPanelNumResearching,
        anchorPoint     = TOPLEFT,
        relativeTo      = ZO_SmithingTopLevelResearchPanel,
        relativePoint   = TOPLEFT,
        offsetX         = 68,
        offsetY         = 8, --18 original
    },
}
local researchListControlForSubfilterBarReanchor = {
        listData = {
            control         = controlsForChecks.researchPanel.researchLineList.control,
            --parent          =,
            anchorPoint     = TOP,
            --relativeTo      =,
            relativePoint   = BOTTOM,
            offsetX         = 0,
            offsetY         = 5,
        },
        moveInvBottomBarDown    = ZO_SmithingTopLevelResearchPanelInfoBar, --For addon "PerfectPixel"
        reanchorData            = reanchorDataSmithingResearch,
    }
local listControlForSubfilterBarReanchor = {
    --[[
    [LF_INVENTORY]          = {
        listData = {
            control                 = controlsForChecks.inv,
            parent                  = ?
            anchorPoint             = TOPLEFT
            relativeTo              = ?
            relativePoint           = TOPLEFT
            offsetX                 = 0,
            offsetY                 = 5,
        },
        moveInvBottomBarDown    = ZO_PlayerInventory..., --For addon "PerfectPixel"
        reanchorData            = {
            {
                control         = ZO_SmithingTopLevelResearchPanelNumResearching,
                anchorPoint     = TOPLEFT,
                relativeTo      = ZO_SmithingTopLevelResearchPanel,
                relativePoint   = TOPLEFT,
                offsetX         = 68,
                offsetY         = 8, --18 original
            },
            ...
        },
    },
    ]]
    [LF_SMITHING_RESEARCH]  =   researchListControlForSubfilterBarReanchor,
    [LF_JEWELRY_RESEARCH]   =   researchListControlForSubfilterBarReanchor,
    [LF_ENCHANTING_CREATION] = {
        reanchorData            = {
            {
                --The "quest only" checkbox and anchored label
                control         = GetControl(controlsForChecks.enchanting.inventory.control, questItemsOnly),
                anchorPoint     = TOPLEFT,
                relativeTo      = controlsForChecks.enchanting.inventory.control,
                relativePoint   = TOPLEFT,
                offsetX         = 0,
                offsetY         = 20,
            }
        },
    },
}
AF.listControlForSubfilterBarReanchor = listControlForSubfilterBarReanchor

--There are no subfilter bars active at the following inventory panels. Used for debug messages!
local subFiltersBarInactive = {
    --[ITEM_TYPE_DISPLAY_CATEGORY_QUEST]  = INVENTORY_QUEST_ITEM,  -- Inventory: Quest items
    --Custom addons
    [ITEMFILTERTYPE_AF_STOLENFILTER]    = INVENTORY_BACKPACK,
}
AF.subFiltersBarInactive = subFiltersBarInactive

--These panels are currently not supported
local notSupportedPanels = {
    [CRAFTING_TYPE_ENCHANTING] = {
        [ENCHANTING_MODE_RECIPES]   = true,
        [ENCHANTING_MODE_NONE]      = true,
    },
}
AF.notSupportedPanels = notSupportedPanels

--Some special constellations where the subfilterbar should not be shown
local subfilterBarsShouldOnlyBeShownSpecial = {
    --Smithing refine
    [LF_SMITHING_REFINE] = {
        [CRAFTING_TYPE_BLACKSMITHING] = {
            [SMITHING_FILTER_TYPE_RAW_MATERIALS] = true,
        },
        [CRAFTING_TYPE_CLOTHIER] = {
            [SMITHING_FILTER_TYPE_RAW_MATERIALS] = true,
        },
        [CRAFTING_TYPE_WOODWORKING] = {
            [SMITHING_FILTER_TYPE_RAW_MATERIALS] = true,
        },
    },
    --Jewelry refine
    [LF_JEWELRY_REFINE] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = {
            [SMITHING_FILTER_TYPE_RAW_MATERIALS] = true,
        }
    }
}
AF.subfilterBarsShouldOnlyBeShownSpecial = subfilterBarsShouldOnlyBeShownSpecial

--Inventory types which should not be updated via function ChangeFilter in PLAYER_INVENTORY
--[[
--> This caused the problem with bug #28:
#28 2020-06-30, FooWasHere: Talk to vendor for woodworking, sell tab, change filter from ALL to "Weapons". Leave the woodworking vendor. Open any other vendor where there is NO
--                          Weapons subfilter given: Only weapons subfilterbar is shown and everything else is hiddem, including items

local doNotUpdateInventoriesWithInventoryChangeFilterFunction = {
    [INVENTORY_TYPE_VENDOR_BUY] = true,
}
AF.doNotUpdateInventoriesWithInventoryChangeFilterFunction = doNotUpdateInventoriesWithInventoryChangeFilterFunction
]]

--Some special inventory types which will update the variable AF.currentInventoryType if a check is done (e.g. at
--activation of a subfilter bar button)
local specialInventoryTypes = {
    [INVENTORY_QUEST_ITEM] = true
}
AF.specialInventoryTypes = specialInventoryTypes

--Abort the subfilter bar refresh for the following inventory types
local abortSubFilterRefreshInventoryTypes = {
    --[INVENTORY_TYPE_VENDOR_BUY]             = true, --Vendor buy
    --[INVENTORY_QUEST_ITEM]                  = true, --Quest items
    --Custom addons
    [ITEMFILTERTYPE_AF_STOLENFILTER] = true,
}
AF.abortSubFilterRefreshInventoryTypes = abortSubFilterRefreshInventoryTypes

--The possible subfilter groups for each inventory type, trade skill type and filtertype.
local subfilterGroups = {
    --Player inventory
    [INVENTORY_BACKPACK] = {
        [CRAFTING_TYPE_INVALID] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_JUNK] = {},

            --CUSTOM ADDON TABs
            --[[
            [ITEMFILTERTYPE_AF_STOLENFILTER] = {},
            ]]
        },
    },
    --Bank
    [INVENTORY_BANK] = {
        [CRAFTING_TYPE_INVALID] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_JUNK] = {},
        },
    },
    --Guild bank
    [INVENTORY_GUILD_BANK] = {
        [CRAFTING_TYPE_INVALID] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS] = {},
        },
    },
    --Craft bag
    [INVENTORY_CRAFT_BAG] = {
        [CRAFTING_TYPE_INVALID] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM] = {},
        },
    },
    --Quest items
    [INVENTORY_QUEST_ITEM] = {
        [CRAFTING_TYPE_INVALID] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_QUEST] = {},
        },
    },
    --Vendor buy -- no standard ZOs inventory type! Self defined in AdvancedFilters with value 900
    -->ZOs did not change the vendor buy as well :-( Only the normal inventories were changed
--[[
    [INVENTORY_TYPE_VENDOR_BUY] = {
        [CRAFTING_TYPE_INVALID] = {
            --New
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS] = {},
            [ITEMFILTERTYPE_COLLECTIBLE] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING] ={},
            --Old
            [ITEMFILTERTYPE_ALL] = {},
            [ITEMFILTERTYPE_WEAPONS] = {},
            [ITEMFILTERTYPE_ARMOR] = {},
            [ITEMFILTERTYPE_CONSUMABLE] = {},
            [ITEMFILTERTYPE_CRAFTING] = {},
            [ITEMFILTERTYPE_MISCELLANEOUS] = {},
            [ITEMFILTERTYPE_COLLECTIBLE] = {},
            [ITEMFILTERTYPE_JEWELRY] = {},
            [ITEMFILTERTYPE_FURNISHING] ={},
        },
    },
]]

    --Crafting SMITHING: Create
    --[[
    [LF_SMITHING_CREATION] = {
        [CRAFTING_TYPE_BLACKSMITHING] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_CREATE_ARMOR_SMITHING] = {},
            [ITEMFILTERTYPE_AF_CREATE_WEAPONS_SMITHING] = {},
        },
        [CRAFTING_TYPE_WOODWORKING] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_CREATE_ARMOR_WOODWORKING] = {},
            [ITEMFILTERTYPE_AF_CREATE_WEAPONS_WOODWORKING] = {},
        },
        [CRAFTING_TYPE_CLOTHIER] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_CREATE_ARMOR_CLOTHIER] = {},
        },
    },
    ]]

    --Crafting SMITHING: Refine
    [LF_SMITHING_REFINE] = {
        [CRAFTING_TYPE_BLACKSMITHING] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_REFINE_SMITHING] = {},
        },
        [CRAFTING_TYPE_WOODWORKING] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_REFINE_WOODWORKING] = {},
        },
        [CRAFTING_TYPE_CLOTHIER] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_REFINE_CLOTHIER] = {},
        },
    },

    --Crafting SMITHING: Deconstruction
    [LF_SMITHING_DECONSTRUCT] = {
        [CRAFTING_TYPE_BLACKSMITHING] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_WEAPONS_SMITHING] = {},
            [ITEMFILTERTYPE_AF_ARMOR_SMITHING] = {},
        },
        [CRAFTING_TYPE_WOODWORKING] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_WEAPONS_WOODWORKING] = {},
            [ITEMFILTERTYPE_AF_ARMOR_WOODWORKING] = {},
        },
        [CRAFTING_TYPE_CLOTHIER] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_ARMOR_CLOTHIER] = {},
        },
    },

    --Crafting SMITHING: Improvement
    [LF_SMITHING_IMPROVEMENT] = {
        [CRAFTING_TYPE_BLACKSMITHING] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_WEAPONS_SMITHING] = {},
            [ITEMFILTERTYPE_AF_ARMOR_SMITHING] = {},
        },
        [CRAFTING_TYPE_WOODWORKING] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_WEAPONS_WOODWORKING] = {},
            [ITEMFILTERTYPE_AF_ARMOR_WOODWORKING] = {},
        },
        [CRAFTING_TYPE_CLOTHIER] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_ARMOR_CLOTHIER] = {},
        },
    },

    --Crafting SMITHING: Research
    [LF_SMITHING_RESEARCH] = {
        [CRAFTING_TYPE_BLACKSMITHING] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_WEAPONS_SMITHING] = {},
            [ITEMFILTERTYPE_AF_ARMOR_SMITHING] = {},
        },
        [CRAFTING_TYPE_WOODWORKING] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_WEAPONS_WOODWORKING] = {},
            [ITEMFILTERTYPE_AF_ARMOR_WOODWORKING] = {},
        },
        [CRAFTING_TYPE_CLOTHIER] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_ARMOR_CLOTHIER] = {},
        },
    },

    --Crafting JEWELRY: Create
    --[[
    [LF_JEWELRY_CREATION] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_CREATE_JEWELRY] = {},
        },
    },
    ]]

    --Crafting JEWELRY: Refine
    [LF_JEWELRY_REFINE] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_REFINE_JEWELRY] = {},
        },
    },

    --Crafting JEWELRY: Deconstruction
    [LF_JEWELRY_DECONSTRUCT] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_JEWELRY_CRAFTING] = {},
        },
    },
    --Crafting JEWELRY: Improvement
    [LF_JEWELRY_IMPROVEMENT] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_JEWELRY_CRAFTING] = {},
        },
    },

    --Crafting JEWELRY: Research
    [LF_JEWELRY_RESEARCH] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_JEWELRY_CRAFTING] = {},
        },
    },

    --Crafting ENCHANTING: Creation
    [LF_ENCHANTING_CREATION] = {
        [CRAFTING_TYPE_ENCHANTING] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            --[ITEMFILTERTYPE_AF_RUNES_ENCHANTING] = {}, TODO: Currently disabled as no extra filters are needed/possible
        },
    },
    --Crafting ENCHANTING: Extraction
    [LF_ENCHANTING_EXTRACTION] = {
        [CRAFTING_TYPE_ENCHANTING] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEMFILTERTYPE_AF_GLYPHS_ENCHANTING] = {},
        },
    },
    --Houes bank withdraw
    [INVENTORY_HOUSE_BANK] = {
        [CRAFTING_TYPE_INVALID] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_JUNK] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY] = {},
            [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING] = {},
        },
    },
    --Retrait
    [LF_RETRAIT] = {
        [CRAFTING_TYPE_INVALID] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL]    = {},
            [ITEMFILTERTYPE_AF_RETRAIT_ARMOR]   = {},
            [ITEMFILTERTYPE_AF_RETRAIT_WEAPONS] = {},
            [ITEMFILTERTYPE_AF_RETRAIT_JEWELRY] = {},
        },
    },
    --QuickSlots
    [LF_QUICKSLOT] = {
        [CRAFTING_TYPE_INVALID] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL]                  = {}, --ITEMFILTERTYPE_ALL
            [AF_QS_PREFIX..ITEMFILTERTYPE_QUICKSLOT]          = {},
            [AF_QS_PREFIX..ITEMFILTERTYPE_QUEST_QUICKSLOT]    = {},
        }
    }
}
AF.subfilterGroups = subfilterGroups

--The filter bar parent controls
local filterBarParents = {
    [inventoryNames[INVENTORY_BACKPACK]]        = GetControl(controlsForChecks.inv, filterDividerSuffix),
    [inventoryNames[INVENTORY_QUEST_ITEM]]      = GetControl(controlsForChecks.inv, filterDividerSuffix),
    [inventoryNames[INVENTORY_BANK]]            = GetControl(controlsForChecks.bank, filterDividerSuffix),
    [inventoryNames[INVENTORY_GUILD_BANK]]      = GetControl(controlsForChecks.guildBank, filterDividerSuffix),
    [inventoryNames[INVENTORY_TYPE_VENDOR_BUY]] = GetControl(controlsForChecks.storeWindow, filterDividerSuffix),
    [inventoryNames[INVENTORY_CRAFT_BAG]]       = GetControl(controlsForChecks.craftBag, filterDividerSuffix),
    --[inventoryNames[LF_SMITHING_CREATION]]      = controlsForChecks.smithing.creationPanel.control,
    [inventoryNames[LF_SMITHING_REFINE]]        = GetControl(controlsForChecks.smithing.refinementPanel.inventory.control, filterDividerSuffix),
    [inventoryNames[LF_SMITHING_DECONSTRUCT]]   = GetControl(controlsForChecks.smithing.deconstructionPanel.inventory.control, filterDividerSuffix),
    [inventoryNames[LF_SMITHING_IMPROVEMENT]]   = GetControl(controlsForChecks.smithing.improvementPanel.inventory.control, filterDividerSuffix),
    [inventoryNames[LF_SMITHING_RESEARCH]]      = GetControl(controlsForChecks.smithing.researchPanel.control, buttonDividerSuffix),
    --[inventoryNames[LF_JEWELRY_CREATION]]       = controlsForChecks.smithing.creationPanel.control,
    [inventoryNames[LF_JEWELRY_REFINE]]         = GetControl(controlsForChecks.smithing.refinementPanel.inventory.control, filterDividerSuffix),
    [inventoryNames[LF_JEWELRY_DECONSTRUCT]]    = GetControl(controlsForChecks.smithing.deconstructionPanel.inventory.control, filterDividerSuffix),
    [inventoryNames[LF_JEWELRY_IMPROVEMENT]]    = GetControl(controlsForChecks.smithing.improvementPanel.inventory.control, filterDividerSuffix),
    [inventoryNames[LF_JEWELRY_RESEARCH]]       = GetControl(controlsForChecks.smithing.researchPanel.control, buttonDividerSuffix),
    [inventoryNames[LF_ENCHANTING_CREATION]]    = GetControl(controlsForChecks.enchanting.inventoryControl, filterDividerSuffix),
    [inventoryNames[LF_ENCHANTING_EXTRACTION]]  = GetControl(controlsForChecks.enchanting.inventoryControl, filterDividerSuffix),
    [inventoryNames[INVENTORY_HOUSE_BANK]]      = GetControl(controlsForChecks.houseBank, filterDividerSuffix),
    [inventoryNames[LF_RETRAIT]]                = GetControl(controlsForChecks.retrait.inventory.control, filterDividerSuffix),
    [inventoryNames[LF_QUICKSLOT]]              = GetControl(controlsForChecks.quickslot.container, filterDividerSuffix),
}
AF.filterBarParents = filterBarParents

--Controls which should be hidden as the filter bar is shown at this panel
local researchFilterBarParentControlsToHide = {
    ZO_SmithingTopLevelResearchPanelResearchLineListDivider,
    ZO_SmithingTopLevelResearchPanelResearchLineListTitle,
}
local filterBarParentControlsToHide = {
    [LF_INVENTORY]   = {
        --ZO_PlayerInventorySearchDivider
        GetControl(controlsForChecks.inv, searchDividerSuffix),
    },
    [LF_MAIL_SEND]   = {
        --ZO_PlayerInventorySearchDivider
        GetControl(controlsForChecks.inv, searchDividerSuffix),
    },
    [LF_TRADE]   = {
        --ZO_PlayerInventorySearchDivider
        GetControl(controlsForChecks.inv, searchDividerSuffix),
    },
    [LF_CRAFTBAG]   = {
        GetControl(controlsForChecks.craftBag, searchDividerSuffix),
    },
    [LF_BANK_DEPOSIT]   = {
        GetControl(controlsForChecks.inv, searchDividerSuffix),
    },
    [LF_BANK_WITHDRAW]   = {
        GetControl(controlsForChecks.bank, searchDividerSuffix),
    },
    [LF_GUILDBANK_DEPOSIT]   = {
        GetControl(controlsForChecks.inv, searchDividerSuffix),
    },
    [LF_GUILDBANK_WITHDRAW]   = {
        GetControl(controlsForChecks.guildBank, searchDividerSuffix),
    },
    --[[
    [LF_VENDOR_SELL]   = {
        GetControl(controlsForChecks.storeWindow, searchDividerSuffix),
    },
    ]]
    [LF_HOUSE_BANK_WITHDRAW]   = {
        GetControl(controlsForChecks.houseBank, searchDividerSuffix),
    },
    [LF_SMITHING_DECONSTRUCT]   = {
        --ZO_SmithingTopLevelDeconstructionPanelInventoryButtonDivider
        GetControl(controlsForChecks.smithing.deconstructionPanel.inventory.control, buttonDividerSuffix),
    },
    [LF_JEWELRY_DECONSTRUCT]    = {
        GetControl(controlsForChecks.smithing.deconstructionPanel.inventory.control, buttonDividerSuffix),
    },
    [LF_SMITHING_RESEARCH]  = researchFilterBarParentControlsToHide,
    [LF_JEWELRY_RESEARCH]   = researchFilterBarParentControlsToHide,
    [LF_ENCHANTING_CREATION]    = {
        GetControl(controlsForChecks.enchanting.inventory.control, buttonDividerSuffix),
    },
    [LF_ENCHANTING_EXTRACTION]  = {
        GetControl(controlsForChecks.enchanting.inventory.control, buttonDividerSuffix),
    },
    [LF_RETRAIT]  = {
        GetControl(controlsForChecks.retrait.inventory.control, buttonDividerSuffix),
    },
    [LF_QUICKSLOT] = {
        GetControl(controlsForChecks.quickslot.container, searchDividerSuffix),
    }
}
AF.filterBarParentControlsToHide = filterBarParentControlsToHide

--The fragment controls which contain the inventory layoutData tables
-->Used for e.g. the vanilla UI searchFilter bars, to disable them (hide them)
local layoutDataFragments = {
    BACKPACK_DEFAULT_LAYOUT_FRAGMENT,
    BACKPACK_MENU_BAR_LAYOUT_FRAGMENT,
    BACKPACK_TRADING_HOUSE_LAYOUT_FRAGMENT,
    QUICKSLOT_FRAGMENT,
}
AF.layoutDataFragments = layoutDataFragments

--The crafting inventory layoutdata for the filterBar, inventoryList, sortHeader offsets
--2020-09-24: https://github.com/esoui/esoui/blob/c47af79c7c51681ae315d4f9a6d70d9e965ad514/esoui/ingame/inventory/backpacklayouts.lua#L6
local AF_defaultInventoryBackpackLayoutData = {
    --inventoryFilterDividerTopOffsetY = DEFAULT_INVENTORY_FILTER_DIVIDER_TOP_OFFSET_Y,
    width = 565,
    backpackOffsetY = 96,
    --inventoryTopOffsetY = -20,
    --inventoryBottomOffsetY = -30,
    sortByOffsetY = 102,
    --emptyLabelOffsetY = 100,
    --sortByHeaderWidth = 576,
    --sortByNameWidth = 241,
    --hideBankInfo = true,
    --hideCurrencyInfo = false,
}
local AF_smithingResearchLayoutData = {
    --inventoryFilterDividerTopOffsetY = DEFAULT_INVENTORY_FILTER_DIVIDER_TOP_OFFSET_Y,
    --width = 565,
    backpackOffsetY = 0,
    --inventoryTopOffsetY = -20,
    --inventoryBottomOffsetY = -30,
    --sortByOffsetY = 0,
    --emptyLabelOffsetY = 100,
    --sortByHeaderWidth = 576,
    --sortByNameWidth = 241,
    --hideBankInfo = true,
    --hideCurrencyInfo = false,
}
local filterBarCraftingInventoryLayoutData = {
    [LF_SMITHING_REFINE]        = AF_defaultInventoryBackpackLayoutData,
    [LF_SMITHING_DECONSTRUCT]   = AF_defaultInventoryBackpackLayoutData,
    [LF_SMITHING_IMPROVEMENT]   = AF_defaultInventoryBackpackLayoutData,
    [LF_SMITHING_RESEARCH]      = AF_smithingResearchLayoutData,
    [LF_JEWELRY_REFINE]         = AF_defaultInventoryBackpackLayoutData,
    [LF_JEWELRY_DECONSTRUCT]    = AF_defaultInventoryBackpackLayoutData,
    [LF_JEWELRY_IMPROVEMENT]    = AF_defaultInventoryBackpackLayoutData,
    [LF_JEWELRY_RESEARCH]       = AF_smithingResearchLayoutData,
    [LF_ENCHANTING_CREATION]    = AF_defaultInventoryBackpackLayoutData,
    [LF_ENCHANTING_EXTRACTION]  = AF_defaultInventoryBackpackLayoutData,
    [LF_RETRAIT]                = AF_defaultInventoryBackpackLayoutData,
}
AF.defaultInventoryBackpackLayoutData = AF_defaultInventoryBackpackLayoutData
AF.filterBarCraftingInventoryLayoutData = filterBarCraftingInventoryLayoutData

--SUBFILTER BAR BUTTONS
--The subfilter bars button names
local subfilterButtonNames = {
    [ITEM_TYPE_DISPLAY_CATEGORY_ALL] = {
        AF_CONST_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] = {
        "HealStaff", "DestructionStaff", "Bow", "TwoHand", "OneHand", AF_CONST_ALL,
    },
    --[[
    [ITEMFILTERTYPE_AF_CREATE_ARMOR_CLOTHIER] = {
        "Heavy", AF_CONST_ALL
    },
    [ITEMFILTERTYPE_AF_CREATE_ARMOR_SMITHING] = {
        "Medium", "LightArmor", AF_CONST_ALL
    },
    [ITEMFILTERTYPE_AF_CREATE_ARMOR_WOODWORKING] = {
        "Shield", AF_CONST_ALL
    },
    [ITEMFILTERTYPE_AF_CREATE_WEAPONS_SMITHING] = {
        "OneHand", "TwoHand", AF_CONST_ALL
    },
    [ITEMFILTERTYPE_AF_CREATE_WEAPONS_WOODWORKING] = {
        "Bow", "DestructionStaff", "HealStaff", AF_CONST_ALL
    },
    [ITEMFILTERTYPE_AF_CREATE_JEWELRY] = {
        "Ring", "Neck", AF_CONST_ALL,
    },
    ]]
    [ITEMFILTERTYPE_AF_REFINE_CLOTHIER] = {
        "RawMaterialClothier", AF_CONST_ALL,
    },
    [ITEMFILTERTYPE_AF_REFINE_SMITHING] = {
        "RawMaterialSmithing", AF_CONST_ALL,
    },
    [ITEMFILTERTYPE_AF_REFINE_WOODWORKING] = {
        "RawMaterialWoodworking", AF_CONST_ALL,
    },
    [ITEMFILTERTYPE_AF_WEAPONS_SMITHING] = {
        "TwoHand", "OneHand", AF_CONST_ALL,
    },
    [ITEMFILTERTYPE_AF_WEAPONS_WOODWORKING] = {
        "HealStaff", "DestructionStaff", "Bow", AF_CONST_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] = {
        --"Vanity", --> Moved to Miscelaneous
        "Shield", "Clothing", "LightArmor", "Medium",
        "Heavy", AF_CONST_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY] = {
        "Neck", "Ring", AF_CONST_ALL,
    },
    [ITEMFILTERTYPE_AF_ARMOR_SMITHING] = {
        "Heavy", AF_CONST_ALL,
    },
    [ITEMFILTERTYPE_AF_ARMOR_CLOTHIER] = {
        "LightArmor", "Medium", AF_CONST_ALL,
    },
    [ITEMFILTERTYPE_AF_ARMOR_WOODWORKING] = {
        "Shield", AF_CONST_ALL,
    },
    [ITEMFILTERTYPE_AF_RUNES_ENCHANTING] = {
        AF_CONST_ALL,
    },
    [ITEMFILTERTYPE_AF_GLYPHS_ENCHANTING] = {
        "WeaponGlyph", "ArmorGlyph", "JewelryGlyph", AF_CONST_ALL,
    },
    [ITEMFILTERTYPE_COLLECTIBLE] = {
        AF_CONST_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE] = {
        "Trophy", "Repair", "Container", "Writ", "Motif", "Poison",
        "Potion", "Recipe", "Drink", "Food", "Crown", AF_CONST_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] = {
        "FurnishingMat", "AllTraits", --"JewelryTrait", "WeaponTrait", "ArmorTrait", -> Removed due to not enough place! Combined within "AllTraits"
        "Style",
        "JewelryCrafting", "Provisioning", "Enchanting", "Alchemy", "Woodworking",
        "Clothier", "Blacksmithing", AF_CONST_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING] = {
        "TargetDummy", "Seating", "Ornamental", "Light", "CraftingStation",
        AF_CONST_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS] = {
        "Vanity", "Trash", "Fence", "Trophy", "Tool", "Bait", "Siege", "SoulGem",
        "Glyphs", AF_CONST_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_QUEST] = {
        AF_CONST_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_JUNK] = {
        "Miscellaneous", "Furnishings", "Materials", "Consumable", "Jewelry", "Armor", "Weapon",
        AF_CONST_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING] = {
        "FurnishingMat", "Temper", "RefinedMaterialSmithing", "RawMaterialSmithing", AF_CONST_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING] = {
        "FurnishingMat", "Tannin", "RefinedMaterialClothier", "RawMaterialClothier", AF_CONST_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING] = {
        "FurnishingMat", "Resin", "RefinedMaterialWoodworking", "RawMaterialWoodworking", AF_CONST_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY] = {
        "FurnishingMat", "Oil", "Water", "Reagent", AF_CONST_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING] = {
        "FurnishingMat", "Potency", "Essence", "Aspect", AF_CONST_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING] = {
        "FurnishingMat", "Bait", "RareIngredient", --"OldIngredient",
        "DrinkIngredient", "FoodIngredient", AF_CONST_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING] = {
        "FurnishingMat", "Plating", "RefinedMaterialJewelry", "RawPlating", "RawMaterialJewelry", AF_CONST_ALL,
    },
    [ITEMFILTERTYPE_AF_JEWELRY_CRAFTING] = {
        "Ring", "Neck", AF_CONST_ALL,
    },
    [ITEMFILTERTYPE_AF_REFINE_JEWELRY] = {
        "RawMaterialJewelry", "RawPlating", "JewelryRawTrait", AF_CONST_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL] = {
        "CrownStyle", "ExoticStyle", "AllianceStyle", "RareStyle",
        "NormalStyle", AF_CONST_ALL,
    },
    [ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM] = {
        "JewelryAllTrait", "WeaponTrait", "ArmorTrait", AF_CONST_ALL,
    },
    [ITEMFILTERTYPE_AF_RETRAIT_ARMOR] = {
        "Shield", "LightArmor", "Medium", "Heavy", AF_CONST_ALL,
    },
    [ITEMFILTERTYPE_AF_RETRAIT_WEAPONS] = {
        "HealStaff", "DestructionStaff", "Bow", "TwoHand", "OneHand", AF_CONST_ALL,
    },
    [ITEMFILTERTYPE_AF_RETRAIT_JEWELRY] = {
        "Neck", "Ring", AF_CONST_ALL,
    },
    [AF_QS_PREFIX..ITEMFILTERTYPE_QUICKSLOT] = {
        "Potion", "Drink", "Food", AF_CONST_ALL,
    },
    [AF_QS_PREFIX..ITEMFILTERTYPE_QUEST_QUICKSLOT] = {
        AF_CONST_ALL,
    }
    --CUSTOM ADDON TABs
    --[[
    [ITEMFILTERTYPE_AF_STOLENFILTER] = {
        AF_CONST_ALL,
    }
    ]]
}

--Dynamic subfilterBar entries, e.g. quickslot -> the collectible subfilterBars. Used in function createAdditionalSubFilterGroups
--in file main.lua
AF.collectibleDataKeyToSubFilterBars = {
    --[Quickslot, dynamically created collectibles subfilterBars]
    --The ones not listed here with the key (see function util.getAFQuickSlotCollectibleKey(categoryData)) will just get
    --1 subfilterBar with AF_CONST_ALL!
    --
    --All others will get the listed bars here. Be sure to also define the categoryTypes below in AF.collectibleDataKeyToCategoryTypes
    --for the same key so they will filter the correct collectible cetegoyTypes!

    --Outfits
    [AF_QS_PREFIX.."13_3_0"] = {
        "Costume", AF_CONST_ALL
    }
}
--The categoryTypes of the collectibles in the subfilter bars. Used in function createAdditionalSubFilterGroups in file
--main.lua to specify what the GetFilterCallbackForCollectibles function in data.lua should filter as categories at this
--subfilterbar
AF.collectibleDataKeyToCategoryTypes = {
    --Outfits
    [AF_QS_PREFIX.."13_3_0"] = {
        ["Costume"] = {COLLECTIBLE_CATEGORY_TYPE_COSTUME},
    }
}


--Exclude some of the buttons at an inventory type, craft type, and filter type?
--If you add entries be sure to add the other ones, sharing the same AF.subfilterCallbacks[groupName][subfilterName]
--as well!
--[[
local excludeButtonNamesfromSubFilterBar = {
    --InventoryName
    [INVENTORY_CRAFT_BAG] = {
        --TradeSkillNames
        [CRAFTING_TYPE_INVALID] = {
            --FilterTypeNames
            [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] =
                --Exclude this single buttons here:
                "AllTraits"
        }
    },
    [INVENTORY_BACKPACK] = {
        [CRAFTING_TYPE_INVALID] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] = {
                --Exclude these buttons here:
                {"JewelryTrait", "WeaponTrait", "ArmorTrait"}
            }
        }
    },
    [INVENTORY_BANK] = {
        [CRAFTING_TYPE_INVALID] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] = {
                --Exclude these buttons here:
                {"JewelryTrait", "WeaponTrait", "ArmorTrait"}
            }
        }
    },
    [INVENTORY_GUILD_BANK] = {
        [CRAFTING_TYPE_INVALID] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] = {
                --Exclude these buttons here:
                {"JewelryTrait", "WeaponTrait", "ArmorTrait"}
            }
        }
    },
    [INVENTORY_HOUSE_BANK] = {
        [CRAFTING_TYPE_INVALID] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] = {
                --Exclude these buttons here:
                {"JewelryTrait", "WeaponTrait", "ArmorTrait"}
            }
        }
    },
    [INVENTORY_TYPE_VENDOR_BUY] = {
        [CRAFTING_TYPE_INVALID] = {
            [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING] = {
                --Exclude these buttons here:
                {"JewelryTrait", "WeaponTrait", "ArmorTrait"}
            }
        }
    },
}
]]
AF.subfilterButtonNames = subfilterButtonNames


--DROPDOWN BOXES
--SubfilterButton entries which should not be added to dropdownCallback entries
local subfilterButtonEntriesNotForDropdownCallback = {
    [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] = {
        ["doNotAdd"] = {"Clothing", "LightArmor", "Medium", "Heavy"}, --These are combined into the entry "Body"
        ["replaceWith"] = "Body",
    },
}
AF.subfilterButtonEntriesNotForDropdownCallback = subfilterButtonEntriesNotForDropdownCallback

--INVENTORY TYPES
--The following inventoryTypes are LibFilters filterPanelIds!
local invEqualsLibFilters = {
    [LF_QUICKSLOT]              = true,
    [LF_SMITHING_REFINE]        = true,
    [LF_JEWELRY_REFINE]         = true,
    [LF_SMITHING_CREATION]      = true,
    [LF_JEWELRY_CREATION]       = true,
    [LF_SMITHING_DECONSTRUCT]   = true,
    [LF_JEWELRY_DECONSTRUCT]    = true,
    [LF_SMITHING_IMPROVEMENT]   = true,
    [LF_JEWELRY_IMPROVEMENT]    = true,
    [LF_SMITHING_RESEARCH]      = true,
    [LF_JEWELRY_RESEARCH]       = true,
    [LF_ENCHANTING_CREATION]    = true,
    [LF_ENCHANTING_EXTRACTION]  = true,
    [LF_RETRAIT]                = true,
}
AF.invEqualsLibFilters = invEqualsLibFilters

local mapInvTypeToInvTypeBefore = {
    --Inventory + quest
    [INVENTORY_BACKPACK]        = INVENTORY_QUEST_ITEM,
    [INVENTORY_QUEST_ITEM]      = INVENTORY_BACKPACK,
    --Enchanting
    [LF_ENCHANTING_CREATION]    = LF_ENCHANTING_EXTRACTION,
    [LF_ENCHANTING_EXTRACTION]  = LF_ENCHANTING_CREATION,
    --Refinement
    [LF_SMITHING_REFINE]        = LF_JEWELRY_REFINE,
    [LF_JEWELRY_REFINE]         = LF_SMITHING_REFINE,
    --Deconstruction
    [LF_SMITHING_DECONSTRUCT]   = LF_JEWELRY_DECONSTRUCT,
    [LF_JEWELRY_DECONSTRUCT]    = LF_SMITHING_DECONSTRUCT,
    --Improvement
    [LF_SMITHING_IMPROVEMENT]   = LF_JEWELRY_IMPROVEMENT,
    [LF_JEWELRY_IMPROVEMENT]    = LF_SMITHING_IMPROVEMENT,
    --Research
    [LF_SMITHING_RESEARCH]      = LF_JEWELRY_RESEARCH,
    [LF_JEWELRY_RESEARCH]       = LF_SMITHING_RESEARCH,
}
AF.mapInvTypeToInvTypeBefore = mapInvTypeToInvTypeBefore

--CRAFTBAG
--The different filter groups for the CraftBag
local craftBagFilterGroups = {
    filterTypeNames[ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING],
    filterTypeNames[ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING],
    filterTypeNames[ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING],
    filterTypeNames[ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY],
    filterTypeNames[ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING],
    filterTypeNames[ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING],
    filterTypeNames[ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL],
    filterTypeNames[ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM],
    filterTypeNames[ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING],
}
AF.craftBagFilterGroups = craftBagFilterGroups

--CRAFTING
--The variables for the crafting tables (to get the active filter)
local craftingTables = {
    --Smithing
    [LF_SMITHING_REFINE]        = controlsForChecks.smithing,
    [LF_JEWELRY_REFINE]         = controlsForChecks.smithing,
    [LF_SMITHING_CREATION]      = controlsForChecks.smithing,
    [LF_JEWELRY_CREATION]       = controlsForChecks.smithing,
    [LF_SMITHING_DECONSTRUCT]   = controlsForChecks.smithing,
    [LF_JEWELRY_DECONSTRUCT]    = controlsForChecks.smithing,
    [LF_SMITHING_IMPROVEMENT]   = controlsForChecks.smithing,
    [LF_JEWELRY_IMPROVEMENT]    = controlsForChecks.smithing,
    [LF_SMITHING_RESEARCH]      = controlsForChecks.smithing,
    [LF_JEWELRY_RESEARCH]       = controlsForChecks.smithing,
    --Enchanting
    [LF_ENCHANTING_CREATION]    = controlsForChecks.enchanting,
    [LF_ENCHANTING_EXTRACTION]  = controlsForChecks.enchanting,
    --Retrait
    [LF_RETRAIT]                = controlsForChecks.retrait,
}
AF.craftingTables = craftingTables

--The variables for the crafting table panels (to get the active filter of their inventory)
local craftingTablePanels = {
    --Smithing
    [LF_SMITHING_REFINE]        = controlsForChecks.refinementPanel,
    [LF_JEWELRY_REFINE]         = controlsForChecks.refinementPanel,
    [LF_SMITHING_CREATION]      = controlsForChecks.creationPanel,
    [LF_JEWELRY_CREATION]       = controlsForChecks.creationPanel,
    [LF_SMITHING_DECONSTRUCT]   = controlsForChecks.deconstructionPanel,
    [LF_JEWELRY_DECONSTRUCT]    = controlsForChecks.deconstructionPanel,
    [LF_SMITHING_IMPROVEMENT]   = controlsForChecks.improvementPanel,
    [LF_JEWELRY_IMPROVEMENT]    = controlsForChecks.improvementPanel,
    [LF_SMITHING_RESEARCH]      = controlsForChecks.researchPanel,
    [LF_JEWELRY_RESEARCH]       = controlsForChecks.researchPanel,
    --Enchanting
    [LF_ENCHANTING_CREATION]    = controlsForChecks.enchantCreatePanel,
    [LF_ENCHANTING_EXTRACTION]  = controlsForChecks.enchantExtractPanel,
    --Retrait
    [LF_RETRAIT]                = controlsForChecks.retraitPanel,
}
AF.craftingTablePanels = craftingTablePanels

--Does the crafting table use the BAG_WORN in it's inventory checks?
local craftingFilterPanelId2UsesBagWorn = {
    --Smithing
    [LF_SMITHING_IMPROVEMENT]   = true,
    [LF_JEWELRY_IMPROVEMENT]    = true,
    --Retrait
    [LF_RETRAIT]                = true,
}
AF.craftingFilterPanelId2UsesBagWorn = craftingFilterPanelId2UsesBagWorn

--The predicate and filter functions used at the crafting panels to prefiletr and "only" show some items
--e.g. no bound ones or no stolen ones, or only the ones which can be refined etc. (including the stolen and bound checks)
local craftingFilterPanelId2PredicateFunc = {
    [LF_SMITHING_REFINE]        = {ZO_SharedSmithingExtraction_IsExtractableItem, ZO_SharedSmithingExtraction_DoesItemPassFilter},
    [LF_SMITHING_CREATION]      = {nil, nil},
    [LF_SMITHING_DECONSTRUCT]   = {ZO_SharedSmithingExtraction_IsExtractableItem, ZO_SharedSmithingExtraction_DoesItemPassFilter},
    [LF_SMITHING_IMPROVEMENT]   = {ZO_SharedSmithingExtraction_IsExtractableItem, ZO_SharedSmithingImprovement_DoesItemPassFilter},
    [LF_SMITHING_RESEARCH]      = {nil, nil},
    [LF_JEWELRY_REFINE]         = {ZO_SharedSmithingExtraction_IsExtractableItem, ZO_SharedSmithingExtraction_DoesItemPassFilter},
    [LF_JEWELRY_CREATION]       = true,
    [LF_JEWELRY_DECONSTRUCT]    = {ZO_SharedSmithingExtraction_IsExtractableItem, ZO_SharedSmithingExtraction_DoesItemPassFilter},
    [LF_JEWELRY_IMPROVEMENT]    = {ZO_SharedSmithingExtraction_IsExtractableItem, ZO_SharedSmithingImprovement_DoesItemPassFilter},
    [LF_JEWELRY_RESEARCH]       = {nil, nil},
    [LF_ENCHANTING_CREATION]    = {nil, nil},
    [LF_ENCHANTING_EXTRACTION]  = {nil, nil},
    [LF_RETRAIT]                = {ZO_RetraitStation_CanItemBeRetraited, ZO_RetraitStation_DoesItemPassFilter},
}
AF.craftingFilterPanelId2PredicateFunc = craftingFilterPanelId2PredicateFunc

--[[
    SMITHING_FILTER_TYPE_RAW_MATERIALS = 1
    SMITHING_FILTER_TYPE_ARMOR = 1
    SMITHING_FILTER_TYPE_WEAPONS = 2
    SMITHING_FILTER_TYPE_ARMOR = 1
    SMITHING_FILTER_TYPE_WEAPONS = 2
    --
    SMITHING_FILTER_TYPE_JEWELRY = 6
    --
    ENCHANTING_MODE_CREATION    = 1
    ENCHANTING_MODE_EXTRACTION  = 2
]]
--Map the AdvancedFilters filter type (selected filter button at the crafting table, or selected subfilter button, e.g. weapons) to the
--itemfilter type that is used for the ESO filters (shown items)
local craftingTableAFFilterType2ESOFilterType = {
    [LF_SMITHING_REFINE] = {
        [CRAFTING_TYPE_BLACKSMITHING] = {
            [ITEMFILTERTYPE_AF_REFINE_SMITHING]             = SMITHING_FILTER_TYPE_RAW_MATERIALS,
        },
        [CRAFTING_TYPE_CLOTHIER] = {
            [ITEMFILTERTYPE_AF_REFINE_CLOTHIER]             = SMITHING_FILTER_TYPE_RAW_MATERIALS,
        },
        [CRAFTING_TYPE_WOODWORKING] = {
            [ITEMFILTERTYPE_AF_REFINE_WOODWORKING]          = SMITHING_FILTER_TYPE_RAW_MATERIALS,
        },
    },
    [LF_SMITHING_DECONSTRUCT] = {
        [CRAFTING_TYPE_BLACKSMITHING] = {
            [ITEMFILTERTYPE_AF_WEAPONS_SMITHING]            = SMITHING_FILTER_TYPE_WEAPONS,
            [ITEMFILTERTYPE_AF_ARMOR_SMITHING]              = SMITHING_FILTER_TYPE_ARMOR,
        },
        [CRAFTING_TYPE_CLOTHIER] = {
            [ITEMFILTERTYPE_AF_ARMOR_CLOTHIER]              = SMITHING_FILTER_TYPE_ARMOR,
        },
        [CRAFTING_TYPE_WOODWORKING] = {
            [ITEMFILTERTYPE_AF_WEAPONS_WOODWORKING]         = SMITHING_FILTER_TYPE_WEAPONS,
            [ITEMFILTERTYPE_AF_ARMOR_WOODWORKING]           = SMITHING_FILTER_TYPE_ARMOR,
        },
    },
    [LF_SMITHING_IMPROVEMENT] = {
        [CRAFTING_TYPE_BLACKSMITHING] = {
            [ITEMFILTERTYPE_AF_WEAPONS_SMITHING]            = SMITHING_FILTER_TYPE_WEAPONS,
            [ITEMFILTERTYPE_AF_ARMOR_SMITHING]              = SMITHING_FILTER_TYPE_ARMOR,
        },
        [CRAFTING_TYPE_CLOTHIER] = {
            [ITEMFILTERTYPE_AF_ARMOR_CLOTHIER]              = SMITHING_FILTER_TYPE_ARMOR,
        },
        [CRAFTING_TYPE_WOODWORKING] = {
            [ITEMFILTERTYPE_AF_WEAPONS_WOODWORKING]         = SMITHING_FILTER_TYPE_WEAPONS,
            [ITEMFILTERTYPE_AF_ARMOR_WOODWORKING]           = SMITHING_FILTER_TYPE_ARMOR,
        },

    },
    [LF_SMITHING_RESEARCH] = {
        [CRAFTING_TYPE_BLACKSMITHING] = {
            [ITEMFILTERTYPE_AF_WEAPONS_SMITHING]            = SMITHING_FILTER_TYPE_WEAPONS,
            [ITEMFILTERTYPE_AF_ARMOR_SMITHING]              = SMITHING_FILTER_TYPE_ARMOR,
        },
        [CRAFTING_TYPE_CLOTHIER] = {
            [ITEMFILTERTYPE_AF_ARMOR_CLOTHIER]              = SMITHING_FILTER_TYPE_ARMOR,
        },
        [CRAFTING_TYPE_WOODWORKING] = {
            [ITEMFILTERTYPE_AF_WEAPONS_WOODWORKING]         = SMITHING_FILTER_TYPE_WEAPONS,
            [ITEMFILTERTYPE_AF_ARMOR_WOODWORKING]           = SMITHING_FILTER_TYPE_ARMOR,
        }
    },
    --[[
    [LF_JEWELRY_CREATION] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = {
            [ITEMFILTERTYPE_AF_CREATE_JEWELRY]             = ITEMFILTERTYPE_AF_CREATE_JEWELRY,
        },

    },
    ]]
    [LF_JEWELRY_REFINE] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = {
            [ITEMFILTERTYPE_AF_REFINE_JEWELRY]             = SMITHING_FILTER_TYPE_RAW_MATERIALS,
        },

    },
    [LF_JEWELRY_DECONSTRUCT] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = {
            [ITEMFILTERTYPE_AF_JEWELRY_CRAFTING]           = SMITHING_FILTER_TYPE_JEWELRY,
        },
    },
    [LF_JEWELRY_IMPROVEMENT] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = {
            [ITEMFILTERTYPE_AF_JEWELRY_CRAFTING]           = SMITHING_FILTER_TYPE_JEWELRY,
        },

    },
    [LF_JEWELRY_RESEARCH] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = {
            [ITEMFILTERTYPE_AF_JEWELRY_CRAFTING]           = SMITHING_FILTER_TYPE_JEWELRY,
        },

    },
    [LF_ENCHANTING_CREATION] = {
        [CRAFTING_TYPE_ENCHANTING] = {
            --TODO: Enable if itemfiltertype subfilters for the runes work: ITEMFILTERTYPE_AF_RUNES_ENCHANTING,
            --[[
            [ITEMFILTERTYPE_AF_RUNES_ENCHANTING]       = ENCHANTING_MODE_CREATION,
            ]]
            [ITEM_TYPE_DISPLAY_CATEGORY_ALL]                            = ENCHANTING_MODE_CREATION,
        },
    },
    [LF_ENCHANTING_EXTRACTION] = {
        [CRAFTING_TYPE_ENCHANTING] = {
            [ITEMFILTERTYPE_AF_GLYPHS_ENCHANTING]           = ENCHANTING_MODE_EXTRACTION,
        },
    },
    [LF_RETRAIT] = {
        [CRAFTING_TYPE_INVALID] = {
            [ITEMFILTERTYPE_AF_RETRAIT_WEAPONS] = SMITHING_FILTER_TYPE_WEAPONS,
            [ITEMFILTERTYPE_AF_RETRAIT_ARMOR]   = SMITHING_FILTER_TYPE_ARMOR,
            [ITEMFILTERTYPE_AF_RETRAIT_JEWELRY] = SMITHING_FILTER_TYPE_JEWELRY,
        },
    },
}
AF.mapIFT2CSFT = craftingTableAFFilterType2ESOFilterType

--Map the ESO filter type (selected filter button at the crafting table, or selected subfilter button, e.g. weapons) to the
--itemfilter type that is used for the AdvancedFilters filters (shown items)
local craftingTableESOFilterType2AFFilterType = {
    --[[
    [LF_SMITHING_CREATION] = {
        [CRAFTING_TYPE_BLACKSMITHING] = {
            [SMITHING_FILTER_TYPE_ARMOR]        = ITEMFILTERTYPE_AF_CREATE_ARMOR_SMITHING,
            [SMITHING_FILTER_TYPE_WEAPONS]      = ITEMFILTERTYPE_AF_CREATE_WEAPONS_SMITHING,
        },
        [CRAFTING_TYPE_CLOTHIER] = {
            [SMITHING_FILTER_TYPE_ARMOR]        = ITEMFILTERTYPE_AF_CREATE_ARMOR_CLOTHIER,
        },
        [CRAFTING_TYPE_WOODWORKING] = {
            [SMITHING_FILTER_TYPE_ARMOR]        = ITEMFILTERTYPE_AF_CREATE_ARMOR_WOODWORKING,
            [SMITHING_FILTER_TYPE_WEAPONS]      = ITEMFILTERTYPE_AF_CREATE_WEAPONS_WOODWORKING,
        },
    },
    ]]
    [LF_SMITHING_REFINE] = {
        [CRAFTING_TYPE_BLACKSMITHING] = {
            [SMITHING_FILTER_TYPE_RAW_MATERIALS] = ITEMFILTERTYPE_AF_REFINE_SMITHING,
        },
        [CRAFTING_TYPE_CLOTHIER] = {
            [SMITHING_FILTER_TYPE_RAW_MATERIALS] = ITEMFILTERTYPE_AF_REFINE_CLOTHIER,
        },
        [CRAFTING_TYPE_WOODWORKING] = {
            [SMITHING_FILTER_TYPE_RAW_MATERIALS] = ITEMFILTERTYPE_AF_REFINE_WOODWORKING,
        },
    },
    [LF_SMITHING_DECONSTRUCT] = {
        [CRAFTING_TYPE_BLACKSMITHING] = {
            [SMITHING_FILTER_TYPE_WEAPONS] = ITEMFILTERTYPE_AF_WEAPONS_SMITHING,
            [SMITHING_FILTER_TYPE_ARMOR] = ITEMFILTERTYPE_AF_ARMOR_SMITHING,
        },
        [CRAFTING_TYPE_CLOTHIER] = {
            [SMITHING_FILTER_TYPE_ARMOR] = ITEMFILTERTYPE_AF_ARMOR_CLOTHIER,
        },
        [CRAFTING_TYPE_WOODWORKING] = {
            [SMITHING_FILTER_TYPE_WEAPONS] = ITEMFILTERTYPE_AF_WEAPONS_WOODWORKING,
            [SMITHING_FILTER_TYPE_ARMOR] = ITEMFILTERTYPE_AF_ARMOR_WOODWORKING,
        },

    },
    [LF_SMITHING_IMPROVEMENT] = {
        [CRAFTING_TYPE_BLACKSMITHING] = {
            [SMITHING_FILTER_TYPE_WEAPONS] = ITEMFILTERTYPE_AF_WEAPONS_SMITHING,
            [SMITHING_FILTER_TYPE_ARMOR] = ITEMFILTERTYPE_AF_ARMOR_SMITHING,
        },
        [CRAFTING_TYPE_CLOTHIER] = {
            [SMITHING_FILTER_TYPE_ARMOR] = ITEMFILTERTYPE_AF_ARMOR_CLOTHIER,
        },
        [CRAFTING_TYPE_WOODWORKING] = {
            [SMITHING_FILTER_TYPE_WEAPONS] = ITEMFILTERTYPE_AF_WEAPONS_WOODWORKING,
            [SMITHING_FILTER_TYPE_ARMOR] = ITEMFILTERTYPE_AF_ARMOR_WOODWORKING,
        },
    },
    [LF_SMITHING_RESEARCH] = {
        [CRAFTING_TYPE_BLACKSMITHING] = {
            [SMITHING_FILTER_TYPE_WEAPONS] = ITEMFILTERTYPE_AF_WEAPONS_SMITHING,
            [SMITHING_FILTER_TYPE_ARMOR] = ITEMFILTERTYPE_AF_ARMOR_SMITHING,
        },
        [CRAFTING_TYPE_CLOTHIER] = {
            [SMITHING_FILTER_TYPE_ARMOR] = ITEMFILTERTYPE_AF_ARMOR_CLOTHIER,
        },
        [CRAFTING_TYPE_WOODWORKING] = {
            [SMITHING_FILTER_TYPE_WEAPONS] = ITEMFILTERTYPE_AF_WEAPONS_WOODWORKING,
            [SMITHING_FILTER_TYPE_ARMOR] = ITEMFILTERTYPE_AF_ARMOR_WOODWORKING,
        },
    },
    --[[
    [LF_JEWELRY_CREATION] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = {
            [ITEMFILTERTYPE_AF_CREATE_JEWELRY]                  = ITEMFILTERTYPE_AF_CREATE_JEWELRY,
        },

    },
    ]]
    [LF_JEWELRY_REFINE] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = {
            [SMITHING_FILTER_TYPE_RAW_MATERIALS] = ITEMFILTERTYPE_AF_REFINE_JEWELRY,
        },
    },
    [LF_JEWELRY_DECONSTRUCT] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = {
            [SMITHING_FILTER_TYPE_JEWELRY] = ITEMFILTERTYPE_AF_JEWELRY_CRAFTING,
        },

    },
    [LF_JEWELRY_IMPROVEMENT] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = {
            [SMITHING_FILTER_TYPE_JEWELRY] = ITEMFILTERTYPE_AF_JEWELRY_CRAFTING,
        },
    },
    [LF_JEWELRY_RESEARCH] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = {
            [SMITHING_FILTER_TYPE_JEWELRY] = ITEMFILTERTYPE_AF_JEWELRY_CRAFTING,
        },
    },
    [LF_ENCHANTING_CREATION] = {
        [CRAFTING_TYPE_ENCHANTING] = {
            [ENCHANTING_MODE_CREATION]  = ITEM_TYPE_DISPLAY_CATEGORY_ALL, --TODO: Enable if itemfiltertype subfilters for the runes work: ITEMFILTERTYPE_AF_RUNES_ENCHANTING,
        },
    },
    [LF_ENCHANTING_EXTRACTION] = {
        [CRAFTING_TYPE_ENCHANTING] = {
            [ENCHANTING_MODE_EXTRACTION] = ITEMFILTERTYPE_AF_GLYPHS_ENCHANTING,
        },
    },
    [LF_RETRAIT] = {
        [CRAFTING_TYPE_INVALID] = {
            [SMITHING_FILTER_TYPE_WEAPONS]  = ITEMFILTERTYPE_AF_RETRAIT_WEAPONS,
            [SMITHING_FILTER_TYPE_ARMOR]    = ITEMFILTERTYPE_AF_RETRAIT_ARMOR,
            [SMITHING_FILTER_TYPE_JEWELRY]  = ITEMFILTERTYPE_AF_RETRAIT_JEWELRY,
        },
    },
}
AF.mapCSFT2IFT = craftingTableESOFilterType2AFFilterType

--OTHER ADDONS
--Mapping for other addons like Harven's Stolen Filters
local customInventoryFilterButton2ItemType = {
    ["HarvensStolenFilter"] = ITEMFILTERTYPE_AF_STOLENFILTER,
    ["NTakLootSteal"]       = ITEMFILTERTYPE_AF_STOLENFILTER,
}
AF.customInventoryFilterButton2ItemType = customInventoryFilterButton2ItemType

--Map the custom addon itemFilterTypes to a LibFilters filterPanelId.
local customAddonItemFilterType2LibFiltersPanelId = {
    [ITEMFILTERTYPE_AF_STOLENFILTER] = LF_INVENTORY,
}
AF.customAddonItemFilterType2LibFiltersPanelId = customAddonItemFilterType2LibFiltersPanelId


--RESEARCH panel
--The indices of the research horizontal scrollList for the different weapontypes
local researchLineListIndicesOfWeaponOrArmorOrJewelryTypes = {
    [CRAFTING_TYPE_BLACKSMITHING] = {
        --Weapons
        [SMITHING_FILTER_TYPE_WEAPONS] = {
            --1hd
            [WEAPONTYPE_AXE]                = 0,
            [WEAPONTYPE_HAMMER]             = -1,
            [WEAPONTYPE_SWORD]              = -2,
            [WEAPONTYPE_DAGGER]             = -6,
            --2hd
            [WEAPONTYPE_TWO_HANDED_AXE]     = -3,
            [WEAPONTYPE_TWO_HANDED_HAMMER]  = -4,
            [WEAPONTYPE_TWO_HANDED_SWORD]   = -5,
        },
        --Armor
        [SMITHING_FILTER_TYPE_ARMOR] = {
            [EQUIP_TYPE_CHEST]      = 0, --
            [EQUIP_TYPE_FEET]       = -1, --
            [EQUIP_TYPE_HAND]       = -2, --
            [EQUIP_TYPE_HEAD]       = -3, --
            [EQUIP_TYPE_LEGS]       = -4, --
            [EQUIP_TYPE_SHOULDERS]  = -5, --
            [EQUIP_TYPE_WAIST]      = -6, --
        },
    },
    [CRAFTING_TYPE_WOODWORKING] = {
        --Weapons
        [SMITHING_FILTER_TYPE_WEAPONS] = {
            --2hd bow
            [WEAPONTYPE_BOW]                = 0,
            --2hd staffs
            [WEAPONTYPE_FIRE_STAFF]         = -1,
            [WEAPONTYPE_FROST_STAFF]        = -2,
            [WEAPONTYPE_LIGHTNING_STAFF]    = -3,
            [WEAPONTYPE_HEALING_STAFF]      = -4,
        },
        --Armor
        [SMITHING_FILTER_TYPE_ARMOR] = {
            --Shield
            [EQUIP_TYPE_OFF_HAND] =         0,
        }
    },
    [CRAFTING_TYPE_CLOTHIER] = {
        [SMITHING_FILTER_TYPE_ARMOR] = {
            [EQUIP_TYPE_CHEST]      = 0, --
            [EQUIP_TYPE_FEET]       = -1, --
            [EQUIP_TYPE_HAND]       = -2, --
            [EQUIP_TYPE_HEAD]       = -3, --
            [EQUIP_TYPE_LEGS]       = -4, --
            [EQUIP_TYPE_SHOULDERS]  = -5, --
            [EQUIP_TYPE_WAIST]      = -6, --
            [EQUIP_TYPE_CHEST]      = -7, --
            [EQUIP_TYPE_FEET]       = -8, --
            [EQUIP_TYPE_HAND]       = -9, --
            [EQUIP_TYPE_HEAD]       = -10, --
            [EQUIP_TYPE_LEGS]       = -11, --
            [EQUIP_TYPE_SHOULDERS]  = -12, --
            [EQUIP_TYPE_WAIST]      = -13, --
        }
    },
    [CRAFTING_TYPE_JEWELRYCRAFTING] = {
        [SMITHING_FILTER_TYPE_JEWELRY] = {
            [EQUIP_TYPE_NECK]       = 0,
            [EQUIP_TYPE_RING]       = -1,
        }
    },
}
AF.researchLineListIndicesOfWeaponOrArmorOrJewelryTypes = researchLineListIndicesOfWeaponOrArmorOrJewelryTypes

--The possible research lines and their item filter types
local blacksmithResearchLines = {
    --Weapons
    [1]=WEAPONTYPE_AXE, --
    [2]=WEAPONTYPE_HAMMER, --
    [3]=WEAPONTYPE_SWORD, --
    [4]=WEAPONTYPE_TWO_HANDED_AXE, --
    [5]=WEAPONTYPE_TWO_HANDED_HAMMER, --
    [6]=WEAPONTYPE_TWO_HANDED_SWORD, --
    [7]=WEAPONTYPE_DAGGER, --
    --Armor
    [8]=EQUIP_TYPE_CHEST, --
    [9]=EQUIP_TYPE_FEET, --
    [10]=EQUIP_TYPE_HAND, --
    [11]=EQUIP_TYPE_HEAD, --
    [12]=EQUIP_TYPE_LEGS, --
    [13]=EQUIP_TYPE_SHOULDERS, --
    [14]=EQUIP_TYPE_WAIST, --
}
local blacksmithResearchLinesArmorType = {
    --Armor
    [8]=ARMORTYPE_HEAVY, --
    [9]=ARMORTYPE_HEAVY, --
    [10]=ARMORTYPE_HEAVY, --
    [11]=ARMORTYPE_HEAVY, --
    [12]=ARMORTYPE_HEAVY, --
    [13]=ARMORTYPE_HEAVY, --
    [14]=ARMORTYPE_HEAVY, --
}
local clothierResearchLines = {
    --Light armor
    [1]=EQUIP_TYPE_CHEST, --
    [2]=EQUIP_TYPE_FEET, --
    [3]=EQUIP_TYPE_HAND, --
    [4]=EQUIP_TYPE_HEAD, --
    [5]=EQUIP_TYPE_LEGS, --
    [6]=EQUIP_TYPE_SHOULDERS, --
    [7]=EQUIP_TYPE_WAIST, --
    --Medium armor
    [8]=EQUIP_TYPE_CHEST, --
    [9]=EQUIP_TYPE_FEET, --
    [10]=EQUIP_TYPE_HAND, --
    [11]=EQUIP_TYPE_HEAD, --
    [12]=EQUIP_TYPE_LEGS, --
    [13]=EQUIP_TYPE_SHOULDERS, --
    [14]=EQUIP_TYPE_WAIST, --
}
local clothierResearchLinesArmorTypes = {
    --Light Armor
    [1]=ARMORTYPE_LIGHT, --
    [2]=ARMORTYPE_LIGHT, --
    [3]=ARMORTYPE_LIGHT, --
    [4]=ARMORTYPE_LIGHT, --
    [5]=ARMORTYPE_LIGHT, --
    [6]=ARMORTYPE_LIGHT, --
    [7]=ARMORTYPE_LIGHT, --
    --Medium armor
    [8]=ARMORTYPE_MEDIUM, --
    [9]=ARMORTYPE_MEDIUM, --
    [10]=ARMORTYPE_MEDIUM, --
    [11]=ARMORTYPE_MEDIUM, --
    [12]=ARMORTYPE_MEDIUM, --
    [13]=ARMORTYPE_MEDIUM, --
    [14]=ARMORTYPE_MEDIUM, --
}
local woodworkingResearchLines = {
    --Weapons
    [1]=WEAPONTYPE_BOW,             -- Bow
    [2]=WEAPONTYPE_FIRE_STAFF,      -- Fire staff
    [3]=WEAPONTYPE_FROST_STAFF,     -- Ice staff
    [4]=WEAPONTYPE_LIGHTNING_STAFF, -- Lightning staff
    [5]=WEAPONTYPE_HEALING_STAFF,   -- Heal staff
    --Armor
    [6]=EQUIP_TYPE_OFF_HAND,        -- Shield
}
local woodworkingResearchLinesArmorType = {
    --Armor
    [6]=ARMORTYPE_NONE,             -- Shield
}
local jewelryCraftingResearchLines = {
    --Neck
    [1] = EQUIP_TYPE_NECK,
    --Ring
    [2] = EQUIP_TYPE_RING,
}
AF.researchLinesToFilterTypes = {}
AF.researchLinesToFilterTypes[CRAFTING_TYPE_BLACKSMITHING]  = blacksmithResearchLines
AF.researchLinesToFilterTypes[CRAFTING_TYPE_CLOTHIER]       = clothierResearchLines
AF.researchLinesToFilterTypes[CRAFTING_TYPE_WOODWORKING]    = woodworkingResearchLines
AF.researchLinesToFilterTypes[CRAFTING_TYPE_JEWELRYCRAFTING]= jewelryCraftingResearchLines
AF.researchLinesToArmorType = {}
AF.researchLinesToArmorType[CRAFTING_TYPE_BLACKSMITHING]    = blacksmithResearchLinesArmorType
AF.researchLinesToArmorType[CRAFTING_TYPE_CLOTHIER]         = clothierResearchLinesArmorTypes
AF.researchLinesToArmorType[CRAFTING_TYPE_WOODWORKING]      = woodworkingResearchLinesArmorType

--ITEM IDs
local itemIds = {
    lockpick    = {
        30357--normal lockpick
    },
    repairtools = {
        44874, --Smallest repair kit
        44875, --Smaller repair kit
        44876, --Lower repair kit
        44877, --Common repair kit
        44878, --Greater repair kit
        44879, --Big repair kit
        157516 --GroupRepair of the Impressaria event
    }
}
AF.itemIds = itemIds

--Table where external dropdown filter plugins can register themselves for checks done by other addos
AF.externalDropdownFilterPlugins = {}

--Mapping for the older ITEMFILTERTYPE_* variables to the new ZOs API100033 ITEM_TYPE_DISPLAY_CATEGORY
--https://github.com/esoui/esoui/blob/pts6.2/esoui/ingame/inventory/itemfilterutils.lua#L692
--ZO_ItemFilterUtils.GetItemTypeDisplayCategoryByItemFilterType(itemFilterType)
-->ITEM_FILTER_UTILS:GetItemTypeDisplayCategoryByItemFilterType(itemFilterType)
--[[
AF.itemDisplayCategoryToItemFilterType = {
    --Normal Inventory
    [ITEM_TYPE_DISPLAY_CATEGORY_ALL]            = ITEMFILTERTYPE_ALL,
    [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS]        = ITEMFILTERTYPE_WEAPONS,
    [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR]          = ITEMFILTERTYPE_ARMOR,
    [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY]        = ITEMFILTERTYPE_JEWELRY,
    [ITEM_TYPE_DISPLAY_CATEGORY_CONSUMABLE]     = ITEMFILTERTYPE_CONSUMABLE,
    [ITEM_TYPE_DISPLAY_CATEGORY_CRAFTING]       = ITEMFILTERTYPE_CRAFTING,
    [ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING]     = ITEMFILTERTYPE_FURNISHING,
    [ITEM_TYPE_DISPLAY_CATEGORY_MISCELLANEOUS]  = ITEMFILTERTYPE_MISCELLANEOUS,
    [ITEM_TYPE_DISPLAY_CATEGORY_QUEST]          = ITEMFILTERTYPE_QUEST,
    [ITEM_TYPE_DISPLAY_CATEGORY_JUNK]           = ITEMFILTERTYPE_JUNK,
    --CraftBag
    [ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING]  = ITEMFILTERTYPE_BLACKSMITHING,
    [ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING]       = ITEMFILTERTYPE_CLOTHING,
    [ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING]    = ITEMFILTERTYPE_WOODWORKING,
    [ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY]        = ITEMFILTERTYPE_ALCHEMY,
    [ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING]     = ITEMFILTERTYPE_ENCHANTING,
    [ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING]   = ITEMFILTERTYPE_PROVISIONING,
    [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING]= ITEMFILTERTYPE_JEWELRYCRAFTING,
    [ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL] = ITEMFILTERTYPE_STYLE_MATERIALS,
    [ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM]     = ITEMFILTERTYPE_TRAIT_ITEMS,
}
]]
