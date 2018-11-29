class UIFacility_SpecialTrainingSlot extends UIFacility_StaffSlot
	dependson(UIPersonnel);
	
var localized string m_strSpecialTrainingDialogTitle;
var localized string m_strSpecialTrainingDialogText;
var localized string m_strStopSpecialTrainingDialogTitle;
var localized string m_strStopSpecialTrainingDialogText;
var localized string m_strNoCandidatesTooltip;
var localized string m_strCandidatesAvailableTooltip;

simulated function UIStaffSlot InitStaffSlot(UIStaffContainer OwningContainer, StateObjectReference LocationRef, int SlotIndex, delegate<OnStaffUpdated> onStaffUpdatedDel)
{
	super.InitStaffSlot(OwningContainer, LocationRef, SlotIndex, onStaffUpdatedDel);
	
	return self;
}

//-----------------------------------------------------------------------------
simulated function ShowDropDown()
{
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_Unit UnitState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectSpecialTraining TrainProject;
	local string StopTrainingText;

	StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));

	if (StaffSlot.IsSlotEmpty())
	{
		StaffContainer.ShowDropDown(self);
	}
	else // Ask the user to confirm that they want to empty the slot and stop training
	{
		//XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		UnitState = StaffSlot.GetAssignedStaff();
		//TrainProject = XComHQ.GetTrainRookieProject(UnitState.GetReference());

		StopTrainingText = m_strStopSpecialTrainingDialogText;
		StopTrainingText = Repl(StopTrainingText, "%UNITNAME", UnitState.GetName(eNameType_RankFull));
		//StopTrainingText = Repl(StopTrainingText, "%CLASSNAME", TrainProject.GetTrainingClassTemplate().DisplayName);

		ConfirmEmptyProjectSlotPopup(m_strStopSpecialTrainingDialogTitle, StopTrainingText);
	}
}

simulated function OnPersonnelSelected(StaffUnitInfo UnitInfo)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XGParamTag LocTag;
	local TDialogueBoxData DialogData;
	local XComGameState_Unit Unit;
	local UICallbackData_StateObjectReference CallbackData;

	History = `XCOMHISTORY;
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = Unit.GetName(eNameType_RankFull);
	LocTag.StrValue1 = class'X2ExperienceConfig'.static.GetRankName((Unit.GetRank() + 1 + XComHQ.BonusTrainingRanks), '');

	CallbackData = new class'UICallbackData_StateObjectReference';
	CallbackData.ObjectRef = Unit.GetReference();
	DialogData.xUserData = CallbackData;
	DialogData.fnCallbackEx = SpecialTrainingDialogCallback;

	DialogData.eType = eDialog_Alert;
	DialogData.strTitle = m_strSpecialTrainingDialogTitle;
	DialogData.strText = `XEXPAND.ExpandString(m_strSpecialTrainingDialogText);
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog(DialogData);
}

simulated function SpecialTrainingDialogCallback(Name eAction, UICallbackData xUserData)
{
	local UICallbackData_StateObjectReference CallbackData;
	
	CallbackData = UICallbackData_StateObjectReference(xUserData);
	
	if (eAction == 'eUIAction_Accept')
	{
		CreateChooseSpecializationUI(CallbackData.ObjectRef);
	}
}

function CreateChooseSpecializationUI(StateObjectReference UnitRef)
{
	local XComHQPresentationLayer HQPresLayer;

	HQPresLayer = `HQPRES();

	if (HQPresLayer.ScreenStack.IsNotInStack(class'UIChooseSpecialization'))
	{
		HQPresLayer.TempScreen = Spawn(class'UIChooseSpecialization', self);
		UIChooseSpecialization(HQPresLayer.TempScreen).m_UnitRef = UnitRef;
		HQPresLayer.ScreenStack.Push(HQPresLayer.TempScreen, HQPresLayer.Get3DMovie());
	}
}

//==============================================================================

defaultproperties
{
	width = 370;
	height = 65;
}