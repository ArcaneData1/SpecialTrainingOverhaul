class UIScreenListener_PromotionScreen_STCO extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local XComGameState_Unit UnitState;
	local XComGameState_Unit_SpecialTraining TrainingState;
	//local X2SoldierClassTemplate ClassTemplate;
	//local X2SpecialTrainingTemplateManager TrainingTemplateManager;
	//local X2SpecialTrainingTemplate TrainingTemplate;
	local UIArmory_PromotionHero Screen_pr;

	Screen_pr = UIArmory_PromotionHero(Screen);

	// if we are not on the promotion screen, then nothing needs to be done
	if (Screen_pr == none)
		return;

	`redscreen("This is the promotion screen.");

	UnitState = Screen_pr.GetUnit();
	TrainingState = class'SpecialTrainingUtilities'.static.GetSpecialTrainingComponentOf(UnitState);

	// if this unit doesn't use the Special Training system, then nothing needs to be done
	if (TrainingState == none)
		return;

	`redscreen("This unit has a Special Training component.");
		/*
	ClassTemplate = UnitState.GetSoldierClassTemplate();
	TrainingTemplateManager = class'X2SpecialTrainingTemplateManager'.static.GetSpecialTrainingTemplateManager();
	TrainingTemplate = TrainingTemplateManager.FindSpecialTrainingTemplate(TrainingState.CurrentSpecializations[0]);

	// if ability tree names don't match the soldier's specializations, then change them and repopulate the screen
	if (ClassTemplate.AbilityTreeTitles[0] != TrainingTemplate.DisplayName)
	{
		ClassTemplate.AbilityTreeTitles[0] = TrainingTemplate.DisplayName;
		Screen_pr.PopulateData();
	}

	*/
}
/*
	local XComGameState_Unit UnitState;
	local X2SoldierClassTemplate ClassTemplate;
	local name ClassTemplateName;
	local UIArmory_PromotionHero Screen_pr;
	local bool changeMade;
	local name MulticlassClass;
	local string OldTitle;

	local X2SoldierClassTemplateManager SoldierClassTemplateMan;
	local X2SoldierClassTemplate MCTemplate;

	Screen_pr = UIArmory_PromotionHero(Screen);
	changeMade = false;
	
	if (Screen_pr != none) {
		UnitState = Screen_pr.GetUnit();
		ClassTemplate = UnitState.GetSoldierClassTemplate();
		ClassTemplateName = ClassTemplate.DataName;

		if (class'X2StrategyElement_SpecialTrainingStaffSlots'.static.IsTrainableClass(ClassTemplateName)) {
			OldTitle = ClassTemplate.AbilityTreeTitles[3];

			ClassTemplate.AbilityTreeTitles[3] = "";

			MulticlassClass = class'X2Ability_STCO'.static.DetermineMulticlassClassForUnit(UnitState);
			
			if (MulticlassClass != '') {
				SoldierClassTemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
				MCTemplate = SoldierClassTemplateMan.FindSoldierClassTemplate(MulticlassClass);

				ClassTemplate.AbilityTreeTitles[3] = MCTemplate.DisplayName;
			}

			if (OldTitle != ClassTemplate.AbilityTreeTitles[3])
				changeMade = true;

		}

		if (changeMade) {
			Screen_pr.PopulateData();
		}
	}
	*/

defaultproperties
{
	// Leaving this assigned to none will cause every screen to trigger its signals on this class
	ScreenClass = none; // TODO: Set this to the actual screen
}
