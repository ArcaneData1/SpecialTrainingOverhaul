class X2Ability_STCOAbilitySet extends X2Ability config(SpecialTrainingClassOverhaul);

var config int DeepPocketsBonus;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(DeepPockets());
	Templates.AddItem(CustomSalvo());

	return Templates;
}

static function X2AbilityTemplate DeepPockets()
{
	local X2AbilityTemplate Template;

	Template = PurePassive('STCO_DeepPockets', "img:///UILibrary_LW_PerkPack.LW_AbilityFullKit");	
	
	Template.bCrossClassEligible = false;
	Template.GetBonusWeaponAmmoFn = DeepPockets_BonusWeaponAmmo;

	return Template;
}

function int DeepPockets_BonusWeaponAmmo(XComGameState_Unit UnitState, XComGameState_Item ItemState)
{
	if (ItemState.InventorySlot == eInvSlot_Utility)
		return default.DeepPocketsBonus;

	return 0;
}

static function X2AbilityTemplate CustomSalvo()
{
	local X2AbilityTemplate Template;

	Template = PurePassive('STCO_Salvo', "img:///UILibrary_PerkIcons.UIPerk_salvo", true);

	return Template;
}