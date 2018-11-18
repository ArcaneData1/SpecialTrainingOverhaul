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