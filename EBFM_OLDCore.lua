--========================================================--
--                Enhance Battlefield Minimap             --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2017/03/04                              --
--========================================================--

--========================================================--
Scorpio            "EnhanceBattlefieldMinimap"       "1.1.1"
--========================================================--

max                     = math.max
min                     = math.min
abs                     = math.abs

BattlefieldMinimapPOI   = false

MOVE_MINIMAP_THREADIDX  = 0
ENTER_TASK_ID           = 0
HiddenTime              = 0
MOUSEDOWN_TIME          = 0

EBFM_INITED_LOADED      = false

DRUID_TRAVEL_STANCE     = 783
DRUID_TRAVEL_INDEX      = false

----------------------------------------------
-------------- Addon Event Handler -----------
----------------------------------------------
function OnLoad(self)
    _SVDB = SVManager.SVCharManager("EnhanceBattlefieldMinimap_DB")

    _SVDB:SetDefault {
        -- Display Status
        MaskScale       = 1.0,
        MinimapScale    = 1.0,
        UnitScale       = 1.0,
        VerticalScroll  = 0,
        HorizontalScroll= 0,
        HiddenWhenQuit  = false,
        Opacity         = false,

        -- Settings
        HideInCombat    = true,
        LockOnPlayer    = true,
        ScaleModifier   = 1.0,
        HideDismount    = false,
        HideInDungeon   = false,

        -- Minimap
        IncludeMinimap  = false,
        AlwaysInclude   = false,

        -- Border Color
        BorderColor     = {
            r           = 0,
            g           = 0,
            b           = 0,
            a           = 1,
        }
    }
end

__Async__()
function OnEnable(self)
    if not IsAddOnLoaded("Blizzard_BattlefieldMinimap") and not _SVDB.HiddenWhenQuit then
        BattlefieldMinimap_LoadUI()
    end

    if not IsAddOnLoaded("Blizzard_BattlefieldMinimap") then
        while NextEvent("ADDON_LOADED") ~= "Blizzard_BattlefieldMinimap" do end
    end

    -- Modify the BattlefieldMinimap
    BattlefieldMinimapBackground:Hide()
    BattlefieldMinimapCloseButton:Hide()
    BattlefieldMinimapCorner:Hide()

    BattlefieldMinimapTab:SetFrameStrata("HIGH")
    BattlefieldMinimapTabLeft:SetTexture(nil)
    BattlefieldMinimapTabMiddle:SetTexture(nil)
    BattlefieldMinimapTabRight:SetTexture(nil)
    BattlefieldMinimapTabText:Hide()

    BattlefieldMinimap:EnableMouseWheel(true)
    BattlefieldMinimap:SetMovable(true)

    -- Fix the BattlefieldMinimap's w/h ratio
    local worldMapWidth, worldMapHeight = WorldMapDetailFrame:GetSize()
    local tileSize = BattlefieldMinimap1:GetWidth()
    local worldTileSize = WorldMapDetailTile1:GetWidth()

    BattlefieldMinimap:SetSize(worldMapWidth / worldTileSize * tileSize, worldMapHeight / worldTileSize * tileSize)

    BattlefieldMinimapScroll = CreateFrame("ScrollFrame", "BattlefieldMinimapScroll", UIParent)
    BattlefieldMinimapScroll:SetFrameStrata("BACKGROUND")

    for i = 1, BattlefieldMinimap:GetNumPoints() do
        BattlefieldMinimapScroll:SetPoint(BattlefieldMinimap:GetPoint(i))
    end

    ORIGIN_WIDTH, ORIGIN_HEIGHT = BattlefieldMinimap:GetSize()

    BattlefieldMinimapScroll:SetSize(ORIGIN_WIDTH * _SVDB.MaskScale, ORIGIN_HEIGHT * _SVDB.MaskScale)
    BattlefieldMinimapScroll:SetScrollChild(BattlefieldMinimap)
    BattlefieldMinimapScrollBack = CreateFrame("Frame", nil, BattlefieldMinimapScroll)
    BattlefieldMinimapScrollBack:SetFrameStrata("BACKGROUND")
    BattlefieldMinimapScrollBack:SetFrameLevel(BattlefieldMinimapScroll:GetFrameLevel() - 1)
    BattlefieldMinimapScrollBack:SetPoint("TOPLEFT", -2, 2)
    BattlefieldMinimapScrollBack:SetPoint("BOTTOMRIGHT", 2, -2)
    BattlefieldMinimapScrollBack:SetBackdrop{
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    }
    BattlefieldMinimapScrollBack:SetBackdropBorderColor(_SVDB.BorderColor.r, _SVDB.BorderColor.g, _SVDB.BorderColor.b, _SVDB.BorderColor.a)

    BattlefieldMinimap:ClearAllPoints()
    BattlefieldMinimap:SetPoint("TOPLEFT", BattlefieldMinimapScroll, "TOPLEFT")
    BattlefieldMinimap:SetScale(_SVDB.MinimapScale)

    BattlefieldMinimapScroll:UpdateScrollChildRect()
    BattlefieldMinimapScroll:SetVerticalScroll(_SVDB.VerticalScroll)
    BattlefieldMinimapScroll:SetHorizontalScroll(_SVDB.HorizontalScroll)

    UpdateHitRectInsets()

    BattlefieldMinimap:HookScript("OnMouseWheel", OnMouseWheel)
    BattlefieldMinimap:HookScript("OnMouseDown", OnMouseDown)
    BattlefieldMinimap:HookScript("OnMouseUp", OnMouseUp)
    BattlefieldMinimap:HookScript("OnShow", OnShow)
    -- BattlefieldMinimap:HookScript("OnHide", OnHide)
    BattlefieldMinimap:HookScript("OnEnter", OnEnter)
    BattlefieldMinimapTab:HookScript("OnEnter", TabOnEnter)
    BattlefieldMinimapTab:HookScript("OnLeave", TabOnLeave)

    -- Fix taint error
    BattlefieldMinimap:SetScript("OnHide", OnHide)

    if BattlefieldMinimap:IsShown() then
        BattlefieldMinimapScrollBack:Show()
    else
        BattlefieldMinimapScrollBack:Hide()
    end

    -- Don't change scale, it'd blink
    BattlefieldMinimapUnitPositionFrame:SetFrameStrata("High")

    -- Hide the origin POI
    local index = 1
    while _G["BattlefieldMinimapPOI"..index] do
        _G["BattlefieldMinimapPOI"..index]:SetAlpha(0)
        index = index + 1
    end

    if not _SVDB.HiddenWhenQuit then BattlefieldMinimap:Show() end

    -- World Map POI
    BattlefieldMinimapPOI = CreateFrame("Frame", "BattlefieldMinimapPOIFrame", BattlefieldMinimap)
    BattlefieldMinimapPOI:SetAllPoints()
    BattlefieldMinimapPOI:SetScale(_SVDB.ScaleModifier / BattlefieldMinimap:GetScale())

    UpdateUnitPositionFrame()

    -- Coords
    BattlefieldMinimapCoords = BattlefieldMinimapScroll:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    BattlefieldMinimapCoords:SetPoint("BOTTOMRIGHT", BattlefieldMinimapScroll, "TOPRIGHT", 0, 2)

    -- Area Label
    AreaLabel = BattlefieldMinimap:CreateFontString(nil, "OVERLAY", "WorldMapTextFont")
    AreaLabel:SetPoint("TOP", BattlefieldMinimapScroll, "TOP", 0, -4)
    _AreaLabelFont, _, _AreaLabelFlags = WorldMapTextFont:GetFont()
    AreaLabel:SetFont(_AreaLabelFont, 16 / BattlefieldMinimap:GetScale(), _AreaLabelFlags)
    AreaLabel:SetTextColor(WorldMapTextFont:GetTextColor())

    AreaDescription = BattlefieldMinimap:CreateFontString(nil, "OVERLAY", "SubZoneTextFont")
    AreaDescription:SetPoint("TOP", AreaLabel, "BOTTOM", 0, -4)
    _ADFont, _, _ADFlags = SubZoneTextFont:GetFont()
    AreaDescription:SetFont(_ADFont, 12 / BattlefieldMinimap:GetScale(), _ADFlags)
    AreaDescription:SetTextColor(SubZoneTextFont:GetTextColor())

    AreaPetLevels = BattlefieldMinimap:CreateFontString(nil, "OVERLAY", "SubZoneTextFont")
    AreaPetLevels:SetPoint("TOP", AreaLabel, "BOTTOM", 0, -4)
    AreaPetLevels:SetFont(_ADFont, 12 / BattlefieldMinimap:GetScale(), _ADFlags)
    AreaPetLevels:SetTextColor(SubZoneTextFont:GetTextColor())

    -- Highlight
    WorldMapHighlight = BattlefieldMinimap:CreateTexture(nil, "OVERLAY")
    WorldMapHighlight:SetBlendMode("ADD")
    WorldMapHighlight:Hide()

    FireSystemEvent("EBFM_INITED")
    EBFM_INITED_LOADED = true

    Minimap:HookScript("OnEnter", Minimap_OnEnter)
    RefreshLandmarks()

    _IncludeMinimap = _SVDB.IncludeMinimap
    _MinimapControlled = false

    if _SVDB.LockOnPlayer and BattlefieldMinimap:IsVisible() then
        LockOnPlayer()

        TryInitMinimap()
    end

    ScanDruidTravelForm()

    if _SVDB.HideDismount then self:RegisterEvent("UNIT_AURA") PLAYER_ONMOUNT = IsMounted() or false self:SecureHook("TakeTaxiNode") end
    if _SVDB.HideInCombat then self:RegisterEvent("PLAYER_REGEN_ENABLED") self:RegisterEvent("PLAYER_REGEN_DISABLED") end
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    tryHide()

    OnEnter(BattlefieldMinimap)
