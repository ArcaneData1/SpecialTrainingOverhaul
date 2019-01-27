class UIScreenListener_Armory_STCO extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local XComGameState_Unit UnitState;
	local XComGameState_Unit_SpecialTraining TrainingState;
	local X2SoldierClassTemplate ClassTemplate;
	local array<X2SpecializationTemplate> Specializations;
	local X2SpecializationTemplate Specialization;
	local UIArmory_Loadout Screen_pr;
	local int i;

	Screen_pr = UIArmory_Loadout(Screen);

	// if we are not on the armory loadout screen, then nothing needs to be done
	if (Screen_pr == none)
		return;

	UnitState = Screen_pr.GetUnit();
	TrainingState = class'SpecialTrainingUtilities'.static.GetSpecialTrainingComponentOf(UnitState);

	// if this unit doesn't use the Special Training system, then nothing needs to be done
	if (TrainingState == none)
		return;
		
	ClassTemplate = UnitState.GetSoldierClassTemplate();
	Specializations = TrainingState.GetCurrentSpecializations();

	ClassTemplate.AllowedWeapons.Length = 0;

	foreach Specializations(Specialization)
	{
		for (i = 0; i < Specialization.AllowedPrimaryWeapons.Length; i++)
		{		
			ClassTemplate.AllowedWeapons.Add(1);
			
			ClassTemplate.AllowedWeapons[ClassTemplate.AllowedWeapons.Length - 1].WeaponType = Specialization.AllowedPrimaryWeapons[i];
			ClassTemplate.AllowedWeapons[ClassTemplate.AllowedWeapons.Length - 1].SlotType = eInvSlot_PrimaryWeapon;
		}
	}

	Screen_pr.PopulateData();
}

defaultproperties
{
	// Leaving this assigned to none will cause every screen to trigger its signals on this class
	ScreenClass = none;
}
