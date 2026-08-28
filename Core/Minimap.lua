local AddonName, ns = ...
local L = ns.L

local BUTTON_NAME = "LibDBIcon10_TitanCharOverview"
local STAR_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local STAR_COORDS = { 0, 0.25, 0, 0.25 } -- 团队标记：星

local function notifyPigCollector()
    if _G.PD and PD.MiniMapBut_Collect then
        PD.MiniMapBut_Collect()
    elseif _G.PD and _G.PD.Mapfun and PD.Mapfun.UpdateCollectBut then
        C_Timer.After(0.2, function()
            PD.Mapfun.UpdateCollectBut(true)
        end)
    end
end

local function updateMinimapPosition(btn, angle)
    angle = angle or 225
    local radius = 80
    local x = radius * math.cos(math.rad(angle))
    local y = radius * math.sin(math.rad(angle))
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function getMinimapDB()
    BiaoGe = BiaoGe or TitanCharOverview or {}
    BiaoGe.minimapBtn = BiaoGe.minimapBtn or {}
    local db = BiaoGe.minimapBtn
    db.minimapPos = tonumber(db.minimapPos) or 225
    return db
end

local function initMinimapButton()
    if not Minimap or _G[BUTTON_NAME] then
        notifyPigCollector()
        return
    end

    local db = getMinimapDB()
    local btn = CreateFrame("Button", BUTTON_NAME, Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:EnableMouse(true)
    btn:RegisterForClicks("anyUp")
    btn:RegisterForDrag("LeftButton")

    local overlay = btn:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT")

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetTexture(STAR_TEXTURE)
    icon:SetTexCoord(STAR_COORDS[1], STAR_COORDS[2], STAR_COORDS[3], STAR_COORDS[4])
    icon:SetPoint("CENTER")

    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            local angle = math.deg(math.atan2(py / scale - my, px / scale - mx)) % 360
            db.minimapPos = angle
            updateMinimapPosition(self, angle)
        end)
    end)

    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        notifyPigCollector()
    end)

    btn:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then
            BG.SetFBCD(nil, nil, true)
        elseif button == "RightButton" then
            if SettingsPanel and SettingsPanel:IsVisible() then
                HideUIPanel(SettingsPanel)
            else
                BG.OpenOption()
            end
        elseif button == "MiddleButton" then
            BG.SetFBCD(nil, nil, true)
        end
        if BG.PlaySound then
            BG.PlaySound(1)
        end
    end)

    btn:SetScript("OnEnter", function(self)
        BG.SetFBCD(self, "minimap")
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L["角色总览"], 1, 1, 1)
        GameTooltip:AddLine(L["打开/关闭角色总览"], 0.8, 0.8, 0.8)
        GameTooltip:AddLine(L["右键：|r打开设置"], 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        if BG.FBCDFrame and not BG.FBCDFrame.click then
            BG.FBCDFrame:Hide()
        end
        GameTooltip:Hide()
    end)

    updateMinimapPosition(btn, db.minimapPos)
    btn:Show()
    ns.minimapBtn = btn

    notifyPigCollector()
    C_Timer.After(2, notifyPigCollector)
    C_Timer.After(8, notifyPigCollector)
end

BG.Init3(initMinimapButton)
