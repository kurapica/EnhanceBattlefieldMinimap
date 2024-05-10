--========================================================--
--                EBFM Questie                            --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2019/08/31                              --
--========================================================--

if Scorpio.IsRetail then return end

--========================================================--
Scorpio     "EnhanceBattlefieldMinimap.Questie" "1.0.0"
--========================================================--

if not IsAddOnLoaded("Questie") then return end

local Questie               = _G.Questie
local HBD_Pins              = _G.LibStub("HereBeDragonsQuestie-Pins-2.0")

local TARGET_MAP
local INITED                = false
local cloneMethod           = function (src, tar) for k, v in pairs(src) do if type(v) == "function" then tar[k] = v end end return tar end

pins_worldmapPinsPool       = HBD_Pins.worldmapPinsPool
pins_worldmapProvider       = HBD_Pins.worldmapProvider

worldmapPinsPool            = cloneMethod(pins_worldmapPinsPool, _G.CreateFramePool("FRAME"))
worldmapProvider            = cloneMethod(pins_worldmapProvider, _G.CreateFromMixins(MapCanvasDataProviderMixin))

__SystemEvent__()
function EBFM_DATAPROVIDER_INIT(map)
    TARGET_MAP              = map

    worldmapPinsPool.parent = map:GetCanvas()
    map.pinPools["HereBeDragonsPinsTemplateQuestie"] = worldmapPinsPool

    map:AddDataProvider(worldmapProvider)

    INITED              = true

    WorldMapFrame:HookScript("OnShow", WorldMapFrame_OnShow)
    WorldMapFrame:HookScript("OnHide", WorldMapFrame_OnHide)

    _Enabled            = true

    if not IsAddOnLoaded("Blizzard_WorldMap") then
        LoadAddOn("Blizzard_WorldMap")
    else
    end

    Continue(function()
        -- Don't know when questie map will show icons, just a try
        for i = 1, 10 do
            Delay(4)
            if not WorldMapFrame:IsShown() then
                WorldMapFrame_OnHide()
            end
        end
    end)
end

__SystemEvent__()
function PLAYER_ENTERING_WORLD()
    pins_worldmapProvider.forceUpdate = true
    return INITED and worldmapProvider:RefreshAllData()
end

__SecureHook__(pins_worldmapProvider)
function RemovePinByIcon(_, ...)
    return INITED and worldmapProvider:RemovePinByIcon(...)
end

__SecureHook__(pins_worldmapProvider)
function RemovePinsByRef(_, ...)
    return INITED and worldmapProvider:RemovePinsByRef(...)
end

__SecureHook__(pins_worldmapProvider)
function RefreshAllData(_, ...)
    pins_worldmapProvider.forceUpdate = true
    return INITED and worldmapProvider:RefreshAllData(...)
end

__SecureHook__(pins_worldmapProvider)
function HandlePin(_, ...)
    return INITED and worldmapProvider:HandlePin(...)
end

function WorldMapFrame_OnShow(self)
    _Enabled = false
    pins_worldmapProvider.forceUpdate = true
    pins_worldmapProvider:RefreshAllData()
end

function WorldMapFrame_OnHide(self)
    _Enabled = true

    local mapID = MapUtil.GetDisplayableMapForPlayer();
    WorldMapFrame:SetMapID(mapID);
    MapCanvasMixin.OnShow(WorldMapFrame)

    pins_worldmapProvider.forceUpdate = true
    worldmapProvider:RefreshAllData()
end