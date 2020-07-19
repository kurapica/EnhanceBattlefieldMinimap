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

CURRENT_PING                    = {}
SORT_USER_PING                  = List()

function OnLoad(self)
    _SVDB:SetDefault {
        -- Display Status
        PingDelay               = 5.0,
        PingPerUser             = 2,    -- The display ping per user
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

__SlashCmd__("ebfm", "pingperuser", _Locale["[1-5] - set the ping count per user, default 2"])
function SetPingPerUser(opt)
    _SVDB.PingPerUser           = Clamp(tonumber(opt) or 0, 1, 5)
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
    self:SetScalingLimits(1.0, 1.0, 2.00)
    self:UseFrameLevelType("PIN_FRAME_LEVEL_MAP_HIGHLIGHT")
    self.UpdateTooltip = self.OnMouseEnter
end

function EBFMPingPinMixin:OnAcquired(user, map, x, y)
    PlaySound(SOUNDKIT.MAP_PING)
    self.sender                 = user
    self.map                    = map
    self.x                      = x
    self.y                      = y
    self.endtime                = GetTime() + _SVDB.PingDelay

    self:SetPosition(x/100, y/100)
    self.DriverAnimation:Play()
    self.ScaleAnimation:Play()
    self.RotateAnimation:Play()

    CURRENT_PING[self]          = true

    -- Reduce the ping of the user
    SORT_USER_PING:Clear()

    for ping in pairs(CURRENT_PING) do
        if ping.sender == user then
            SORT_USER_PING:Insert(ping.endtime)
        end
    end

    if #SORT_USER_PING > _SVDB.PingPerUser then
        SORT_USER_PING:Sort()
        local last              = SORT_USER_PING[#SORT_USER_PING - _SVDB.PingPerUser]
        for ping in pairs(CURRENT_PING) do
            if ping.sender == user and ping.endtime <= last then
                local map   = ping:GetMap()
                if map then map:RemovePin(ping) end
            end
        end
    end

    FireSystemEvent("EBFM_PING_ACQUIRED")
end

function EBFMPingPinMixin:OnReleased()
    CURRENT_PING[self]          = nil

    self.sender                 = nil
    self.map                    = nil
    self.x                      = nil
    self.y                      = nil
    self.endtime                = nil

    self.DriverAnimation:Stop()
    self.ScaleAnimation:Stop()
    self.RotateAnimation:Stop()
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

__Service__(true)
function ProcessPing()
    while true do
        NextEvent("EBFM_PING_ACQUIRED")

        local hasping           = true

        while hasping do
            hasping             = false
            local now           = GetTime()

            for ping in pairs(CURRENT_PING) do
                hasping         = true

                if ping.endtime and ping.endtime <= now then
                    local map   = ping:GetMap()
                    if map then map:RemovePin(ping) end
                end
            end

            Delay(0.1)
        end
    end
end

function Container_OnMouseDown(self, button)
    mouseDownTime               = GetTime()
end

function Container_OnMouseUp(self, button)
    if button == "LeftButton" and GetTime() - mouseDownTime < 0.3 then
        -- Click to ping
        local mapid             = TARGET_MAP:GetMapID()
        local x, y              = self:GetCursorPosition()
        x                       = self:NormalizeHorizontalSize(x / self:GetCanvasScale() - self.Child:GetLeft())
        y                       = self:NormalizeVerticalSize(self.Child:GetTop() - y / self:GetCanvasScale())

        local type              = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or IsInRaid() and "RAID" or IsInGroup() and "PARTY" or C_GuildInfo.CanSpeakInGuildChat() and "GUILD"
        if type then
            C_ChatInfo.SendAddonMessage(EBFM_PING_PREFIX, ("%s:%d(%.2f, %.2f)"):format(GetRealmName() .. "-" .. UnitName("player"), mapid, x * 100, y * 100), type)
        else
            C_ChatInfo.SendAddonMessage(EBFM_PING_PREFIX, ("%s:%d(%.2f, %.2f)"):format(GetRealmName() .. "-" .. UnitName("player"), mapid, x * 100, y * 100), "WHISPER", UnitName("player"))
        end
    end
end
