class X2SpecializationTemplate extends X2DataTemplate config(SpecialTrainingClassOverhaul);

var config array<name> AllowedSlots;
var config string IconImage;
var config array<SoldierClassAbilityType> Abilities;
var config bool CanBeTrained;
var config bool CanBeReplaced;

var localized string DisplayName;
var localized string Summary;

defaultproperties
{
	bShouldCreateDifficultyVariants = false
}