class X2EventListener_SpecializationModifiers extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2DataTemplate> Templates;

    Templates.AddItem(CreateSpecializationModifiersTemplate());

    return Templates;
}

static function X2EventListenerTemplate CreateSpecializationModifiersTemplate()
{
    local X2EventListenerTemplate Template;

    `CREATE_X2TEMPLATE(class'X2EventListenerTemplate', Template, 'STCO_SpecializationModifiers');

    Template.RegisterInStrategy = true;
    Template.AddEvent('NewCrewNotification', AddSpecialTrainingComponentToUnit);
    Template.AddEvent('UnitRankUp',	AddSpecialTrainingComponentToUnit);

    return Template;
}

static protected function EventListenerReturn AddSpecialTrainingComponentToUnit(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(EventData);

	if (UnitState != None && class'SpecialTrainingUtilities'.static.UnitRequiresSpecialTrainingComponent(UnitState))
	{
		class'SpecialTrainingUtilities'.static.AddNewSpecialTrainingComponentTo(UnitState);
	}

	return ELR_NoInterrupt;
}