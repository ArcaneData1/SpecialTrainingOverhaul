class XComGameState_HeadquartersProjectSpecialTraining extends XComGameState_HeadquartersProjectTrainRookie;

var() name NewSpecializationName; // name of the specialization being trained

//---------------------------------------------------------------------------------------
// Call when you start a new project, NewGameState should be none if not coming from tactical
function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_GameTime TimeState;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;
	ProjectFocus = FocusRef; // Unit
	AuxilaryReference = AuxRef; // Facility
	
	ProjectPointsRemaining = CalculatePointsToTrain();
	InitialProjectPoints = ProjectPointsRemaining;

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ProjectFocus.ObjectID));
	//UnitState.PsiTrainingRankReset();
	UnitState.SetStatus(eStatus_Training);

	UpdateWorkPerHour(NewGameState);
	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	StartDateTime = TimeState.CurrentTime;

	if (`STRATEGYRULES != none)
	{
		if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(TimeState.CurrentTime, `STRATEGYRULES.GameTime))
		{
			StartDateTime = `STRATEGYRULES.GameTime;
		}
	}
	
	if (MakingProgress())
	{
		SetProjectedCompletionDateTime(StartDateTime);
	}
	else
	{
		// Set completion time to unreachable future
		CompletionDateTime.m_iYear = 9999;
	}
}

//---------------------------------------------------------------------------------------
function int CalculatePointsToTrain()
{
	//return int(class'LWOfficerUtilities'.static.GetOfficerTrainingDays(NewRank) * 24.0);
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	return XComHQ.GetTrainRookieDays() * 24;
}

//---------------------------------------------------------------------------------------
function int CalculateWorkPerHour(optional XComGameState StartState = none, optional bool bAssumeActive = false)
{
	return 1;
}

function X2SpecialTrainingTemplate GetTrainingSpecializationTemplate()
{
	return class'X2SpecialTrainingTemplateManager'.static.GetSpecialTrainingTemplateManager().FindSpecialTrainingTemplate(NewSpecializationName);
}

//---------------------------------------------------------------------------------------
// Remove the project
function OnProjectCompleted()
{
	local XComGameStateHistory History;
	local XComHeadquartersCheatManager CheatMgr;
	local XComGameState_HeadquartersXCom XComHQ, NewXComHQ;
	local XComGameState_Unit Unit;
	local XComGameState_Unit UpdatedUnit;
	//local XComGameState_Unit_LWOfficer OfficerState;
	local XComGameState UpdateState;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	//local SoldierClassAbilityType Ability;
	//local ClassAgnosticAbility NewOfficerAbility;
	local XComGameState_HeadquartersProjectSpecialTraining ProjectState;
	local XComGameState_StaffSlot StaffSlotState;
	/*
	Ability.AbilityName = AbilityName;
	Ability.ApplyToWeaponSlot = eInvSlot_Unknown;
	Ability.UtilityCat = '';
	NewOfficerAbility.AbilityType = Ability;
	NewOfficerAbility.iRank = 0;
	NewOfficerAbility.bUnlocked = true;
	*/
	History = `XCOMHISTORY;
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectFocus.ObjectID));
	
	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Special Training Complete");
	UpdateState = History.CreateNewGameState(true, ChangeContainer);
	UpdatedUnit = XComGameState_Unit(UpdateState.CreateStateObject(class'XComGameState_Unit', Unit.ObjectID));

	//OfficerState = class'LWOfficerUtilities'.static.GetOfficerComponent(Unit);
	//OfficerState = XComGameState_Unit_LWOfficer(UpdateState.CreateStateObject(class'XComGameState_Unit_LWOfficer', OfficerState.ObjectID));

	//OfficerState.SetOfficerRank(NewRank);
	
	//UpdatedUnit = class'LWOfficerUtilities'.static.AddInitialAbilities(UpdatedUnit, OfficerState, UpdateState);

	//OfficerState.LastAbilityTrainedName = OfficerState.AbilityTrainingName;
	//OfficerState.OfficerAbilities.AddItem(NewOfficerAbility);
	UpdatedUnit.SetStatus(eStatus_Active);

	ProjectState = XComGameState_HeadquartersProjectSpecialTraining(`XCOMHISTORY.GetGameStateForObjectID(GetReference().ObjectID));
	if (ProjectState != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			NewXComHQ = XComGameState_HeadquartersXCom(UpdateState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			UpdateState.AddStateObject(NewXComHQ);
			NewXComHQ.Projects.RemoveItem(ProjectState.GetReference());
			UpdateState.RemoveStateObject(ProjectState.ObjectID);
		}


		// Remove the soldier from the staff slot
		StaffSlotState = UpdatedUnit.GetStaffSlot();
		if (StaffSlotState != none)
		{
			StaffSlotState.EmptySlot(UpdateState);
		}
	}

	UpdateState.AddStateObject(UpdatedUnit);
	//UpdateState.AddStateObject(OfficerState);
	UpdateState.AddStateObject(ProjectState);
	`GAMERULES.SubmitGameState(UpdateState);

	CheatMgr = XComHeadquartersCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager);
	if (CheatMgr == none || !CheatMgr.bGamesComDemo)
	{
		UITrainingComplete(ProjectFocus);
	}
}

