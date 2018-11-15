class X2Ability_STCO extends X2Ability config(SpecialTrainingClassOverhaul);

var config array<name> AllowedClasses;
var config array<name> AllowedSubClasses;

struct MulticlassInfo {
	var name ClassName;
	var array<name> Perks;
	var bool DefaultPrimary;
};

var config array<MulticlassInfo> Multiclass;

var config array<name> GrenadeLauncherPerks;
var config array<name> PistolPerks;
var config array<name> SwordPerks;
var config array<name> GremlinPerks;

var config array<name> BadForReroll;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	return Templates;
}

static function GetMulticlassClassTemplates(X2SoldierClassTemplateManager SoldierClassTemplateMan, XComGameState_Unit ForUnit, out array<X2SoldierClassTemplate> ClassTemplates)
{
	local MulticlassInfo MCInfo;
	local X2SoldierClassTemplate Template;
	local name UnitClassName;

	ClassTemplates.Length = 0;

	UnitClassName = ForUnit.GetSoldierClassTemplateName();

	foreach default.Multiclass(MCInfo) {
		if (MCInfo.ClassName != UnitClassName)
		{
			Template = SoldierClassTemplateMan.FindSoldierClassTemplate(MCInfo.ClassName);
			ClassTemplates.AddItem(Template);
		}
	}
}

static function bool GetPerksForMulticlassClass(name MulticlassClass, out array<name> ClassPerks)
{
	local MulticlassInfo MCInfo;
	local name CurrentPerk;
	
	ClassPerks.Length = 0;

	foreach default.Multiclass(MCInfo) {
		if (MulticlassClass == MCInfo.ClassName) {
			foreach MCInfo.Perks(CurrentPerk) {
				ClassPerks.AddItem(CurrentPerk);
			}
			return MCInfo.DefaultPrimary;
		}
	}
}

static function name DetermineMulticlassClassForUnit(XComGameState_Unit UnitState)
{
	local name firstAbilityName;
	local MulticlassInfo MCInfo;

	if (UnitState.AbilityTree[1].Abilities.Length < 4)
		return '';

	firstAbilityName = UnitState.AbilityTree[1].Abilities[3].AbilityName;

	foreach default.Multiclass(MCInfo) {
		if (firstAbilityName == MCInfo.Perks[0]) {
			return MCInfo.ClassName;
		}
	}

	return '';
}