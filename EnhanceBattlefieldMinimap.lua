--========================================================--
--                Enhance Battlefield Minimap             --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2018/07/19                             --
--========================================================--

--========================================================--
Scorpio            "EnhanceBattlefieldMinimap"       "2.0.0"
--========================================================--

local OriginOnMouseWheel
local ORIGIN_WIDTH, ORIGIN_HEIGHT
local ORIGIN_AddWorldQuest

local ENTER_TASK_ID = 0

local _IncludeMinimap, _MinimapControlled

export { min = math.min }

WORLD_QUEST_PIN_LIST    = List()

----------------------------------------------
--            Addon Event Handler           --
----------------------------------------------
function OnLoad(self)
    _SVDB = SVManager.SVCharManager("EnhanceBattlefieldMinimap_DB")

    _SVDB:SetDefault {
        -- Display Status
        MaskScale       = 1.0,
        CanvasScale     = 1.0,

        -- Minimap
        IncludeMinimap  = false,
        AlwaysInclude   = false,

        -- Border Color
        BorderColor     = {
            r           = 0,
            g           = 0,
            b           = 0,
            a           = 1,
        },

        -- Zone Text
        ShowZoneText    = true,
        ZoneLocation    = { x = 2, y = -2 },
        ZoneTextScale   = 1.0,

        -- Player Arrow
        PlayerScale     = 1.0,

        -- Area Label Scale
        AreaLabelScale  = 1.0,

        -- World Quest Scale
        WorldQuestScale = 0.5,
    }
end

__Async__()
function OnEnable(self)
    OnEnable            = nil

    _Enabled            = false

    if not IsAddOnLoaded("Blizzard_BattlefieldMap") then
        while NextEvent("ADDON_LOADED") ~= "Blizzard_BattlefieldMap" do end
    end

    ORDER_RESOURCES_CURRENCY_ID = 1220
    azeriteCurrencyID = C_CurrencyInfo.GetAzeriteCurrencyID()
    warResourcesCurrencyID = C_CurrencyInfo.GetWarResourcesCurrencyID()

    BattlefieldMapTab:SetUserPlaced(true)   -- Fix the bug blz won't save location

    BattlefieldMapFrame:SetShouldNavigateOnClick(true)
    BattlefieldMapFrame.UpdatePinNudging = UpdatePinNudging

    ORIGIN_WIDTH        = BattlefieldMapFrame:GetWidth()
    ORIGIN_HEIGHT       = BattlefieldMapFrame:GetHeight()

    BFMScrollContainer  = BattlefieldMapFrame.ScrollContainer
    BFMScrollContainer:HookScript("OnShow", Container_OnShow)
    BFMScrollContainer:HookScript("OnHide", Container_OnHide)
    BFMScrollContainer:HookScript("OnMouseDown", Container_OnMouseDown)
    BFMScrollContainer:HookScript("OnMouseUp", Container_OnMouseUp)
    BFMScrollContainer:HookScript("OnEnter", Container_OnEnter)

    BFMScrollContainer.CalculateViewRect = CalculateViewRect

    OriginOnMouseWheel  = BFMScrollContainer:GetScript("OnMouseWheel")
    BFMScrollContainer:SetScript("OnMouseWheel", Container_OnMouseWheel)
    BattlefieldMapFrame.BorderFrame:Hide()

    BattlefieldMapFrameBack = CreateFrame("Frame", nil, BFMScrollContainer)
    BattlefieldMapFrameBack:SetFrameStrata("HIGH")
    BattlefieldMapFrameBack:SetPoint("TOPLEFT", 0, 0)
    BattlefieldMapFrameBack:SetPoint("BOTTOMRIGHT", 0, 0)
    BattlefieldMapFrameBack:SetBackdrop{ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 }
    BattlefieldMapFrameBack:SetBackdropBorderColor(_SVDB.BorderColor.r, _SVDB.BorderColor.g, _SVDB.BorderColor.b, _SVDB.BorderColor.a)
    BattlefieldMapFrameBack:SetIgnoreParentScale(true)
    BattlefieldMapFrameBack:SetAlpha(min(1 - (_G.BattlefieldMapOptions.opacity or 0), _SVDB.BorderColor.a))

    BattlefieldMapFrameCoordsFrame = CreateFrame("Frame", nil, BFMScrollContainer)
    BattlefieldMapFrameCoordsFrame:SetFrameStrata("HIGH")
    BattlefieldMapFrameCoordsFrame:SetSize(40, 32)
    BattlefieldMapFrameCoordsFrame:SetPoint("TOPRIGHT")
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

        _SVDB.ZoneLocation.x = self:GetLeft() - BFMScrollContainer:GetLeft()
        _SVDB.ZoneLocation.y = self:GetTop() - BFMScrollContainer:GetTop()

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
    BattlefieldMapFrame:SetSize(ORIGIN_WIDTH * _SVDB.MaskScale, ORIGIN_HEIGHT * _SVDB.MaskScale)
    BattlefieldMapFrame:OnFrameSizeChanged()

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
end

