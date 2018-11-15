class UIAlert_STCO extends UIAlert;

var localized string m_strNewMulticlassTitle;
var localized string m_strNewMulticlassLabel;

simulated function Name GetLibraryID()
{
	return 'Alert_TrainingComplete';
}

simulated function BuildAlert()
{
	BindLibraryItem();

	`log("USSM: UIAlert_USSM.BuildAlert ran");

	BuildMulticlassAlert();

	// Set  up the navigation *after* the alert is built, so that the button visibility can be used. 
	RefreshNavigation();
	if (!Movie.IsMouseActive())
	{
		Navigator.Clear();
	}
}

simulated function BuildMulticlassAlert()
{
	local XComGameState_Unit UnitState;
	local X2AbilityTemplate TrainedAbilityTemplate;
	local array<SoldierClassAbilityType> AbilityTree;
	local X2SoldierClassTemplateManager SoldierClassTemplateMan;
	local X2SoldierClassTemplate ClassTemplate;
	local X2SoldierClassTemplate NewClassTemplate;
	local XGParamTag kTag;
	local XComGameState_ResistanceFaction FactionState;
	local int i;
	local name MulticlassClass;
	local string NewClassIcon, NewClassName, NewClassDescription, ClassIcon, ClassName, RankName;
	local string TitleLabel;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
	ClassTemplate = UnitState.GetSoldierClassTemplate();
	ClassName = Caps(ClassTemplate.DisplayName);
	ClassIcon = ClassTemplate.IconImage;
	RankName = Caps(class'X2ExperienceConfig'.static.GetRankName(UnitState.GetRank(), ClassTemplate.DataName));
	
	FactionState = UnitState.GetResistanceFaction();

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = "";

	SoldierClassTemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	TitleLabel = m_strNewMulticlassTitle;

	MulticlassClass = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'MulticlassClass');

	NewClassTemplate = SoldierClassTemplateMan.FindSoldierClassTemplate(MulticlassClass);
	NewClassName = Caps(NewClassTemplate.DisplayName);
	NewClassIcon = NewClassTemplate.IconImage;
	NewClassDescription = NewClassTemplate.ClassSummary;

	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(TitleLabel);
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(ClassIcon);
	LibraryPanel.MC.QueueString(RankName);
	LibraryPanel.MC.QueueString(UnitState.GetName(eNameType_FullNick));
	LibraryPanel.MC.QueueString(ClassName);

	LibraryPanel.MC.QueueString(NewClassIcon);
	LibraryPanel.MC.QueueString(m_strNewMulticlassLabel);
	LibraryPanel.MC.QueueString(NewClassName);
	LibraryPanel.MC.QueueString(NewClassDescription);

	LibraryPanel.MC.QueueString(m_strViewSoldier);
	LibraryPanel.MC.QueueString(m_strCarryOn);
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();

	//Set icons before hiding the button.
	Button1.SetGamepadIcon(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
	
	//bsg-crobinson (5.17.17): Buttons need to be in a different area for this screen
	Button1.OnSizeRealized = OnTrainingButtonRealized;
	Button2.OnSizeRealized = OnTrainingButtonRealized;
	//bsg-crobinson (5.17.17): end

	// always hide the first button
	Button1.Hide(); 
	Button1.DisableNavigation();

	if (FactionState != none)
		SetFactionIcon(FactionState.GetFactionIcon());
}