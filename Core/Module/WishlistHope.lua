local _, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local RR = ns.RR
local NN = ns.NN
local RN = ns.RN
local Size = ns.Size
local RGB = ns.RGB
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local HopeMaxn = ns.HopeMaxn
local HopeMaxb = ns.HopeMaxb
local HopeMaxi = ns.HopeMaxi
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID

local pt = print
local RealmID = GetRealmID()
local player = BG.playerName

local function OpenHopeLootPicker(bt)
    if not bt then return end
    local fn = BG.TCOSetListzhuangbei or BG.SetListzhuangbei
    if fn then
        local ok, err = pcall(fn, bt)
        if ok then return end
        print("|cff00BFFF<TCO>|r 装备列表打开失败:", tostring(err))
    end
    if BG.TCOShowHopeLootList then
        BG.TCOShowHopeLootList(bt)
    end
end

function BG.TCOPatchHopeEditBg(bt)
    if not bt or bt.tcoHopeBgPatched then return end
    bt.tcoHopeBgPatched = true

    if bt.Left then bt.Left:Hide() end
    if bt.Middle then bt.Middle:Hide() end
    if bt.Right then bt.Right:Hide() end

    if bt.tcoEditLeft then return end

    bt.tcoEditLeft = bt:CreateTexture(nil, "BACKGROUND", nil, 0)
    bt.tcoEditLeft:SetPoint("LEFT", -5, 0)
    bt.tcoEditLeft:SetSize(8, 20)
    bt.tcoEditLeft:SetTexture("interface/common/commonsearch")
    bt.tcoEditLeft:SetTexCoord(.88, .95, .01, .31)

    bt.tcoEditRight = bt:CreateTexture(nil, "BACKGROUND", nil, 0)
    bt.tcoEditRight:SetPoint("RIGHT", 0, 0)
    bt.tcoEditRight:SetSize(8, 20)
    bt.tcoEditRight:SetTexture("interface/common/commonsearch")
    bt.tcoEditRight:SetTexCoord(0, .07, .338, .638)

    bt.tcoEditMiddle = bt:CreateTexture(nil, "BACKGROUND", nil, 0)
    bt.tcoEditMiddle:SetSize(10, 20)
    bt.tcoEditMiddle:SetPoint("LEFT", bt.tcoEditLeft, "RIGHT", 0, 0)
    bt.tcoEditMiddle:SetPoint("RIGHT", bt.tcoEditRight, "LEFT", 0, 0)
    bt.tcoEditMiddle:SetTexture("interface/common/commonsearch")
    bt.tcoEditMiddle:SetTexCoord(0, .8, .01, .31)
end

-- 时光服：与 BGLite 表格一致的 commonsearch 浅灰底
local function StyleHopeEditBox(bt)
    if not bt or bt.tcoHopeStyled then return end
    bt.tcoHopeStyled = true
    if BG.IsTitan and BG.TCOPatchHopeEditBg then
        BG.TCOPatchHopeEditBg(bt)
    end
end

-- 清理旧版遮罩层（Button 点击层 / 深色边框层）
function BG.TCOCleanupHopeOverlays(FB)
    if not FB or not BG.HopeFrame or not BG.HopeFrame[FB] or not HopeMaxn or not HopeMaxn[FB] then
        return
    end
    for n = 1, HopeMaxn[FB] do
        for b = 1, HopeMaxb[FB] do
            for i = 1, HopeMaxi do
                local bt = BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i]
                if bt then
                    if bt.tcoCellBtn then
                        bt.tcoCellBtn:Hide()
                        bt.tcoCellBtn:SetParent(nil)
                        bt.tcoCellBtn = nil
                    end
                    if bt.tcoHopeBorder then
                        bt.tcoHopeBorder:Hide()
                        bt.tcoHopeBorder:SetParent(nil)
                        bt.tcoHopeBorder = nil
                    end
                end
            end
        end
    end
end

BG.HopeJingzheng = {}

local function EnsureHopeUIStructures(FB)
    BG.HopeFrame = BG.HopeFrame or {}
    BG.HopeFrame[FB] = BG.HopeFrame[FB] or {}
    for n = 1, HopeMaxn[FB] do
        BG.HopeFrame[FB]["nandu" .. n] = BG.HopeFrame[FB]["nandu" .. n] or {}
        for b = 1, HopeMaxb[FB] do
            BG.HopeFrame[FB]["nandu" .. n]["boss" .. b] = BG.HopeFrame[FB]["nandu" .. n]["boss" .. b] or {}
        end
    end
    BG.HopeFrameDs = BG.HopeFrameDs or {}
    for t = 1, 3 do
        local key = FB .. t
        BG.HopeFrameDs[key] = BG.HopeFrameDs[key] or {}
        for n = 1, HopeMaxn[FB] do
            BG.HopeFrameDs[key]["nandu" .. n] = BG.HopeFrameDs[key]["nandu" .. n] or {}
            for b = 1, HopeMaxb[FB] do
                BG.HopeFrameDs[key]["nandu" .. n]["boss" .. b] =
                    BG.HopeFrameDs[key]["nandu" .. n]["boss" .. b] or {}
            end
        end
    end
end

-- 确保 SavedVariables 里 nandu/boss 层级存在（清空或导入前调用）
local function EnsureHopeSavedStructures(FB)
    if not FB or not HopeMaxn or not HopeMaxn[FB] or not HopeMaxb or not HopeMaxb[FB] then
        return nil
    end
    BiaoGe.Hope = BiaoGe.Hope or {}
    BiaoGe.Hope[RealmID] = BiaoGe.Hope[RealmID] or {}
    BiaoGe.Hope[RealmID][player] = BiaoGe.Hope[RealmID][player] or {}
    BiaoGe.Hope[RealmID][player][FB] = BiaoGe.Hope[RealmID][player][FB] or {}
    local root = BiaoGe.Hope[RealmID][player][FB]
    for n = 1, HopeMaxn[FB] do
        root["nandu" .. n] = root["nandu" .. n] or {}
        for b = 1, HopeMaxb[FB] do
            root["nandu" .. n]["boss" .. b] = root["nandu" .. n]["boss" .. b] or {}
        end
    end
    return root
end

BG.EnsureHopeSavedStructures = EnsureHopeSavedStructures

