--========================================================--
--                EBFM TomTom                  			  --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2021/08/29                              --
--========================================================--

--========================================================--
Scorpio            "EnhanceBattlefieldMinimap.TOMTOM"     ""
--========================================================--

if not IsAddOnLoaded("TomTom") then return end

__SystemEvent__()
function EBFM_DATAPROVIDER_INIT(map)
    TARGET_MAP                  = map

    map.ScrollContainer:HookScript("OnMouseUp", Container_OnMouseUp)
end

function Container_OnMouseUp(self, button)
    if IsAltKeyDown() and button == "RightButton" then
        -- Click to ping
        local mapid             = TARGET_MAP:GetMapID()
        local x, y              = self:GetCursorPosition()
        if not Scorpio.IsRetail then
            x                   = x / self:GetEffectiveScale()
            y                   = y / self:GetEffectiveScale()
        end
        x                       = self:NormalizeHorizontalSize(x / self:GetCanvasScale() - self.Child:GetLeft())
        y                       = self:NormalizeVerticalSize(self.Child:GetTop() - y / self:GetCanvasScale())

        local desc 				= string.format("%.2f, %.2f", x*100, y*100)
        TomTom:AddWaypoint(mapid, x, y, { title = desc, from = "EBFM" })
    end
end
