class SpecialTrainingUtilities extends Object;

// adds a new training component to a soldier and gives them the initial perks
static function AddNewSpecialTrainingComponentTo(XComGameState_Unit UnitState)
{
	`log("STCO: Creating new special training component.");
}

// checks if a soldier already has a training component attached
static function bool DoesUnitHaveSpecialTrainingComponent(XComGameState_Unit UnitState)
{
	return false;
}

// tests if unit is capable of special training; NOT if they can actually recieve some right now
static function bool IsUnitCapableOfSpecialTraining(XComGameState_Unit UnitState)
{
	return UnitState.GetSoldierClassTemplateName() == 'STCO_Soldier';
}

// runs checks to see if unit should have AddNewSpecialTrainingComponentTo called on it
static function bool UnitRequiresSpecialTrainingComponent(XComGameState_Unit UnitState)
{
	return !DoesUnitHaveSpecialTrainingComponent(UnitState) && IsUnitCapableOfSpecialTraining(UnitState);
}