class SpecialTrainingUtilities extends Object config (SpecialTrainingClassOverhaul);

var config array<int> DefaultSpecialTrainingDays;
var config int ExtraDaysForUnexperiencedRookies;
var config name PerkForHackingBonus;
var config int HackingBonusAmount;

// adds a new training component to a soldier and gives them the initial perks
static function XComGameState_Unit_SpecialTraining AddNewSpecialTrainingComponentTo(XComGameState_Unit UnitState, optional XComGameState GameState = none)
{
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState_Unit_SpecialTraining TrainingState;
	local bool ShouldAddStateToHistory;
	local XComGameState_Unit UpdatedUnit;

	ShouldAddStateToHistory = (GameState == none);

	if (GameState == none)
	{
		ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Add Special Training Component");
		GameState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);
	}
	
	UpdatedUnit = XComGameState_Unit(GameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));

	TrainingState = XComGameState_Unit_SpecialTraining(GameState.CreateStateObject(class'XComGameState_Unit_SpecialTraining'));
	TrainingState.Initialize(GameState, UnitState);
	
	GameState.AddStateObject(TrainingState);
	GameState.AddStateObject(UpdatedUnit);

	if (ShouldAddStateToHistory)
		`GAMERULES.SubmitGameState(GameState);

	`log("STCO: Added Special Training component to soldier.");

	return TrainingState;
}

// gets the special training component of a soldier
static function XComGameState_Unit_SpecialTraining GetSpecialTrainingComponentOf(XComGameState_Unit UnitState)
{
	local XComGameState_Unit_SpecialTraining TrainingState;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit_SpecialTraining', TrainingState)
	{
		if (TrainingState.ParentUnitIs(UnitState))
			return TrainingState;
	}
	return none;
}

// runs checks to see if unit should have AddNewSpecialTrainingComponentTo called on it
static function bool UnitRequiresSpecialTrainingComponent(XComGameState_Unit UnitState)
{
	return !DoesUnitHaveSpecialTrainingComponent(UnitState) && UnitState.GetSoldierClassTemplateName() == 'STCO_Soldier';
}

// checks if a soldier already has a training component attached
static function bool DoesUnitHaveSpecialTrainingComponent(XComGameState_Unit UnitState)
{
	return GetSpecialTrainingComponentOf(UnitState) != none;
}

// gets the currently-running special training project for the given slot
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

static function float GetSpecialTrainingDays(XComGameState_Unit UnitState)
{
	if (!IsRookieWaitingToTrain(UnitState))
	{
		return `ScaleStrategyArrayInt(default.DefaultSpecialTrainingDays) + default.ExtraDaysForUnexperiencedRookies;
	}
	else
	{
		return `ScaleStrategyArrayInt(default.DefaultSpecialTrainingDays);
	}
}

static function bool IsRookieWaitingToTrain(XComGameState_Unit UnitState)
{
	if (UnitState.IsSoldier() && UnitState.GetRank() == 0 && UnitState.GetTotalNumKills() >= class'X2ExperienceConfig'.static.GetRequiredKills(1))
	{
		return true;
	}
}