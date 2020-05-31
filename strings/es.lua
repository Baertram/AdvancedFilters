local util = AdvancedFilters.util
local enStrings = AdvancedFilters.ENstrings

local afPrefixNormal    = enStrings.AFPREFIXNORMAL
local afPrefixError     = string.format(enStrings.AFPREFIX, " ERROR")

local strings = {
     --WEAPON
    OneHand = "Una Mano",
    TwoHand = "Dos Manos",
    DestructionStaff = "Vara de destrucci\195\179n",

    TwoHandAxe = "2H "..util.Localize(SI_WEAPONTYPE1),
    TwoHandSword = "2H "..util.Localize(SI_WEAPONTYPE3),
    TwoHandHammer = "2H "..util.Localize(SI_WEAPONTYPE2),

    --Clothing = ,
    Shield = "Escudos",
    Jewelry = "Joyas",
    Vanity = "Varios",

    Head = "Cabeza",
    Chest = "Pecho",
    Shoulders = "Hombros",
    Hand = "Manos",
    Waist = "Cintura",
    Legs = "Piernas",
    Feet = "Pies",
    Ring = "Anillo",
    Neck = "Cuello",

    Repair = "Reparaci\195\179n",

    --MATERIALS
    Blacksmithing = "Herrer\195\173a",
    Clothier = "Sastrer\195\173a",
    Woodworking = "Carpinter\195\173a",
    Alchemy = "Alquimia",
    Enchanting = "Encantamiento",
    Provisioning = "Cocina",

    --MISCELLANEOUS
    Glyphs = "Glifos",
    Bait = "Cebo",

    --DROPDOWN CONTEXT MENU
    ResetToAll           = "Mostrar todo",
    InvertDropdownFilter = "Filtro invertido: %s",
}

local light = " (ligera)"
local medium = " (media)"
strings.Head_Light = strings.Head ..  light
strings.Chest_Light = strings.Chest ..  light
strings.Shoulders_Light = strings.Shoulders ..  light
strings.Hand_Light = strings.Hand ..  light
strings.Waist_Light = strings.Waist ..  light
strings.Legs_Light = strings.Legs ..  light
strings.Feet_Light = strings.Feet ..  light
strings.Head_Light = strings.Head ..  medium
strings.Chest_Medium = strings.Chest ..  medium
strings.Shoulders_Medium = strings.Shoulders ..  medium
strings.Hand_Medium = strings.Hand ..  medium
strings.Waist_Medium = strings.Waist ..  medium
strings.Legs_Medium = strings.Legs ..  medium
strings.Feet_Medium = strings.Feet ..  medium
local ringStr = " (" .. strings.Ring .. ")"
strings.Arcane_Ring = strings.Arcane .. ringStr
strings.Bloodthirsty_Ring = strings.Bloodthirsty .. ringStr
strings.Harmony_Ring = strings.Harmony .. ringStr
strings.Healthy_Ring = strings.Healthy .. ringStr
strings.Infused_Ring = strings.Infused .. ringStr
strings.Intricate_Ring = strings.Intricate .. ringStr
strings.Ornate_Ring = strings.Ornate .. ringStr
strings.Robust_Ring = strings.Robust .. ringStr
strings.Swift_Ring = strings.Swift .. ringStr
strings.Triune_Ring = strings.Triune .. ringStr
local neckStr = " (" .. strings.Neck .. ")"
strings.Arcane_Neck = strings.Arcane .. neckStr
strings.Bloodthirsty_Neck = strings.Bloodthirsty .. neckStr
strings.Harmony_Neck = strings.Harmony .. neckStr
strings.Healthy_Neck = strings.Healthy .. neckStr
strings.Infused_Neck = strings.Infused .. neckStr
strings.Intricate_Neck = strings.Intricate .. neckStr
strings.Ornate_Neck = strings.Ornate .. neckStr
strings.Robust_Neck = strings.Robust .. neckStr
strings.Swift_Neck = strings.Swift .. neckStr
strings.Triune_Neck = strings.Triune .. neckStr

setmetatable(strings, {__index = enStrings})
AdvancedFilters.strings = strings
