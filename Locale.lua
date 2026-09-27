ComfyMaps = ComfyMaps or {}
local A=ComfyMaps
local de=GetLocale and GetLocale()=="deDE"

local EN={
    TAB_GENERAL="Maps",TAB_INFO="Info",ADDON_ENABLED="Enable ComfyMaps",
    INFO_VERSION="Version",INFO_BUILD_DATE="Build date",INFO_STATUS="Status",INFO_CLIENT="Current client",
    INFO_TESTED_TARGET="Tested target",INFO_COMPAT_STATUS="Compatibility",INFO_AUTHOR="Author",
    INFO_DISCORD="Discord",INFO_GITHUB="GitHub",INFO_COMMANDS="Slash commands",
    COMPAT_MATCH="Compatible",COMPAT_UPDATE_REQUIRED="Interface differs from the tested target",
    INFO_NOTICE="ComfyMaps owns world-map presentation for the Comfy Suite. Other Comfy addons can provide map data without modifying the map independently.",
    INFO_THANKS="Thanks for using ComfyMaps! Feedback and bug reports are welcome via Discord.",

    CAT_MAP="World map",CAT_COORDS="Coordinates",CAT_DATA="Comfy data",
    MAP_SCALE="World map scale",MAP_OPACITY="World map opacity",
    FADE_MOVING="Reduce map opacity while moving",MOVING_OPACITY="Opacity while moving",
    HIDE_BORDER="Hide decorative map border",
    UNLOCK_MAP="Unlock map position",REMEMBER_POSITION="Remember map position",RESET_POSITION="Reset map position",
    PLAYER_COORDS="Show player coordinates",CURSOR_COORDS="Show cursor coordinates",
    GATHERER_PINS="Show ComfyGatherer nodes on world map",
    GATHERER_PIN_SIZE="Gatherer pin size",MAX_GATHERER_PINS="Maximum Gatherer pins",
    DRAG_HANDLE="Drag map",
    NO_MAP_API="World map frame/API not available yet.",
    FOREVER_NOTE="0.1 focuses on safe map presentation, coordinates and ComfyGatherer integration. POIs, exploration reveal and deeper zoom controls will be added only after Forever runtime validation.",
}
local DE={
    TAB_GENERAL="Karten",TAB_INFO="Info",ADDON_ENABLED="ComfyMaps aktivieren",
    INFO_VERSION="Version",INFO_BUILD_DATE="Build-Datum",INFO_STATUS="Status",INFO_CLIENT="Aktueller Client",
    INFO_TESTED_TARGET="Getestetes Ziel",INFO_COMPAT_STATUS="Kompatibilität",INFO_AUTHOR="Autor",
    INFO_DISCORD="Discord",INFO_GITHUB="GitHub",INFO_COMMANDS="Slash-Befehle",
    COMPAT_MATCH="Kompatibel",COMPAT_UPDATE_REQUIRED="Interface weicht vom getesteten Ziel ab",
    INFO_NOTICE="ComfyMaps übernimmt die Darstellung der Weltkarte für die Comfy Suite. Andere Comfy-Addons können Kartendaten liefern, ohne die Karte selbst umzubauen.",
    INFO_THANKS="Danke, dass du ComfyMaps nutzt! Feedback und Fehlermeldungen sind über Discord willkommen.",

    CAT_MAP="Weltkarte",CAT_COORDS="Koordinaten",CAT_DATA="Comfy-Daten",
    MAP_SCALE="Skalierung der Weltkarte",MAP_OPACITY="Deckkraft der Weltkarte",
    FADE_MOVING="Karte beim Laufen transparenter machen",MOVING_OPACITY="Deckkraft beim Laufen",
    HIDE_BORDER="Dekorativen Kartenrand ausblenden",
    UNLOCK_MAP="Kartenposition entsperren",REMEMBER_POSITION="Kartenposition merken",RESET_POSITION="Kartenposition zurücksetzen",
    PLAYER_COORDS="Spielerkoordinaten anzeigen",CURSOR_COORDS="Mauskoordinaten anzeigen",
    GATHERER_PINS="ComfyGatherer-Punkte auf der Weltkarte anzeigen",
    GATHERER_PIN_SIZE="Größe der Gatherer-Punkte",MAX_GATHERER_PINS="Maximale Gatherer-Punkte",
    DRAG_HANDLE="Karte ziehen",
    NO_MAP_API="Weltkarten-Frame/API ist noch nicht verfügbar.",
    FOREVER_NOTE="0.1 konzentriert sich auf sichere Kartendarstellung, Koordinaten und ComfyGatherer-Integration. POIs, Map-Reveal und tieferer Zoom folgen erst nach Forever-Laufzeittests.",
}
local S=de and DE or EN
function A:T(k) return S[k] or EN[k] or k end