function UITrainingComplete(StateObjectReference UnitRef)
{
	local UIAlert_STCO Alert;
	local XComHQPresentationLayer HQPres;

	HQPres = `HQPres;

	Alert = HQPres.Spawn(class'UIAlert_STCO', HQPres);
	//Alert.eAlert = eAlert_TrainingComplete; // UIAlert.eAlert deprecated in WOTC. Now eAlertName of type Name
	//Alert.UnitInfo.UnitRef = UnitRef;
	//Alert.fnCallback = TrainingCompleteCB;
	//Alert.SoundToPlay = "Geoscape_CrewMemberLevelledUp";
	Alert.eAlertName = 'eAlert_TrainingComplete';
	Alert.DisplayPropertySet.SecondaryRoutingKey = Alert.eAlertName; // Necessary? Probably not. Who cares?
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(Alert.DisplayPropertySet, 'UnitRef', UnitRef.ObjectID);
	Alert.DisplayPropertySet.CallbackFunction = TrainingCompleteCB;
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(Alert.DisplayPropertySet, 'SoundToPlay', "Geoscape_CrewMemberLevelledUp");
	HQPres.ScreenStack.Push(Alert);

}

simulated function TrainingCompleteCB(/*EUIAction*/ Name eAction, out /*UIAlert*/ DynamicPropertySet AlertData, optional bool bInstants = false) // eAction now of type Name, AlertData now of type DynamicPropertySet
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	
	if( eAction == 'eUIAction_Accept' || eAction == 'eUIAction_Cancel' )
	{
		// Flag the new class popup as having been seen
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Promotion Callback");
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit',
																	  class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'UnitRef')));
		UnitState.bNeedsNewClassPopup = false;
		`XEVENTMGR.TriggerEvent('UnitPromoted', , , NewGameState);
		`GAMERULES.SubmitGameState(NewGameState);
	}
/*
	//local XComGameState NewGameState; 
	local XComHQPresentationLayer HQPres;
	local StateObjectReference UnitRef; // Added for WOTC compatibility, see below

	HQPres = `HQPres;
	
	//NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Promotion");
	//`XEVENTMGR.TriggerEvent('UnitPromoted', , , NewGameState);
	//`GAMERULES.SubmitGameState(NewGameState);

	if (!HQPres.m_kAvengerHUD.Movie.Stack.HasInstanceOf(class'UIArmory_LWOfficerPromotion')) // If we are already in the promotion screen, just close this popup
	{
		//if (eAction == eUIAction_Accept) // eAction now of type Name
		if (eAction == 'eUIAction_Accept')
		{
			//GoToArmoryLWOfficerPromotion(AlertData.UnitInfo.UnitRef, true); // AlertData.UnitInfo deprecated in favor of the DisplayPropertySet, now must reverse reference the UnitRef by its ObjectID
			UnitRef.ObjectID = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'UnitRef');
			GoToArmoryLWOfficerPromotion(UnitRef, true);
		}
		else
		{
			`GAME.GetGeoscape().Resume();
		}
	}
	*/
}
/*
simulated function GoToArmoryLWOfficerPromotion(StateObjectReference UnitRef, optional bool bInstantb = false)
{
	//local XComGameState_HeadquartersXCom XComHQ;
	//local XComGameState_FacilityXCom ArmoryState;
	local UIArmory_LWOfficerPromotion OfficerScreen;
	local XComHQPresentationLayer HQPres;

	HQPres = `HQPres;
	
	if (`GAME.GetGeoscape().IsScanning())
		HQPres.StrategyMap2D.ToggleScan();

	//call Armory_MainMenu to populate pawn data
	if(HQPres.ScreenStack.IsNotInStack(class'UIArmory_MainMenu'))
		UIArmory_MainMenu(HQPres.ScreenStack.Push(HQPres.Spawn(class'UIArmory_MainMenu', HQPres), HQPres.Get3DMovie())).InitArmory(UnitRef,,,,,, bInstant);


	OfficerScreen = UIArmory_LWOfficerPromotion(HQPres.ScreenStack.Push(HQPres.Spawn(class'UIArmory_LWOfficerPromotion', HQPres), HQPres.Get3DMovie()));
	OfficerScreen.InitPromotion(UnitRef, bInstant);
}
*/
//---------------------------------------------------------------------------------------
DefaultProperties
{
}



/*

class XComGameState_HeadquartersProjectSpecialTraining extends XComGameState_HeadquartersProject;

var() name NewSpecializationName;

//---------------------------------------------------------------------------------------
// Call when you start a new project, NewGameState should be none if not coming from tactical
function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_GameTime TimeState;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;
	ProjectFocus = FocusRef; // Unit
	AuxilaryReference = AuxRef; // Facility
	
	ProjectPointsRemaining = CalculatePointsToTrain();
	InitialProjectPoints = ProjectPointsRemaining;

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ProjectFocus.ObjectID));
	UnitState.SetStatus(eStatus_Training);

	UpdateWorkPerHour(NewGameState);
	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	StartDateTime = TimeState.CurrentTime;

	if (`STRATEGYRULES != none)
	{
		if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(TimeState.CurrentTime, `STRATEGYRULES.GameTime))
		{
			StartDateTime = `STRATEGYRULES.GameTime;
		}
	}
	
	if (MakingProgress())
	{
		SetProjectedCompletionDateTime(StartDateTime);
	}
	else
	{
		// Set completion time to unreachable future
		CompletionDateTime.m_iYear = 9999;
	}
}

function int CalculatePointsToTrain()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	return XComHQ.GetTrainRookieDays() * 24;
}

