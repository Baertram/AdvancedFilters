-- News check translations by @XXXspartiateXXX 2022/05

local util = AdvancedFilters.util
local enStrings = AdvancedFilters.ENstrings

local afPrefixNormal    = enStrings.AFPREFIXNORMAL
local afPrefixError     = string.format(enStrings.AFPREFIX, " ERREUR")

local strings = {
    --ARMES
    OneHand = "Une main",
    TwoHand = "Deux mains",
    TwoHandAxe = "2M "..util.Localize(SI_WEAPONTYPE1),
    TwoHandSword = "2M "..util.Localize(SI_WEAPONTYPE3),
    TwoHandHammer = "2M "..util.Localize(SI_WEAPONTYPE2),

    --CONSOMMABLES
    Repair = "Réparation",

    --MATÉRIAUX
    Clothier = "Couture",

    WeaponTrait = "Trait d'arme",
    ArmorTrait = "Trait d'armure",
    Water = "Eau",
    Oil = "Huile",

    --MENU CONTEXTUEL DÉROULANT
    ResetToAll           = "Tout réinitialiser",
    InvertDropdownFilter = "Inverser le filtre: %s",

    --Menu des paramètres LAM
    lamDescription = "Affiche des boutons de filtre supplémentaires dans les inventaires pour séparer les types d'éléments",
    lamHideItemCount = "Masquer le compteur d'objet",
    lamHideItemCountTT = "Masque le nombre d'objets présents dans la sous-catégorie (affiché entre parenthèses en bas de l'inventaire à côté du nombre d'objet total).",
    lamHideItemCountColor = "Couleur du compteur d'objet",
    lamHideItemCountColorTT = "Détermine la couleur du compteur d'objet affiché en bas de l'inventaire.",
    lamHideSubFilterLabel = "Masquer le nom de la sous-catégorie",
    lamHideSubFilterLabelTT = "Masque le texte indiquant le nom de la sous-catégorie (affiché en haut de l'inventaire à gauche).",
    lamGrayOutSubFiltersWithNoItems = "Désactiver les sous-catégories sans objets",
    lamGrayOutSubFiltersWithNoItemsTT = "Masque le bouton des sous-catégories ne comportant aucun objet.",
    lamShowIconsInFilterDropdowns = "Afficher les icônes du menu déroulant",
    lamShowIconsInFilterDropdownsTT = "Affiche les icônes des sous-catégories d'objet dans la liste déroulante de filtrage par type d'objet.",
    lamRememberFilterDropdownsLastSelection = "Mémoriser la dernière sélection du menu des filtres",
    lamRememberFilterDropdownsLastSelectionTT = "Rappelez-vous la dernière liste déroulante de filtre à chaque sous-filtre et panneau de filtre (inventaire, courrier, table d'artisanat, ...) et réappliquez ce filtre dans l'entrée de la liste déroulante si vous revenez à ce panneau de filtre et sous-filtre.\nCeci ne sera PAS enregistré si vous vous déconnecter/faites un rechargement de l'interface utilisateur !",
    lamShowDropdownSelectedReminderAnimation = "Éclairer la liste déroulante du dernier filtre",
    lamShowDropdownSelectedReminderAnimationTT = "Fais briller la liste déroulante lorsque vous passez à une barre de sous-filtre, où le filtre de la liste déroulante est sélectionné et n'affiche pas \'".. util.Localize(SI_ITEMFILTERTYPE0) .. "\' l'entrée.",
    lamShowDropdownLastSelectedEntries = "Afficher l'historique de sélection de la liste déroulante des filtres",
    lamShowDropdownLastSelectedEntriesTT = "Cliquez avec le bouton droit sur la liste déroulante du filtre pour afficher une liste des 10 dernières entrées de liste déroulante sélectionnées sous les entrées du menu contextuel standard. Cliquez sur une entrée d'historique pour la sélectionner à nouveau (si la liste déroulante de la barre de sous-filtre actuelle fournit cette entrée car l'historique est créé entre les barres de sous-filtre) !",
    lamHideCharBoundAtBankDeposit = "Masquer les objets liés aux personnages à la banque",
    lamHideCharBoundAtBankDepositTT = "Masquer les éléments liés aux personnages dans l'onglet Dépôt bancaire.",
    lamShowFilterDropdownMenuOnRightMouse   = "|t150.000000%:150.000000%:EsoUI/Art/Miscellaneous/icon_RMB.dds|t: Afficher les filtres du menu sur le bouton",
    lamShowFilterDropdownMenuOnRightMouseTT = "Afficher les mêmes filtres, que les filtres de la liste déroulante afficheraient si vous l'ouvriez sur le bouton de sous-filtre actuel.\n\n|t100.000000%:100.000000%:EsoUI/Art/Miscellaneous/icon_RMB.dds|t : Afficher le plugin normal menu des filtres\ntouche SHIFT + |t100.000000%:100.000000%:EsoUI/Art/Miscellaneous/icon_RMB.dds|t : Afficher le menu des filtres du plugin par clic droit.",
    lamHeaderVisual = "Visuel",
    lamHeaderFilterCategory = "Filtrer les catégories",
    lamHeaderSubfilter = "Boutons de sous-filtre",
    lamHeaderDropdownFilterbox = "Boîte de filtre déroulante",
    lamDebugOutput = "Déboguage",
    lamDebugOutputTT = "Affiche certains messages de débogage dans le Tchat utilisateur/DebugLogViewer UI.",
    lamDebugSpamOutput = "Déboguer les spams",
    lamDebugSpamOutputTT = "Attention : cela va spammer votre Tchat/DebugLogViewer UI avec beaucoup de messages d'AdvancedFilters. N'activez cette option que si on vous a dit de le faire !",
    lamDebugSpamExcludeRefreshSubfilterBar = "Exclure: \'Rafraîchir la barre de sous-filtre\'",
    lamDebugSpamExcludeDropdownBoxFilters = "Exclure: \'Filtres déroulants\'",

    --Messages d'erreur
    errorCheckChatPlease    = afPrefixError .. " Veuillez lire le message d'erreur du Tchat !",
    errorLibraryMissing     = afPrefixError .. " La bibliothèque requise \'%s\' n'est pas chargée. Cet addon ne fonctionnera pas correctement !",
    errorWhatToDo1          = "!> Veuillez répondre aux 4 questions suivantes et envoyer les réponses (et si elles sont données : les variables affichées dans les lignes, en commençant par ->, après les questions) aux commentaires de l'addon AdvancedFilters @www.esoui.com:\nhttps://bit.ly/2lSbb2A",
    errorWhatToDo2          = "1) Qu'avez-vous fait ?\n2)Où l'avez-vous fait ?\n3)Avez-vous testé si l'erreur se produit uniquement avec l'addon AdvancedFilters et les bibliothèques activées (veuillez tester ceci !) ?\n4)Si l'erreur se produit avec d'autres addons actifs : Quels autres addons utilisiez-vous lorsque l'erreur s'est produite, et êtes-vous en mesure de dire lequel de ceux-ci est à l'origine de l'erreur ?",

    --Erreurs dues à d'autres addons
    errorOtherAddonsMulticraft = afPrefixError .. "Autre addon cassé\'" .. afPrefixNormal .. "\' -> VEUILLEZ DÉSACTIVER CET ADDON: \'MultiCraft\' !",
    errorOtherAddonsMulticraftLong = "VEUILLEZ DÉSACTIVER CET ADDON \'MultiCraft\' ! " .. afPrefixNormal .. " ne peut pas fonctionner si cet addon est activé. \'Multicraft\' a été remplacé par la propre interface utilisateur multi-artisanat de ZOS, vous n'en avez donc plus besoin !"
}

setmetatable(strings, {__index = enStrings})
AdvancedFilters.strings = strings
