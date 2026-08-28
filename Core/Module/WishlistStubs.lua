local AddonName, ns = ...

local GetItemID = ns.GetItemID
local L = ns.L

-- 心愿单模块缺少的 BiaoGe 表格/装备库接口占位
BG.UpdateItemLib_LeftHope_All = BG.UpdateItemLib_LeftHope_All or function() end
BG.UpdateItemLib_RightHope_All = BG.UpdateItemLib_RightHope_All or function() end
BG.UpdateItemLib_LeftHope_HideAll = BG.UpdateItemLib_LeftHope_HideAll or function() end
BG.UpdateItemLib_RightHope_HideAll = BG.UpdateItemLib_RightHope_HideAll or function() end

if not BG.FilterClassItemMainFrame then
    BG.FilterClassItemMainFrame = {
        AddFrame = { Hide = function() end },
        Buttons2 = {
            SetParent = function() end,
            UpdatePoint = function() end,
            Hide = function() end,
        },
        Hide = function() end,
    }
end

-- 历史成交价 / 套装提示：BGLite 精简版未包含 History.lua、独立 TCO 亦不需要
if not BG.SetHistoryMoney then
    function BG.SetHistoryMoney() end
end
if not BG.HideHistoryMoney then
    function BG.HideHistoryMoney() end
end
if not BG.SetZUGSetTooltip then
    function BG.SetZUGSetTooltip() end
end
if not BG.DressUp then
    function BG.DressUp() end
end

-- BGLite 才有完整实现；独立 TCO 仅需处理特殊副本后缀
if not BG.AddHText then
    function BG.AddHText(FB, itemText, itemID, bt)
        if FB == "ULD" and itemText and not itemText:match("H$") then
            for _, num in ipairs({ 10, 20 }) do
                local loot = BG.Loot and BG.Loot.ULD and BG.Loot.ULD["Hard" .. num]
                if loot then
                    for _, _itemID in ipairs(loot) do
                        if itemID == _itemID then
                            bt:SetText(itemText .. "H")
                            return true
                        end
                    end
                end
            end
        elseif FB == "ICC" and itemText and not itemText:match("H$") then
            if itemID == 52030 or itemID == 52029 or itemID == 52028 then
                bt:SetText(itemText .. "H")
                return true
            end
        end
        return false
    end
end

if not BG.Update_IsLooted then
    function BG.Update_IsLooted(bt, itemID)
        if not bt or not bt.looted then return end
        itemID = itemID or GetItemID(bt:GetText())
        if not itemID then
            bt.looted:Hide()
            return
        end

        local FB = bt.FB or BG.FB1
        if BG.GetLeiTingItem then
            itemID = BG.GetLeiTingItem(itemID, FB)
        end

        local Maxb = ns.Maxb
        if BG.Frame and Maxb and Maxb[FB] then
            for b = 1, Maxb[FB] do
                local maxi = BG.GetMaxi and BG.GetMaxi(FB, b) or 0
                for i = 1, maxi do
                    local zb = BG.Frame[FB]["boss" .. b] and BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]
                    if zb and zb.GetText then
                        local _itemID = GetItemID(zb:GetText())
                        if _itemID and BG.GetLeiTingItem then
                            _itemID = BG.GetLeiTingItem(_itemID, FB)
                        end
                        if itemID == _itemID then
                            bt.looted:Show()
                            return
                        end
                    end
                end
            end
        end

        bt.looted:Hide()
    end
end

if not BG.UpdateHopeFrame_IsLooted_All then
    function BG.UpdateHopeFrame_IsLooted_All()
        local FB = BG.FB1
        local HopeMaxn = ns.HopeMaxn
        local HopeMaxb = ns.HopeMaxb
        local HopeMaxi = ns.HopeMaxi
        if not FB or not HopeMaxn or not HopeMaxn[FB] or not BG.HopeFrame or not BG.HopeFrame[FB] then
            return
        end
        for n = 1, HopeMaxn[FB] do
            for b = 1, HopeMaxb[FB] do
                for i = 1, HopeMaxi do
                    local hope = BG.HopeFrame[FB]["nandu" .. n]
                        and BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]
                        and BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i]
                    if hope then
                        BG.Update_IsLooted(hope)
                    end
                end
            end
        end
    end
end

