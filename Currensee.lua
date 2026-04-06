-- Currensee.lua
-- Track all WoW currencies across all your characters, with a full UI.
-- Repo: https://github.com/fstubner/currensee-wow

local ADDON_NAME    = "Currensee"
local ADDON_VERSION = "3.0.0"

-- Layout constants
local WINDOW_W      = 820
local WINDOW_H      = 560
local HEADER_H      = 26
local ROW_H         = 22
local COL_NAME_W    = 250
local COL_TOTAL_W   = 70
local COL_CHAR_W    = 80
local MAX_CHAR_COLS = 5

-- ---------------------------------------------------------------------------
-- Snapshot: walk the live currency list and capture every entry + its category
-- ---------------------------------------------------------------------------

local function getCharacterKey()
    return GetUnitName("player", true) .. " - " .. GetRealmName()
end

local function snapshot()
    local charKey = getCharacterKey()

    if not Currensee_Data[charKey] then
        Currensee_Data[charKey] = { currencies = {}, ilvl = 0 }
    end

    local currencies  = {}
    local numEntries  = C_CurrencyInfo.GetCurrencyListSize()
    local currentCat  = "Other"

    for i = 1, numEntries do
        local info = C_CurrencyInfo.GetCurrencyListInfo(i)
        if info then
            if info.isHeader then
                currentCat = info.name or "Other"
            elseif info.currencyID and info.quantity ~= nil then
                currencies[info.currencyID] = {
                    name           = info.name,
                    quantity       = info.quantity,
                    category       = currentCat,
                    weeklyMax      = info.weeklyMax      or 0,
                    earnedThisWeek = info.earnedThisWeek or 0,
                }
            end
        end
    end

    Currensee_Data[charKey].currencies = currencies
    local _, equippedIlvl = GetAverageItemLevel()
    Currensee_Data[charKey].ilvl = math.floor((equippedIlvl or 0) * 10) / 10
end

-- ---------------------------------------------------------------------------
-- Build display data: flat ordered list of header/currency rows
-- ---------------------------------------------------------------------------

local displayData = {}
local charColumns = {}
local colOffset   = 0

local function buildDisplayData()
    displayData = {}
    charColumns = {}

    for charKey in pairs(Currensee_Data) do
        table.insert(charColumns, charKey)
    end
    table.sort(charColumns)

    local cats     = {}
    local catOrder = {}

    for charKey, data in pairs(Currensee_Data) do
        if data.currencies then
            for id, entry in pairs(data.currencies) do
                local cat = entry.category or "Other"
                if not cats[cat] then
                    cats[cat] = {}
                    table.insert(catOrder, cat)
                end
                if not cats[cat][id] then
                    cats[cat][id] = { id = id, name = entry.name, total = 0,
                                      weeklyMax = entry.weeklyMax or 0, chars = {} }
                end
                if entry.quantity and entry.quantity > 0 then
                    cats[cat][id].chars[charKey] = {
                        qty            = entry.quantity,
                        earnedThisWeek = entry.earnedThisWeek or 0,
                    }
                    cats[cat][id].total = cats[cat][id].total + entry.quantity
                end
            end
        end
    end

    table.sort(catOrder)

    for _, cat in ipairs(catOrder) do
        table.insert(displayData, { type = "header", text = cat })
        local rows = {}
        for _, row in pairs(cats[cat]) do
            if row.total > 0 then table.insert(rows, row) end
        end
        table.sort(rows, function(a, b) return a.name < b.name end)
        for _, row in ipairs(rows) do
            table.insert(displayData, { type = "currency", data = row })
        end
    end
end

-- ---------------------------------------------------------------------------
-- UI state
-- ---------------------------------------------------------------------------

local UI = {}

