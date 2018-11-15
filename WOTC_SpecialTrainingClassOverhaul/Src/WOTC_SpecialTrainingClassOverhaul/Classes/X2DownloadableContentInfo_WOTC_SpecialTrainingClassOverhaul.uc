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
/*
	local X2CharacterTemplateManager CharacterManager;
	local X2CharacterTemplate Template;

	CharacterManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	Template = CharacterManager.FindCharacterTemplate('Soldier');

	Template.DefaultSoldierClass = 'STCO_Soldier';
	*/
/*
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2DataTemplate> DifficultyVariants;
	local array<name> TemplateNames;
	local name TemplateName;
	local X2DataTemplate ItemTemplate;
	local X2WeaponTemplate WeaponTemplate;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	ItemTemplateManager.GetTemplateNames(TemplateNames);

	foreach TemplateNames(TemplateName)
	{
		ItemTemplateManager.FindDataTemplateAllDifficulties(TemplateName, DifficultyVariants);
		
		foreach DifficultyVariants(ItemTemplate)
		{
			WeaponTemplate = X2WeaponTemplate(ItemTemplate);

			if (WeaponTemplate == none)
				continue;
			
			switch (WeaponTemplate.WeaponCat)
			{
				case 'sword':
					WeaponTemplate.InventorySlot = eInvSlot_AugmentationHead;
					break;
				case 'pistol':
					WeaponTemplate.InventorySlot = eInvSlot_AugmentationTorso;
					break;
				case 'gremlin':
					WeaponTemplate.InventorySlot = eInvSlot_AugmentationArms;
					break;
				case 'grenade_launcher':
					WeaponTemplate.InventorySlot = eInvSlot_AugmentationLegs;
					break;
				default:
					break;
			}
		}
	}
	*/
}
