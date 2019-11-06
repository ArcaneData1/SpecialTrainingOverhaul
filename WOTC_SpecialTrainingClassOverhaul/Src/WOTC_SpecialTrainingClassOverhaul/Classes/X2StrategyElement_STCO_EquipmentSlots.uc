class X2StrategyElement_STCO_EquipmentSlots extends CHItemSlotSet;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateSpecialSlotTemplate('STCO_SwordSlot', eInvSlot_AugmentationHead));
	Templates.AddItem(CreateSpecialSlotTemplate('STCO_PistolSlot', eInvSlot_AugmentationTorso));
	Templates.AddItem(CreateSpecialSlotTemplate('STCO_GremlinSlot', eInvSlot_AugmentationArms));
	Templates.AddItem(CreateSpecialSlotTemplate('STCO_GrenadeLauncherSlot', eInvSlot_AugmentationLegs));

	return Templates;
}

static function X2DataTemplate CreateSpecialSlotTemplate(name slotName, EInventorySlot invSlot)
{
	local CHItemSlot Template;

	`CREATE_X2TEMPLATE(class'CHItemSlot', Template, slotName);

	Template.InvSlot = invSlot;
	Template.SlotCatMask = Template.SLOT_WEAPON;

	Template.IsUserEquipSlot = true;
	Template.IsEquippedSlot = true;
	Template.IsMultiItemSlot = false;
	Template.NeedsPresEquip = true;
	Template.ShowOnCinematicPawns = true;

	Template.CanAddItemToSlotFn = CanAddItemToSlot;
	Template.UnitHasSlotFn = HasSlot;
	Template.GetPriorityFn = GetPriority;	
	Template.ShowItemInLockerListFn = ShowItemInLockerList;
	Template.ValidateLoadoutFn = ValidateLoadout;

	return Template;
}

static function bool CanAddItemToSlot(CHItemSlot Slot, XComGameState_Unit Unit, X2ItemTemplate Template, optional XComGameState CheckGameState, optional int Quantity = 1, optional XComGameState_Item ItemState)
{
	switch (Slot.InvSlot)
	{
		case eInvSlot_AugmentationHead:
			return X2WeaponTemplate(Template).WeaponCat == 'sword';
		case eInvSlot_AugmentationTorso:
			return X2WeaponTemplate(Template).WeaponCat == 'pistol';
		case eInvSlot_AugmentationArms:
			return X2WeaponTemplate(Template).WeaponCat == 'gremlin';
		case eInvSlot_AugmentationLegs:
			return X2WeaponTemplate(Template).WeaponCat == 'grenade_launcher';
		default:
			return false;
	}
}

static function bool HasSlot(CHItemSlot Slot, XComGameState_Unit UnitState, out string LockedReason, optional XComGameState CheckGameState)
{
	local XComGameState_Unit_SpecialTraining TrainingState;
	local array<name> AllowedSlots;

	TrainingState = class'SpecialTrainingUtilities'.static.GetSpecialTrainingComponentOf(UnitState, CheckGameState);

	if (TrainingState == none)
		return false;

	AllowedSlots = TrainingState.GetAllowedSlots();

	return AllowedSlots.Find(Slot.DataName) != INDEX_NONE;
}

static function int GetPriority(CHItemSlot Slot, XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	switch (Slot.InvSlot)
	{
		case eInvSlot_AugmentationHead:
			return 31;
		case eInvSlot_AugmentationTorso:
			return 32;
		case eInvSlot_AugmentationArms:
			return 33;
		case eInvSlot_AugmentationLegs:
			return 34;
		default:
			return 31;
	}
}

static function bool ShowItemInLockerList(CHItemSlot Slot, XComGameState_Unit Unit, XComGameState_Item ItemState, X2ItemTemplate ItemTemplate, XComGameState CheckGameState)
{
	local X2WeaponTemplate WeaponTemplate;

	WeaponTemplate = X2WeaponTemplate(ItemTemplate);

	if (WeaponTemplate == none)
		return false;

	switch (Slot.InvSlot)
	{
		case eInvSlot_AugmentationHead:
			return WeaponTemplate.WeaponCat == 'sword';
		case eInvSlot_AugmentationTorso:
			return WeaponTemplate.WeaponCat == 'pistol';
		case eInvSlot_AugmentationArms:
			return WeaponTemplate.WeaponCat == 'gremlin';
		case eInvSlot_AugmentationLegs:
			return WeaponTemplate.WeaponCat == 'grenade_launcher';
		default:
			return false;
	}
}

static function ValidateLoadout(CHItemSlot Slot, XComGameState_Unit Unit, XComGameState_HeadquartersXCom XComHQ, XComGameState NewGameState)
{
	switch (Slot.InvSlot)
	{
		case eInvSlot_AugmentationHead:
			class'SpecialTrainingUtilities'.static.ApplyBestGearForSlot(Unit, eInvSlot_AugmentationHead, 'STCO_SwordSlot', 'sword', NewGameState);
			return;
		case eInvSlot_AugmentationTorso:
			class'SpecialTrainingUtilities'.static.ApplyBestGearForSlot(Unit, eInvSlot_AugmentationTorso, 'STCO_PistolSlot', 'pistol', NewGameState);
			return;
		case eInvSlot_AugmentationArms:
			class'SpecialTrainingUtilities'.static.ApplyBestGearForSlot(Unit, eInvSlot_AugmentationArms, 'STCO_GremlinSlot', 'gremlin', NewGameState);
			return;
		case eInvSlot_AugmentationLegs:
			class'SpecialTrainingUtilities'.static.ApplyBestGearForSlot(Unit, eInvSlot_AugmentationLegs, 'STCO_GrenadeLauncherSlot', 'grenade_launcher', NewGameState);
			return;
		default:
			return;
	}
}