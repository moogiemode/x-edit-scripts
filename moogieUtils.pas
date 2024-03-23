unit moogieUtils;

uses praUtil;


  function GetFilteredFileName(e: IInterface; removeExt: boolean): string;
    var
      s: string;
    begin
      s := StringReplace(StringReplace(StringReplace(GetFileName(e), '[', '', [rfReplaceAll]), ']', ' -', [rfReplaceAll]), '_', ' ', [rfReplaceAll]);

      if removeExt then begin
        Result := Copy(s, 1, Length(s) - 4)
      end else begin
        Result := s
      end;
  end;

  function CreateNewRecordInFile(e: IwbFile; signature: string): IInterface;
    var
      recGroup: IInterface;
    begin
      if not HasGroup(e, signature) then begin  // Add 'begin' here
        recGroup := Add(e, signature, true); 
      end else begin                            // Add 'begin' and 'end' for the else block
        recGroup := GroupBySignature(e, signature);
      end;  
    Result := Add(recGroup, signature, true); // Does this belong inside the if-else?
  end;

  procedure CreateAndSetStructMember(struct: IInterface; memberName: string; memberType: string; value: variant);
  var
      curMember: IInterface;
  begin
    curMember := createRawStructMember(struct, memberName);
		SetElementEditValues(curMember, 'Type', memberType);
		setPropertyValue(curMember, value);
  end;


end.