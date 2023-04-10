{
  Change ESM flag on selected plugins.
}
unit UserScript;

var
  bESM, SkipProcess: boolean;

function Initialize: integer;
var
  i: integer;
begin
  Result := 0;
  
  // process only file elements
  try 
    ScriptProcessElements := [etFile];
  except on Exception do
    SkipProcess := true;
    Result := 2;
  end;
  
  i := MessageDlg('Choose [YES] to set, or [NO] to clear ESM flag?', mtConfirmation, [mbYes, mbNo, mbCancel], 0);
  if i = mrYes then bESM := true else
    if i = mrNo then bESM := false else begin
      Result := 1;
      Exit;
    end;
end;

function Process(f: IInterface): integer;

var
  fs : string;

begin
  Result := 0;
  if SkipProcess then begin
    Result := 1001;
    exit;
  end;

  if (ElementType(f) = etMainRecord) then
    exit;

  fs := GetFileName(f);

  if IsEditable(f) then begin
  if bESM then
    SetIsESM(f, true)
  else
    SetIsESM(f, false);
end;

end;
end.
