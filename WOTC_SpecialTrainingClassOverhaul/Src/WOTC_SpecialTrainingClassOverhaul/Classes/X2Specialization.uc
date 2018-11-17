class X2Specialization extends X2DataSet config(SpecialTrainingClassOverhaul);

var config array<name> Specializations;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2SpecializationTemplate Template;
	local name SpecializationName;
	
	foreach default.Specializations(SpecializationName)
	{		
		`CREATE_X2TEMPLATE(class'X2SpecializationTemplate', Template, SpecializationName);
		Templates.AddItem(Template);
	}

	return Templates;
}