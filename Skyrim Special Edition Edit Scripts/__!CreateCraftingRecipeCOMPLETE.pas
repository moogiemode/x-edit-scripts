{
	Purpose: Create COBJ records (crafting recipe) from ARMO and WEAP records into new plugin
	Game: The Elder Scrolls V: Skyrim
	Version: 3.0
}

unit UserScript;
uses mteFunctions;


var
	baserecord, destinationFile, book: IInterface;
	bookCreated: boolean;
    destinationFileName: string;
  
//============================================================================
function CreateBook(e: IInterface): IInterface;

    var
        recordGroup, condition, conditions, bookCondition, kwda, k, recipeItem, items, bookRecord: IInterface;
        createdFile: IwbFile;
        bookRecipeRecord: IwbElement;
        newEditorId, newName, bookName, bookFileName: String;

    begin


        bookFileName := '[Craft] ' + StringReplace(StringReplace(StringReplace(GetFileName(e), '[', '', [rfReplaceAll]), ']', ' -', [rfReplaceAll]), '_', ' ', [rfReplaceAll]);
        createdFile := AddNewFileName(bookFileName);

        //Add Masters
		AddRequiredElementMasters(e, createdFile, False);
        //Set As ESL
        SetElementNativeValues(ElementByIndex(createdFile, 0), 'Record Header\Record Flags\ESL', 1);

        // Add Book Category
        recordGroup := Add(createdFile, 'BOOK', true);

        // Create Book record
        bookRecord := Add(recordGroup, 'BOOK', true);

        // Define Book Name
        bookName := Copy(bookFileName, 1, Length(bookFileName) - 4);
        
        //Set Book values
        SetElementEditValues(bookRecord, 'EDID', StringReplace(StringReplace(bookName, ' ', '', [rfReplaceAll]), '-', '', [rfReplaceAll]));//replace all space with underscore in bookname
        SetElementEditValues(bookRecord, 'FULL', bookName);
        SetElementEditValues(bookRecord, 'OBND\X1', -57);
        SetElementEditValues(bookRecord, 'OBND\Y1', -13);
        SetElementEditValues(bookRecord, 'OBND\Z1', -7);
        SetElementEditValues(bookRecord, 'OBND\X2', 57);
        SetElementEditValues(bookRecord, 'OBND\Y2', 1);
        SetElementEditValues(bookRecord, 'OBND\Z2', 7);
        SetElementEditValues(bookRecord, 'DESC', 'A Design Schematic Compendium that enables forging of Equipment.');
        Add(bookRecord, 'Model', true);
        SetElementEditValues(bookRecord, 'Model\MODL', 'Clutter\ElderScroll\ElderScrollFurled.nif');
        SetElementEditValues(bookRecord, 'DATA\Skill', 'None');
        SetElementEditValues(bookRecord, 'DATA\Value', 100);
        SetElementEditValues(bookRecord, 'DATA\Weight', 5);
        SetElementEditValues(bookRecord, 'INAM', '00048783');

        // Do this just because every skyrim book has an empty description
        Add(bookRecord, 'CNAM', true);

        //SETTING UP RECIPE FOR BOOK BELOW

        // Add COBJ Group category
        recordGroup := Add(createdFile, 'COBJ', true);

        // Create Book record
        bookRecipeRecord := Add(recordGroup, 'COBJ', true);

        // Set values
        SetElementEditValues(bookRecipeRecord, 'EDID', GetElementEditValues(bookRecord, 'EDID') + 'Recipe');
        SetElementNativeValues(bookRecipeRecord, 'CNAM', FormID(bookRecord));
        SetElementEditValues(bookRecipeRecord, 'BNAM', '000F46CE'); // Sky Forge
        SetElementEditValues(bookRecipeRecord, 'NAM1', '1');

        items := Add(bookRecipeRecord, 'Items', true);

        // Add new recipe ingredient: 3 Daedra Silk
        recipeItem := ElementByIndex(items, 0);
        AddMasterIfMissing(createdFile, 'ccBGSSSE037-Curios.esl');
        SetElementEditValues(recipeItem, 'CNTO\Item', IntToHex(GetLoadOrderFormID(MainRecordByEditorID(GroupBySignature(FileByName('ccBGSSSE037-Curios.esl'), 'INGR'), 'ccBGSSSE037_DaedraSilk')), 8));
        SetElementNativeValues(recipeItem, 'CNTO\Count', 3);

        // Change/repeat these 3 rows to create new requirements for the recipe
        recipeItem := ElementAssign(items, HighInteger, nil, False);
        SetElementEditValues(recipeItem, 'CNTO\Item', '0003F7F8');//Tundra Cotton
        SetElementNativeValues(recipeItem, 'CNTO\Count', 12);

        // Change/repeat these 3 rows to create new requirements for the recipe
        recipeItem := ElementAssign(items, HighInteger, nil, False);
        SetElementEditValues(recipeItem, 'CNTO\Item', '0003AD5F');//Frost Salts
        SetElementNativeValues(recipeItem, 'CNTO\Count', 3);

        // Change/repeat these 3 rows to create new requirements for the recipe
        recipeItem := ElementAssign(items, HighInteger, nil, False);
        SetElementEditValues(recipeItem, 'CNTO\Item', '0003AD60');//Void Salts
        SetElementNativeValues(recipeItem, 'CNTO\Count', 3);

        // Change/repeat these 3 rows to create new requirements for the recipe
        recipeItem := ElementAssign(items, HighInteger, nil, False);
        SetElementEditValues(recipeItem, 'CNTO\Item', '0003AD5E');//Fire Salts
        SetElementNativeValues(recipeItem, 'CNTO\Count', 3);

        // Change/repeat these 3 rows to create new requirements for the recipe
        recipeItem := ElementAssign(items, HighInteger, nil, False);
        SetElementEditValues(recipeItem, 'CNTO\Item', '0005AD9E');//Gold Ingot
        SetElementNativeValues(recipeItem, 'CNTO\Count', 1);

        // Add Conditions for Book
        Add(bookRecipeRecord, 'Conditions', true);
        bookCondition := ElementByPath(bookRecipeRecord, 'Conditions\Condition\CTDA');


        // Set bookCondition values
        SetEditValue(ElementByIndex(bookCondition, 0), '00100000');
        SetEditValue(ElementByIndex(bookCondition, 2), 1.000000);
        SetEditValue(ElementByIndex(bookCondition, 3), 'GetItemCount');
        SetNativeValue(ElementByName(bookCondition, 'Inventory Object'), FormID(bookRecord));
        SetEditValue(ElementByName(bookCondition, 'Run On'), 'Reference');
        SetEditValue(ElementByName(bookCondition, 'Reference'), '00000014');

    Result := bookRecord;
