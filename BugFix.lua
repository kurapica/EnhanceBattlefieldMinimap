if not Scorpio.IsRetail then return end

function QuestSuperTracking_ShouldHighlightDungeons(uiMapID)
	return SuperTrackEventFrame and SuperTrackEventFrame.uiMapID == uiMapID and SuperTrackEventFrame.dungeons;
end