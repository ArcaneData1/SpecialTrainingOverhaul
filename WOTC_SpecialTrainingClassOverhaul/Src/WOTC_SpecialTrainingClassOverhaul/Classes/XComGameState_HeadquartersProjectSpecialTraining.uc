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


