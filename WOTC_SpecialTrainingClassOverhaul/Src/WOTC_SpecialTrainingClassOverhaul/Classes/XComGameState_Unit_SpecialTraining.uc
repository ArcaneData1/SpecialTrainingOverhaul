class XComGameState_Unit_SpecialTraining extends XComGameState_BaseObject config (SpecialTrainingClassOverhaul);

var config int MaxMinorSpecializations;
var config int NumberOfRanks;

var protected StateObjectReference UnitRef;
var protected array<name> CurrentSpecializations;
var protected X2SpecializationTemplate LastTrainedSpecialization;

function Initialize(XComGameState UpdateState, XComGameState_Unit ParentUnit)
{
	local X2SoldierClassTemplate NewClassTemplate;
	local XComGameState_DynamicClassTemplatePool TemplatePool;
	
	UnitRef = ParentUnit.GetReference();

	TemplatePool = class'XComGameState_DynamicClassTemplatePool'.static.GetDynamicClassTemplatePool(true);
	TemplatePool = XComGameState_DynamicClassTemplatePool(UpdateState.CreateStateObject(class'XComGameState_DynamicClassTemplatePool', TemplatePool.ObjectID));

	if (TemplatePool != None)
	{
		NewClassTemplate = TemplatePool.GetTemplateFromPool();
		ParentUnit.SetSoldierClassTemplate(NewClassTemplate.DataName);
		UpdateState.AddStateObject(TemplatePool);
	}

	ParentUnit.AbilityTree.Length = 0;
	ParentUnit.AbilityTree.Length = default.NumberOfRanks;
}

function XComGameState_Unit GetParentUnit(optional XComGameState UpdateState)
{
	if (UpdateState == none)
		return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	else
		return XComGameState_Unit(UpdateState.GetGameStateForObjectID(UnitRef.ObjectID));
}

function X2SoldierClassTemplate GetSoldierClassTemplate(optional XComGameState UpdateState)
{
	return GetParentUnit(UpdateState).GetSoldierClassTemplate();
}

function bool ParentUnitIs(XComGameState_Unit UnitState)
{
	return UnitRef.ObjectID == UnitState.ObjectID;
}

function X2SpecializationTemplate GetLastTrainedSpecialization()
{
	return LastTrainedSpecialization;
}

function bool HasSpecialization(name SpecializationName)
{
	return CurrentSpecializations.Find(SpecializationName) != INDEX_NONE;
}

function AddSpecialization(name SpecializationName, optional XComGameState UpdateState)
{
	local X2SpecializationTemplate Specialization;
	local X2SoldierClassTemplate ClassTemplate;
	local int i, Row;

	Specialization = GetSpecializationTemplate(SpecializationName);
	ClassTemplate = GetSoldierClassTemplate(UpdateState);

	// if training core:
	if (CurrentSpecializations.Length == 0)
	{
		Row = 0;
		AddPerksToRow(1, Specialization.CoreAbilities, UpdateState);
		
		ClassTemplate.IconImage = Specialization.IconImage;
		ClassTemplate.DisplayName = Specialization.DisplayName;
	}
	else
	{
		Row = 2 + CurrentSpecializations.Length - 1;
	}

	AddPerksToRow(Row, Specialization.Abilities, UpdateState);

	CurrentSpecializations.AddItem(SpecializationName);
	ClassTemplate.AbilityTreeTitles[Row] = Specialization.DisplayName;

	LastTrainedSpecialization = Specialization;

	for (i = 0; i < Specialization.AllowedPrimaryWeapons.Length; i++)
	{
		ClassTemplate.AllowedWeapons.Add(1);			
		ClassTemplate.AllowedWeapons[ClassTemplate.AllowedWeapons.Length - 1].WeaponType = Specialization.AllowedPrimaryWeapons[i];
		ClassTemplate.AllowedWeapons[ClassTemplate.AllowedWeapons.Length - 1].SlotType = eInvSlot_PrimaryWeapon;
	}

	// buy first perk automatically
	GetParentUnit(UpdateState).BuySoldierProgressionAbility(UpdateState, 0, Row);
}

