class X2DownloadableContentInfo_WOTC_SpecialTrainingClassOverhaul extends X2DownloadableContentInfo;

static event InstallNewCampaign(XComGameState StartState)
{	
	class'XComGameState_DynamicClassTemplatePool'.static.CreateDynamicClassTemplatePool(StartState);

	BuildGTS(StartState);
}

static event OnLoadedSavedGameToStrategy()
{
	UpdateDynamicClassTemplates();
}

static event OnLoadedSavedGameToTactical()
{
	UpdateDynamicClassTemplates();
}

static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{
	local int Index;
	local array<XComGameState_Item> CurrentInventory;
	local XComGameState_Item InventoryItem;
	local AbilitySetupData Data, EmptyData;
	local array<AbilitySetupData> DataToAdd;

	if (!UnitState.IsSoldier())
		return;

	CurrentInventory = UnitState.GetAllInventoryItems(StartState);

	// allows soldiers to use their launcher - code borrowed from RPG Overhaul
	for(Index = SetupData.Length; Index >= 0; Index--)
	{		
		if (SetupData[Index].Template.bUseLaunchedGrenadeEffects)
		{
			Data = EmptyData;
			Data.TemplateName = SetupData[Index].TemplateName;
			Data.Template = SetupData[Index].Template;
			Data.SourceWeaponRef = SetupData[Index].SourceWeaponRef;

			// Remove the original ability
			SetupData.Remove(Index, 1);

			//  populate a version of the ability for every grenade in the inventory
			foreach CurrentInventory(InventoryItem)
			{
				if (InventoryItem.bMergedOut) 
					continue;

				if (X2GrenadeTemplate(InventoryItem.GetMyTemplate()) != none)
				{ 
					Data.SourceAmmoRef = InventoryItem.GetReference();
					DataToAdd.AddItem(Data);
				}
			}
		}
	}

	foreach DataToAdd(Data)
	{
		SetupData.AddItem(Data);
	}
}

static event OnPostTemplatesCreated()
{
	class'XComGameState_DynamicClassTemplatePool'.static.CreateObjectsForPool();

	DisableAllOtherClasses();
	AddNewStaffSlots();
	RemoveStaffSlots();
	RemoveClassUpgradesFromGTS();
	AddAbilitiesToWeapons();
	PatchAbilities();

	class'X2StrategyGameRulesetDataStructures'.default.PowerfulAbilities.Length = 0;
}

static function UpdateDynamicClassTemplates()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_Unit> Soldiers;
	local XComGameState_Unit UnitState;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	Soldiers = XComHQ.GetSoldiers();

	foreach Soldiers(UnitState)
	{
		if (class'SpecialTrainingUtilities'.static.HasSpecialTrainingComponent(UnitState))
		{			
			class'SpecialTrainingUtilities'.static.GetSpecialTrainingComponentOf(UnitState).UpdateClassTemplate();
		}
	}
}

static function DisableAllOtherClasses()
{
	local X2SoldierClassTemplateManager SoldierClassManager;
    local array<X2SoldierClassTemplate> Templates;
	local X2SoldierClassTemplate Template;

	SoldierClassManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	Templates = SoldierClassManager.GetAllSoldierClassTemplates(true); // true to not get multiplayer classes

	foreach Templates(Template)
	{
		// don't disable STCO's soldier class
		if (Template.DataName == 'STCO_Soldier')
			continue;

		if (Template.NumInForcedDeck > 0 || Template.NumInDeck > 0)
		{
			Template.NumInForcedDeck = 0;
			Template.NumInDeck = 0;
		}
	}
}

static function AddNewStaffSlots()
{
	local X2FacilityTemplate FacilityTemplate;
	local array<X2FacilityTemplate> FacilityTemplates;
	local StaffSlotDefinition StaffSlotDef;

	FindFacilityTemplateAllDifficulties('OfficerTrainingSchool', FacilityTemplates);
	StaffSlotDef.StaffSlotTemplateName = 'STCO_SpecialTrainingStaffSlot';
	foreach FacilityTemplates(FacilityTemplate)
	{
		FacilityTemplate.StaffSlotDefs.AddItem(StaffSlotDef);
	}
}

