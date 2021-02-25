--========================================================--
--                Enhance Battlefield Minimap             --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2018/07/19                             --
--========================================================--

--========================================================--
Scorpio            "EnhanceBattlefieldMinimap"       "2.0.1"
--========================================================--

import "System.Reactive"

local OriginOnMouseWheel
local ORIGIN_WIDTH, ORIGIN_HEIGHT
local ORIGIN_AddWorldQuest
local _WorldQuestDataProvider

local ENTER_TASK_ID = 0

local _IncludeMinimap, _MinimapControlled, _MinimapOriginalSize

local Enum              = _G.Enum
local _InBattleField    = false

export { min = math.min }

WORLD_QUEST_PIN_LIST    = List()


PIN_TEXTURE             = [[Interface\AddOns\EnhanceBattlefieldMinimap\resource\pin.blp]]
ORIGIN_PLAYER_TEXTURE   = [[Interface\WorldMap\WorldMapArrow]]

----------------------------------------------
--            Addon Event Handler           --
----------------------------------------------
function OnLoad(self)
    _SVDB               = SVManager.SVCharManager("EnhanceBattlefieldMinimap_DB")

    _SVDB:SetDefault {
        -- Display Status
        CanvasScale     = 1.0,
        MaskSize        = nil,
        Resizable       = true,
        BlockTab        = false,
        ZoomTarget      = 1.0,

        -- Minimap
        IncludeMinimap  = false,
        AlwaysInclude   = false,
        MinimapSize     = 180,

        -- Block the mouse interaction with the embed minimap
        BlockEmbedMap   = true,

        -- Border Color
        BorderColor     = {
            r           = 0,
            g           = 0,
            b           = 0,
            a           = 1,
        },

        -- The Frame Strata
        FrameStrata     = "LOW",

        -- Zone Text
        ShowZoneText    = true,
        ZoneLocation    = { x = 2, y = -2 },
        ZoneTextScale   = 1.0,

        -- Player Arrow
        PlayerScale     = 1.0,
        PartyScale      = 1.0,
        RaidScale       = 1.0,
        UseClassColor   = true,

        -- Replace pin
        ReplacePlayerPin= false,
        ReplacePartyPin = false,
        ReplaceRaidPin  = false,

        -- Area Label Scale
        AreaLabelScale  = 0.5,

        -- World Quest Scale
        WorldQuestScale = 0.5,

        -- Block the mouse action on the map
        BlockMouse      = false,

        -- Only show in battlegroud
        OnlyBattleField = false,

        -- Enable the mouse coordinate
        EnableCoordinate= true,
    }
end

