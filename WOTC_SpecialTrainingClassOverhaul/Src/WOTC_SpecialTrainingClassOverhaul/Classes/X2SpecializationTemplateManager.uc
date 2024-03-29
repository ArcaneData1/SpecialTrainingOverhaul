class X2SpecializationTemplateManager extends X2DataTemplateManager config(SpecialTrainingClassOverhaul);

static function X2SpecializationTemplateManager GetInstance()
{
    return X2SpecializationTemplateManager(class'Engine'.static.GetTemplateManager(class'X2SpecializationTemplateManager'));
}

function bool AddSpecializationTemplate(X2SpecializationTemplate Template, bool ReplaceDuplicate = false)
{
	return AddDataTemplate(Template, ReplaceDuplicate);
}

function X2SpecializationTemplate FindSpecializationTemplate(name DataName)
{
	local X2DataTemplate kTemplate;

	kTemplate = FindDataTemplate(DataName);
	if (kTemplate != none)
		return X2SpecializationTemplate(kTemplate);
	return none;
}

function array<X2SpecializationTemplate> GetAllSpecializationTemplates()
{
	local array<X2SpecializationTemplate> arrSpecializationTemplates;
	local X2DataTemplate Template;
	local X2SpecializationTemplate SpecializationTemplate;

	foreach IterateTemplates(Template, none)
	{
		SpecializationTemplate = X2SpecializationTemplate(Template);

		if (SpecializationTemplate != none)
		{
			arrSpecializationTemplates.AddItem(SpecializationTemplate);
		}
	}

	return arrSpecializationTemplates;
}

DefaultProperties
{
	TemplateDefinitionClass=class'X2Specialization'
	ManagedTemplateClass=class'X2SpecializationTemplate'
}