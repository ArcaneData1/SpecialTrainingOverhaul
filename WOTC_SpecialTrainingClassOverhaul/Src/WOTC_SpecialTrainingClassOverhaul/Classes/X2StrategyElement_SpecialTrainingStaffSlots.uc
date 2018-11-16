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

	Template = CreateStaffSlotTemplate('STCO_SecondaryTrainingStaffSlot');
	Template.bSoldierSlot = true;
	Template.bRequireConfirmToEmpty = true;
	Template.bPreventFilledPopup = true;
	Template.UIStaffSlotClass = class'UIFacility_STCO_AcademySlot';
	Template.FillFn = STCO_FillOTSSlot;
	Template.EmptyStopProjectFn = EmptyStopProjectOTSSoldierSlot;
	Template.ShouldDisplayToDoWarningFn = ShouldDisplayOTSSoldierToDoWarning;
	Template.GetSkillDisplayStringFn = GetOTSSkillDisplayString;
	Template.GetBonusDisplayStringFn = GetOTSBonusDisplayString;
	Template.IsUnitValidForSlotFn = STCO_IsUnitValidForOTSSoldierSlot;
	Template.MatineeSlotName = "Soldier";

	return Template;
}

static function STCO_FillOTSSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo, optional bool bTemporary = false)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_HeadquartersProjectTrainRookie ProjectState;
	local StateObjectReference EmptyRef;
	local int SquadIndex;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);
	
	ProjectState = XComGameState_HeadquartersProjectTrainRookie(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectSpecialTraining'));
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

static function bool STCO_IsUnitValidForOTSSoldierSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	return (
		Unit.CanBeStaffed()	&& 
		Unit.IsSoldier() &&
		Unit.IsActive() &&
		!Unit.CanRankUpSoldier() &&
		SlotState.GetMyTemplate().ExcludeClasses.Find(Unit.GetSoldierClassTemplateName()) == INDEX_NONE);
	/*
	if (Unit.CanBeStaffed()
		&& Unit.IsSoldier()
		&& Unit.IsActive()
		&& !Unit.CanRankUpSoldier()
		&& SlotState.GetMyTemplate().ExcludeClasses.Find(Unit.GetSoldierClassTemplateName()) == INDEX_NONE)
	{
		return true;
	}

	return false;
	*/
}