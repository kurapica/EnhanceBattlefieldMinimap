--========================================================--
--                EBFM HandyNotes                         --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2018/07/23                              --
--========================================================--

--========================================================--
Scorpio     "EnhanceBattlefieldMinimap.HandyNotes"   "2.0.0"
--========================================================--

if not (Scorpio.IsRetail and IsAddOnLoaded("HandyNotes")) then return end

export { tinsert = table.insert }

local INITED            = false
local TARGET_MAP

HandyNotes              = HandyNotes

HandyNotesDataProvider  = CreateFromMixins({}, HandyNotes.WorldMapDataProvider)

function OnLoad(self)
    _SVDB:SetDefault {
        ShowHandyNotes  = true,
        HandyNotesScale = 1.0,
    }
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

__SystemEvent__()
function EBFM_SHOW_MENU(option)
    tinsert(option,
        {
            text            = _Locale["HandyNotes"],
            submenu         = {
                {
                    text    = _Locale["Enable"],
                    check   = {
                        get = function() return _SVDB.ShowHandyNotes end,
                        set = function(value) ToggleHandyNotes(value and "on" or "off") end,
                    }
                },
                {
                    text    = _Locale["Pin Scale"] .. " - " .. _SVDB.HandyNotesScale,
                    click   = function()
                        local scale = PickRange(_Locale["Choose Pin Scale"], 0.1, 5, 0.1, _SVDB.HandyNotesScale)
                        if not scale then return end

                        _SVDB.HandyNotesScale = scale

                        if INITED then
                            HandyNotesDataProvider:RefreshAllData()
                        end
                    end,
                },
            }
        }
    )
end

__SystemEvent__()
function EBFM_PIN_ACQUIRED(template, pin)
    if template == "HandyNotesWorldMapPinTemplate" then
        local w, h = pin:GetSize()
        pin:SetSize(w * _SVDB.HandyNotesScale, h * _SVDB.HandyNotesScale)
    end
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
