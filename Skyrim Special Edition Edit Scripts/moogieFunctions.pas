unit MoogieFunctions;

//============================================================================
function CreateCraftingBook(e: IInterface): IInterface;

    var
        recordGroup, condition, bookCondition, recipeItem, items, bookRecord: IInterface;
        bookRecipeRecord: IwbElement;
        bookName, tempBookName: String;

    begin

        // Get BOOK category
        recordGroup := GroupBySignature(e, 'BOOK');

        // Create BOOK category if it didn't exist
        if not Assigned(recordGroup) then begin
            recordGroup := Add(GetFile(e), 'BOOK', true);
        end;

        // Create Book record
        bookRecord := Add(recordGroup, 'BOOK', true);

        // Define Book Name
        tempBookName := '[Craft] ' + StringReplace(StringReplace(StringReplace(GetFileName(e), '[', '', [rfReplaceAll]), ']', ' -', [rfReplaceAll]), '_', ' ', [rfReplaceAll]);
        bookName := Copy(tempBookName, 1, Length(tempBookName) - 4);
		AddMessage(bookName);        
        //Set Book values
        SetElementEditValues(bookRecord, 'EDID', StringReplace(StringReplace(StringReplace(StringReplace(bookName, ' ', '', [rfReplaceAll]), '-', '', [rfReplaceAll]), '[', '', [rfReplaceAll]), ']', '', [rfReplaceAll]));
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


        //##########SETTING UP RECIPE FOR BOOK BELOW##########

        // Add COBJ Group category
        recordGroup := Add(GetFile(e), 'COBJ', true);

        // Create Book record
        bookRecipeRecord := Add(recordGroup, 'COBJ', true);

        // Set values
        SetElementEditValues(bookRecipeRecord, 'EDID', GetElementEditValues(bookRecord, 'EDID') + 'Recipe');
        SetElementNativeValues(bookRecipeRecord, 'CNAM', FormID(bookRecord));
        SetElementEditValues(bookRecipeRecord, 'BNAM', '0007866A'); // Tanning Rack
        SetElementEditValues(bookRecipeRecord, 'NAM1', '1');

        items := Add(bookRecipeRecord, 'Items', true);

        // Add new recipe ingredient: 3 Daedra Silk
        recipeItem := ElementByIndex(items, 0);
        AddMasterIfMissing(GetFile(e), 'ccBGSSSE037-Curios.esl');
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
end.
//============================================================================
