-- Faction Relations - Live PDA Tab
-- Shows how the factions of the Zone relate to you and to each other.
-- Requires UE4SS.

local UEHelpers = require("UEHelpers")
local ENTWICKLER = false

local TAG = "[FMTX]"
local VERSION = "2.5.1"
local function p(s) print(TAG .. " " .. s .. "\n") end

local SPRACHE = "en"
local spracheGeprueft = false

local TEXTE = {
    de = {
        reiter  = "Fraktionen",
        titel   = "Fraktionsbeziehungen",
        spieler = "Spieler",
        wort    = { [0]="feindlich", [1]="misstrauisch", [2]="neutral", [3]="freundlich" },
        legende = "freundlich = einer der ihren        neutral = laesst dich in Ruhe        "
               .. "misstrauisch = geduldet, beobachtet        feindlich = Feuer ohne Warnung",
        fehler  = "MOD FEHLERHAFT INSTALLIERT - es wird nichts gemessen, die Tabelle zeigt nur Vorgabewerte",
    },
    en = {
        reiter  = "Factions",
        titel   = "Faction Relations",
        spieler = "Player",
        wort    = { [0]="hostile", [1]="wary", [2]="neutral", [3]="friendly" },
        legende = "friendly = one of their own        neutral = leaves you alone        "
               .. "wary = tolerated, watched        hostile = shoots on sight",
        fehler  = "MOD NOT INSTALLED CORRECTLY - nothing is being measured, the table shows default values only",
    },
    uk = {
        reiter  = "Фракції",
        titel   = "Стосунки фракцій",
        spieler = "Гравець",
        wort    = { [0]="вороже", [1]="насторожено", [2]="нейтрально", [3]="дружньо" },
        legende = "дружньо = свій        нейтрально = не чіпають        "
               .. "насторожено = терплять, стежать        вороже = стріляють без попередження",
        fehler  = "МОД ВСТАНОВЛЕНО НЕПРАВИЛЬНО - вимірювання не працює, таблиця показує стандартні значення",
    },
    ru = {
        reiter  = "Фракции",
        titel   = "Отношения фракций",
        spieler = "Игрок",
        wort    = { [0]="враждебно", [1]="настороже", [2]="нейтрально", [3]="дружелюбно" },
        legende = "дружелюбно = свой        нейтрально = не трогают        "
               .. "настороже = терпят, следят        враждебно = стреляют без предупреждения",
        fehler  = "МОД УСТАНОВЛЕН НЕПРАВИЛЬНО - измерение не работает, таблица показывает значения по умолчанию",
    },
    pl = {
        reiter  = "Frakcje",
        titel   = "Relacje frakcji",
        spieler = "Gracz",
        wort    = { [0]="wrogo", [1]="nieufnie", [2]="neutralnie", [3]="przyjaźnie" },
        legende = "przyjaźnie = jeden ze swoich        neutralnie = nie zaczepiają        "
               .. "nieufnie = tolerują, obserwują        wrogo = strzelają bez ostrzeżenia",
        fehler  = "MOD ZAINSTALOWANY NIEPRAWIDŁOWO - nic nie jest mierzone, tabela pokazuje wartości domyślne",
    },
    sr = {
        reiter  = "Фракције",
        titel   = "Фракцијски односи",
        spieler = "Играч",
        wort    = { [0]="непријатељски", [1]="неповерљиви", [2]="неутрални", [3]="пријатељски" },
        legende = "пријатељски = сматрају те својим        неутрални = остављају те на миру        "
               .. "неповерљиви = трпе те, али те држе на оку        непријатељски = пуцају без упозорења",
        fehler  = "МОД НИЈЕ ИСПРАВНО ИНСТАЛИРАН - ништа се не мери, табела приказује само подразумеване вредности",
        kurz    = { Duty="Дужност", Freedom="Слобода", Ward="Стража", Loners="Самотњаци",
                    Scientists="Научници", Spark="Искра", Corps="Корпус", Noontide="Подне",
                    Military="Војска", Mercenaries="Плаћеници", Bandits="Бандити", Monolith="Монолит" },
    },
}
local L = TEXTE[SPRACHE]

local SICHTBAR = 0
local ZIEL     = "bestiary"
local TITEL = L.reiter

local RAND_L   = 44.0
local RAND_O   = 26.0
local SP_NAME  = 190.0
local SP_WERT  = 124.0

local KURZ = { L.spieler,"Duty","Freedom","Ward","Loners","Scientists","Spark",
               "Corps","Noontide","Military","Mercenaries","Bandits","Monolith" }

local function anzeigeName(name) return (L.kurz and L.kurz[name]) or name end

local M = {
  {  999,    0,    0,    0,    0,    0,    0,    0,    0, -800, -800, -800, -800 },
  {    0,  600, -599,  201,    0,  201,    0,  201, -599,    0, -799, -800, -800 },
  {    0, -599,  600,    0,    0,    0,    0,    0, -599, -799, -599, -800, -800 },
  {    0,  201,    0,  600, -399,    0, -599,    0, -399,    0, -599, -800, -800 },
  {    0,    0,    0, -399,  600,    0,    0,    0, -599, -800, -799, -800, -800 },
  {    0,  201,    0,    0,    0,  600,  201,  201,    0,  201,    0, -800, -800 },
  {    0,    0,    0, -599,    0,  201,  600,    0, -599, -800, -799, -800, -800 },
  {    0,  201,    0,    0,    0,  201,    0,  600, -599,    0, -799, -800, -800 },
  {    0, -599, -599, -399, -599,    0, -599, -599,  600, -800, -799, -800, -800 },
  { -800,    0, -799,    0, -800,  201, -800,    0, -800,  600, -800, -800, -800 },
  { -800, -799, -599, -599, -799,    0, -799, -799, -799, -800,  600, -599, -800 },
  { -800, -800, -800, -800, -800, -800, -800, -800, -800, -800, -599,  600, -800 },
  { -800, -800, -800, -800, -800, -800, -800, -800, -800, -800, -800, -800,  600 },
}

local function stufe(w)
    if w == 999  then return nil end
    if w <= -800 then return 0 end
    if w <= -201 then return 1 end
    if w <=  200 then return 2 end
    return 3
end

local function sc(r, g, b, a)
    return { SpecifiedColor = {R=r, G=g, B=b, A=a or 1.0}, ColorUseRule = 0 }
end

local C_TITEL  = sc(0.591, 0.521, 0.434)
local C_UNTER  = sc(0.571, 0.558, 0.515)
local C_KOPF   = sc(0.571, 0.558, 0.515)
local C_LINIE  = {R=0.42, G=0.37, B=0.30, A=1.0}
local C_EIGEN  = sc(0.246, 0.220, 0.175)
local C_NAME   = sc(0.591, 0.521, 0.434)
local C_LEG    = sc(0.515, 0.509, 0.418)
local C_KOPFH  = sc(0.831, 0.815, 0.768)
local TEX_GRUND = "/Game/GameLite/FPS_Game/UIRemaster/UITextures/PDA/PDAView/QuestBackground/T_pda_main_background.T_pda_main_background"
local TEX_LINIE = "/Game/GameLite/FPS_Game/UIRemaster/UITextures/PDA/Stats/T_Header_Separator.T_Header_Separator"
local C_GRUND  = {R=0.005, G=0.005, B=0.006, A=1.0}
local FARBE = {
    [0] = sc(0.768, 0.095, 0.095),
    [1] = sc(0.745, 0.361, 0.047),
    [2] = sc(0.515, 0.509, 0.418),
    [3] = sc(0.45, 0.78, 0.48),
}

