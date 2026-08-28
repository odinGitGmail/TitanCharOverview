local AddonName, ns = ...

local L = ns.L

BiaoGeTooltip = CreateFrame("GameTooltip", "BiaoGeTooltip", UIParent, "GameTooltipTemplate")
BiaoGeTooltip2 = CreateFrame("GameTooltip", "BiaoGeTooltip2", UIParent, "GameTooltipTemplate")
BiaoGeTooltip2:SetClampedToScreen(false)
BiaoGeTooltip4 = CreateFrame("GameTooltip", "BiaoGeTooltip4", UIParent, "GameTooltipTemplate")
BiaoGeTooltip5 = CreateFrame("GameTooltip", "BiaoGeTooltip5", UIParent, "GameTooltipTemplate")
BiaoGeTooltip5:SetClampedToScreen(false)

BINDING_HEADER_TITANCHAROVERVIEW = "TitanCharOverview"
BINDING_NAME_RoleOverview = L["打开/关闭角色总览"]

BG.blackListPlayer = {}