function BG.HopeUI(FB)
    local hopeFrame = BG["HopeFrame" .. FB]
    -- WoW 带点帧名 GetName() 只返回最后一段，不能用全名比较
    if not hopeFrame or not hopeFrame.isTCOHope then
        return false
    end
    if not HopeMaxn[FB] or not HopeMaxb[FB] or not HopeMaxi then
        return false
    end

    EnsureHopeUIStructures(FB)

    BG.TCOHopeToolbar = BG.TCOHopeToolbar or {}
    BG.TCOHopeToolbar[FB] = {}

    local preWidget
    local framedown
    local frameright
    local framedownH
    local red, greed, blue = 1, 1, 1
    local touming1, touming2 = 0.1, 0.1
    local btwidth = 105
    local titlewidth = 92
    local titlewidth2 = 16

    for n = 1, HopeMaxn[FB], 1 do
        ------------------标题------------------
        do
            local version = hopeFrame:CreateFontString()
            if n == 1 then
                version:SetPoint("TOPLEFT", hopeFrame, "TOPLEFT", 8, -36)
            elseif n == 2 then
                version:SetPoint("TOPRIGHT", framedownH, "TOPLEFT", -titlewidth2, -30)
            end
            version:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            version:SetTextColor(RGB(BG.y2))
            version:SetWidth(titlewidth)
            version:SetWordWrap(false)
            version:SetJustifyH("RIGHT")
            if BG.IsWLKFB(FB) then
                if n == 1 then
                    version:SetText(L["< |cffFFFFFF10人|r|cff00BFFF普通|r >"])
                elseif n == 2 then
                    version:SetText(L["< |cffFFFFFF25人|r|cff00BFFF普通|r >"])
                elseif n == 3 then
                    version:SetPoint("TOPLEFT", frameright, "TOPRIGHT", titlewidth2, 0)
                    version:SetText(L["< |cffFFFFFF10人|r|cffFF0000英雄|r >"])
                elseif n == 4 then
                    version:SetText(L["< |cffFFFFFF25人|r|cffFF0000英雄|r >"])
                    version:SetPoint("TOPRIGHT", framedownH, "TOPLEFT", -titlewidth2, -30)
                end
            elseif BG.IsRetail then
                if n == 1 then
                    version:SetText(L["< |cff00BFFF普通|r >"])
                elseif n == 2 then
                    version:SetText(L["< |cffFF0000英雄|r >"])
                elseif n == 3 then
                    version:SetPoint("TOPRIGHT", framedownH, "TOPLEFT", -titlewidth2, -30)
                    version:SetText(L["< |cffa335ee史诗|r >"])
                end
            else
                if n == 1 then
                    version:SetText(L["< |cff00BFFF普通|r >"])
                elseif n == 2 then
                    version:SetText(L["< |cffFF0000英雄|r >"])
                end
            end
            preWidget = version

            for i = 1, HopeMaxi, 1 do
                local version = hopeFrame:CreateFontString()
                if i == 1 then
                    version:SetPoint("TOPLEFT", preWidget, "TOPRIGHT", titlewidth2, 0)
                    framedown = version
                else
                    version:SetPoint("TOPLEFT", preWidget, "TOPRIGHT", titlewidth2 + 4, 0)
                    frameright = version
                end
                version:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                version:SetTextColor(RGB(BG.y2))
                version:SetText(L["心愿"] .. i)
                version:SetWidth(btwidth)
                version:SetWordWrap(false)
                version:SetJustifyH("LEFT")
                preWidget = version
            end
        end
        for b = 1, HopeMaxb[FB], 1 do
            for i = 1, HopeMaxi, 1 do
                ------------------装备------------------
                do
                    local editTpl = BG.editTemplate or "InputBoxTemplate"
                    local bt = CreateFrame("EditBox", nil, hopeFrame, editTpl)
                    bt:SetSize(btwidth, 20)
                    bt:SetFrameLevel(110)
                    StyleHopeEditBox(bt)
                    if i == 1 then
                        bt:SetPoint("TOPLEFT", framedown, "BOTTOMLEFT", 0, -1)
                    else
                        bt:SetPoint("TOPLEFT", framedown, "TOPLEFT", (btwidth + 22) * (i - 1), 0)
                    end
                    bt:SetAutoFocus(false)
                    bt:EnableMouse(true)
                    BG.SetEditStickyFocus(bt)
                    bt:Show()
                    bt.FB = FB
                    bt.bossnum = b
                    bt.hopenandu = n
                    bt.i = i
                    bt.icon = bt:CreateTexture(nil, 'ARTWORK')
                    bt.icon:SetPoint('LEFT', -22, 0)
                    bt.icon:SetSize(16, 16)
                    local hopeData = BiaoGe.Hope
                        and BiaoGe.Hope[RealmID]
                        and BiaoGe.Hope[RealmID][player]
                        and BiaoGe.Hope[RealmID][player][FB]
                        and BiaoGe.Hope[RealmID][player][FB]["nandu" .. n]
                        and BiaoGe.Hope[RealmID][player][FB]["nandu" .. n]["boss" .. b]
                    local savedText = hopeData and hopeData["zhuangbei" .. i]
                    if savedText then
                        if savedText ~= "" then
                            bt:SetText(savedText)
                            bt:SetCursorPosition(0)
                        else
                            hopeData["zhuangbei" .. i] = nil
                        end
                    end
                    BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i] = bt
                    preWidget = bt
                    if i == 1 then
                        framedown = bt
                        -- if n == 1 or n == 3 and b == HopeMaxb[FB] then
                        if b == HopeMaxb[FB] then
                            framedownH = bt
                        end
                    end
                    -- 创建已掉落文本
                    BG.LootedText(bt)

                    -- 内容改变时
                    bt:SetScript("OnTextChanged", function(self)
                        if self.tcoSuppressChange then return end
                        local itemText = self:GetText()
                        local itemID = select(1, GetItemInfoInstant(itemText))
                        if itemID then
                            local loadToken = (self.tcoLoadToken or 0) + 1
                            self.tcoLoadToken = loadToken
                            BG.OnItemLoad(itemText):ContinueOnItemLoad(function()
                                if self.tcoSuppressChange or self.tcoLoadToken ~= loadToken then
                                    return
                                end
                                if self:GetText() == "" or select(1, GetItemInfoInstant(self:GetText())) ~= itemID then
                                    return
                                end
                                local name, link, quality, level, _, _, _, _, _, Texture,
                                _, typeID, _, bindType = GetItemInfo(itemText)
                                BG.AddHText(FB, itemText, itemID, self)
                                self.icon:SetTexture(Texture)
                                BG.BindOnEquip(self, bindType)
                                BG.LevelText(self, level, typeID)
                                BG.IsHave(self)
                            end)
                        else
                            self.icon:SetTexture(nil)
                            BG.BindOnEquip(self)
                            BG.LevelText(self)
                            BG.IsHave(self)
                        end

                        if BG.UpdateFilter then
                            BG.UpdateFilter(self)
                        end
                        if BG.Update_IsLooted then
                            BG.Update_IsLooted(self)
                        end

                        BiaoGe.Hope[RealmID] = BiaoGe.Hope[RealmID] or {}
                        BiaoGe.Hope[RealmID][player] = BiaoGe.Hope[RealmID][player] or {}
                        BiaoGe.Hope[RealmID][player][FB] = BiaoGe.Hope[RealmID][player][FB] or {}
                        BiaoGe.Hope[RealmID][player][FB]["nandu" .. n] =
                            BiaoGe.Hope[RealmID][player][FB]["nandu" .. n] or {}
                        BiaoGe.Hope[RealmID][player][FB]["nandu" .. n]["boss" .. b] =
                            BiaoGe.Hope[RealmID][player][FB]["nandu" .. n]["boss" .. b] or {}
                        if itemText ~= "" then
                            BiaoGe.Hope[RealmID][player][FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i] = itemText
                        else
                            BiaoGe.Hope[RealmID][player][FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i] = nil
                        end
                    end)
                    -- 点击
                    bt:SetScript("OnMouseDown", function(self, button)
                        if button == "RightButton" and not IsAltKeyDown() then
                            self:SetEnabled(false)
                            self:SetText("")
                            if BG.lastfocus then
                                BG.lastfocus:ClearFocus()
                            end
                            return
                        end
                        if BG.IsSetBestPriceKeyDown(button == "RightButton") then
                            if self:GetText() ~= "" then
                                self:SetEnabled(false)
                                bt:ClearFocus()
                                if BG.lastfocus then
                                    BG.lastfocus:ClearFocus()
                                end
                                BG.SetBestPrice(self:GetText(), self)
                            end
                            return
                        end
                        if IsShiftKeyDown() then
                            if self:GetText() ~= "" then
                                self:SetEnabled(false)
                                bt:ClearFocus()
                                BG.InsertLink(self:GetText())
                            end
                            return
                        end
                        if IsAltKeyDown() then
                            if self:GetText() ~= "" then
                                self:SetEnabled(false)
                                bt:ClearFocus()
                                if BG.lastfocus then
                                    BG.lastfocus:ClearFocus()
                                end
                            end
                            return
                        end
                        if IsControlKeyDown() then
                            if self:GetText() ~= "" then
                                self:SetEnabled(false)
                                BG.GoToItemLib(self)
                            end
                            return
                        end
                        if button == "LeftButton" then
                            if not self:IsEnabled() then
                                self:SetEnabled(true)
                            end
                            self:SetFocus()
                            OpenHopeLootPicker(self)
                        end
                    end)
                    bt:SetScript("OnMouseUp", function(self, enter)
                        if self:IsEnabled() then
                            local infoType, itemID, itemLink = GetCursorInfo()
                            if infoType == "item" then
                                self:SetText(itemLink)
                                self:ClearFocus()
                                ClearCursor()
                                return
                            end
                        end
                        for n = 1, HopeMaxn[FB], 1 do
                            for b = 1, HopeMaxb[FB] do
                                for i = 1, HopeMaxi do
                                    if BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i] then
                                        BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i]:SetEnabled(true)
                                    end
                                end
                            end
                        end
                        if enter == "RightButton" then
                            self:SetEnabled(true)
                        end
                    end)
                    -- 鼠标悬停在装备时
                    bt:SetScript("OnEnter", function(self)
                        BG.HopeFrameDs[FB .. 1]["nandu" .. n]["boss" .. b]["ds" .. i]:Show()
                        if not tonumber(self:GetText()) then
                            local link = bt:GetText()
                            local itemID = select(1, GetItemInfoInstant(link))
                            if itemID then
                                local point
                                if BG.ButtonIsInRight(self) then
                                    GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0)
                                    point = 'LEFT'
                                else
                                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                                    point = 'RIGHT'
                                end
                                GameTooltip:ClearLines()
                                GameTooltip:SetHyperlink(BG.SetSpecIDToLink(link))
                                BG.SetZUGSetTooltip(itemID, point)
                                -- BG.SetHistoryMoney(itemID)

                                BG.DressUpLastButton = self
                                if IsControlKeyDown() and not IsShiftKeyDown() then
                                    SetCursor("Interface/Cursor/Inspect")
                                    BG.DressUp()
                                end
                                BG.canShowTrunToItemLibCursor = true
                            end
                        end
                    end)
                    bt:SetScript("OnLeave", function(self)
                        BG.HopeFrameDs[FB .. 1]["nandu" .. n]["boss" .. b]["ds" .. i]:Hide()
                        GameTooltip:Hide()
                        BG.HideHistoryMoney()
                        SetCursor(nil)
                        BG.canShowTrunToItemLibCursor = nil
                        if BG.DressUpFrame then
                            BG.DressUpFrame:Hide()
                        end
                        BG.DressUpLastButton = nil
                    end)
                    -- 获得光标时
                    bt:SetScript("OnEditFocusGained", function(self)
                        BG.FrameHide(1, { keepZhuangbeiList = true })
                        self:HighlightText()
                        BG.lastfocuszhuangbei = self
                        BG.lastfocus = self

                        local infoType, itemID, itemLink = GetCursorInfo()
                        if infoType ~= "item" then
                            OpenHopeLootPicker(self)
                        end

                        if BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i + 1] then
                            BG.lastfocuszhuangbei2 = BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i + 1]
                        else
                            BG.lastfocuszhuangbei2 = nil
                        end
                        BG.HopeFrameDs[FB .. 2]["nandu" .. n]["boss" .. b]["ds" .. i]:Show()
                    end)
                    -- 失去光标时
                    bt:SetScript("OnEditFocusLost", function(self)
                        self:ClearHighlightText()
                        BG.HopeFrameDs[FB .. 2]["nandu" .. n]["boss" .. b]["ds" .. i]:Hide()
                    end)
                    -- 按TAB跳转右边
                    bt:SetScript("OnTabPressed", function(self)
                        if BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i + 1] then
                            BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i + 1]:SetFocus()
                        elseif BG.HopeFrame[FB]["nandu" .. n]["boss" .. b + 1]["zhuangbei" .. 1] then
                            BG.HopeFrame[FB]["nandu" .. n]["boss" .. b + 1]["zhuangbei" .. 1]:SetFocus()
                        elseif n ~= HopeMaxn[FB] then
                            local nn
                            if n == 3 then
                                nn = 2
                            elseif n == 2 then
                                nn = 4
                            elseif n == 1 then
                                if HopeMaxn[FB] > 2 then
                                    nn = 3
                                else
                                    nn = 2
                                end
                            end
                            BG.HopeFrame[FB]["nandu" .. nn]["boss" .. 1]["zhuangbei" .. 1]:SetFocus()
                        end
                    end)
                    -- 按ENTER
                    bt:SetScript("OnEnterPressed", function(self)
                        self:ClearFocus()
                        if BG.FrameZhuangbeiList then
                            BG.FrameZhuangbeiList:Hide()
                        end
                    end)
                    -- 按箭头跳转
                    bt:SetScript("OnKeyDown", function(self, enter)
                        if not IsModifierKeyDown() then
                            if enter == "UP" then -- 上↑
                                if BG.HopeFrame[FB]["nandu" .. n]["boss" .. b - 1] and
                                    BG.HopeFrame[FB]["nandu" .. n]["boss" .. b - 1]["zhuangbei" .. i] then
                                    BG.HopeFrame[FB]["nandu" .. n]["boss" .. b - 1]["zhuangbei" .. i]:SetFocus()
                                else
                                    local nn
                                    if n == 4 then
                                        nn = 2
                                    elseif n == 3 then
                                        nn = 1
                                    elseif n == 2 then
                                        if HopeMaxn[FB] > 2 then
                                            nn = 4
                                        else
                                            nn = 2
                                        end
                                    elseif n == 1 then
                                        if HopeMaxn[FB] > 2 then
                                            nn = 3
                                        else
                                            nn = 1
                                        end
                                    end
                                    BG.HopeFrame[FB]["nandu" .. nn]["boss" .. HopeMaxb[FB]]["zhuangbei" .. i]:SetFocus()
                                end
                            elseif enter == "DOWN" then -- 下↓
                                if BG.HopeFrame[FB]["nandu" .. n]["boss" .. b + 1] and
                                    BG.HopeFrame[FB]["nandu" .. n]["boss" .. b + 1]["zhuangbei" .. i] then
                                    BG.HopeFrame[FB]["nandu" .. n]["boss" .. b + 1]["zhuangbei" .. i]:SetFocus()
                                else
                                    local nn
                                    if n == 4 then
                                        nn = 2
                                    elseif n == 3 then
                                        nn = 1
                                    elseif n == 2 then
                                        if HopeMaxn[FB] > 2 then
                                            nn = 4
                                        else
                                            nn = 1
                                        end
                                    elseif n == 1 then
                                        if HopeMaxn[FB] > 2 then
                                            nn = 3
                                        else
                                            nn = 1
                                        end
                                    end
                                    BG.HopeFrame[FB]["nandu" .. nn]["boss" .. 1]["zhuangbei" .. i]:SetFocus()
                                end
                            elseif enter == "LEFT" then -- 左←
                                if BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i - 1] then
                                    BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i - 1]:SetFocus()
                                else
                                    local nn
                                    if HopeMaxn[FB] == 1 then
                                        nn = 1
                                    else
                                        if n == 4 then
                                            nn = 3
                                        elseif n == 3 then
                                            nn = 4
                                        elseif n == 2 then
                                            nn = 1
                                        elseif n == 1 then
                                            nn = 2
                                        end
                                    end
                                    BG.HopeFrame[FB]["nandu" .. nn]["boss" .. b]["zhuangbei" .. HopeMaxi]:SetFocus()
                                end
                            elseif enter == "RIGHT" then -- 右→
                                if BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i + 1] then
                                    BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i + 1]:SetFocus()
                                else
                                    local nn
                                    if HopeMaxn[FB] == 1 then
                                        nn = 1
                                    else
                                        if n == 4 then
                                            nn = 3
                                        elseif n == 3 then
                                            nn = 4
                                        elseif n == 2 then
                                            nn = 1
                                        elseif n == 1 then
                                            nn = 2
                                        end
                                    end
                                    BG.HopeFrame[FB]["nandu" .. nn]["boss" .. b]["zhuangbei" .. 1]:SetFocus()
                                end
                            end
                        else
                            if enter == "UP" or enter == "DOWN" then -- 上↑下↓
                                if HopeMaxn[FB] > 2 then
                                    local nn
                                    if n == 1 or n == 2 then
                                        nn = n + 2
                                    else
                                        nn = n - 2
                                    end
                                    if BG.HopeFrame[FB]["nandu" .. nn] then
                                        BG.HopeFrame[FB]["nandu" .. nn]["boss" .. b]["zhuangbei" .. i]:SetFocus()
                                    end
                                end
                            elseif enter == "LEFT" or enter == "RIGHT" then -- 左←右→
                                local nn
                                if n == 1 or n == 3 then
                                    nn = n + 1
                                else
                                    nn = n - 1
                                end
                                if BG.HopeFrame[FB]["nandu" .. nn] then
                                    BG.HopeFrame[FB]["nandu" .. nn]["boss" .. b]["zhuangbei" .. i]:SetFocus()
                                end
                            end
                        end
                    end)
                    -- 按ESC退出
                    bt:SetScript("OnEscapePressed", function(self)
                        self:ClearFocus()
                        if BG.FrameZhuangbeiList then
                            BG.FrameZhuangbeiList:Hide()
                        end
                    end)
                    -- 复原按钮为可点击
                    bt:SetScript("OnShow", function(self)
                        self:SetEnabled(true)
                        self:EnableMouse(true)
                    end)
                end

                ------------------底色材质------------------
                do
                    local cell = BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i]
                    -- 先做底色材质1（鼠标悬停的）
                    local textrue = cell:CreateTexture(nil, "BACKGROUND", nil, 2)
                    textrue:SetPoint("TOPLEFT", cell, "TOPLEFT", -4, -2)
                    textrue:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -1, 0)
                    textrue:SetColorTexture(red, greed, blue, touming1)
                    textrue:Hide()
                    BG.HopeFrameDs[FB .. 1]["nandu" .. n]["boss" .. b]["ds" .. i] = textrue

                    -- 底色材质2（点击框体后）
                    local textrue = cell:CreateTexture(nil, "BACKGROUND", nil, 2)
                    textrue:SetPoint("TOPLEFT", cell, "TOPLEFT", -4, -2)
                    textrue:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -1, 0)
                    textrue:SetColorTexture(red, greed, blue, touming2)
                    textrue:Hide()
                    BG.HopeFrameDs[FB .. 2]["nandu" .. n]["boss" .. b]["ds" .. i] = textrue

                    -- 底色材质3（团长发的装备高亮）
                    local textrue = cell:CreateTexture(nil, "BACKGROUND", nil, 2)
                    textrue:SetPoint("TOPLEFT", cell, "TOPLEFT", -4, -2)
                    textrue:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", -1, 0)
                    textrue:SetColorTexture(1, 1, 0, BG.highLightAlpha)
                    textrue:Hide()
                    BG.HopeFrameDs[FB .. 3]["nandu" .. n]["boss" .. b]["ds" .. i] = textrue
                end
            end
            ------------------BOSS名字------------------
            do
                local version = hopeFrame:CreateFontString()
                version:SetPoint("TOPRIGHT", BG.HopeFrame[FB]["nandu" .. n]["boss" .. b].zhuangbei1, "TOPLEFT", -titlewidth2 - 4, -3)
                version:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                local bossInfo = BG.Boss[FB] and BG.Boss[FB]["boss" .. b]
                if bossInfo then
                    version:SetTextColor(RGB(bossInfo.color))
                    version:SetText(bossInfo.name2 or "")
                else
                    version:SetTextColor(RGB(BG.dis))
                    version:SetText("")
                end
                version:SetWidth(titlewidth)
                version:SetWordWrap(false)
                version:SetJustifyH("RIGHT")

                BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["name"] = version
            end
        end
    end

    if not BG.IsRetail then
        ------------------通报心愿------------------
        do
            local xinyuan
            if BG.onlyOneHard then
                xinyuan = {
                    { name1 = L["通报心愿"], name2 = "" },
                }
                -- elseif BG.IsRetail then
                --     xinyuan = {
                --         { name1 = L["|cffFFFFFF10人|r|cff00BFFF普通|r"], name2 = "10PT" },
                --         { name1 = L["|cffFFFFFF25人|r|cff00BFFF普通|r"], name2 = "25PT" },
                --         { name1 = L["|cffFFFFFF10人|r|cffFF0000英雄|r"], name2 = "10H" },
                --         { name1 = L["|cffFFFFFF25人|r|cffFF0000英雄|r"], name2 = "25H" },
                --     }
            else
                xinyuan = {
                    { name1 = L["|cffFFFFFF10人|r|cff00BFFF普通|r"], name2 = "10PT" },
                    { name1 = L["|cffFFFFFF25人|r|cff00BFFF普通|r"], name2 = "25PT" },
                    { name1 = L["|cffFFFFFF10人|r|cffFF0000英雄|r"], name2 = "10H" },
                    { name1 = L["|cffFFFFFF25人|r|cffFF0000英雄|r"], name2 = "25H" },
                }
            end

            local function CreateList(n, onClick)
                local tbl = {}
                local tbl_onClick = {}
                for b = 1, HopeMaxb[FB] do
                    local text = ""
                    for i = 1, HopeMaxi do
                        local zb = BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i]
                        if zb then
                            local _, link = GetItemInfo(zb:GetText())
                            if link then
                                text = text .. link
                            end
                        end
                    end

                    if text ~= "" then
                        local bosscolorname
                        if onClick then
                            bosscolorname = BG.Boss[FB]["boss" .. b]["name2"] .. ": "
                        else
                            bosscolorname = "|cff" .. BG.Boss[FB]["boss" .. b]["color"] .. BG.Boss[FB]["boss" .. b]["name2"] .. ": |r"
                        end
                        text = bosscolorname .. text
                        tinsert(tbl, text)
                    end
                end
                return tbl
            end

            local reportBtn
            for n = 1, HopeMaxn[FB] do
                local bt = BG.CreateButton(hopeFrame)
                bt:SetSize(120, 25)
                if n == 1 then
                    bt:SetPoint("TOPRIGHT", hopeFrame, "TOPRIGHT", -8, -8)
                else
                    bt:SetPoint("TOPLEFT", reportBtn, "BOTTOMLEFT", 0, -2)
                end
                bt:SetText(xinyuan[n].name1)
                bt:SetFrameLevel(105)
                reportBtn = bt
                tinsert(BG.TCOHopeToolbar[FB], bt)

                -- 鼠标悬停提示
                bt:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0)
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(L["———我的心愿———"])
                    local tbl = CreateList(n)
                    if #tbl == 0 then
                        GameTooltip:AddLine(L["没有心愿"])
                    else
                        for i, text in ipairs(tbl) do
                            GameTooltip:AddLine(text)
                        end
                    end
                    GameTooltip:Show()
                end)
                bt:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)

                -- 单击触发
                bt:SetScript("OnClick", function(self)
                    if BG.InBoss() then return end
                    BG.FrameHide(0)
                    if not BiaoGe.HopeSendChannel then return end
                    local targetName = BG.GN("t")
                    if BiaoGe.HopeSendChannel == "RAID" then
                        if not IsInRaid(1) then
                            SendSystemMessage(L["不在团队，无法通报"])
                            BG.PlaySound(1)
                            return
                        end
                    end
                    if BiaoGe.HopeSendChannel == "PARTY" then
                        if not IsInGroup() then
                            SendSystemMessage(L["不在队伍，无法通报"])
                            BG.PlaySound(1)
                            return
                        end
                    end
                    if BiaoGe.HopeSendChannel == "GUILD" then
                        if not IsInGuild() then
                            SendSystemMessage(L["没有公会，无法通报"])
                            BG.PlaySound(1)
                            return
                        end
                    end
                    if BiaoGe.HopeSendChannel == "WHISPER" then
                        if not targetName then
                            SendSystemMessage(L["没有目标，无法通报"])
                            BG.PlaySound(1)
                            return
                        end
                    end

                    self:SetEnabled(false)
                    C_Timer.After(2, function()
                        bt:SetEnabled(true)
                    end)
                    local channel = BiaoGe.HopeSendChannel

                    local text = L["———我的心愿———"]
                    SendChatMessage(text, channel, nil, targetName)

                    local tbl = CreateList(n, true)
                    if #tbl == 0 then
                        BG.After(BG.tongBaoSendCD, function()
                            text = L["没有心愿"]
                            SendChatMessage(text, channel, nil, targetName)
                        end)
                    else
                        local t = BG.tongBaoSendCD
                        for _, text in ipairs(tbl) do
                            BG.After(t, function()
                                SendChatMessage(text, channel, nil, targetName)
                            end)
                            t = t + BG.tongBaoSendCD
                        end
                    end
                    BG.PlaySound(2)
                end)
            end

            -- 频道
            BG.HopeSendTable = {
                RAID = L["频道：团队"],
                PARTY = L["频道：队伍"],
                GUILD = L["频道：公会"],
                WHISPER = L["频道：密语"],
            }
            if not BG.HopeSenddropDown then
                BG.HopeSenddropDown = {}
            end
            if not BiaoGe.HopeSendChannel then
                BiaoGe.HopeSendChannel = "RAID"
            end

            local function AddButton(dropDown, text, channel)
                local info = LibBG:UIDropDownMenu_CreateInfo()
                info.text = text
                info.func = function()
                    BiaoGe.HopeSendChannel = channel
                    LibBG:UIDropDownMenu_SetText(dropDown, BG.HopeSendTable[BiaoGe.HopeSendChannel])
                    BG.FrameHide(0)
                end
                if BiaoGe.HopeSendChannel == channel then
                    info.checked = true
                end
                LibBG:UIDropDownMenu_AddButton(info)
            end

            local dropDown = LibBG:Create_UIDropDownMenu(nil, hopeFrame)
            BG.HopeSenddropDown[FB] = dropDown
            BG.dropDownToggle(dropDown)
            if reportBtn then
                dropDown:SetPoint("TOP", reportBtn, "BOTTOM", 0, -5)
            else
                dropDown:SetPoint("TOPRIGHT", hopeFrame, "TOPRIGHT", -8, -40)
            end
            LibBG:UIDropDownMenu_SetWidth(dropDown, 100)
            LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOP", dropDown, "BOTTOM")
            LibBG:UIDropDownMenu_SetText(dropDown, BG.HopeSendTable[BiaoGe.HopeSendChannel])
            tinsert(BG.TCOHopeToolbar[FB], dropDown)
            LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level, menuList)
                BG.FrameHide(0)
                AddButton(dropDown, L["团队"], "RAID")
                AddButton(dropDown, L["队伍"], "PARTY")
                AddButton(dropDown, L["公会"], "GUILD")
                AddButton(dropDown, L["密语目标"], "WHISPER")
            end)
        end
    end

    -- 更新心愿
    BG["HopeFrame" .. FB]:HookScript("OnShow", function(self)
        for n = 1, HopeMaxn[FB] do
            for b = 1, HopeMaxb[FB] do
                for i = 1, HopeMaxi do
                    local bt = BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i]
                    if bt and bt:GetText() == "" then
                        for ii = i, HopeMaxi do
                            local _bt = BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. ii]
                            if _bt:GetText() ~= "" then
                                bt:SetText(_bt:GetText())
                                _bt:SetText("")
                                break
                            end
                        end
                    end
                end
            end
        end
        BG.UpdateHopeFrame_IsLooted_All()
    end)
    return true
