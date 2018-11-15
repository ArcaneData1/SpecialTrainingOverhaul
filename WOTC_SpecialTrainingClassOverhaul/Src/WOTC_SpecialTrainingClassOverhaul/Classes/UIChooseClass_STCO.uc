class UIChooseClass_STCO extends UIChooseClass;

static function bool IsUSSMProject(XComGameState_Unit Unit)
{
	local name UnitClassName;

	UnitClassName = Unit.GetSoldierClassTemplateName();

	if (Unit.GetRank() >= 3 && class'X2StrategyElement_SpecialTrainingStaffSlots'.static.IsTrainableClass(UnitClassName)) {
		return true;
	}

	return false;
}

simulated function array<X2SoldierClassTemplate> GetClasses()
{
	local XComGameState_Unit Unit;

	local X2SoldierClassTemplateManager SoldierClassTemplateMan;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local X2DataTemplate Template;
	local array<X2SoldierClassTemplate> ClassTemplates;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_UnitRef.ObjectID));

	SoldierClassTemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	if (IsUSSMProject(Unit)) {
		class'X2Ability_STCO'.static.GetMulticlassClassTemplates(SoldierClassTemplateMan, Unit, ClassTemplates);
		return ClassTemplates;
	}

	foreach SoldierClassTemplateMan.IterateTemplates(Template, none)
	{		
		SoldierClassTemplate = X2SoldierClassTemplate(Template);
		
		if (SoldierClassTemplate.NumInForcedDeck > 0 && !SoldierClassTemplate.bMultiplayerOnly)
			ClassTemplates.AddItem(SoldierClassTemplate);
	}

	return ClassTemplates;
}

function bool OnClassSelected(int iOption)
{
	local XComGameState NewGameState;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameState_HeadquartersProjectTrainRookie TrainRookieProject;
	local XComGameState_HeadquartersProjectTrain_STCO TrainMulticlassProject;

	local StaffUnitInfo UnitInfo;

	local bool projectFound;

	FacilityState = XComHQ.GetFacilityByName('OfficerTrainingSchool');
	StaffSlotState = FacilityState.GetEmptyStaffSlotByTemplate('USSM_OTSStaffSlot');
	
	if (StaffSlotState != none)
	{
		// The Training project is started when the staff slot is filled. Pass in the NewGameState so the project can be found below.
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Staffing Train Rookie Slot");
		UnitInfo.UnitRef = m_UnitRef;
		StaffSlotState.FillSlot(UnitInfo, NewGameState);
		
		// Find the new Training Project which was just created by filling the staff slot and set the class
		// for the USSM project we need to iterate over the right class or the slot won't get filled
		foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersProjectTrainRookie', TrainRookieProject)
		{
			TrainRookieProject.NewClassName = m_arrClasses[iOption].DataName;
			projectFound = true;
			break;
		}

		if (projectFound == false)
		{
			foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersProjectTrain_STCO', TrainMulticlassProject)
			{
				TrainMulticlassProject.NewClassName = m_arrClasses[iOption].DataName;
				projectFound = true;
				break;
			}
		}
		
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Assign");
		
		RefreshFacility();
	}

	return true;
}