__Async__()
function OnEnable(self)
    OnEnable            = nil

    _Enabled            = false

    if not IsAddOnLoaded("Blizzard_BattlefieldMap") then
        while NextEvent("ADDON_LOADED") ~= "Blizzard_BattlefieldMap" do end
        Next()
    end

    BFMScrollContainer  = BattlefieldMapFrame.ScrollContainer

    if not BattlefieldMapFrame:IsShown() then
        Next(Observable.From(Frame(BattlefieldMapFrame).OnShow))
    end

    ORDER_RESOURCES_CURRENCY_ID = 1220
    azeriteCurrencyID   = C_CurrencyInfo.GetAzeriteCurrencyID()
    warResourcesCurrencyID = C_CurrencyInfo.GetWarResourcesCurrencyID()

    BattlefieldMapTab:SetUserPlaced(true)   -- Fix the bug blz won't save location
    BattlefieldMapTab:SetScript("OnClick", BattlefieldMapTab_OnClick) -- Change the menu

    BattlefieldMapFrame:SetShouldNavigateOnClick(true)
    BattlefieldMapFrame.UpdatePinNudging = UpdatePinNudging

    ORIGIN_WIDTH        = BattlefieldMapFrame:GetWidth()
    ORIGIN_HEIGHT       = BattlefieldMapFrame:GetHeight()

    BFMScrollContainer:HookScript("OnShow", Container_OnShow)
    BFMScrollContainer:HookScript("OnHide", Container_OnHide)
    BFMScrollContainer:HookScript("OnMouseDown", Container_OnMouseDown)
    BFMScrollContainer:HookScript("OnMouseUp", Container_OnMouseUp)
    BFMScrollContainer:HookScript("OnEnter", Container_OnEnter)

    BattlefieldMapFrame:SetResizable(_SVDB.Resizable)
    BFMResizer          = Resizer("EBFMResizer", BFMScrollContainer)
    BFMResizer.ResizeTarget = BattlefieldMapFrame
    BFMResizer.OnStopResizing = BFMResizer_OnResized
    Style[BFMResizer].size = Size(24, 24)

    BFMScrollContainer.CalculateViewRect = CalculateViewRect

    OriginOnMouseWheel  = BFMScrollContainer:GetScript("OnMouseWheel")
    BFMScrollContainer:SetScript("OnMouseWheel", Container_OnMouseWheel)
    BattlefieldMapFrame.BorderFrame:Hide()

    BattlefieldMapFrameBack = CreateFrame("Frame", nil, BFMScrollContainer)
    BattlefieldMapFrameBack:SetFrameStrata("HIGH")
    BattlefieldMapFrameBack:SetPoint("TOPLEFT", 0, 0)
    BattlefieldMapFrameBack:SetPoint("BOTTOMRIGHT", 0, 0)
    BattlefieldMapFrameBack:SetIgnoreParentScale(true)
    BattlefieldMapFrameBack:SetAlpha(min(1 - (_G.BattlefieldMapOptions.opacity or 0), _SVDB.BorderColor.a))

    Style[BattlefieldMapFrameBack] = {
        backdrop            = { edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 },
        backdropBorderColor = Color(_SVDB.BorderColor.r, _SVDB.BorderColor.g, _SVDB.BorderColor.b, _SVDB.BorderColor.a),
    }

    BattlefieldMapFrameCoordsFrame = CreateFrame("Frame", nil, BFMScrollContainer)
    BattlefieldMapFrameCoordsFrame:SetFrameStrata("HIGH")
    BattlefieldMapFrameCoordsFrame:SetSize(40, 32)
    BattlefieldMapFrameCoordsFrame:SetPoint("TOPRIGHT", -8, 0)
    BattlefieldMapFrameCoordsFrame:SetIgnoreParentScale(true)

    BattlefieldMapFrameCoords = BattlefieldMapFrameCoordsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    BattlefieldMapFrameCoords:SetPoint("RIGHT")

    Minimap:HookScript("OnEnter", Minimap_OnEnter)

    -- Zone Text
    BattlefieldZoneTextFrame  = CreateFrame("Frame", nil, BFMScrollContainer)
    BattlefieldZoneTextFrame:SetFrameStrata("HIGH")
    BattlefieldZoneTextFrame:SetSize(40, 32)
    BattlefieldZoneTextFrame:SetPoint("TOPLEFT", BFMScrollContainer, "TOPLEFT", _SVDB.ZoneLocation.x, _SVDB.ZoneLocation.y)
    BattlefieldZoneTextFrame:SetMovable(true)
    BattlefieldZoneTextFrame:EnableMouse(true)
    BattlefieldZoneTextFrame:EnableMouseWheel(true)
    BattlefieldZoneTextFrame:SetIgnoreParentScale(true)

    BattlefieldZoneTextFrame:SetScript("OnMouseDown", BattlefieldZoneTextFrame.StartMoving)
    BattlefieldZoneTextFrame:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()

        local loc               = LayoutFrame.GetLocation(self, { Anchor("TOPLEFT") })

        _SVDB.ZoneLocation.x    = loc[1].x
        _SVDB.ZoneLocation.y    = loc[1].y

        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", BFMScrollContainer, "TOPLEFT", _SVDB.ZoneLocation.x, _SVDB.ZoneLocation.y)
    end)
    BattlefieldZoneTextFrame:SetScript("OnMouseWheel", function(self, delta)
        _SVDB.ZoneTextScale  = Clamp(_SVDB.ZoneTextScale + delta/math.abs(delta) * 0.1, 0.3, 4)
        BattlefieldZoneText:SetFont(BattlefieldZoneText.fonts[1], BattlefieldZoneText.fonts[2] * _SVDB.ZoneTextScale, BattlefieldZoneText.fonts[3])
        BattlefieldZoneTextFrame:SetHeight(BattlefieldZoneText.fonts[2] * _SVDB.ZoneTextScale + 2)
        BattlefieldZoneTextFrame:SetWidth(BattlefieldZoneText:GetStringWidth() + 2)
    end)

    BattlefieldZoneText       = BattlefieldZoneTextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    BattlefieldZoneText:SetPoint("CENTER")
    BattlefieldZoneText.fonts = { BattlefieldZoneText:GetFont() }
    BattlefieldZoneText:SetFont(BattlefieldZoneText.fonts[1], BattlefieldZoneText.fonts[2] * _SVDB.ZoneTextScale, BattlefieldZoneText.fonts[3])
    BattlefieldZoneTextFrame:SetHeight(BattlefieldZoneText.fonts[2] * _SVDB.ZoneTextScale + 2)

    UpdateZoneText()

    -- Apply Settings
    if _SVDB.MaskSize then
        BattlefieldMapFrame:SetSize(_SVDB.MaskSize.width, _SVDB.MaskSize.height)
        BattlefieldMapFrame:OnFrameSizeChanged()
    end

    _Enabled            = true

    AddRestDataProvider(BattlefieldMapFrame)

    _IncludeMinimap     = _SVDB.IncludeMinimap
    _MinimapControlled  = false

    if _SVDB.ShowZoneText then
        BattlefieldZoneTextFrame:Show()
    else
        BattlefieldZoneTextFrame:Hide()
    end

    if BattlefieldMapFrame:IsVisible() then
        LockOnPlayer(BFMScrollContainer)
        TryInitMinimap()
    end

    _M:SecureHook(BattlefieldMapFrame, "UpdateUnitsVisibility")

    if UnitIsDeadOrGhost("player") then PLAYER_DEAD(true) end

    Next()

    pcall(BFMScrollContainer.SetZoomTarget, BFMScrollContainer, _SVDB.ZoomTarget)

    pcall(MapCanvasMixin.OnHide, BattlefieldMapFrame)
    MapCanvasMixin.OnShow(BattlefieldMapFrame)

    BFMScrollContainer:EnableMouse(not _SVDB.BlockMouse)
    BFMScrollContainer:EnableMouseWheel(not _SVDB.BlockMouse)
    BattlefieldMapFrame:EnableMouse(not _SVDB.BlockMouse)

    local test          = Texture("test", BFMScrollContainer, "ARTWORK")
    test:SetTexture(PIN_TEXTURE)
    test:Hide()

    BattlefieldMapFrame:SetFrameStrata(_SVDB.FrameStrata)

    ReplacePartyPin()
    BlockTabFrame()
end

function OnQuit(self)
    _SVDB.ZoomTarget    = BFMScrollContainer:GetCanvasScale()
end

__SlashCmd__("ebfm", "reset", _Locale["reset the zone map"])
function resetlocaton()
    BattlefieldMapTab:ClearAllPoints()
    BattlefieldMapTab:SetPoint("TOPLEFT", 100, -100)

    UpdatePlayerScale()

    _SVDB.MaskSize      = Size(ORIGIN_WIDTH, ORIGIN_HEIGHT)
    BattlefieldMapFrame:SetSize(ORIGIN_WIDTH, ORIGIN_HEIGHT)
    BattlefieldMapFrame:OnFrameSizeChanged()
end

__SlashCmd__("ebfm", "incminimap", _Locale["on/off/always - embed the minimap"])
function ToggleIncludeMinimap(opt)
    if opt == "always" then
        _SVDB.AlwaysInclude = true
        _SVDB.IncludeMinimap = true
        _IncludeMinimap = true
        TryInitMinimap()
    elseif opt == "on" then
        if not _IncludeMinimap then
            _SVDB.IncludeMinimap = true
            _IncludeMinimap = true
            TryInitMinimap()
        end

        _SVDB.AlwaysInclude = false

        if _IncludeMinimap and not BFMScrollContainer:IsVisible() then
            SendBackMinimap()
        end
    elseif opt == "off" then
        _SVDB.AlwaysInclude = false
        if _IncludeMinimap then
            _SVDB.IncludeMinimap = false
            _IncludeMinimap = false
            SendBackMinimap()
        end
    else
        return false
    end
end

__SlashCmd__("ebfm", "color", _Locale["r, g, b[, a] - the border's color"])
function SetBorderColor(opt)
    local color = { strsplit(",", opt) }

    if #color < 3 then return false end

    for i = 1, 4 do
        if color[i] then
            local v = tonumber(strtrim(color[i]))
            if not v or v < 0 or v > 1 then return false end
            color[i] = v
        elseif i < 4 then
            return false
        else
            color[i] = 1
        end
    end

    _SVDB.BorderColor.r, _SVDB.BorderColor.g, _SVDB.BorderColor.b, _SVDB.BorderColor.a = unpack(color)

    Style[BattlefieldMapFrameBack].backdropBorderColor = Color(_SVDB.BorderColor.r, _SVDB.BorderColor.g, _SVDB.BorderColor.b, _SVDB.BorderColor.a)
