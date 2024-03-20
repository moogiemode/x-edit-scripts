{
	Purpose: Create COBJ records (crafting recipe) from ARMO and WEAP records into new plugin
	Game: The Elder Scrolls V: Skyrim
	Version: 3.0
}

unit __SMMWorkshopMenuPatch;
uses mteFunctions;


var baserecord, destinationFile, book: IInterface;
  
//============================================================================

function Initialize: integer;
begin
    baserecord := RecordByFormID(FileByIndex(0), $000A30C3, true);
end;

//==================ADD RECIPE FOR EQUIPMENT BEGIN==========================================================
function Process(e: IInterface): integer;
	var
		recipe, recipeCondition, recipeItem, items: IInterface;
		keyword, recipeFormId: string;
	
	begin

        AddMessage(GetFileName(baserecord))

	end;
	
end.