end

function OnQuit(self)
    if BattlefieldMinimapPOI then
        -- Save settings
        _SVDB.MaskScale         = BattlefieldMinimapScroll:GetWidth() / ORIGIN_WIDTH
        _SVDB.MinimapScale      = BattlefieldMinimap:GetScale()
        _SVDB.HorizontalScroll  = BattlefieldMinimapScroll:GetHorizontalScroll()
        _SVDB.VerticalScroll    = BattlefieldMinimapScroll:GetVerticalScroll()
        _SVDB.HiddenWhenQuit    = not BattlefieldMinimap:IsShown()
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
    BattlefieldMinimapScrollBack:SetBackdropBorderColor(_SVDB.BorderColor.r, _SVDB.BorderColor.g, _SVDB.BorderColor.b, _SVDB.BorderColor.a)
end

__SlashCmd__("ebfm", "nodismount", _Locale["on/off - hide when dismount"])
function ToggleDismount(opt)
    if opt == "on" then
        _SVDB.HideDismount = true
        _M:RegisterEvent("UNIT_AURA")
        _M:SecureHook("TakeTaxiNode")
        tryHide()
    elseif opt == "off" then
        _SVDB.HideDismount = false
        _M:UnregisterEvent("UNIT_AURA")
        _M:SecureUnHook("TakeTaxiNode")
        tryShow()
    else
        return false
    end
end

__SlashCmd__("ebfm", "nocombat", _Locale["on/off - hide during combat"])
function ToggleNoCombat(opt)
    if opt == "on" then
        _SVDB.HideInCombat = true
        _M:RegisterEvent("PLAYER_REGEN_ENABLED")
        _M:RegisterEvent("PLAYER_REGEN_DISABLED")
        tryHide()
    elseif opt == "off" then
        _SVDB.HideInCombat = false
        _M:UnregisterEvent("PLAYER_REGEN_ENABLED")
        _M:UnregisterEvent("PLAYER_REGEN_DISABLED")
        tryShow()
    else
        return false
    end
end

__SlashCmd__("ebfm", "nodungeon", _Locale["on/off - hide in dungeon(can't get location)"])
function ToggleNoDungeon(opt)
    if opt == "on" then
        _SVDB.HideInDungeon = true
        tryHide()
    elseif opt == "off" then
        _SVDB.HideInDungeon = false
        tryShow()
    else
        return false
    end
end

__SlashCmd__("ebfm", "lockplayer", _Locale["on/off - lock on the player"])
function ToggleLockPlayer(opt)
    if opt == "on" then
        if not _SVDB.LockOnPlayer then
            _SVDB.LockOnPlayer = true
            if BattlefieldMinimap:IsVisible() and not BattlefieldMinimapScroll:IsMouseOver() then
                return LockOnPlayer()
            end
        end
    elseif opt == "off" then
        _SVDB.LockOnPlayer = false
    else
        return false
    end
end

__SlashCmd__("ebfm", "scale", _Locale["1.0 - the scale modifier (0.1-10)"])
function ToggleScaleModifier(scale)
    scale = tonumber(scale)
    if scale and scale >= 0.1 and scale <= 10 then
        _SVDB.ScaleModifier = scale

        BattlefieldMinimapPOI:SetScale(_SVDB.ScaleModifier / BattlefieldMinimap:GetScale())

        UpdateUnitPositionFrame()
        RefreshLandmarks(true)
        UpdateHitRectInsets()
    else
        return false
    end
end

__SlashCmd__("ebfm", "unit", _Locale["1.0 - the scale modifier (0.1-10)"])
function ToggleUnitScaleModifier(scale)
    scale = tonumber(scale)
    if scale and scale >= 0.1 and scale <= 10 then
        _SVDB.UnitScale = scale
        UpdateUnitPositionFrame()
    else
        return false
    end
end

__SlashCmd__("ebfm", "opacity", _Locale["[0-1]/off - The opacity of the Battlefield minimap"])
function ToggleOpacity(opt)
    if tonumber(opt) then
        opt = tonumber(opt)
        if opt >= 0 and opt <= 1 then
            _SVDB.Opacity = opt
            OnEnter(BattlefieldMinimap)
        else
            return false
        end
    elseif opt == "off" then
        _SVDB.Opacity = false
        OnEnter(BattlefieldMinimap)
    else
        return false
    end
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

        if _IncludeMinimap and not BattlefieldMinimap:IsVisible() then
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

__AddonSecureHook__ "Blizzard_BattlefieldMinimap"
function BattlefieldMinimapTabDropDown_ShowOpacity()
    OpacityFrame:ClearAllPoints()
    OpacityFrame:SetPoint("TOPRIGHT", BattlefieldMinimapScroll, "TOPLEFT", 0, 7)
end

__AddonSecureHook__ "Blizzard_BattlefieldMinimap"
function BattlefieldMinimap_CreatePOI(index)
    _G["BattlefieldMinimapPOI"..index]:SetAlpha(0)
end

function PLAYER_REGEN_ENABLED()
    tryShow()
end

__Async__()
function PLAYER_ENTERING_WORLD()
    for i = 1, 10 do
        Delay(0.1)
        if GetPlayerMapPosition("player") then
            if _SVDB.HideInDungeon then
                tryShow()
            end
            if _MinimapControlled then
                Minimap:Show()
                Minimap:SetFrameStrata("HIGH")
            end
        else
            if _SVDB.HideInDungeon then
                tryHide()
            elseif _MinimapControlled then
                Minimap:Hide()
            end
        end
    end