end

__SlashCmd__("ebfm", "zonetext", _Locale["on/off - whether show the zone text"])
function ToggleZoneText(opt)
    if opt == "on" then
        _SVDB.ShowZoneText = true
        BattlefieldZoneTextFrame:Show()
    elseif opt == "off" then
        _SVDB.ShowZoneText = false
        BattlefieldZoneTextFrame:Hide()
    else
        return false
    end
end

__SlashCmd__("ebfm", "player", _Locale["scale - set the scale of the player arror"])
function SetPlayerScale(opt)
    opt = tonumber(opt)
    if opt and opt > 0 then
        _SVDB.PlayerScale = opt
        UpdatePlayerScale()

        if BattlefieldMapFrame:IsVisible() then
            BattlefieldMapFrame:Hide()
            BattlefieldMapFrame:Show()
        end
    else
        return false
    end
end

__SlashCmd__("ebfm", "party", _Locale["scale - set the scale of the party members"])
function SetPartyScale(opt)
    opt = tonumber(opt)
    if opt and opt > 0 then
        _SVDB.PartyScale = opt
        UpdatePlayerScale()

        if BattlefieldMapFrame:IsVisible() then
            BattlefieldMapFrame:Hide()
            BattlefieldMapFrame:Show()
        end
    else
        return false
    end
end

__SlashCmd__("ebfm", "raid", _Locale["scale - set the scale of the raid members"])
function SetRaidScale(opt)
    opt = tonumber(opt)
    if opt and opt > 0 then
        _SVDB.RaidScale = opt
        UpdatePlayerScale()

        if BattlefieldMapFrame:IsVisible() then
            BattlefieldMapFrame:Hide()
            BattlefieldMapFrame:Show()
        end
    else
        return false
    end
end

__SlashCmd__("ebfm", "arealabel", _Locale["[0.1-4] - set the scale of the area labels"])
function SetAreaLabelScale(opt)
    _SVDB.AreaLabelScale = Clamp(tonumber(opt) or 0, 0.1, 4)
    UpdateAreaLabelScale()
end

__SlashCmd__("ebfm", "worldquest", _Locale["[0.1-2] - set the scale of the world quest icon, default 0.5"])
function SetWorldQuestScale(opt)
    opt                         = Clamp(tonumber(opt) or 0, 0.1, 3)
    _SVDB.WorldQuestScale       = opt

    for _, pin in WORLD_QUEST_PIN_LIST:GetIterator() do
        pin:SetScalingLimits(1, opt, opt)
        pin:SetScale(opt)
    end
end

__SlashCmd__("ebfm", "mouse", _Locale["on/off - toggle the usage of the mouse action"])
function EnableMouseAction(opt)
    _SVDB.BlockMouse            = opt and opt:lower() == "off" or false
    BFMScrollContainer:EnableMouse(not _SVDB.BlockMouse)
    BFMScrollContainer:EnableMouseWheel(not _SVDB.BlockMouse)
    BattlefieldMapFrame:EnableMouse(not _SVDB.BlockMouse)
end

__SlashCmd__("ebfm", "lock", _Locale["Lock the map so it can't be resized"])
function LockMap()
    _SVDB.Resizable             = false
    BattlefieldMapFrame:SetResizable(_SVDB.Resizable)
end

__SlashCmd__("ebfm", "unlock", _Locale["Unlock the map so it can be resized"])
function UnLockMap()
    _SVDB.Resizable             = true
    BattlefieldMapFrame:SetResizable(_SVDB.Resizable)
end

__SlashCmd__("ebfm", "blocktab", _Locale["on/off - Block the tab frame"])
function BlockMap(opt)
    _SVDB.BlockTab              = opt and opt:lower() == "on" or false

    BlockTabFrame()
end

__SlashCmd__("ebfm", "onlybg", _Locale["on/off - whether only show in battlegroud"])
function ToggleOnlyBattlefield(opt)
    if opt == "on" then
        _SVDB.OnlyBattleField = true
        if _InBattleField then
            BFMScrollContainer:Show()
        else
            BFMScrollContainer:Hide()
        end
    elseif opt == "off" then
        _SVDB.OnlyBattleField = false
        BFMScrollContainer:Show()
    else
        return false
    end
end

__SlashCmd__("ebfm", "coordinate", _Locale["on/off - whether show the coordinate"])
function ToggleMouseCoordinate(opt)
    if opt == "on" then
        _SVDB.EnableCoordinate = true
    elseif opt == "off" then
        _SVDB.EnableCoordinate = false
    else
        return false
    end
end