function int CalculateWorkPerHour(optional XComGameState StartState = none, optional bool bAssumeActive = false)
{
	return 1;
}

function X2SpecialTrainingTemplate GetTrainingSpecializationTemplate()
{
	return class'X2SpecialTrainingTemplateManager'.static.GetSpecialTrainingTemplateManager().FindSpecialTrainingTemplate(NewSpecializationName);
}

function OnProjectCompleted()
{
	local HeadquartersOrderInputContext OrderInput;
	local XComHeadquartersCheatManager CheatMgr;

	OrderInput.OrderType = eHeadquartersOrderType_TrainRookieCompleted; // attempting to hijack Train Rookie to serve as special training
	OrderInput.AcquireObjectReference = self.GetReference();

	class'XComGameStateContext_HeadquartersOrder_STCO'.static.IssueHeadquartersOrder_STCO(OrderInput);

	CheatMgr = XComHeadquartersCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager);
	if (CheatMgr == none || !CheatMgr.bGamesComDemo)
	{
		STCO_UITrainingComplete(ProjectFocus, NewSpecializationName);
	}
}

simulated function STCO_UITrainingComplete(StateObjectReference UnitRef, name SpecializationName)
{
	local DynamicPropertySet PropertySet;
	local XComHQPresentationLayer HQPresLayer;

	HQPresLayer = `HQPRES();

	`log("STCO: Training Complete UI Event");
	class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'USSM_Multiclass', 'USSM_Multiclass', STCO_TrainingCompleteCB, true, true, true, false);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'EventToTrigger', '');
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'MulticlassClass', MulticlassClassName);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'SoundToPlay', "Geoscape_CrewMemberLevelledUp");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
	
	HQPresLayer.QueueDynamicPopup(PropertySet);
}

simulated function STCO_TrainingCompleteCB(Name eAction, out DynamicPropertySet AlertData, optional bool xbInstant = false)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	
	if( eAction == 'eUIAction_Accept' || eAction == 'eUIAction_Cancel' )
	{
		// Flag the new class popup as having been seen
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Promotion Callback");
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit',
																	  class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'UnitRef')));
		UnitState.bNeedsNewClassPopup = false;
		`XEVENTMGR.TriggerEvent('UnitPromoted', , , NewGameState);
		`GAMERULES.SubmitGameState(NewGameState);
	}
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}
*/




/*

class XComGameState_HeadquartersProjectSpecialTraining extends XComGameState_HeadquartersProjectTrainRookie;

function int CalculatePointsToTrain()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	return XComHQ.GetTrainRookieDays() * 24;
	
	//return 24; // DEBUG 
}

function OnProjectCompleted()
{
	local HeadquartersOrderInputContext OrderInput;
	local XComHeadquartersCheatManager CheatMgr;

	OrderInput.OrderType = eHeadquartersOrderType_TrainRookieCompleted;
	OrderInput.AcquireObjectReference = self.GetReference();

	class'XComGameStateContext_HeadquartersOrder_STCO'.static.IssueHeadquartersOrder_USSM(OrderInput);

	CheatMgr = XComHeadquartersCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager);
	if (CheatMgr == none || !CheatMgr.bGamesComDemo)
	{
		USSM_UITrainingComplete(ProjectFocus, NewClassName);
	}
}

simulated function USSM_UITrainingComplete(StateObjectReference UnitRef, name MulticlassClassName)
{
	local DynamicPropertySet PropertySet;
	local XComHQPresentationLayer HQPresLayer;

	HQPresLayer = `HQPRES();

	`log("USSM: Training Complete UI Event");
	class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'USSM_Multiclass', 'USSM_Multiclass', USSM_TrainingCompleteCB, true, true, true, false);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'EventToTrigger', '');
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'MulticlassClass', MulticlassClassName);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'SoundToPlay', "Geoscape_CrewMemberLevelledUp");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
	
	HQPresLayer.QueueDynamicPopup(PropertySet);
}

simulated function USSM_TrainingCompleteCB(Name eAction, out DynamicPropertySet AlertData, optional bool xbInstant = false)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	
	if( eAction == 'eUIAction_Accept' || eAction == 'eUIAction_Cancel' )
	{
		// Flag the new class popup as having been seen
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Promotion Callback");
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit',
																	  class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'UnitRef')));
		UnitState.bNeedsNewClassPopup = false;
		`XEVENTMGR.TriggerEvent('UnitPromoted', , , NewGameState);
		`GAMERULES.SubmitGameState(NewGameState);
	}
}


*/