--========================================================--
--                EBFM HandyNotes                         --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2018/07/23                              --
--========================================================--

--========================================================--
Scorpio     "EnhanceBattlefieldMinimap.HandyNotes"   "2.0.0"
--========================================================--

if not IsAddOnLoaded("HandyNotes") then return end

local INITED            = false
local TARGET_MAP

HandyNotes              = HandyNotes

HandyNotesDataProvider  = CreateFromMixins({}, HandyNotes.WorldMapDataProvider)

function OnLoad(self)
    _SVDB:SetDefault { ShowHandyNotes = true }
end

__SlashCmd__("ebfm", "handynotes", _Locale["on/off - show HandyNotes's marks"])
function ToggleHandyNotes(opt)
    if opt == "on" then
        if not _SVDB.ShowHandyNotes then
            _SVDB.ShowHandyNotes = true

            if INITED then
                TARGET_MAP:AddDataProvider(HandyNotesDataProvider)
                HandyNotesDataProvider:RefreshAllData()
            end
        end
    elseif opt == "off" then
        if _SVDB.ShowHandyNotes then
            _SVDB.ShowHandyNotes = false

            if INITED then
                TARGET_MAP:RemoveDataProvider(HandyNotesDataProvider)
            end
        end
    else
        return false
    end
end

__SystemEvent__()
function EBFM_DATAPROVIDER_INIT(map)
    TARGET_MAP          = map

    if _SVDB.ShowHandyNotes then
        map:AddDataProvider(HandyNotesDataProvider)
        HandyNotesDataProvider:RefreshAllData()
    end

    INITED              = true
end

__SecureHook__(HandyNotes)
function UpdateWorldMapPlugin(self, pluginName)
    if INITED and _SVDB.ShowHandyNotes then
        HandyNotesDataProvider:RefreshPlugin(pluginName)
    end
end

__SecureHook__(HandyNotes)
function UpdateWorldMap(self)
    if INITED and _SVDB.ShowHandyNotes then
        HandyNotesDataProvider:RefreshAllData()
    end
end