end

function PLAYER_REGEN_DISABLED()
    tryHide()
end

__Async__()
function TakeTaxiNode()
    Next()
    tryShow()
end

__SystemEvent__ "SPELLS_CHANGED" "UPDATE_SHAPESHIFT_FORMS"
function ScanDruidTravelForm()
    DRUID_TRAVEL_INDEX = false

    for i = 1, GetNumShapeshiftForms() do
        local id = select(5, GetShapeshiftFormInfo(i))
        if id == DRUID_TRAVEL_STANCE then
            DRUID_TRAVEL_INDEX = i
            break
        end
    end
end

function UNIT_AURA(unit)
    if unit == "player" then
        if IsMounted() or (DRUID_TRAVEL_INDEX and select(3, GetShapeshiftFormInfo(DRUID_TRAVEL_INDEX))) then
            if not PLAYER_ONMOUNT then
                PLAYER_ONMOUNT = true
                tryShow()
            end
        elseif PLAYER_ONMOUNT then
            PLAYER_ONMOUNT = false
            tryHide()
        end
    end
end

_RequireRefreshLandmarks = false

__SystemEvent__ "WORLD_MAP_UPDATE"
    "REQUEST_CEMETERY_LIST_RESPONSE"
    "RESEARCH_ARTIFACT_DIG_SITE_UPDATED"
    "SUPER_TRACKED_QUEST_CHANGED"
    "QUESTLINE_UPDATE"
    "QUEST_LOG_UPDATE"
    "WORLD_QUEST_COMPLETED_BY_SPELL"
    "MINIMAP_UPDATE_TRACKING"
function RefreshLandmarks(instant)
    if not BattlefieldMinimapPOI then return end
    if instant then
        FireSystemEvent("EBFM_REFRESH")
        UpdateHitRectInsets()
    elseif not _RequireRefreshLandmarks then
        _RequireRefreshLandmarks = true
        Next(DoRefreshLandmarks)
    end
end

function DoRefreshLandmarks()
    _RequireRefreshLandmarks = false
    FireSystemEvent("EBFM_REFRESH")
    UpdateHitRectInsets()
end

__SecureHook__()
function WorldStateFrame_ToggleBattlefieldMinimap()
    -- Re-show the minimap if blz closed it
    if abs(GetTime() - HiddenTime) < 0.1 then
        BattlefieldMinimap:Show()
    end
end

__SystemEvent__()
function PLAYER_STARTED_MOVING()
    if BattlefieldMinimapScroll and _SVDB.LockOnPlayer and not BattlefieldMinimapScroll:IsMouseOver() and BattlefieldMinimapScroll:IsVisible() and BattlefieldMinimap:IsVisible() then
       return LockOnPlayer()
    end
end

__SystemEvent__()
function EBFM_MOUSE_OVER(cx, cy)
    BattlefieldMinimapCoords:SetText(("(%.2f, %.2f)"):format(cx * 100, cy * 100))

    local name, fileName, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY, minLevel, maxLevel, petMinLevel, petMaxLevel = HJUpdateMapHighlight( cx, cy )

    local effectiveAreaName = name
    WorldMapFrame_ClearAreaLabel(WORLDMAP_AREA_LABEL_TYPE.AREA_NAME)

    if (name and minLevel and maxLevel and minLevel > 0 and maxLevel > 0) then
        local playerLevel = UnitLevel("player")
        local color
        if (playerLevel < minLevel) then
            color = GetQuestDifficultyColor(minLevel)
        elseif (playerLevel > maxLevel) then
            --subtract 2 from the maxLevel so zones entirely below the player's level won't be yellow
            color = GetQuestDifficultyColor(maxLevel - 2)
        else
            color = QuestDifficultyColors["difficult"]
        end
        color = ConvertRGBtoColorString(color)
        if (minLevel ~= maxLevel) then
            effectiveAreaName = effectiveAreaName..color.." ("..minLevel.."-"..maxLevel..")"..FONT_COLOR_CODE_CLOSE
        else
            effectiveAreaName = effectiveAreaName..color.." ("..maxLevel..")"..FONT_COLOR_CODE_CLOSE
        end
    end

    if effectiveAreaName then WorldMapFrame_SetAreaLabel(WORLDMAP_AREA_LABEL_TYPE.AREA_NAME, effectiveAreaName) end
    WorldMapFrame_EvaluateAreaLabels()

    AreaPetLevels:SetText("")

    local _, _, _, _, locked = C_PetJournal.GetPetLoadOutInfo(1)
    if not locked then
        if (petMinLevel and petMaxLevel and petMinLevel > 0 and petMaxLevel > 0) then
            local teamLevel = C_PetJournal.GetPetTeamAverageLevel()
            local color
            if (teamLevel) then
                if (teamLevel < petMinLevel) then
                    --add 2 to the min level because it's really hard to fight higher level pets
                    color = GetRelativeDifficultyColor(teamLevel, petMinLevel + 2)
                elseif (teamLevel > petMaxLevel) then
                    color = GetRelativeDifficultyColor(teamLevel, petMaxLevel)
                else
                    --if your team is in the level range, no need to call the function, just make it yellow
                    color = QuestDifficultyColors["difficult"]
                end
            else
                --If you unlocked pet battles but have no team, level ranges are meaningless so make them grey
                color = QuestDifficultyColors["header"]
            end
            color = ConvertRGBtoColorString(color)
            if (petMinLevel ~= petMaxLevel) then
                AreaPetLevels:SetText(WORLD_MAP_WILDBATTLEPET_LEVEL..color.."("..petMinLevel.."-"..petMaxLevel..")"..FONT_COLOR_CODE_CLOSE)
            else
                AreaPetLevels:SetText(WORLD_MAP_WILDBATTLEPET_LEVEL..color.."("..petMaxLevel..")"..FONT_COLOR_CODE_CLOSE)
            end
        end
    end

    if ( fileName ) then
        local width, height = BattlefieldMinimap:GetSize()

        WorldMapHighlight:SetTexCoord(0, texPercentageX, 0, texPercentageY)
        if fileName:match("^>") then
            WorldMapHighlight:SetBlendMode("ADD")
            WorldMapHighlight:SetAtlas(fileName:sub(2, -1))
        elseif fileName:match("^Cosmic") then
            WorldMapHighlight:SetBlendMode("BLEND")
            WorldMapHighlight:SetTexture("Interface\\WorldMap\\Cosmic\\"..fileName.."-Highlight")
        else
            WorldMapHighlight:SetBlendMode("ADD")
            WorldMapHighlight:SetTexture("Interface\\WorldMap\\"..fileName.."\\"..fileName.."Highlight")
        end
        textureX = textureX * width
        textureY = textureY * height
        scrollChildX = scrollChildX * width
        scrollChildY = -scrollChildY * height
        if ( (textureX > 0) and (textureY > 0) ) then
            WorldMapHighlight:SetWidth(textureX)
            WorldMapHighlight:SetHeight(textureY)
            WorldMapHighlight:SetPoint("TOPLEFT", "BattlefieldMinimap", "TOPLEFT", scrollChildX, scrollChildY)
            WorldMapHighlight:Show()
        end
    else
        WorldMapHighlight:Hide()
    end
end

__SystemEvent__()
function EBFM_MOUSE_OFF()
    WorldMapFrame_ClearAreaLabel(WORLDMAP_AREA_LABEL_TYPE.AREA_NAME)
    WorldMapFrame_EvaluateAreaLabels()
    AreaPetLevels:SetText("")
