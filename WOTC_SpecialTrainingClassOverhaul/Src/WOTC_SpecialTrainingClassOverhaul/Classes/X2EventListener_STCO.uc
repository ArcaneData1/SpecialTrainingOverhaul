class X2EventListener_STCO extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateStrategyListeners());

    return Templates;
}

static function CHEventListenerTemplate CreateStrategyListeners()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'STCO_StrategyListeners');

	Template.AddCHEvent('OverrideShowPromoteIcon', OverrideShowPromoteIcon, ELD_Immediate);
	Template.AddCHEvent('OverrideImproveCombatIntelligenceAPAmount', OverrideImproveCombatIntelligenceAPAmount, ELD_Immediate);
	Template.AddCHEvent('RewardUnitGenerated', RewardUnitGenerated);
	Template.AddCHEvent('UnitRankUp', UnitRankUp);

	Template.RegisterInStrategy = true;

	return Template;
}

// override promotion icon to display when rookies will get reduced special training time in GTS
static protected function EventListenerReturn OverrideShowPromoteIcon(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit Unit;
	local XComLWTuple Tuple;
	local UIScreenStack ScreenStack;

	ScreenStack = `SCREENSTACK;

	Unit = XComGameState_Unit(EventSource);
	Tuple = XComLWTuple(EventData);

	if (UIPersonnel(ScreenStack.GetCurrentScreen()) != none && Unit.IsAlive() && class'SpecialTrainingUtilities'.static.IsRookieWaitingToTrain(Unit))
	{
		Tuple.Data[0].b = true; //bOverrideShowPromoteIcon;
		Tuple.Data[1].b = true; //bShowPromoteIcon;
	}	

	return ELR_NoInterrupt;
}

// override rewarded AP when soldier's combat intelligence is increased
static protected function EventListenerReturn OverrideImproveCombatIntelligenceAPAmount(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit Unit;
	local XComLWTuple Tuple;
	local int iRank, APIncrease;

	Unit = XComGameState_Unit(EventSource);
	Tuple = XComLWTuple(EventData);

	if (class'SpecialTrainingUtilities'.static.DoesUnitHaveSpecialTrainingComponent(Unit))
	{
		for (iRank = Unit.GetRank(); iRank >= 2; iRank--)
		{
			APIncrease += (GetSoldierAPAmount(iRank, Unit.ComInt) - GetSoldierAPAmount(iRank, ECombatIntelligence(Unit.ComInt - 1)));
		}

		Tuple.Data[0].i = Round(APIncrease);
	}

	return ELR_NoInterrupt;
}

// give reward unit special training component and random specializations
static protected function EventListenerReturn RewardUnitGenerated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComGameState_Unit UnitState;
	local XComGameState_Unit_SpecialTraining TrainingState;
	local int i;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState UpdateState;

	UnitState = XComGameState_Unit(EventData);	

	if (UnitState != None && UnitState.GetSoldierClassTemplateName() == 'STCO_Soldier' && UnitState.GetRank() > 0)
	{
		ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Modify Reward Soldier");
		UpdateState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);
		UnitState = XComGameState_Unit(UpdateState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));

		if (class'SpecialTrainingUtilities'.static.UnitRequiresSpecialTrainingComponent(UnitState))
		{
			TrainingState = class'SpecialTrainingUtilities'.static.AddNewSpecialTrainingComponentTo(UnitState, UpdateState);
		}
		else
		{
			TrainingState = class'SpecialTrainingUtilities'.static.GetSpecialTrainingComponentOf(UnitState);
			TrainingState = XComGameState_Unit_SpecialTraining(UpdateState.CreateStateObject(class'XComGameState_Unit_SpecialTraining', TrainingState.ObjectID));
		}

		TrainingState.TrainRandomSpecializations(UpdateState);

		// update stats retroactively
		for (i = 1; i <= UnitState.GetRank(); i++)
		{
			TrainingState.ApplyStatIncreasesForRank(i, UpdateState);
		}
		
		UpdateState.AddStateObject(UnitState);
		UpdateState.AddStateObject(TrainingState);

		`GAMERULES.SubmitGameState(UpdateState);
	}

	return ELR_NoInterrupt;
}

// notify special training component about ranking up and provides AP points
static protected function EventListenerReturn UnitRankUp(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComGameState_Unit UnitState;
	local XComGameState_Unit_SpecialTraining SpecialTraining;

	UnitState = XComGameState_Unit(EventData);
	SpecialTraining = class'SpecialTrainingUtilities'.static.GetSpecialTrainingComponentOf(UnitState);

	if (SpecialTraining != None)
	{
		SpecialTraining.UnitHasRankedUp(GameState);

		if (UnitState.GetRank() >= 2)
		{
			`log("STCO " $ UnitState.GetFullName() $ " " $ UnitState.GetRank());
			UnitState.AbilityPoints += Round(GetSoldierAPAmount(UnitState.GetRank(), UnitState.ComInt));
			`XEVENTMGR.TriggerEvent('AbilityPointsChange', UnitState, , GameState);
		}
	}

	return ELR_NoInterrupt;
}

static private function int GetSoldierAPAmount(int Rank, ECombatIntelligence eComInt)
{
	local XComGameState_HeadquartersResistance ResHQ;
	local int APReward;

	ResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance', true));

	// get base earned AP at this rank from config
	APReward = class'SpecialTrainingUtilities'.default.BaseAbilityPointsPerRank[Rank];

	// apply bonus based on combat intelligence
	APReward *= class'X2StrategyGameRulesetDataStructures'.default.ResistanceHeroComIntModifiers[eComInt];

	// modify AP based on any resistance orders
	if(ResHQ.AbilityPointScalar > 0)
	{
		APReward = Round(float(APReward) * ResHQ.AbilityPointScalar);
	}

	return APReward;
}