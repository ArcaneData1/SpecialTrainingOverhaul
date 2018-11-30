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
			return X2WeaponTemplate(Template).WeaponCat == 'sword';
	}
}

static function bool HasSlot(CHItemSlot Slot, XComGameState_Unit UnitState, out string LockedReason, optional XComGameState CheckGameState)
{
	return UnitState.IsSoldier() && !UnitState.IsRobotic();
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
	return X2WeaponTemplate(ItemTemplate).InventorySlot == eInvSlot_SecondaryWeapon;
}