local C_ZEBRA   = {R=1.0, G=0.93, B=0.78, A=0.022}
local C_SPIELER = {R=1.0, G=0.93, B=0.78, A=0.048}
local C_WARN    = sc(0.768, 0.095, 0.095)

local logGemeldet = false
local markenGesamt = 0
local LOGPFAD = (os.getenv("LOCALAPPDATA") or "")
                .. "/Stalker2/Saved/Logs/Stalker2.log"
local WORT = L.wort
local IDX = { Player=1, Duty=2, Freedom=3, Varta=4, Neutrals=5, Scientists=6, Spark=7,
              Corpus=8, Noon=9, Militaries=10, Mercenaries=11, Bandits=12, Monolith=13 }
local ZEILE = { [0]="Player", [1]="Bandits", [2]="Bandits", [3]="Bandits", [4]="Corpus", [5]="Corpus", [6]="Corpus", [7]="Duty", [8]="Duty", [9]="Duty", [10]="Freedom", [11]="Freedom", [12]="Freedom", [13]="Mercenaries", [14]="Militaries", [15]="Militaries", [16]="Militaries", [17]="Neutrals", [18]="Neutrals", [19]="Neutrals", [20]="Noon", [21]="Noon", [22]="Noon", [23]="Scientists", [24]="Scientists", [25]="Scientists", [26]="Spark", [27]="Spark", [28]="Spark", [29]="Varta", [30]="Varta", [31]="Varta" }
local SPALTE = { [0]="Player", [1]="FreeStalkers", [2]="Neutrals", [3]="Bandits", [4]="Monolith", [5]="Duty", [6]="Freedom", [7]="Varta", [8]="Militaries", [9]="Noon", [10]="Scientists", [11]="Mercenaries", [12]="Spark", [13]="Corpus" }

