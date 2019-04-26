class UIChooseSpecialization extends UIInventory;

var array<X2SpecializationTemplate> PrimarySpecializations;
var array<Commodity>		PrimaryCommodities;
var int						PrimarySelectedIndex;

var array<X2SpecializationTemplate> SecondarySpecializations;
var array<Commodity>		SecondaryCommodities;
var int						SecondarySelectedIndex;

var UIX2PanelHeader PrimaryHeader;
var UIList PrimaryList;
var UIX2PanelHeader SecondaryHeader;
var UIList SecondaryList;

var StateObjectReference m_UnitRef;

var localized string m_strBuy;


simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	BuildList(PrimaryList, PrimaryHeader, 'PrimaryList', 'PrimaryHeader',
		120, "Primary Specializations", "Available Specializations:");

	BuildList(SecondaryList, SecondaryHeader, 'SecondaryList', 'SecondaryHeader',
		1200, "Secondary Specializations", "Available Specializations:");

	List.OnItemDoubleClicked = OnPurchaseClicked;
	
	PrimarySpecializations.Remove(0, PrimarySpecializations.Length);
	PrimarySpecializations = class'X2SpecializationTemplateManager'.static.GetInstance().GetPrimarySpecializationTemplates(true);
	PrimarySpecializations.Sort(SortSpecializationsByName);

	PrimaryCommodities = ConvertToCommodities(PrimarySpecializations);

		
	SecondarySpecializations.Remove(0, SecondarySpecializations.Length);
	SecondarySpecializations = class'X2SpecializationTemplateManager'.static.GetInstance().GetSecondarySpecializationTemplates(true);
	SecondarySpecializations.Sort(SortSpecializationsByName);

	SecondaryCommodities = ConvertToCommodities(SecondarySpecializations);


	PopulateData();
	UpdateNavHelp();
	
	SetBuiltLabel("");
	SetCategory("");
	ListContainer.Hide();
	ItemCard.Hide();
	
	Navigator.SetSelected(List);
	List.SetSelectedIndex(0);
}

simulated function BuildList(out UIList CommList, out UIX2PanelHeader Header, name ListName, name HeaderName,
	int PositionX, optional string HeaderTitle = "", optional string HeaderSubtitle = "")
{
	CommList = Spawn(class'UIList', self);
	CommList.BGPaddingTop = 90;
	CommList.BGPaddingRight = 30;
	CommList.bSelectFirstAvailable = false;
	CommList.bAnimateOnInit = false;
	CommList.InitList(ListName,
		PositionX, 230,
		568, 710,
		false, true
	);
	CommList.BG.SetAlpha(75);

	Header = Spawn(class'UIX2PanelHeader', self);	
	Header.bAnimateOnInit = false;
	Header.InitPanelHeader(HeaderName,
		HeaderTitle, HeaderSubtitle);	
	Header.SetPosition(PositionX, 150);
	Header.SetHeaderWidth(588);
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
	bHideOnLoseFocus = true
	
	InputState = eInputState_Consume
	
	DisplayTag="UIDisplay_Academy"
	CameraTag="UIDisplay_Academy"
}