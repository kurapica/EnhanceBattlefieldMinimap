--========================================================--
--                EBFM PING DataProvider                  --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2020/07/17                              --
--========================================================--

--========================================================--
Scorpio            "EnhanceBattlefieldMinimap.PING"       ""
--========================================================--

EBFMPingDataProviderMixin       = CreateFromMixins(MapCanvasDataProviderMixin)
EBFMPingPinMixin                = CreateFromMixins(MapCanvasPinMixin)

_G.EBFMPingPinMixin             = EBFMPingPinMixin

EBFM_PING_PREFIX                = "EBFM:PING"

function OnLoad(self)
    _SVDB:SetDefault {
        -- Display Status
        PingDelay               = 5.0,
    }
end

__SystemEvent__()
function EBFM_DATAPROVIDER_INIT(map)
    TARGET_MAP                  = map

    C_ChatInfo.RegisterAddonMessagePrefix(EBFM_PING_PREFIX)

    map.ScrollContainer:HookScript("OnMouseDown", Container_OnMouseDown)
    map.ScrollContainer:HookScript("OnMouseUp", Container_OnMouseUp)

    map:AddDataProvider(CreateFromMixins({}, EBFMPingDataProviderMixin))
end

__SlashCmd__("ebfm", "ping", _Locale["[3-10] - set the ping display time, default 5"])
function SetPingDelay(opt)
    _SVDB.PingDelay             = Clamp(tonumber(opt) or 0, 3, 10)
end

----------------------------------------------
--        EBFMPingDataProviderMixin         --
----------------------------------------------
function EBFMPingDataProviderMixin:GetPinTemplate()
    return "EBFMPingPinTemplate";
end

function EBFMPingDataProviderMixin:OnAdded(mapCanvas)
    MapCanvasDataProviderMixin.OnAdded(self, mapCanvas);

    self:RegisterEvent("CHAT_MSG_ADDON")
end

function EBFMPingDataProviderMixin:OnEvent(event, prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID)
    if prefix ~= EBFM_PING_PREFIX then return end

    local user, map, x, y       = text:match("^(.*):(%d+)%(([%d%.]+),%s*([%d%.]+)%)$")
    if user and map and x and y then
        if tonumber(map) ~= self:GetMap():GetMapID() then return end

        self:GetMap():AcquirePin(self:GetPinTemplate(), user, map, x, y)
    end
end

function EBFMPingDataProviderMixin:RemoveAllData()
    self:GetMap():RemoveAllPinsByTemplate(self:GetPinTemplate())
end

function EBFMPingDataProviderMixin:RefreshAllData(fromOnShow)
    self:RemoveAllData()
end

----------------------------------------------
--             EBFMPingPinMixin             --
----------------------------------------------
function EBFMPingPinMixin:OnLoad()
    --self:SetScalingLimits(1, 0.4125, 0.4125)
    self:UseFrameLevelType("PIN_FRAME_LEVEL_MAP_HIGHLIGHT")
    self.UpdateTooltip = self.OnMouseEnter
end

function EBFMPingPinMixin:OnAcquired(user, map, x, y)
    PlaySound(SOUNDKIT.MAP_PING)
    self.sender                 = user
    self.map                    = map
    self.x                      = x
    self.y                      = y

    self:SetPosition(x/100, y/100)
    self.DriverAnimation:Play()
    self.ScaleAnimation:Play()

    Delay(_SVDB.PingDelay, function() self:GetMap():RemovePin(self) end)
end

function EBFMPingPinMixin:OnReleased()
    self.sender                 = nil
    self.map                    = nil
    self.x                      = nil
    self.y                      = nil
    self.DriverAnimation:Stop()
    self.ScaleAnimation:Stop()
end

function EBFMPingPinMixin:OnMouseEnter()
    local sender                = self.sender

    GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 5, 2)
    GameTooltip:SetText(sender)
    GameTooltip:Show()
end

function EBFMPingPinMixin:OnMouseLeave()
    GameTooltip:Hide()
end

----------------------------------------------
--          Script Event Handlers           --
----------------------------------------------
local mouseDownTime

function Container_OnMouseDown(self, button)
    mouseDownTime               = GetTime()
end

function Container_OnMouseUp(self, button)
    if button == "LeftButton" and GetTime() - mouseDownTime < 0.3 then
        -- Click to ping
        local mapid             = TARGET_MAP:GetMapID()
        local x, y              = self:GetCursorPosition()
        local x, y              = self:GetCursorPosition()
        x                       = self:NormalizeHorizontalSize(x / self:GetCanvasScale() - self.Child:GetLeft())
        y                       = self:NormalizeVerticalSize(self.Child:GetTop() - y / self:GetCanvasScale())

        local type              = IsInRaid() and "RAID" or IsInGroup() and "PARTY" or C_GuildInfo.CanSpeakInGuildChat() and "GUILD"
        if type then
            C_ChatInfo.SendAddonMessage(EBFM_PING_PREFIX, ("%s:%d(%.2f, %.2f)"):format(UnitName("player"), mapid, x * 100, y * 100), type)
        end
    end
end
