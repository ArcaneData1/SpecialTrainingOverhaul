class X2EventListener_SpecializationModifiers extends X2EventListener;

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

	Unit = XComGameState_Unit(EventSource);
	Tuple = XComLWTuple(EventData);

	if (Unit.IsAlive() && class'SpecialTrainingUtilities'.static.IsRookieWaitingToTrain(Unit))
	{
		Tuple.Data[0].b = true; //bOverrideShowPromoteIcon;
		Tuple.Data[1].b = true; //bShowPromoteIcon;
	}	

	return ELR_NoInterrupt;
}

// give reward unit special training component and random specializations
static protected function EventListenerReturn RewardUnitGenerated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComGameState_Unit UnitState;
	local XComGameState_Unit_SpecialTraining TrainingState;
	local int i;

	UnitState = XComGameState_Unit(EventData);

	if (UnitState != None && UnitState.GetRank() > 0)
	{
		UnitState = XComGameState_Unit(GameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));

		if (class'SpecialTrainingUtilities'.static.UnitRequiresSpecialTrainingComponent(UnitState))
		{
			TrainingState = class'SpecialTrainingUtilities'.static.AddNewSpecialTrainingComponentTo(UnitState, GameState);
		}
		else
		{
			TrainingState = class'SpecialTrainingUtilities'.static.GetSpecialTrainingComponentOf(UnitState);
			TrainingState = XComGameState_Unit_SpecialTraining(GameState.CreateStateObject(class'XComGameState_Unit_SpecialTraining', TrainingState.ObjectID));
		}

		TrainingState.AddSpecialization('STCO_Gunslinger', GameState);		

		// update stats retroactively
		for (i = 1; i <= UnitState.GetRank(); i++)
		{
			TrainingState.ApplyStatIncreasesForRank(i, GameState);
		}
		
		GameState.AddStateObject(UnitState);
		GameState.AddStateObject(TrainingState);
	}

	return ELR_NoInterrupt;
}

// notify special training component about ranking up
static protected function EventListenerReturn UnitRankUp(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComGameState_Unit UnitState;
	local XComGameState_Unit_SpecialTraining SpecialTraining;

	UnitState = XComGameState_Unit(EventData);
	SpecialTraining = class'SpecialTrainingUtilities'.static.GetSpecialTrainingComponentOf(UnitState);

	if (SpecialTraining != None)
	{
		SpecialTraining.UnitHasRankedUp(GameState);
	}

	return ELR_NoInterrupt;
}