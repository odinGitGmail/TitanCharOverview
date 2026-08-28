local AddonName, ns = ...
local L = ns.L
local GetItemID = ns.GetItemID
local AddTexture = ns.AddTexture

local hopeAlertCooldown = {}

local function EnsureSoundOptions()
    BiaoGe.options = BiaoGe.options or {}
    if BiaoGe.options.tipsSound == nil then
        BiaoGe.options.tipsSound = 1
    end
    if BiaoGe.options.hopeAuctionSound == nil then
        BiaoGe.options.hopeAuctionSound = 1
    end
    if not BiaoGe.options.Sound then
        BiaoGe.options.Sound = "AI"
    end
end

local function EnsureLootMsgFrame()
    if BG.FrameLootMsg then return end
    local f = CreateFrame("ScrollingMessageFrame", "TCO.FrameLootMsg", UIParent, "BackdropTemplate")
    f:SetSpacing(3)
    f:SetFadeDuration(1)
    f:SetTimeVisible(8)
    f:SetJustifyH("LEFT")
    f:SetSize(700, 170)
    f:SetFont(BIAOGE_TEXT_FONT, 20, "OUTLINE")
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(130)
    f:SetClampedToScreen(true)
    f:SetHyperlinksEnabled(true)
    f:SetPoint("TOP", UIParent, "TOP", -200, -80)
    BG.FrameLootMsg = f
end

-- 解析 CHAT_MSG_LOOT（自己/他人/分配 均支持，对齐原版 BiaoGe/Loot.lua）
local function ParseLootMessage(msg)
    if not msg or msg == "" then return end
    if BG.IsSecret and BG.IsSecret(msg) then return end

    local lootplayer, link, count

    if LOOT_ITEM_SELF_MULTIPLE then
        link, count = msg:match(LOOT_ITEM_SELF_MULTIPLE)
    end
    if not link and LOOT_ITEM_PUSHED_SELF_MULTIPLE then
        link, count = msg:match(LOOT_ITEM_PUSHED_SELF_MULTIPLE)
    end
    if not link and LOOT_ITEM_SELF then
        link = msg:match(LOOT_ITEM_SELF)
    end
    if not link and LOOT_ITEM_PUSHED_SELF then
        link = msg:match(LOOT_ITEM_PUSHED_SELF)
    end
    if not link and LOOT_ITEM_MULTIPLE then
        lootplayer, link, count = msg:match(LOOT_ITEM_MULTIPLE)
    end
    if not link and LOOT_ITEM_PUSHED_MULTIPLE then
        lootplayer, link, count = msg:match(LOOT_ITEM_PUSHED_MULTIPLE)
    end
    if not link and LOOT_ITEM then
        lootplayer, link = msg:match(LOOT_ITEM)
    end
    if not link and LOOT_ITEM_PUSHED then
        lootplayer, link = msg:match(LOOT_ITEM_PUSHED)
    end
    if not link then
        link = msg:match("|c.-|Hitem:%d+:.-|h")
    end
    if not link then return end

    if not lootplayer then
        lootplayer = BG.playerName
    end
    return lootplayer, link, tonumber(count) or 1
end

local function IsWishlistItem(itemID)
    if not itemID or not BG.IsHope then return false end
    local FB = BG.FB2 or BG.FB1
    if FB and BG.IsHope(itemID, FB) then
        return true
    end
    return BG.IsHope(itemID)
end

local function ShouldPlayHopeAlert(itemID)
    local now = GetTime()
    local last = hopeAlertCooldown[itemID]
    if last and now - last < 2 then
        return false
    end
    hopeAlertCooldown[itemID] = now
    return true
end

local function OnLootMessage(_, _, msg)
    if not BG.IsTitan then return end
    EnsureSoundOptions()
    if BiaoGe.options.tipsSound ~= 1 then return end

    local lootplayer, link = ParseLootMessage(msg)
    if not link then return end

    local itemID = GetItemID(link)
    if not itemID then return end
    if BG.GetLeiTingItem then
        itemID = BG.GetLeiTingItem(itemID, BG.FB2 or BG.FB1)
    end
    if not IsWishlistItem(itemID) then return end
    if not ShouldPlayHopeAlert(itemID) then return end

    EnsureLootMsgFrame()
    local _, itemLink, _, level, _, _, _, _, _, texture = GetItemInfo(itemID)
    link = itemLink or link
    texture = texture or 134400

    local who = lootplayer and lootplayer ~= BG.playerName and (" (" .. lootplayer .. ")") or ""
    BG.FrameLootMsg:AddMessage(BG.STC_g1(format(L["你的心愿达成啦！！！>>>>> %s(%s) <<<<<"] .. who,
        AddTexture(texture) .. link, level or "")))
    BG.PlaySound("hope")
end

local auctionKeywords = {
    "拍卖", "起拍", "当前", "加价", "倒数", "成交", "金", "万",
}

local function LooksLikeAuction(msg)
    for _, kw in ipairs(auctionKeywords) do
        if msg:find(kw) then
            return true
        end
    end
    return false
end