end

__SecureHook__(WorldMapFrameAreaLabel, "SetText")
function WorldMapFrameAreaLabel_SetText(self, text)
    if EBFM_INITED_LOADED then return AreaLabel:SetText(text) end
end

__SecureHook__(WorldMapFrameAreaLabel, "SetVertexColor")
function WorldMapFrameAreaLabel_SetVertexColor(self, ...)
    if EBFM_INITED_LOADED then return AreaLabel:SetVertexColor(...) end
end

__SecureHook__(WorldMapFrameAreaDescription, "SetText")
function WorldMapFrameAreaDescription_SetText(self, text)
    if EBFM_INITED_LOADED then return AreaDescription:SetText(text) end
end

__SecureHook__(WorldMapFrameAreaDescription, "SetVertexColor")
function WorldMapFrameAreaDescription_SetVertexColor(self, ...)
    if EBFM_INITED_LOADED then return AreaDescription:SetVertexColor(...) end
end

----------------------------------------------
----------------- Addon Helpers --------------
----------------------------------------------
function OnShow(self)
    BattlefieldMinimapScrollBack:Show()
    if _SVDB.LockOnPlayer and not BattlefieldMinimapScroll:IsMouseOver() then
        LockOnPlayer()
        TryInitMinimap()
    end
    RefreshLandmarks(true)
end

__Async__()
function OnHide(self)
    BattlefieldMinimapScrollBack:Hide()
    HiddenTime = GetTime()

    Delay(0.2)

    if _IncludeMinimap and not self:IsVisible() then
        SendBackMinimap()
    end
end

__Async__()
function OnEnter(self)
    ENTER_TASK_ID = ENTER_TASK_ID + 1

    local task = ENTER_TASK_ID

    TabOnEnter()
    UpdateOpacity(0)

    -- Scan the coords
    while task == ENTER_TASK_ID and BattlefieldMinimapScroll:IsMouseOver() do
        local ox, oy = BattlefieldMinimapScroll:GetHorizontalScroll(), BattlefieldMinimapScroll:GetVerticalScroll()
        local cx, cy = GetCursorPosition()
        local rscale = (WorldMapFrame_InWindowedMode() and UIParent or WorldMapFrame):GetScale()
        local scale = BattlefieldMinimap:GetScale()

        cx = (cx / rscale - BattlefieldMinimapScroll:GetLeft()) / scale + ox
        cy = (BattlefieldMinimapScroll:GetTop() - cy / rscale) / scale + oy

        FireSystemEvent("EBFM_MOUSE_OVER", cx / BattlefieldMinimap:GetWidth(), cy / BattlefieldMinimap:GetHeight())

        Next()
    end

    FireSystemEvent("EBFM_MOUSE_OFF")

    tryHide()

    if task == ENTER_TASK_ID then
        BattlefieldMinimapCoords:SetText("")

        if _SVDB.LockOnPlayer then LockOnPlayer() end
        TabOnLeave()

        if _SVDB.Opacity then
            BattlefieldMinimapOptions.opacity = _SVDB.Opacity
        end

        local tar = BattlefieldMinimapOptions.opacity or 0
        if tar == 0 then return end

        if not (BattlefieldMinimapScroll:IsVisible() and BattlefieldMinimap:IsVisible()) then
            UpdateOpacity(tar)
            return
        end

        local st = GetTime()

        while task == ENTER_TASK_ID and not BattlefieldMinimapScroll:IsMouseOver() do
            local opacity = (GetTime() - st) / 2.0 * tar

            if opacity < tar then
                UpdateOpacity(opacity)
            else
                UpdateOpacity(tar)
                break
            end

            Next()
        end
    end
end

__Async__()
function OnMouseDown(self, button)
    if _MinimapControlled then Minimap:Hide() end

    if button == "LeftButton" then
        MOUSEDOWN_TIME = GetTime()

        MOVE_MINIMAP_THREADIDX = MOVE_MINIMAP_THREADIDX + 1
        local task = MOVE_MINIMAP_THREADIDX

        local scale  = BattlefieldMinimap:GetScale()
        local rx, ry = max(BattlefieldMinimap:GetWidth() - BattlefieldMinimapScroll:GetWidth() / scale, 0), max(BattlefieldMinimap:GetHeight() - BattlefieldMinimapScroll:GetHeight() / scale, 0)
        local sx, sy = BattlefieldMinimapScroll:GetHorizontalScroll(), BattlefieldMinimapScroll:GetVerticalScroll()
        local cx, cy = GetCursorPosition()

        while task == MOVE_MINIMAP_THREADIDX do
            Next()

            local x, y = GetCursorPosition()

            x = max(0, min(sx - (x - cx) / scale, rx))
            y = max(0, min(sy + (y - cy) / scale, ry))

            BattlefieldMinimapScroll:SetHorizontalScroll(x)
            BattlefieldMinimapScroll:SetVerticalScroll(y)

            UpdateHitRectInsets()
        end
    end
end

__Async__()
function OnMouseUp(self, button)
    if button == "LeftButton" then
        -- Stop the OnMouseDown thread
        MOVE_MINIMAP_THREADIDX = MOVE_MINIMAP_THREADIDX + 1

        if GetTime() - MOUSEDOWN_TIME < 0.3 then
            local ox, oy = BattlefieldMinimapScroll:GetHorizontalScroll(), BattlefieldMinimapScroll:GetVerticalScroll()
            local cx, cy = GetCursorPosition()
            local rscale = (WorldMapFrame_InWindowedMode() and UIParent or WorldMapFrame):GetScale()
            local scale = BattlefieldMinimap:GetScale()

            cx = (cx / rscale - BattlefieldMinimapScroll:GetLeft()) / scale + ox
            cy = (BattlefieldMinimapScroll:GetTop() - cy / rscale) / scale + oy

            HJProcessMapClick( cx / BattlefieldMinimap:GetWidth(), cy / BattlefieldMinimap:GetHeight())
        end
    elseif button == "RightButton" then
        WorldMapZoomOutButton_OnClick()
    else
        SetMapToCurrentZone()
    end
    BattlefieldMinimap_UpdateOpacity(0)
end