static function RemoveStaffSlots()
{
	local X2FacilityTemplate FacilityTemplate;
	local array<X2FacilityTemplate> FacilityTemplates;
	local StaffSlotDefinition StaffSlotDef;
	local int i, index;

	FindFacilityTemplateAllDifficulties('OfficerTrainingSchool', FacilityTemplates);

	foreach FacilityTemplates(FacilityTemplate)
	{
		index = -1;

		for (i = 0; i < FacilityTemplate.StaffSlotDefs.Length; i++)
		{
			StaffSlotDef = FacilityTemplate.StaffSlotDefs[i];

			if (StaffSlotDef.StaffSlotTemplateName == 'OTSStaffSlot')
			{
				index = i;
			}
		}

		if (index != -1)
		{
			FacilityTemplate.StaffSlotDefs.Remove(index, 1);
		}
	}
}

static function RemoveClassUpgradesFromGTS()
{
	local X2FacilityTemplate FacilityTemplate;
	local array<X2FacilityTemplate> FacilityTemplates;

	FindFacilityTemplateAllDifficulties('OfficerTrainingSchool', FacilityTemplates);

	foreach FacilityTemplates(FacilityTemplate)
	{
		FacilityTemplate.SoldierUnlockTemplates.RemoveItem('HuntersInstinctUnlock');
		FacilityTemplate.SoldierUnlockTemplates.RemoveItem('HitWhereItHurtsUnlock');
		FacilityTemplate.SoldierUnlockTemplates.RemoveItem('CoolUnderPressureUnlock');
		FacilityTemplate.SoldierUnlockTemplates.RemoveItem('BiggestBoomsUnlock');
	}
}

static function AddAbilitiesToWeapons()
{
	local X2ItemTemplateManager ItemManager;
	local X2WeaponTemplate WeaponTemplate;
	local array<name> TemplateNames;
	local name TemplateName;
	local array<X2DataTemplate> DifficultyVariants;
	local X2DataTemplate ItemTemplate;

	ItemManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	ItemManager.GetTemplateNames(TemplateNames);

	foreach TemplateNames(TemplateName)
	{
		ItemManager.FindDataTemplateAllDifficulties(TemplateName, DifficultyVariants);

		foreach DifficultyVariants(ItemTemplate)
		{
			WeaponTemplate = X2WeaponTemplate(ItemTemplate);

			if (WeaponTemplate != none)
			{
				PatchWeaponTemplate(WeaponTemplate);
			}
		}
	}
}

static function PatchWeaponTemplate(X2WeaponTemplate WeaponTemplate)
{
	local X2GremlinTemplate GremlinTemplate;

	switch (WeaponTemplate.WeaponCat)
	{
		case 'Gremlin':
			GremlinTemplate = X2GremlinTemplate(WeaponTemplate);
			AddAbilityToGremlinTemplate(GremlinTemplate, 'IntrusionProtocol');
			break;
		case 'sniper_rifle':
			AddAbilityToWeaponTemplate(WeaponTemplate, 'Squadsight');
			break;
		case 'pistol':
			AddAbilityToWeaponTemplate(WeaponTemplate, 'PistolStandardShot');
			break;
		case 'sword':
			AddAbilityToWeaponTemplate(WeaponTemplate, 'SwordSlice');
			break;
		case 'grenade_launcher':
			AddAbilityToWeaponTemplate(WeaponTemplate, 'LaunchGrenade');
			break;
		default:
			break;
	}
}

static function AddAbilityToGremlinTemplate(X2GremlinTemplate GremlinTemplate, name AbilityName)
{
	if (GremlinTemplate.Abilities.Find(AbilityName) == INDEX_NONE)
	{
		GremlinTemplate.Abilities.AddItem(AbilityName);
	}
}

