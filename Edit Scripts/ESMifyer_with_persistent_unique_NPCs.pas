unit ESMifyer_with_persistent_unique_NPCs;

function Process(e: IInterface): integer;
var
  i: integer;
  b: boolean;
  f: IwbFile;
  s: string;
begin
  f := getFile(e);
  if (getIsESM(f) = false) then
       setIsESM(f, true);
  s := GetEditValue(ElementByPath(e, 'ACBS\Flags\Unique'));

  b := false;

  if (Signature(e) = 'NPC_') then
    for i := 0 to ReferencedByCount(e)-1 do
      if(Signature(ReferencedByIndex(e,i)) = 'QUST') then
        b := true;
    if((b = true) or (s = '1')) then
      for i := 0 to ReferencedByCount(e)-1 do
        if((Signature(ReferencedByIndex(e,i)) = 'ACHR') and (getFileName(getFile(ReferencedByIndex(e,i))) = getFileName(f))) then
          SetIsPersistent(ReferencedByIndex(e,i), true);
end;

end.
