class X2SpecialTrainingTemplateManager extends X2DataTemplateManager config(SpecialTrainingClassOverhaul);

//static function X2SpecialTrainingTemplateManager GetSpecialTrainingTemplateManager();

static function X2SpecialTrainingTemplateManager GetSpecialTrainingTemplateManager()
{
    return X2SpecialTrainingTemplateManager(class'Engine'.static.GetTemplateManager(class'X2SpecialTrainingTemplateManager'));
}

function bool AddSpecialTrainingTemplate(X2SpecialTrainingTemplate Template, bool ReplaceDuplicate = false)
{
	return AddDataTemplate(Template, ReplaceDuplicate);
}

function X2SpecialTrainingTemplate FindSpecialTrainingTemplate(name DataName)
{
	local X2DataTemplate kTemplate;

	kTemplate = FindDataTemplate(DataName);
	if (kTemplate != none)
		return X2SpecialTrainingTemplate(kTemplate);
	return none;
}

function array<X2SpecialTrainingTemplate> GetAllSpecialTrainingTemplates()
{
	local array<X2SpecialTrainingTemplate> arrTrainingTemplates;
	local X2DataTemplate Template;
	local X2SpecialTrainingTemplate TrainingTemplate;

	foreach IterateTemplates(Template, none)
	{
		TrainingTemplate = X2SpecialTrainingTemplate(Template);

		if (TrainingTemplate != none)
		{
			arrTrainingTemplates.AddItem(TrainingTemplate);
		}
	}

	return arrTrainingTemplates;
}

DefaultProperties
{
	TemplateDefinitionClass=class'X2SpecialTraining'
	ManagedTemplateClass=class'X2SpecialTrainingTemplate'
}