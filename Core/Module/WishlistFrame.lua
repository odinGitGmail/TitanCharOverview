local AddonName, ns = ...
local L = ns.L
local LibBG = ns.LibBG
local RGB = ns.RGB
local GetClassRGB = ns.GetClassRGB
local HopeMaxb = ns.HopeMaxb
local HopeMaxn = ns.HopeMaxn
local HopeMaxi = ns.HopeMaxi
local HOPE_UI_VERSION = 10

local function EnsureHopeSaved()
    local realmID = GetRealmID()
    local player = BG.playerName
    BiaoGe.Hope = BiaoGe.Hope or {}
    BiaoGe.Hope[realmID] = BiaoGe.Hope[realmID] or {}
    BiaoGe.Hope[realmID][player] = BiaoGe.Hope[realmID][player] or {}
    for _, FB in ipairs(BG.FBtable) do
        BiaoGe.Hope[realmID][player][FB] = BiaoGe.Hope[realmID][player][FB] or {}
        local nanduCount = (HopeMaxn and HopeMaxn[FB]) or 1
        for n = 1, nanduCount do
            BiaoGe.Hope[realmID][player][FB]["nandu" .. n] =
                BiaoGe.Hope[realmID][player][FB]["nandu" .. n] or {}
            local bossCount = (HopeMaxb and HopeMaxb[FB]) or 12
            for b = 1, bossCount do
                BiaoGe.Hope[realmID][player][FB]["nandu" .. n]["boss" .. b] =
                    BiaoGe.Hope[realmID][player][FB]["nandu" .. n]["boss" .. b] or {}
            end
        end
    end
end

local function IsTCOHopeWidget(widget, hopeFrame)
    return widget
        and hopeFrame
        and widget.GetObjectType
        and widget:GetObjectType() == "EditBox"
        and widget:GetParent() == hopeFrame
end

local function HopeContentHeight(FB)
    local rows = (HopeMaxb and HopeMaxb[FB]) or 12
    local nandu = (HopeMaxn and HopeMaxn[FB]) or 1
    return 40 + nandu * (50 + rows * 22)
end

local function ApplyWishlistWindowSize(FB)
    if not BG.WishlistWindow or not FB then return end
    local w = (BG.FBWidth and BG.FBWidth[FB]) or 1275
    local h = (BG.FBHeight and BG.FBHeight[FB]) or 810
    BG.WishlistWindow:SetSize(w, h)
    local contentHeight = HopeContentHeight(FB)
    if BG.HopeMainFrame then
        BG.HopeMainFrame:SetSize(w - 2, contentHeight)
    end
    if BG["HopeFrame" .. FB] then
        BG["HopeFrame" .. FB]:SetSize(w - 48, contentHeight)
    end
end

local function SwitchHopeFB(FB)
    if not FB or not BG["HopeFrame" .. FB] then
        FB = BG.FBtable and BG.FBtable[1]
    end
    if not FB then return end

    BG.FB1 = FB
    BiaoGe.FB = FB
    BiaoGe.lastFrame = "Hope"

    if BG.FrameHide then
        BG.FrameHide(0)
    end

    for _, fb in ipairs(BG.FBtable) do
        if BG["HopeFrame" .. fb] then
            BG["HopeFrame" .. fb]:SetShown(fb == FB)
        end
        if BG.WishlistFBButtons and BG.WishlistFBButtons[fb] then
            BG.WishlistFBButtons[fb]:SetEnabled(fb ~= FB)
        end
        if BG.TCOHopeToolbar and BG.TCOHopeToolbar[fb] then
            for _, w in ipairs(BG.TCOHopeToolbar[fb]) do
                if w.SetShown then
                    w:SetShown(fb == FB)
                end
            end
        end
    end

    ApplyWishlistWindowSize(FB)

    if BG.HopeSenddropDown and BG.HopeSenddropDown[FB] and BiaoGe.HopeSendChannel then
        LibBG:UIDropDownMenu_SetText(BG.HopeSenddropDown[FB], BG.HopeSendTable[BiaoGe.HopeSendChannel])
    end
    if BG.UpdateHopeFrame_IsLooted_All then
        BG.UpdateHopeFrame_IsLooted_All()
    end
end