end

----------导出导入心愿心愿----------
function BG.HopeDaoChuUI()
    if BG.ButtonImportHope then return end

    local width_jiange = -7
    local hideFrameTbl = {}
    local parent = (BG.WishlistWindow and BG.WishlistWindow.content) or BG.WishlistWindow or BG.HopeMainFrame
    local function HideOtherFrame(myframe)
        for _, frame in ipairs(hideFrameTbl) do
            if not myframe or frame.frameName ~= myframe.frameName then
                frame:Hide()
            end
        end
    end
    local function ExportHope()
        local FB = BG.FB1
        local tbl = {}
        for n = 1, HopeMaxn[FB] do
            for b = 1, HopeMaxb[FB] do
                local oneboss = {}
                for i = 1, HopeMaxi do
                    local bt = BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i]
                    if bt then
                        local itemID = GetItemID(bt:GetText())
                        if itemID then
                            tinsert(oneboss, itemID)
                        end
                    end
                end
                if #oneboss ~= 0 then
                    local t = "n" .. n .. "b" .. b
                    for i, itemID in ipairs(oneboss) do
                        t = t .. "-" .. itemID
                    end
                    tinsert(tbl, t)
                end
            end
        end
        local t = table.concat(tbl, ",")
        if t == "" then
            return L["心愿清单是空的"]
        else
            return FB .. ":" .. t
        end
    end
    local function ImportHope(text)
        -- 划分副本
        for _, fb in ipairs({ strsplit(".", text) }) do
            local FB, allboss = strsplit(":", fb)
            for _, _FB in ipairs(BG.FBtable) do
                if FB == _FB then
                    local qingkong
                    local count = 0
                    EnsureHopeUIStructures(FB)
                    EnsureHopeSavedStructures(FB)
                    -- 划分boss
                    for _, v in ipairs({ strsplit(",", allboss) }) do
                        local text = { strsplit("-", v) }
                        local n, b = strmatch(text[1], "n(%d+)b(%d+)")
                        n, b = tonumber(n), tonumber(b)
                        if n and b and n <= HopeMaxn[FB] and b <= HopeMaxb[FB] then
                            local i = 1
                            for ii = 2, #text do
                                local itemID = tonumber(text[ii])
                                if itemID then
                                    if not qingkong then
                                        BG.ClearBiaoGe("hope", FB)
                                        EnsureHopeSavedStructures(FB)
                                        qingkong = true
                                    end
                                    if BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i] then
                                        local _i = i
                                        count = count + 1
                                        local item = Item:CreateFromItemID(itemID)
                                        item:ContinueOnItemLoad(function()
                                            local _, link = GetItemInfo(itemID)
                                            if not link then return end
                                            EnsureHopeSavedStructures(FB)
                                            local edit = BG.HopeFrame[FB]
                                                and BG.HopeFrame[FB]["nandu" .. n]
                                                and BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]
                                                and BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. _i]
                                            if edit then
                                                edit:SetText(link)
                                            end
                                            BiaoGe.Hope[RealmID][player][FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. _i] = link
                                        end)
                                        i = i + 1
                                    end
                                end
                            end
                        end
                    end
                    if qingkong then
                        BG.UpdateItemLib_LeftHope_All()
                        BG.UpdateItemLib_RightHope_All()

                        BG.After(0.2, function()
                            SendSystemMessage(BG.BG .. BG.STC_g1(format(
                                L["心愿清单导入成功：%s，一共导入%s件装备。"], BG.GetFBinfo(FB, "shortName"), count)))
                        end)
                    end
                    break
                end
            end
        end
    end

    -- 导入心愿
    do
        local bt = CreateFrame("Button", nil, parent)
        bt:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -80, -8)
        bt:SetNormalFontObject(BG.FontGreen15)
        bt:SetDisabledFontObject(BG.FontDis15)
        bt:SetHighlightFontObject(BG.FontWhite15)
        bt:SetText(L["导入心愿"])
        bt:SetSize(bt:GetFontString():GetWidth(), 30)
        BG.SetTextHighlightTexture(bt)
        BG.ButtonImportHope = bt

        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            HideOtherFrame(bt.bg)

            if not self.bg then
                local sbg, scroll, child
                local bg = CreateFrame("Frame", nil, bt, "BackdropTemplate")
                do
                    bg:SetBackdrop({
                        bgFile = "Interface/ChatFrame/ChatFrameBackground",
                        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                        edgeSize = 10,
                        insets = { left = 3, right = 3, top = 3, bottom = 3 }
                    })
                    bg:SetBackdropColor(0, 0, 0, 0.8)
                    bg:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, -40)
                    bg:SetSize(250, 250)
                    bg:SetFrameLevel(130)
                    bg:EnableMouse(true)
                    bg.frameName = self:GetText()
                    self.bg = bg
                    BG.frameImportHope = bg
                    tinsert(hideFrameTbl, bg)

                    local t = bg:CreateFontString()
                    t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                    t:SetPoint("TOP", 0, -8)
                    t:SetTextColor(1, 1, 1)
                    t:SetText(bt:GetText())
                    t:SetWordWrap(false)
                end

                sbg = CreateFrame("Frame", nil, bg, "BackdropTemplate")
                do
                    sbg:SetBackdrop({
                        bgFile = "Interface/ChatFrame/ChatFrameBackground",
                        edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                        edgeSize = 1,
                    })
                    sbg:SetBackdropColor(0, 0, 0, 0.8)
                    sbg:SetBackdropBorderColor(1, 1, 1, 0.5)
                    sbg:SetPoint("TOPLEFT", 8, -28)
                    sbg:SetSize(bg:GetWidth() - 16, bg:GetHeight() - 70)
                    sbg:SetFrameLevel(130)
                    self.sbg = sbg
                    scroll = CreateFrame("ScrollFrame", nil, sbg, BG.scrollTemplate)
                    scroll:SetPoint("TOPLEFT", 5, -4)
                    scroll:SetPoint("BOTTOMRIGHT", -27, 4)
                    scroll.ScrollBar.scrollStep = BG.scrollStep
                    BG.CreateSrollBarBackdrop(scroll.ScrollBar)
                    BG.HookScrollBarShowOrHide(scroll)

                    self.s = scroll

                    child = CreateFrame("EditBox", nil, scroll)
                    child:SetWidth(sbg:GetWidth())
                    child:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
                    child:SetMultiLine(true)
                    child:SetAutoFocus(false)
                    child:EnableMouse(true)
                    child:SetTextInsets(5, 28, 5, 10)
                    self.child = child
                    scroll:SetScrollChild(child)
                    child:SetScript("OnEscapePressed", function(self)
                        bg:Hide()
                    end)
                    child:SetScript("OnEnterPressed", function(self)
                        BG.PlaySound(1)
                        ImportHope(child:GetText())
                        bg:Hide()
                    end)
                end

                local bt = BG.CreateButton(bg)
                do
                    bt:SetSize(110, 25)
                    bt:SetPoint("BOTTOMLEFT", 8, 10)
                    bt:SetText(OKAY)
                    bt:SetScript("OnClick", function(self)
                        BG.PlaySound(1)
                        ImportHope(child:GetText())
                        bg:Hide()
                    end)
                    local bt = BG.CreateButton(bg)
                    bt:SetSize(110, 25)
                    bt:SetPoint("BOTTOMRIGHT", -8, 10)
                    bt:SetText(CANCEL)
                    bt:SetScript("OnClick", function(self)
                        bg:Hide()
                    end)
                end
            else
                if self.bg:IsVisible() then
                    self.bg:Hide()
                else
                    self.bg:Show()
                end
            end
            self.child:SetText("")
            self.child:SetFocus()
        end)
    end
    -- 导出心愿
    do
        local bt = CreateFrame("Button", nil, BG.ButtonImportHope)
        bt:SetPoint("RIGHT", BG.ButtonImportHope, "LEFT", width_jiange, 0)
        bt:SetNormalFontObject(BG.FontGreen15)
        bt:SetDisabledFontObject(BG.FontDis15)
        bt:SetHighlightFontObject(BG.FontWhite15)
        bt:SetText(L["导出心愿"])
        bt:SetSize(bt:GetFontString():GetWidth(), 30)
        BG.SetTextHighlightTexture(bt)
        BG.ButtonExportHope = bt

        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            HideOtherFrame(bt.bg)

            if not self.bg then
                local sbg, scroll, child
                local bg = CreateFrame("Frame", nil, bt, "BackdropTemplate")
                do
                    bg:SetBackdrop({
                        bgFile = "Interface/ChatFrame/ChatFrameBackground",
                        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                        edgeSize = 10,
                        insets = { left = 3, right = 3, top = 3, bottom = 3 }
                    })
                    bg:SetBackdropColor(0, 0, 0, 0.8)
                    bg:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, -40)
                    bg:SetSize(250, 250)
                    bg:SetFrameLevel(130)
                    bg:EnableMouse(true)
                    bg.frameName = self:GetText()
                    self.bg = bg
                    BG.frameExportHope = bg
                    tinsert(hideFrameTbl, bg)

                    local t = bg:CreateFontString()
                    t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                    t:SetPoint("TOP", 0, -8)
                    t:SetTextColor(1, 1, 1)
                    t:SetText(bt:GetText())
                    t:SetWordWrap(false)
                end

                sbg = CreateFrame("Frame", nil, bg, "BackdropTemplate")
                do
                    sbg:SetBackdrop({
                        bgFile = "Interface/ChatFrame/ChatFrameBackground",
                        edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                        edgeSize = 1,
                    })
                    sbg:SetBackdropColor(0, 0, 0, 0.8)
                    sbg:SetBackdropBorderColor(1, 1, 1, 0.5)
                    sbg:SetPoint("TOPLEFT", 8, -28)
                    sbg:SetSize(bg:GetWidth() - 16, bg:GetHeight() - 70)
                    sbg:SetFrameLevel(130)
                    self.sbg = sbg
                    scroll = CreateFrame("ScrollFrame", nil, sbg, BG.scrollTemplate)
                    scroll:SetPoint("TOPLEFT", 5, -4)
                    scroll:SetPoint("BOTTOMRIGHT", -27, 4)
                    scroll.ScrollBar.scrollStep = BG.scrollStep
                    BG.CreateSrollBarBackdrop(scroll.ScrollBar)
                    BG.HookScrollBarShowOrHide(scroll)

                    self.s = scroll

                    child = CreateFrame("EditBox", nil, scroll)
                    child:SetWidth(scroll:GetWidth())
                    child:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
                    child:SetMultiLine(true)
                    child:SetAutoFocus(false)
                    child:EnableMouse(true)
                    self.child = child
                    scroll:SetScrollChild(child)
                    child:SetScript("OnEscapePressed", function(self)
                        bg:Hide()
                    end)
                end

                local bt = BG.CreateButton(bg)
                do
                    bt:SetSize(110, 25)
                    bt:SetPoint("BOTTOMRIGHT", -8, 10)
                    bt:SetText(CANCEL)
                    bt:SetScript("OnClick", function(self)
                        bg:Hide()
                    end)
                end
            else
                if self.bg:IsVisible() then
                    self.bg:Hide()
                else
                    self.bg:Show()
                end
            end
            self.child:SetText(ExportHope())
            self.child:HighlightText()
            self.child:SetFocus()
            BG.SetScrollBottom(self.s, self.child)
        end)
    end
