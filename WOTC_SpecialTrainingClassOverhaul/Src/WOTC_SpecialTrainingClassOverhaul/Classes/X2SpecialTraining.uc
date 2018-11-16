class X2SpecialTraining extends X2DataSet
	config(SpecialTrainingClassOverhaul);

var config array<name> Specializations;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2SpecialTrainingTemplate Template;
	local name SpecialTrainingName;
	
	foreach default.Specializations(SpecialTrainingName)
	{
		`CREATE_X2TEMPLATE(class'X2SpecialTrainingTemplate', Template, SpecialTrainingName);
		Templates.AddItem(Template);
	}

	return Templates;
}