__SlashCmd__("ebfm", "reset", _Locale["reset the zone map"])
function resetlocaton()
    BattlefieldMapTab:ClearAllPoints()
    BattlefieldMapTab:SetPoint("TOPLEFT", 100, -100)

    UpdatePlayerScale()

    _SVDB.MaskScale     = 1
    BattlefieldMapFrame:SetSize(ORIGIN_WIDTH * _SVDB.MaskScale, ORIGIN_HEIGHT * _SVDB.MaskScale)
    BattlefieldMapFrame:OnFrameSizeChanged()
end

__SlashCmd__("ebfm", "incminimap", _Locale["on/off/always - take control of the minimap"])
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
    BattlefieldMapFrameBack:SetBackdropBorderColor(_SVDB.BorderColor.r, _SVDB.BorderColor.g, _SVDB.BorderColor.b, _SVDB.BorderColor.a)
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

__SlashCmd__("ebfm", "arealabel", _Locale["[0.1-4] - set the scale of the area labels"])
function SetAreaLabelScale(opt)
    _SVDB.AreaLabelScale = Clamp(tonumber(opt) or 0, 0.1, 4)
    UpdateAreaLabelScale()
end

__SlashCmd__("ebfm", "worldquest", _Locale["[0.1-2] - set the scale of the world quest icon, default 0.5"])
function SetWorldQuestScale(opt)
    opt                         = Clamp(tonumber(opt) or 0, 0.1, 2)
    _SVDB.WorldQuestScale       = opt

    for _, pin in WORLD_QUEST_PIN_LIST:GetIterator() do
        pin:SetScalingLimits(1, opt, opt)
        pin:SetScale(opt)
    end
end

----------------------------------------------
--               System Event               --
----------------------------------------------
__SystemEvent__()
function PLAYER_STARTED_MOVING()
    ZONE_CHANGED()
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

    if not rects then
        local _, topleft        = C_Map.GetWorldPosFromMapPos(mapid, CreateVector2D(0,0))
        local _, bottomright    = C_Map.GetWorldPosFromMapPos(mapid, CreateVector2D(1,1))

        bottomright:Subtract(topleft)
        rects                   = { topleft.x, topleft.y, bottomright.x, bottomright.y }
        MapRects[mapid]         = rects
    end

    local x, y                  = UnitPosition("player")
    if not x then return end

    x, y                        = x - rects[1], y - rects[2]

    return y / rects[4], x / rects[3]
end

function AddRestDataProvider(self)
    self:AddDataProvider(CreateFromMixins(WorldMap_InvasionDataProviderMixin))
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
    FireSystemEvent("EBFM_DATAPROVIDER_INIT", self)
end

