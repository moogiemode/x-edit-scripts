{
  New script template, only shows processed records
  Assigning any nonzero value to Result will terminate script
}
unit ReplaceRefs;
    var
        replaceMap: TStringList;
        replaceMapVals: TStringList;

        groupsToSearch: TStringList;

    function findObjectByEdid(edid: String): IInterface;
    var
        iFiles, iSigs, j: integer;
        curGroup: IInterface;
        curFile: IInterface;
        curRecord: IInterface;
    begin
        curRecord := nil;
        for iFiles := 0 to FileCount-1 do begin
            curFile := FileByIndex(iFiles);

            if(assigned(curFile)) then begin

                for iSigs:=0 to groupsToSearch.count-1 do begin

                    curGroup := GroupBySignature(curFile, groupsToSearch[iSigs]);
                    if(assigned(curGroup)) then begin
                        curRecord := MainRecordByEditorID(curGroup, edid);
                        if(assigned(curRecord)) then begin
                            Result := curRecord;
                            exit;
                        end;

                    end;

                end;
            end;
        end;
    end;

    function edidAndFormId(e: IInterface): string;
    begin
        Result := '[' +Signature(e)+':'+IntToHex(FormID(e),8)+ ']';
    end;

    function extractEdid(s: String): string;
    var
        i, len: integer;
        curChar: string;

    begin
        len := length(s);
        for i := 0 to len do begin
            curChar := s[i];
            if(curChar = ' ') then begin
                Result := copy(s, 1, i-1);
                exit;
            end;
        end;

        result := '';
    end;

    function registerReplacement(key: String; val: String): boolean;
    var
        i :Integer;
        curObj:IInterface;
        // obj: TObject;
    begin
        Result := true;
        curObj := findObjectByEdid(val);
        if(not assigned(curObj)) then begin
            AddMessage('ERROR: found no element with ID '+val);
            //halt;
            Result := false;
            exit;
        end;

        i := replaceMap.indexOf(key);
        if i < 0 then begin
            i := replaceMap.add(key);
            //replaceMapVals.insert(i, val);
            replaceMapVals.insertObject(i, val, curObj);

        end else begin
            //replaceMapVals[i] := val;
            replaceMapVals[i] := val;
            replaceMapVals.Objects[i] := curObj;
        end;
    end;

    function getReplacementElem(key: String): IInterface;
    var
        i: Integer;
        obj: TObject;
    begin
        result := nil;
        i := replaceMap.indexOf(key);
        if(i >= 0) then begin
            obj := replaceMapVals.objects[i];
            Result := ObjectToElement(obj);
        end;
    end;

    function getReplacement(key: String): string;
    var
        i: Integer;
    begin
        result := '';
        i := replaceMap.indexOf(key);
        if(i >= 0) then begin
            Result := replaceMapVals[i];
        end;
    end;

    // Called before processing
    // You can remove it if script doesn't require initialization code
    function Initialize: integer;
    var
        list: TStringList;
        curLine: String;
        i, j: Integer;
        endPos: Integer;
        key: String;
        val: String;
        spacePos: Integer;
    begin
        Result := 0;

        replaceMap := TStringList.create;
        replaceMapVals := TStringList.create;

        groupsToSearch := TStringList.create;

        groupsToSearch.add('MISC');
        groupsToSearch.add('ALCH');
        groupsToSearch.add('AMMO');
        groupsToSearch.add('ARMO');
        groupsToSearch.add('BOOK');
        groupsToSearch.add('WEAP');
        groupsToSearch.add('CONT');
        groupsToSearch.add('DOOR');
        groupsToSearch.add('FLOR');
        groupsToSearch.add('FURN');
        groupsToSearch.add('LIGH');
        groupsToSearch.add('LVLI');
        groupsToSearch.add('LVLN');
        groupsToSearch.add('MSTT');
        groupsToSearch.add('NOTE');
        groupsToSearch.add('NPC_');
        groupsToSearch.add('STAT');
        groupsToSearch.add('SCOL');
        groupsToSearch.add('TERM');
        groupsToSearch.add('KEYM');
        groupsToSearch.add('ACTI');
        groupsToSearch.add('IDLM');
        groupsToSearch.add('SOUN');



        list := TStringList.Create;
        list.loadFromFile( ProgramPath + 'Edit Scripts\replace-map.txt');
        for i:=0 to list.count-1 do begin
            curLine := trim(list[i]);
            if (length(curLine) > 0) then begin

                if (curLine[1] <> ';') then begin
                    spacePos := -1;
                    for j:=1 to length(curLine) do begin
                        if curLine[j] = '=' then begin
                            spacePos := j;
                            break;
                        end;
                        //AddMessage(curLine[j]);
                    end;
                    if spacePos <> -1 then begin
                        key := trim(copy(curLine, 0, spacePos-1));
                        val := trim(copy(curLine, spacePos+1, length(curLine)));
                        if (key <> '') and (val <> '') then begin
                            if(not registerReplacement(key, val)) then begin
                                Result := 1;
                                exit;
                            end;
                        end;
                    end;
                end;
            end;
        end;
        // TEST
        //replaceMap.SaveToFile (ProgramPath + 'Edit Scripts\FOO.txt');

    end;

    function isSomehowDeleted(e: IInterface): boolean;
    var
        zPosStr : string;
    begin
        Result := false;
        if(GetIsDeleted(e)) then begin
            Result := true;
            exit;
        end;

        if(GetIsInitiallyDisabled(e)) then begin
            zPosStr := GetElementEditValues(e, 'DATA\Position\Z');
            if(zPosStr = '-30000.000000') then begin
                Result := true;
            end;
        end;

    end;

    procedure replaceLinksToRecursive(curElem, source, target: IInterface);
    var
        i: integer;
        curChild, curLinksTo: IInterface;
        editVal: string;
    begin
        for i := 0 to ElementCount(curElem)-1 do begin
            curChild := ElementByIndex(curElem, i);

            editVal := GetEditValue(curChild);
            if(editVal <> '') then begin
                if (IsEditable(curChild)) then begin
                    curLinksTo := LinksTo(curChild);
                    if (equals(curLinksTo, source)) then begin
                        AddMessage('    Updating '+Path(curChild));
                        SetEditValue(curChild, IntToHex(GetLoadOrderFormID(target), 8));
                    end;
                end;
            end else begin
                replaceLinksToRecursive(curChild, source, target);
            end;
        end;
    end;

    procedure removeLinkedRefs(elem: IInterface);
    var
        lref : IInterface;
    begin
        lref := ElementByPath(elem, 'Linked References');
        if(assigned(lref)) then begin
            RemoveElement(elem, lref);
        end;
    end;

    procedure updateReferences(e: IInterface; newRef: IInterface);
    var
        i, num: integer;
        curRef: IInterface;
        refs: array of IInterface;
    begin
        num := ReferencedByCount(e);

        AddMessage('Replacing references to '+edidAndFormId(e) + ' with '+edidAndFormId(newRef));
        for i:=num-1 downto 0 do begin
            curRef := ReferencedByIndex(e, i);
            if (assigned(curRef)) and (Signature(curRef) <> 'TES4') and (Signature(curRef) <> 'CELL') then begin
                AddMessage('  Processing '+edidAndFormId(curRef));
                replaceLinksToRecursive(curRef, e, newRef);
            end;
        end;
        //ReferencedByCount
    end;

    procedure markRefDeleted(e: IInterface);
    var
        xesp: IInterface;
    begin
        SetIsDeleted(e, false);
        SetElementEditValues(e, 'DATA\Position\Z', '-30000.000000');
        xesp := ElementByPath(e, 'XESP');
        if(not assigned(xesp)) then begin
            xesp := Add(e, 'XESP', true);
        end;
        SetElementEditValues(xesp, 'Reference', '00000014');
        SetElementEditValues(xesp, 'Flags\Set Enable State to Opposite of Parent', '1');
        SetIsInitiallyDisabled(e, true);
    end;

    function getReferenceSig(objSig: string): string;
    begin
        Result := 'REFR';
        if (objSig = 'NPC_') or (objSig = 'LVLN') then begin
            Result := 'ACHR';
        end;
    end;

    // called for every record selected in xEdit
    function Process(e: IInterface): integer;
    var
        curName: string;
        curEdid: string;
        curSig, newSig: string;
        replaceEdid: string;
        linkedTo, replaceWith, leMaster, newOverride: IInterface;
        doFullReplace: boolean;
    begin
        Result := 0;

        curSig := Signature(e);

        if (curSig <> 'REFR') and (curSig <> 'ACHR') then begin
            exit;
        end;
        // comment this out if you don't want those messages
        //AddMessage('Processing: ' + FullPath(e));
        //curName := GetElementEditValues(e, 'NAME');

        // curEdid := extractEdid(curName);

        linkedTo := LinksTo(ElementBySignature(e, 'NAME'));
        curEdid := EditorID(linkedTo);

        replaceWith := getReplacementElem(curEdid);



        if(assigned(replaceWith)) then begin
            newSig := getReferenceSig(Signature(replaceWith));
            if(newSig <> curSig) then begin
                // hack until the xEdit bug is fixed
                AddMessage('Cannot replace '+curEdid+' with '+EditorID(replaceWith)+', because REFR<-->ACHR conversion doesn''t work yet.');
                exit;
            end;

            if (IsMaster(e)) then begin

                // replace!
                AddMessage('Replacing '+curEdid+' with '+EditorID(replaceWith)+' in '+edidAndFormId(e));

                if(newSig <> curSig) then begin
                    SetEditValue(ElementBySignature(e, 'NAME'), '');
                    ChangeFormSignature(e, newSig);
                end;
                SetEditValue(ElementBySignature(e, 'NAME'), IntToHex(GetLoadOrderFormID(replaceWith), 8));
            end else begin
                if(isSomehowDeleted(e)) then begin
                    // skip
                    exit;
                end;
                
                leMaster := Master(e);
                
                if (GetIsPersistent(e) <> GetIsPersistent(leMaster)) then begin
                    // it seems to be bad to change both the NAME and the persistence state in the same override
                    AddMessage('Replacing '+curEdid+' with '+EditorID(replaceWith)+' by substitution');

                    // master := Master(e);
                    newOverride := wbCopyElementToFile(e, GetFile(e), true, true);

                    SetEditValue(ElementBySignature(newOverride, 'NAME'), '');
                    ChangeFormSignature(newOverride, newSig);
                    
                    SetEditValue(ElementBySignature(newOverride, 'NAME'), IntToHex(GetLoadOrderFormID(replaceWith), 8));
                    updateReferences(e, newOverride);
                    markRefDeleted(e);
                    removeLinkedRefs(e);
                    
                    SetIsPersistent(newOverride, GetIsPersistent(e));
                    SetIsPersistent(e, false);
                end else begin
                    AddMessage('Replacing '+curEdid+' with '+EditorID(replaceWith)+' in '+edidAndFormId(e));
                    SetEditValue(ElementBySignature(e, 'NAME'), IntToHex(GetLoadOrderFormID(replaceWith), 8));
                end;

            end;

        end;

    end;

    // Called after processing
    // You can remove it if script doesn't require finalization code
    function Finalize: integer;
    begin
        Result := 0;
    end;

end.