function OnMouseWheel(self, d)
    if _MinimapControlled then Minimap:Hide() end

    if not IsAltKeyDown() then
        -- Scale the minimap
        local ox, oy = BattlefieldMinimapScroll:GetHorizontalScroll(), BattlefieldMinimapScroll:GetVerticalScroll()
        local cx, cy = GetCursorPosition()
        local rscale = (WorldMapFrame_InWindowedMode() and UIParent or WorldMapFrame):GetScale()

        cx = cx / rscale - BattlefieldMinimapScroll:GetLeft()
        cy = BattlefieldMinimapScroll:GetTop() - cy / rscale

        local oscale = self:GetScale()
        local nscale = max(0.1, oscale + d * (IsControlKeyDown() and 0.5 or 0.15))
        local framex = cx / oscale + ox
        local framey = cy / oscale + oy

        self:SetScale(nscale)

        BattlefieldMinimapScroll:SetHorizontalScroll(framex - cx / nscale)
        BattlefieldMinimapScroll:SetVerticalScroll(framey - cy / nscale)
    else
        -- Scale the window
        _SVDB.MaskScale = max(0.3, _SVDB.MaskScale + d * 0.05)
        BattlefieldMinimapScroll:SetSize(ORIGIN_WIDTH * _SVDB.MaskScale, ORIGIN_HEIGHT * _SVDB.MaskScale)
    end

    -- Re-check the scroll ranges
    BattlefieldMinimapScroll:UpdateScrollChildRect()

    local scale  = BattlefieldMinimap:GetScale()
    local rx, ry = max(BattlefieldMinimap:GetWidth() - BattlefieldMinimapScroll:GetWidth() / scale, 0), max(BattlefieldMinimap:GetHeight() - BattlefieldMinimapScroll:GetHeight() / scale, 0)
    local x, y   = BattlefieldMinimapScroll:GetHorizontalScroll(), BattlefieldMinimapScroll:GetVerticalScroll()

    if rx <= 0 then
        BattlefieldMinimap:SetScale(BattlefieldMinimapScroll:GetWidth() / BattlefieldMinimap:GetWidth())
        BattlefieldMinimapScroll:UpdateScrollChildRect()
        x = 0
    elseif ry <= 0 then
        BattlefieldMinimap:SetScale(BattlefieldMinimapScroll:GetHeight() / BattlefieldMinimap:GetHeight())
        BattlefieldMinimapScroll:UpdateScrollChildRect()
        y = 0
    end
    x = max(0, min(x, rx))
    y = max(0, min(y, ry))

    BattlefieldMinimapScroll:SetHorizontalScroll(x)
    BattlefieldMinimapScroll:SetVerticalScroll(y)

    BattlefieldMinimapPOI:SetScale(_SVDB.ScaleModifier / BattlefieldMinimap:GetScale())
    AreaLabel:SetFont(_AreaLabelFont, 16 / BattlefieldMinimap:GetScale(), _AreaLabelFlags)
    AreaDescription:SetFont(_ADFont, 12 / BattlefieldMinimap:GetScale(), _ADFlags)
    AreaPetLevels:SetFont(_ADFont, 12 / BattlefieldMinimap:GetScale(), _ADFlags)

    UpdateUnitPositionFrame()
    UpdateHitRectInsets()
    RefreshLandmarks(true)
end

function TabOnEnter()
    BattlefieldMinimapTabText:Show()
    BattlefieldMinimapTabText:SetAlpha(1)
end

__Async__()
function TabOnLeave()
    local st = GetTime()

    while not BattlefieldMinimapScroll:IsMouseOver() and not BattlefieldMinimapTab:IsMouseOver() do
        local opacity = (GetTime() - st) / 3.0

        if opacity < 1 then
            BattlefieldMinimapTabText:SetAlpha(1 - opacity)
        else
            BattlefieldMinimapTabText:Hide()
        end

        Next()
    end
end

function UpdateOpacity(opacity)
    local alpha = 1 - opacity
    BattlefieldMinimapScrollBack:SetAlpha(math.min(alpha, _SVDB.BorderColor.a))
    for i=1, GetNumberOfDetailTiles() do
        _G["BattlefieldMinimap"..i]:SetAlpha(alpha)
    end
    if alpha >= 0.15 then alpha = alpha - 0.15 end
    for i=1, BattlefieldMinimap:GetAttribute("NUM_BATTLEFIELDMAP_OVERLAYS") do
        _G["BattlefieldMinimapOverlay"..i]:SetAlpha(alpha)
    end
end

function UpdateHitRectInsets()
    local x, y      = BattlefieldMinimapScroll:GetHorizontalScroll(), BattlefieldMinimapScroll:GetVerticalScroll()
    local scale     = BattlefieldMinimap:GetScale()
    local w, h      = BattlefieldMinimap:GetSize()
    local mw, mh    = BattlefieldMinimapScroll:GetSize()

    BattlefieldMinimap:SetHitRectInsets(x, w - x - mw / scale, y, h - y - mh / scale)
    local l, b, w, h=BattlefieldMinimapScroll:GetRect()
    if not l then return end

    FixVehicleSize()

    local mod       = _SVDB.ScaleModifier
    return FireSystemEvent("EBFM_UPDATE_HITRECT", l/mod, (l+w)/mod, (b+h)/mod, b/mod)
end

_LockOnPlayerTaskOn = false

__Async__()
function LockOnPlayer()
    if _LockOnPlayerTaskOn then return end
    _LockOnPlayerTaskOn = true

    TryInitMinimap()

    Next() Next()

    while _SVDB.LockOnPlayer and not BattlefieldMinimapScroll:IsMouseOver() and BattlefieldMinimapScroll:IsVisible() and BattlefieldMinimap:IsVisible() do
        local px, py = GetPlayerMapPosition("player")

        if px and py and (px > 0 or py > 0) then
            local scale  = BattlefieldMinimap:GetScale()
            local rx, ry = max(BattlefieldMinimap:GetWidth() - BattlefieldMinimapScroll:GetWidth() / scale, 0), max(BattlefieldMinimap:GetHeight() - BattlefieldMinimapScroll:GetHeight() / scale, 0)

            px = BattlefieldMinimap:GetWidth()  * px
            py = BattlefieldMinimap:GetHeight() * py

            local x = px - BattlefieldMinimapScroll:GetWidth()  / 2 / scale
            local y = py - BattlefieldMinimapScroll:GetHeight() / 2 / scale

            x = max(0, min(x, rx))
            y = max(0, min(y, ry))

            local cx, cy = BattlefieldMinimapScroll:GetHorizontalScroll(), BattlefieldMinimapScroll:GetVerticalScroll()

            if abs(cx - x) > 2 then if cx > x then x = cx - 2 else x = cx + 2 end end
            if abs(cy - y) > 2 then if cy > y then y = cy - 2 else y = cy + 2 end end

            BattlefieldMinimapScroll:SetHorizontalScroll(x)
            BattlefieldMinimapScroll:SetVerticalScroll(y)

            if _MinimapControlled then
                px = (px - x) * scale
                py = (py - y) * scale

                Minimap:ClearAllPoints()
                Minimap:SetPoint("CENTER", BattlefieldMinimapScroll, "TOPLEFT", px, - py)
                if not Minimap:IsShown() then Minimap:Show() Minimap:SetFrameStrata("HIGH") Minimap:SetAlpha(0) end
            end

            UpdateHitRectInsets()
        --elseif _MinimapControlled then
        --    if not Minimap:IsShown() then Minimap:Show() Minimap:SetAlpha(0) end
        end

        Next()
    end

    _LockOnPlayerTaskOn = false
end

function AddPOIButton(poiButton, posX, posY, frameLevelOffset)
    if ( posX and posY ) then
        posX = posX * BattlefieldMinimapPOI:GetWidth()
        posY = posY * BattlefieldMinimapPOI:GetHeight()
        poiButton:SetPoint("CENTER", BattlefieldMinimapPOI, "TOPLEFT", posX, -posY)
        poiButton:SetFrameLevel(poiButton:GetParent():GetFrameLevel() + frameLevelOffset)
    end
end

function UpdateUnitPositionFrame()
    local scale = BattlefieldMinimap:GetScale() / (1.5 * _SVDB.UnitScale)
    BattlefieldMinimapUnitPositionFrame:SetPinSize("player", 24 / scale)
    BattlefieldMinimapUnitPositionFrame:SetPinSize("party", 8 / scale)
    BattlefieldMinimapUnitPositionFrame:SetPinSize("raid", 8 / scale)

    return BattlefieldMinimapUnitPositionFrame:UpdatePlayerPins()
end

function FixVehicleSize()
    if _G.BG_VEHICLES then
        for _, btn in ipairs(_G.BG_VEHICLES) do
            btn:SetScale(1.5 / BattlefieldMinimap:GetScale())
        end
    end
end