function UnitHasRankedUp(optional XComGameState UpdateState)
{
	ApplyStatIncreases(UpdateState);
}

function ApplyStatIncreases(optional XComGameState UpdateState) // do not modify: this code is copied from XComGameState_Unit in order to apply correct stat progression
{
	local XComGameState_Unit UnitState;
	local array<SoldierClassStatType> StatProgression;
	local int SoldierRank, i, MaxStat, NewMaxStat, StatVal, NewCurrentStat, StatCap;

	UnitState = GetParentUnit(UpdateState);
	SoldierRank = UnitState.GetRank();
	StatProgression = GetSpecializationAt(0).StatProgressions[SoldierRank - 1].StatProgressionsForRank;

	if (SoldierRank > 0)
	{
		for (i = 0; i < class'X2SoldierClassTemplateManager'.default.GlobalStatProgression.Length; ++i)
		{
			StatProgression.AddItem(class'X2SoldierClassTemplateManager'.default.GlobalStatProgression[i]);
		}
	}

	for (i = 0; i < StatProgression.Length; ++i)
	{
		StatVal = StatProgression[i].StatAmount;
		//  add random amount if any
		if (StatProgression[i].RandStatAmount > 0)
		{
			StatVal += `SYNC_RAND(StatProgression[i].RandStatAmount);
		}

		if((StatProgression[i].StatType == eStat_HP) && `SecondWaveEnabled('BetaStrike' ))
		{
			StatVal *= class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthMod;
		}

		MaxStat = UnitState.GetMaxStat(StatProgression[i].StatType);
		//  cap the new value if required
		if (StatProgression[i].CapStatAmount > 0)
		{
			StatCap = StatProgression[i].CapStatAmount;

			if((i == eStat_HP) && `SecondWaveEnabled('BetaStrike' ))
			{
				StatCap *= class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthMod;
			}

			if (StatVal + MaxStat > StatCap)
				StatVal = StatCap - MaxStat;
		}

		// If the Soldier has been shaken, save any will bonus from ranking up to be applied when they recover
		if (StatProgression[i].StatType == eStat_Will && UnitState.bIsShaken)
		{
			UnitState.SavedWillValue += StatVal;
		}
		else
		{				
			NewMaxStat = MaxStat + StatVal;
			NewCurrentStat = int(UnitState.GetCurrentStat(StatProgression[i].StatType)) + StatVal;
			UnitState.SetBaseMaxStat(StatProgression[i].StatType, NewMaxStat);
			if (StatProgression[i].StatType != eStat_HP || !UnitState.IsInjured())
			{
				UnitState.SetCurrentStat(StatProgression[i].StatType, NewCurrentStat);
			}
		}
	}
}

function bool CanReceiveTraining()
{
	return CurrentSpecializations.Length < MaxMinorSpecializations + 1;
}

function bool HasExcludingSpecializationTo(X2SpecializationTemplate Template)
{
	local name ExcludedSpecName, CurrentSpecName;

	foreach Template.DisallowedSpecs(ExcludedSpecName)
	{
		foreach CurrentSpecializations(CurrentSpecName)
		{
			if (ExcludedSpecName == CurrentSpecName)
			{
				return true;
			}
		}
	}
	return false;
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
	SpecializationTemplateManager = class'X2SpecializationTemplateManager'.static.GetInstance();
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

protected function AddPerksToRow(int row, array<SoldierClassAbilityType> Abilities, optional XComGameState UpdateState)
{
	local XComGameState_Unit ParentUnit;
	local int i;

	ParentUnit = GetParentUnit(UpdateState);

	for (i = 0; i < default.NumberOfRanks; i++)
	{
		ParentUnit.AbilityTree[i].Abilities[row] = Abilities[i];
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