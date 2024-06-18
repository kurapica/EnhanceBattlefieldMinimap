--========================================================--
--                EBFM RareScanner                        --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2018/07/23                              --
--========================================================--

--========================================================--
Scorpio     "EnhanceBattlefieldMinimap.RareScanner"  "1.0.0"
--========================================================--


if not IsAddOnLoaded("RareScanner") then return end

export { tinsert = table.insert }

local INITED            = false
local TARGET_MAP

RareScannerDataProvider = CreateFromMixins({}, RareScannerDataProviderMixin)

function OnLoad(self)
    _SVDB:SetDefault {
        ShowRareScanner  = true,
        RareScannerScale = 1.0,
    }
end

__SlashCmd__("ebfm", "rarescanner", _Locale["on/off - show RareScanner's marks"])
function ToggleRareScanner(opt)
    if opt == "on" then
        if not _SVDB.ShowRareScanner then
            _SVDB.ShowRareScanner = true

            if INITED then
                TARGET_MAP:AddDataProvider(RareScannerDataProvider)
                RareScannerDataProvider:RefreshAllData()
            end
        end
    elseif opt == "off" then
        if _SVDB.ShowRareScanner then
            _SVDB.ShowRareScanner = false

            if INITED then
                TARGET_MAP:RemoveDataProvider(RareScannerDataProvider)
            end
        end
    else
        return false
    end
end

__SystemEvent__()
function EBFM_DATAPROVIDER_INIT(map)
    TARGET_MAP          = map

    if _SVDB.ShowRareScanner then
        map:AddDataProvider(RareScannerDataProvider)
        RareScannerDataProvider:RefreshAllData()
    end

    INITED              = true
end

__SystemEvent__()
function EBFM_SHOW_MENU(option)
    tinsert(option,
        {
            text            = _Locale["RareScanner"],
            submenu         = {
                {
                    text    = _Locale["Enable"],
                    check   = {
                        get = function() return _SVDB.ShowRareScanner end,
                        set = function(value) ToggleRareScanner(value and "on" or "off") end,
                    }
                },
                {
                    text    = _Locale["Pin Scale"] .. " - " .. _SVDB.RareScannerScale,
                    click   = function()
                        local scale = PickRange(_Locale["Choose Pin Scale"], 0.1, 5, 0.1, _SVDB.RareScannerScale)
                        if not scale then return end

                        _SVDB.RareScannerScale = scale

                        if INITED then
                            RareScannerDataProvider:RefreshAllData()
                        end
                    end,
                },
            }
        }
    )
end

__SystemEvent__()
function EBFM_PIN_ACQUIRED(template, pin)
    if template == "RSEntityPinTemplate" or template == "RSOverlayTemplate" or template == "RSGuideTemplate" or template == "RSGroupPinTemplate" then
        local w, h = pin:GetSize()
        pin:SetSize(w * _SVDB.RareScannerScale, h * _SVDB.RareScannerScale)
    end
end
