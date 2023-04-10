{
    Adds crafting recipe to books and prepends "[Craft] " to the book name.

    This is useful for marking and changing mods that come with crafting recipes tied to books.
}
unit BOOKintoCOBJ;
uses mteFunctions;

function Process(e: IInterface): integer;
var
    recordGroup, condition, conditions, recipeItem, items: IInterface;
    bookRecipeRecord: IwbElement;

begin
    // Skip all that is not a BOOK
    if not (Signature(e) = 'BOOK') then
    exit;

    // Remove unwanted Record Groups
    Remove(GroupBySignature(GetFile(e), 'WRLD'));
    Remove(GroupBySignature(GetFile(e), 'CELL'));
    Remove(GroupBySignature(GetFile(e), 'CONT'));

    // prepend "[Craft] " to book name
    SetElementEditValues(e, 'FULL', '[Craft] ' + GetElementEditValues(e, 'FULL'));

    // Create recipe for book
    begin
        // Get COBJ category
        recordGroup := GroupBySignature(getFile(e), 'COBJ');
        
        // Create record
        bookRecipeRecord := Add(recordGroup, 'COBJ', true);

        // Set values
        SetElementEditValues(bookRecipeRecord, 'EDID', GetElementEditValues(e, 'EDID') + 'Recipe');
        SetElementNativeValues(bookRecipeRecord, 'CNAM', FormID(e));

        SetElementEditValues(bookRecipeRecord, 'BNAM', '0007866A'); // Tanning rack
        SetElementEditValues(bookRecipeRecord, 'NAM1', '1');
        
        items := Add(bookRecipeRecord, 'Items', true);

        // Add new recipe ingredient: 3 gold ingots //daedra silk
        recipeItem := ElementByIndex(items, 0);
        AddMasterIfMissing(getFile(e), 'ccBGSSSE037-Curios.esl');
        SetElementEditValues(recipeItem, 'CNTO\Item', IntToHex(GetLoadOrderFormID(MainRecordByEditorID(GroupBySignature(FileByName('ccBGSSSE037-Curios.esl'), 'INGR'), 'ccBGSSSE037_DaedraSilk')), 8));
        SetElementNativeValues(recipeItem, 'CNTO\Count', 3);

        // Change/repeat these 3 rows to create new requirements for the recipe
        recipeItem := ElementAssign(items, HighInteger, nil, False);
        SetElementEditValues(recipeItem, 'CNTO\Item', '0003F7F8');//Tundra Cotton
        SetElementNativeValues(recipeItem, 'CNTO\Count', 12);

    end;

    // Add new condition (CTDA)
    conditions := ElementByName(bookRecipeRecord, 'Conditions');
    if not Assigned(conditions) then begin
		Add(bookRecipeRecord, 'Conditions', true);
        condition := ElementByPath(bookRecipeRecord, 'Conditions\Condition\CTDA');
    end else begin
        ElementAssign(conditions, HighInteger, nil, false);
        conditions := ElementByName(bookRecipeRecord, 'Conditions');
        condition := ElementBySignature(ElementByIndex(conditions, ElementCount(conditions) - 1), 'CTDA');
    end;

    // Set condition values
    SetEditValue(ElementByIndex(condition, 0), '00100000');
    SetEditValue(ElementByIndex(condition, 2), 1.000000);
    SetEditValue(ElementByIndex(condition, 3), 'GetItemCount');
    SetNativeValue(ElementByName(condition, 'Inventory Object'), FormID(e));
    SetEditValue(ElementByName(condition, 'Run On'), 'Reference');
    SetEditValue(ElementByName(condition, 'Reference'), '00000014');

end;

end.
