class XComGameState_Unit_SpecialTraining extends XComGameState_BaseObject config (SpecialTrainingClassOverhaul);

var config int MaxSpecializations;
var config int NumberOfRanks;
var config array<name> DefaultSpecializations;

var protected StateObjectReference UnitRef;
var protected array<name> CurrentSpecializations;
var protected X2SpecializationTemplate LastTrainedSpecialization;

function Initialize(XComGameState_Unit ParentUnit)
{
	local name SpecializationName;

	UnitRef = ParentUnit.GetReference();
	
	ParentUnit.AbilityTree.Length = 0;

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

function bool CanReceiveTraining()
{
	return GetSpecializationAt(0).CanBeReplaced;
}

function array<X2SpecializationTemplate> GetCurrentSpecializations()
{
	local name SpecializationName;
	local array<X2SpecializationTemplate> Specializations;

	foreach CurrentSpecializations(SpecializationName)
	{
		Specializations.AddItem(GetSpecializationTemplate(SpecializationName));
	}

	return Specializations;
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

protected function ClearPerksFromRow(int row, optional XComGameState UpdateState)
{
	local XComGameState_Unit ParentUnit;
	local int i, RefundedPoints;

	ParentUnit = GetParentUnit(UpdateState);

	for (i = 0; i < ParentUnit.AbilityTree.Length; i++)
	{
		if (ParentUnit.HasSoldierAbility(ParentUnit.AbilityTree[i].Abilities[row].AbilityName))
		{		
			ParentUnit.RemoveSoldierProgressionAbility(i, row);
			RefundedPoints += GetAbilityPointCost(i, row, UpdateState);		
		}
	}

	if (RefundedPoints > 0)
	{	
		ParentUnit.AbilityPoints += RefundedPoints;	
		ParentUnit.SpentAbilityPoints -= RefundedPoints;
		`XEVENTMGR.TriggerEvent('AbilityPointsChange', self, , UpdateState);
	}
}

protected function RegeneratePerks(optional XComGameState UpdateState)
{
	local XComGameState_Unit ParentUnit;
	local X2SpecializationTemplate Specialization;
	local int a, b;

	ParentUnit = GetParentUnit(UpdateState);

	ParentUnit.AbilityTree.Length = 0;
	ParentUnit.AbilityTree.Length = default.NumberOfRanks;

	for (a = 0; a < CurrentSpecializations.Length; a++)
	{
		Specialization = GetSpecializationTemplate(CurrentSpecializations[a]);

		for (b = 0; b < Specialization.Abilities.Length; b++)
		{
			ParentUnit.AbilityTree[b].Abilities[a] = Specialization.Abilities[b];
		}
	}
}

// Do not modify: this is copied from UIArmory_PromotionHero in order to refund the correct amount of points
function int GetAbilityPointCost(int Rank, int Branch, optional XComGameState UpdateState)
{
	local XComGameState_Unit UnitState;
	local array<SoldierClassAbilityType> AbilityTree;
	local bool bPowerfulAbility;

	UnitState = GetParentUnit(UpdateState);
	AbilityTree = UnitState.GetRankAbilities(Rank);
	bPowerfulAbility = (class'X2StrategyGameRulesetDataStructures'.default.PowerfulAbilities.Find(AbilityTree[Branch].AbilityName) != INDEX_NONE);

	if (bPowerfulAbility || (Rank >= 6 && Branch < 3))
	{
		return class'X2StrategyGameRulesetDataStructures'.default.PowerfulAbilityPointCost;
	}
	
	return class'X2StrategyGameRulesetDataStructures'.default.AbilityPointCosts[Rank];
}