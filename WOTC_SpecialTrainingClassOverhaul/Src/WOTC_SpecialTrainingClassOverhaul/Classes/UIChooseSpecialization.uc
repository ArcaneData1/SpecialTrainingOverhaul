class UIChooseSpecialization extends UIInventory;

var array<Commodity>		arrItems;
var int						iSelectedItem;
var array<StateObjectReference> m_arrRefs;

var array<X2SpecializationTemplate> m_arrSpecializations;

var StateObjectReference m_UnitRef;

var bool		m_bShowButton;
var bool		m_bInfoOnly;
var EUIState	m_eMainColor;
var EUIConfirmButtonStyle m_eStyle;
var int ConfirmButtonX;
var int ConfirmButtonY;

var public localized String m_strBuy;


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

simulated function GetItems()
{
	arrItems = ConvertSpecializationsToCommodities();
}

simulated function array<Commodity> ConvertSpecializationsToCommodities()
{
	local X2SpecializationTemplate TrainingTemplate;
	local int iTraining;
	local array<Commodity> arrCommodoties;
	local Commodity TrainingComm;
	
	m_arrSpecializations.Remove(0, m_arrSpecializations.Length);
	m_arrSpecializations = class'X2SpecializationTemplateManager'.static.GetSpecializationTemplateManager().GetAllSpecializationTemplates(true);
	m_arrSpecializations.Sort(SortSpecializationsByName);

	for (iTraining = 0; iTraining < m_arrSpecializations.Length; iTraining++)
	{
		TrainingTemplate = m_arrSpecializations[iTraining];
		
		TrainingComm.Title = TrainingTemplate.DisplayName;
		TrainingComm.Image = TrainingTemplate.IconImage;
		TrainingComm.Desc = TrainingTemplate.Summary;
		TrainingComm.OrderHours = class'SpecialTrainingUtilities'.static.GetSpecialTrainingDays() * 24;
		//TrainingComm.OrderHours = XComHQ.GetTrainRookieDays() * 24;

		arrCommodoties.AddItem(TrainingComm);
	}

	return arrCommodoties;
}

//-------------- UI LAYOUT --------------------------------------------------------
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	// Move and resize list to accommodate label
	List.OnItemDoubleClicked = OnPurchaseClicked;

	SetBuiltLabel("");

	GetItems();

	SetChooseResearchLayout();
	PopulateData();
	UpdateNavHelp(); // bsg-jrebar (4/20/17): Update on Init instead of receive focus


	
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

simulated function int GetItemIndex(Commodity Item)
{
	local int i;

	for(i = 0; i < arrItems.Length; i++)
	{
		if(arrItems[i] == Item)
		{
			return i;
		}
	}

	return -1;
}

simulated function bool NeedsAttention(int ItemIndex)
{
	// Implement in subclasses
	return false;
}
simulated function bool ShouldShowGoodState(int ItemIndex)
{
	// Implement in subclasses
	return false;
}

simulated function bool CanAffordItem(int ItemIndex)
{
	if( ItemIndex > -1 && ItemIndex < arrItems.Length )
	{
		return XComHQ.CanAffordCommodity(arrItems[ItemIndex]);
	}
	else
	{
		return false;
	}
}

simulated function bool MeetsItemReqs(int ItemIndex)
{
	if( ItemIndex > -1 && ItemIndex < arrItems.Length )
	{
		return XComHQ.MeetsCommodityRequirements(arrItems[ItemIndex]);
	}
	else
	{
		return false;
	}
}

simulated function bool IsItemPurchased(int ItemIndex)
{
	// Implement in subclasses
	return false;
}

simulated function String GetButtonString(int ItemIndex)
{
	return m_strBuy;
}

// bsg-jrebar (4/20/17): Override Inventory versions to look if can afford before select
simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys

	bHandled = super.OnUnrealCommand(cmd, arg);

	if (bHandled)
	{
		if (List.GetSelectedItem() != none)
			iSelectedItem = List.GetItemIndex(List.GetSelectedItem());
	}
	else
	{
		if (`ISCONTROLLERACTIVE && CanAffordItem(iSelectedItem) && !IsItemPurchased(iSelectedItem))
		{
			switch (cmd)
			{
			case class'UIUtilities_Input'.const.FXS_BUTTON_A :
				OnPurchaseClicked(List, iSelectedItem);
				bHandled = true;
				break;
			}
		}
	}

	return bHandled;
}

simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE;
	NavHelp.AddBackButton(CloseScreen);

	if(`ISCONTROLLERACTIVE && CanAffordItem(iSelectedItem) && !IsItemPurchased(iSelectedItem))
	{
		NavHelp.AddSelectNavHelp();
	}
}

simulated function PlayNegativeSound()
{
	if(!`ISCONTROLLERACTIVE)
			class'UIUtilities_Sound'.static.PlayNegativeSound();
}
// bsg-jrebar (4/20/17): end

function int SortSpecializationsByName(X2SpecializationTemplate a, X2SpecializationTemplate b)
{	
	if (a.DisplayName < b.DisplayName)
	{
		return 1;
	}
	else if (a.DisplayName > b.DisplayName)
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
	StaffSlotState = FacilityState.GetEmptyStaffSlotByTemplate('STCO_SpecialTrainingStaffSlot');
	
	if (StaffSlotState != none)
	{
		// The Training project is started when the staff slot is filled. Pass in the NewGameState so the project can be found below.
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Staffing Special Training Slot");
		UnitInfo.UnitRef = m_UnitRef;
		StaffSlotState.FillSlot(UnitInfo, NewGameState);
		
		// Find the new Training Project which was just created by filling the staff slot and set the class
		foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersProjectSpecialTraining', SpecialTrainingProject)
		{
			SpecialTrainingProject.NewSpecializationName = m_arrSpecializations[iOption].DataName;
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
	bAutoSelectFirstNavigable = false
	m_bShowButton = true
	m_bInfoOnly = false
	m_eMainColor = eUIState_Normal
	m_eStyle = eUIConfirmButtonStyle_Default //word button
	ConfirmButtonX = 12
	ConfirmButtonY = 0
	
	InputState = eInputState_Consume	
	bHideOnLoseFocus = true
	
	DisplayTag="UIDisplay_Academy"
	CameraTag="UIDisplay_Academy"
}