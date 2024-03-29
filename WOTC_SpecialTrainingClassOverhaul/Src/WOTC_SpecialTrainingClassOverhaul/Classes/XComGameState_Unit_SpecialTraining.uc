class XComGameState_Unit_SpecialTraining extends XComGameState_BaseObject config (SpecialTrainingClassOverhaul);

var config int MaxMinorSpecializations;
var config int NumberOfRanks;

var localized string MinorSpecSymbol;

var protected StateObjectReference UnitRef;
var protected array<name> CurrentSpecializations;
var protected X2SpecializationTemplate LastTrainedSpecialization;

//-------------------------------------------------------------------------
// CONSTRUCTOR
//-------------------------------------------------------------------------

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
		`log("STCO: Template assigned to " $ ParentUnit.GetFullName() $ " from dynamic class template pool. Templates remaining: " $ TemplatePool.GetRemainingTemplateCount() $ ".");
	}

	ParentUnit.AbilityTree.Length = 0;
	ParentUnit.AbilityTree.Length = default.NumberOfRanks;
}

//-------------------------------------------------------------------------
// GETTERS
//-------------------------------------------------------------------------

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

function bool CanReceiveTraining()
{
	return CurrentSpecializations.Length < MaxMinorSpecializations + 1;
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

function bool HasSpecialization(name SpecializationName)
{
	return CurrentSpecializations.Find(SpecializationName) != INDEX_NONE;
}

function array<X2SpecializationTemplate> GetAllowedSpecializations()
{
	local array<X2SpecializationTemplate> AllSpecs, AllowedSpecs;
	local X2SpecializationTemplate Specialization;

	AllSpecs = class'X2SpecializationTemplateManager'.static.GetInstance().GetAllSpecializationTemplates();

	foreach AllSpecs(Specialization)
	{
		if (!HasExcludingSpecializationTo(Specialization))
		{
			AllowedSpecs.AddItem(Specialization);
		}
	}

	return AllowedSpecs;
}

function bool HasExcludingSpecializationTo(X2SpecializationTemplate Template)
{
	local name ExcludedSpecName, CurrentSpecName;

	if (HasSpecialization(Template.DataName))
		return true;

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

//-------------------------------------------------------------------------
// PUBLIC FUNCTIONS
//-------------------------------------------------------------------------

function TrainRandomSpecializations(optional XComGameState UpdateState)
{
	local array<X2SpecializationTemplate> AllowedSpecializations;
	local X2SpecializationTemplate Specialization;
	local int RandomIndex;

	AllowedSpecializations = GetAllowedSpecializations();
	RandomIndex = `SYNC_RAND(AllowedSpecializations.Length);
	Specialization = AllowedSpecializations[RandomIndex];

	AddSpecialization(Specialization.DataName, UpdateState);
}

function AddSpecialization(name SpecializationName, optional XComGameState UpdateState)
{
	local X2SpecializationTemplate Specialization;
	local int Row;

	Specialization = GetSpecializationTemplate(SpecializationName);

	// if training core:
	if (CurrentSpecializations.Length == 0)
	{
		Row = 0;
		AddPerksToRow(1, Specialization.CoreAbilities, UpdateState);		
	}
	else
	{
		Row = 2 + CurrentSpecializations.Length - 1;
	}

	AddPerksToRow(Row, Specialization.Abilities, UpdateState);

	CurrentSpecializations.AddItem(SpecializationName);

	LastTrainedSpecialization = Specialization;

	// buy first perk automatically
	GetParentUnit(UpdateState).BuySoldierProgressionAbility(UpdateState, 0, Row);
		
	UpdateClassTemplate(UpdateState);
}

function UpdateClassTemplate(optional XComGameState UpdateState)
{
	local X2SoldierClassTemplate ClassTemplate;
	local int i;
	local array<X2SpecializationTemplate> SpecializationTemplates;
	local X2SpecializationTemplate Specialization;
	local array<SoldierClassWeaponType> AllowedWeapons;
	local SoldierClassWeaponType AllowedWeapon;
	local bool HasAddedPrimary;

	ClassTemplate = GetParentUnit(UpdateState).GetSoldierClassTemplate();
		
	// set variables from core specialization
	ClassTemplate.IconImage = GetSpecializationAt(0).IconImage;
	ClassTemplate.DisplayName = GetSpecializationAt(0).DisplayName;
	ClassTemplate.AbilityTreeTitles[0] = GetSpecializationAt(0).DisplayName;

	// add symbols to class name to indicate extra specs
	for (i = 0; i < CurrentSpecializations.Length - 1; i++)
	{
		ClassTemplate.DisplayName = ClassTemplate.DisplayName $ default.MinorSpecSymbol;
	}

	// add other ability tree titles
	for (i = 1; i < CurrentSpecializations.Length; i++)
	{
		ClassTemplate.AbilityTreeTitles[i + 1] = GetSpecializationAt(i).DisplayName;
	}

	// make a copy of class's allowed weapons without the primaries
	foreach ClassTemplate.AllowedWeapons(AllowedWeapon)
	{
		if (AllowedWeapon.SlotType != eInvSlot_PrimaryWeapon)
		{
			AllowedWeapons.AddItem(AllowedWeapon);
		}
	}

	// add all primary weapons allowed by trained specs to the allowed weapons
	HasAddedPrimary = false;
	SpecializationTemplates = GetCurrentSpecializations();
	foreach SpecializationTemplates(Specialization)
	{
		for (i = 0; i < Specialization.AllowedPrimaryWeapons.Length; i++)
		{
			AllowedWeapons.Add(1);			
			AllowedWeapons[AllowedWeapons.Length - 1].WeaponType = Specialization.AllowedPrimaryWeapons[i];
			AllowedWeapons[AllowedWeapons.Length - 1].SlotType = eInvSlot_PrimaryWeapon;
			HasAddedPrimary = true;
		}
	}

	// if no other primary weapon has been granted, allow soldier to use rifle
	if (!HasAddedPrimary)
	{
		AllowedWeapons.Add(1);
		AllowedWeapons[AllowedWeapons.Length - 1].WeaponType = 'rifle';
		AllowedWeapons[AllowedWeapons.Length - 1].SlotType = eInvSlot_PrimaryWeapon;
	}

	// replace the original list with the new one
	ClassTemplate.AllowedWeapons = AllowedWeapons;
}

function UnitHasRankedUp(optional XComGameState UpdateState)
{
	ApplyStatIncreasesForRank(GetParentUnit(UpdateState).GetRank(), UpdateState);
}

// apply stat increases from core specialization
function ApplyStatIncreasesForRank(int SoldierRank, optional XComGameState UpdateState)
{
	local XComGameState_Unit UnitState;
	local array<SoldierClassStatType> StatProgression;
	local int i, MaxStat, NewMaxStat, StatVal, NewCurrentStat, StatCap;

	UnitState = GetParentUnit(UpdateState);
	SoldierRank = UnitState.GetRank();
	StatProgression = GetSpecializationAt(0).StatProgressions[SoldierRank - 1].StatProgressionsForRank;

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

//-------------------------------------------------------------------------
// PROTECTED FUNCTIONS
//-------------------------------------------------------------------------

protected function X2SpecializationTemplate GetSpecializationTemplate(name SpecializationName)
{
	local X2SpecializationTemplateManager SpecializationTemplateManager;
	SpecializationTemplateManager = class'X2SpecializationTemplateManager'.static.GetInstance();
	return SpecializationTemplateManager.FindSpecializationTemplate(SpecializationName);
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