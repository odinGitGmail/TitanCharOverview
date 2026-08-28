-- 跨 WOW 子账号本地聚合（无网络通信）
-- 每个子账号登录时，将本账号角色数据写入 TitanCharOverviewAccounts
local AddonName, ns = ...

local SYNC_KEYS = {
    "RaidCD",
    "MONEY",
    "playerInfo",
    "equip",
    "bag",
    "tradeSkillCooldown",
    "QuestCD",
    "buffCD",
    "roleOverviewNote",
    "PlayerItemsLevel",
    "realmName",
}

local function GetAccountKey()
    if GetAccountName then
        local name = GetAccountName()
        if name and name ~= "" then
            return name
        end
    end
    --  fallback：用当前 WOW 账号目录标识
    return "WOW_ACCOUNT"
end

local function CopyPlayerBranch(dst, src, realmID, player)
    for _, key in ipairs(SYNC_KEYS) do
        if src[key] and src[key][realmID] and src[key][realmID][player] ~= nil then
            dst[key] = dst[key] or {}
            dst[key][realmID] = dst[key][realmID] or {}
            if type(src[key][realmID][player]) == "table" then
                dst[key][realmID][player] = BG.Copy(src[key][realmID][player])
            else
                dst[key][realmID][player] = src[key][realmID][player]
            end
        end
    end
end

local function SyncCurrentAccount()
    BiaoGeAccounts = BiaoGeAccounts or {}
    BiaoGeAccounts.accountName = BiaoGeAccounts.accountName or {}

    local accountKey = GetAccountKey()
    BiaoGeAccounts.accountName[accountKey] = BiaoGeAccounts.accountName[accountKey] or {}

    -- 标记本账号下所有已知角色
    if BiaoGe.MONEY then
        for realmID, players in pairs(BiaoGe.MONEY) do
            if type(realmID) == "number" and type(players) == "table" then
                BiaoGeAccounts.accountName[accountKey][realmID] = BiaoGeAccounts.accountName[accountKey][realmID] or {}
                for player in pairs(players) do
                    BiaoGeAccounts.accountName[accountKey][realmID][player] = true
                    CopyPlayerBranch(BiaoGeAccounts, BiaoGe, realmID, player)
                end
            end
        end
    end

    -- 自定义排序按服务器保留
    if BiaoGe.RoleOverviewSort then
        BiaoGeAccounts.RoleOverviewSort = BiaoGeAccounts.RoleOverviewSort or {}
        for realmID, sortData in pairs(BiaoGe.RoleOverviewSort) do
            if type(sortData) == "table" then
                BiaoGeAccounts.RoleOverviewSort[realmID] = BG.Copy(sortData)
            end
        end
    end

    TitanCharOverviewAccounts = BiaoGeAccounts
end

BG.Init3(function()
    SyncCurrentAccount()
end)

BG.RegisterEvent("PLAYER_LOGOUT", function()
    SyncCurrentAccount()
end)
