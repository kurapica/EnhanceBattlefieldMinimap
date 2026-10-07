--========================================================--
--                EBFM HandyNotes                         --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2018/07/23                              --
-- Update Date :  2026/10/07                              --
--========================================================--

--========================================================--
Scorpio     "EnhanceBattlefieldMinimap.HandyNotes"   "2.1.0"
--========================================================--

export { tinsert = table.insert }

local INITED            = false
local TARGET_MAP
local DataProvider

function OnLoad()
    _SVDB:SetDefault {
        ShowHandyNotes  = true,
        HandyNotesScale = 1.0,
    }
end

__Async__()
function OnEnable(self)
    if not IsAddOnLoaded("HandyNotes") then
        while NextEvent("ADDON_LOADED") ~= "HandyNotes" do end
        Next()
    end

    local HandyNotes    = _G.HandyNotes
    DataProvider        = CreateFromMixins({}, HandyNotes.WorldMapDataProvider)

    self:SecureHook(HandyNotes, "UpdateWorldMapPlugin")
    self:SecureHook(HandyNotes, "UpdateWorldMap")

    if TARGET_MAP and _SVDB.ShowHandyNotes then
        TARGET_MAP:AddDataProvider(DataProvider)
        DataProvider:RefreshAllData()
    end
end

__SlashCmd__("ebfm", "handynotes", _Locale["on/off - show HandyNotes's marks"])
function ToggleHandyNotes(opt)
    if opt == "on" then
        if not _SVDB.ShowHandyNotes then
            _SVDB.ShowHandyNotes = true

            if INITED and DataProvider then
                TARGET_MAP:AddDataProvider(DataProvider)
                DataProvider:RefreshAllData()
            end
        end
    elseif opt == "off" then
        if _SVDB.ShowHandyNotes then
            _SVDB.ShowHandyNotes = false

            if INITED and DataProvider then
                TARGET_MAP:RemoveDataProvider(DataProvider)
            end
        end
    else
        return false
    end
end

__SystemEvent__()
function EBFM_DATAPROVIDER_INIT(map)
    TARGET_MAP          = map

    if _SVDB.ShowHandyNotes and DataProvider then
        map:AddDataProvider(DataProvider)
        DataProvider:RefreshAllData()
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

                        if INITED and DataProvider then
                            DataProvider:RefreshAllData()
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

function UpdateWorldMapPlugin(self, pluginName)
    if INITED and _SVDB.ShowHandyNotes then
        DataProvider:RefreshPlugin(pluginName)
    end
end

function UpdateWorldMap(self)
    if INITED and _SVDB.ShowHandyNotes then
        DataProvider:RefreshAllData()
    end
end
