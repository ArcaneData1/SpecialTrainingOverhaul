class XComGameState_Unit_SpecialTraining extends XComGameState_BaseObject;

var StateObjectReference UnitRef; // TODO: Make this a protected variable

var array<name> CurrentSpecializations; // TODO: Make this a protected variable as well

function Initialize(XComGameState_Unit ParentUnit)
{
	UnitRef = ParentUnit.GetReference();
}

function XComGameState_Unit GetParentUnit()
{
	return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
}

function AddSpecialization(name SpecializationName)
{
	CurrentSpecializations.AddItem(SpecializationName);
}

function bool HasSpecialization(name SpecializationName)
{
	return CurrentSpecializations.Find(SpecializationName) != INDEX_NONE;
}