end

local function GetBossNum(itemID, FB)
    FB = FB or BG.FB1
    local diffs = BG.difficultyTable[FB]
    if not diffs then error(L["表格ID错误"]) end
    for hardIndex, hard in ipairs(diffs) do
        if BG.Loot[FB][hard] then
            local b = 1
            while BG.Loot[FB][hard]["boss" .. b] do
                for _, _itemID in ipairs(BG.Loot[FB][hard]["boss" .. b]) do
                    if BG.IsSame(itemID, _itemID) then
                        return hardIndex, b
                    end
                end
                b = b + 1
            end
        end
    end
end

-- 参数1（必选）：link。类型：string
-- 参数2（可选）：表格ID。不传参数则对当前表格添加心愿。类型：string
-- 返回：true或false，true代表心愿设置成功了。类型：boolean
function BG.SetHope(link, FB, isBiaoGe)
    if type(link) ~= "string" then error(L["物品链接类型错误，需要string类型。"]) end
    local itemID = GetItemID(link)
    if not itemID then error(L["物品链接错误，没有读取到物品ID。"]) end

    FB = FB or BG.FB1
    local n, b = GetBossNum(itemID, FB)
    if not n then
        if isBiaoGe then
            UIErrorsFrame:AddMessage(L["不能设置为心愿，因为该装备未知由哪个物品兑换"], 1, 0, 0)
            return false
        else
            error(L["该物品链接没有匹配到正确的BOSS序号。"])
        end
    end

    for i = 1, HopeMaxi do
        local hope = BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i]
        if hope and hope:GetText() == "" then
            hope:SetText(link)
            hope:SetCursorPosition(0)
            BiaoGe.Hope[RealmID][player][FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i] = link
            if BG.ItemLibMainFrame and BG.ItemLibMainFrame:IsVisible() then
                BG.UpdateItemLib_LeftHope_All()
                BG.UpdateItemLib_RightHope_All()
            end
            BG.SetBiaoGeGuanZhu(itemID)
            return true
        end
    end
    if isBiaoGe then
        UIErrorsFrame:AddMessage(L["不能设置为心愿，因为该BOSS的心愿格子已满"], 1, 0, 0)
    end
    return false
