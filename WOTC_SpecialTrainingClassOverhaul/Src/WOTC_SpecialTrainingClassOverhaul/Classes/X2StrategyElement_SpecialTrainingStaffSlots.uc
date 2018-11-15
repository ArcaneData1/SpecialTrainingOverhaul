class X2StrategyElement_SpecialTrainingStaffSlots extends X2StrategyElement_DefaultStaffSlots;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> StaffSlots;

	StaffSlots.AddItem(CreateUSSMOTSStaffSlotTemplate());

	return StaffSlots;
}

static function X2DataTemplate CreateUSSMOTSStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	Template = CreateStaffSlotTemplate('USSM_OTSStaffSlot');
	Template.bSoldierSlot = true;
	Template.bRequireConfirmToEmpty = true;
	Template.bPreventFilledPopup = true;
	Template.UIStaffSlotClass = class'UIFacility_STCO_AcademySlot';
	Template.FillFn = USSM_FillOTSSlot;
	Template.EmptyStopProjectFn = EmptyStopProjectOTSSoldierSlot;
	Template.ShouldDisplayToDoWarningFn = ShouldDisplayOTSSoldierToDoWarning;
	Template.GetSkillDisplayStringFn = GetOTSSkillDisplayString;
	Template.GetBonusDisplayStringFn = GetOTSBonusDisplayString;
	Template.IsUnitValidForSlotFn = USSM_IsUnitValidForOTSSoldierSlot;
	Template.MatineeSlotName = "Soldier";

	return Template;
}

static function USSM_FillOTSSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo, optional bool bTemporary = false)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_HeadquartersProjectTrainRookie ProjectState;
	local StateObjectReference EmptyRef;
	local int SquadIndex;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);
	
	// create USSM training project or rookie training project
	if (class'UIChooseClass_STCO'.static.IsUSSMProject(NewUnitState)) {
		ProjectState = XComGameState_HeadquartersProjectTrainRookie(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectTrain_USSM'));
	} else {
		ProjectState = XComGameState_HeadquartersProjectTrainRookie(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectTrainRookie'));
	}
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

static function bool USSM_IsUnitValidForOTSSoldierSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local int UnitRank;
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	
	if (Unit.CanBeStaffed()
		&& Unit.IsSoldier()
		&& Unit.IsActive()
		&& SlotState.GetMyTemplate().ExcludeClasses.Find(Unit.GetSoldierClassTemplateName()) == INDEX_NONE)
	{
		UnitRank = Unit.GetRank();
		if (UnitRank == 0 && !Unit.CanRankUpSoldier()) {
			return true;
		}

		if (UnitRank >= 3 && IsTrainableClass(Unit.GetSoldierClassTemplateName()))
		{
			// check for a multiclass ability
			if (Unit.AbilityTree[2].Abilities.Length >= 4)
			{
				return false;
			}

			return true;
		}
	}

	return false;
}

static function bool IsTrainableClass(name UnitClassName) {
	local name className;
	foreach class'X2Ability_STCO'.default.AllowedClasses(className) {
		if (className == UnitClassName) {
			return true;
		}
	}

	return false;
}