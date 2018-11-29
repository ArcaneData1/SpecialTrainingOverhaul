class XComGameState_Unit_SpecialTraining extends XComGameState_BaseObject config (SpecialTrainingClassOverhaul);

var config array<name> DefaultSpecializations;

var protected StateObjectReference UnitRef;
var protected array<name> CurrentSpecializations;
var protected X2SpecializationTemplate LastTrainedSpecialization;

function Initialize(XComGameState_Unit ParentUnit)
{
	local name SpecializationName;

	UnitRef = ParentUnit.GetReference();
	
	ParentUnit.AbilityTree.Length = 0; // TODO: turn this into function and make sure to reset soldier properly, like removing any obtained perks

	foreach default.DefaultSpecializations(SpecializationName)
	{
		AddSpecialization(SpecializationName);
	}
}

function XComGameState_Unit GetParentUnit()
{
	return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
}

function bool ParentUnitIs(XComGameState_Unit UnitState)
{
	return UnitRef.ObjectID == UnitState.ObjectID;
}

function X2SpecializationTemplate GetLastTrainedSpecialization()
{
	return LastTrainedSpecialization;
}

function AddSpecialization(name SpecializationName)
{
	`log("STCO: Adding specialization.");

	AddSpecializationToRow(GetSpecializationTemplate(SpecializationName).Abilities, 0);

	//CurrentSpecializations.AddItem(SpecializationName);
	CurrentSpecializations[0] = SpecializationName;

	LastTrainedSpecialization = GetSpecializationTemplate(SpecializationName);

	`log("STCO: Finished adding specialization. New count: " $ CurrentSpecializations.Length);
}

function X2SpecializationTemplate GetSpecializationAt(int index)
{
	return GetSpecializationTemplate(CurrentSpecializations[index]);
}

protected function X2SpecializationTemplate GetSpecializationTemplate(name SpecializationName)
{
	local X2SpecializationTemplateManager SpecializationTemplateManager;
	SpecializationTemplateManager = class'X2SpecializationTemplateManager'.static.GetSpecializationTemplateManager();
	return SpecializationTemplateManager.FindSpecializationTemplate(SpecializationName);
}

protected function AddSpecializationToRow(array<SoldierClassAbilityType> Abilities, int row)
{
	local XComGameState_Unit ParentUnit;
	local int i;

	ParentUnit = GetParentUnit();

	ParentUnit.AbilityTree.Length = 0;

	if (Abilities.Length > ParentUnit.AbilityTree.Length)
		ParentUnit.AbilityTree.Length = Abilities.Length;

	for (i = 0; i < Abilities.Length; i++)
	{
		ParentUnit.AbilityTree[i].Abilities[row] = Abilities[i];
	}
}