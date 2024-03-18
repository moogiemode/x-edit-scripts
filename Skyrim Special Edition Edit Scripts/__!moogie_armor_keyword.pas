unit UserScript;var
slKeywordHA: TStringList;
slKeywordLA: TStringList;
slKeywordCL: TStringList;
slKeywordSH: TStringList;
slKeywords: TStringList;

//============================================================================
function Initialize: integer;
begin
// keywords to add
slKeywordCL := TStringList.Create;
slKeywordHA := TStringList.Create;
slKeywordLA := TStringList.Create;
slKeywordSH := TStringList.Create;

slKeywordHA.Add('0006BBD2'); // ArmorHeavy [KYWD:0006BBD2]
slKeywordLA.Add('0006BBD3'); // ArmorLight [KYWD:0006BBD3]
slKeywordCL.Add('0006BBE8'); // ArmorClothing [KYWD:0006BBE8]
slKeywordSH.Add('000965B2'); // ArmorShield [KYWD:000965B2]Clothing
end;
//============================================================================
function Process(e: IInterface): integer;
var
kwda, k: IInterface;
i, j: integer;
exists: boolean;
begin
//only processing armour
if Signature(e) <> 'ARMO' then
Exit;

//determine correct keyword to add
if GetElementEditValues(e, 'BOD2\Armor Type') = 'Light Armor' then
slKeywords := slKeywordLA
else if GetElementEditValues(e, 'BOD2\Armor Type') = 'Heavy Armor' then
slKeywords := slKeywordHA
else if GetElementEditValues(e, 'BOD2\Armor Type') = 'Clothing' then
slKeywords := slKeywordCL
else
Exit;

// get existing keywords list or add a new
kwda := ElementBySignature(e, 'KWDA');
if not Assigned(kwda) then
kwda := Add(e, 'KWDA', True);

// no keywords subrecord (it must exist) - terminate script
if not Assigned(kwda) then begin
AddMessage('No keywords subrecord in ' + Name(e));
Result := 1;
Exit;
end;

// check it isn't a shield - shields don't get armor keywords
// if it is, terminate
for i := 0 to slKeywordSH.Count - 1 do begin
for j := 0 to ElementCount(kwda) - 1 do
if IntToHex(GetNativeValue(ElementByIndex(kwda, j)), 8) = slKeywordSH[i] then
Exit;
end;


// iterate through additional keywords
for i := 0 to slKeywords.Count - 1 do begin

// check if our keyword already exists
exists := false;
for j := 0 to ElementCount(kwda) - 1 do
if IntToHex(GetNativeValue(ElementByIndex(kwda, j)), 8) = slKeywords[i] then begin
exists := true;
Break;
end;

// skip the rest of code in loop if keyword exists
if exists then Continue;

// CK likes to save empty KWDA with only a single NULL form, use it if so
if (ElementCount(kwda) = 1) and (GetNativeValue(ElementByIndex(kwda, 0)) = 0) then
SetEditValue(ElementByIndex(kwda, 0), slKeywords[i])
else begin
// add a new keyword at the end of list
// container, index, element, aOnlySK
k := ElementAssign(kwda, HighInteger, nil, False);
if not Assigned(k) then begin
AddMessage('Can''t add keyword to ' + Name(e));
Exit;
end;
SetEditValue(k, slKeywords[i]);
end;

end;

// update KSIZ keywords count
if not ElementExists(e, 'KSIZ') then
Add(e, 'KSIZ', True);
SetElementNativeValues(e, 'KSIZ', ElementCount(kwda));

AddMessage('Processed: ' + Name(e));
end;

//============================================================================


function Finalize: integer;
begin
slKeywordHA.Free;
slKeywordLA.Free;
slKeywordCL.Free;
slKeywordSH.Free;
end;

end.
