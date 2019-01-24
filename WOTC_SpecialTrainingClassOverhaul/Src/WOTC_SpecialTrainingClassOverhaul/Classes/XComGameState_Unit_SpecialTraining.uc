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
	CurrentSpecializations.AddItem(SpecializationName);

	LastTrainedSpecialization = GetSpecializationTemplate(SpecializationName);

	// TODO: make sure there is room for new row, and order row by primary first, then secondaries in alphebetical

	RegeneratePerks(UpdateState);
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

protected function RegeneratePerks(optional XComGameState UpdateState)
{
	local XComGameState_Unit ParentUnit;
	local X2SpecializationTemplate Specialization;
	local int a, b;

	ParentUnit = GetParentUnit(UpdateState);

	ParentUnit.AbilityTree.Length = 0;
	ParentUnit.AbilityTree.Length = 7; // TODO: Make this configurable

	for (a = 0; a < CurrentSpecializations.Length; a++)
	{
		Specialization = GetSpecializationTemplate(CurrentSpecializations[a]);

		for (b = 0; b < Specialization.Abilities.Length; b++)
		{
			ParentUnit.AbilityTree[b].Abilities[a] = Specialization.Abilities[b];
		}
	}
}