----------------------------------------------
--               System Event               --
----------------------------------------------
__Async__() __SystemEvent__()
function PLAYER_DEAD()
    Delay(6)

    BattlefieldMapFrame:RefreshAllDataProviders(true)

    repeat
        Wait("PLAYER_UNGHOST", "PLAYER_ALIVE", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED")
        BattlefieldMapFrame:RefreshAllDataProviders(true)
    until not UnitIsDeadOrGhost("player")
end

__SystemEvent__()
function PLAYER_STARTED_MOVING()
    -- ZONE_CHANGED()
    return LockOnPlayer(BFMScrollContainer)
end

__SystemEvent__() __Async__()
function ZONE_CHANGED_NEW_AREA()
    UpdateZoneText()
    Next()
    if BFMScrollContainer.zoomLevels then
        BFMScrollContainer:SetZoomTarget(_SVDB.CanvasScale)
    end
end

__SystemEvent__ "ZONE_CHANGED_INDOORS" "ZONE_CHANGED"
__Async__()
function ZONE_CHANGED()
    UpdateZoneText()
    Next()

    if _WorldQuestDataProvider then _WorldQuestDataProvider:RefreshAllData() end

    if MapUtil.GetDisplayableMapForPlayer() ~= BattlefieldMapFrame:GetMapID() then
        -- Return to the player's map
        local mapID = MapUtil.GetDisplayableMapForPlayer()
        if mapID then
            BattlefieldMapFrame:SetMapID(mapID)

            Next()
            if BFMScrollContainer.zoomLevels then
                BFMScrollContainer:SetZoomTarget(_SVDB.CanvasScale)
            end
        end
    end
end

__SystemEvent__()
function PLAYER_ENTERING_WORLD()
    _InBattleField              = false
    if BFMScrollContainer and _SVDB.OnlyBattleField then
        -- Hide when enter the world
        BFMScrollContainer:Hide()
    end
end

__SystemEvent__()
function PLAYER_ENTERING_BATTLEGROUND()
    _InBattleField              = true
    if BFMScrollContainer and _SVDB.OnlyBattleField then
        -- Show when enter the battleround
        BFMScrollContainer:Show()
        BattlefieldMapFrame:Show()
    end
end

function UpdateUnitsVisibility()
    UpdatePlayerScale()
end

----------------------------------------------
--              Widget Helpers              --
----------------------------------------------
local MapRects                  = {}
function GetPlayerMapPos()
    local mapid                 = BattlefieldMapFrame:GetMapID()
    if not mapid or mapid ~= MapUtil.GetDisplayableMapForPlayer() then return end

    local rects                 = MapRects[mapid]

    if rects == nil then
        local _, topleft        = C_Map.GetWorldPosFromMapPos(mapid, CreateVector2D(0,0))
        local _, bottomright    = C_Map.GetWorldPosFromMapPos(mapid, CreateVector2D(1,1))

        if topleft and bottomright then
            bottomright:Subtract(topleft)
            rects               = { topleft.x, topleft.y, bottomright.x, bottomright.y }
            MapRects[mapid]     = rects
        end
    end

    if not rects then return end

    local x, y                  = UnitPosition("player")
    if not x then return end

    x, y                        = x - rects[1], y - rects[2]

    return y / rects[4], x / rects[3]
end

function AddRestDataProvider(self)
    self:AddDataProvider(CreateFromMixins(WorldMap_EventOverlayDataProviderMixin))
    self:AddDataProvider(CreateFromMixins(StorylineQuestDataProviderMixin))
    self:AddDataProvider(CreateFromMixins(BonusObjectiveDataProviderMixin))
    self:AddDataProvider(CreateFromMixins(QuestBlobDataProviderMixin))
    self:AddDataProvider(CreateFromMixins(QuestDataProviderMixin))
    self:AddDataProvider(CreateFromMixins(InvasionDataProviderMixin))
    self:AddDataProvider(CreateFromMixins(GarrisonPlotDataProviderMixin))
    self:AddDataProvider(CreateFromMixins(BannerDataProvider))
    self:AddDataProvider(CreateFromMixins(ContributionCollectorDataProviderMixin))

    areaLabelDataProvider = CreateFromMixins(AreaLabelDataProviderMixin)
    areaLabelDataProvider:SetOffsetY(-10)
    self:AddDataProvider(areaLabelDataProvider)
    UpdateAreaLabelScale()

    local worldQuestDataProvider= CreateFromMixins(WorldMap_WorldQuestDataProviderMixin)
    worldQuestDataProvider:SetMatchWorldMapFilters(true)
    worldQuestDataProvider:SetUsesSpellEffect(true)
    worldQuestDataProvider:SetCheckBounties(true)
    worldQuestDataProvider:SetMarkActiveQuests(true)
    ORIGIN_AddWorldQuest        = worldQuestDataProvider.AddWorldQuest
    worldQuestDataProvider.AddWorldQuest = AddWorldQuest
    self:AddDataProvider(worldQuestDataProvider)
    _WorldQuestDataProvider     = worldQuestDataProvider

    local pinFrameLevelsManager = self:GetPinFrameLevelsManager()
    pinFrameLevelsManager:AddFrameLevel("PIN_FRAME_LEVEL_GARRISON_PLOT")
    pinFrameLevelsManager:AddFrameLevel("PIN_FRAME_LEVEL_QUEST_BLOB")
    pinFrameLevelsManager:AddFrameLevel("PIN_FRAME_LEVEL_INVASION")
    pinFrameLevelsManager:AddFrameLevel("PIN_FRAME_LEVEL_SELECTABLE_GRAVEYARD")
    pinFrameLevelsManager:AddFrameLevel("PIN_FRAME_LEVEL_CONTRIBUTION_COLLECTOR")
    pinFrameLevelsManager:AddFrameLevel("PIN_FRAME_LEVEL_STORY_LINE")
    pinFrameLevelsManager:AddFrameLevel("PIN_FRAME_LEVEL_WORLD_QUEST_PING")
    pinFrameLevelsManager:AddFrameLevel("PIN_FRAME_LEVEL_WORLD_QUEST", 500)
    pinFrameLevelsManager:AddFrameLevel("PIN_FRAME_LEVEL_ACTIVE_QUEST", C_QuestLog.GetMaxNumQuests())
    pinFrameLevelsManager:AddFrameLevel("PIN_FRAME_LEVEL_SUPER_TRACKED_QUEST")
    pinFrameLevelsManager:AddFrameLevel("PIN_FRAME_LEVEL_BONUS_OBJECTIVE")
    pinFrameLevelsManager:AddFrameLevel("PIN_FRAME_LEVEL_AREA_POI_BANNER")

    pinFrameLevelsManager.definitions.PIN_FRAME_LEVEL_GROUP_MEMBER = nil
    pinFrameLevelsManager:AddFrameLevel("PIN_FRAME_LEVEL_GROUP_MEMBER")

    UpdatePlayerScale()

    local oldAcquirePin         = self.AcquirePin
    self.AcquirePin             = function(self, pinTemplate, ...)
        local pin               = oldAcquirePin(self, pinTemplate, ...)

        if pin then
            FireSystemEvent("EBFM_PIN_ACQUIRED", pinTemplate, pin)
        end

        return pin
    end

    FireSystemEvent("EBFM_DATAPROVIDER_INIT", self)
end

function UpdatePlayerScale()
    BattlefieldMapFrame.groupMembersDataProvider:SetUnitPinSize("player", BATTLEFIELD_MAP_PLAYER_SIZE * _SVDB.PlayerScale)

    if BattlefieldMapOptions.showPlayers then
        BattlefieldMapFrame.groupMembersDataProvider:SetUnitPinSize("party", BATTLEFIELD_MAP_PARTY_MEMBER_SIZE * _SVDB.PartyScale)
        BattlefieldMapFrame.groupMembersDataProvider:SetUnitPinSize("raid", BATTLEFIELD_MAP_RAID_MEMBER_SIZE * _SVDB.RaidScale)
    end
end

function UpdatePlayerPinTexture(self)
    self                        = self or BattlefieldMapFrame.groupMembersDataProvider.pin

    if _SVDB.ReplacePlayerPin then
        self:SetPinTexture("player", PIN_TEXTURE)
        self:SetAppearanceField("player", "useClassColor", _SVDB.UseClassColor)
    else
        self:SetPinTexture("player", ORIGIN_PLAYER_TEXTURE)
        self:SetAppearanceField("player", "useClassColor", false)
    end
end

function UpdatePinTexture(self)
    self                        = self or BattlefieldMapFrame.groupMembersDataProvider.pin

    if _SVDB.ReplacePartyPin then
        self:SetPinTexture("party", PIN_TEXTURE)
    else
        self:SetPinTexture("party", IsInRaid() and "WhiteDotCircle-RaidBlips" or "WhiteCircle-RaidBlips")
    end

    if _SVDB.ReplaceRaidPin then
        self:SetPinTexture("raid", PIN_TEXTURE)
    else
        self:SetPinTexture("raid", "WhiteCircle-RaidBlips")
    end
end

function UpdateClassColor(self)
    self                        = self or BattlefieldMapFrame.groupMembersDataProvider.pin
    if _SVDB.ReplacePlayerPin then
        self:SetAppearanceField("player", "useClassColor", _SVDB.UseClassColor)
    end
    self:SetAppearanceField("party", "useClassColor", _SVDB.UseClassColor)
    self:SetAppearanceField("raid", "useClassColor", _SVDB.UseClassColor)
end

function ReplacePartyPin()
    local pin                   = BattlefieldMapFrame.groupMembersDataProvider.pin
    hooksecurefunc(pin, "UpdateAppearanceData", UpdatePinTexture)
    UpdatePlayerPinTexture()
    UpdatePinTexture()
    UpdateClassColor()

    -- Keep player arrow above party and raid, and keep party member dots above raid dots.
    pin:SetAppearanceField("party", "sublevel", 1)
    pin:SetAppearanceField("raid", "sublevel", 0)
end

function BlockTabFrame()
    if _SVDB.BlockTab then
        BattlefieldMapTab:EnableMouse(false)
        BattlefieldMapTab:Hide()
        BattlefieldMapTab.Show = BattlefieldMapTab.Hide
    else
        BattlefieldMapTab:EnableMouse(true)
        BattlefieldMapTab.Show = nil
        BattlefieldMapTab:Show()
    end
end

__Async__() local _LockOnPlayed = false
function LockOnPlayer(self)
    if _LockOnPlayed then return end

    Next() Next()

    while self:IsVisible() and not self:IsMouseOver() do
        local x, y              = GetPlayerMapPos()

        if x then
            local minX, maxX, minY, maxY = self:CalculateScrollExtentsAtScale(self:GetCanvasScale())
            local cx            = Clamp(x, minX, maxX)
            local cy            = Clamp(y, minY, maxY)
            self:SetPanTarget(cx, cy)

            if _MinimapControlled then
                Minimap:ClearAllPoints()
                Minimap:SetPoint("CENTER", self:DenormalizeHorizontalSize(x - cx) * self:GetCanvasScale(), - self:DenormalizeVerticalSize(y - cy) * self:GetCanvasScale())
                if not Minimap:IsShown() then Minimap:Show() Minimap:SetAlpha(0) end
            end
        end

        Delay(0.2)
    end

    _LockOnPlayed = false
end

function Container_OnShow(self)
    if not self:IsMouseOver() then LockOnPlayer(BFMScrollContainer) end
    ZONE_CHANGED_NEW_AREA()
    TryInitMinimap()
end

function Container_OnHide(self)
    if _IncludeMinimap then
        SendBackMinimap()
    end
end

__Async__()
function Container_OnEnter(self)
    ENTER_TASK_ID   = ENTER_TASK_ID + 1
    local task      = ENTER_TASK_ID

    BattlefieldMapFrame:SetGlobalAlpha(1)
    BattlefieldMapFrameBack:SetAlpha(min(1, _SVDB.BorderColor.a))

    if _SVDB.EnableCoordinate then
        while task == ENTER_TASK_ID and self:IsMouseOver() do
            local x, y  = self:GetCursorPosition()
            x           = self:NormalizeHorizontalSize(x / self:GetCanvasScale() - self.Child:GetLeft())
            y           = self:NormalizeVerticalSize(self.Child:GetTop() - y / self:GetCanvasScale())

            BattlefieldMapFrameCoords:SetText(("(%.2f, %.2f)"):format(x * 100, y * 100))

            Next()
        end
    end

    BattlefieldMapFrameCoords:SetText("")

    local st    = GetTime()
    local tar   = _G.BattlefieldMapOptions.opacity or 0

    while task == ENTER_TASK_ID and not BattlefieldMapFrame:IsMouseOver() do
        local opacity = (GetTime() - st) / 2.0 * tar

        if opacity < tar then
            BattlefieldMapFrame:SetGlobalAlpha(1 - opacity)
            BattlefieldMapFrameBack:SetAlpha(min(1 - opacity, _SVDB.BorderColor.a))
        else
            BattlefieldMapFrame:SetGlobalAlpha(1 - tar)
            BattlefieldMapFrameBack:SetAlpha(min(1 - tar, _SVDB.BorderColor.a))
            LockOnPlayer(BFMScrollContainer)
            break
        end

        Next()
    end
end

function Container_OnMouseDown(self, button)
    if _MinimapControlled then Minimap:Hide() end
end

function Container_OnMouseUp(self, button)
    if button ~= "LeftButton" and button ~= "RightButton" then
        ZONE_CHANGED()
    end
end

function Container_OnMouseWheel(self, delta)
    OriginOnMouseWheel(self, delta)
    _SVDB.CanvasScale   = BFMScrollContainer:GetCanvasScale()
end

function BFMResizer_OnResized(self)
    BattlefieldMapFrame:OnFrameSizeChanged()
    _SVDB.MaskSize      = Size(BattlefieldMapFrame:GetSize())
end

__Async__()
function Minimap_OnEnter(self)
    if _MinimapControlled and BFMScrollContainer:IsVisible() then
        Minimap:SetAlpha(1)
        Minimap:SetPlayerTexture([[Interface\Minimap\MinimapArrow]])

        while Minimap:IsMouseOver() and _MinimapControlled do Next() end
        if not _MinimapControlled then return end

        local now = GetTime()
        local endTime = now + 2

        while now < endTime and not Minimap:IsMouseOver() and _MinimapControlled do
            Minimap:SetAlpha((endTime - now)/2)
            Next()
            now = GetTime()
        end

        if Minimap:IsMouseOver() or not _MinimapControlled then
            Minimap:SetAlpha(1)
            Minimap:SetPlayerTexture([[Interface\Minimap\MinimapArrow]])
        else
            Minimap:SetAlpha(0)
            Minimap:SetPlayerTexture([[]])
        end
    else
        Minimap:SetAlpha(1)
        Minimap:SetPlayerTexture([[Interface\Minimap\MinimapArrow]])
    end
end

function SaveMinimapLocation()
    MinimapLoc = {}
    MinimapParent = Minimap:GetParent()
    MinimapStrata = Minimap:GetFrameStrata()
    MinimapLevel  = Minimap:GetFrameLevel()

    for i = 1, Minimap:GetNumPoints() do
        MinimapLoc[i] = { Minimap:GetPoint(i) }
    end

    if #MinimapLoc == 1 and MinimapLoc[1][2] == MinimapCluster then
        _HideCluster = true
        -- Means origin
        MinimapCluster:Hide()
        MinimapBackdrop:Hide()
    else
        _HideCluster = false
    end

    Minimap:SetParent(BattlefieldMapFrame)
    Minimap:SetFrameStrata("HIGH")
    Minimap:SetFrameLevel(99)
end

function TryInitMinimap()
    if _IncludeMinimap and (BFMScrollContainer:IsVisible() or _SVDB.AlwaysInclude) and not _MinimapControlled then
        _MinimapControlled = true
        _MinimapOriginalSize = Size(Minimap:GetSize())
        Minimap:EnableMouse(not _SVDB.BlockEmbedMap)
        SaveMinimapLocation()
        Minimap:SetSize(_SVDB.MinimapSize, _SVDB.MinimapSize)
        Minimap:SetZoom(Minimap:GetZoom() + 1)
        Minimap:SetZoom(Minimap:GetZoom() - 1)
        Minimap_OnEnter(Minimap)
        if not UnitPosition("player") then
            Minimap:Hide()
        end
    end
end

function SendBackMinimap()
    if _SVDB.AlwaysInclude then return end

    if _MinimapControlled then
        Minimap:EnableMouse(true)
        _MinimapControlled = false
        if _HideCluster then
            MinimapCluster:Show()
        end
        Minimap:Show()
        Minimap:SetParent(MinimapParent)
        Minimap:SetFrameStrata(MinimapStrata)
        Minimap:SetFrameLevel(MinimapLevel)
        Minimap:SetAlpha(1)
        Minimap:SetPlayerTexture([[Interface\Minimap\MinimapArrow]])
        Minimap:ClearAllPoints()
        Minimap:SetSize(_MinimapOriginalSize.width, _MinimapOriginalSize.height)
        for i, v in ipairs(MinimapLoc) do
            Minimap:SetPoint(unpack(v))
        end
        if _HideCluster then
            MinimapBackdrop:Show()
        end
    end
end

function UpdateZoneText()
    BattlefieldZoneText:SetText(GetMinimapZoneText())
    BattlefieldZoneTextFrame:SetWidth(BattlefieldZoneText:GetStringWidth() + 2)

    local pvpType, isSubZonePvP, factionName = GetZonePVPInfo()
    if ( pvpType == "sanctuary" ) then
        BattlefieldZoneText:SetTextColor(0.41, 0.8, 0.94)
    elseif ( pvpType == "arena" ) then
        BattlefieldZoneText:SetTextColor(1.0, 0.1, 0.1)
    elseif ( pvpType == "friendly" ) then
        BattlefieldZoneText:SetTextColor(0.1, 1.0, 0.1)
    elseif ( pvpType == "hostile" ) then
        BattlefieldZoneText:SetTextColor(1.0, 0.1, 0.1)
    elseif ( pvpType == "contested" ) then
        BattlefieldZoneText:SetTextColor(1.0, 0.7, 0.0)
    else
        BattlefieldZoneText:SetTextColor(1, 0.82, 0)
    end

    for pin in BattlefieldMapFrame:EnumeratePinsByTemplate("MapHighlightPinTemplate") do
        if not pin:IsIgnoringGlobalPinScale() then
            pin:SetIgnoreGlobalPinScale(true)
            pin:ApplyCurrentScale()
        end
    end
end

function UpdateAreaLabelScale()
    local name = areaLabelDataProvider.Label.Name
    local description = areaLabelDataProvider.Label.Description

    name:SetIgnoreParentScale(true)
    description:SetIgnoreParentScale(true)

    if not name.originfont then
        name.originfont = { name:GetFont() }
    end

    if not description.originfont then
        description.originfont = { description:GetFont() }
    end

    name:SetFont( name.originfont[1], name.originfont[2] * _SVDB.AreaLabelScale, name.originfont[3])
    description:SetFont( description.originfont[1], description.originfont[2] * _SVDB.AreaLabelScale, description.originfont[3])
end

----------------------------------------------
--    BLIZZARD MEMORY LEAK FIX AND MORE     --
----------------------------------------------
local viewRect  = CreateRectangle(0, 0, 0, 0)

function CalculateViewRect(self, scale)
    local childWidth, childHeight = self.Child:GetSize()
    local left = self:GetHorizontalScroll() / childWidth
    local right = left + (self:GetWidth() / scale) / childWidth
    local top = self:GetVerticalScroll() / childHeight
    local bottom = top + (self:GetHeight() / scale) / childHeight

    viewRect:SetSides(left, right, top, bottom)

    return viewRect
end

function UpdatePinNudging(self)
    if not self.pinNudgingDirty and #self.pinsToNudge == 0 then
        return
    end

    if self.pinNudgingDirty then
        for targetPin in self:EnumerateAllPins() do
            self:CalculatePinNudging(targetPin)
        end
    else
        for _, targetPin in ipairs(self.pinsToNudge) do
            self:CalculatePinNudging(targetPin)
        end
    end

    self.pinNudgingDirty = false
    wipe(self.pinsToNudge)
end

function AddWorldQuest(self, info)
    local pin = ORIGIN_AddWorldQuest(self, info)

    if not pin.RewardRing then
        WORLD_QUEST_PIN_LIST:Insert(pin)

        pin:SetScalingLimits(1, _SVDB.WorldQuestScale, _SVDB.WorldQuestScale)
        pin.RewardRing = pin:CreateTexture("nil", "BACKGROUND", -2)
        pin.RewardRing:SetPoint("TOPLEFT", -4, 4)
        pin.RewardRing:SetPoint("BOTTOMRIGHT", 4, -4)
        pin.RewardRing:SetTexture("Interface/AddOns/EnhanceBattlefieldMinimap/resource/ring.tga")
        pin.RewardRing:Hide()

        pin.RefreshVisuals = RefreshVisuals
    end

    return pin
end

function RefreshVisuals(self)
    local questID = self.questID
    local tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, displayTimeLeft = C_QuestLog.GetQuestTagInfo(questID)
    local selected = questID == C_SuperTrack.GetSuperTrackedQuestID()
    self.Glow:SetShown(selected)
    self.SelectedGlow:SetShown(rarity ~= Enum.WorldQuestQuality.COMMON and selected)

    if rarity == Enum.WorldQuestQuality.COMMON then
        if selected then
            self.Background:SetTexCoord(0.500, 0.625, 0.375, 0.5)
            self.PushedBackground:SetTexCoord(0.375, 0.500, 0.375, 0.5)
        else
            self.Background:SetTexCoord(0.875, 1, 0.375, 0.5)
            self.PushedBackground:SetTexCoord(0.750, 0.875, 0.375, 0.5)
        end
    end

    local bountyQuestID = self.dataProvider:GetBountyQuestID()
    self.BountyRing:SetShown(bountyQuestID and IsQuestCriteriaForBounty(questID, bountyQuestID))

    --if self.dataProvider:IsMarkingActiveQuests() and C_QuestLog.IsOnQuest(questID) then
    --    self.Texture:SetAtlas("worldquest-questmarker-questionmark")
    --    self.Texture:SetSize(20, 30)
    --else
    self.RewardRing:Hide()

    if self.worldQuestType == Enum.QuestTag.PVP then
        local _, width, height = GetAtlasInfo("worldquest-icon-pvp-ffa")
        self.Texture:SetAtlas("worldquest-icon-pvp-ffa")
        self.Texture:SetSize(width * 2, height * 2)
    elseif self.worldQuestType == Enum.QuestTag.PET_BATTLE then
        self.Texture:SetAtlas("worldquest-icon-petbattle")
        self.Texture:SetSize(26, 22)
    elseif self.worldQuestType == Enum.QuestTag.PROFESSION and WORLD_QUEST_ICONS_BY_PROFESSION[tradeskillLineID] then
        local _, width, height = GetAtlasInfo(WORLD_QUEST_ICONS_BY_PROFESSION[tradeskillLineID])
        self.Texture:SetAtlas(WORLD_QUEST_ICONS_BY_PROFESSION[tradeskillLineID])
        self.Texture:SetSize(width * 2, height * 2)
    elseif self.worldQuestType == Enum.QuestTag.DUNGEON then
        local _, width, height = GetAtlasInfo("worldquest-icon-dungeon")
        self.Texture:SetAtlas("worldquest-icon-dungeon")
        self.Texture:SetSize(width * 2, height * 2)
    elseif self.worldQuestType == Enum.QuestTag.RAID then
        local _, width, height = GetAtlasInfo("worldquest-icon-raid")
        self.Texture:SetAtlas("worldquest-icon-raid")
        self.Texture:SetSize(width * 2, height * 2)
    elseif self.worldQuestType == Enum.QuestTag.INVASION then
        local _, width, height = GetAtlasInfo("worldquest-icon-burninglegion")
        self.Texture:SetAtlas("worldquest-icon-burninglegion")
        self.Texture:SetSize(width * 2, height * 2)
    else
        local _, texture, quality, currencyID, width, height, r, g, b
        if ( not HaveQuestRewardData(questID) ) then
            C_TaskQuest.RequestPreloadRewardData(questID)
        else
            local worldQuestRewardType = 0

            if GetNumQuestLogRewards(questID) > 0 then
                _, texture, _, quality = GetQuestLogRewardInfo(1, questID)
                if quality then r, g, b = GetItemQualityColor(quality) end
                width, height = 45, 45
            elseif GetQuestLogRewardMoney(questID) > 0 then
                texture = "Interface/ICONS/INV_Misc_Coin_01"
                r, g, b = 0.85, 0.7, 0
                width, height = 45, 45
            elseif GetNumQuestLogRewardCurrencies(questID) > 0 then
                for i = 1, GetNumQuestLogRewardCurrencies(questID)  do
                    _, texture, _, currencyID = GetQuestLogRewardCurrencyInfo(i, questID)
                    if currencyID == ORDER_RESOURCES_CURRENCY_ID or currencyID == warResourcesCurrencyID or currencyID == azeriteCurrencyID then
                        break
                    end
                end
                r, g, b = 0.6, 0.4, 0.1
                width, height = 45, 45
            end
        end

        if texture then
            self.Texture:SetSize(width, height)
            SetPortraitToTexture(self.Texture, texture)
            self.RewardRing:SetVertexColor(r, g, b)
            self.RewardRing:Show()
        else
            self.Texture:SetAtlas("worldquest-questmarker-questbang")
            self.Texture:SetSize(12, 30)
        end
    end
end

-- Dropdown Menu
function BattlefieldMapTab_OnClick(self, button)
    if button == "RightButton" then
        local options           = {
            -- The original
            {
                text            = SHOW_BATTLEFIELDMINIMAP_PLAYERS,
                check           = {
                    get         = function() return BattlefieldMapOptions.showPlayers end,
                    set         = function(value) BattlefieldMapOptions.showPlayers = value; BattlefieldMapFrame:UpdateUnitsVisibility() end,
                }
            },
            {
                text            = LOCK_BATTLEFIELDMINIMAP,
                check           = {
                    get         = function() return BattlefieldMapOptions.locked end,
                    set         = function(value) BattlefieldMapOptions.locked = value end,
                }
            },
            {
                text            = BATTLEFIELDMINIMAP_OPACITY_LABEL,
                click           = function() BattlefieldMapTab:ShowOpacity() end,
            },
            -- The EBFM Part
            {
                text            = _Locale["Enable Mouse"],
                check           = {
                    get         = function() return not _SVDB.BlockMouse end,
                    set         = function(value) EnableMouseAction(value and "on" or "off") end,
                }
            },
            {
                text            = _Locale["UnLock The Map"],
                check           = {
                    get         = function() return _SVDB.Resizable end,
                    set         = function(value) if value then UnLockMap() else LockMap() end end,
                }
            },
            {
                text            = _Locale["Disable The Tab Frame"],
                check           = {
                    get         = function() return _SVDB.BlockTab end,
                    set         = function(value) BlockMap(value and "on" or "off") end
                }
            },
            {
                text            = _Locale["Show Zone Text"],
                check           = {
                    get         = function() return _SVDB.ShowZoneText end,
                    set         = function(value) ToggleZoneText(value and "on" or "off") end,
                }
            },
            {
                text            = _Locale["Only in Battlefield"],
                check           = {
                    get         = function() return _SVDB.OnlyBattleField end,
                    set         = function(value) ToggleOnlyBattlefield(value and "on" or "off") end,
                },
            },
            {
                text            = _Locale["Enable Mouse Coordinate"],
                check           = {
                    get         = function() return _SVDB.EnableCoordinate end,
                    set         = function(value) ToggleMouseCoordinate(value and "on" or "off") end,
                }
            },
            {
                text            = _Locale["The Frame Strata"],

                submenu         = {
                    check       = {
                        get     = function() return _SVDB.FrameStrata end,
                        set     = function(value) _SVDB.FrameStrata = value; BattlefieldMapFrame:SetFrameStrata(value) end,
                    },

                    {
                        text    = "BACKGROUND",
                        checkvalue = "BACKGROUND",
                    },
                    {
                        text    = "LOW",
                        checkvalue = "LOW",
                    },
                    {
                        text    = "MEDIUM",
                        checkvalue = "MEDIUM",
                    },
                    {
                        text    = "HIGH",
                        checkvalue = "HIGH",
                    },
                    {
                        text    = "DIALOG",
                        checkvalue = "DIALOG",
                    },
                    {
                        text    = "FULLSCREEN",
                        checkvalue = "FULLSCREEN",
                    },
                    {
                        text    = "FULLSCREEN_DIALOG",
                        checkvalue = "FULLSCREEN_DIALOG",
                    },
                }
            },
            {
                text            = _Locale["Pin Texture"],
                submenu         = {

                    {
                        text        = _Locale["Use Class Color"],
                        check       = {
                            get     = function() return _SVDB.UseClassColor end,
                            set     = function(value) _SVDB.UseClassColor = value; UpdateClassColor() end,
                        }
                    },
                    {
                        text        = _Locale["Replace Player Arrow"],
                        check       = {
                            get     = function() return _SVDB.ReplacePlayerPin end,
                            set     = function(value) _SVDB.ReplacePlayerPin = value; UpdatePlayerPinTexture() end,
                        }
                    },
                    {
                        text        = _Locale["Replace Party Member"],
                        check       = {
                            get     = function() return _SVDB.ReplacePartyPin end,
                            set     = function(value) _SVDB.ReplacePartyPin = value; UpdatePinTexture() end,
                        }
                    },
                    {
                        text        = _Locale["Replace Raid Member"],
                        check       = {
                            get     = function() return _SVDB.ReplaceRaidPin end,
                            set     = function(value) _SVDB.ReplaceRaidPin = value; UpdatePinTexture() end,
                        }
                    },
                }
            },
            {
                text            = _Locale["Minimap"],
                submenu         = {
                    {
                        text    = _Locale["Embed Minimap"],
                        submenu = {
                            check       = {
                                get     = function() return _SVDB.AlwaysInclude and 2 or _SVDB.IncludeMinimap and 1 or 0 end,
                                set     = function(value) ToggleIncludeMinimap(value == 2 and "always" or value == 1 and "on" or "off") end,
                            },

                            {
                                text    = _Locale["Off"],
                                checkvalue = 0,
                            },
                            {
                                text    = _Locale["On"],
                                checkvalue = 1,
                            },
                            {
                                text    = _Locale["Always"],
                                checkvalue = 2,
                            },
                        }
                    },
                    {
                        text    = _Locale["Block Minimap Interaction"],
                        check   = {
                            get = function() return _SVDB.BlockEmbedMap end,
                            set = function(value)
                                _SVDB.BlockEmbedMap   = value
                                Minimap:EnableMouse(not (_MinimapControlled and value))
                            end,
                        }
                    },
                    {
                        text    = _Locale["The Minimap Size"] .. " - " .. _SVDB.MinimapSize,
                        click   = function()
                            local scale = PickRange(_Locale["Choose Minimap Scale"], 100, 400, 5, _SVDB.MinimapSize)
                            if not scale then return end

                            _SVDB.MinimapSize = scale
                            if _IncludeMinimap then
                                Minimap:SetSize(_SVDB.MinimapSize, _SVDB.MinimapSize)
                                Minimap:SetZoom(Minimap:GetZoom() + 1)
                                Minimap:SetZoom(Minimap:GetZoom() - 1)
                            end
                        end,
                    }
                }
            },
            {
                text            = _Locale["Player Scale"] .. " - " .. _SVDB.PlayerScale,
                click           = function() SetPlayerScale(PickRange(_Locale["Choose Player Scale"], 0.1, 5, 0.1, _SVDB.PlayerScale)) end,
            },
            {
                text            = _Locale["Party Member Scale"] .. " - " .. _SVDB.PartyScale,
                click           = function() SetPartyScale(PickRange(_Locale["Choose Party Member Scale"], 0.1, 5, 0.1, _SVDB.PartyScale)) end,
            },
            {
                text            = _Locale["Raid Member Scale"] .. " - " .. _SVDB.RaidScale,
                click           = function() SetRaidScale(PickRange(_Locale["Choose Raid Member Scale"], 0.1, 5, 0.1, _SVDB.RaidScale)) end,
            },
            {
                text            = _Locale["Area Label Scale"] .. " - " .. _SVDB.AreaLabelScale,
                click           = function() SetAreaLabelScale(PickRange(_Locale["Choose Area Label Scale"], 0.1, 3, 0.1, _SVDB.AreaLabelScale)) end,
            },
            {
                text            = _Locale["World Quest Scale"] .. " - " .. _SVDB.WorldQuestScale,
                click           = function() SetWorldQuestScale(PickRange(_Locale["Choose World Quest Scale"], 0.1, 3, 0.1, _SVDB.WorldQuestScale)) end,
            },
            {
                text            = _Locale["Border Color"],
                color           = {
                    get         = _SVDB.BorderColor,
                    set         = function(color) SetBorderColor(List{ color.r, color.g, color.b, color.a }:Join(",")) end,
                }
            },
        }
        FireSystemEvent("EBFM_SHOW_MENU", options)
        ShowDropDownMenu(options)
    else
        -- If frame is not locked then allow the frame to be dragged or dropped
        if self:GetButtonState() == "PUSHED" then
            self:StopMovingOrSizing()
        else
            -- If locked don't allow any movement
            if BattlefieldMapOptions.locked then
                return
            else
                self:StartMoving()
            end
        end
    end
end
