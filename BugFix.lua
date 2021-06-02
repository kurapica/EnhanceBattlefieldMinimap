Scorpio     "EnhanceBattlefieldMinimap.BugFix" "1.0.0"

if Scorpio.IsRetail then
	function _G.QuestSuperTracking_ShouldHighlightDungeons(uiMapID)
		return SuperTrackEventFrame and SuperTrackEventFrame.uiMapID == uiMapID and SuperTrackEventFrame.dungeons;
	end
else
	INITED 						= false
	__SystemEvent__()
	function EBFM_DATAPROVIDER_INIT(map)
		BattlefieldMapFrame:UnregisterAllEvents()

		INITED 					= true
	end

	__SystemEvent__ "PLAYER_ENTERING_WORLD" "ZONE_CHANGED_NEW_AREA" "UPDATE_ALL_UI_WIDGETS" "UPDATE_UI_WIDGET"
	function UpdateMap()
		if not (INITED and BattlefieldMapFrame:IsShown()) then return end

		local mapID = MapUtil.GetDisplayableMapForPlayer()
		BattlefieldMapFrame:SetMapID(mapID)
	end
end