local function refreshUI()
    if not UI.frame or not UI.frame:IsShown() then return end

    buildDisplayData()

    for i = 1, MAX_CHAR_COLS do
        local charKey = charColumns[colOffset + i]
        if charKey then
            local name = charKey:match("^(.-)%s*%-") or charKey
            UI.colHeaders[i]:SetText(name)
        else
            UI.colHeaders[i]:SetText("")
        end
    end

    UI.prevBtn:SetEnabled(colOffset > 0)
    UI.nextBtn:SetEnabled(colOffset + MAX_CHAR_COLS < #charColumns)

    local dp = CreateDataProvider()
    for _, item in ipairs(displayData) do dp:Insert(item) end
    UI.view:SetDataProvider(dp)
end

-- ---------------------------------------------------------------------------
-- Element initializer
-- ---------------------------------------------------------------------------

local function initRow(row, elementData)
    if not row._bg then
        row._bg = row:CreateTexture(nil, "BACKGROUND")
        row._bg:SetAllPoints()
    end
    if not row._nameFS then
        row._nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row._nameFS:SetPoint("LEFT", 8, 0)
        row._nameFS:SetWidth(COL_NAME_W - 10)
        row._nameFS:SetJustifyH("LEFT")
        row._nameFS:SetWordWrap(false)
    end
    if not row._totalFS then
        row._totalFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row._totalFS:SetPoint("LEFT", COL_NAME_W + 8, 0)
        row._totalFS:SetWidth(COL_TOTAL_W)
        row._totalFS:SetJustifyH("RIGHT")
    end
    if not row._charFS then row._charFS = {} end
    for i = 1, MAX_CHAR_COLS do
        if not row._charFS[i] then
            local xOff = COL_NAME_W + COL_TOTAL_W + 16 + (i - 1) * COL_CHAR_W
            row._charFS[i] = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row._charFS[i]:SetPoint("LEFT", xOff, 0)
            row._charFS[i]:SetWidth(COL_CHAR_W - 4)
            row._charFS[i]:SetJustifyH("RIGHT")
        end
    end

    if elementData.type == "header" then
        row._bg:SetColorTexture(0.12, 0.10, 0.06, 0.9)
        row._nameFS:SetText(elementData.text)
        row._nameFS:SetTextColor(1, 0.82, 0)
        row._nameFS:SetFontObject("GameFontNormal")
        row._totalFS:SetText("")
        for i = 1, MAX_CHAR_COLS do row._charFS[i]:SetText("") end
        row:SetScript("OnEnter", nil)
        row:SetScript("OnLeave", nil)
    else
        row._bg:SetColorTexture(0, 0, 0, 0)
        local d = elementData.data
        row._nameFS:SetText(d.name)
        row._nameFS:SetTextColor(0.9, 0.9, 0.9)
        row._nameFS:SetFontObject("GameFontNormalSmall")
        row._totalFS:SetText(BreakUpLargeNumbers(d.total))
        row._totalFS:SetTextColor(1, 0.82, 0)

        for i = 1, MAX_CHAR_COLS do
            local charKey = charColumns[colOffset + i]
            local fs = row._charFS[i]
            if charKey then
                local entry = d.chars[charKey]
                local qty = entry and entry.qty or 0
                if qty > 0 then
                    fs:SetText(BreakUpLargeNumbers(qty))
                    if d.weeklyMax > 0 and entry and entry.earnedThisWeek >= d.weeklyMax then
                        fs:SetTextColor(0.4, 0.9, 0.4)
                    else
                        fs:SetTextColor(1, 0.82, 0)
                    end
                else
                    fs:SetText("|cff444444\226\128\148|r")
                end
            else
                fs:SetText("")
            end
        end

        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(d.name, 1, 0.82, 0)
            local sorted = {}
            for ck, e in pairs(d.chars) do
                table.insert(sorted, { key = ck, qty = e.qty })
            end
            table.sort(sorted, function(a, b) return a.qty > b.qty end)
            GameTooltip:AddLine(" ")
            for _, v in ipairs(sorted) do
                local name = v.key:match("^(.-)%s*%-") or v.key
                GameTooltip:AddDoubleLine(name, BreakUpLargeNumbers(v.qty),
                                          0.8, 0.8, 0.8, 1, 0.82, 0)
            end
            if d.weeklyMax > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Weekly cap: " .. BreakUpLargeNumbers(d.weeklyMax), 0.55, 0.55, 0.55)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
end

-- ---------------------------------------------------------------------------
-- Create the main window
-- ---------------------------------------------------------------------------

local function createUI()
    local f = CreateFrame("Frame", "CurrenseeMainFrame", UIParent,
                          "BasicFrameTemplateWithInset")
    f:SetSize(WINDOW_W, WINDOW_H)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetResizable(true)
    f:SetResizeBounds(600, 360, 1400, 900)
    f:SetFrameStrata("MEDIUM")
    f:Hide()

    f.TitleText:SetText("Currensee  |cff888888v" .. ADDON_VERSION .. "|r")

    if Currensee_UIPos then
        f:ClearAllPoints()
        f:SetPoint(Currensee_UIPos.point, UIParent, Currensee_UIPos.relPoint,
                   Currensee_UIPos.x, Currensee_UIPos.y)
    end
    f:SetScript("OnHide", function()
        local point, _, relPoint, x, y = f:GetPoint()
        Currensee_UIPos = { point = point, relPoint = relPoint, x = x, y = y }
    end)

    -- Column header bar
    local hBar = CreateFrame("Frame", nil, f.Inset)
    hBar:SetPoint("TOPLEFT", 2, -2)
    hBar:SetPoint("TOPRIGHT", -22, -2)
    hBar:SetHeight(HEADER_H)
    local hBg = hBar:CreateTexture(nil, "BACKGROUND")
    hBg:SetAllPoints()
    hBg:SetColorTexture(0.08, 0.07, 0.05, 1)

    local nameHdr = hBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameHdr:SetPoint("LEFT", 8, 0)
    nameHdr:SetText("Currency")
    nameHdr:SetTextColor(0.6, 0.6, 0.6)

    local totalHdr = hBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    totalHdr:SetPoint("LEFT", COL_NAME_W + 8, 0)
    totalHdr:SetWidth(COL_TOTAL_W)
    totalHdr:SetJustifyH("RIGHT")
    totalHdr:SetText("Total")
    totalHdr:SetTextColor(0.6, 0.6, 0.6)

    UI.colHeaders = {}
    for i = 1, MAX_CHAR_COLS do
        local xOff = COL_NAME_W + COL_TOTAL_W + 16 + (i - 1) * COL_CHAR_W
        local fs = hBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT", xOff, 0)
        fs:SetWidth(COL_CHAR_W - 4)
        fs:SetJustifyH("RIGHT")
        fs:SetTextColor(0.5, 0.8, 1)
        UI.colHeaders[i] = fs
    end

    UI.prevBtn = CreateFrame("Button", nil, f.Inset, "UIPanelButtonTemplate")
    UI.prevBtn:SetSize(20, 20)
    UI.prevBtn:SetPoint("TOPRIGHT", -22, -2)
    UI.prevBtn:SetText("<")
    UI.prevBtn:GetFontString():SetFontObject("GameFontNormalSmall")
    UI.prevBtn:SetScript("OnClick", function()
        if colOffset > 0 then colOffset = colOffset - 1; refreshUI() end
    end)

    UI.nextBtn = CreateFrame("Button", nil, f.Inset, "UIPanelButtonTemplate")
    UI.nextBtn:SetSize(20, 20)
    UI.nextBtn:SetPoint("TOPRIGHT", -2, -2)
    UI.nextBtn:SetText(">")
    UI.nextBtn:GetFontString():SetFontObject("GameFontNormalSmall")
    UI.nextBtn:SetScript("OnClick", function()
        if colOffset + MAX_CHAR_COLS < #charColumns then
            colOffset = colOffset + 1; refreshUI()
        end
    end)

    -- Scroll box
    local scrollBox = CreateFrame("Frame", nil, f.Inset, "WoWScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", 2, -(HEADER_H + 4))
    scrollBox:SetPoint("BOTTOMRIGHT", -22, 4)

    local scrollBar = CreateFrame("EventFrame", nil, f.Inset, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 2, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 2, 0)

    local view = CreateScrollBoxListLinearView()
    view:SetElementExtentCalculator(function(_, node)
        local data = node:GetData()
        return data.type == "header" and HEADER_H or ROW_H
    end)
    view:SetElementInitializer("Frame", initRow)
    view:SetDataProvider(CreateDataProvider())
    ScrollUtil.InitScrollBoxWithScrollBar(scrollBox, scrollBar, view)

    -- Resize grip
    local grip = CreateFrame("Button", nil, f)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetSize(16, 16)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() f:StopMovingOrSizing() end)

    -- Rescan button
    local rescanBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    rescanBtn:SetSize(80, 22)
    rescanBtn:SetPoint("BOTTOMLEFT", 10, 6)
    rescanBtn:SetText("Rescan")
    rescanBtn:SetScript("OnClick", function() snapshot(); refreshUI() end)

    UI.frame = f
    UI.view  = view
