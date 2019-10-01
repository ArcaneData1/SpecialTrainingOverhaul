class X2SpecializationTemplate extends X2DataTemplate config(SpecialTrainingClassOverhaul);
/*
enum ESpecializationType
{
	Primary, Secondary
};
*/
var config array<name> AllowedPrimaryWeapons;
var config array<name> AllowedSlots;
var config string IconImage;
var config array<SoldierClassAbilityType> Abilities;
var config array<SoldierClassAbilityType> CoreAbilities;
var config array<name> DisallowedSpecs;

var localized string DisplayName;
var localized string Summary;

defaultproperties
{
	bShouldCreateDifficultyVariants = false
}