local function HopeGridMissing(FB)
    local hopeFrame = BG["HopeFrame" .. FB]
    if not hopeFrame or not hopeFrame.isTCOHope then
        return true
    end
    if not HopeMaxn or not HopeMaxn[FB] or not HopeMaxb or not HopeMaxb[FB] then
        return true
    end
    local grid = BG.HopeFrame and BG.HopeFrame[FB]
    if not grid then
        return true
    end
    for n = 1, HopeMaxn[FB] do
        for b = 1, HopeMaxb[FB] do
            if not IsTCOHopeWidget(grid["nandu" .. n]["boss" .. b]["zhuangbei1"], hopeFrame) then
                return true
            end
            local bossName = grid["nandu" .. n]["boss" .. b]["name"]
            if not bossName or not bossName.GetObjectType or bossName:GetObjectType() ~= "FontString" then
                return true
            end
        end
    end
    return false
end

local function RunHopeUI(FB)
    EnsureHopeSaved()
    local ok, result = pcall(BG.HopeUI, FB)
    if not ok then
        print("|cff00BFFF<TCO>|r 心愿 UI 构建失败 [" .. tostring(FB) .. "]:", tostring(result))
        return false
    end
    return result == true
end

local function BuildHopeFrames(parent)
    BG.TCOHopeUIBuilt = BG.TCOHopeUIBuilt or {}
    local maxHeight = 120
    for _, FB in ipairs(BG.FBtable) do
        if not BG.TCOHopeUIBuilt[FB] then
            local hf = CreateFrame("Frame", "TCO.HopeFrame" .. FB, parent)
            hf.isTCOHope = true
            hf:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
            hf:Hide()
            BG["HopeFrame" .. FB] = hf
            if RunHopeUI(FB) then
                BG.TCOHopeUIBuilt[FB] = true
            end
        end
        local h = HopeContentHeight(FB)
        if h > maxHeight then
            maxHeight = h
        end
    end
    parent:SetSize((BG.FBWidth and BG.FBWidth[BG.FB1]) or 1275, maxHeight)
    for _, fb in ipairs(BG.FBtable) do
        if BG["HopeFrame" .. fb] then
            BG["HopeFrame" .. fb]:SetWidth(parent:GetWidth())
            BG["HopeFrame" .. fb]:SetHeight(HopeContentHeight(fb))
        end
    end
end

StaticPopupDialogs["TCO_CLEAR_HOPE"] = {
    text = L["确定清空心愿？"],
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function()
        BG.TCOClearHope(BG.TCOClearHopeFB or BG.FB1 or BiaoGe.FB)
        BG.PlaySound(1)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    showAlert = true,
}

local function EnsureWishlistClearButton(f, shell)
    if not f or not shell then return end
    if not BG.ButtonHopeQingKong then
        local clearBt = BG.CreateButton(shell)
        clearBt:SetSize(120, 25)
        clearBt:SetText(L["清空心愿"])
        clearBt:SetScript("OnClick", function()
            BG.TCOClearHopeFB = BG.FB1 or BiaoGe.FB
            StaticPopup_Show("TCO_CLEAR_HOPE")
            BG.PlaySound(1)
        end)
        BG.ButtonHopeQingKong = clearBt
    end
    local clearBt = BG.ButtonHopeQingKong
    clearBt:SetParent(shell)
    clearBt:ClearAllPoints()
    clearBt:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 30, 38)
    clearBt:SetFrameLevel(shell:GetFrameLevel() + 30)
    clearBt:Show()
end

local function EnsureWishlistShellFixed(f)
    if not f then return end
    if f.tcoShellVersion == HOPE_UI_VERSION then return end
    f.tcoShellVersion = HOPE_UI_VERSION
    f:SetBackdropColor(0, 0, 0, 0)

    if not f.content then
        f.content = CreateFrame("Frame", nil, f)
        f.content:SetAllPoints()
    end
    f.content:SetFrameLevel(f:GetFrameLevel() + 100)

    if f.titleBg then
        f.titleBg:SetDrawLayer("BACKGROUND", 1)
    end
    if f.Bg then
        f.Bg:SetDrawLayer("BACKGROUND", 0)
    end

    if f.CloseButton then
        f.CloseButton:SetParent(f.content)
        f.CloseButton:SetFrameLevel(f.content:GetFrameLevel() + 20)
    end
    if f.titleText then
        f.titleText:SetParent(f.content)
    end
    if BG.WishlistTabButtonsFB then
        BG.WishlistTabButtonsFB:SetParent(f.content)
        BG.WishlistTabButtonsFB:SetFrameLevel(f.content:GetFrameLevel() + 5)
    end
    if BG.HopeMainFrame then
        BG.HopeMainFrame:SetParent(f.content)
        BG.HopeMainFrame:SetFrameLevel(f.content:GetFrameLevel() + 10)
    end
    EnsureWishlistClearButton(f, f.content)
