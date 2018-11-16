class XComGameStateContext_HeadquartersOrder_STCO extends XComGameStateContext_HeadquartersOrder;
/*
static function IssueHeadquartersOrder_STCO(const out HeadquartersOrderInputContext UseInputContext)
{
	local XComGameStateContext_HeadquartersOrder NewOrderContext;

	NewOrderContext = XComGameStateContext_HeadquartersOrder(class'XComGameStateContext_HeadquartersOrder_STCO'.static.CreateXComGameStateContext());
	NewOrderContext.InputContext = UseInputContext;

	`GAMERULES.SubmitGameStateContext(NewOrderContext);
}

// finish multiclass training (not actually called on rookies)
static function CompleteTrainRookie(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersProjectTrainRookie ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;

	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate CurrentAbilityTemplate;

	local name MulticlassClass;
	local array<name> DisallowedPerks;
	local array<name> ClassPerks;
	local array<SoldierClassAbilityType> ClassPerkSCAT;
	local SoldierClassAbilityType NewTreeAbility;

	local array<name> XComPerksBought;
	local name chkBoughtPerk;
	local bool DefaultPrimary;

	local name currentPerk;
	local SoldierClassAbilityType chkSCAT;

	local EInventorySlot ApplySlot;
	local int rank;
	local int branch;
	local int i;
	local int xcomPerkN;
	local int classPerkN;

	local bool bought;

	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProjectTrainRookie(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}

		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
		if (UnitState != none)
		{
			MulticlassClass = ProjectState.NewClassName;

			AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

			DefaultPrimary = class'X2Ability_STCO'.static.GetPerksForMulticlassClass(MulticlassClass, ClassPerks);

			if (DefaultPrimary) {
				ApplySlot = eInvSlot_PrimaryWeapon;
			} else {
				ApplySlot = eInvSlot_SecondaryWeapon;
			}

			// build ability tree for our multiclass class's perk list
			for(i = 0;i < ClassPerks.Length; i++) {
				NewTreeAbility.AbilityName = ClassPerks[i];
				NewTreeAbility.ApplyToWeaponSlot = ApplySlot;

				CurrentAbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(ClassPerks[i]);
				if (CurrentAbilityTemplate.bIsPassive == true) {
					NewTreeAbility.ApplyToWeaponSlot = eInvSlot_Unknown;
				}
				
				ClassPerkSCAT.AddItem(NewTreeAbility);
				DisallowedPerks.AddItem(ClassPerks[i]);
			}

			// make a list of all of the xcom perks the soldier has
			for (i = 0; i < UnitState.m_SoldierProgressionAbilties.Length; ++i)
			{
				rank = UnitState.m_SoldierProgressionAbilties[i].iRank;
				branch = UnitState.m_SoldierProgressionAbilties[i].iBranch;

				// xcom branch
				if (branch == 2) {
					XComPerksBought.AddItem(UnitState.AbilityTree[rank].Abilities[branch].AbilityName);
				}
			}

			// add xcom's perks to our list of perks we can't randomly roll up
			for(xcomPerkN = 0; xcomPerkN < UnitState.AbilityTree.Length; xcomPerkN++) 
			{
				if (UnitState.AbilityTree[xcomPerkN].Abilities.Length >= 3) {
					currentPerk = UnitState.AbilityTree[xcomPerkN].Abilities[2].AbilityName;
					if (currentPerk != '') {
						DisallowedPerks.AddItem(currentPerk);
					}
				}
			}

			// now go through and make sure there aren't any xcom perks that are redundant
			for(xcomPerkN = 0; xcomPerkN < UnitState.AbilityTree.Length; xcomPerkN++) 
			{
				if (UnitState.AbilityTree[xcomPerkN].Abilities.Length >= 3) {
					currentPerk = UnitState.AbilityTree[xcomPerkN].Abilities[2].AbilityName;
					if (currentPerk != '') {

						for (classPerkN = 0; classPerkN < ClassPerkSCAT.Length; classPerkN++) {
							chkSCAT = ClassPerkSCAT[classPerkN];

							// one of the perks we want is already an xcom perk
							if (chkSCAT.AbilityName == currentPerk) {

								bought = false;
								foreach XComPerksBought(chkBoughtPerk) {
									if (chkBoughtPerk == currentPerk) {
										bought = true;
										break;
									}
								}

								// soldier already owns the perk, so replace our version
								if (bought) {
									ClassPerkSCAT[classPerkN] = RerollPerk(UnitState, DisallowedPerks);

								// soldier doesn't own the perk, safe to replace it
								} else {
									UnitState.AbilityTree[xcomPerkN].Abilities[2] = RerollPerk(UnitState, DisallowedPerks);
								}

							}
						}

					}
				}
			}

			// add our new perk list
			for(rank=0;rank<6;rank++) {
				while (UnitState.AbilityTree[rank+1].Abilities.Length < 4) {
					UnitState.AbilityTree[rank+1].Abilities.Length = UnitState.AbilityTree[rank+1].Abilities.Length + 1;
				}

				UnitState.AbilityTree[rank+1].Abilities[3] = ClassPerkSCAT[rank];
			}

			//UnitState.ApplyBestGearLoadout(AddToGameState);
			UnitState.SetStatus(eStatus_Active);

			// Remove the soldier from the staff slot
			StaffSlotState = UnitState.GetStaffSlot();
			if (StaffSlotState != none)
			{
				StaffSlotState.EmptySlot(AddToGameState);
			}
		}
	}
}

static function SoldierClassAbilityType RerollPerk(XComGameState_Unit UnitState, out array<name> DisallowedPerks) 
{
	local X2SoldierClassTemplate SoldierClassTemplate;
	local array<SoldierClassAbilityType> EligibleAbilities;
	local SoldierClassAbilityType newPerk;
	local name DisallowName;
	local int Idx;
	local int RemIdx;
	local int AbilityIdx;

	EligibleAbilities = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().GetCrossClassAbilities(UnitState.GetSoldierClassTemplate());

	SoldierClassTemplate = UnitState.GetSoldierClassTemplate();
	for (Idx = 0; Idx < SoldierClassTemplate.ExcludedAbilities.Length; ++Idx)
	{
		RemIdx = EligibleAbilities.Find('AbilityName', SoldierClassTemplate.ExcludedAbilities[Idx]);
		if (RemIdx != INDEX_NONE) {
			EligibleAbilities.Remove(RemIdx, 1);
		}
	}

	foreach DisallowedPerks(DisallowName) 
	{
		RemIdx = EligibleAbilities.Find('AbilityName', DisallowName);
		if (RemIdx != INDEX_NONE) {
			EligibleAbilities.Remove(RemIdx, 1);
		}
	}

	if (class'X2Ability_STCO'.default.BadForReroll.Length > 0) {
		foreach class'X2Ability_STCO'.default.BadForReroll(DisallowName)
		{
			RemIdx = EligibleAbilities.Find('AbilityName', DisallowName);
			if (RemIdx != INDEX_NONE) {
				EligibleAbilities.Remove(RemIdx, 1);
			}
		}
	}

	if (EligibleAbilities.Length > 0)
	{
		AbilityIdx = `SYNC_RAND_STATIC(EligibleAbilities.Length);
		newPerk = EligibleAbilities[AbilityIdx];
		DisallowedPerks.AddItem(newPerk.AbilityName);
	}

	return newPerk;
}
*/