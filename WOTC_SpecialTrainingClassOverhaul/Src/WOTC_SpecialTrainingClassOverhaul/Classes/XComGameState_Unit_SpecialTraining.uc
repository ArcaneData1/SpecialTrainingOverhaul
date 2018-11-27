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
	AddSpecializationToRow(SpecializationName, 0);

	CurrentSpecializations.AddItem(SpecializationName);
}

function bool HasSpecialization(name SpecializationName)
{
	return CurrentSpecializations.Find(SpecializationName) != INDEX_NONE;
}

function X2SpecializationTemplate GetSpecializationAt(int index)
{
	local X2SpecializationTemplateManager SpecializationTemplateManager;

	SpecializationTemplateManager = class'X2SpecializationTemplateManager'.static.GetSpecializationTemplateManager();

	return SpecializationTemplateManager.FindSpecializationTemplate(CurrentSpecializations[index]);
}

protected function AddSpecializationToRow(name SpecializationName, int row)
{
	local X2SpecializationTemplateManager SpecializationManager;
	local X2SpecializationTemplate Specialization;
	local XComGameState_Unit ParentUnit;
	local SoldierRankAbilities RankAbilities;
	local int i;

	SpecializationManager = class'X2SpecializationTemplateManager'.static.GetSpecializationTemplateManager();
	Specialization = SpecializationManager.FindSpecializationTemplate(SpecializationName);

	ParentUnit = GetParentUnit();

	ParentUnit.AbilityTree.Length = 0;
	ParentUnit.AbilityTree.Length = Specialization.Abilities.Length;

	for (i = 0; i < Specialization.Abilities.Length; i++)
	{
		ParentUnit.AbilityTree[i].Abilities[row] = Specialization.Abilities[i];
	}
}