end

local function ResetWishlistWindowIfStale()
    if not BG.WishlistWindow then return end
    if BG.WishlistWindow.tcoShellVersion == HOPE_UI_VERSION then return end
    BG.WishlistWindow:Hide()
    BG.WishlistWindow = nil
    BG.HopeMainFrame = nil
    BG.ButtonHopeQingKong = nil
    BG.TCOHopeUIBuilt = {}
    BG.TCOHopeUIVersion = nil
end

local function TryRebuildHopeUI()
    if not BG.WishlistWindow or not BG.HopeMainFrame then return end
    EnsureWishlistShellFixed(BG.WishlistWindow)
    if BG.TCOHopeUIVersion ~= HOPE_UI_VERSION then
        BG.TCOHopeUIVersion = HOPE_UI_VERSION
        BG.TCOHopeUIBuilt = {}
    end
    BG.TCOHopeUIBuilt = BG.TCOHopeUIBuilt or {}
    for _, FB in ipairs(BG.FBtable) do
        local hf = BG["HopeFrame" .. FB]
        if not hf then
            hf = CreateFrame("Frame", "TCO.HopeFrame" .. FB, BG.HopeMainFrame)
            hf.isTCOHope = true
            hf:Hide()
            BG["HopeFrame" .. FB] = hf
        elseif not hf.isTCOHope then
            hf.isTCOHope = true
        end
        if not hf:GetPoint() then
            hf:SetPoint("TOPLEFT", BG.HopeMainFrame, "TOPLEFT", 0, 0)
        end
        if HopeGridMissing(FB) then
            BG.TCOHopeUIBuilt[FB] = nil
            local oldFrame = BG["HopeFrame" .. FB]
            if oldFrame then
                oldFrame:Hide()
                oldFrame:SetParent(nil)
            end
            hf = CreateFrame("Frame", "TCO.HopeFrame" .. FB, BG.HopeMainFrame)
            hf.isTCOHope = true
            hf:SetPoint("TOPLEFT", BG.HopeMainFrame, "TOPLEFT", 0, 0)
            hf:Hide()
            BG["HopeFrame" .. FB] = hf
            if BG.HopeFrame then
                BG.HopeFrame[FB] = nil
            end
        elseif not hf:GetPoint() then
            hf:SetPoint("TOPLEFT", BG.HopeMainFrame, "TOPLEFT", 0, 0)
        end
        if not BG.TCOHopeUIBuilt[FB] and RunHopeUI(FB) then
            BG.TCOHopeUIBuilt[FB] = true
        end
        if BG.TCOCleanupHopeOverlays then
            BG.TCOCleanupHopeOverlays(FB)
        end
        if BG.TCOPatchHopeEditBg and HopeMaxn and HopeMaxn[FB] and BG.HopeFrame and BG.HopeFrame[FB] then
            for n = 1, HopeMaxn[FB] do
                for b = 1, HopeMaxb[FB] do
                    for i = 1, HopeMaxi do
                        local bt = BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i]
                        if bt then
                            BG.TCOPatchHopeEditBg(bt)
                        end
                    end
                end
            end
        end
    end
    SwitchHopeFB(BiaoGe.FB or BG.FB1)
    if BG.WishlistWindow and BG.WishlistWindow.content then
        EnsureWishlistClearButton(BG.WishlistWindow, BG.WishlistWindow.content)
    end
end

