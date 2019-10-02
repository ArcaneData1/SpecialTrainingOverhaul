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
	return int(class'SpecialTrainingUtilities'.static.GetSpecialTrainingDays() * 24.0);
	//return int(class'LWOfficerUtilities'.static.GetOfficerTrainingDays(NewRank) * 24.0);
	//local XComGameStateHistory History;
	//local XComGameState_HeadquartersXCom XComHQ;

	//History = `XCOMHISTORY;
	//XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	//return XComHQ.GetTrainRookieDays() * 24;
}

//---------------------------------------------------------------------------------------
function int CalculateWorkPerHour(optional XComGameState StartState = none, optional bool bAssumeActive = false)
{
	return 1;
}

function X2SpecializationTemplate GetTrainingSpecializationTemplate()
{
	return class'X2SpecializationTemplateManager'.static.GetInstance().FindSpecializationTemplate(NewSpecializationName);
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
	local XComGameState_Unit_SpecialTraining TrainingState;
	local XComGameState UpdateState;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState_HeadquartersProjectSpecialTraining ProjectState;
	local XComGameState_StaffSlot StaffSlotState;

	History = `XCOMHISTORY;
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectFocus.ObjectID));
	
	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Special Training Complete");
	UpdateState = History.CreateNewGameState(true, ChangeContainer);
	UpdatedUnit = XComGameState_Unit(UpdateState.CreateStateObject(class'XComGameState_Unit', Unit.ObjectID));

	if (UpdatedUnit.GetRank() == 0)
	{
		UpdatedUnit.RankUpSoldier(UpdateState, 'STCO_Soldier');
		TrainingState = class'SpecialTrainingUtilities'.static.AddNewSpecialTrainingComponentTo(UpdatedUnit, UpdateState);
	}
	else
	{
		TrainingState = class'SpecialTrainingUtilities'.static.GetSpecialTrainingComponentOf(Unit);
	}

	TrainingState = XComGameState_Unit_SpecialTraining(UpdateState.CreateStateObject(class'XComGameState_Unit_SpecialTraining', TrainingState.ObjectID));

	TrainingState.AddSpecialization(NewSpecializationName, UpdateState);

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
	UpdateState.AddStateObject(TrainingState);
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
	local UIAlert_SpecialTrainingComplete Alert;
	local XComHQPresentationLayer HQPres;

	HQPres = `HQPres;

	Alert = HQPres.Spawn(class'UIAlert_SpecialTrainingComplete', HQPres);
	Alert.eAlertName = 'eAlert_TrainingComplete';
	Alert.DisplayPropertySet.SecondaryRoutingKey = Alert.eAlertName;
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(Alert.DisplayPropertySet, 'UnitRef', UnitRef.ObjectID);
	Alert.DisplayPropertySet.CallbackFunction = TrainingCompleteCB;
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(Alert.DisplayPropertySet, 'SoundToPlay', "Geoscape_CrewMemberLevelledUp");
	HQPres.ScreenStack.Push(Alert);

}

simulated function TrainingCompleteCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstants = false)
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