end

-- 参数1（必选）：link或itemID。类型：string或number
-- 参数2（可选）：表格ID。不传参数则历遍全部表格的心愿进行匹配删除。类型：string
-- 返回：没有返回值
function BG.DeleteHope(LINKorID, FB)
    local itemID
    if type(LINKorID) == "number" then
        itemID = LINKorID
    elseif type(LINKorID) == "string" then
        itemID = GetItemID(LINKorID)
    end
    if not itemID then error(L["物品链接错误，没有读取到物品ID。"]) end
    local FBs = FB and BG.phaseFBtable[FB] or BG.FBtable
    if not FBs then error(L["表格ID错误"]) end

    for _, FB in pairs(FBs) do
        for n = 1, HopeMaxn[FB] do
            for b = 1, HopeMaxb[FB] do
                for i = 1, HopeMaxi do
                    local hope = BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i]
                    if hope then
                        if itemID == GetItemID(hope:GetText()) then
                            hope:SetText("")
                            BiaoGe.Hope[RealmID][player][FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i] = nil
                        end
                    end
                end
            end
        end
    end
end

-- 参数1（必选）：link或itemID。类型：string或number
-- 参数2（可选）：表格ID。不传参数则历遍全部表格的心愿进行匹配删除。类型：string
-- 返回：true或false，true代表是心愿。类型：boolean
function BG.IsHope(LINKorID, FB)
    local itemID
    if type(LINKorID) == "number" then
        itemID = LINKorID
    elseif type(LINKorID) == "string" then
        itemID = GetItemID(LINKorID)
    end
    if not itemID then error(L["物品链接错误，没有读取到物品ID。"]) end
    local FBs = FB and BG.phaseFBtable[FB] or BG.FBtable
    if not FBs then error(L["表格ID错误"]) end

    for _, FB in pairs(FBs) do
        for n = 1, HopeMaxn[FB] do
            for b = 1, HopeMaxb[FB] do
                for i = 1, HopeMaxi do
                    local hope = BG.HopeFrame[FB]
                        and BG.HopeFrame[FB]["nandu" .. n]
                        and BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]
                        and BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i]
                    if hope then
                        if BG.IsSame(itemID, hope) then
                            return true
                        end
                    end
                    local saved = BiaoGe.Hope
                        and BiaoGe.Hope[RealmID]
                        and BiaoGe.Hope[RealmID][player]
                        and BiaoGe.Hope[RealmID][player][FB]
                        and BiaoGe.Hope[RealmID][player][FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i]
                    if saved and saved ~= "" and BG.IsSame(itemID, saved) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- 兜底：居中弹窗（调试/SetListzhuangbei 不可用时）
