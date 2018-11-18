class UIScreenListener_PromotionScreen_STCO extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local XComGameState_Unit UnitState;
	local XComGameState_Unit_SpecialTraining TrainingState;
	local X2SoldierClassTemplate ClassTemplate;
	local X2SpecializationTemplate SpecializationTemplate;
	local UIArmory_PromotionHero Screen_pr;

	Screen_pr = UIArmory_PromotionHero(Screen);

	// if we are not on the promotion screen, then nothing needs to be done
	if (Screen_pr == none)
		return;

	UnitState = Screen_pr.GetUnit();
	TrainingState = class'SpecialTrainingUtilities'.static.GetSpecialTrainingComponentOf(UnitState);

	// if this unit doesn't use the Special Training system, then nothing needs to be done
	if (TrainingState == none)
		return;
		
	ClassTemplate = UnitState.GetSoldierClassTemplate();
	SpecializationTemplate = TrainingState.GetSpecializationAt(0);

	// if ability tree names don't match the soldier's specializations, then change them and repopulate the screen
	if (ClassTemplate.AbilityTreeTitles[0] != SpecializationTemplate.DisplayName)
	{
		ClassTemplate.AbilityTreeTitles[0] = SpecializationTemplate.DisplayName;
		Screen_pr.PopulateData();
	}	
}

defaultproperties
{
	// Leaving this assigned to none will cause every screen to trigger its signals on this class
	ScreenClass = none;
}
