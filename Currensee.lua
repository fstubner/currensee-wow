-- Currensee.lua
-- Track WoW Midnight currencies across all your characters.
-- Repo: https://github.com/fstubner/currensee-wow

local ADDON_NAME = "Currensee"

-- ---------------------------------------------------------------------------
-- Currency definitions for WoW Midnight (patch 12.0.x)
-- IDs sourced from wowhead.com/currencies/midnight
-- The Dawncrests system replaced Harbinger Crests from The War Within.
-- ---------------------------------------------------------------------------
local CURRENCIES = {
    { id = 3383, key = "adventurer_crest", label = "Adventurer Dawncrest", short = "adventurer" },
    { id = 3341, key = "veteran_crest",    label = "Veteran Dawncrest",    short = "veteran"    },
    { id = 3343, key = "champion_crest",   label = "Champion Dawncrest",   short = "champion"   },
    { id = 3345, key = "hero_crest",       label = "Hero Dawncrest",       short = "hero"       },
    { id = 3347, key = "myth_crest",       label = "Myth Dawncrest",       short = "myth"       },
}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function getCharacterKey()
    return GetUnitName("player", true) .. " - " .. GetRealmName()
end

local function snapshot()
    local charKey = getCharacterKey()

    if not Currensee_Data[charKey] then
        Currensee_Data[charKey] = {}
    end

    for _, currency in ipairs(CURRENCIES) do
        local info = C_CurrencyInfo.GetCurrencyInfo(currency.id)
        Currensee_Data[charKey][currency.key] = info and info.quantity or 0
    end

    -- Track average equipped item level (second return value is equipped ilvl)
    local _, equippedIlvl = GetAverageItemLevel()
    Currensee_Data[charKey]["ilvl"] = math.floor((equippedIlvl or 0) * 10) / 10
end

local function printCurrencyTable(currencyKey, label)
    if not Currensee_Data or next(Currensee_Data) == nil then
        print("|cffff9900[Currensee]|r No data yet — log in on each character to populate.")
        return
    end

    local rows = {}
    for charKey, data in pairs(Currensee_Data) do
        local value = data[currencyKey]
        if value ~= nil then
            table.insert(rows, { key = charKey, value = value })
        end
    end

    if #rows == 0 then
        print(string.format("|cff00ccff[Currensee]|r No data for %s yet.", label))
        return
    end

    table.sort(rows, function(a, b) return a.value > b.value end)

    print(string.format("|cff00ccff[Currensee]|r --- %s ---", label))
    for _, row in ipairs(rows) do
        print(string.format("  |cffffd700%s|r  --  %s", row.value, row.key))
    end
end

-- ---------------------------------------------------------------------------
-- Event handling
-- ---------------------------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        if not Currensee_Data then
            Currensee_Data = {}
        end

    elseif event == "PLAYER_LOGIN" then
        snapshot()

    elseif event == "PLAYER_LOGOUT" then
        snapshot()
    end
end)

-- ---------------------------------------------------------------------------
-- Slash commands: /currensee or /cs
-- ---------------------------------------------------------------------------

SLASH_CURRENSEE1 = "/currensee"
SLASH_CURRENSEE2 = "/cs"

SlashCmdList["CURRENSEE"] = function(msg)
    local cmd = strtrim(msg or ""):lower()

    if cmd == "ilvl" then
        printCurrencyTable("ilvl", "Equipped Item Level")

    elseif cmd == "all" then
        for _, currency in ipairs(CURRENCIES) do
            printCurrencyTable(currency.key, currency.label)
        end
        printCurrencyTable("ilvl", "Equipped Item Level")

    elseif cmd == "reset" then
        Currensee_Data = {}
        print("|cffff9900[Currensee]|r All saved data cleared.")

    else
        -- Match by short name
        local matched = false
        for _, currency in ipairs(CURRENCIES) do
            if cmd == currency.short or cmd == currency.key then
                printCurrencyTable(currency.key, currency.label)
                matched = true
                break
            end
        end

        if not matched then
            print("|cff00ccff[Currensee]|r Commands:")
            print("  /cs all         — All currencies and item level")
            print("  /cs adventurer  — Adventurer Dawncrests")
            print("  /cs veteran     — Veteran Dawncrests")
            print("  /cs champion    — Champion Dawncrests")
            print("  /cs hero        — Hero Dawncrests")
            print("  /cs myth        — Myth Dawncrests")
            print("  /cs ilvl        — Equipped item level")
            print("  /cs reset       — Clear all saved data")
        end
    end
end
