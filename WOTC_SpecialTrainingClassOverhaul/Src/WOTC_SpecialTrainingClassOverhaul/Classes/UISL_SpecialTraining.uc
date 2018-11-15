class UISL_SpecialTraining extends UIScreenListener;

event OnInit(UIScreen Screen) {
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
}

defaultproperties
{
	// Leaving this assigned to none will cause every screen to trigger its signals on this class
	ScreenClass = none;
}