end

-- ---------------------------------------------------------------------------
-- Toggle
-- ---------------------------------------------------------------------------

function Currensee_Toggle()
    if not UI.frame then createUI() end
    if UI.frame:IsShown() then
        UI.frame:Hide()
    else
        colOffset = 0
        UI.frame:Show()
        refreshUI()
    end
end

-- ---------------------------------------------------------------------------
-- Addon Compartment
-- ---------------------------------------------------------------------------

local function registerCompartment()
    if not AddonCompartmentFrame then return end
    AddonCompartmentFrame:RegisterAddon({
        text         = "Currensee",
        icon         = "Interface\\Icons\\INV_Misc_Coin_02",
        notCheckable = true,
        func         = Currensee_Toggle,
        funcOnEnter  = function(_, _, button)
            GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
            GameTooltip:SetText("Currensee", 1, 0.82, 0)
            GameTooltip:AddLine("All your currencies, across all characters.", 1, 1, 1)
            GameTooltip:Show()
        end,
        funcOnLeave  = function() GameTooltip:Hide() end,
    })
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        if not Currensee_Data  then Currensee_Data  = {} end
        if not Currensee_UIPos then Currensee_UIPos = nil end
        registerCompartment()
    elseif event == "PLAYER_LOGIN" then
        snapshot()
    elseif event == "PLAYER_LOGOUT" then
        snapshot()
    end
end)

-- ---------------------------------------------------------------------------
-- Slash commands
-- ---------------------------------------------------------------------------

SLASH_CURRENSEE1 = "/currensee"
SLASH_CURRENSEE2 = "/cs"

SlashCmdList["CURRENSEE"] = function(msg)
    local cmd = strtrim(msg or ""):lower()
    if cmd == "" or cmd == "show" then
        Currensee_Toggle()
    elseif cmd == "rescan" or cmd == "refresh" then
        snapshot(); refreshUI()
        print("|cff00ccff[Currensee]|r Rescanned.")
    elseif cmd == "reset" then
        Currensee_Data = {}
        print("|cffff9900[Currensee]|r All data cleared.")
    else
        print("|cff00ccff[Currensee]|r  /cs \226\128\148 open/close  |  /cs rescan  |  /cs reset")
    end
end
