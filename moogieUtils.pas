unit moogieUtils;


  function GetFilteredFileName(e: IInterface; removeExt: boolean): string;
    var
      s: string;
    begin
      s := StringReplace(StringReplace(StringReplace(GetFileName(e), '[', '', [rfReplaceAll]), ']', ' -', [rfReplaceAll]), '_', ' ', [rfReplaceAll]);

      if removeExt then
        Result := Copy(s, 1, Length(s) - 4)
      else
        Result := s
  end;

end.