local function StyleWishlistShell(f)
    local r, g, b = GetClassRGB(nil, "player")
    f:SetBackdrop({
        edgeFile = "Interface/ChatFrame/ChatFrameBackground",
        edgeSize = 1,
    })
    -- BackdropTemplate 默认会填不透明黑底，视觉上像整窗遮罩；与 BGLite MainFrame 一致只保留边框
    f:SetBackdropColor(0, 0, 0, 0)
    f:SetBackdropBorderColor(r, g, b, BG.borderAlpha)
    f:SetMovable(true)
    f:SetToplevel(true)
    -- 对齐 BiaoGe：仅标题栏可拖动，避免整窗 EnableMouse 吞掉格子点击
    local drag = CreateFrame("Frame", nil, f)
    drag:SetPoint("TOPLEFT")
    drag:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, -22)
    drag:EnableMouse(true)
    drag:SetScript("OnMouseUp", function()
        f:StopMovingOrSizing()
    end)
    drag:SetScript("OnMouseDown", function()
        if BG.FrameHide then
            BG.FrameHide(0)
        end
        if LibBG.CloseDropDownMenus then
            LibBG:CloseDropDownMenus()
        end
        if BG.ClearFocus then
            BG.ClearFocus()
        end
        f:StartMoving()
    end)
    f:SetScript("OnHide", function()
        if BG.FrameHide then
            BG.FrameHide(0)
        end
    end)

    local l = f:CreateLine()
    l:SetColorTexture(r, g, b, BG.borderAlpha)
    l:SetStartPoint("TOPLEFT", 1, -21)
    l:SetEndPoint("TOPRIGHT", -1, -21)
    l:SetThickness(1)

    f.titleBg = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    f.titleBg:SetPoint("TOPLEFT")
    f.titleBg:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, -22)
    f.titleBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    f.titleBg:SetGradient("VERTICAL", CreateColor(r, g, b, .2), CreateColor(r, g, b, .0))

    f.Bg = f:CreateTexture(nil, "BACKGROUND", nil, 0)
    f.Bg:SetAllPoints()
    f.Bg:SetColorTexture(.01, .01, .01, BiaoGe.options and BiaoGe.options.alpha or .8)

    BG.CreateCloseButton(f)
    f.CloseButton:SetFrameLevel(f:GetFrameLevel() + 50)
    f.CloseButton:SetScript("OnClick", function()
        f:Hide()
        BG.PlaySound(1)
    end)

    f.titleText = f:CreateFontString(nil, "ARTWORK")
    f.titleText:SetPoint("TOP", 0, -4)
    f.titleText:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
    f.titleText:SetTextColor(RGB("00BFFF"))
    f.titleText:SetText(L["< 心愿清单 >"])

    -- 所有交互控件挂到 content，避免 BackdropTemplate 底色盖住子控件
    f.content = CreateFrame("Frame", nil, f)
    f.content:SetAllPoints()
    f.content:SetFrameLevel(f:GetFrameLevel() + 100)
    f.titleText:SetParent(f.content)
    f.CloseButton:SetParent(f.content)
    f.CloseButton:SetFrameLevel(f.content:GetFrameLevel() + 20)
    f.tcoShellVersion = HOPE_UI_VERSION
end

local function CreateWishlistFBButtons(parent)
    local shell = BG.WishlistWindow and BG.WishlistWindow.content or parent
    BG.WishlistFBButtons = {}
    BG.WishlistTabButtonsFB = CreateFrame("Frame", nil, shell)
    BG.WishlistTabButtonsFB:SetPoint("TOP", parent, "TOP", 0, -28)
    BG.WishlistTabButtonsFB:SetHeight(20)

    local lastBtn
    local totalWidth = 0
    local seenFB = {}
    for _, v in ipairs(BG.FBtable2 or {}) do
        local FB = v.FB
        if not seenFB[FB] then
            seenFB[FB] = true
        local bt = CreateFrame("Button", nil, BG.WishlistTabButtonsFB)
        bt:SetHeight(BG.WishlistTabButtonsFB:GetHeight())
        bt:SetNormalFontObject(BG.FontBlue15)
        bt:SetDisabledFontObject(BG.FontWhite15)
        bt:SetHighlightFontObject(BG.FontWhite15)
        if not lastBtn then
            bt:SetPoint("LEFT")
        else
            bt:SetPoint("LEFT", lastBtn, "RIGHT", 0, 0)
        end
        bt:SetText(BG.GetFBinfo(FB, "shortName") or FB)
        local fs = bt:GetFontString()
        bt:SetWidth((fs and fs:GetStringWidth() or 60) + 20)
        bt:SetHighlightTexture("Interface/PaperDollInfoFrame/UI-Character-Tab-Highlight")
        bt:SetScript("OnClick", function()
            SwitchHopeFB(FB)
            BG.PlaySound(1)
        end)
        BG.WishlistFBButtons[FB] = bt
        totalWidth = totalWidth + bt:GetWidth()
        lastBtn = bt
        end
    end
    if totalWidth > 0 then
        BG.WishlistTabButtonsFB:SetWidth(totalWidth)
    end
    BG.WishlistTabButtonsFB:SetFrameLevel(shell:GetFrameLevel() + 5)

    local line = BG.WishlistTabButtonsFB:CreateLine()
    line:SetColorTexture(GetClassRGB(nil, "player", BG.borderAlpha))
    line:SetStartPoint("BOTTOMLEFT", -10, -3)
    line:SetEndPoint("BOTTOMRIGHT", 10, -3)
    line:SetThickness(1.5)
