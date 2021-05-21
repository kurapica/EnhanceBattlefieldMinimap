--========================================================--
--                EBFM ClassicCodex                         --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2019/08/31                              --
--========================================================--

--========================================================--
Scorpio    "EnhanceBattlefieldMinimap.HereBeDragons" "1.0.0"
--========================================================--

local HBD_Pins

local TARGET_MAP
local INITED                = false
local cloneMethod           = function (src, tar) for k, v in pairs(src) do if type(v) == "function" then tar[k] = v end end return tar end

local pins_worldmapPinsPool
local pins_worldmapProvider

local worldmapPinsPool
local worldmapProvider

__SystemEvent__()
function EBFM_DATAPROVIDER_INIT(map)
    if not _G.LibStub then return end
    local ok, ret           = pcall(_G.LibStub, "HereBeDragons-Pins-2.0")

    if not ok then return end
    HBD_Pins                = ret

    TARGET_MAP              = map

    pins_worldmapPinsPool   = HBD_Pins.worldmapPinsPool
    pins_worldmapProvider   = HBD_Pins.worldmapProvider

    worldmapPinsPool        = cloneMethod(pins_worldmapPinsPool, _G.CreateFramePool("FRAME"))
    worldmapProvider        = cloneMethod(pins_worldmapProvider, _G.CreateFromMixins(MapCanvasDataProviderMixin))

    worldmapPinsPool.parent = map:GetCanvas()
    map.pinPools["HereBeDragonsPinsTemplate"] = worldmapPinsPool

    map:AddDataProvider(worldmapProvider)

    worldmapProvider:RefreshAllData()

    INITED                  = true

    WorldMapFrame:HookScript("OnShow", function(self)
        _Enabled            = false
        pins_worldmapProvider.forceUpdate = true
        pins_worldmapProvider:RefreshAllData()
    end)
    WorldMapFrame:HookScript("OnHide", function(self)
        _Enabled            = true
        pins_worldmapProvider.forceUpdate = true
        worldmapProvider:RefreshAllData()
    end)

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
end