function UpdatePlayerScale()
    BattlefieldMapFrame.groupMembersDataProvider:SetUnitPinSize("player", BATTLEFIELD_MAP_PLAYER_SIZE * _SVDB.PlayerScale)

    if BattlefieldMapOptions.showPlayers then
        BattlefieldMapFrame.groupMembersDataProvider:SetUnitPinSize("party", BATTLEFIELD_MAP_PARTY_MEMBER_SIZE * _SVDB.PlayerScale)
        BattlefieldMapFrame.groupMembersDataProvider:SetUnitPinSize("raid", BATTLEFIELD_MAP_RAID_MEMBER_SIZE * _SVDB.PlayerScale)
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

    while task == ENTER_TASK_ID and self:IsMouseOver() do
        local x, y  = self:GetCursorPosition()
        x           = self:NormalizeHorizontalSize(x / self:GetCanvasScale() - self.Child:GetLeft())
        y           = self:NormalizeVerticalSize(self.Child:GetTop() - y / self:GetCanvasScale())

        BattlefieldMapFrameCoords:SetText(("(%.2f, %.2f)"):format(x * 100, y * 100))

        Next()
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
    if IsAltKeyDown() then
        _SVDB.MaskScale     = max(0.3, _SVDB.MaskScale + delta * 0.05)
        BattlefieldMapFrame:SetSize(ORIGIN_WIDTH * _SVDB.MaskScale, ORIGIN_HEIGHT * _SVDB.MaskScale)
        return BattlefieldMapFrame:OnFrameSizeChanged()
    else
        OriginOnMouseWheel(self, delta)
        _SVDB.CanvasScale   = BFMScrollContainer:GetCanvasScale()
    end
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
        SaveMinimapLocation()
        Minimap_OnEnter(Minimap)
        if not UnitPosition("player") then
            Minimap:Hide()
        end
    end
end

function SendBackMinimap()
    if _SVDB.AlwaysInclude then return end

    if _MinimapControlled then
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
    local tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, displayTimeLeft = GetQuestTagInfo(questID)
    local selected = questID == GetSuperTrackedQuestID()
    self.Glow:SetShown(selected)
    self.SelectedGlow:SetShown(rarity ~= LE_WORLD_QUEST_QUALITY_COMMON and selected)

    if rarity == LE_WORLD_QUEST_QUALITY_COMMON then
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

    if self.worldQuestType == LE_QUEST_TAG_TYPE_PVP then
        local _, width, height = GetAtlasInfo("worldquest-icon-pvp-ffa")
        self.Texture:SetAtlas("worldquest-icon-pvp-ffa")
        self.Texture:SetSize(width * 2, height * 2)
    elseif self.worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE then
        self.Texture:SetAtlas("worldquest-icon-petbattle")
        self.Texture:SetSize(26, 22)
    elseif self.worldQuestType == LE_QUEST_TAG_TYPE_PROFESSION and WORLD_QUEST_ICONS_BY_PROFESSION[tradeskillLineID] then
        local _, width, height = GetAtlasInfo(WORLD_QUEST_ICONS_BY_PROFESSION[tradeskillLineID])
        self.Texture:SetAtlas(WORLD_QUEST_ICONS_BY_PROFESSION[tradeskillLineID])
        self.Texture:SetSize(width * 2, height * 2)
    elseif self.worldQuestType == LE_QUEST_TAG_TYPE_DUNGEON then
        local _, width, height = GetAtlasInfo("worldquest-icon-dungeon")
        self.Texture:SetAtlas("worldquest-icon-dungeon")
        self.Texture:SetSize(width * 2, height * 2)
    elseif self.worldQuestType == LE_QUEST_TAG_TYPE_RAID then
        local _, width, height = GetAtlasInfo("worldquest-icon-raid")
        self.Texture:SetAtlas("worldquest-icon-raid")
        self.Texture:SetSize(width * 2, height * 2)
    elseif self.worldQuestType == LE_QUEST_TAG_TYPE_INVASION then
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