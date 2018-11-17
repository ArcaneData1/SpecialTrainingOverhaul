class X2SpecializationTemplate extends X2DataTemplate config(SpecialTrainingClassOverhaul);

var config array<name> AllowedWeapons;
var config array<name> AllowedSlots;
var config string IconImage;
var config array<SoldierClassAbilityType> Abilities;

var localized string DisplayName;
var localized string Summary;

defaultproperties
{
	bShouldCreateDifficultyVariants = false
}