function BG.TCOShowHopeLootList(owner)
    if not owner or not owner.FB or not owner.bossnum then
        print("|cff00BFFF<TCO>|r 无效的心愿格子")
        return false
    end

    if BG.FrameZhuangbeiList then
        BG.FrameZhuangbeiList:Hide()
        BG.FrameZhuangbeiList = nil
    end

    local FB = owner.FB
    local bossnum = owner.bossnum
    local diffName = "N"
    if owner.hopenandu and BG.difficultyTable and BG.difficultyTable[FB] then
        diffName = BG.difficultyTable[FB][owner.hopenandu] or "N"
    end

    local loots = BG.Loot and BG.Loot[FB] and BG.Loot[FB][diffName]
        and BG.Loot[FB][diffName]["boss" .. bossnum]
    local font = BIAOGE_TEXT_FONT or "Fonts\\FRIZQT__.TTF"

    local f = CreateFrame("Frame", "TCO_HopeLootPicker", UIParent, "BackdropTemplate")
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(500)
    f:SetBackdrop({
        bgFile = "Interface/ChatFrame/ChatFrameBackground",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0, 0, 0, 0.9)
    f:SetSize(460, 360)
    f:SetPoint("CENTER")
    f:EnableMouse(true)
    f:Show()
    BG.FrameZhuangbeiList = f

    local title = f:CreateFontString(nil, "ARTWORK")
    title:SetPoint("TOP", 0, -10)
    title:SetFont(font, 15, "OUTLINE")
    title:SetTextColor(0, 0.75, 1)
    local bossInfo = BG.Boss and BG.Boss[FB] and BG.Boss[FB]["boss" .. bossnum]
    title:SetText("选择装备" .. (bossInfo and bossInfo.name2 and (" - " .. bossInfo.name2) or ""))

    if BG.CreateCloseButton then
        BG.CreateCloseButton(f)
        f.CloseButton:SetFrameLevel(f:GetFrameLevel() + 20)
        f.CloseButton:SetScript("OnClick", function()
            f:Hide()
            BG.PlaySound(1)
        end)
    end

    if not loots or #loots == 0 then
        local tip = f:CreateFontString(nil, "ARTWORK")
        tip:SetPoint("TOP", 0, -44)
        tip:SetWidth(420)
        tip:SetFont(font, 13, "OUTLINE")
        tip:SetText("|cff00BFFF该 Boss 无内置掉落列表。|r\n\n可从背包拖入格子，或先点格子再 SHIFT+点击装备链接。")
        return true
    end

    local scroll = CreateFrame("ScrollFrame", nil, f, BG.scrollTemplate or "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -32)
    scroll:SetPoint("BOTTOMRIGHT", -30, 12)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(400)
    scroll:SetScrollChild(child)

    local rowH = 22
    local y = 0
    for _, itemID in ipairs(loots) do
        local btn = CreateFrame("Button", nil, child)
        btn:SetSize(400, rowH)
        btn:SetPoint("TOPLEFT", 0, -y)
        y = y + rowH + 2

        local hl = btn:CreateTexture(nil, "BACKGROUND")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.08)
        hl:Hide()

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(18, 18)
        icon:SetPoint("LEFT", 4, 0)

        local fs = btn:CreateFontString(nil, "OVERLAY")
        fs:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        fs:SetWidth(370)
        fs:SetFont(font, 12, "OUTLINE")
        fs:SetJustifyH("LEFT")

        local function RefreshItem()
            local _, link, _, _, _, _, _, _, _, tex = GetItemInfo(itemID)
            if link then
                fs:SetText(link)
                icon:SetTexture(tex)
                btn.itemLink = link
            else
                fs:SetText("|cff808080[item:" .. tostring(itemID) .. "]|r")
            end
        end
        RefreshItem()

        btn:SetScript("OnClick", function()
            local link = btn.itemLink or select(2, GetItemInfo(itemID))
            if link and link ~= "" then
                owner:SetText(link)
                owner:SetCursorPosition(0)
                if BG.Update_IsLooted then
                    BG.Update_IsLooted(owner)
                end
            end
            f:Hide()
            owner:ClearFocus()
            BG.PlaySound(1)
        end)
        btn:SetScript("OnEnter", function()
            hl:Show()
            RefreshItem()
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(btn.itemLink or ("item:" .. itemID))
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            hl:Hide()
            GameTooltip:Hide()
        end)

        if C_Timer then
            C_Timer.After(0.05, RefreshItem)
        end
    end
    child:SetHeight(math.max(y, 1))

    return true
end

function BG.TCODebugHopeLoot()
    local FB = BG.FB1 or "MCtitan"
    local bt = BG.HopeFrame and BG.HopeFrame[FB]
        and BG.HopeFrame[FB]["nandu1"] and BG.HopeFrame[FB]["nandu1"]["boss1"]
        and BG.HopeFrame[FB]["nandu1"]["boss1"]["zhuangbei1"]
    local lootN = BG.Loot and BG.Loot[FB] and BG.Loot[FB].N and BG.Loot[FB].N.boss1
    print("|cff00BFFF<TCO>|r 调试 FB=", FB, "格子=", bt and "OK" or "无",
        "掉落数=", lootN and #lootN or 0)
    if not bt then
        print("|cff00BFFF<TCO>|r 请先 /tcoh 打开心愿窗口")
        return
    end
    OpenHopeLootPicker(bt)
end

function BG.OpenHopeLootPicker(owner)
    if not owner then return false end
    local fn = BG.TCOSetListzhuangbei or BG.SetListzhuangbei
    if fn then
        local ok, err = pcall(fn, owner)
        if not ok then
            print("|cff00BFFF<TCO>|r 装备列表打开失败:", tostring(err))
        end
        return ok
    end
    return BG.TCOShowHopeLootList(owner)
end