static function AddAbilityToWeaponTemplate(X2WeaponTemplate WeaponTemplate, name AbilityName)
{
	if (WeaponTemplate.Abilities.Find(AbilityName) == INDEX_NONE)
	{
		WeaponTemplate.Abilities.AddItem(AbilityName);
	}
}

static function PatchAbilities()
{
	local X2AbilityTemplateManager AbilityManager;
	local array<X2AbilityTemplate> AbilityTemplates;
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect_PersistentStatChange	PersistentStatChange;

	AbilityManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	// add bonus hack to a specified perk
	AbilityManager.FindAbilityTemplateAllDifficulties(class'SpecialTrainingUtilities'.default.PerkForHackingBonus, AbilityTemplates);

	PersistentStatChange = new class'X2Effect_PersistentStatChange';
	PersistentStatChange.BuildPersistentEffect(1, true, false, false);
	PersistentStatChange.AddPersistentStatChange(eStat_Hacking, class'SpecialTrainingUtilities'.default.HackingBonusAmount);

	foreach AbilityTemplates(AbilityTemplate)
	{
		AbilityTemplate.AddTargetEffect(PersistentStatChange);
		AbilityTemplate.SetUIStatMarkup(class'XLocalizedData'.default.TechLabel, eStat_Hacking, class'SpecialTrainingUtilities'.default.HackingBonusAmount);
	}

	// allow launch grenade to work with modified version of Salvo
	AbilityManager.FindAbilityTemplateAllDifficulties('LaunchGrenade', AbilityTemplates);

	foreach AbilityTemplates(AbilityTemplate)
	{
		X2AbilityCost_ActionPoints(AbilityTemplate.AbilityCosts[0]).DoNotConsumeAllSoldierAbilities.AddItem('STCO_Salvo');
	}
}

static function BuildGTS(XComGameState UpdateState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersRoom Room, NewRoomState;
	local XComGameState_FacilityXCom Facility;
	local X2FacilityTemplate FacilityTemplate;
	local XComGameStateHistory History;
	local StateObjectReference FacilityRef;
	local int MapIndex;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		
	MapIndex = 3;

	Room = XComHQ.GetRoom(MapIndex);

	// if map index 3 is the starting open space, then build the GTS somewhere else
	if (!Room.ConstructionBlocked)
	{
		MapIndex = 5;
		Room = XComHQ.GetRoom(MapIndex);
	}
	
	NewRoomState = XComGameState_HeadquartersRoom(UpdateState.ModifyStateObject(class'XComGameState_HeadquartersRoom', Room.ObjectID));
	FacilityTemplate = X2FacilityTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate('OfficerTrainingSchool'));

	if(FacilityTemplate != none)
	{
		Facility = FacilityTemplate.CreateInstanceFromTemplate(UpdateState);
		FacilityRef = Facility.GetReference();
		Facility.Room = NewRoomState.GetReference();
		NewRoomState.Facility = Facility.GetReference();
		NewRoomState.ConstructionBlocked = false;
		NewRoomState.SpecialFeature = '';

		XComHQ.Facilities.AddItem(FacilityRef);
	}
}

//retrieves all difficulty variants of a given facility template
static function FindFacilityTemplateAllDifficulties(name DataName, out array<X2FacilityTemplate> FacilityTemplates, optional X2StrategyElementTemplateManager StrategyTemplateMgr)
{
	local array<X2DataTemplate> DataTemplates;
	local X2DataTemplate DataTemplate;
	local X2FacilityTemplate FacilityTemplate;

	if(StrategyTemplateMgr == none)
		StrategyTemplateMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	StrategyTemplateMgr.FindDataTemplateAllDifficulties(DataName, DataTemplates);
	FacilityTemplates.Length = 0;
	foreach DataTemplates(DataTemplate)
	{
		FacilityTemplate = X2FacilityTemplate(DataTemplate);
		if( FacilityTemplate != none )
		{
			FacilityTemplates.AddItem(FacilityTemplate);
		}
	}
}