end

local function BuildWishlistWindow()
    ResetWishlistWindowIfStale()
    if BG.WishlistWindow then
        TryRebuildHopeUI()
        return
    end

    EnsureHopeSaved()

    local f = CreateFrame("Frame", "TCO_WishlistWindow", UIParent, "BackdropTemplate")
    f:SetPoint("CENTER")
    f:SetFrameLevel(100)
    f:Hide()
    StyleWishlistShell(f)
    BG.WishlistWindow = f
    tinsert(UISpecialFrames, "TCO_WishlistWindow")

    if BiaoGe.options and BiaoGe.options.scale then
        f:SetScale(BiaoGe.options.scale)
    end

    local shell = f.content
    CreateWishlistFBButtons(f)

    BG.HopeMainFrame = CreateFrame("Frame", nil, shell)
    BG.HopeMainFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -48)
    BG.HopeMainFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 42)
    BG.HopeMainFrame:SetFrameLevel(shell:GetFrameLevel() + 10)
    BG.HopeMainFrame:EnableMouse(false)

    BuildHopeFrames(BG.HopeMainFrame)

    BG.HopeMainFrame:SetScript("OnShow", function()
        SwitchHopeFB(BiaoGe.FB or BG.FB1)
    end)

    -- 底部提示（BGLite 心愿页同款文案）
    local hint = shell:CreateFontString(nil, "ARTWORK")
    hint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 35, 45)
    hint:SetFont(BIAOGE_TEXT_FONT, 20, "OUTLINE")
    hint:SetTextColor(RGB(BG.g1))
    hint:SetText(L["心愿装备只要掉落就会有提醒，并且掉落后自动关注团长拍卖"])

    EnsureWishlistClearButton(f, shell)

    BG.HopeDaoChuUI()

    f:SetScript("OnShow", function()
        if f.Bg then
            f.Bg:SetColorTexture(.01, .01, .01, BiaoGe.options and BiaoGe.options.alpha or .8)
        end
        SwitchHopeFB(BiaoGe.FB or BG.FB1)
        if BG.WishlistFBButtons then
            for fb, bt in pairs(BG.WishlistFBButtons) do
                bt:SetEnabled(fb ~= BG.FB1)
            end
        end
        if BG.ButtonImportHope then
            BG.ButtonImportHope:SetParent(shell)
            BG.ButtonExportHope:SetParent(shell)
            BG.ButtonImportHope:ClearAllPoints()
            BG.ButtonExportHope:ClearAllPoints()
            BG.ButtonImportHope:SetPoint("TOPRIGHT", f, "TOPRIGHT", -28, -4)
            BG.ButtonExportHope:SetPoint("RIGHT", BG.ButtonImportHope, "LEFT", -10, 0)
            BG.ButtonImportHope:Show()
            BG.ButtonExportHope:Show()
        end
        EnsureWishlistClearButton(f, shell)
    end)

    ApplyWishlistWindowSize(BiaoGe.FB or BG.FB1)
end

function BG.OpenWishlist()
    if not BG.IsTitan then
        print("|cff00BFFF<TCO>|r 心愿清单仅支持时光服。")
        return
    end
    local ok, err = pcall(function()
        BuildWishlistWindow()
        TryRebuildHopeUI()
        if not BG.WishlistWindow then
            error("窗口未创建")
        end
        if BG.WishlistWindow:IsVisible() then
            BG.WishlistWindow:Hide()
        else
            BG.WishlistWindow:Show()
        end
    end)
    if not ok then
        print("|cff00BFFF<TCO>|r 心愿清单打开失败:", tostring(err))
    end
end

BG.Init2(function()
    if not BG.IsTitan then return end
    BuildWishlistWindow()
end)
