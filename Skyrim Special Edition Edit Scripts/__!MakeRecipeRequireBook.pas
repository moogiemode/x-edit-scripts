{
    Makes a new recipe book (BOOK) record and applies having it as a codition to the selected recipes.
    Hotkey: Ctrl+i
    Remember to make overrides of COBJ records before applying script to leave the original records unmodified.
}
unit BOOKintoCOBJ;
uses mteFunctions, moogieFunctions;

var
    bookName: String;
    bookRecord: IwbElement;

function Process(e: IInterface): integer;
var
    condition, conditions: IInterface;

    begin
        // Skip all that is not a COBJ
        if not (Signature(e) = 'COBJ') then
        exit;

        if (Equals(e, bookRecord)) then
        exit;

        // IF TANNING RACK CHANGE TO SMITHING FORGE OTHERWISE EXIT
        if (GetElementEditValues(e, 'BNAM') = 'CraftingTanningRack [KYWD:0007866A]') then begin
            SetElementEditValues(e, 'BNAM', '00088105');
            AddMessage('Tanning Rack Converted to Smithing Forge');
        end else if (GetElementEditValues(e, 'BNAM') = 'CraftingSmithingSkyforge [KYWD:000F46CE]') then begin
            SetElementEditValues(e, 'BNAM', '00088105');
            AddMessage('Sky Forge Converted to Smithing Forge');
        end else if not (GetElementEditValues(e, 'BNAM') = 'CraftingSmithingForge [KYWD:00088105]') then
            exit;
        
        // Create book
        if not Assigned(bookRecord) then begin
            bookRecord := CreateCraftingBook(e);
        end;

        // Check if conditions already exist if not Add new condition (CTDA)
        conditions := ElementByName(e, 'Conditions');
        if not Assigned(conditions) then begin
            Add(e, 'Conditions', true);
            condition := ElementByPath(e, 'Conditions\Condition\CTDA');
        end else begin
            ElementAssign(conditions, HighInteger, nil, false);
            conditions := ElementByName(e, 'Conditions');
            condition := ElementBySignature(ElementByIndex(conditions, ElementCount(conditions) - 1), 'CTDA');
        end;


        // Set condition values
        SetEditValue(ElementByIndex(condition, 0), '11000000');
        SetEditValue(ElementByIndex(condition, 2), 1.000000);
        SetEditValue(ElementByIndex(condition, 3), 'GetItemCount');
        SetNativeValue(ElementByName(condition, 'Inventory Object'), FormID(bookRecord));
        SetEditValue(ElementByName(condition, 'Run On'), 'Reference');
        SetEditValue(ElementByName(condition, 'Reference'), '00000014');

    end;

end.
