class XComGameState_Unit_SpecialTraining extends XComGameState_BaseObject config (SpecialTrainingClassOverhaul);

var config array<name> DefaultSpecializations;

var protected StateObjectReference UnitRef;
var protected array<name> CurrentSpecializations;
var protected X2SpecializationTemplate LastTrainedSpecialization;

function Initialize(XComGameState_Unit ParentUnit)
{
	local name SpecializationName;

	UnitRef = ParentUnit.GetReference();

	//for (i = 0; i < ParentUnit.AbilityTree.Length; i++)
	//{
	//	ParentUnit.AbilityTree[i].Abilities[row] = Abilities[i];
	//}
	
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
	AddSpecializationToRow(GetSpecializationTemplate(SpecializationName).Abilities, 0, UpdateState);

	CurrentSpecializations[0] = SpecializationName;

	LastTrainedSpecialization = GetSpecializationTemplate(SpecializationName);
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

	ParentUnit = GetParentUnit(UpdateState);

	//ClearPerkRow(row, UpdateState);

	if (Abilities.Length > ParentUnit.AbilityTree.Length)
	{	
		ParentUnit.AbilityTree.Length = Abilities.Length;
	}

	for (i = 0; i < Abilities.Length; i++)
	{
		ParentUnit.AbilityTree[i].Abilities[row] = Abilities[i];
	}
}
/*
protected function ClearPerkRow(int row, optional XComGameState UpdateState)
{	
	local XComGameState_Unit ParentUnit;
	local int i;

	ParentUnit = GetParentUnit(UpdateState);

	for (i = 0; i < Abilities.Length; i++)
	{
		ParentUnit.AbilityTree[i].Abilities[row]
	}
}
*/