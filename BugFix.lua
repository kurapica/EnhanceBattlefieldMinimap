Scorpio     "EnhanceBattlefieldMinimap.BugFix" "1.0.0"

if Scorpio.IsRetail then
	function _G.QuestSuperTracking_ShouldHighlightWorldQuests(uiMapID)
		return SuperTrackEventFrame and SuperTrackEventFrame.uiMapID == uiMapID and SuperTrackEventFrame.worldQuests;
	end

	function _G.QuestSuperTracking_ShouldHighlightWorldQuestsElite(uiMapID)
		return SuperTrackEventFrame and SuperTrackEventFrame.uiMapID == uiMapID and SuperTrackEventFrame.worldQuestsElite;
	end

	function _G.QuestSuperTracking_ShouldHighlightDungeons(uiMapID)
		return SuperTrackEventFrame and SuperTrackEventFrame.uiMapID == uiMapID and SuperTrackEventFrame.dungeons;
	end

	function _G.QuestSuperTracking_ShouldHighlightTreasures(uiMapID)
		return SuperTrackEventFrame and SuperTrackEventFrame.uiMapID == uiMapID and SuperTrackEventFrame.treasures;
	end
else
	INITED 						= false
    _G.BattlefieldMapAllowed 	= function() return true end

	__SystemEvent__()
	function EBFM_DATAPROVIDER_INIT(map)
		BattlefieldMapFrame:UnregisterAllEvents()
        BattlefieldMapFrame:SetGlobalPinScale(1)

		INITED 					= true
	end

	__SystemEvent__ "PLAYER_ENTERING_WORLD" "ZONE_CHANGED_NEW_AREA" "UPDATE_ALL_UI_WIDGETS" "UPDATE_UI_WIDGET"
	function UpdateMap()
		if not (INITED and BattlefieldMapFrame:IsShown()) then return end

		local mapID = MapUtil.GetDisplayableMapForPlayer()
		BattlefieldMapFrame:SetMapID(mapID)
	end
end