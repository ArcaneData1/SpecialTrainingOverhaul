class XComGameState_DynamicClassTemplatePool extends XComGameState_BaseObject config(SpecialTrainingClassOverhaul);

var config name ParentSoldierClassTemplate;
var config int ObjectsInPool;

var protected array<name> AvailableTemplates;

static function XComGameState_DynamicClassTemplatePool GetDynamicClassTemplatePool(optional bool AllowNull = false)
{
	return XComGameState_DynamicClassTemplatePool(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_DynamicClassTemplatePool', AllowNull));
}

static function CreateDynamicClassTemplatePool(XComGameState StartState)
{
	local XComGameState_DynamicClassTemplatePool TemplatePool;

	//first check that there isn't already a singleton instance of the template pool
	if (GetDynamicClassTemplatePool(true) != none)
		return;

	TemplatePool = XComGameState_DynamicClassTemplatePool(StartState.CreateStateObject(class'XComGameState_DynamicClassTemplatePool'));
	TemplatePool.PopulateAvailableTemplates();
	StartState.AddStateObject(TemplatePool);
}

static function CreateObjectsForPool()
{
	local X2SoldierClassTemplateManager TemplateManager;
	local X2SoldierClassTemplate ParentTemplate, ClonedTemplate;
	local int i;
		
	TemplateManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	ParentTemplate = TemplateManager.FindSoldierClassTemplate(default.ParentSoldierClassTemplate);

	for (i = 0; i < default.ObjectsInPool; i++)
	{
		ClonedTemplate = new class'X2SoldierClassTemplate' (ParentTemplate);
		ClonedTemplate.SetTemplateName(name(ParentTemplate.DataName $ "_Instance" $ i));

		TemplateManager.AddSoldierClassTemplate(ClonedTemplate);
	}
}

function PopulateAvailableTemplates()
{
	local X2SoldierClassTemplateManager TemplateManager;
	local array<X2SoldierClassTemplate> Templates;
	local X2SoldierClassTemplate Template;

	TemplateManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	Templates = TemplateManager.GetAllSoldierClassTemplates();

	foreach Templates(Template)
	{
		if (InStr(string(Template.DataName), ParentSoldierClassTemplate $ "_Instance") != -1)
		{
			AvailableTemplates.AddItem(Template.DataName);
		}
	}
}

function X2SoldierClassTemplate GetTemplateFromPool()
{
	local X2SoldierClassTemplateManager TemplateManager;
	local name TemplateName;
	
	TemplateManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	TemplateName = AvailableTemplates[0];
	AvailableTemplates.Remove(0, 1);

	return TemplateManager.FindSoldierClassTemplate(TemplateName);
}

function ReturnTemplateToPool(X2SoldierClassTemplate Template)
{
	AvailableTemplates.AddItem(Template.DataName);
}