local function OnAuctionChat(_, _, msg)
    if not BG.IsTitan then return end
    EnsureSoundOptions()
    if BiaoGe.options.hopeAuctionSound ~= 1 then return end
    if not LooksLikeAuction(msg) then return end
    EnsureLootMsgFrame()

    local played = {}
    for itemID in msg:gmatch("|Hitem:(%d+):") do
        itemID = tonumber(itemID)
        if BG.GetLeiTingItem then
            itemID = BG.GetLeiTingItem(itemID, BG.FB2 or BG.FB1)
        end
        if itemID and IsWishlistItem(itemID) and not played[itemID] then
            played[itemID] = true
            local _, link, _, _, _, _, _, _, _, texture = GetItemInfo(itemID)
            link = link or ("item:" .. itemID)
            texture = texture or 134400
            BG.FrameLootMsg:AddMessage(BG.STC_g1(format(L["你关注的装备开始拍卖了：%s（%s取消关注）"],
                AddTexture(texture) .. link, AddTexture("RIGHT"))))
            BG.PlaySound("paimai")
        end
    end
end

-- 当前所在副本 ID（BG.FB2），BGLite 未加载时由 TCO 自己维护
local function EnsureInstanceFBTracker()
    if BG.TCOInstanceFBTracker then return end
    BG.TCOInstanceFBTracker = true
    C_Timer.NewTicker(5, function()
        BG.FB2 = nil
        local FBID = select(8, GetInstanceInfo())
        if FBID and BG.FBIDtable then
            for _FBID, FB in pairs(BG.FBIDtable) do
                if FBID == _FBID then
                    BG.FB2 = FB
                    break
                end
            end
        end
    end)
end

BG.Init3(function()
    if not BG.IsTitan then return end
    EnsureSoundOptions()
    EnsureLootMsgFrame()
    EnsureInstanceFBTracker()
    BG.RegisterEvent("CHAT_MSG_LOOT", OnLootMessage)
    BG.RegisterEvent({ "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING" }, OnAuctionChat)
end)

-- 注册露露语音包路径（依赖 BiaoGe-Rurutia，不依赖 BiaoGe 主插件）
BG.Init2(function()
    if not BG.IsTitan then return end
    if not C_AddOns or not C_AddOns.IsAddOnLoaded("BiaoGe-Rurutia") then return end
    local author = "露露缇娅"
    local base = "Interface\\AddOns\\BiaoGe-Rurutia\\sound\\"
    BG["sound_hope" .. author] = BG["sound_hope" .. author] or (base .. "心愿达成")
    BG["sound_paimai" .. author] = BG["sound_paimai" .. author] or (base .. "拍卖啦")
    if BiaoGe.options and BiaoGe.options.Sound == "AI" then
        BiaoGe.options.Sound = author
    end
end)

-- 调试：/tco hope voice
function BG.TCOHopeVoiceTest()
    if not BG.IsTitan then return end
    EnsureSoundOptions()
    EnsureLootMsgFrame()
    if BiaoGe.options.tipsSound ~= 1 then
        print("|cff00BFFF<TCO>|r 心愿语音未开启。请 /tcoopt → 心愿清单 → 勾选「心愿达成语音」。")
        return
    end
    local _, link = GetItemInfo(19019)
    link = link or "|cff0070dd|Hitem:19019:0:0:0:0:0:0:0|h[测试]|h|r"
    BG.FrameLootMsg:AddMessage(BG.STC_g1(format(L["你的心愿达成啦！！！>>>>> %s(%s) <<<<<"],
        AddTexture(134400) .. link, "")))
    BG.PlaySound("hope")
    print("|cff00BFFF<TCO>|r 已播放心愿达成语音（语音包：" .. tostring(BiaoGe.options.Sound) .. "）")
end

-- 调试：/tco hope match
function BG.TCOHopeMatchTest()
    if not BG.IsTitan then return end
    local FB = BG.FB1
    if not FB or not BG.HopeFrame or not BG.HopeFrame[FB] then
        print("|cff00BFFF<TCO>|r 心愿未初始化，请先 /tcoh 打开心愿清单。")
        return
    end
    local count = 0
    for key, grid in pairs(BG.HopeFrame[FB]) do
        if type(key) == "string" and key:match("^nandu") and type(grid) == "table" then
            for bkey, boss in pairs(grid) do
                if type(bkey) == "string" and bkey:match("^boss") and type(boss) == "table" then
                    for zkey, edit in pairs(boss) do
                        if type(zkey) == "string" and zkey:match("^zhuangbei")
                            and edit and edit.GetText then
                            local link = edit:GetText()
                            if link and link ~= "" then
                                count = count + 1
                                local itemID = GetItemID(link)
                                local matched = itemID and BG.IsHope(itemID, FB)
                                print(format("|cff00BFFF<TCO>|r #%d %s  %s",
                                    count,
                                    matched and "|cff00ff00匹配|r" or "|cffff0000未匹配|r",
                                    link))
                            end
                        end
                    end
                end
            end
        end
    end
    if count == 0 then
        print("|cff00BFFF<TCO>|r 当前副本心愿为空（FB=" .. tostring(FB) .. "）")
    else
        print("|cff00BFFF<TCO>|r 共 " .. count .. " 件；心愿语音="
            .. tostring(BiaoGe.options.tipsSound) .. "；拍卖语音="
            .. tostring(BiaoGe.options.hopeAuctionSound))
    end
end
