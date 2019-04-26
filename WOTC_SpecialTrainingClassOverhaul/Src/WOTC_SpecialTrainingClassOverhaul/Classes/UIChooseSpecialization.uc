class UIChooseSpecialization extends UIInventory;

var array<X2SpecializationTemplate> PrimarySpecializations;
var array<Commodity>		PrimaryCommodities;
var int						PrimarySelectedIndex;
//var array<StateObjectReference> m_arrRefs;


var array<X2SpecializationTemplate> SecondarySpecializations;
var array<Commodity>		SecondaryCommodities;
var int						SecondarySelectedIndex;

var StateObjectReference m_UnitRef;

var bool		m_bShowButton;
var bool		m_bInfoOnly;
var EUIState	m_eMainColor;
var int ConfirmButtonX;
var int ConfirmButtonY;

var public localized String m_strBuy;

var UIX2PanelHeader PrimaryHeader;
var UIList PrimaryList;

var UIX2PanelHeader SecondaryHeader;
var UIList SecondaryList;


simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
			
	PrimaryList = Spawn(class'UIList', self);
	PrimaryList.BGPaddingTop = 90;
	PrimaryList.BGPaddingRight = 30;
	PrimaryList.bSelectFirstAvailable = false;
	PrimaryList.bAnimateOnInit = false;
	PrimaryList.InitList(
		'PrimaryList',
		120, 230,
		568, 710,
		false, true
	);
	PrimaryList.BG.SetAlpha(75);

	PrimaryHeader = Spawn(class'UIX2PanelHeader', self);	
	PrimaryHeader.bAnimateOnInit = false;
	PrimaryHeader.InitPanelHeader('PrimaryHeader',
		"Primary Specializations", "Available Specializations:");	
	PrimaryHeader.SetPosition(120, 150);
	PrimaryHeader.SetHeaderWidth(588);

	
	SecondaryList = Spawn(class'UIList', self);
	SecondaryList.BGPaddingTop = 90;
	SecondaryList.BGPaddingRight = 30;
	SecondaryList.bSelectFirstAvailable = false;
	SecondaryList.bAnimateOnInit = false;
	SecondaryList.InitList(
		'SecondaryList',
		1200, 230,
		568, 710,
		false, true
	);
	SecondaryList.BG.SetAlpha(75);

	SecondaryHeader = Spawn(class'UIX2PanelHeader', self);	
	SecondaryHeader.bAnimateOnInit = false;
	SecondaryHeader.InitPanelHeader('SecondaryHeader',
		"Secondary Specializations", "Available Specializations:");	
	SecondaryHeader.SetPosition(1200, 150);
	SecondaryHeader.SetHeaderWidth(588);
	
	
	// Move and resize list to accommodate label
	List.OnItemDoubleClicked = OnPurchaseClicked;

	SetBuiltLabel("");
	
	PrimarySpecializations.Remove(0, PrimarySpecializations.Length);
	PrimarySpecializations = class'X2SpecializationTemplateManager'.static.GetInstance().GetPrimarySpecializationTemplates(true);
	PrimarySpecializations.Sort(SortSpecializationsByName);

	PrimaryCommodities = ConvertToCommodities(PrimarySpecializations);

	
	SecondarySpecializations.Remove(0, SecondarySpecializations.Length);
	SecondarySpecializations = class'X2SpecializationTemplateManager'.static.GetInstance().GetSecondarySpecializationTemplates(true);
	SecondarySpecializations.Sort(SortSpecializationsByName);

	SecondaryCommodities = ConvertToCommodities(SecondarySpecializations);



	SetChooseResearchLayout();
	PopulateData();
	UpdateNavHelp();

	SetCategory("");
	TitleHeader.Hide();
	ListContainer.Hide();
	ItemCard.Hide();

	Navigator.SetSelected(List);
	List.SetSelectedIndex(0);
}

