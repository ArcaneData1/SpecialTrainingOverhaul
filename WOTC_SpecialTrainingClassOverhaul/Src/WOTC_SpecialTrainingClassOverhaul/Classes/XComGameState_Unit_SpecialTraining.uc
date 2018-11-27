class XComGameState_Unit_SpecialTraining extends XComGameState_BaseObject;

var protected StateObjectReference UnitRef;

var protected array<name> CurrentSpecializations;

function Initialize(XComGameState_Unit ParentUnit)
{
	UnitRef = ParentUnit.GetReference();
}

function XComGameState_Unit GetParentUnit()
{
	return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
}

function bool ParentUnitIs(XComGameState_Unit UnitState)
{
	return UnitRef.ObjectID == UnitState.ObjectID;
}

function AddSpecialization(name SpecializationName)
{
	AddSpecializationToRow(GetSpecializationTemplate(SpecializationName).Abilities, 0);

	CurrentSpecializations.AddItem(SpecializationName);
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
	ParentUnit.AbilityTree.Length = Abilities.Length;

	for (i = 0; i < Abilities.Length; i++)
	{
		ParentUnit.AbilityTree[i].Abilities[row] = Abilities[i];
	}
}