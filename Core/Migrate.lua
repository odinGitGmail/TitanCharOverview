-- 从 BiaoGe 迁移 SavedVariables 数据到 TitanCharOverview
local AddonName, ns = ...

local function DeepMerge(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then
        return dst
    end
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then
                dst[k] = {}
            end
            DeepMerge(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

local function CopyTable(src)
    if type(src) ~= "table" then return src end
    local t = {}
    for k, v in pairs(src) do
        t[k] = type(v) == "table" and CopyTable(v) or v
    end
    return t
end

-- BGLite 在 TCO 切换 BiaoGe 别名前写入独立 SavedVariables 表；合并后仍需补齐 Options.lua 才初始化的字段
local BGLiteOptionDefaults = {
    alpha = 0.8,
    scale = 1,
    bg = "0.01,0.01,0.01,0.8",
    mainIcon = 0,
    mainIconScale = 1,
    mainIconFrameLevel = "HIGH",
    Sound = "AI",
    tipsSound = 1,
    hopeAuctionSound = 1,
    buttonSound = 1,
    autoLoot = 1,
    moLing = 1,
    editFontSize = 14,
    showAuctionLogFrame = 1,
    auctionLogChoose = 1,
    autoCreateBill = 1,
    enableSendMail = 1,
    NotifyChannel = "RAID",
}

local function EnsureOptionDefault(key, default)
    if BiaoGe.options[key] == nil then
        BiaoGe.options[key] = default
    end
end

local function EnsureBGLiteCoexistDefaults()
    BiaoGe.options = BiaoGe.options or {}
    BiaoGe.options.SearchHistory = BiaoGe.options.SearchHistory or {}
    BiaoGe.point = BiaoGe.point or {}

    if type(BiaoGe.options.alpha) ~= "number" then
        BiaoGe.options.alpha = (type(BiaoGe.Alpha) == "number" and BiaoGe.Alpha) or BGLiteOptionDefaults.alpha
    end
    if type(BiaoGe.options.scale) ~= "number" then
        BiaoGe.options.scale = (type(BiaoGe.Scale) == "number" and BiaoGe.Scale) or BGLiteOptionDefaults.scale
    end
    if type(BiaoGe.options.mainIconScale) ~= "number" then
        BiaoGe.options.mainIconScale = BGLiteOptionDefaults.mainIconScale
    end
    if type(BiaoGe.options.mainIconFrameLevel) ~= "string" or BiaoGe.options.mainIconFrameLevel == "" then
        BiaoGe.options.mainIconFrameLevel = BGLiteOptionDefaults.mainIconFrameLevel
    end

    for key, default in pairs(BGLiteOptionDefaults) do
        EnsureOptionDefault(key, default)
    end
end

function ns.EnsureBGLiteCoexistDefaults()
    EnsureBGLiteCoexistDefaults()
end

function ns.MigrateSavedVariables()
    TitanCharOverview = TitanCharOverview or {}
    TitanCharOverviewAccounts = TitanCharOverviewAccounts or {}

    -- WoW 会分别加载 BiaoGe / TitanCharOverview 两个 SavedVariables 表。
    -- BGLite 先于 TCO 触发 ADDON_LOADED，会把 auctionMSGhistory 等写入独立 BiaoGe 表。
    local legacyBiaoGe = (type(BiaoGe) == "table" and BiaoGe ~= TitanCharOverview) and BiaoGe or nil
    local legacyBiaoGeAccounts = (type(BiaoGeAccounts) == "table" and BiaoGeAccounts ~= TitanCharOverviewAccounts) and BiaoGeAccounts or nil

    -- 首次迁移：合并旧 BiaoGe / BiaoGeAccounts 数据
    if not TitanCharOverview.__migratedFromBiaoGe then
        if legacyBiaoGe and next(legacyBiaoGe) then
            DeepMerge(TitanCharOverview, legacyBiaoGe)
        end
        if legacyBiaoGeAccounts and next(legacyBiaoGeAccounts) then
            DeepMerge(TitanCharOverviewAccounts, legacyBiaoGeAccounts)
        end
        TitanCharOverview.__migratedFromBiaoGe = true
    elseif legacyBiaoGe then
        -- 每登录合并 BGLite 写入独立 BiaoGe 表的数据（含拍卖聊天记录等）
        DeepMerge(TitanCharOverview, legacyBiaoGe)
    end
    if legacyBiaoGeAccounts then
        DeepMerge(TitanCharOverviewAccounts, legacyBiaoGeAccounts)
    end

    -- 统一别名：模块代码仍使用 BiaoGe / BiaoGeAccounts
    BiaoGe = TitanCharOverview
    BiaoGeAccounts = TitanCharOverviewAccounts

    -- 同步回写，确保 WoW 持久化
    _G.TitanCharOverview = TitanCharOverview
    _G.TitanCharOverviewAccounts = TitanCharOverviewAccounts
    _G.BiaoGe = BiaoGe
    _G.BiaoGeAccounts = BiaoGeAccounts

    -- function2.lua 过滤装备模块需要的基础结构
    BiaoGe.FilterClassItemDB = BiaoGe.FilterClassItemDB or {}
    BiaoGe.options = BiaoGe.options or {}
    BiaoGe.disabledModules = BiaoGe.disabledModules or {}

    -- BGLite 共存：BiaoGe 别名切换后仍需存在的字段
    BiaoGe.auctionMSGhistory = BiaoGe.auctionMSGhistory or {}
    BiaoGe.Auction = BiaoGe.Auction or {}
    BiaoGe.tradeHistory = BiaoGe.tradeHistory or {}
    BiaoGe.mailHistory = BiaoGe.mailHistory or {}
    BiaoGe.sendMail = BiaoGe.sendMail or {}

    EnsureBGLiteCoexistDefaults()
end

-- 尽早执行迁移，确保 DB.lua 读到合并后的数据
ns.MigrateSavedVariables()
