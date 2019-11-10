class SpecialTrainingUtilities extends Object config (SpecialTrainingClassOverhaul);

var config array<int> DefaultSpecialTrainingDays;
var config int ExtraDaysForUnexperiencedRookies;

var config name PerkForHackingBonus;
var config int HackingBonusAmount;

var config array<int> BaseAbilityPointsPerRank;

// adds a new training component to a soldier
static function XComGameState_Unit_SpecialTraining AddNewSpecialTrainingComponentTo(XComGameState_Unit UnitState, XComGameState GameState)
{
	local XComGameState_Unit_SpecialTraining TrainingState;
	
	TrainingState = XComGameState_Unit_SpecialTraining(GameState.CreateStateObject(class'XComGameState_Unit_SpecialTraining'));
	TrainingState.Initialize(GameState, UnitState);
	
	GameState.AddStateObject(TrainingState);

	`log("STCO: Created special training component for " $ UnitState.GetFullName() $ ".");

	return TrainingState;
}

// gets the special training component of a soldier
static function XComGameState_Unit_SpecialTraining GetSpecialTrainingComponentOf(XComGameState_Unit UnitState, optional XComGameState UpdateState)
{
	local XComGameState_Unit_SpecialTraining TrainingState;

	if (UpdateState == none)
	{
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit_SpecialTraining', TrainingState)
		{
			if (TrainingState.ParentUnitIs(UnitState))
				return TrainingState;
		}
	}
	else
	{
		foreach UpdateState.IterateByClassType(class'XComGameState_Unit_SpecialTraining', TrainingState)
		{
			if (TrainingState.ParentUnitIs(UnitState))
				return TrainingState;
		}
	}

	return none;
}

// checks if unit should have AddNewSpecialTrainingComponentTo called on it
static function bool RequiresSpecialTrainingComponent(XComGameState_Unit UnitState)
{
	return UnitState.GetSoldierClassTemplateName() == 'STCO_Soldier';
}

// checks if a soldier has a special training component attached
static function bool HasSpecialTrainingComponent(XComGameState_Unit UnitState)
{
	return GetSpecialTrainingComponentOf(UnitState) != none;
}

// gets the currently-running special training project for the given slot
static function XComGameState_HeadquartersProjectSpecialTraining GetSpecialTrainingProject(XComGameState_StaffSlot SlotState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectSpecialTraining TrainProject;
	local int idx;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	for (idx = 0; idx < XComHQ.Projects.Length; idx++)
	{
		TrainProject = XComGameState_HeadquartersProjectSpecialTraining(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));

		if (TrainProject != none)
		{
			if (SlotState.GetAssignedStaffRef() == TrainProject.ProjectFocus)
			{
				return TrainProject;
			}
		}
	}
}

// gets the length of time needed for special training
static function float GetSpecialTrainingDays(XComGameState_Unit UnitState)
{
	if (UnitState.GetRank() > 0 || IsRookieWaitingToTrain(UnitState))
	{
		return `ScaleStrategyArrayInt(default.DefaultSpecialTrainingDays);
	}
	else
	{
		return `ScaleStrategyArrayInt(default.DefaultSpecialTrainingDays) + default.ExtraDaysForUnexperiencedRookies;
	}
}

// returns if the unit is a rookie with experience
static function bool IsRookieWaitingToTrain(XComGameState_Unit UnitState)
{
	return UnitState.IsSoldier() && UnitState.GetRank() == 0 && UnitState.GetTotalNumKills() >= class'X2ExperienceConfig'.static.GetRequiredKills(1);
}

// applies best gear for a custom secondary weapon slot
static function ApplyBestGearForSlot(XComGameState_Unit Unit, EInventorySlot InvSlot, name SlotName, name Category, XComGameState UpdateState)
{
	local XComGameState_Item EquippedWeapon;
	local array<X2WeaponTemplate> BestWeaponTemplates;
	local XComGameState_Unit_SpecialTraining SpecialTraining;
	local array<name> AllowedSlots;
	
	SpecialTraining = GetSpecialTrainingComponentOf(Unit, UpdateState);

	if (SpecialTraining == none)
	{
		return;
	}
			
	AllowedSlots = SpecialTraining.GetAllowedSlots();

	if (AllowedSlots.Find(SlotName) == INDEX_NONE)
	{
		return;
	}

	EquippedWeapon = Unit.GetItemInSlot(InvSlot, UpdateState);
	BestWeaponTemplates = GetBestWeaponTemplatesFor(Unit, SlotName, Category, UpdateState);
	Unit.UpgradeEquipment(UpdateState, EquippedWeapon, BestWeaponTemplates, InvSlot);
}

static function array<X2WeaponTemplate> GetBestWeaponTemplatesFor(XComGameState_Unit Unit, name SlotName, name Category, XComGameState UpdateState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2WeaponTemplate WeaponTemplate, BestWeaponTemplate;
	local array<X2WeaponTemplate> BestWeaponTemplates;
	local XComGameState_Item ItemState;
	local int idx, HighestTier;
	local XComGameState_Unit_SpecialTraining SpecialTraining;
	local array<name> AllowedSlots;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	SpecialTraining = GetSpecialTrainingComponentOf(Unit, UpdateState);

	if( XComHQ != none && SpecialTraining != none)
	{
		// Try to find a better secondary weapon as an infinite item in the inventory
		for (idx = 0; idx < XComHQ.Inventory.Length; idx++)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[idx].ObjectID));
			WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
			AllowedSlots = SpecialTraining.GetAllowedSlots();

			if(WeaponTemplate != none && WeaponTemplate.bInfiniteItem && (BestWeaponTemplate == none || (BestWeaponTemplates.Find(WeaponTemplate) == INDEX_NONE && WeaponTemplate.Tier >= BestWeaponTemplate.Tier)) &&
				WeaponTemplate.WeaponCat == Category && AllowedSlots.Find(SlotName) != INDEX_NONE)
			{
				BestWeaponTemplate = WeaponTemplate;
				BestWeaponTemplates.AddItem(BestWeaponTemplate);
				HighestTier = BestWeaponTemplate.Tier;
			}
		}
	}

	for(idx = 0; idx < BestWeaponTemplates.Length; idx++)
	{
		if(BestWeaponTemplates[idx].Tier < HighestTier)
		{
			BestWeaponTemplates.Remove(idx, 1);
			idx--;
		}
	}

	return BestWeaponTemplates;
}