class UIChooseSpecialization extends UISimpleCommodityScreen;

var array<X2SpecialTrainingTemplate> m_arrSpecializations;

var StateObjectReference m_UnitRef;

//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnPurchaseClicked(UIList kList, int itemIndex)
{
	if (itemIndex != iSelectedItem)
	{
		iSelectedItem = itemIndex;
	}

	if (CanAffordItem(iSelectedItem))
	{
		if (OnSpecializationSelected(iSelectedItem))
			Movie.Stack.Pop(self);
	}
	else
	{
		PlayNegativeSound();
	}
}

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	ItemCard.Hide();
	Navigator.SetSelected(List);
	List.SetSelectedIndex(0);
}

simulated function PopulateData()
{
	local Commodity Template;
	local int i;

	List.ClearItems();
	List.bSelectFirstAvailable = false;
	
	for(i = 0; i < arrItems.Length; i++)
	{
		Template = arrItems[i];
		if(i < m_arrRefs.Length)
		{
			Spawn(class'UIInventory_ClassListItem', List.itemContainer).InitInventoryListCommodity(Template, m_arrRefs[i], GetButtonString(i), m_eStyle, , 126);
		}
		else
		{
			Spawn(class'UIInventory_ClassListItem', List.itemContainer).InitInventoryListCommodity(Template, , GetButtonString(i), m_eStyle, , 126);
		}
	}
}

simulated function PopulateResearchCard(optional Commodity ItemCommodity, optional StateObjectReference ItemRef)
{
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function GetItems()
{
	arrItems = ConvertSpecializationsToCommodities();
}

simulated function array<Commodity> ConvertSpecializationsToCommodities()
{
	local X2SpecialTrainingTemplate TrainingTemplate;
	local int iTraining;
	local array<Commodity> arrCommodoties;
	local Commodity TrainingComm;
	
	m_arrSpecializations.Remove(0, m_arrSpecializations.Length);
	m_arrSpecializations = GetSpecializations();
	m_arrSpecializations.Sort(SortClassesByName);

	for (iTraining = 0; iTraining < m_arrSpecializations.Length; iTraining++)
	{
		TrainingTemplate = m_arrSpecializations[iTraining];
		
		TrainingComm.Title = TrainingTemplate.DisplayName;
		TrainingComm.Image = TrainingTemplate.IconImage;
		TrainingComm.Desc = TrainingTemplate.Summary;
		TrainingComm.OrderHours = XComHQ.GetTrainRookieDays() * 24;

		arrCommodoties.AddItem(TrainingComm);
	}

	return arrCommodoties;
}

//-----------------------------------------------------------------------------

//This is overwritten in the research archives. 
simulated function array<X2SpecialTrainingTemplate> GetSpecializations()
{
	local X2SpecialTrainingTemplateManager TrainingManager;
	local X2SpecialTrainingTemplate TrainingTemplate;
	local X2DataTemplate Template;
	local array<X2SpecialTrainingTemplate> TrainingTemplates;

	TrainingManager = class'X2SpecialTrainingTemplateManager'.static.GetSpecialTrainingTemplateManager();

	foreach TrainingManager.IterateTemplates(Template, none)
	{		
		TrainingTemplate = X2SpecialTrainingTemplate(Template);
		if (true) // ADD LOGIC HERE
			TrainingTemplates.AddItem(TrainingTemplate);
	}

	return TrainingTemplates;
}

function int SortClassesByName(X2SoldierClassTemplate ClassA, X2SoldierClassTemplate ClassB)
{	
	if (ClassA.DisplayName < ClassB.DisplayName)
	{
		return 1;
	}
	else if (ClassA.DisplayName > ClassB.DisplayName)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

function bool OnSpecializationSelected(int iOption)
{
	local XComGameState NewGameState;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameState_HeadquartersProjectSpecialTraining SpecialTrainingProject;
	local StaffUnitInfo UnitInfo;

	FacilityState = XComHQ.GetFacilityByName('OfficerTrainingSchool');
	StaffSlotState = FacilityState.GetEmptyStaffSlotByTemplate('STCO_SecondaryTrainingStaffSlot');
	
	if (StaffSlotState != none)
	{
		// The Training project is started when the staff slot is filled. Pass in the NewGameState so the project can be found below.
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Staffing Special Training Slot");
		UnitInfo.UnitRef = m_UnitRef;
		StaffSlotState.FillSlot(UnitInfo, NewGameState);
		
		// Find the new Training Project which was just created by filling the staff slot and set the class
		foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersProjectSpecialTraining', SpecialTrainingProject)
		{
			SpecialTrainingProject.NewClassName = m_arrSpecializations[iOption].DataName;
			break;
		}
		
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Assign");
		
		RefreshFacility();
	}

	return true;
}

simulated function RefreshFacility()
{
	local UIScreen QueueScreen;

	QueueScreen = Movie.Stack.GetScreen(class'UIFacility_Academy');
	if (QueueScreen != None)
		UIFacility_Academy(QueueScreen).RealizeFacility();
}

//----------------------------------------------------------------
simulated function OnCancelButton(UIButton kButton) { OnCancel(); }
simulated function OnCancel()
{
	CloseScreen();
}

//==============================================================================

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	`HQPRES.m_kAvengerHUD.NavHelp.AddBackButton(OnCancel);
}

defaultproperties
{
	InputState = eInputState_Consume;

	bHideOnLoseFocus = true;
	//bConsumeMouseEvents = true;

	DisplayTag="UIDisplay_Academy"
	CameraTag="UIDisplay_Academy"
}