-- Data Hack for lazy blz
WorldMapData = {
    [WORLDMAP_COSMIC_ID] = {
        [0]     = WorldMapFrame_IsCosmicMap,
        Azeroth = {
            continent       = 0,
            left            = (AzerothButton:GetLeft()  - AzerothButton:GetParent():GetLeft()) / AzerothButton:GetParent():GetWidth(),
            top             =-(AzerothButton:GetTop()   - AzerothButton:GetParent():GetTop())  / AzerothButton:GetParent():GetHeight(),
            right           = (AzerothButton:GetRight() - AzerothButton:GetParent():GetLeft()) / AzerothButton:GetParent():GetWidth(),
            bottom          =-(AzerothButton:GetBottom()- AzerothButton:GetParent():GetTop())  / AzerothButton:GetParent():GetHeight(),

            fileName        = [[Cosmic-Azeroth]],
            texPercentageX  = 1,
            texPercentageY  = 1,
            textureX        = WorldMapButton.AzerothHighlight:GetWidth() / WorldMapDetailFrame:GetWidth(),
            textureY        = WorldMapButton.AzerothHighlight:GetHeight()/ WorldMapDetailFrame:GetHeight(),
            scrollChildX    = (WorldMapButton.AzerothHighlight:GetLeft() - WorldMapDetailFrame:GetLeft()) / WorldMapDetailFrame:GetWidth(),
            scrollChildY    = -(WorldMapButton.AzerothHighlight:GetTop() - WorldMapDetailFrame:GetTop()) / WorldMapDetailFrame:GetHeight(),
        },
        Outland = {
            continent       = 3,
            left            = (OutlandButton:GetLeft()  - OutlandButton:GetParent():GetLeft()) / OutlandButton:GetParent():GetWidth(),
            top             =-(OutlandButton:GetTop()   - OutlandButton:GetParent():GetTop())  / OutlandButton:GetParent():GetHeight(),
            right           = (OutlandButton:GetRight() - OutlandButton:GetParent():GetLeft()) / OutlandButton:GetParent():GetWidth(),
            bottom          =-(OutlandButton:GetBottom()- OutlandButton:GetParent():GetTop())  / OutlandButton:GetParent():GetHeight(),

            fileName        = [[Cosmic-Outland]],
            texPercentageX  = 1,
            texPercentageY  = 1,
            textureX        = WorldMapButton.OutlandHighlight:GetWidth() / WorldMapDetailFrame:GetWidth(),
            textureY        = WorldMapButton.OutlandHighlight:GetHeight() / WorldMapDetailFrame:GetHeight(),
            scrollChildX    = (WorldMapButton.OutlandHighlight:GetLeft() - WorldMapDetailFrame:GetLeft()) / WorldMapDetailFrame:GetWidth(),
            scrollChildY    = -(WorldMapButton.OutlandHighlight:GetTop() - WorldMapDetailFrame:GetTop()) / WorldMapDetailFrame:GetHeight(),
        },
        Draenor = {
            continent       = 7,
            left            = (DraenorButton:GetLeft()  - DraenorButton:GetParent():GetLeft()) / DraenorButton:GetParent():GetWidth(),
            top             =-(DraenorButton:GetTop()   - DraenorButton:GetParent():GetTop())  / DraenorButton:GetParent():GetHeight(),
            right           = (DraenorButton:GetRight() - DraenorButton:GetParent():GetLeft()) / DraenorButton:GetParent():GetWidth(),
            bottom          =-(DraenorButton:GetBottom()- DraenorButton:GetParent():GetTop())  / DraenorButton:GetParent():GetHeight(),

            fileName        = [[Cosmic-Draenor]],
            texPercentageX  = 1,
            texPercentageY  = 1,
            textureX        = WorldMapButton.DraenorHighlight:GetWidth() / WorldMapDetailFrame:GetWidth(),
            textureY        = WorldMapButton.DraenorHighlight:GetHeight() / WorldMapDetailFrame:GetHeight(),
            scrollChildX    = (WorldMapButton.DraenorHighlight:GetLeft() - WorldMapDetailFrame:GetLeft()) / WorldMapDetailFrame:GetWidth(),
            scrollChildY    = -(WorldMapButton.DraenorHighlight:GetTop() - WorldMapDetailFrame:GetTop()) / WorldMapDetailFrame:GetHeight(),
        },
    },
    [WORLDMAP_MAELSTROM_ID] = {
        [0]     = WorldMapFrame_IsMaelstromContinentMap,
        Maelstrom = {
            zoneID          = MAELSTROM_ZONES_ID.TheMaelstrom,
            left            = (TheMaelstromButton:GetLeft()  - TheMaelstromButton:GetParent():GetLeft()) / TheMaelstromButton:GetParent():GetWidth(),
            top             =-(TheMaelstromButton:GetTop()   - TheMaelstromButton:GetParent():GetTop())  / TheMaelstromButton:GetParent():GetHeight(),
            right           = (TheMaelstromButton:GetRight() - TheMaelstromButton:GetParent():GetLeft()) / TheMaelstromButton:GetParent():GetWidth(),
            bottom          =-(TheMaelstromButton:GetBottom()- TheMaelstromButton:GetParent():GetTop())  / TheMaelstromButton:GetParent():GetHeight(),

            name            = GetMapNameByID(MAELSTROM_ZONES_ID.TheMaelstrom),
            fileName        = "TheMaelstrom",
            texPercentageX  = 1,
            texPercentageY  = 1,
            textureX        = TheMaelstromButtonHighlight:GetWidth() / TheMaelstromButton:GetParent():GetWidth(),
            textureY        = TheMaelstromButtonHighlight:GetHeight() / TheMaelstromButton:GetParent():GetHeight(),
            scrollChildX    = (TheMaelstromButtonHighlight:GetLeft()  - TheMaelstromButton:GetParent():GetLeft()) / TheMaelstromButton:GetParent():GetWidth(),
            scrollChildY    =-(TheMaelstromButtonHighlight:GetTop()   - TheMaelstromButton:GetParent():GetTop())  / TheMaelstromButton:GetParent():GetHeight(),
            minLevel        = MAELSTROM_ZONES_LEVELS.TheMaelstrom.minLevel,
            maxLevel        = MAELSTROM_ZONES_LEVELS.TheMaelstrom.maxLevel,
            petMinLevel     = MAELSTROM_ZONES_LEVELS.TheMaelstrom.petMinLevel,
            petMaxLevel     = MAELSTROM_ZONES_LEVELS.TheMaelstrom.petMaxLevel,
        },
        Deepholm = {
            zoneID          = MAELSTROM_ZONES_ID.Deepholm,
            left            = (DeepholmButton:GetLeft()  - DeepholmButton:GetParent():GetLeft()) / DeepholmButton:GetParent():GetWidth(),
            top             =-(DeepholmButton:GetTop()   - DeepholmButton:GetParent():GetTop())  / DeepholmButton:GetParent():GetHeight(),
            right           = (DeepholmButton:GetRight() - DeepholmButton:GetParent():GetLeft()) / DeepholmButton:GetParent():GetWidth(),
            bottom          =-(DeepholmButton:GetBottom()- DeepholmButton:GetParent():GetTop())  / DeepholmButton:GetParent():GetHeight(),

            name            = GetMapNameByID(MAELSTROM_ZONES_ID.Deepholm),
            fileName        = "Deepholm",
            texPercentageX  = 1,
            texPercentageY  = 1,
            textureX        = DeepholmButtonHighlight:GetWidth() / DeepholmButton:GetParent():GetWidth(),
            textureY        = DeepholmButtonHighlight:GetHeight() / DeepholmButton:GetParent():GetHeight(),
            scrollChildX    = (DeepholmButtonHighlight:GetLeft()  - DeepholmButton:GetParent():GetLeft()) / DeepholmButton:GetParent():GetWidth(),
            scrollChildY    =-(DeepholmButtonHighlight:GetTop()   - DeepholmButton:GetParent():GetTop())  / DeepholmButton:GetParent():GetHeight(),
            minLevel        = MAELSTROM_ZONES_LEVELS.Deepholm.minLevel,
            maxLevel        = MAELSTROM_ZONES_LEVELS.Deepholm.maxLevel,
            petMinLevel     = MAELSTROM_ZONES_LEVELS.Deepholm.petMinLevel,
            petMaxLevel     = MAELSTROM_ZONES_LEVELS.Deepholm.petMaxLevel,
        },
        Kezan = {
            zoneID          = MAELSTROM_ZONES_ID.Kezan,
            left            = (KezanButton:GetLeft()  - KezanButton:GetParent():GetLeft()) / KezanButton:GetParent():GetWidth(),
            top             =-(KezanButton:GetTop()   - KezanButton:GetParent():GetTop())  / KezanButton:GetParent():GetHeight(),
            right           = (KezanButton:GetRight() - KezanButton:GetParent():GetLeft()) / KezanButton:GetParent():GetWidth(),
            bottom          =-(KezanButton:GetBottom()- KezanButton:GetParent():GetTop())  / KezanButton:GetParent():GetHeight(),

            name            = GetMapNameByID(MAELSTROM_ZONES_ID.Kezan),
            fileName        = "Kezan",
            texPercentageX  = 1,
            texPercentageY  = 1,
            textureX        = KezanButtonHighlight:GetWidth() / KezanButton:GetParent():GetWidth(),
            textureY        = KezanButtonHighlight:GetHeight() / KezanButton:GetParent():GetHeight(),
            scrollChildX    = (KezanButtonHighlight:GetLeft()  - KezanButton:GetParent():GetLeft()) / KezanButton:GetParent():GetWidth(),
            scrollChildY    =-(KezanButtonHighlight:GetTop()   - KezanButton:GetParent():GetTop())  / KezanButton:GetParent():GetHeight(),
            minLevel        = MAELSTROM_ZONES_LEVELS.Kezan.minLevel,
            maxLevel        = MAELSTROM_ZONES_LEVELS.Kezan.maxLevel,
            petMinLevel     = MAELSTROM_ZONES_LEVELS.Kezan.petMinLevel,
            petMaxLevel     = MAELSTROM_ZONES_LEVELS.Kezan.petMaxLevel,
        },
        TheLostIsles = {
            zoneID          = MAELSTROM_ZONES_ID.TheLostIsles,
            left            = (LostIslesButton:GetLeft()  - LostIslesButton:GetParent():GetLeft()) / LostIslesButton:GetParent():GetWidth(),
            top             =-(LostIslesButton:GetTop()   - LostIslesButton:GetParent():GetTop())  / LostIslesButton:GetParent():GetHeight(),
            right           = (LostIslesButton:GetRight() - LostIslesButton:GetParent():GetLeft()) / LostIslesButton:GetParent():GetWidth(),
            bottom          =-(LostIslesButton:GetBottom()- LostIslesButton:GetParent():GetTop())  / LostIslesButton:GetParent():GetHeight(),

            name            = GetMapNameByID(MAELSTROM_ZONES_ID.TheLostIsles),
            fileName        = "TheLostIsles",
            texPercentageX  = 1,
            texPercentageY  = 1,
            textureX        = LostIslesButtonHighlight:GetWidth() / LostIslesButton:GetParent():GetWidth(),
            textureY        = LostIslesButtonHighlight:GetHeight() / LostIslesButton:GetParent():GetHeight(),
            scrollChildX    = (LostIslesButtonHighlight:GetLeft()  - LostIslesButton:GetParent():GetLeft()) / LostIslesButton:GetParent():GetWidth(),
            scrollChildY    =-(LostIslesButtonHighlight:GetTop()   - LostIslesButton:GetParent():GetTop())  / LostIslesButton:GetParent():GetHeight(),
            minLevel        = MAELSTROM_ZONES_LEVELS.TheLostIsles.minLevel,
            maxLevel        = MAELSTROM_ZONES_LEVELS.TheLostIsles.maxLevel,
            petMinLevel     = MAELSTROM_ZONES_LEVELS.TheLostIsles.petMinLevel,
            petMaxLevel     = MAELSTROM_ZONES_LEVELS.TheLostIsles.petMaxLevel,
        },
    },
    [WORLDMAP_BROKEN_ISLES_ID] = {
        [0]     = WorldMapFrame_IsBrokenIslesContinentMap,
        BrokenIslesArgus = {
            continent       = 9,
            left            = (BrokenIslesArgusButton:GetLeft()  - BrokenIslesArgusButton:GetParent():GetLeft()) / BrokenIslesArgusButton:GetParent():GetWidth(),
            top             =-(BrokenIslesArgusButton:GetTop()   - BrokenIslesArgusButton:GetParent():GetTop())  / BrokenIslesArgusButton:GetParent():GetHeight(),
            right           = (BrokenIslesArgusButton:GetRight() - BrokenIslesArgusButton:GetParent():GetLeft()) / BrokenIslesArgusButton:GetParent():GetWidth(),
            bottom          =-(BrokenIslesArgusButton:GetBottom()- BrokenIslesArgusButton:GetParent():GetTop())  / BrokenIslesArgusButton:GetParent():GetHeight(),

            fileName        = [[>BrokenIslesHightlight]],
            texPercentageX  = 1,
            texPercentageY  = 1,
            textureX        = ({BrokenIslesArgusButton:GetRegions()})[1]:GetWidth() / WorldMapDetailFrame:GetWidth(),
            textureY        = ({BrokenIslesArgusButton:GetRegions()})[1]:GetHeight() / WorldMapDetailFrame:GetHeight(),
            scrollChildX    = (({BrokenIslesArgusButton:GetRegions()})[1]:GetLeft() - WorldMapDetailFrame:GetLeft()) / WorldMapDetailFrame:GetWidth(),
            scrollChildY    = -(({BrokenIslesArgusButton:GetRegions()})[1]:GetTop() - WorldMapDetailFrame:GetTop()) / WorldMapDetailFrame:GetHeight(),
        },
    },
    [WORLDMAP_ARGUS_ID] = {
        [0]     = WorldMapFrame_IsArgusContinentMap,
        Krokuun = {
            zoneID          = KrokuunButton.zoneID,
            left            = (KrokuunButton:GetLeft()  - KrokuunButton:GetParent():GetLeft()) / KrokuunButton:GetParent():GetWidth(),
            top             =-(KrokuunButton:GetTop()   - KrokuunButton:GetParent():GetTop())  / KrokuunButton:GetParent():GetHeight(),
            right           = (KrokuunButton:GetRight() - KrokuunButton:GetParent():GetLeft()) / KrokuunButton:GetParent():GetWidth(),
            bottom          =-(KrokuunButton:GetBottom()- KrokuunButton:GetParent():GetTop())  / KrokuunButton:GetParent():GetHeight(),

            fileName        = [[>Krokuun_Highlight]],
            texPercentageX  = 1,
            texPercentageY  = 1,
            textureX        = ({KrokuunButton:GetRegions()})[1]:GetWidth() / WorldMapDetailFrame:GetWidth(),
            textureY        = ({KrokuunButton:GetRegions()})[1]:GetHeight() / WorldMapDetailFrame:GetHeight(),
            scrollChildX    = (({KrokuunButton:GetRegions()})[1]:GetLeft() - WorldMapDetailFrame:GetLeft()) / WorldMapDetailFrame:GetWidth(),
            scrollChildY    = -(({KrokuunButton:GetRegions()})[1]:GetTop() - WorldMapDetailFrame:GetTop()) / WorldMapDetailFrame:GetHeight(),
        },
        MacAree = {
            zoneID          = MacAreeButton.zoneID,
            left            = (MacAreeButton:GetLeft()  - MacAreeButton:GetParent():GetLeft()) / MacAreeButton:GetParent():GetWidth(),
            top             =-(MacAreeButton:GetTop()   - MacAreeButton:GetParent():GetTop())  / MacAreeButton:GetParent():GetHeight(),
            right           = (MacAreeButton:GetRight() - MacAreeButton:GetParent():GetLeft()) / MacAreeButton:GetParent():GetWidth(),
            bottom          =-(MacAreeButton:GetBottom()- MacAreeButton:GetParent():GetTop())  / MacAreeButton:GetParent():GetHeight(),

            fileName        = [[>MacAree_Highlight]],
            texPercentageX  = 1,
            texPercentageY  = 1,
            textureX        = ({MacAreeButton:GetRegions()})[1]:GetWidth() / WorldMapDetailFrame:GetWidth(),
            textureY        = ({MacAreeButton:GetRegions()})[1]:GetHeight() / WorldMapDetailFrame:GetHeight(),
            scrollChildX    = (({MacAreeButton:GetRegions()})[1]:GetLeft() - WorldMapDetailFrame:GetLeft()) / WorldMapDetailFrame:GetWidth(),
            scrollChildY    = -(({MacAreeButton:GetRegions()})[1]:GetTop() - WorldMapDetailFrame:GetTop()) / WorldMapDetailFrame:GetHeight(),
        },
        AntoranWastes = {
            zoneID          = AntoranWastesButton.zoneID,
            left            = (AntoranWastesButton:GetLeft()  - AntoranWastesButton:GetParent():GetLeft()) / AntoranWastesButton:GetParent():GetWidth(),
            top             =-(AntoranWastesButton:GetTop()   - AntoranWastesButton:GetParent():GetTop())  / AntoranWastesButton:GetParent():GetHeight(),
            right           = (AntoranWastesButton:GetRight() - AntoranWastesButton:GetParent():GetLeft()) / AntoranWastesButton:GetParent():GetWidth(),
            bottom          =-(AntoranWastesButton:GetBottom()- AntoranWastesButton:GetParent():GetTop())  / AntoranWastesButton:GetParent():GetHeight(),

            fileName        = [[>AntoranWastes_Highlight]],
            texPercentageX  = 1,
            texPercentageY  = 1,
            textureX        = ({AntoranWastesButton:GetRegions()})[1]:GetWidth() / WorldMapDetailFrame:GetWidth(),
            textureY        = ({AntoranWastesButton:GetRegions()})[1]:GetHeight() / WorldMapDetailFrame:GetHeight(),
            scrollChildX    = (({AntoranWastesButton:GetRegions()})[1]:GetLeft() - WorldMapDetailFrame:GetLeft()) / WorldMapDetailFrame:GetWidth(),
            scrollChildY    = -(({AntoranWastesButton:GetRegions()})[1]:GetTop() - WorldMapDetailFrame:GetTop()) / WorldMapDetailFrame:GetHeight(),
        },
    },
}
function HJUpdateMapHighlight(cx, cy)
    local mapName, textureHeight, _, isMicroDungeon, microDungeonMapName = GetMapInfo()
    if not (isMicroDungeon and (not microDungeonMapName or microDungeonMapName == "")) then
        local mapdata = WorldMapData[GetCurrentMapContinent()]
        if mapdata and mapdata[0]() then
            for name, data in pairs(mapdata) do
                if name ~= 0 and cx >= data.left and cx <= data.right and cy >= data.top and cy <= data.bottom then
                    return data.name, data.fileName, data.texPercentageX, data.texPercentageY, data.textureX, data.textureY, data.scrollChildX, data.scrollChildY, data.minLevel, data.maxLevel, data.petMinLevel, data.petMaxLevel
                end
            end
        end
    end

    return UpdateMapHighlight( cx, cy )
