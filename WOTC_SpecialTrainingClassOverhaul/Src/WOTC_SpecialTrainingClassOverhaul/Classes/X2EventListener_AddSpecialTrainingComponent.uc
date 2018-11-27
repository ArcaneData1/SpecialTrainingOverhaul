class X2EventListener_AddSpecialTrainingComponent extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2DataTemplate> Templates;

    Templates.AddItem(CreateNewCrewNotificationTemplate());
    Templates.AddItem(CreateUnitRankUpTemplate());

    return Templates;
}

static function X2EventListenerTemplate CreateNewCrewNotificationTemplate()
{
    local X2EventListenerTemplate Template;

    `CREATE_X2TEMPLATE(class'X2EventListenerTemplate', Template, 'NewCrewNotification');

    Template.RegisterInStrategy = true;
    Template.AddEvent('NewCrewNotification', OnNewCrew);

    return Template;
}

static function X2EventListenerTemplate CreateUnitRankUpTemplate()
{
    local X2EventListenerTemplate Template;

    `CREATE_X2TEMPLATE(class'X2EventListenerTemplate', Template, 'UnitRankUp');

    Template.RegisterInStrategy = true;
    Template.AddEvent('UnitRankUp',	OnRankUp);

    return Template;
}

static protected function EventListenerReturn OnNewCrew(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComGameState_Unit UnitState;

	`log("STCO: Firing New Crew Event!");

	UnitState = XComGameState_Unit(EventData);

	if (UnitState != None && class'SpecialTrainingUtilities'.static.UnitRequiresSpecialTrainingComponent(UnitState))
	{
		`log("STCO: Found unit!");
		class'SpecialTrainingUtilities'.static.AddNewSpecialTrainingComponentTo(UnitState);
	}

	return ELR_NoInterrupt;
}

static protected function EventListenerReturn OnRankUp(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComGameState_Unit UnitState;

	`log("STCO: Firing Rank Up Event!");

	UnitState = XComGameState_Unit(EventData);

	if (UnitState != None && class'SpecialTrainingUtilities'.static.UnitRequiresSpecialTrainingComponent(UnitState))
	{
		`log("STCO: Found unit!");
		class'SpecialTrainingUtilities'.static.AddNewSpecialTrainingComponentTo(UnitState);
	}

	return ELR_NoInterrupt;
}