local function ClearHopeWidget(bt)
    if not bt or not bt.SetText then return end
    bt.tcoSuppressChange = true
    bt.tcoLoadToken = (bt.tcoLoadToken or 0) + 1
    bt:SetText("")
    bt:ClearFocus()
    if bt.icon then bt.icon:SetTexture(nil) end
    if bt.looted then bt.looted:Hide() end
    if bt.bindingTex then bt.bindingTex:Hide() end
    if bt.levelText then bt.levelText:Hide() end
    if bt.isHaveTex then bt.isHaveTex:Hide() end
    bt.tcoSuppressChange = nil
end

local function ForEachHopeEditBox(FB, fn)
    if not FB or not fn then return end
    local seen = {}

    if BG.HopeFrame and BG.HopeFrame[FB] then
        local HopeMaxn = ns.HopeMaxn
        local HopeMaxb = ns.HopeMaxb
        local HopeMaxi = ns.HopeMaxi or 7
        if HopeMaxn and HopeMaxn[FB] and HopeMaxb and HopeMaxb[FB] then
            for n = 1, HopeMaxn[FB] do
                for b = 1, HopeMaxb[FB] do
                    for i = 1, HopeMaxi do
                        local bt = BG.HopeFrame[FB]["nandu" .. n]
                            and BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]
                            and BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i]
                        if bt and not seen[bt] then
                            seen[bt] = true
                            fn(bt)
                        end
                    end
                end
            end
        end
    end

    local hopeFrame = BG["HopeFrame" .. FB]
    if hopeFrame and hopeFrame.GetNumChildren then
        local i = 1
        while true do
            local child = select(i, hopeFrame:GetChildren())
            if not child then break end
            if child.GetObjectType and child:GetObjectType() == "EditBox" and child.FB == FB and not seen[child] then
                seen[child] = true
                fn(child)
            end
            i = i + 1
        end
    end
end

function BG.TCOClearHope(FB)
    FB = FB or BG.FB1 or BiaoGe.FB
    local HopeMaxn = ns.HopeMaxn
    local HopeMaxb = ns.HopeMaxb
    if not FB or not HopeMaxn or not HopeMaxn[FB] or not HopeMaxb or not HopeMaxb[FB] then
        return false
    end

    local realmID = GetRealmID()
    local player = BG.playerName

    BiaoGe.Hope = BiaoGe.Hope or {}
    BiaoGe.Hope[realmID] = BiaoGe.Hope[realmID] or {}
    BiaoGe.Hope[realmID][player] = BiaoGe.Hope[realmID][player] or {}
    BiaoGe.Hope[realmID][player][FB] = {}
    if BG.EnsureHopeSavedStructures then
        BG.EnsureHopeSavedStructures(FB)
    end

    ForEachHopeEditBox(FB, ClearHopeWidget)

    if BG.HopeFrameDs then
        for t = 1, 3 do
            local key = FB .. t
            local dsRoot = BG.HopeFrameDs[key]
            if dsRoot then
                for n = 1, HopeMaxn[FB] do
                    for b = 1, HopeMaxb[FB] do
                        for i = 1, (ns.HopeMaxi or 7) do
                            local ds = dsRoot["nandu" .. n]
                                and dsRoot["nandu" .. n]["boss" .. b]
                                and dsRoot["nandu" .. n]["boss" .. b]["ds" .. i]
                            if ds and ds.Hide then
                                ds:Hide()
                            end
                        end
                    end
                end
            end
        end
    end

    if BG.UpdateHopeFrame_IsLooted_All then
        BG.UpdateHopeFrame_IsLooted_All()
    end
    if BG.UpdateItemLib_LeftHope_HideAll then
        BG.UpdateItemLib_LeftHope_HideAll()
    end
    if BG.UpdateItemLib_RightHope_HideAll then
        BG.UpdateItemLib_RightHope_HideAll()
    end

    local shortName = (BG.GetFBinfo and BG.GetFBinfo(FB, "shortName")) or FB
    if SendSystemMessage and BG.STC_g1 then
        SendSystemMessage(BG.STC_g1(format(L["已清空心愿< %s >"], shortName)))
    end
    return true
end

function BG.ClearBiaoGe(_type, FB)
    if _type == "hope" then
        return BG.TCOClearHope(FB)
    end
end
