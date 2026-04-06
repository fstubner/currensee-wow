-- Currensee.lua
-- Track WoW Midnight currencies across all your characters.
-- Repo: https://github.com/fstubner/currensee-wow

local ADDON_NAME = "Currensee"

-- ---------------------------------------------------------------------------
-- Currency definitions for WoW Midnight (patch 12.0.x)
-- IDs sourced from wowhead.com/currencies/midnight
-- ---------------------------------------------------------------------------

local CATEGORIES = {
    { key = "crests",       label = "Dawncrests (Progression)" },
    { key = "zone",         label = "Zone Currencies"          },
    { key = "delves",       label = "Delves"                   },
    { key = "pvp",          label = "PvP"                      },
    { key = "professions",  label = "Professions"              },
    { key = "events",       label = "Events & Seasonal"        },
}

local CURRENCIES = {
    -- Progression / Gear Upgrade Crests
    { id = 3383, key = "adventurer_crest",  label = "Adventurer Dawncrest",       category = "crests",      short = "adventurer" },
    { id = 3341, key = "veteran_crest",     label = "Veteran Dawncrest",           category = "crests",      short = "veteran"    },
    { id = 3343, key = "champion_crest",    label = "Champion Dawncrest",          category = "crests",      short = "champion"   },
    { id = 3345, key = "hero_crest",        label = "Hero Dawncrest",              category = "crests",      short = "hero"       },
    { id = 3347, key = "myth_crest",        label = "Myth Dawncrest",              category = "crests",      short = "myth"       },

    -- Zone / World currencies
    { id = 3316, key = "voidlight_marl",    label = "Voidlight Marl",              category = "zone",        short = "marl"       },
    { id = 3379, key = "brimming_arcana",   label = "Brimming Arcana",             category = "zone",        short = "arcana"     },
    { id = 3377, key = "unalloyed",         label = "Unalloyed Abundance",         category = "zone",        short = "abundance"  },
    { id = 3376, key = "shard_dundun",      label = "Shard of Dundun",             category = "zone",        short = "dundun"     },
    { id = 3385, key = "luminous_dust",     label = "Luminous Dust",               category = "zone",        short = "dust"       },
    { id = 3392, key = "remnant_anguish",   label = "Remnant of Anguish",          category = "zone",        short = "remnant"    },
    { id = 3373, key = "angler_pearls",     label = "Angler Pearls",               category = "zone",        short = "pearls"     },

    -- Delves
    { id = 3310, key = "coffer_shards",     label = "Coffer Key Shards",           category = "delves",      short = "coffer"     },
    { id = 2803, key = "undercoin",         label = "Undercoin",                   category = "delves",      short = "undercoin"  },

    -- PvP
    { id = 1602, key = "conquest",          label = "Conquest",                    category = "pvp",         short = "conquest"   },
    { id = 1792, key = "honor",             label = "Honor",                       category = "pvp",         short = "honor"      },

    -- Professions (Artisan's Moxie per trade)
    { id = 3256, key = "moxie_alchemy",     label = "Alchemist's Moxie",           category = "professions", short = "alchemy"    },
    { id = 3257, key = "moxie_blacksmith",  label = "Blacksmith's Moxie",          category = "professions", short = "blacksmith" },
    { id = 3258, key = "moxie_enchanting",  label = "Enchanter's Moxie",           category = "professions", short = "enchanting" },
    { id = 3259, key = "moxie_engineering", label = "Engineer's Moxie",            category = "professions", short = "engineering"},
    { id = 3260, key = "moxie_herbalism",   label = "Herbalist's Moxie",           category = "professions", short = "herbalism"  },
    { id = 3261, key = "moxie_inscription", label = "Scribe's Moxie",              category = "professions", short = "inscription"},
    { id = 3262, key = "moxie_jewel",       label = "Jewelcrafter's Moxie",        category = "professions", short = "jewelcraft" },
    { id = 3263, key = "moxie_leather",     label = "Leatherworker's Moxie",       category = "professions", short = "leatherwork"},
    { id = 3264, key = "moxie_mining",      label = "Miner's Moxie",               category = "professions", short = "mining"     },
    { id = 3265, key = "moxie_skinning",    label = "Skinner's Moxie",             category = "professions", short = "skinning"   },
    { id = 3266, key = "moxie_tailoring",   label = "Tailor's Moxie",              category = "professions", short = "tailoring"  },

    -- Events & Seasonal
    { id = 3089, key = "residual_memories", label = "Residual Memories",           category = "events",      short = "memories"   },
    { id = 3319, key = "twilight_insignia", label = "Twilight's Blade Insignia",   category = "events",      short = "twilight"   },
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
        if info then
            Currensee_Data[charKey][currency.key] = info.quantity or 0
        end
    end

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

    if #rows == 0 then return end

    table.sort(rows, function(a, b) return a.value > b.value end)

    print(string.format("|cff00ccff[Currensee]|r %s", label))
    for _, row in ipairs(rows) do
        print(string.format("  |cffffd700%s|r  --  %s", row.value, row.key))
    end
end

local function printCategory(categoryKey)
    local printed = false
    for _, cat in ipairs(CATEGORIES) do
        if cat.key == categoryKey then
            print(string.format("|cff00ccff[Currensee]|r === %s ===", cat.label))
            printed = true
            break
        end
    end
    if not printed then return end

    for _, currency in ipairs(CURRENCIES) do
        if currency.category == categoryKey then
            printCurrencyTable(currency.key, currency.label)
        end
    end
end

local function printAll()
    print("|cff00ccff[Currensee]|r ========== All Characters ==========")
    for _, cat in ipairs(CATEGORIES) do
        print(string.format("|cff888888[Currensee]|r --- %s ---", cat.label))
        for _, currency in ipairs(CURRENCIES) do
            if currency.category == cat.key then
                printCurrencyTable(currency.key, currency.label)
            end
        end
    end
    printCurrencyTable("ilvl", "Equipped Item Level")
    print("|cff00ccff[Currensee]|r =====================================")
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

    if cmd == "" or cmd == "all" then
        printAll()
        return
    end

    if cmd == "ilvl" then
        printCurrencyTable("ilvl", "Equipped Item Level")
        return
    end

    if cmd == "reset" then
        Currensee_Data = {}
        print("|cffff9900[Currensee]|r All saved data cleared.")
        return
    end

    local categoryAliases = {
        crests = "crests", progression = "crests", dawncrest = "crests",
        zone = "zone", world = "zone",
        delves = "delves", delve = "delves",
        pvp = "pvp",
        professions = "professions", prof = "professions", profession = "professions",
        events = "events", seasonal = "events", event = "events",
    }
    if categoryAliases[cmd] then
        printCategory(categoryAliases[cmd])
        return
    end

    for _, currency in ipairs(CURRENCIES) do
        if cmd == currency.short or cmd == currency.key then
            printCurrencyTable(currency.key, currency.label)
            return
        end
    end

    print("|cff00ccff[Currensee]|r Commands:")
    print("  /cs              — All currencies across all characters")
    print("  /cs crests       — Dawncrests (progression)")
    print("  /cs zone         — Zone & world currencies")
    print("  /cs delves       — Delves currencies")
    print("  /cs pvp          — Honor & Conquest")
    print("  /cs professions  — Artisan's Moxie (all trades)")
    print("  /cs events       — Seasonal & event currencies")
    print("  /cs ilvl         — Equipped item level")
    print("  /cs myth         — (or any currency short name)")
    print("  /cs reset        — Clear all saved data")
end
