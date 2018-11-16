//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_WOTC_SpecialTrainingClassOverhaul.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

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
{}

static event OnPostTemplatesCreated()
{
	SetDefaultSoldierClass();

	AddNewStaffSlots();

}

static function SetDefaultSoldierClass()
{
	local X2CharacterTemplateManager CharacterManager;
	local X2CharacterTemplate Template;

	CharacterManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	Template = CharacterManager.FindCharacterTemplate('Soldier');

	Template.DefaultSoldierClass = 'STCO_Soldier';
}

static function AddNewStaffSlots()
{
	local X2FacilityTemplate FacilityTemplate;
	local array<X2FacilityTemplate> FacilityTemplates;
	local StaffSlotDefinition StaffSlotDef;

	FindFacilityTemplateAllDifficulties('OfficerTrainingSchool', FacilityTemplates);
	StaffSlotDef.StaffSlotTemplateName = 'STCO_SecondaryTrainingStaffSlot';
	foreach FacilityTemplates(FacilityTemplate)
	{
		FacilityTemplate.StaffSlotDefs.AddItem(StaffSlotDef);
	}
}

static function AddNewStuffSlots_Original()
{
	local int n;
	local X2FacilityTemplate Template;
	local array<X2FacilityTemplate> FacilityTemplates;
	
	FindFacilityTemplateAllDifficulties('OfficerTrainingSchool', FacilityTemplates);
	foreach FacilityTemplates(Template) {
		for (n=0;n<Template.StaffSlotDefs.Length;n++) {
			if (Template.StaffSlotDefs[n].StaffSlotTemplateName == 'OTSStaffSlot') {
				Template.StaffSlotDefs[n].StaffSlotTemplateName = 'STCO_SecondaryTrainingStaffSlot';
				
				`log("Replaced OTS Staff slot " $ n);

			}
		}
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

static function bool DisplayQueuedDynamicPopup(DynamicPropertySet PropertySet)
{
	local UIAlert_STCO Alert;
	local XComHQPresentationLayer HQPresLayer;

	HQPresLayer = `HQPRES();

	if (PropertySet.PrimaryRoutingKey == 'USSM_Multiclass') {
		Alert = HQPresLayer.Spawn(class'UIAlert_STCO', HQPresLayer);
		Alert.DisplayPropertySet = PropertySet;
		Alert.eAlertName = PropertySet.SecondaryRoutingKey;

		HQPresLayer.ScreenStack.Push(Alert);
		return true;
	}
}