local ZEILEN_VON, SPALTE_VON = {}, {}
for r, name in pairs(ZEILE) do
    local i = IDX[name]
    if i then
        ZEILEN_VON[i] = ZEILEN_VON[i] or {}
        ZEILEN_VON[i][#ZEILEN_VON[i] + 1] = r
    end
end
for c, name in pairs(SPALTE) do
    local j = IDX[name]
    if j then SPALTE_VON[j] = c end
end

local ROH = {}
local function merken(r, c, satz)
    ROH[r] = ROH[r] or {}
    ROH[r][c] = satz
end
local function mehrheit(i, j)
    local c      = SPALTE_VON[j]
    local reihen = ZEILEN_VON[i]
    if c == nil or reihen == nil then return nil end

    local zaehl   = { [0] = 0, [1] = 0, [2] = 0, [3] = 0 }
    local stimmen = 0
    for k = 1, #reihen do
        local satz = ROH[reihen[k]] and ROH[reihen[k]][c]
        if satz then
            local n, einzige = 0, nil
            for l = 0, 3 do if satz[l] then n = n + 1; einzige = l end end
            if n == 1 then
                zaehl[einzige] = zaehl[einzige] + 1
                stimmen = stimmen + 1
            end
        end
    end
    if stimmen == 0 then return nil end

    local best, bn, gleich = nil, 0, false
    for l = 0, 3 do
        local n = zaehl[l]
        if n > bn then bn, best, gleich = n, l, false
        elseif n == bn and n > 0 then gleich = true end
    end
    if gleich then return nil end
    return best
end
local NATIV, nativDa, nativNeu, nativText = {}, false, false, nil
local function nativStufe(i, j)
    return NATIV[i] and NATIV[i][j]
end
local function nativLesen()
    if type(FMTXNative) ~= "function" then return false end
    local ok, s = pcall(FMTXNative)
    if not ok or type(s) ~= "string" or s == "" then return false end
    if s ~= nativText then
        nativText = s
        nativNeu = true
        for a, b, w in string.gmatch(s, "(%a+) (%a+) (%-?%d+)") do
            local i, j = IDX[a], IDX[b]
            if i and j then
                NATIV[i] = NATIV[i] or {}
                NATIV[i][j] = stufe(tonumber(w))
            end
        end
    end
    if not nativDa then
        nativDa = true
        p("native core active - relations are read directly from the game, no quests needed")
    end
    return true
end
local LETZTPFAD = (os.getenv("LOCALAPPDATA") or "") .. "/Stalker2/Saved/FactionMatrix_last.txt"
local LETZT, letztGeaendert = {}, false
do
    local f = io.open(LETZTPFAD, "rb")
    if f then
        for i, j, l in string.gmatch(f:read("*a") or "", "(%d+) (%d+) (%d)") do
            i, j = tonumber(i), tonumber(j)
            LETZT[i] = LETZT[i] or {}
            LETZT[i][j] = tonumber(l)
        end
        f:close()
    end
end
local function letztSpeichern()
    if type(FMTXNative) == "function" then
        if next(LETZT) ~= nil then
            LETZT = {}
            os.remove(LETZTPFAD)
        end
        return
    end
    if not letztGeaendert then return end
    letztGeaendert = false
    local f = io.open(LETZTPFAD, "wb")
    if not f then return end
    for i, zeile in pairs(LETZT) do
        for j, l in pairs(zeile) do f:write(i, " ", j, " ", l, string.char(10)) end
    end
    f:close()
end
local function zellenStufe(i, j)
    local l = nativStufe(i, j)
    if l == nil then l = mehrheit(i, j) end
    local cache = type(FMTXNative) ~= "function"
    if l ~= nil then
        if not cache then return l, true end
        LETZT[i] = LETZT[i] or {}
        if LETZT[i][j] ~= l then LETZT[i][j] = l; letztGeaendert = true end
        return l, true
    end
    if cache and LETZT[i] and LETZT[i][j] ~= nil then return LETZT[i][j], true end
    return stufe(M[i][j]), false
end
local function gemessen()
    local n = 0
    for i = 1, 13 do for j = 1, 13 do if nativStufe(i, j) ~= nil or mehrheit(i, j) ~= nil then n = n + 1 end end end
    return n
end
local function legendeText()
    return L.legende
end

local gehoert = {}
local logPos = 0
do
    local f = io.open(LOGPFAD, "rb")
    if f then logPos = f:seek("end") or 0; f:close() end
end
local logPfadGesucht = false
local function logPfadSuchen()
    if logPfadGesucht then return false end
    logPfadGesucht = true
    local kandidaten = {}
    local ok, ksl = pcall(StaticFindObject,
        "/Script/Engine.Default__KismetSystemLibrary")
    if ok and ksl then
        local function hole(fn)
            local ok2, v = pcall(fn)
            if not ok2 or v == nil then return nil end
            local okT, st = pcall(function() return v:ToString() end)
            local txt = (okT and st) and tostring(st) or nil
            if not txt or txt == "" or txt:find("FString") then return nil end
            return (txt:gsub("\\", "/"):gsub("/+$", ""))
        end
        local saved = hole(function() return ksl:GetProjectSavedDirectory() end)
        if saved then kandidaten[#kandidaten + 1] = saved .. "/Logs/Stalker2.log" end
        local proj = hole(function() return ksl:GetProjectDirectory() end)
        if proj then kandidaten[#kandidaten + 1] = proj .. "/Saved/Logs/Stalker2.log" end
    end
    local up = os.getenv("USERPROFILE")
    if up then
        kandidaten[#kandidaten + 1] = (up:gsub("\\", "/"))
            .. "/AppData/Local/Stalker2/Saved/Logs/Stalker2.log"
    end
    for i = 1, #kandidaten do
        local f = io.open(kandidaten[i], "rb")
        if f then
            f:close()
            LOGPFAD = kandidaten[i]
            logPos  = 0
            p("game log found at a different place: " .. LOGPFAD)
            return true
        end
    end
    for i = 1, #kandidaten do p("  also looked in: " .. kandidaten[i]) end
    return false
end
local function logLesen()
    local f = io.open(LOGPFAD, "rb")
    if not f and logPfadSuchen() then f = io.open(LOGPFAD, "rb") end
    if not f then
        if not logGemeldet then
            logGemeldet = true
            p("GAME LOG NOT READABLE: " .. LOGPFAD)
            p("  Without the log there are no live values - the table falls back")
            p("  to the shipping defaults. Is your save folder somewhere else?")
        end
        return
    end
    local groesse = f:seek("end")
    if groesse < logPos then logPos = 0 end
    if groesse <= logPos then f:close(); return end
    if groesse - logPos > 4194304 then logPos = groesse - 4194304 end
    f:seek("set", logPos)
    local neu = f:read("*a") or ""
    logPos = groesse
    f:close()
    local frisch = {}
    local function sammeln(r, c, l)
        markenGesamt = markenGesamt + 1
        frisch[r] = frisch[r] or {}
        frisch[r][c] = frisch[r][c] or {}
        frisch[r][c][l] = true
    end
    for r, c, l in string.gmatch(neu, "fmtx_R(%d%d)C(%d%d)L(%d)") do
        sammeln(tonumber(r), tonumber(c), tonumber(l))
    end
    for nr, c, l in string.gmatch(neu, "fmtp_(%d%d%d)C(%d%d)L(%d)") do
        nr = tonumber(nr)
        gehoert[nr] = (gehoert[nr] or 0) + 1
        sammeln(0, tonumber(c), tonumber(l))
    end
    for r, zeile in pairs(frisch) do
        for c, satz in pairs(zeile) do merken(r, c, satz) end
    end
end

local totGezaehlt = 0
local function gueltig(o)
    if not o then return false end
    local ok, v = pcall(function() return o:IsValid() end)
    if ok then return v end
    totGezaehlt = totGezaehlt + 1
    if totGezaehlt == 1 then
        p("  IsValid() threw - object treated as dead (this is the safe answer)")
    end
    return false
end

local function spielerRegler()
    local ok, pcx = pcall(FindFirstOf, "PlayerController")
    if ok and pcx and gueltig(pcx) then return pcx end
    return nil
end

local function konsole(befehl)
    local ksl = StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")
    if not (ksl and ksl:IsValid()) then return false end
    local pcx = spielerRegler()
    if not pcx then return false end
    local welt; pcall(function() welt = pcx:GetWorld() end)
    if not welt then return false end
    local ok = pcall(function() ksl:ExecuteConsoleCommand(welt, befehl, nil) end)
    return ok
end

local PAKDATEI = "ZZZ_FactionMatrix_P.pak"
local PAKREST  = "Paks/~mods/" .. PAKDATEI

local function engineOrdner()
    local ok, ksl = pcall(StaticFindObject,
        "/Script/Engine.Default__KismetSystemLibrary")
    if not (ok and ksl) then return nil, nil end
    local function hole(fn)
        local ok2, s = pcall(fn)
        if not ok2 or s == nil then return nil end
        local okT, st = pcall(function() return s:ToString() end)
        local txt = (okT and st) and tostring(st) or nil
        if not txt or txt == "" or txt:find("FString") then return nil end
        return (txt:gsub("\\", "/"):gsub("/+$", ""))
    end
    local content = hole(function() return ksl:GetProjectContentDirectory() end)
    local projekt = hole(function() return ksl:GetProjectDirectory() end)
    return content, projekt
end

local pakGeprueft, pakVorhanden = false, false
local function pakDa()
    if pakGeprueft then return pakVorhanden end
    pakGeprueft = true

    local orte = {}
    local content, projekt = engineOrdner()
    if content then orte[#orte+1] = content .. "/" .. PAKREST end
    if projekt then orte[#orte+1] = projekt .. "/Content/" .. PAKREST end
    if content then orte[#orte+1] = content .. "/Paks/~mods/zzzFactionMatrix/" .. PAKDATEI end
    if projekt then orte[#orte+1] = projekt .. "/Content/Paks/~mods/zzzFactionMatrix/" .. PAKDATEI end
    if content then orte[#orte+1] = content .. "/Paks/~mods/FactionMatrix/" .. PAKDATEI end
    if projekt then orte[#orte+1] = projekt .. "/Content/Paks/~mods/FactionMatrix/" .. PAKDATEI end
    orte[#orte+1] = "../../../Content/" .. PAKREST
    orte[#orte+1] = "../../Content/"    .. PAKREST
    orte[#orte+1] = "../Content/"       .. PAKREST
    orte[#orte+1] = "Stalker2/Content/" .. PAKREST
    orte[#orte+1] = "Content/"          .. PAKREST

    for i = 1, #orte do
        local f = io.open(orte[i], "rb")
        if f then
            f:close()
            pakVorhanden = true
            p("quest pak found - live measurement starting")
            p("  " .. orte[i])
            return true
        end
    end

    if content and type(io.popen) == "function" then
        local ordner = ((content:gsub("/+$", "")) .. "/Paks/~mods"):gsub("/", "\\")
        local fund = nil
        pcall(function()
            local h = io.popen('dir /b /s "' .. ordner .. '\\' .. PAKDATEI .. '" 2>nul', "r")
            if h then
                fund = h:read("*l")
                h:close()
            end
        end)
        if type(fund) == "string" and fund ~= "" then
            local f2 = io.open(fund, "rb")
            if f2 then
                f2:close()
                pakVorhanden = true
                p("quest pak found by directory search - live measurement starting")
                p("  " .. fund)
                return true
            end
        end
    end

    pakVorhanden = false
    p("QUEST PAK MISSING - looked in " .. #orte .. " places, plus a directory search:")
    for i = 1, #orte do p("    " .. orte[i]) end
    p("  No quest will be started - that would crash the game.")
    p("  The table will show default values, no live measurement.")
    return false
end

local function installationDefekt()
    if nativDa then return false end
    if not pakDa() then return true end
    if logGemeldet then return true end
    local f = io.open(LOGPFAD, "rb")
    if not f and logPfadSuchen() then f = io.open(LOGPFAD, "rb") end
    if not f then return true end
    f:close()
    return false
end

local POOL = 1
local VOLLE_REIHE = 10
local naechste, grossGestartet = 0, false
local warten, startNach = nil, nil
local neustartWeg = nil
local letzteAuffrischung = 0
local stumm, stummGemeldet = false, false

local konsoleGeprueft = false
local konsoleWeggemeldet = false
local function konsoleSicherstellen()
    if konsoleGeprueft then return end
    konsoleGeprueft = true
    local ok = pcall(function()
        local eng = UEHelpers.GetEngine()
        if not gueltig(eng) then p("  engine not found - console unchanged") return end
        local vp = eng.GameViewport
        if not gueltig(vp) then p("  no GameViewport - console unchanged") return end
        if gueltig(vp.ViewportConsole) then p("  console already active") return end
        local kl = eng.ConsoleClass
        if not gueltig(kl) then p("  ConsoleClass not found") return end
        local k = StaticConstructObject(kl, vp)
        if gueltig(k) then
            vp.ViewportConsole = k
            p("  console created - live measurement enabled")
        else
            p("  could not construct console object")
        end
    end)
    if not ok then p("  console setup failed") end
end
local function matrixStarten()
    if nativLesen() then return end
    konsoleSicherstellen()
    if not pakDa() then return end
    if grossGestartet then return end
    if konsole("XStartQuestBySID FMTX_B") then
        grossGestartet = true
        letzteAuffrischung = os.time()
        p("matrix quest FMTX_B started")
    end
end
local quotaGemeldet = false
local function starten(nr, art)
    if konsole(string.format("XStartQuestBySID FMTX_P%03d", nr)) then
        warten = { nr = nr, vorher = gehoert[nr] or 0, art = art }
        return true
    end
    return false
end
local function auffrischen()
    if nativDa then return end
    if not pakDa() then return end
    if stumm then return end
    if grossGestartet and markenGesamt == 0 then
        logLesen()
    end
    if grossGestartet and markenGesamt == 0 then
        stumm = true
        if not stummGemeldet then
            stummGemeldet = true
            p("MEASUREMENT CHAIN IS SILENT - no refresh quests will be started.")
            p("  FMTX_B was started at least a minute ago and not one single line came back.")
            p("  Two things can cause this, and this mod cannot tell them apart:")
            p("    1. the quest pak is on disk but was not mounted by the game.")
            p("       A pak is only mounted at STARTUP. If you copied it while")
            p("       the game was running, restart the game.")
            p("    2. the developer console is off, so the game writes no lines.")
            p("  The table keeps working, but it shows the shipping defaults.")
        end
        return
    end
    if startNach then
        local nr = startNach
        startNach = nil
        starten(nr, "ende")
        return
    end
    if warten then
        logLesen()
        local w = warten
        warten = nil
        if (gehoert[w.nr] or 0) - w.vorher >= VOLLE_REIHE then
            if w.art ~= "neu" and neustartWeg ~= w.art then
                neustartWeg = w.art
                p(w.art == "direkt"
                  and "  restarting a used refresh quest answers - refreshes keep cycling"
                  or  "  end + restart of a refresh quest answers - refreshes keep cycling")
            end
        elseif w.art == "direkt" then
            if konsole(string.format("XEndQuestBySID FMTX_P%03d", w.nr)) then
                startNach = w.nr
            end
            return
        elseif w.art == "ende" then
            neustartWeg = false
        end
    end
    if naechste < POOL then
        if starten(naechste, "neu") then naechste = naechste + 1 end
    elseif neustartWeg == false then
        if not quotaGemeldet then
            quotaGemeldet = true
            p("REFRESH QUESTS DO NOT ANSWER A RESTART - no further refreshes this session.")
            p("  New refresh quests would make your save bigger, so the mod stops here.")
            p("  The quests already running still report every change of a player")
            p("  relation on their own. Faction-to-faction values are unaffected.")
        end
        return
    else
        local nr = naechste % POOL
        if neustartWeg == "ende" then
            if konsole(string.format("XEndQuestBySID FMTX_P%03d", nr)) then
                startNach = nr
                naechste = naechste + 1
            end
        elseif starten(nr, "direkt") then
            naechste = naechste + 1
        end
    end
    if naechste % 10 == 0 and not konsoleWeggemeldet then
        pcall(function()
            local eng = UEHelpers.GetEngine()
            if not gueltig(eng) then return end
            local vp = eng.GameViewport
            if not gueltig(vp) then return end
            if not gueltig(vp.ViewportConsole) then
                konsoleWeggemeldet = true
                p("CONSOLE IS GONE - the game no longer writes the lines we read.")
                p("  Values will stop updating. Restarting the game brings it back.")
            end
        end)
    end
end

local KLASSEN_WEG = {}
local KLASSEN_TOT = {}
local function klasseVon(pfad, kurz)
    if KLASSEN_TOT[kurz] then return nil end
    local cdoPfad = pfad:gsub("%.([^%.]+)$", ".Default__%1")

    local function ueberWeg(weg)
        if weg == "pfad" then
            local ok, k = pcall(StaticFindObject, pfad)
            if ok and k and gueltig(k) then return k end
        elseif weg == "cdo" then
            local ok, cdo = pcall(StaticFindObject, cdoPfad)
            if ok and cdo and gueltig(cdo) then
                local okC, kc = pcall(function() return cdo:GetClass() end)
                if okC and kc and gueltig(kc) then return kc end
            end
        elseif weg == "instanz" then
            local ok, a = pcall(FindAllOf, kurz)
            if ok and a and #a > 0 then
                local okC, kg = pcall(function() return a[1]:GetClass() end)
                if okC and kg and gueltig(kg) then return kg end
            end
        end
        return nil
    end

    if KLASSEN_WEG[kurz] then
        local k = ueberWeg(KLASSEN_WEG[kurz])
        if k then return k end
        p("  class " .. kurz .. ": remembered route no longer works - searching again")
        KLASSEN_WEG[kurz] = nil
    end

    local function nimm(k, woher, weg)
        if k and gueltig(k) then
            KLASSEN_WEG[kurz] = weg
            p("  class " .. kurz .. " via " .. woher)
            return k
        end
        return nil
    end

    local ok, k = pcall(StaticFindObject, pfad)
    if ok then local t = nimm(k, "path", "pfad") if t then return t end end

    local ok2, cdo = pcall(StaticFindObject, cdoPfad)
    if ok2 and cdo and gueltig(cdo) then
        local okC, kc = pcall(function() return cdo:GetClass() end)
        if okC then local t = nimm(kc, "default object", "cdo") if t then return t end end
    end

    local ok3, a = pcall(FindAllOf, kurz)
    if ok3 and a and #a > 0 then
        local okC, kg = pcall(function() return a[1]:GetClass() end)
        if okC then local t = nimm(kg, "live instance (old route)", "instanz") if t then return t end end
    end

    KLASSEN_TOT[kurz] = true
    p("  class not found by any method: " .. kurz)
    return nil
end

local SCHRIFT, PINSELQUELLE = nil, nil

local function baumSuchen(wurzel, pruefe)
    if not gueltig(wurzel) then return nil end
    local gesehen = 0
    local function lauf(w, tiefe)
        if tiefe > 8 or gesehen > 600 then return nil end
        if not gueltig(w) then return nil end
        gesehen = gesehen + 1

        local nm = ""; pcall(function() nm = w:GetFullName() end)
        if nm ~= "" then
            local treffer = pruefe(w, nm)
            if treffer ~= nil then return treffer end
        end

        local baum; pcall(function() baum = w.WidgetTree end)
        if gueltig(baum) then
            local wz; pcall(function() wz = baum.RootWidget end)
            if gueltig(wz) then
                local t = lauf(wz, tiefe + 1)
                if t ~= nil then return t end
            end
        end

        local n = -1; pcall(function() n = w:GetChildrenCount() end)
        if n >= 0 and n <= 128 then
            for i = 0, n - 1 do
                local k; pcall(function() k = w:GetChildAt(i) end)
                if gueltig(k) then
                    local t = lauf(k, tiefe + 1)
                    if t ~= nil then return t end
                end
            end
        end
        return nil
    end
    return lauf(wurzel, 0)
end

local function baumWurzel(view)
    if not gueltig(view) then return nil end
    local baum; pcall(function() baum = view.WidgetTree end)
    if not gueltig(baum) then return nil end
    local wz; pcall(function() wz = baum.RootWidget end)
    if not gueltig(wz) then return nil end
    return wz
end

local function spielSchrift(view)
    if SCHRIFT == false then return nil end
    if SCHRIFT ~= nil then
        if gueltig(SCHRIFT.FontObject) then return SCHRIFT end
        SCHRIFT = nil
        p("  cached font was dead - fetching a fresh one")
    end
    p("  step 6 searching game font")
    local gefunden = baumSuchen(baumWurzel(view), function(w, nm)
        local okF, f = pcall(function() return w.Font end)
        if not (okF and f) then return nil end
        local fo, tf = nil, nil
        pcall(function() fo = f.FontObject end)
        pcall(function() tf = f.TypefaceFontName end)
        if not gueltig(fo) then return nil end
        p("  font taken from game: " .. nm)
        return { FontObject = fo, TypefaceFontName = tf }
    end)
    if gefunden then SCHRIFT = gefunden; return SCHRIFT end
    p("  no game font found")
    SCHRIFT = false
    return SCHRIFT
end

local function spielPinsel(view)
    if PINSELQUELLE == false then return nil end
    if PINSELQUELLE ~= nil then
        if gueltig(PINSELQUELLE) then
            local okB, b = pcall(function() return PINSELQUELLE.Brush end)
            if okB and b then return b end
        end
        PINSELQUELLE = nil
        p("  cached brush source was dead - fetching a fresh one")
    end
    p("  step 7 searching game brush")
    local gefunden = baumSuchen(baumWurzel(view), function(w, nm)
        local n = nm:lower()
        if not (n:find("decor") or n:find("line") or n:find("frame")) then return nil end
        local okB, b = pcall(function() return w.Brush end)
        if not (okB and b) then return nil end
        PINSELQUELLE = w
        p("  brush taken from game: " .. nm)
        return b
    end)
    if gefunden then return gefunden end
    p("  no game brush found - using flat line")
    PINSELQUELLE = false
    return nil
end

local function merkerLeeren()
    if SCHRIFT ~= false then SCHRIFT = nil end
    if PINSELQUELLE ~= false then PINSELQUELLE = nil end
end

local KTL
local function ftext(s)
    if not KTL then local ok,l = pcall(function() return UEHelpers.GetKismetTextLibrary() end); if ok then KTL=l end end
    if not KTL then return nil end
    local ok, t = pcall(function() return KTL:Conv_StringToText(s) end)
    return ok and t or nil
end

local matrix, warZuvor, gebautBei = nil, nil, -1
local offen = false
local matrixName = nil
local ZELLEN, legendeTB, warnTB = {}, nil, nil
local bauZaehler = 0
local bauFehler  = 0

local WAPPEN_ORTE = {
    {
        woher = "game",
        basis = "/Game/GameLite/FPS_Game/UIRemaster/UITextures/PDA/FractionIcons/",
        tex = {
            ["Duty"]        = "T_icon_fraction_duty",
            ["Freedom"]     = "T_icon_fraction_freedom",
            ["Ward"]        = "T_icon_fraction_varta",
            ["Loners"]      = "T_icon_fraction_neutrals",
            ["Scientists"]  = "T_icon_fraction_scientists",
            ["Spark"]       = "T_icon_fraction_spark",
            ["Corps"]       = "T_icon_fraction_corps",
            ["Noontide"]    = "T_icon_fraction_noon",
            ["Military"]    = "T_icon_fraction_militaries",
            ["Mercenaries"] = "T_icon_fraction_mercenaries",
            ["Bandits"]     = "T_icon_fraction_bandits",
            ["Monolith"]    = "T_icon_fraction_monolith",
        },
    },
    {
        woher = "OXA",
        basis = "/Standard/Interface/WidgetStalkerID/FactionIcons/",
        tex = {
            ["Duty"]        = "T_faction_duty",
            ["Freedom"]     = "T_faction_freedom",
            ["Ward"]        = "T_faction_ward",
            ["Loners"]      = "T_faction_loner",
            ["Scientists"]  = "T_faction_ecologists",
            ["Spark"]       = "T_faction_spark",
            ["Corps"]       = "T_faction_corps",
            ["Noontide"]    = "T_faction_noontide",
            ["Military"]    = "T_faction_IPSF",
            ["Mercenaries"] = "T_faction_mercenaries",
            ["Bandits"]     = "T_faction_bandit",
            ["Monolith"]    = "T_faction_monolith",
            [L.spieler]     = "T_faction_unknown",
        },
    },
}
local WAPPEN_OXA = WAPPEN_ORTE[2].tex

local function spracheAnwenden()
    if spracheGeprueft then return end
    spracheGeprueft = true
    local ok, kil = pcall(StaticFindObject,
        "/Script/Engine.Default__KismetInternationalizationLibrary")
    if ok and kil then
        local ok2, s = pcall(function() return kil:GetCurrentLanguage() end)
        local txt = nil
        if ok2 and s ~= nil then
            local okT, st = pcall(function() return s:ToString() end)
            txt = (okT and st) and tostring(st) or tostring(s)
        end
        if txt then
            local voll = txt:lower()
            if TEXTE[voll] then
                SPRACHE = voll
            elseif TEXTE[voll:sub(1, 2)] then
                SPRACHE = voll:sub(1, 2)
            end
        end
    end
    L = TEXTE[SPRACHE]
    TITEL   = L.reiter
    WORT    = L.wort
    KURZ[1] = L.spieler
    WAPPEN_OXA[L.spieler] = "T_faction_unknown"
    p("language: " .. SPRACHE)
end

local wappenGemeldet = {}
local wappenQuelle = {}
local function wappenNeu()
    for k, v in pairs(wappenQuelle) do
        if v == "-" then wappenQuelle[k] = nil end
    end
end
local function wappenTextur(fraktion)
    local q = wappenQuelle[fraktion]
    if q == "-" then return nil end

    local function ausOrt(ort)
        local name = ort.tex[fraktion]
        if not name then return nil end
        local pfad = ort.basis .. name .. "." .. name
        local ok, t = pcall(StaticFindObject, pfad)
        if ok and gueltig(t) then return t end
        pcall(function() LoadAsset(ort.basis .. name) end)
        local ok2, t2 = pcall(StaticFindObject, pfad)
        if ok2 and gueltig(t2) then return t2 end
        return nil
    end

    if q then
        for _, ort in ipairs(WAPPEN_ORTE) do
            if ort.woher == q then
                local t = ausOrt(ort)
                if t then return t end
            end
        end
        wappenQuelle[fraktion] = nil
    end

    for _, ort in ipairs(WAPPEN_ORTE) do
        local t = ausOrt(ort)
        if t then wappenQuelle[fraktion] = ort.woher; return t end
    end

    wappenQuelle[fraktion] = "-"
    if not wappenGemeldet[fraktion] then
        wappenGemeldet[fraktion] = true
        p("  no emblem for " .. fraktion .. " - neither source has one")
    end
    return nil
end

local uiManager = nil
local uiAlter = 0
local function pdaOffen()
    uiAlter = uiAlter + 1
    if uiAlter >= 120 then
        uiAlter = 0
        uiManager = nil
    end
    if not gueltig(uiManager) then
        uiManager = FindFirstOf("UIManagerEx")
        if not gueltig(uiManager) then
            local ok, views = pcall(FindAllOf, "PDAView")
            if ok and views and #views > 0 then return true, views[1] end
            return false, nil
        end
    end
    local views = nil
    local okV = pcall(function() views = uiManager.OpenViews end)
    if not okV or views == nil then
        uiManager = nil
        return false, nil
    end
    local n = -1
    pcall(function() n = #views end)
    if n < 0 or n > 64 then
        uiManager = nil
        p("  view list length was " .. tostring(n) .. " - dropping stale UI manager")
        return false, nil
    end
    for i = 1, n do
        local v = nil
        pcall(function() v = views[i] end)
        if gueltig(v) then
            local kl = ""
            pcall(function() kl = v:GetClass():GetFullName() end)
            if kl:find("PDABookView") or kl:find("PDAView") then return true, v end
        end
    end
    return false, nil
end
local function bauen(view, besitzer)
    p("  step 1 language")
    spracheAnwenden()
    p("  step 2 emblems")
    wappenNeu()
    merkerLeeren()
    p("  step 3 classes")
    local kVB = klasseVon("/Script/UMG.VerticalBox", "VerticalBox")
    local kHB = klasseVon("/Script/UMG.HorizontalBox", "HorizontalBox")
    local kTB = klasseVon("/Script/UMG.TextBlock", "TextBlock")
    local kSB = klasseVon("/Script/UMG.SizeBox", "SizeBox")
    local kIM = klasseVon("/Script/UMG.Image", "Image")
    local kOV = klasseVon("/Script/UMG.Overlay", "Overlay")
    local kBO = klasseVon("/Script/UMG.Border", "Border")
    if not (kVB and kHB and kTB) then p("  UMG building blocks missing"); return nil end

    p("  step 4 player controller")
    local pc = spielerRegler()
    if not pc then p("  no PlayerController yet - build postponed"); return nil end
    local aussen = besitzer
    if not gueltig(aussen) then pcall(function() aussen = view.WidgetTree end) end
    if not gueltig(aussen) then aussen = view end
    local function mach(kl, eltern)
        if not kl then return nil end
        local ok, o = pcall(function() return StaticConstructObject(kl, eltern or aussen) end)
        if ok and o then pcall(function() o:SetVisibility(SICHTBAR) end); return o end
        return nil
    end

    p("  step 5 root container")
    local spalte = mach(kVB)
    if not spalte then p("  root container could not be built"); return nil end

    local function text(eltern, s, farbe, groesse)
        local tb = mach(kTB, eltern)
        if not tb then return nil end
        local t = ftext(s); if t then pcall(function() tb:SetText(t) end) end
        pcall(function() tb:SetColorAndOpacity(farbe) end)
        pcall(function()
            local eigen = tb.Font
            local sf = spielSchrift(view)
            if sf then
                eigen.FontObject = sf.FontObject
                eigen.TypefaceFontName = sf.TypefaceFontName
            end
            eigen.Size = groesse
            pcall(function() tb:SetFont(eigen) end)
        end)
        return tb
    end

    local titel = text(spalte, L.titel, C_TITEL, 27)
    if titel then
        local halter = titel
        if kSB then
            local kasten = mach(kSB, spalte)
            if kasten then
                pcall(function() kasten:SetHeightOverride(92.0) end)
                local sl
                pcall(function() sl = kasten:AddChild(titel) end)
                if sl then
                    pcall(function() sl:SetHorizontalAlignment(1) end)
                    pcall(function() sl:SetVerticalAlignment(2) end)
                    halter = kasten
                end
            end
        end
        local s
        pcall(function() s = spalte:AddChild(halter) end)
        if s then
            pcall(function() s:SetPadding({Left=RAND_L, Top=0, Right=0, Bottom=0}) end)
        end
    end

    local TAB_BREITE = SP_NAME + 13 * SP_WERT
    local function trennlinie(oben, unten)
        if not (kIM and kSB) then return end
        local kasten = mach(kSB, spalte)
        local linie  = mach(kIM, kasten or spalte)
        if not (kasten and linie) then return end
        local ltex = StaticFindObject(TEX_LINIE)
        local gesetzt = false
        if gueltig(ltex) then
            gesetzt = pcall(function() linie:SetBrushFromTexture(ltex, false) end)
        end
        if not gesetzt then
            local pn = spielPinsel(view)
            if pn then pcall(function() linie:SetBrush(pn) end) end
            pcall(function() linie:SetColorAndOpacity(C_LINIE) end)
        end
        pcall(function() kasten:SetWidthOverride(TAB_BREITE) end)
        pcall(function() kasten:SetHeightOverride(2.0) end)
        pcall(function() kasten:AddChild(linie) end)
        local s
        pcall(function() s = spalte:AddChild(kasten) end)
        if s then
            pcall(function() s:SetPadding({Left=RAND_L, Top=oben or 0, Right=0, Bottom=unten or 14}) end)
            pcall(function() s:SetHorizontalAlignment(1) end)
        end
    end
    trennlinie(0, 16)

    local z, f = 0, 0
    local function zelle(eltern, s, farbe, breite, groesse)
        local tb = text(eltern, s, farbe, groesse)
        if not tb then f = f + 1; return end
        local halter = tb
        if kSB then
            local sb = mach(kSB, eltern)
            if sb then
                pcall(function() sb:SetWidthOverride(breite) end)
                pcall(function() sb:SetHeightOverride(38.0) end)
                local sl
                pcall(function() sl = sb:AddChild(tb) end)
                if sl then
                    halter = sb
                    pcall(function() sl:SetHorizontalAlignment(0) end)
                    pcall(function() tb:SetJustification(1) end)
                end
            end
        end
        if pcall(function() eltern:AddChild(halter) end) then z = z + 1 else f = f + 1 end
        return tb
    end

    local function namensZelle(eltern, name, breite, farbe)
        farbe = farbe or C_NAME
        local hb = mach(kHB, eltern)
        if not hb then return zelle(eltern, anzeigeName(name), farbe, breite, 18) end

        local tex = wappenTextur(name)
        if tex and kIM and kSB then
            local bild   = mach(kIM, hb)
            local kasten = mach(kSB, hb)
            if bild and kasten then
                local okT = pcall(function() bild:SetBrushFromTexture(tex, false) end)
                if okT then
                    pcall(function() kasten:SetWidthOverride(26.0) end)
                    pcall(function() kasten:SetHeightOverride(26.0) end)
                    pcall(function() kasten:AddChild(bild) end)
                    local sw
                    pcall(function() sw = hb:AddChild(kasten) end)
                    if sw then
                        pcall(function() sw:SetPadding({Left=0, Top=0, Right=8, Bottom=0}) end)
                        pcall(function() sw:SetVerticalAlignment(2) end)
                    end
                end
            end
        end

        local tb = text(hb, anzeigeName(name), farbe, 18)
        if tb then
            local st
            pcall(function() st = hb:AddChild(tb) end)
            if st then pcall(function() st:SetVerticalAlignment(2) end) end
        end

        local halter = hb
        if kSB then
            local sb = mach(kSB, eltern)
            if sb then
                pcall(function() sb:SetWidthOverride(breite) end)
                pcall(function() sb:SetHeightOverride(38.0) end)
                if pcall(function() sb:AddChild(hb) end) then halter = sb end
            end
        end
        if pcall(function() eltern:AddChild(halter) end) then z = z + 1 else f = f + 1 end
        return tb
    end

    local function reihe(oben)
        local hb = mach(kHB, spalte)
        if not hb then return nil end
        return hb
    end
    local streifenAus = false
    local function anhaengen(hb, unten, streifen)
        local kind = hb
        if streifen and kBO and not streifenAus then
            local bo = mach(kBO, spalte)
            local ok = false
            if bo and pcall(function() bo:SetBrushColor(streifen) end) then
                ok = pcall(function() bo:SetContent(hb) end)
                if not ok then ok = pcall(function() bo:AddChild(hb) end) end
                if ok then
                    kind = bo
                end
            end
            if not ok then streifenAus = true; p("  row background not available - plain rows") end
        end
        local s
        pcall(function() s = spalte:AddChild(kind) end)
        if s then
            pcall(function() s:SetHorizontalAlignment(1) end)
            pcall(function() s:SetPadding({Left=RAND_L, Top=0, Right=0, Bottom=unten or 5}) end)
        end
    end

    local function kopfZelle(eltern, name, breite)
        local tex = (kIM and kSB and kVB) and wappenTextur(name) or nil
        if not tex then return zelle(eltern, anzeigeName(name), C_KOPFH, breite, 14) end
        local vb = mach(kVB, eltern)
        if not vb then return zelle(eltern, anzeigeName(name), C_KOPFH, breite, 14) end

        local bild   = mach(kIM, vb)
        local kasten = mach(kSB, vb)
        if bild and kasten and pcall(function() bild:SetBrushFromTexture(tex, false) end) then
            pcall(function() kasten:SetWidthOverride(24.0) end)
            pcall(function() kasten:SetHeightOverride(24.0) end)
            pcall(function() kasten:AddChild(bild) end)
            local sw
            pcall(function() sw = vb:AddChild(kasten) end)
            if sw then
                pcall(function() sw:SetHorizontalAlignment(2) end)
                pcall(function() sw:SetPadding({Left=0, Top=0, Right=0, Bottom=4}) end)
            end
        end

        local tb = text(vb, anzeigeName(name), C_KOPFH, 14)
        if tb then
            local st
            pcall(function() st = vb:AddChild(tb) end)
            if st then pcall(function() st:SetHorizontalAlignment(2) end) end
        end

        local halter = vb
        if kSB then
            local sb = mach(kSB, eltern)
            if sb then
                pcall(function() sb:SetWidthOverride(breite) end)
                pcall(function() sb:SetHeightOverride(56.0) end)
                if pcall(function() sb:AddChild(vb) end) then halter = sb end
            end
        end
        if pcall(function() eltern:AddChild(halter) end) then z = z + 1 else f = f + 1 end
        return tb
    end

    local kz = reihe()
    if kz then
        zelle(kz, "", C_KOPFH, SP_NAME, 14)
        for j = 1, 13 do kopfZelle(kz, KURZ[j], SP_WERT) end
        anhaengen(kz, 4)
        trennlinie(0, 10)
    end

    for i = 1, 13 do
        local rz = reihe()
        if rz then
            local eigen = (i == 1)
            namensZelle(rz, KURZ[i], SP_NAME, eigen and C_KOPFH or C_NAME)
            for j = 1, 13 do
                ZELLEN[i] = ZELLEN[i] or {}
                if i == j then ZELLEN[i][j] = zelle(rz, "-", C_EIGEN, SP_WERT, 12)
                else
                    local st = zellenStufe(i, j)
                    if st == nil then ZELLEN[i][j] = zelle(rz, "-", C_EIGEN, SP_WERT, 12)
                    else ZELLEN[i][j] = zelle(rz, WORT[st], FARBE[st], SP_WERT, 12) end
                end
            end
            if eigen then
                anhaengen(rz, 6, C_SPIELER)
                trennlinie(2, 8)
            else
                anhaengen(rz, nil, (i % 2 == 0) and C_ZEBRA or nil)
            end
        end
    end

    trennlinie(10, 12)
    local leg = text(spalte, legendeText(), C_LEG, 12)
    legendeTB = leg
    if leg then
        local s
        pcall(function() s = spalte:AddChild(leg) end)
        if s then pcall(function() s:SetPadding({Left=RAND_L, Top=18, Right=0, Bottom=0}) end) end
    end

    if installationDefekt() then
        local w = text(spalte, L.fehler, C_WARN, 13)
        warnTB = w
        if w then
            local s
            pcall(function() s = spalte:AddChild(w) end)
            if s then pcall(function() s:SetPadding({Left=RAND_L, Top=10, Right=0, Bottom=0}) end) end
        end
        p("  WARNING SHOWN: installation broken (pak missing or log unreadable)")
    end

    do
        local ausSpiel, ausOxa, ohne = 0, 0, 0
        for _, q in pairs(wappenQuelle) do
            if q == "game" then ausSpiel = ausSpiel + 1
            elseif q == "OXA" then ausOxa = ausOxa + 1
            else ohne = ohne + 1 end
        end
        p(string.format("  emblems: %d from the game, %d from OXA, %d missing",
                        ausSpiel, ausOxa, ohne))
    end
    bauZaehler = bauZaehler + 1
    p(string.format("  cells: %d built, %d failed (expected 196) - build #%d",
                    z, f, bauZaehler))
    if kOV then
        local rahmen = mach(kOV)
        if rahmen then
            local grund = nil
            local gtex = StaticFindObject(TEX_GRUND)
            if not gueltig(gtex) then
                pcall(function() LoadAsset(TEX_GRUND:gsub("%.[^.]*$", "")) end)
                gtex = StaticFindObject(TEX_GRUND)
            end
            if gueltig(gtex) and kIM then
                local bild = mach(kIM, rahmen)
                if bild and pcall(function() bild:SetBrushFromTexture(gtex, false) end) then
                    grund = bild
                    p("  background texture set")
                end
            end
            if not grund and kBO then
                grund = mach(kBO, rahmen)
                if grund then
                    pcall(function() grund:SetBrushColor(C_GRUND) end)
                    p("  background texture missing - using flat colour")
                end
            end
            if grund then
                local sg
                pcall(function() sg = rahmen:AddChild(grund) end)
                if sg then
                    pcall(function() sg:SetHorizontalAlignment(0) end)
                    pcall(function() sg:SetVerticalAlignment(0) end)
                end
            else
                p("  Border class missing - no background")
            end
            local si
            pcall(function() si = rahmen:AddChild(spalte) end)
            if si then
                pcall(function() si:SetHorizontalAlignment(1) end)
                pcall(function() si:SetVerticalAlignment(1) end)
            end
            if si then
                p("  background applied")
                return rahmen
            end
        end
        p("  background could not be built")
    end
    return spalte
end

local function aktualisieren()
    for i = 1, 13 do
        local r = ZELLEN[i]
        if r then
            for j = 1, 13 do
                local tb = r[j]
                if tb and gueltig(tb) and i ~= j then
                    local st = zellenStufe(i, j)
                    local s = (st == nil) and "-" or WORT[st]
                    local farbe = (st == nil) and C_EIGEN or FARBE[st]
                    local ft = ftext(s)
                    if ft then pcall(function() tb:SetText(ft) end) end
                    pcall(function() tb:SetColorAndOpacity(farbe) end)
                end
            end
        end
    end
    if legendeTB and gueltig(legendeTB) then
        local ft = ftext(legendeText())
        if ft then pcall(function() legendeTB:SetText(ft) end) end
    end
end

local function wurzelVon(seite)
    local baum
    pcall(function() baum = seite.WidgetTree end)
    if not gueltig(baum) then p("    page WidgetTree not readable"); return nil end
    local w
    pcall(function() w = baum.RootWidget end)
    if not gueltig(w) then p("    page RootWidget not readable"); return nil end
    local nm = "?"; pcall(function() nm = w:GetFullName() end)
    p("    page root: " .. nm)
    return w
end

local function reiterUmbenennen(view)
    local nav, cont
    pcall(function() nav = view.NavigationPanel end)
    if not gueltig(nav) then return false end
    pcall(function() cont = nav.SlotContainer end)
    if not gueltig(cont) then return false end
    local n = 0; pcall(function() n = cont:GetChildrenCount() end)
    for i = 0, n - 1 do
        local k
        pcall(function() k = cont:GetChildAt(i) end)
        if gueltig(k) then
            local nm = ""; pcall(function() nm = k:GetFullName() end)
            if nm:lower():find(ZIEL) then
                local ok = pcall(function() k.ButtonText:SetText(ftext(TITEL)) end)
                p("  tab " .. i .. " renamed to '" .. TITEL .. "': " .. tostring(ok))
                return ok
            end
        end
    end
    return false, nil
end

local function kindMitName(cont, name)
    local n = 0; pcall(function() n = cont:GetChildrenCount() end)
    for i = 0, n - 1 do
        local k; pcall(function() k = cont:GetChildAt(i) end)
        if gueltig(k) then
            local nm = ""; pcall(function() nm = k:GetFName():ToString() end)
            if nm == name then return k, i end
        end
    end
    return nil
end
local function eigenerReiter()
    return type(FMTXNative) == "function"
end
local function eigeneSeite(view)
    local sw, cont
    pcall(function() sw = view.Switcher end)
    pcall(function() cont = view.NavigationPanel.SlotContainer end)
    if not (gueltig(sw) and gueltig(cont)) then return nil end
    local seite, si = kindMitName(sw, "FMTX_Seite")
    local knopf = kindMitName(cont, "FMTX_Reiter")
    if not (seite and knopf) then return nil end
    pcall(function() knopf.ButtonText:SetText(ftext(TITEL)) end)
    return seite, "own tab, page " .. si
end
local function zielSeite(view)
    if eigenerReiter() then return eigeneSeite(view) end
    pcall(function() view.NavigationPanel.BestiaryBtn:SetVisibility(4) end)
    local s
    pcall(function() s = view.BestiaryPage end)
    if gueltig(s) then return s, "named field BestiaryPage" end

    local sw
    pcall(function() sw = view.Switcher end)
    if not gueltig(sw) then return nil end
    local n = 0; pcall(function() n = sw:GetChildrenCount() end)
    for i = 0, n - 1 do
        local k
        pcall(function() k = sw:GetChildAt(i) end)
        local nm = ""
        if gueltig(k) then pcall(function() nm = k:GetFullName() end) end
        if nm:lower():find(ZIEL) then return k, "Switcher, slot " .. i end
    end
    return nil
end

local function einhaengen(view)
    p("")
    p("======== FactionMatrix " .. VERSION .. " ========")
    nativLesen()

    local seite, woher = zielSeite(view)
    if not seite and eigenerReiter() then p("  own tab not ready yet"); return false, true end
    if not seite then p("  target page not found"); return false end
    p("  target page via " .. woher)

    local wurzel = wurzelVon(seite)
    if not wurzel then return false end

    ZELLEN, legendeTB, warnTB = {}, nil, nil
    local baum; pcall(function() baum = seite.WidgetTree end)
    matrix = bauen(view, baum)
    if not matrix then p("  page not built"); return false end

    gebautBei = gemessen()
    aktualisieren()

    pcall(function() wurzel:ClearChildren() end)
    local s
    local ok = pcall(function() s = wurzel:AddChild(matrix) end)
    p("  page attached: " .. tostring(ok))
    if s then
        pcall(function() s:SetHorizontalAlignment(0) end)
        pcall(function() s:SetVerticalAlignment(0) end)
        pcall(function() s:SetAnchors({Minimum = {X = 0, Y = 0}, Maximum = {X = 1, Y = 1}}) end)
        pcall(function() s:SetOffsets({Left = 0, Top = 0, Right = 0, Bottom = 0}) end)
    end
    if not ok then matrix, legendeTB, warnTB, ZELLEN = nil, nil, nil, {}; return false end

    matrixName = nil
    pcall(function() matrixName = matrix:GetFullName() end)

    if not eigenerReiter() then reiterUmbenennen(view) end
    matrixStarten()
    p("======== end ========")
    return true
end

do
    local jobQueued, queuedAt, warned, lastError = false, 0, false, nil

    local function imFaden(fn)
        if type(ExecuteInGameThread) ~= "function" then return end
        if jobQueued then
            if not warned and os.time() - queuedAt >= 30 then
                warned = true
                p("game thread has not answered for 30 s - live update waits")
            end
            return
        end
        jobQueued, queuedAt = true, os.time()
        local ok = pcall(ExecuteInGameThread, function()
            local ok2, err = pcall(fn)
            if not ok2 and tostring(err) ~= lastError then
                lastError = tostring(err)
                p("tick error: " .. lastError)
            end
            jobQueued = false
            if warned then
                warned = false
                p("game thread answers again")
            end
        end)
        if not ok then jobQueued = false end
    end

    local function tafelLebtNoch(view)
        if not matrixName then return false end
        if not gueltig(view) then return false end
        local seite = zielSeite(view)
        if not gueltig(seite) then return false end
        local baum;   pcall(function() baum = seite.WidgetTree end)
        if not gueltig(baum) then return false end
        local wurzel; pcall(function() wurzel = baum.RootWidget end)
        if not gueltig(wurzel) then return false end
        local n = -1; pcall(function() n = wurzel:GetChildrenCount() end)
        if n < 0 or n > 64 then return false end
        for i = 0, n - 1 do
            local kind; pcall(function() kind = wurzel:GetChildAt(i) end)
            if gueltig(kind) then
                local nm = ""; pcall(function() nm = kind:GetFullName() end)
                if nm ~= "" and nm == matrixName then return true end
            end
        end
        return false
    end

    local function vergessen(warum)
        if not offen and not matrix then return end
        offen = false
        SCHRIFT, PINSELQUELLE = nil, nil
        matrix, legendeTB, warnTB, warZuvor, gebautBei = nil, nil, nil, nil, -1
        matrixName = nil
        ZELLEN = {}
        p("  display released (" .. warum .. ") - rebuilt on next open")
    end

    local function annehmen(view, woher)
        if not gueltig(view) then return end
        local vn = "?"; pcall(function() vn = view:GetFullName() end)
        if offen and vn == warZuvor then return end
        local nochDa = false
        if vn == warZuvor then
            p("  checking display")
            nochDa = tafelLebtNoch(view)
        end
        if nochDa then
            offen = true
            p("  display reused - no rebuild")
            return
        end
        vergessen("new view")
        warZuvor = vn
        p("  PDA detected via " .. woher)
        local okE, warten = einhaengen(view)
        if okE then
            offen = true
            bauFehler = 0
        elseif warten then
            warZuvor = nil
        else
            bauFehler = bauFehler + 1
            if bauFehler == 3 then
                p("  giving up after 3 failed builds - will retry on a new view")
            end
        end
    end

    if type(LoopAsync) ~= "function" then
        p("LoopAsync missing - no live values")
    else
        local takt = 0
        local HERZTAKT = ENTWICKLER and 40 or 120
        local warOffen = false
        LoopAsync(500, function()
            takt = takt + 1
            if not warOffen and takt % 2 ~= 0 then return false end
            imFaden(function()
                local t0 = ENTWICKLER and os.clock() or nil
                local offenJetzt, viewJetzt = pdaOffen()
                if t0 and takt % 20 == 0 then
                    p(string.format("  PDA open took %.3f ms", (os.clock() - t0) * 1000))
                end
                warOffen = offenJetzt

                if offenJetzt then
                    if takt % 4 == 0 and not nativLesen() then logLesen() end
                    local jetzt = os.time()
                    if jetzt - letzteAuffrischung >= 60 then
                        letzteAuffrischung = jetzt
                        auffrischen()
                    end
                end

                if takt % HERZTAKT == 0 then
                    letztSpeichern()
                    p(string.format("  heartbeat %d: %d of 169 cells live, PDA %s, source %s",
                                    takt, gemessen(), offenJetzt and "open" or "closed", nativDa and "game" or "quests"))
                end

                if not offenJetzt then
                    if offen then
                        offen = false
                        p("  PDA closed - display kept (no rebuild needed)")
                    end
                    return
                end

                local view = viewJetzt
                local vn = "?"; pcall(function() vn = view:GetFullName() end)
                if vn ~= warZuvor then
                    bauFehler = 0
                    annehmen(view, "tick scan")
                elseif not offen and bauFehler < 3 then
                    annehmen(view, "PDA reopened")
                elseif takt % 10 == 0 and (gemessen() ~= gebautBei or nativNeu) then
                    if tafelLebtNoch(view) then
                        gebautBei = gemessen()
                        nativNeu = false
                        aktualisieren()
                    else
                        vergessen("display vanished - name check failed")
                    end
                end
            end)
            return false
        end)
        p("FactionMatrix " .. VERSION .. " loaded. Open the PDA, tab: " .. TITEL)
    end
end

