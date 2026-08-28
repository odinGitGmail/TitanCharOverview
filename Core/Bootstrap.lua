local AddonName, ns = ...

-- 确保 SavedVariables 别名已建立（Migrate.lua 在 DB 之前已执行）
ns.MigrateSavedVariables = ns.MigrateSavedVariables or function() end
ns.MigrateSavedVariables()

-- 世界 Boss CD 上报 stub（原 BiaoGe 团队通信，独立插件不需要）
ns.SendMyWorldBossCD = function() end

local function RegisterSlashCommands()
    SlashCmdList["TitanCharOverview"] = function(msg)
        msg = strtrim(msg or ""):lower()
        if msg == "hope" or msg == "wish" or msg == "心愿" then
            if BG.OpenWishlist then
                BG.OpenWishlist()
            else
                print("|cff00BFFF<TCO>|r 心愿模块未加载，请 /reload 后重试。")
            end
            return
        end
        if msg == "hope test" or msg == "testhope" or msg == "心愿测试" then
            if BG.TCODebugHopeLoot then
                BG.TCODebugHopeLoot()
            else
                print("|cff00BFFF<TCO>|r 心愿模块未加载，请 /reload 后重试。")
            end
            return
        end
        if msg == "hope voice" or msg == "hope voice test" or msg == "心愿语音" then
            if BG.TCOHopeVoiceTest then
                BG.TCOHopeVoiceTest()
            else
                print("|cff00BFFF<TCO>|r 心愿提醒模块未加载，请 /reload 后重试。")
            end
            return
        end
        if msg == "hope match" or msg == "心愿匹配" then
            if BG.TCOHopeMatchTest then
                BG.TCOHopeMatchTest()
            else
                print("|cff00BFFF<TCO>|r 心愿提醒模块未加载，请 /reload 后重试。")
            end
            return
        end
        if BG.SetFBCD then
            BG.SetFBCD(nil, nil, true)
        end
    end
    SLASH_TitanCharOverview1 = "/tco"
    SLASH_TitanCharOverview2 = "/bgr"

    SlashCmdList["TitanCharOverviewHope"] = function()
        if BG.OpenWishlist then
            BG.OpenWishlist()
        else
            print("|cff00BFFF<TCO>|r 心愿模块未加载，请 /reload 后重试。")
        end
    end
    SLASH_TitanCharOverviewHope1 = "/tcoh"

    SlashCmdList["TitanCharOverviewOptions"] = function()
        if BG.OpenOption then
            BG.OpenOption()
        end
    end
    SLASH_TitanCharOverviewOptions1 = "/tcoopt"
end

-- 文件加载时立即注册，避免 PLAYER_LOGIN 时序导致命令失效
RegisterSlashCommands()
BG.Init(RegisterSlashCommands)
BG.Init3(function()
    if BG.ResolveUITemplates then
        BG.ResolveUITemplates()
    end
    RegisterSlashCommands()
    if BG.TCOSetListzhuangbei then
        BG.SetListzhuangbei = BG.TCOSetListzhuangbei
    end
    -- BGLite PLAYER_LOGIN 会覆盖 ClearBiaoGe，此处恢复心愿清空逻辑
    local oldClearBiaoGe = BG.ClearBiaoGe
    function BG.ClearBiaoGe(_type, FB)
        if _type == "hope" and BG.TCOClearHope then
            return BG.TCOClearHope(FB)
        end
        if oldClearBiaoGe and oldClearBiaoGe ~= BG.ClearBiaoGe then
            return oldClearBiaoGe(_type, FB)
        end
    end
end)