end

function HJProcessMapClick(cx, cy)
    local mapName, textureHeight, _, isMicroDungeon, microDungeonMapName = GetMapInfo()
    if not (isMicroDungeon and (not microDungeonMapName or microDungeonMapName == "")) then
        local mapdata = WorldMapData[GetCurrentMapContinent()]
        if mapdata and mapdata[0]() then
            for name, data in pairs(mapdata) do
                if name ~= 0 and cx >= data.left and cx <= data.right and cy >= data.top and cy <= data.bottom then
                    if data.continent then
                        return SetMapZoom(data.continent)
                    else
                        return SetMapByID(data.zoneID)
                    end
                end
            end
        end
    end

    return ProcessMapClick(cx, cy)
end

function tryShow()
    if not BattlefieldMinimapScroll:IsVisible() then
        if (not _SVDB.HideInDungeon or GetPlayerMapPosition("player")) and
            (not _SVDB.HideInCombat or not UnitAffectingCombat("player")) and
            (not _SVDB.HideDismount or (IsMounted() or (DRUID_TRAVEL_INDEX and select(3, GetShapeshiftFormInfo(DRUID_TRAVEL_INDEX))))) then
            BattlefieldMinimapScroll:SetAlpha(0)
            BattlefieldMinimapScroll:Show()

            Continue(function()
                local st = GetTime()
                while BattlefieldMinimapScroll:IsVisible() do
                    local alpha = (GetTime() - st) / 3.0
                    if alpha < 1 then
                        BattlefieldMinimapScroll:SetAlpha(alpha)
                    else
                        BattlefieldMinimapScroll:SetAlpha(1)
                        TryInitMinimap()
                        break
                    end

                    Next()
                end
            end)
        end
    end