end;
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

	
		//script will cycle trough all given records (which were highlighted before 'apply script')
	
		if ((Signature(e) <> 'ARMO') and (Signature(e) <> 'WEAP')) then
			Exit;

		//Make new file for recipes
		if not bookCreated then begin
            book := CreateBook(e);
            destinationFile := GetFile(book);
            bookCreated := true;
		end;

		// Add masters
		AddRequiredElementMasters(e, destinationFile, False);
        //creating recipe values
		recipe := wbCopyElementToFile(baserecord, destinationFile, true, true);
		//Adding COBJ values		
		SetElementEditValues(recipe, 'COCT', 1);
		SetElementEditValues(recipe, 'DESC', GetElementEditValues(e, 'FULL'));
		SetElementEditValues(recipe, 'BNAM', '00088105'); //smithing forge
		SetElementEditValues(recipe, 'NAM1', 1);

	    items := Add(recipe, 'Items', true);
        recipeItem := ElementByIndex(items, 0);

        if GetElementEditValues(e, 'BOD2\Armor Type') = 'Light Armor' then begin
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005AD9E');  //Gold Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 2);
        end else if GetElementEditValues(e, 'BOD2\Armor Type') = 'Heavy Armor' then begin
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ACE2');  //Quicksilver Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 2);
        end else if GetElementEditValues(e, 'BOD2\Armor Type') = 'Clothing' then begin
            SetElementEditValues(recipeItem, 'CNTO\Item', '0003F7F8');  //Tundra Cotton
            SetElementNativeValues(recipeItem, 'CNTO\Count', 16);
        end else if HasKeyword(e, 'WeapTypeBattleaxe') then begin
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005AD9E');  //Gold Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 4);
        end else if HasKeyword(e, 'WeapTypeBow') then begin
            SetElementEditValues(recipeItem, 'CNTO\Item', '0006F993');  //Firewood
            SetElementNativeValues(recipeItem, 'CNTO\Count', 24);
        end else if HasKeyword(e, 'WeapTypeDagger') then begin
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005AD9E');  //Gold Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 1);
        end else if HasKeyword(e, 'WeapTypeGreatsword') then begin
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005AD9E');  //Gold Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 4);
        end else if HasKeyword(e, 'WeapTypeMace') then begin
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005AD9E');  //Gold Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 2);
        end else if HasKeyword(e, 'WeapTypeStaff') then begin
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ACE2');  //Quicksilver Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 4);
        end else if HasKeyword(e, 'WeapTypeSword') then begin
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005AD9E');  //Gold Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 3);
        end else if HasKeyword(e, 'WeapTypeWarAxe') then begin
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005AD9E');  //Gold Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 2);
        end else if HasKeyword(e, 'WeapTypeWarhammer') then begin
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005AD9E');  //Gold Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 2);
        end else begin
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005AD9E');  //Gold Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 1);
            AddMessage('Armor Type Unfound, Defaulting to Iron')
        end;
        


		if HasKeyword(e, 'ArmorMaterialLeather') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '000DB5D2'); //Leather
            SetElementNativeValues(recipeItem, 'CNTO\Count', 12);
        end;
		
		if HasKeyword(e, 'ArmorMaterialDaedric') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0003AD5B');  //Daedra Heart
            SetElementNativeValues(recipeItem, 'CNTO\Count', 4);
        end;

		if HasKeyword(e, 'ArmorMaterialDragonplate') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0003ADA4');  //Dragonbone
            SetElementNativeValues(recipeItem, 'CNTO\Count', 3);
        end;

		if HasKeyword(e, 'ArmorMaterialDragonscale') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0003ADA3');  //Dragonscale
            SetElementNativeValues(recipeItem, 'CNTO\Count', 6);
        end;

		if HasKeyword(e, 'ArmorMaterialDwarven') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '000DB8A2');  //Dwarven Metal Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 7);
        end;

		if HasKeyword(e, 'ArmorMaterialEbony') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005AD9D');  //Ebony Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 2);
        end;

		if HasKeyword(e, 'ArmorMaterialElven') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ADA0');  //Quicksilver Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 2);
        end;

		if HasKeyword(e, 'ArmorMaterialElvenGilded') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005AD9F');  //Refined Moonstone
            SetElementNativeValues(recipeItem, 'CNTO\Count', 3);
        end;

		if HasKeyword(e, 'ArmorMaterialGlass') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ADA1');  //Refined Malachite
            SetElementNativeValues(recipeItem, 'CNTO\Count', 2);
        end;

		if HasKeyword(e, 'ArmorMaterialHide') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0003AD75');  //Ice Wolf Pelt
            SetElementNativeValues(recipeItem, 'CNTO\Count', 7);
        end;

		if HasKeyword(e, 'ArmorMaterialImperialHeavy') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ad93');  //Corundum Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 3);
        end;

		if HasKeyword(e, 'ArmorMaterialImperialLight') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ad93');  //Corundum Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 1);
        end;

		if HasKeyword(e, 'ArmorMaterialImperialStudded') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ad93');  //Corundum Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 2);
        end;

		if HasKeyword(e, 'ArmorMaterialIron') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ACE4'); //Iron Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 6);
        end;

		if HasKeyword(e, 'ArmorMaterialIronBanded') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ad93');//Corundum Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 2);
        end;

		if HasKeyword(e, 'ArmorMaterialScaled') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ad93');  //Corundum Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 3);
        end;

		if HasKeyword(e, 'ArmorMaterialSteel') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ACE5');  //Steel Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 4);
        end;

		if HasKeyword(e, 'ArmorMaterialSteelPlate') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ACE5');  //Steel Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 6);
        end;

		if HasKeyword(e, 'ArmorMaterialStormcloak') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0003AD52'); //Bear Pelt
            SetElementNativeValues(recipeItem, 'CNTO\Count', 7);
        end;

		if HasKeyword(e, 'ArmorMaterialStudded') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ACE5');  //Steel Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 4);
        end;

		if HasKeyword(e, 'ArmorMaterialOrcish') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005AD99'); //Orichalcum Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 3);
        end;

		if HasKeyword(e, 'ArmorNightingale') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0003AD60');  //Void Salts
            SetElementNativeValues(recipeItem, 'CNTO\Count', 8);
        end;

		if HasKeyword(e, 'ArmorShield') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005AD9D'); //Ebony Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 2);
        end;

		if HasKeyword(e, 'ArmorClothing') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            AddMasterIfMissing(destinationFile, 'ccBGSSSE037-Curios.esl');
            recipeFormId := IntToHex(GetLoadOrderFormID(MainRecordByEditorID(GroupBySignature(FileByName('ccBGSSSE037-Curios.esl'), 'INGR'), 'ccBGSSSE037_DaedraSilk')), 8);
            SetElementEditValues(recipeItem, 'CNTO\Item', recipeFormId); //Daedra Silk
            SetElementNativeValues(recipeItem, 'CNTO\Count', 7);
        end;

		if HasKeyword(e, 'ClothingBody') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '000727E0');//Butterfly Wing
            SetElementNativeValues(recipeItem, 'CNTO\Count', 12);
        end;

		if HasKeyword(e, 'ArmorJewelry') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0006851F'); //Flawless Diamond
            SetElementNativeValues(recipeItem, 'CNTO\Count', 1);
        end;

        //  #####WEAPONS#####ArmorMaterialOrcish [KYWD:0006BBE5]

		if HasKeyword(e, 'WeapMaterialDaedric') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0003AD5B');  //Daedra Heart
            SetElementNativeValues(recipeItem, 'CNTO\Count', 4);
        end;

		if HasKeyword(e, 'WeapMaterialDraugr') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ad93');  //Corundum Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 2);
        end;

		if HasKeyword(e, 'WeapMaterialDraugrHoned') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ad93');  //Corundum Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 1);
        end;

		if HasKeyword(e, 'WeapMaterialDwarven') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '000DB8A2');  //Dwarven Metal Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 7);
        end;

		if HasKeyword(e, 'WeapMaterialEbony') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005AD9D');  //Ebony Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 3);
        end;

		if HasKeyword(e, 'WeapMaterialElven') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ACE2');  //Quicksilver Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 3);
        end;

		if HasKeyword(e, 'WeapMaterialFalmer') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005AD9F');  //Refined Moonstone
            SetElementNativeValues(recipeItem, 'CNTO\Count', 3);
        end;

		if HasKeyword(e, 'WeapMaterialFalmerHoned') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005AD9F');  //Refined Moonstone
            SetElementNativeValues(recipeItem, 'CNTO\Count', 4);
        end;

		if HasKeyword(e, 'WeapMaterialGlass') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ADA1');  //Refined Malachite
            SetElementNativeValues(recipeItem, 'CNTO\Count', 3);
        end;

		if HasKeyword(e, 'WeapMaterialImperial') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ACE5');  //Steel Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 3);
        end;

		if HasKeyword(e, 'WeapMaterialIron') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ACE4'); //Iron Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 6);
        end;

		if HasKeyword(e, 'WeapMaterialOrcish') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005AD99'); //Orichalcum Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 3);
        end;

		if HasKeyword(e, 'WeapMaterialSilver') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ACE3'); //Silver Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 3);
        end;

		if HasKeyword(e, 'WeapMaterialSteel') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0005ACE5');  //Steel Ingot
            SetElementNativeValues(recipeItem, 'CNTO\Count', 4);
        end;

		if HasKeyword(e, 'WeapMaterialWood') then begin
            recipeItem := ElementAssign(items, HighInteger, nil, False);
            SetElementEditValues(recipeItem, 'CNTO\Item', '0006F993');  //Firewood
            SetElementNativeValues(recipeItem, 'CNTO\Count', 18);
        end;

		//Creating new COBJ record
		
		if not Assigned(recipe) then begin
			AddMessage('Can''t copy base record as new');
			Result := 1;
			Exit;
		end;

        // Add Conditions for Recipe
        Add(recipe, 'Conditions', true);
        recipeCondition := ElementByPath(recipe, 'Conditions\Condition\CTDA');

        // Set recipeCondition values
        SetEditValue(ElementByIndex(recipeCondition, 0), '11000000');
        SetEditValue(ElementByIndex(recipeCondition, 2), 1.000000);
        SetEditValue(ElementByIndex(recipeCondition, 3), 'GetItemCount');
        SetNativeValue(ElementByName(recipeCondition, 'Inventory Object'), FormID(book));
        SetEditValue(ElementByName(recipeCondition, 'Run On'), 'Reference');
        SetEditValue(ElementByName(recipeCondition, 'Reference'), '00000014');

		
		//Setting output as original armor piece
		SetElementEditValues(recipe, 'CNAM', GetElementEditValues(e, 'Record Header\FormID'));
		//Defining record name (Recepie+EditorID of the original armor piece). Feel free to modify if you need another naming convention
		
		SetElementEditValues(recipe, 'EDID', GetElementEditValues(e, 'EDID') + 'Recipe');
		
	end;
	
end.
