{
  New script template, only shows processed records
  Assigning any nonzero value to Result will terminate script
}
unit userscript;

    // Called before processing
    // You can remove it if script doesn't require initialization code
    function Initialize: integer;
    begin
        Result := 0;
    end;

    // called for every record selected in xEdit
    function Process(e: IInterface): integer;
    var
        formId: Integer;
    begin
        Result := 0;

        // comment this out if you don't want those messages
        //AddMessage('Processing: ' + FullPath(e));
        
        formId := (GetLoadOrderFormID(e) and 16777215); // this is 00FFFFFF
        
        AddMessage(GetFileName(GetFile(e))+'    '+IntToStr(formId));
        
        // AddMessage('A '+IntToStr(formId)+' '+IntToHex(formId, 8));
        
        // processing code goes here

    end;

    // Called after processing
    // You can remove it if script doesn't require finalization code
    function Finalize: integer;
    begin
        Result := 0;
    end;

end.
