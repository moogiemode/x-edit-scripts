unit UserScript;

var
CountCOBJ: Integer;

function Process(e: IInterface): integer;
var
workbenchKeyword: Cardinal;
begin
// Check if the record is a COBJ
if Signature(e) = 'COBJ' then begin
// Get the workbench keyword of the COBJ
workbenchKeyword := GetElementNativeValues(e, 'BNAM');

// Check if the workbench keyword is not CraftingSmithingForge
if workbenchKeyword <> $00088105 then begin
  AddMessage('Removing: ' + Name(e));
  RemoveNode(e);
  Inc(CountCOBJ);
end;

end;
end;

function Finalize: integer;
begin
AddMessage('COBJ records removed: ' + IntToStr(CountCOBJ));
end;

end.