end

function tryHide()
    if BattlefieldMinimapScroll:IsVisible() and not BattlefieldMinimapScroll:IsMouseOver() then
        if _SVDB.HideInDungeon and (not GetPlayerMapPosition("player")) or
            _SVDB.HideInCombat and UnitAffectingCombat("player") or
            _SVDB.HideDismount and not (IsMounted() or (DRUID_TRAVEL_INDEX and select(3, GetShapeshiftFormInfo(DRUID_TRAVEL_INDEX)))) then
            BattlefieldMinimapScroll:Hide()

            if _IncludeMinimap then
                SendBackMinimap()
            end
        end
    end
end

__Async__()
function Minimap_OnEnter(self)
    if _MinimapControlled and BattlefieldMinimapScroll:IsVisible() and BattlefieldMinimap:IsVisible() then
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

    Minimap:SetParent(BattlefieldMinimapScroll)
    Minimap:SetFrameStrata("HIGH")
end

function TryInitMinimap()
    if _IncludeMinimap and _SVDB.LockOnPlayer and ((BattlefieldMinimap:IsVisible() and BattlefieldMinimapScroll:IsVisible()) or _SVDB.AlwaysInclude) and not _MinimapControlled then
        _MinimapControlled = true
        SaveMinimapLocation()
        Minimap_OnEnter(Minimap)
        if not GetPlayerMapPosition("player") then
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
            MinimapBackdrop:Show()
        end
        Minimap:Show()
        Minimap:SetParent(MinimapParent)
        Minimap:SetFrameStrata(MinimapStrata)
        Minimap:SetAlpha(1)
        Minimap:SetPlayerTexture([[Interface\Minimap\MinimapArrow]])
        Minimap:ClearAllPoints()
        for i, v in ipairs(MinimapLoc) do
            Minimap:SetPoint(unpack(v))
        end
    end
end