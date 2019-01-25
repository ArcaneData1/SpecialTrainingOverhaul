class X2SpecializationTemplate extends X2DataTemplate config(SpecialTrainingClassOverhaul);

enum ESpecializationType
{
	Primary, Secondary
};

var config array<name> AllowedPrimaryWeapons;
var config array<name> AllowedSlots;
var config string IconImage;
var config array<SoldierClassAbilityType> Abilities;
var config bool CanBeTrained;
var config bool CanBeReplaced;
var config bool IsPrimary;

var localized string DisplayName;
var localized string Summary;

defaultproperties
{
	bShouldCreateDifficultyVariants = false
}