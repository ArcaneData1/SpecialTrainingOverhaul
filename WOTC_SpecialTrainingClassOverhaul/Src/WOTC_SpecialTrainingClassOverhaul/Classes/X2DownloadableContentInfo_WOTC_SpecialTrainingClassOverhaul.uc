class X2DownloadableContentInfo_WOTC_SpecialTrainingClassOverhaul extends X2DownloadableContentInfo;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{	
	class'XComGameState_DynamicClassTemplatePool'.static.CreateDynamicClassTemplatePool(StartState);

	ModifyAllSoldiersInBarracks(StartState);
}

static event OnPostTemplatesCreated()
{
	class'XComGameState_DynamicClassTemplatePool'.static.CreateObjectsForPool();
	DisableAllOtherClasses();
	ModifyDefaultSoldierTemplate();
	AddNewStaffSlots();
	RemoveStaffSlots();
	RemoveClassUpgradesFromGTS();
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

static function ModifyDefaultSoldierTemplate()
{
	local X2CharacterTemplateManager CharacterManager;
	local X2CharacterTemplate Template;

	CharacterManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	Template = CharacterManager.FindCharacterTemplate('Soldier');

	Template.bIsResistanceHero = true; // allows alternate style of ranking up
}

static function ModifyAllSoldiersInBarracks(XComGameState StartState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_Unit> Soldiers;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	Soldiers = XComHQ.GetSoldiers();

	foreach Soldiers(UnitState)
	{
		if (class'SpecialTrainingUtilities'.static.UnitRequiresSpecialTrainingComponent(UnitState))
		{
			class'SpecialTrainingUtilities'.static.AddNewSpecialTrainingComponentTo(UnitState, StartState);
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