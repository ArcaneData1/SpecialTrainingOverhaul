class X2StrategyElement_SpecialTrainingStaffSlots extends X2StrategyElement_DefaultStaffSlots;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> StaffSlots;

	StaffSlots.AddItem(CreateSpecialTrainingStaffSlotTemplate());

	return StaffSlots;
}

static function X2DataTemplate CreateSpecialTrainingStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	Template = CreateStaffSlotTemplate('STCO_SpecialTrainingStaffSlot');
	Template.bSoldierSlot = true;
	Template.bRequireConfirmToEmpty = true;
	Template.bPreventFilledPopup = true;
	Template.UIStaffSlotClass = class'UIFacility_SpecialTrainingSlot';
	Template.FillFn = STCO_FillOTSSlot;
	Template.EmptyStopProjectFn = STCO_EmptyStopProjectOTSSoldierSlot;
	//Template.ShouldDisplayToDoWarningFn = STCO_ShouldDisplayOTSSoldierToDoWarning;
	Template.ShouldDisplayToDoWarningFn = ShouldDisplayOTSSoldierToDoWarning;
	//Template.GetSkillDisplayStringFn = STCO_GetOTSSkillDisplayString;
	Template.GetBonusDisplayStringFn = STCO_GetOTSBonusDisplayString;
	Template.GetSkillDisplayStringFn = GetOTSSkillDisplayString;
	//Template.GetBonusDisplayStringFn = GetOTSBonusDisplayString;
	Template.IsUnitValidForSlotFn = STCO_IsUnitValidForOTSSoldierSlot;
	Template.MatineeSlotName = "Soldier";

	return Template;
}

static function STCO_FillOTSSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo, optional bool bTemporary = false)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_HeadquartersProjectSpecialTraining ProjectState;
	local StateObjectReference EmptyRef;
	local int SquadIndex;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);
	
	ProjectState = XComGameState_HeadquartersProjectSpecialTraining(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectSpecialTraining'));
	ProjectState.SetProjectFocus(UnitInfo.UnitRef, NewGameState, NewSlotState.Facility);

	NewUnitState.SetStatus(eStatus_Training);
	NewXComHQ.Projects.AddItem(ProjectState.GetReference());

	// Remove their gear
	NewUnitState.MakeItemsAvailable(NewGameState, false);
	
	// If the unit undergoing training is in the squad, remove them
	SquadIndex = NewXComHQ.Squad.Find('ObjectID', UnitInfo.UnitRef.ObjectID);
	if (SquadIndex != INDEX_NONE)
	{
		// Remove them from the squad
		NewXComHQ.Squad[SquadIndex] = EmptyRef;
	}
}

static function STCO_EmptyStopProjectOTSSoldierSlot(StateObjectReference SlotRef)
{
	local HeadquartersOrderInputContext OrderInput;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectSpecialTraining TrainingProject;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	SlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(SlotRef.ObjectID));

	TrainingProject = XComGameState_HeadquartersProjectSpecialTraining(XComHQ.GetTrainRookieProject(SlotState.GetAssignedStaffRef()));
	if (TrainingProject != none)
	{
		OrderInput.OrderType = eHeadquartersOrderType_CancelTrainRookie;
		OrderInput.AcquireObjectReference = TrainingProject.GetReference();

		class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);
	}
}

static function bool STCO_ShouldDisplayOTSSoldierToDoWarning(StateObjectReference SlotRef)
{
	return false;
}

static function string STCO_GetOTSSkillDisplayString(XComGameState_StaffSlot SlotState)
{
	return "";
}

static function string STCO_GetOTSBonusDisplayString(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
	local XComGameState_HeadquartersProjectSpecialTraining TrainProject;
	local string Contribution;

	if (SlotState.IsSlotFilled())
	{
		TrainProject = GetSpecialTrainingProject(SlotState);
		//Contribution = Caps(TrainProject.NewSpecializationName());
		Contribution = "NOW TRAINING";
	}

	return GetBonusDisplayString(SlotState, "%SKILL", Contribution);
}

static function bool STCO_IsUnitValidForOTSSoldierSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	return (
		Unit.CanBeStaffed() &&
		Unit.IsActive() &&
		class'SpecialTrainingUtilities'.static.CanUnitReceiveSpecialTraining(Unit));
}

static function XComGameState_HeadquartersProjectSpecialTraining GetSpecialTrainingProject(XComGameState_StaffSlot SlotState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectSpecialTraining TrainProject;
	local int idx;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	for (idx = 0; idx < XComHQ.Projects.Length; idx++)
	{
		TrainProject = XComGameState_HeadquartersProjectSpecialTraining(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));

		if (TrainProject != none)
		{
			if (SlotState.GetAssignedStaffRef() == TrainProject.ProjectFocus)
			{
				return TrainProject;
			}
		}
	}
}