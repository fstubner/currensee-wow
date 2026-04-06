-- Currensee.lua
-- Track ALL World of Warcraft currencies across all your characters.
-- Works with every expansion — current and legacy.
-- Repo: https://github.com/fstubner/currensee-wow

local ADDON_NAME = "Currensee"

-- ---------------------------------------------------------------------------
-- Snapshot: enumerate every currency the character has via the currency list
-- API. No hard-coded IDs — this picks up everything automatically, including
-- currencies from future patches.
-- ---------------------------------------------------------------------------

local function getCharacterKey()
    return GetUnitName("player", true) .. " - " .. GetRealmName()
end

local function snapshot()
    local charKey = getCharacterKey()

    if not Currensee_Data[charKey] then
        Currensee_Data[charKey] = { currencies = {}, ilvl = 0 }
    end

    local currencies = {}
    local numEntries = C_CurrencyInfo.GetCurrencyListSize()

    for i = 1, numEntries do
        local info = C_CurrencyInfo.GetCurrencyListInfo(i)
        if info and not info.isHeader and info.currencyID and info.quantity then
            currencies[info.currencyID] = {
                name           = info.name,
                quantity       = info.quantity,
                weeklyMax      = info.weeklyMax or 0,
                earnedThisWeek = info.earnedThisWeek or 0,
            }
        end
    end

    Currensee_Data[charKey].currencies = currencies

    local _, equippedIlvl = GetAverageItemLevel()
    Currensee_Data[charKey].ilvl = math.floor((equippedIlvl or 0) * 10) / 10
end

-- ---------------------------------------------------------------------------
-- Display helpers
-- ---------------------------------------------------------------------------

local function printHeader(text)
    print(string.format("|cff00ccff[Currensee]|r --- %s ---", text))
end

local function printNoData()
    print("|cffff9900[Currensee]|r No data yet — log in on each character to populate.")
end

-- Print a single currency row across all characters, sorted descending.
local function printCurrencyById(currencyId, label)
    local rows = {}
    for charKey, data in pairs(Currensee_Data) do
        local entry = data.currencies and data.currencies[currencyId]
        if entry and entry.quantity and entry.quantity > 0 then
            local suffix = ""
            if entry.weeklyMax and entry.weeklyMax > 0 then
                suffix = string.format(" (%d/%d this week)", entry.earnedThisWeek or 0, entry.weeklyMax)
            end
            table.insert(rows, { key = charKey, value = entry.quantity, suffix = suffix })
        end
    end

    if #rows == 0 then return false end

    table.sort(rows, function(a, b) return a.value > b.value end)
    printHeader(label)
    for _, row in ipairs(rows) do
        print(string.format("  |cffffd700%d|r%s  --  %s", row.value, row.suffix, row.key))
    end
    return true
end

-- Search currencies by name (partial, case-insensitive) across all chars.
local function searchCurrencies(query)
    query = query:lower()

    local matched = {}
    for _, data in pairs(Currensee_Data) do
        if data.currencies then
            for id, entry in pairs(data.currencies) do
                if entry.name and entry.name:lower():find(query, 1, true) then
                    matched[id] = entry.name
                end
            end
        end
    end

    if next(matched) == nil then
        print(string.format("|cffff9900[Currensee]|r No currencies matching '%s' found.", query))
        return
    end

    for id, name in pairs(matched) do
        printCurrencyById(id, name)
    end
end

-- Show item level across all characters.
local function printIlvl()
    local rows = {}
    for charKey, data in pairs(Currensee_Data) do
        if data.ilvl and data.ilvl > 0 then
            table.insert(rows, { key = charKey, value = data.ilvl })
        end
    end

    if #rows == 0 then printNoData(); return end

    table.sort(rows, function(a, b) return a.value > b.value end)
    printHeader("Equipped Item Level")
    for _, row in ipairs(rows) do
        print(string.format("  |cffffd700%.1f|r  --  %s", row.value, row.key))
    end
end

-- Show every currency that any character has, grouped by currency.
local function printAll()
    local allIds = {}
    for _, data in pairs(Currensee_Data) do
        if data.currencies then
            for id, entry in pairs(data.currencies) do
                if entry.quantity and entry.quantity > 0 then
                    allIds[id] = entry.name
                end
            end
        end
    end

    if next(allIds) == nil then printNoData(); return end

    local sorted = {}
    for id, name in pairs(allIds) do
        table.insert(sorted, { id = id, name = name })
    end
    table.sort(sorted, function(a, b) return a.name < b.name end)

    for _, entry in ipairs(sorted) do
        printCurrencyById(entry.id, entry.name)
    end

    printIlvl()
end

-- List all currencies for a single character.
local function printCharacter(query)
    query = query:lower()

    local found = nil
    for charKey, data in pairs(Currensee_Data) do
        if charKey:lower():find(query, 1, true) then
            found = { key = charKey, data = data }
            break
        end
    end

    if not found then
        print(string.format("|cffff9900[Currensee]|r No character matching '%s' found.", query))
        return
    end

    printHeader(found.key)

    if not found.data.currencies or next(found.data.currencies) == nil then
        print("  No currencies recorded.")
    else
        local rows = {}
        for _, entry in pairs(found.data.currencies) do
            if entry.quantity and entry.quantity > 0 then
                table.insert(rows, entry)
            end
        end
        table.sort(rows, function(a, b) return a.name < b.name end)
        for _, entry in ipairs(rows) do
            local suffix = ""
            if entry.weeklyMax and entry.weeklyMax > 0 then
                suffix = string.format(" (%d/%d this week)", entry.earnedThisWeek or 0, entry.weeklyMax)
            end
            print(string.format("  |cffffd700%d|r%s  --  %s", entry.quantity, suffix, entry.name))
        end
    end

    if found.data.ilvl and found.data.ilvl > 0 then
        print(string.format("  |cffffd700%.1f|r  --  Item Level", found.data.ilvl))
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
    if not Currensee_Data or next(Currensee_Data) == nil then
        printNoData(); return
    end

    local cmd, arg = msg:match("^(%S+)%s*(.*)")
    cmd = (cmd or msg):lower()
    arg = arg or ""

    if cmd == "" or cmd == "all" then
        printAll()
    elseif cmd == "ilvl" then
        printIlvl()
    elseif cmd == "char" or cmd == "character" then
        if arg == "" then
            printCharacter(GetUnitName("player", true))
        else
            printCharacter(arg)
        end
    elseif cmd == "reset" then
        Currensee_Data = {}
        print("|cffff9900[Currensee]|r All saved data cleared.")
    elseif cmd == "help" or cmd == "?" then
        print("|cff00ccff[Currensee]|r Commands:")
        print("  /cs                    — Show all currencies across characters")
        print("  /cs <name>             — Search currencies by name (partial match)")
        print("  /cs char               — All currencies for your current character")
        print("  /cs char <name>        — All currencies for a specific character")
        print("  /cs ilvl               — Item level across characters")
        print("  /cs reset              — Clear all saved data")
    else
        searchCurrencies(cmd .. (arg ~= "" and " " .. arg or ""))
    end
end
