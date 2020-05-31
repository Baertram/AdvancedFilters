local util = AdvancedFilters.util
local enStrings = AdvancedFilters.ENstrings

local afPrefixNormal    = enStrings.AFPREFIXNORMAL
local afPrefixError     = string.format(enStrings.AFPREFIX, " FEHLER")

local strings = {
    TwoHandAxe = util.Localize(zo_strformat("<<1>> <<2>>", GetString(SI_EQUIPTYPE6), GetString(SI_WEAPONTYPE1))),
    TwoHandSword = util.Localize(zo_strformat("<<1>> <<2>>", GetString(SI_EQUIPTYPE6), GetString(SI_WEAPONTYPE3))),
    TwoHandHammer = util.Localize(zo_strformat("<<1>> <<2>>", GetString(SI_EQUIPTYPE6), GetString(SI_WEAPONTYPE2))),
    Shield = zo_strformat("<<m:1>>", GetString(SI_ITEMSTYLECHAPTER13)),

    ResetToAll           = util.Localize(SI_ITEMFILTERTYPE0) .. " anzeigen",
    InvertDropdownFilter = "Filter umdrehen: %s",

    --LAM settings menu
    lamDescription = "Zeige zusätzliche Filter Kategorien in den Inventaren, um Gegenstandstypen zu unterscheiden",
    lamHideItemCount = "Verstecke Gegenstand Anzahl",
    lamHideItemCountTT = "Versteckt die Gegenstand Anzahl, welche als \"(...)\" am unteren Inventar Rand angezeigt wird",
    lamHideItemCountColor = "Farbe der Gegenstand Anzahl",
    lamHideItemCountColorTT = "Setze die Farbe der Gegenstand Anzahl",
    lamHideSubFilterLabel = "Verstecke Filter Kategorie Label",
    lamHideSubFilterLabelTT = "Versteckt den Filter Kategorie Beschreibungstext Label, welcher sich links am Inventar Rand befindet",
    lamGrayOutSubFiltersWithNoItems = "Deaktiviere Kategorien ohne Gegenstände",
    lamGrayOutSubFiltersWithNoItemsTT = "Deaktiviert die Filter Kategorien, welche aktuell keine Gegegnstände besitzen.",
    lamShowIconsInFilterDropdowns = "Zeige Symbole in Filter Boxen",
    lamShowIconsInFilterDropdownsTT = "Zeige Symbole in den Filter Aufklapp Boxen an",
    lamRememberFilterDropdownsLastSelection = "Merke letzte Filter Box Auswahl",
    lamRememberFilterDropdownsLastSelectionTT = "Merkt sich je Unterfilter und Filter Panel (Inventar, Mail senden, Handerksstation, ...) die letzte Filter Box Auswahl und stellt diese wieder her, wenn du den Unterfilter auf diesem Filter Panel das nächste mal besuchst.\NDies wird NICHT über eine Ausloggen/Benutzeroberfläche Neuladen hinweg gemerkt!",

    --Error messages
    errorCheckChatPlease    = afPrefixError .. " Bitte lese die Fehlermeldung im Chat!",
    errorLibrayMissing      = afPrefixError .. " Benötigte Bibliothek \'%s\' ist nicht aktiviert. Dieses AddOn funktioniert nicht ohne diese!",
    errorWhatToDo1          = "!> Bitte beantworte die folgenden 4 Fragen und schreibe die Antworten (und wenn verfügbar: die Variablen, welche in den Chat Zeilen nach den Fragen mit -> beginnen) in den AddOn Kommentaren von AdvancedFilters @www.esoui.com:\nhttps://bit.ly/2lSbb2A",
    errorWhatToDo2          = "1) Was hast du gemacht als der Fehler auftrat?\n2)Wo hast du es gemacht?\n3)Hast du ausprobiert, ob der Fehler auch auftritt, wenn NUR das AddOn AdvancedFilters und die Bibliotheken aktiv sind (Bitte teste dies unbedingt!)?\n4)Wenn der Fehler mit anderen AddOns aktiv auftritt: Welche anderen AddOns waren aktiv, und kannst du eingrenzen welches es verursacht?",

    --Errors because of other addons
    errorOtherAddonsMulticraft = afPrefixError .. "Ein anderes AddOn stört \'" .. afPrefixNormal .. "\' -> BITTE DEAKTIVIER DAS FOLGENDE AddOn: \'MultiCraft\'!",
    errorOtherAddonsMulticraftLong = "BITTE DEAKTIVIERE DAS ADDON \'MultiCraft\'! " .. afPrefixNormal .. " funktioniert nicht wenn dieses AddOn aktiviert ist. \'Multicraft\' wurde außerdem durch die ZOs eigene Multi-Craft Handwerks UI ersetzt und wird daher nicht mehr benötigt!"
}
setmetatable(strings, {__index = enStrings})
AdvancedFilters.strings = strings
