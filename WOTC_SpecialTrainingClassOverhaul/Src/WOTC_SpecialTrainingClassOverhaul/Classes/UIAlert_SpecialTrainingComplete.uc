class UIAlert_SpecialTrainingComplete extends UIAlert;

var localized string m_strNewSpecializationLabel;

simulated function BuildAlert()
{
	BindLibraryItem();
	BuildSpecialTrainingAlert();
}

simulated function BuildSpecialTrainingAlert()
{
	local XComGameState_Unit UnitState;
	local X2SpecializationTemplate SpecializationTemplate;
	local X2SoldierClassTemplate ClassTemplate;
	local XComGameState_ResistanceFaction FactionState;

	if(LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
	SpecializationTemplate = class'SpecialTrainingUtilities'.static.GetSpecialTrainingComponentOf(UnitState).GetLastTrainedSpecialization();
	ClassTemplate = UnitState.GetSoldierClassTemplate();
	FactionState = UnitState.GetResistanceFaction();

	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strTrainingCompleteLabel);
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(ClassTemplate.IconImage);
	LibraryPanel.MC.QueueString(Caps(class'X2ExperienceConfig'.static.GetRankName(UnitState.GetRank(), ClassTemplate.DataName)));
	LibraryPanel.MC.QueueString(UnitState.GetName(eNameType_FullNick));
	LibraryPanel.MC.QueueString(Caps(ClassTemplate.DisplayName));

	LibraryPanel.MC.QueueString(SpecializationTemplate.IconImage);
	LibraryPanel.MC.QueueString(m_strNewSpecializationLabel);
	LibraryPanel.MC.QueueString(SpecializationTemplate.DisplayName);
	LibraryPanel.MC.QueueString(SpecializationTemplate.Summary);

	LibraryPanel.MC.QueueString(m_strViewSoldier);
	LibraryPanel.MC.QueueString(m_strCarryOn);
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();

	Button1.SetGamepadIcon(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
	Button1.OnSizeRealized = OnTrainingButtonRealized;
	Button2.OnSizeRealized = OnTrainingButtonRealized;

	Button1.Hide(); 
	Button1.DisableNavigation();

	if (FactionState != none)
		SetFactionIcon(FactionState.GetFactionIcon());
}