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

function XComGameState_Unit GetParentUnit(optional XComGameState UpdateState)
{
	if (UpdateState == none)
		return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	else
		return XComGameState_Unit(UpdateState.GetGameStateForObjectID(UnitRef.ObjectID));
}

function bool ParentUnitIs(XComGameState_Unit UnitState)
{
	return UnitRef.ObjectID == UnitState.ObjectID;
}

function X2SpecializationTemplate GetLastTrainedSpecialization()
{
	return LastTrainedSpecialization;
}

function AddSpecialization(name SpecializationName, optional XComGameState UpdateState)
{
	`log("STCO: Adding specialization.");

	AddSpecializationToRow(GetSpecializationTemplate(SpecializationName).Abilities, 0, UpdateState);

	//CurrentSpecializations.AddItem(SpecializationName);
	CurrentSpecializations[0] = SpecializationName;

	LastTrainedSpecialization = GetSpecializationTemplate(SpecializationName);

	`log("STCO: Finished adding specialization. New count: " $ CurrentSpecializations.Length);
}

function X2SpecializationTemplate GetSpecializationAt(int index)
{
	return GetSpecializationTemplate(CurrentSpecializations[index]);
}

function array<name> GetAllowedSlots()
{
	local name SpecializationName;
	local X2SpecializationTemplate Template;
	local name SlotName;
	local array<name> AllowedSlots;

	foreach CurrentSpecializations(SpecializationName)
	{
		Template = GetSpecializationTemplate(SpecializationName);

		foreach Template.AllowedSlots(SlotName)
		{
			AllowedSlots.AddItem(SlotName);
		}
	}

	return AllowedSlots;
}

protected function X2SpecializationTemplate GetSpecializationTemplate(name SpecializationName)
{
	local X2SpecializationTemplateManager SpecializationTemplateManager;
	SpecializationTemplateManager = class'X2SpecializationTemplateManager'.static.GetSpecializationTemplateManager();
	return SpecializationTemplateManager.FindSpecializationTemplate(SpecializationName);
}

protected function AddSpecializationToRow(array<SoldierClassAbilityType> Abilities, int row, optional XComGameState UpdateState)
{
	local XComGameState_Unit ParentUnit;
	local int i;

	`log("STCO: Beginning AddSpecializationToRow function...");

	ParentUnit = GetParentUnit(UpdateState);

	`log("STCO: Got parent unit.");

	if (Abilities.Length > ParentUnit.AbilityTree.Length)
	{	
		`log("STCO: Increasing ability tree length.");
		ParentUnit.AbilityTree.Length = Abilities.Length;
	}

	for (i = 0; i < Abilities.Length; i++)
	{
		`log("STCO: Adding a new ability...");
		ParentUnit.AbilityTree[i].Abilities[row] = Abilities[i];
	}
	
	`log("STCO: Done!");
}