class UIFacility_STCO_AcademySlot extends UIFacility_AcademySlot;

//var localized string m_strTrainMulticlassDialogTitle;
//var localized string m_strTrainMulticlassDialogText;
//var localized string m_strStopTrainMulticlassDialogTitle;
//var localized string m_strStopTrainMulticlassDialogText;

var localized string m_strSpecialTrainingDialogTitle;
var localized string m_strSpecialTrainingDialogText;
var localized string m_strStopSpecialTrainingDialogTitle;
var localized string m_strStopSpecialTrainingDialogText;

simulated function ShowDropDown()
{
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_Unit UnitState;
	local XComGameState_HeadquartersXCom XComHQ;
	//local XComGameState_HeadquartersProjectSpecialTraining TrainProject;
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
/*
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_Unit UnitState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectTrainRookie TrainProject;
	local string StopTrainingText;

	StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));

	if (StaffSlot.IsSlotEmpty())
	{
		StaffContainer.ShowDropDown(self);
	}
	else // Ask the user to confirm that they want to empty the slot and stop training
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		UnitState = StaffSlot.GetAssignedStaff();
		TrainProject = XComHQ.GetTrainRookieProject(UnitState.GetReference());

		if (class'UIChooseClass_STCO'.static.IsUSSMProject(UnitState)) {
			StopTrainingText = m_strStopTrainMulticlassDialogText;
			StopTrainingText = Repl(StopTrainingText, "%UNITNAME", UnitState.GetName(eNameType_RankFull));
			StopTrainingText = Repl(StopTrainingText, "%CLASSNAME", TrainProject.GetTrainingClassTemplate().DisplayName);

			ConfirmEmptyProjectSlotPopup(m_strStopTrainMulticlassDialogTitle, StopTrainingText);
		} else {
			StopTrainingText = m_strStopTrainRookieDialogText;
			StopTrainingText = Repl(StopTrainingText, "%UNITNAME", UnitState.GetName(eNameType_RankFull));
			StopTrainingText = Repl(StopTrainingText, "%CLASSNAME", TrainProject.GetTrainingClassTemplate().DisplayName);

			ConfirmEmptyProjectSlotPopup(m_strStopTrainRookieDialogTitle, StopTrainingText);
		}
	}
	*/
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
/*
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

	DialogData.eType = eDialog_Alert;

	DialogData.fnCallbackEx = USSM_TrainDialogCallback;
	
	if (class'UIChooseClass_STCO'.static.IsUSSMProject(Unit)) {
		DialogData.strTitle = m_strTrainMulticlassDialogTitle;
		DialogData.strText = `XEXPAND.ExpandString(m_strTrainMulticlassDialogText);
	} else {
		DialogData.strTitle = m_strTrainRookieDialogTitle;
		DialogData.strText = `XEXPAND.ExpandString(m_strTrainRookieDialogText);
	}
	
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog(DialogData);
	*/
}

simulated function SpecialTrainingDialogCallback(Name eAction, UICallbackData xUserData)
{
	local UICallbackData_StateObjectReference CallbackData;
	
	CallbackData = UICallbackData_StateObjectReference(xUserData);
	
	if (eAction == 'eUIAction_Accept')
	{
		//`HQPRES.UIChooseClass(CallbackData.ObjectRef);
		STCO_HQUIChooseClass(CallbackData.ObjectRef);
	}
}

function STCO_HQUIChooseClass(StateObjectReference UnitRef)
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