simulated function array<Commodity> ConvertToCommodities(array<X2SpecializationTemplate> Specializations)
{
	local X2SpecializationTemplate Template;
	local int i;
	local array<Commodity> Commodities;
	local Commodity Comm;

	for (i = 0; i < Specializations.Length; i++)
	{
		Template = Specializations[i];
		
		Comm.Title = Template.DisplayName;
		Comm.Image = Template.IconImage;
		Comm.Desc = Template.Summary;
		Comm.OrderHours = class'SpecialTrainingUtilities'.static.GetSpecialTrainingDays() * 24;

		Commodities.AddItem(Comm);
	}

	return Commodities;
}

function int SortSpecializationsByName(X2SpecializationTemplate a, X2SpecializationTemplate b)
{	
	if (a.DisplayName < b.DisplayName)
		return 1;
	else if (a.DisplayName > b.DisplayName)
		return -1;
	else
		return 0;
}

simulated function PopulateData()
{
	local Commodity Template;
	local int i;

	PrimaryList.ClearItems();
	
	for(i = 0; i < PrimaryCommodities.Length; i++)
	{
		Template = PrimaryCommodities[i];
		Spawn(class'UIInventory_ClassListItem', PrimaryList.itemContainer).InitInventoryListCommodity(Template, , m_strBuy, , , 126);		
	}


	SecondaryList.ClearItems();
	
	for(i = 0; i < SecondaryCommodities.Length; i++)
	{
		Template = SecondaryCommodities[i];
		Spawn(class'UIInventory_ClassListItem', SecondaryList.itemContainer).InitInventoryListCommodity(Template, , m_strBuy, , , 126);
	}
}

simulated function int GetItemIndex(Commodity Item)
{
	local int i;

	for(i = 0; i < PrimaryCommodities.Length; i++)
	{
		if(PrimaryCommodities[i] == Item)
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
	if( ItemIndex > -1 && ItemIndex < PrimaryCommodities.Length )
	{
		return XComHQ.CanAffordCommodity(PrimaryCommodities[ItemIndex]);
	}
	else
	{
		return false;
	}
}

simulated function bool MeetsItemReqs(int ItemIndex)
{
	if( ItemIndex > -1 && ItemIndex < PrimaryCommodities.Length )
	{
		return XComHQ.MeetsCommodityRequirements(PrimaryCommodities[ItemIndex]);
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

simulated function OnPurchaseClicked(UIList kList, int itemIndex)
{
	if (itemIndex != PrimarySelectedIndex)
	{
		PrimarySelectedIndex = itemIndex;
	}

	if (CanAffordItem(PrimarySelectedIndex))
	{
		if (OnSpecializationSelected(PrimarySelectedIndex))
			Movie.Stack.Pop(self);
	}
	else
	{
		PlayNegativeSound();
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
			SpecialTrainingProject.NewSpecializationName = PrimarySpecializations[iOption].DataName;
			break;
		}
		
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Assign");
		
		RefreshFacility();
	}

	return true;
}

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
			PrimarySelectedIndex = List.GetItemIndex(List.GetSelectedItem());
	}
	else
	{
		if (`ISCONTROLLERACTIVE && CanAffordItem(PrimarySelectedIndex) && !IsItemPurchased(PrimarySelectedIndex))
		{
			switch (cmd)
			{
			case class'UIUtilities_Input'.const.FXS_BUTTON_A :
				OnPurchaseClicked(List, PrimarySelectedIndex);
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

	if(`ISCONTROLLERACTIVE && CanAffordItem(PrimarySelectedIndex) && !IsItemPurchased(PrimarySelectedIndex))
	{
		NavHelp.AddSelectNavHelp();
	}
}

simulated function PlayNegativeSound()
{
	if(!`ISCONTROLLERACTIVE)
			class'UIUtilities_Sound'.static.PlayNegativeSound();
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
	ConfirmButtonX = 12
	ConfirmButtonY = 0
	
	InputState = eInputState_Consume	
	bHideOnLoseFocus = true
	
	DisplayTag="UIDisplay_Academy"
	CameraTag="UIDisplay_Academy"
}