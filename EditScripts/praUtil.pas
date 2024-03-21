{
    Some useful functions
}
unit PraUtil;
    uses mteFunctions;

    const STRING_LINE_BREAK = #13#10;

    const
        JSON_TYPE_NONE      = 0; // none
        JSON_TYPE_STRING    = 1; // string
        JSON_TYPE_INT       = 2; // int
        JSON_TYPE_LONG      = 3; // long
        JSON_TYPE_ULONG     = 4; // ulong
        JSON_TYPE_FLOAT     = 5; // float
        JSON_TYPE_DATETIME  = 6; // datetime
        JSON_TYPE_BOOL      = 7; // bool
        JSON_TYPE_ARRAY     = 8; // array
        JSON_TYPE_OBJECT    = 9; // object

    // generic stuff
    {
        Check if two file variables are referring to the same file
    }
    function FilesEqual(file1, file2: IwbFile): boolean;
    begin
        // Should be faster than comparing the filenames
        Result := (GetLoadOrder(file1) = GetLoadOrder(file2));
    end;

    function isSameFile(file1, file2: IwbFile): boolean;
    begin
        Result := FilesEqual(file1, file2);
    end;

    {
        Check if two IInterfaces are equivalent, by recursively comparing the edit values of their contents
    }
    function ElementsEquivalent(e1, e2: IInterface): boolean;
    var
        i, count1, count2: Integer;
        child1, child2: IInterface;
        key1, key2, val1, val2: string;
        tmpResult: boolean;
    begin
        Result := false;

        // trivial crap
        if (not assigned(e1)) and (not assigned(e2)) then begin
            Result := true;
            exit;
        end;

        if(Equals(e1, e2)) then begin
            Result := true;
            exit;
        end;

        count1 := ElementCount(e1);
        count2 := ElementCount(e2);

        if(count1 <> count2) then exit;

        if(count1 = 0) then begin
            val1 := GetEditValue(e1);
            val2 := GetEditValue(e2);
            Result := (val1 = val2);
            exit;
        end;

        for i := 0 to ElementCount(e1)-1 do begin
            child1 := ElementByIndex(e1, i);
            child2 := ElementByIndex(e2, i);

            key1 := DisplayName(child1);
            key2 := DisplayName(child2);

            if(key1 <> key2) then exit;

            if (key1 <> '') then begin
                tmpResult := ElementsEquivalent(child1, child2);
                if(not tmpResult) then exit;
            end;
        end;

        Result := true;
    end;

    {
        Gets a file object by filename
    }
    function FindFile (name: String): IwbFile;
    var
        i: integer;
        curFile: IwbFile;
    begin
        name := LowerCase(name);
        Result := nil;
        for i := 0 to FileCount-1 do
        begin
            curFile := FileByIndex(i);
            if(LowerCase(GetFileName(curFile)) = name) then begin
                Result := curFile;
                exit;
            end;
        end;
    end;

    {
        Returns whenever a file has the ESL header
    }
    function isFileLight(f: IInterface): boolean;
    var
        header, esl: IInterface;
        val: string;
    begin
        Result := false;
        header := ElementBySignature(f, 'TES4');
        esl := ElementByPath(header, 'Record Header\Record Flags\ESL');
        if(not assigned(esl)) then begin
            exit;
        end;

        val := GetEditValue(esl);

        if(val = '1') then begin
            Result := true;
        end;
    end;

    {
        Gets and trims element edit values, for SimSettlements city plans
    }
    function geevt(e: IInterface; name: string): string;
    begin
        Result := trim(GetElementEditValues(e, name));
    end;

    {
        Gets an object by editor ID from any currently loaded file and any group.
        This is not a performant function.
    }
    function FindObjectByEdid(edid: String): IInterface;
    var
        iFiles: integer;
        curFile: IInterface;
        curRecord: IInterface;
    begin
        Result := nil;

        if(edid = '') then exit;

        curRecord := nil;
        for iFiles := 0 to FileCount-1 do begin
            curFile := FileByIndex(iFiles);

            if(assigned(curFile)) then begin

                curRecord := FindObjectInFileByEdid(curFile, edid);
                if (assigned(curRecord)) then begin
                    Result := curRecord;
                    exit;
                end;
            end;
        end;
    end;

    function GetFormByEdid(edid: string): IInterface;
    begin
        Result := FindObjectByEdid(edid);
    end;

    {
        Gets an object by editor ID from the given file and any group.
        This is not a performant function.
    }
    function FindObjectInFileByEdid(theFile: IInterface; edid: string): IInterface;
    var
        iSigs: integer;
        curGroup: IInterface;
        curRecord: IInterface;
    begin
        Result := nil;

        if(edid = '') then exit;

        curRecord := nil;
        for iSigs:=0 to ElementCount(theFile)-1 do begin
            curGroup := ElementByIndex(theFile, iSigs);
            if (Signature(curGroup) = 'GRUP') then begin
                curRecord := MainRecordByEditorID(curGroup, edid);
                if(assigned(curRecord)) then begin
                    Result := curRecord;
                    exit;
                end;
            end;
        end;
    end;

    {
        Iterates through all interior cells in a file, and returns the one with the matching edid
    }
    function findInteriorCellInFileByEdid(sourceFile: IInterface; edid: String): IInterface;
    var
        cellGroup: IInterface;
        block, subblock, cell: IInterface;
        i, j, k: integer;
    begin
        Result := nil;
        cellGroup := GroupBySignature(sourceFile, 'CELL');

        for i:=0 to ElementCount(cellGroup)-1 do begin
            block := ElementByIndex(cellGroup, i);

            for j:=0 to ElementCount(block)-1 do begin
                subblock := ElementByIndex(block, j);

                for k:=0 to ElementCount(subblock)-1 do begin
                    cell := ElementByIndex(subblock, k);

                    if(Signature(cell) = 'CELL') then begin
                        if(EditorID(cell) = edid) then begin
                            Result := cell;
                            exit;
                        end;
                    end;
                end;
            end;
        end;
    end;

    {
        Searches in persistent and temporary references for one with a specific editorID
    }
    function findNamedReference(cell: IInterface; refEdid: string): IInterface;
    var
        i: integer;
        cur, test: IInterface;
    begin
        //  persistent
        test := FindChildGroup(ChildGroup(cell), 8, cell);
        for i:=0 to ElementCount(test)-1 do begin
            cur := ElementByIndex(test, i);
            if(EditorID(cur) = refEdid) then begin
                Result: = cur;
                exit;
            end;
        end;

        test := FindChildGroup(ChildGroup(cell), 9, cell);
        for i:=0 to ElementCount(test)-1 do begin
            cur := ElementByIndex(test, i);
            if(EditorID(cur) = refEdid) then begin
                Result: = cur;
                exit;
            end;
        end;
    end;

    {
        Searches in subject using regexString. Returns the matched group of the given number.
        Matched groups begin at 1, with 0 being the entire matched string.
        Returns empty string on failure.

        Example:
        regexExtract('123 foobar 235 what', '([0-9]+) what', 1) -> '235'

    }
    function regexExtract(subject, regexString: string; returnMatchNr: integer): string;
    var
        regex: TPerlRegEx;
    begin
        regex := TPerlRegEx.Create();
        Result := '';
        try
            regex.RegEx := regexString;
            regex.Subject := subject;

            if(regex.Match()) then begin
                // misnomer, is actually the highest valid index of regex.Groups
                if(regex.GroupCount >= returnMatchNr) then begin
                    Result := regex.Groups[returnMatchNr];
                end;
            end;
        finally
            RegEx.Free;
        end;
    end;

    function regexReplace(subject, regexString, replacement: string): string;
    var
        regex: TPerlRegEx;
    begin
        Result := '';
        regex  := TPerlRegEx.Create();
        try
            regex.RegEx := regexString;
            regex.Subject := subject;
            regex.Replacement := replacement;
            regex.ReplaceAll();
            Result := regex.Subject;
        finally
            RegEx.Free;
        end;
    end;

    {
        Tries to extract the FormID from a string like 'REObjectJS01Note "Note" [BOOK:00031901]'.
        If the string is just a plain hex number already, should parse that as well.
    }
    function findFormIdInString(someStr: string): cardinal;
    var
        regex: TPerlRegEx;
        maybeFormId : cardinal;
        maybeMatch: string;
    begin
        maybeFormId := 0;
        Result := 0;
        if (someStr = '') then exit;

        maybeMatch := regexExtract(someStr, '^([0-9a-fA-F]+)$', 1);
        if (maybeMatch <> '') then begin
            maybeFormId := IntToStr('$' + maybeMatch);
            if(maybeFormId > 0) then begin
                Result := maybeFormId;
                exit;
            end;
        end;

        maybeMatch := regexExtract(someStr, '\[....:([0-9a-fA-F]{8})\]', 1);
        if (maybeMatch <> '') then begin
            maybeFormId := IntToStr('$' + maybeMatch);
            if(maybeFormId > 0) then begin
                Result := maybeFormId;
                exit;
            end;
        end;
    end;

    {
        Tries to find a form by strings like:
            - REObjectJS01Note "Note" [BOOK:00031901]
            - 00031901
            - REObjectJS01Note
        In the first case, it only cares about the FormID, not the EditorID, if any.
    }
    function findFormByString(someStr: string): IInterface;
    var
        maybeFormId: cardinal;
    begin
        maybeFormId := findFormIdInString(someStr);
        if(maybeFormId > 0) then begin
            Result := getFormByLoadOrderFormID(maybeFormId);
            // return nil here if it failed, too
            exit;
        end;

        Result := FindObjectByEdid(someStr);
    end;

    {
        Go upwards from a child to a main record
    }
    function getParentRecord(child: IInterface): IInterface;
    var
        t1: TwbElementType;
        t2: TwbDefType;
    begin
        Result := nil;
        t1 := ElementType(child);

        if(t1 = etMainRecord) then begin
            Result := child;
            exit;
        end;

        Result := getParentRecord(GetContainer(child));
    end;

    function getFormByFilenameAndFormID(filename: string; id: cardinal): IInterface;
    var
        fileObj: IInterface;
        {localFormId: cardinal;}
    begin

        Result := nil;
        fileObj := FindFile(filename);
        if(not assigned(fileObj)) then begin
            exit;
        end;
        Result := getFormByFileAndFormID(FindFile(filename), id);
        {
        localFormId := FileToLoadOrderFormID(fileObj, id);

        Result := RecordByFormID(fileObj, localFormId, true);
        }
    end;

    procedure loadMasterList(list: TStringList; theFile: IInterface);
    var
		curFile: IInterface;
		curFileName: string;
		i: integer;
	begin
		for i:=0 to MasterCount(theFile)-1 do begin
			curFile := MasterByIndex(theFile, i);
			curFileName := GetFileName(curFile);

            if(list.indexOf(curFileName) < 0) then begin
                list.addObject(curFileName, curFile);
                loadMasterList(list, curFile);
            end;
		end;
    end;


	function getMasterList(theFile: IInterface): TStringList;
	begin
		Result := TStringList.create();

        loadMasterList(Result, theFile);
	end;

    function GetFirstNonOverrideElement(theFile: IwbFile): IInterface;
    var
        curGroup, curRecord: IInterface;
        iSigs, i: integer;
    begin
        for iSigs:=0 to ElementCount(theFile)-1 do begin
            curGroup := ElementByIndex(theFile, iSigs);
            if (Signature(curGroup) = 'GRUP') then begin
                for i:=0 to ElementCount(curGroup)-1 do begin
                    curRecord := ElementByIndex(curGroup, i);
                    if(IsMaster(curRecord)) then begin
                        Result := curRecord;
                        exit;
                    end;
                end;
            end;
        end;
    end;

    {
        Returns a formID with the value zero, but all the load order prefixes
        This is because xEdit has absolutely no way whatsoever to actually get the true load order of a file, even less so for ESLs.
        GetLoadOrder is a misnomer, it actually returns the index in the current list.
    }
    function GetZeroFormID(theFile: IwbFile): cardinal;
    var
        numMasters: integer;
        elemFormId, relativeFormID: cardinal;
        firstElem: IInterface;
    begin
        Result := 0;
        if(wbVersionNumber < 67109888) then begin // what does this magic number mean? WHO KNOWS?! But it's what 4.0.4 returns
            numMasters := MasterCount(theFile);
            relativeFormID := (numMasters shl 24) and $FF000000;
            // this no longer works with xedit 4.0.4
            Result := FileFormIDtoLoadOrderFormID(theFile, relativeFormID);
        end else begin
            // try getting the first record in the thing
            firstElem := GetFirstNonOverrideElement(theFile);

            if(not assigned(firstElem)) then begin
                exit;
            end;
            elemFormId := GetLoadOrderFormID(firstElem);

            Result := getLoadOrderPrefix(theFile, elemFormId);
        end;
    end;


    {
        Returns the FormID of e with the LO prefix replaced with the corresponding master index in theFile.
        That is, if the record 0x00001234 is from the second master, this will return 0x01001234
    }
    function getRelativeFormId(theFile: IwbFile; e: IInterface): cardinal;
    var
        numMasters, i: integer;
        curMaster, mainRec, mainFile: IInterface;
    begin
        Result := 0;
        mainRec := MasterOrSelf(e);
        mainFile := GetFile(mainRec);
        numMasters := MasterCount(theFile);
        if(isSameFile(mainFile, theFile)) then begin
            // my own file
            Result := getLocalFormId(theFile, FormID(e)) or (numMasters shl 24);
            exit;
        end;

        for i:=0 to numMasters-1 do begin
            curMaster := MasterByIndex(theFile, i);
            if(isSameFile(mainFile, curMaster)) then begin
                // this file
                Result := getLocalFormId(theFile, FormID(e)) or (i shl 24);
                exit;
            end;
        end;
    end;

    {
        Returns an element by a formId, which is relative to the given file's master list.
        That is, if theFile has at least 2 masters and the given id is 0x01001234, it will
        try to find 0x00001234 in the second master.
        If applicable, will return the corresponding override from theFile
    }
    function elementByRelativeFormId(theFile: IwbFile; id: cardinal): IInterface;
    var
        numMasters, prefix, baseId: integer;
        targetMaster, formMaster: IInterface;
    begin
        Result := nil;
        numMasters := MasterCount(theFile);
        prefix := (id and $FF000000) shr 24;
        baseId := (id and $00FFFFFF);
        if(prefix > numMasters) then begin
            // bad
            exit;
        end;
        if(prefix = numMasters) then begin
            // from theFile itself
            Result := getFormByFileAndFormID(theFile, baseId);
            exit;
        end;

        // otherwise, from a master
        targetMaster := MasterByIndex(theFile, prefix);

        formMaster := getFormByFileAndFormID(targetMaster, baseId);

        Result := getExistingElementOverride(formMaster, theFile);
        if(not assigned(Result)) then begin
            Result := formMaster;
        end;
    end;

    {
        Strips the LO prefix from a FormID
    }
    function getLocalFormId(theFile: IwbFile; id: cardinal): cardinal;
    begin
        if(isFileLight(theFile)) then begin
            Result := $00000FFF and id;
        end else begin;
            Result := $00FFFFFF and id;
        end;
    end;

    {
        Strips the actual ID part from a FormID, leaving only the LO part
    }
    function getLoadOrderPrefix(theFile: IwbFile; id: cardinal): cardinal;
    begin
        if (isFileLight(theFile)) then begin
            Result := $FFFFF000 and id;
        end else begin
            Result := $FF000000 and id;
        end;
    end;

	function getElementLocalFormId(e: IInterface): cardinal;
	begin
		Result := getLocalFormId(GetFile(e), FormID(e));
	end;

    {
        An actually functional version of FileFormIDtoLoadOrderFormID.
    }
    function FileToLoadOrderFormID(theFile: IwbFile; id: cardinal): cardinal;
    var
        prefix: cardinal;
    begin
        prefix := GetZeroFormID(theFile);

        Result := prefix or id;
    end;

    {
        Like FileByLoadOrder, loads the file by actual load order ID, not by the number in the list (aka the 0xFF000000 part)
    }
    function FileByRealLoadOrder(loadOrder: cardinal): IInterface;
    var
        i: integer;
        id, mainLO, test: cardinal;
        curFile: IwbFile;
        curHeader: IInterface;
    begin
        // this sucks... but I have no better idea
        for i := 0 to FileCount-1 do
        begin
            curFile := FileByIndex(i);

            id := GetZeroFormID(curFile);
            mainLO := ($FF000000 and id) shr 24;
            if(mainLO = $FE) then begin
                continue;
            end;

            if(mainLO = loadOrder) then begin
                Result := curFile;
                exit;
            end;
        end;
    end;

    {
        Like FileByRealLoadOrder, but for light file load order (aka the 0x00FFF000 part)
    }
    function FileByLightLoadOrder(lightLoadOrder: cardinal): IInterface;
    var
        i: integer;
        id, mainLO, eslLO: cardinal;
        curFile: IwbFile;
    begin
        // this sucks... but I have no better idea
        for i := 0 to FileCount-1 do
        begin
            curFile := FileByIndex(i);

            id := GetZeroFormID(curFile);

            mainLO := ($FF000000 and id) shr 24;
            if(mainLO <> $FE) then begin
                continue;
            end;

            eslLO := ($FFF000 and id) shr 12;

            if(lightLoadOrder = eslLO) then begin
                Result := curFile;
                exit;
            end;
        end;
    end;


    function getFormByLoadOrderFormID(id: cardinal): IInterface;
    var
        localFormId, fixedId, anotherFormId: cardinal;
        loadOrderIndexInt, lightLOIndex, fileIndex: integer;
        theFile : IInterface;
        isLight : boolean;
    begin
        Result := nil;

        loadOrderIndexInt := ($FF000000 and id) shr 24;

        if(loadOrderIndexInt = $FE) then begin
            // fix the formID for ESL
            lightLOIndex := ($FFF000 and id) shr 12;
            theFile := FileByLightLoadOrder(lightLOIndex);
            isLight := true;
        end else begin
            theFile := FileByRealLoadOrder(loadOrderIndexInt);
            isLight := false;
        end;

        if(not assigned(theFile)) then begin
            exit;
        end;

        Result := getFormByFileAndFormID(theFile, id);
    end;



    {
        Returns a record by it's prefix-less form ID and a file, like Game.GetFormFromFile does
    }
    function getFormByFileAndFormID(theFile: IInterface; id: cardinal): IInterface;
    var
        numMasters: integer;
        localFormId, fixedId, fileIndex: cardinal;
    begin
        Result := nil;
        // It seems like RecordByFormID doesn't care about the real load order prefix.
        // Instead, it expects the first byte to contain the index of the file.
        // Since RecordByFormID also expects that very same format, I suspect that
        // xEdit uses correct light FormIDs for display only, but still gives them a full slot internally.
        fileIndex := GetLoadOrder(theFile);

        if(fileIndex > 255) then begin
            AddMessage('ERROR: Cannot resolve FormID '+IntToHex(id, 8)+' for file '+GetFileName(theFile)+', because you have more than 255 files loaded. xEdit doesn''t actually support this.');
            exit;
        end;

        fileIndex := (fileIndex shl 24) and $FF000000;

        fixedId := fileIndex or getLocalFormId(theFile, id);

        Result := RecordByFormID(theFile, fixedId, false);
    end;

    {
        Returns a record by it's form ID and a file. This should also work
    }
    function getFormByFileAndPrefixedFormID(theFile: IInterface; id: cardinal): IInterface;
    var
        numMasters: integer;
        localFormId, fixedId, fileIndex: cardinal;
    begin
        Result := nil;
        // It seems like RecordByFormID doesn't care about the real load order prefix.
        // Instead, it expects the first byte to contain the index of the file.
        // Since RecordByFormID also expects that very same format, I suspect that
        // xEdit uses correct light FormIDs for display only, but still gives them a full slot internally.
        fileIndex := GetLoadOrder(theFile);

        if(fileIndex > 255) then begin
            AddMessage('ERROR: Cannot resolve FormID '+IntToHex(id, 8)+' for file '+GetFileName(theFile)+', because you have more than 255 files loaded. xEdit doesn''t actually support this.');
            exit;
        end;

        fileIndex := (fileIndex shl 24) and $FF000000;

        fixedId := fileIndex or getLocalFormId(theFile, id);

        Result := RecordByFormID(theFile, fixedId, false);
    end;

    {
        Calculates a string's CRC32
        To output as string, use IntToHex(foo, 8)

        Function by zilav
    }
    function StringCRC32(s: string): Cardinal;
    var
        ms: TMemoryStream;
        bw: TBinaryWriter;
        br: TBinaryReader;
    begin
        ms := TMemoryStream.Create;
        bw := TBinaryWriter.Create(ms);
        bw.Write(s);
        bw.Free;
        ms.Position := 0;
        br := TBinaryReader.Create(ms);
        Result := wbCRC32Data(br.ReadBytes(ms.Size));
        br.Free;
        ms.Free;
    end;

    procedure WriteElementRecursive(e: IInterface; bw: TBinaryWriter; index: integer);
    var
        i: Integer;
        child, maybeLinksTo: IInterface
    begin
        for i := 0 to ElementCount(e)-1 do begin
            child := ElementByIndex(e, i);
            maybeLinksTo := LinksTo(child);
            // no clue how much is actually necessary here...
            bw.Write(IntToStr(index));
            bw.Write(';');
            bw.Write(DisplayName(child));
            bw.Write(';');
            if(assigned(maybeLinksTo)) then begin
                bw.Write(FormToAbsStr(child));
            end else begin
                bw.Write(GetEditValue(child));
            end;

            WriteElementRecursive(child, bw, index+1);
        end;

    end;


    function ElementCRC32(e: IInterface): string;
    var
        ms: TMemoryStream;
        bw: TBinaryWriter;
        br: TBinaryReader;
    begin
        ms := TMemoryStream.Create;
        bw := TBinaryWriter.Create(ms);

        WriteElementRecursive(e, bw, 0);

        bw.Free;
        ms.Position := 0;
        br := TBinaryReader.Create(ms);
        Result := wbCRC32Data(br.ReadBytes(ms.Size));
        br.Free;
        ms.Free;
    end;

    {
        Copypasta of the above, just using the MD5 function

        IntToHex(foo, 16)
    }
    function StringMD5(s: string): cardinal;
    var
        ms: TMemoryStream;
        bw: TBinaryWriter;
        br: TBinaryReader;
    begin
        ms := TMemoryStream.Create;
        bw := TBinaryWriter.Create(ms);
        bw.Write(s);
        bw.Free;
        ms.Position := 0;
        br := TBinaryReader.Create(ms);
        Result := wbMD5Data(br.ReadBytes(ms.Size));
        br.Free;
        ms.Free;
    end;

    {
        Tries to recursively create the given path. Returns the last subrecord on success. Returns nil on failure.
    }
    function ensurePath(elem: IInterface; path: string): IInterface;
    var
        i: integer;
        helper: TStringList;
        curPart, nextPart : IInterface;
    begin
        Result := ElementByPath(elem, path);
        if(assigned(Result)) then exit;

        curPart := elem;

        helper := TStringList.create;
        helper.Delimiter := '\';
        helper.StrictDelimiter := True; // Spaces excluded from being a delimiter
        helper.DelimitedText := path;

        for i := 0 to helper.count-1 do begin
            nextPart := ElementByName(curPart, helper[i]);
            if(not assigned(nextPart)) then begin
                nextPart := Add(elem, helper[i], true);
            end;

            if(not assigned(nextPart)) then begin
                // fail
                helper.free();
                exit;
            end;

            curPart := nextPart;
        end;

        Result := curPart;

        helper.free();
    end;

    function getFileAsJson(fullPath: string): TJsonObject;
    begin
        Result := TJsonObject.create();

        try
            Result.LoadFromFile(fullPath);
        except

            on E: Exception do begin
                AddMessage('Failed to parse '+fullPath+': '+E.Message);
                Result.free();
                Result := nil;
            end else begin
                AddMessage('Failed to parse '+fullPath+'.');
                Result.free();
                Result := nil;
            end;

            // code here seems to be unreachable
        end;
    end;

    {
        A potentially fixed version of seev, where path is created if it doesn't exist
    }
    procedure SetEditValueByPath(e: IInterface; path, value: string);
    var
        subrec: IInterface;
    begin
        subrec := ensurePath(e, path);
        if(assigned(subrec)) then begin
            SetEditValue(subrec, value);
        end;
    end;

    // Conversion functions
    {
        Returns "True" or "False"
    }
    function BoolToStr(b: boolean): string;
    begin
        if(b) then begin
            Result := 'True';
        end else begin
            Result := 'False';
        end;
    end;

    {
        Returns true for "true" (in any case), false otherwise
    }
    function StrToBool(s: string): boolean;
    begin
        Result := (LowerCase(s)  = 'true');
    end;

    function ternaryOp(condition: boolean; ifTrue: variant; ifFalse: variant): variant;
    begin
        if(condition) then begin
            Result := ifTrue;
            exit;
        end;
        Result := ifFalse;
    end;

    {
        because xEdit says that '%0001110000000000000000000000001' is not a valid integer value
    }
    function BinToInt(bin: string): cardinal;
    var
        curChar, tmp: string;
        i: integer;
        factor: cardinal;
    begin
        Result := 0;
        factor := 1;
        if(length(bin) > 64) then begin
            AddMessage('Binary string too long: '+bin);
            exit;
        end;

        tmp := bin;

        for i:=length(tmp) downto 1 do begin
            curChar := tmp[i];
            if(curChar = '1') then begin
                Result := (Result + factor);
            end else begin
                if(curChar <> '0') then begin
                    AddMessage(tmp+' is not a valid binary string');
                    Result := 0;
                    exit;
                end;
            end;

            factor := factor * 2;
        end;
    end;

    {
        Encodes the given form's ID into a string, so that it can be found again using that string.
		Bascially just gets the current LO formID as a hex string
    }
    function FormToStr(form: IInterface): string;
    var
        curFormID: cardinal;
    begin
        curFormID := GetLoadOrderFormID(MasterOrSelf(form));

        Result := IntToHex(curFormID, 8);
    end;

    {
        Decodes a string generated by FormToStr into a FormID and finds the correspodning form
    }
    function StrToForm(str: string): IInterface;
    var
        theFormID: cardinal;
    begin
        Result := nil;
        if(str = '') then exit;
        // StrToInt64 must be used, otherwise large values will just cause an error
        theFormID := StrToInt64('$' + str);

        if(theFormID = 0) then exit;

        Result := getFormByLoadOrderFormID(theFormID);
    end;

	{
		Encodes a form into Filename:formID
	}
	function FormToAbsStr(form: IInterface): string;
	var
		theFile: IInterface;
		theFormId: cardinal;
		theFilename: string;
	begin
		theFile := GetFile(form);
		theFilename := GetFileName(theFile);
		theFormId := getLocalFormId(theFile, FormID(form));

		Result := theFilename + ':'+IntToHex(theFormId, 8);
	end;

	{
		Decodes a Filename:formID string into a form
	}
	function AbsStrToForm(str: string): IInterface;
	var
		separatorPos: integer;
		theFilename, formIdStr: string;
		theFormId: cardinal;
	begin
		Result := nil;
		separatorPos := Pos(':', str);
		if(separatorPos <= 0) then begin
			exit;
		end;

		theFilename := copy(str, 1, separatorPos-1);
		formIdStr := copy(str, separatorPos+1, length(str)-separatorPos+1);

		Result := getFormByFilenameAndFormID(theFilename, StrToInt('$'+formIdStr));
	end;

	function floatEqualsWithTolerance(val1, val2, tolerance: float): boolean;
	begin
		Result := abs(val1 - val2) < tolerance;
	end;

	function floatEquals(val1, val2: float): boolean;
	begin
		Result := floatEqualsWithTolerance(val1, val2, 0.0001);
	end;

    {
        Checks whenever a subrecord is any kind of array
    }
    function isSubrecordArray(e: IInterface): boolean;
    var
        t1: TwbElementType;
        t2: TwbDefType;
    begin
        Result := false;
        t1 := ElementType(e);

        if (t1 = etSubRecordArray) or (t1 = etArray) then begin
            Result := true;
            exit;
        end;

        t2 := DefType(e);

        if (t2 = dtSubRecordArray) or (t2 = dtByteArray) or (t2 = dtArray) then begin
            Result := true;
            exit;
        end;
    end;

    {
        Checks whenever a subrecord is something non-iterable, basically
    }
    function isSubrecordScalar(e: IInterface): boolean;
    var
        t1: TwbElementType;
        t2: TwbDefType;
    begin
        Result := false;
        t1 := ElementType(e);

        if (t1 = etSubRecordArray) or (t1 = etArray) or (t1 = etMainRecord) or (t1 = etGroupRecord) or (t1 = etSubRecordStruct) or (t1 = etSubRecordArray) or (t1 = etSubRecordUnion)
            or (t1 = etArray) or (t1 = etStruct) or (t1 = etUnion)
        then begin
            Result := false;
            exit;
        end;

        if (t1 = etFlag) or (t1 = etValue) then begin
            Result := true;
            exit;
        end;

        t2 := DefType(e);

        if (t2 = dtSubRecordArray) or (t2 = dtByteArray) or (t2 = dtArray) or (t2 = dtSubRecordStruct) or (t2 = dtSubRecordUnion)
            or (t2 = dtStruct) or (t2 = dtUnion)
        then begin
            Result := false;
            exit;
        end;

        if (t2 = dtString) or (t2 = dtLString) or (t2 = dtLenString) or (t2 = dtInteger) or (t2 = dtFloat) or (t2 = dtEmpty) then begin
            Result := true;
            exit;
        end;
    end;

    {
        Checks whenever the element is modified, but not saved (bold in xEdit)
    }
    function isElementUnsaved(e: IInterface): boolean;
    begin
        Result := GetElementState(e, 2);
    end;

    {

    // other flags which could be checked:
    function IntToEsState(anInt: Integer): TwbElementState;
    begin
      case anInt of
        0: Result := esModified;
        1: Result := esInternalModified;
        2: Result := esUnsaved;
        3: Result := esSortKeyValid;
        4: Result := esExtendedSortKeyValid;
        5: Result := esHidden;
        6: Result := esParentHidden;
        7: Result := esParentHiddenChecked;
        8: Result := esNotReachable;
        9: Result := esReachable;
        10: Result := esTagged;
        11: Result := esResolving;
        12: Result := esNotSuitableToAddTo;
      else
        Result := esDummy;
      end;
    end;
    }

    // Keyword-manipulation functions
    {
        Adds a keyword to a specific signature. KWYD is the most usual one
    }
    procedure addKeywordByPath(toElem: IInterface; kw: IInterface; targetSig: string);
    var
        container: IInterface;
        newElem: IInterface;
        num: integer;
        formId: LongWord;
    begin
        container := ElementByPath(toElem, targetSig);
        num := ElementCount(container);

        if((not assigned(container)) or (num <= 0)) then begin
            container := Add(toElem, targetSig, True);
        end;

        newElem := ElementAssign(container, HighInteger, nil, False);
        formId := GetLoadOrderFormID(kw);
        SetEditValue(newElem, IntToHex(formId, 8));
    end;

    function hasKeywordByPath(e: IInterface; kw: variant; signature: String): boolean;
    var
        kwda: IInterface;
        curKW: IInterface;
        i, variantType: Integer;
        kwEdid: string;
    begin
        Result := false;
        kwda := ElementByPath(e, signature);

        variantType := varType(kw);
        if (variantType = 258) or (variantType = varString) then begin
            kwEdid := kw;
        end else begin
            kwEdid := EditorID(kw);
        end;

        for i := 0 to ElementCount(kwda)-1 do begin
            curKW := LinksTo(ElementByIndex(kwda, i));

            if EditorID(curKW) = kwEdid then begin
                Result := true;
                exit;
            end
        end;
    end;

    procedure ensureKeywordByPath(toElem: IInterface; kw: IInterface; targetSig: string);
    begin
        if(not hasKeywordByPath(toElem, kw, targetSig)) then begin
            addKeywordByPath(toElem, kw, targetSig);
        end;
    end;

    procedure removeKeywordByPath(e: IInterface; kw: variant; signature: String);
    var
        kwda: IInterface;
        curKW, kwdaEntry: IInterface;
        i, variantType: Integer;
        kwEdid: string;
    begin
        kwda := ElementByPath(e, signature);

        variantType := varType(kw);
        if (variantType = 258) or (variantType = varString) then begin
            kwEdid := kw;
        end else begin
            kwEdid := EditorID(kw);
        end;

        for i := 0 to ElementCount(kwda)-1 do begin
            kwdaEntry := ElementByIndex(kwda, i);
            curKW := LinksTo(kwdaEntry);
            if (EditorID(curKW) = kwEdid) then begin
                // this seems to be more reliable than by index
                RemoveElement(kwda, kwdaEntry);
                exit;
            end
        end;
    end;

    function getAvByPath(e: IInterface; av: variant; signature: string): float;
    var
        kwda, curKW, curProp: IInterface;
        i, variantType: Integer;
        kwEdid: string;
    begin
        Result := 0.0;
        kwda := ElementByPath(e, signature);

        variantType := varType(av);
        if (variantType = 258) or (variantType = varString) then begin
            kwEdid := av;
        end else begin
            kwEdid := EditorID(av);
        end;

        for i := 0 to ElementCount(kwda)-1 do begin
            curProp := ElementByIndex(kwda, i);

            curKw := pathLinksTo(curProp, 'Actor Value');

            if EditorID(curKW) = kwEdid then begin
                Result := StrToFloat(GetElementEditValues(curKw, 'Value'));
                exit;
            end
        end;

    end;

    // Formlist-Manipulation functions

    {
        Looks in the given formlist for an enthry with the given edid, and if found, returns it
    }
    function getFormlistEntryByEdid(formList: IInterface; edid: string): IInterface;
    var
        numElems, i : integer;
        curElem: IInterface;
        formIdList: IInterface;
    begin
        Result := nil;
        formIdList := ElementByName(formList, 'FormIDs');
        if(assigned(formIdList)) then begin
            numElems := ElementCount(formIdList);

            if(numElems > 0) then begin

                for i := 0 to numElems-1 do begin
                    curElem := LinksTo(ElementByIndex(formIdList, i));

                    if(geevt(curElem, 'EDID') = edid) then begin
                        Result := curElem;
                        exit;
                    end;
                end;

            end;
        end;
    end;

    {
        Checks whenever the given formlist has the given entry
    }
    function hasFormlistEntry(formList: IInterface; entry: IInterface): boolean;
    var
        numElems, i : integer;
        curElem: IInterface;
        formIdList: IInterface;
    begin
        Result := false;
        formIdList := ElementByName(formList, 'FormIDs');
        if(assigned(formIdList)) then begin
            numElems := ElementCount(formIdList);

            if(numElems > 0) then begin

                for i := 0 to numElems-1 do begin
                    curElem := LinksTo(ElementByIndex(formIdList, i));

                    if(isSameForm(curElem, entry)) then begin
                        Result := true;
                        exit;
                    end;
                end;

            end;
        end;
    end;

    {
        Adds a form to a formlist, if it doesn't exist already
    }
    procedure addToFormlist(formList: IInterface; newForm: IInterface);
    var
        numElems, i : integer;
        curElem: IInterface;
        formIdList: IInterface;
    begin

        if(not assigned(newForm)) or (GetLoadOrderFormID(newForm) = 0) then begin
            exit;
        end;


        formIdList := ElementByName(formList, 'FormIDs');
        if(not assigned(formIdList)) then begin
            formIdList := Add(formList, 'FormIDs', True);
            // This automatically gives you one free entry pointing to NULL
            curElem := ElementByIndex(formIdList, i);
            SetEditValue(curElem, IntToHex(GetLoadOrderFormID(newForm), 8));
            exit;
        end;


        numElems := ElementCount(formIdList);

        if(numElems > 0) then begin
            for i := 0 to numElems-1 do begin
                curElem := LinksTo(ElementByIndex(formIdList, i));
                if(isSameForm(curElem, newForm)) then begin
                    exit;
                end;
            end;
        end;


        curElem := ElementAssign(formIdList, HighInteger, nil, False);
        SetEditValue(curElem, IntToHex(GetLoadOrderFormID(newForm), 8));

    end;

    {
        Removes everything from the formlist
    }
    procedure clearFormList(formList: IInterface);
    var
        formIdList: IInterface;
    begin
        // levelFormlist
        formIdList := ElementByName(formList, 'FormIDs');
        if(assigned(formIdList)) then begin
            RemoveElement(formList, formIdList);
        end;
    end;

    {
        Gets the length of a formlist
    }
    function getFormListLength(formList: IInterface): integer;
    var
        formIdList: IInterface;
    begin
        formIdList := ElementByName(formList, 'FormIDs');
        Result := 0;
        if(not assigned(formIdList)) then begin
            exit;
        end;
        Result := ElementCount(formIdList);
    end;

    {
        Gets a specific element from a formlist
    }
    function getFormListEntry(formList: IInterface; index: integer): IInterface;
    var
        formIdList: IInterface;
    begin
        Result := nil;
        formIdList := ElementByName(formList, 'FormIDs');
        if(not assigned(formIdList)) then begin
            exit;
        end;
        Result := LinksTo(ElementByIndex(formIdList, index));
    end;

    {
        Creates a new entry at the end of an array-like element at path.
        Takes care of the free first item automatically.
    }
    function addNewEntry(elem: IInterface; path: string): IInterface;
    var
        elemAtPath: IInterface;
    begin
        elemAtPath := ElementByPath(elem, path);

        if(assigned(elemAtPath)) then begin
            Result := ElementAssign(elemAtPath, HighInteger, nil, False);
            exit;
        end;

        elemAtPath := EnsurePath(elem, path);
        // see if we got the free elem
        if(ElementCount(elemAtPath) = 1) then begin
            Result := ElementByIndex(elemAtPath, 0);
            exit;
        end;

        Result := ElementAssign(elemAtPath, HighInteger, nil, False);
    end;
    
    {
        Removes the elem located at path from elem.
    }
    procedure removeByPath(elem: IInterface; path: string);
    var
        i, len: integer;
        pathTmp, curChar, pathParent, pathChild: string;
        parent, child: IInterface;
    begin
        // find the last \
        pathTmp := path;
        pathParent := pathTmp;
        len := length(path);

        for i:=len downto 1 do begin
            curChar := copy(pathTmp, i, 1);

            if (curChar = '\') or (curChar = '/') then begin
                pathParent := copy(pathTmp, 1, i-1);
                pathChild := copy(pathTmp, i+1, len-i);
                break;
            end;
        end;

        if(pathChild = '') then begin
            // easy
            child := ElementByPath(pathParent);
            if(assigned(child)) then begin
                RemoveElement(elem, child);
            end;
        end;

        parent := ElementByPath(elem, pathParent);
        if(not assigned(parent)) then begin
            exit;
        end;

        child := ElementByPath(parent, pathChild);
        if(not assigned(child)) then begin
            exit;
        end;

        RemoveElement(parent, child);
    end;

    // helper functions
    {
        Checks if string haystack starts with string needle
    }
    function strStartsWith(haystack: String; needle: String): boolean;
    var
        len: Integer;
        cmp: String;
    begin
        if needle = haystack then begin
            Result := true;
            exit;
        end;

        len := length(needle);

        if len > length(haystack) then begin
            Result := false;
            exit;
        end;

        cmp := copy(haystack, 0, len);

        Result := (cmp = needle);
    end;

    function strStartsWithCI(haystack: String; needle: String): boolean;
    begin
        Result := strStartsWith(LowerCase(haystack), LowerCase(needle));
    end;

    {
        Checks if string haystack ends with string needle
    }
    function strEndsWith(haystack: String; needle: String): boolean;
    var
        len, lenHaystack: Integer;
        cmp: String;
    begin
        if needle = haystack then begin
            Result := true;
            exit;
        end;

        len := length(needle);
        lenHaystack := length(haystack);

        if len > lenHaystack then begin
            Result := false;
            exit;
        end;

        cmp := copy(haystack, lenHaystack-len+1, lenHaystack);

        Result := (cmp = needle);
    end;

    function strEndsWithCI(haystack: String; needle: String): boolean;
    begin
        Result := strEndsWith(LowerCase(haystack), LowerCase(needle));
    end;
    
    function getStringAfter(str, separator: string): string;
    var
        p: integer;
    begin

        p := Pos(separator, str);
        if(p <= 0) then begin
            Result := str;
            exit;
        end;

        p := p + length(separator);

        Result := copy(str, p, length(str)-p+1);
    end;

	function StringRepeat(str: string; len: integer): string;
	var
		i: integer;
	begin
		Result := '';
		for i:=0 to len-1 do begin
			Result := Result + str;
		end;
	end;

    function strUpperCaseFirst(str: string): string;
    var
        firstChar, rest: string;
        len: integer;
    begin
        len := length(str);

        firstChar := copy(str, 0, 1);
        rest := copy(str, 2, len);

        Result := UpperCase(firstChar) + LowerCase(rest);
    end;

    {
        Checks if f1 is being referenced by f2.
        Possible usecase: pass a formlist as f2 for faster lookup
    }
    function isReferencedBy(f1, f2: IInterface): boolean;
    var
        numRefs, i: integer;
        curRec: IInterface;
    begin
        Result := false;

        numRefs := ReferencedByCount(f1)-1;
        for i := 0 to numRefs do begin
            curRec := ReferencedByIndex(f1, i);
            if(isSameForm(curRec, f2)) then begin
                Result := true;
                exit;
            end;
        end;
    end;

    {
        Checks if the two objects are the same, because IInterfaces aren't comparable
    }
    function isSameForm(e1: IInterface; e2: IInterface): boolean;
    begin
        Result := Equals(MasterOrSelf(e1), MasterOrSelf(e2));
    end;

    function FormsEqual(e1: IInterface; e2: IInterface): boolean;
    begin
        Result := isSameForm(e1, e2);
    end;

    {
        Setter to the getter LinksTo. formToAdd can be nil, to set the property to none
    }
    procedure setLinksTo(e: IInterface; formToAdd: IInterface);
    begin
        if(assigned(formToAdd)) then begin
            SetEditValue(e, IntToHex(GetLoadOrderFormID(formToAdd), 8));
        end else begin
            SetEditValue(e, IntToHex(0, 8));
        end;
    end;

    {
        A combination of SetElementEditValues and SetLinksTo: sets the value at the given path to the given form
    }
    procedure setPathLinksTo(e: IInterface; path: string; form: IInterface);
    begin
        if(assigned(form)) then begin
            SetElementEditValues(e, path, IntToHex(GetLoadOrderFormID(form), 8));
        end else begin
            SetElementEditValues(e, path, IntToHex(0, 8));
        end;
    end;

    {
        A combination of ElementByPath and LinksTo: returns what the element links to at the given path
    }
    function pathLinksTo(e: IInterface; path: string): IInterface;
    begin
        Result := LinksTo(ElementByPath(e, path));
    end;

    {
        Checks whenever the element has the given flag set
    }
    function hasFlag(e: IInterface; flagName: string): boolean;
    var
        i: integer;
        curName, curValue: string;
    begin
        Result := false;

        for i:=0 to ElementCount(e)-1 do begin
            curName := DisplayName(ElementByIndex(e, i));
            curValue := GetEditValue(ElementByIndex(e, i));
            if (curName = flagName) and (curValue = '1') then begin
                Result := true;
                exit;
            end;
        end
    end;

    {
        similar to GetElementByPath, but will create everything along the path if it doesn't exist

        Note: here, the path can only contain signatures.
            Good: 'VMAD\Scripts'
            Bad:  'VMAD - Virtual Machine Adapter\Scripts'
    }
    function CreateElementByPath(e: IInterface; objectPath: string): IInterface;
    var
        i, index: integer;
        path: TStringList;
        curSubpath: IInterface;
    begin
        // replace forward slashes with backslashes
        objectPath := StringReplace(objectPath, '/', '\', [rfReplaceAll]);

        // prepare path stringlist delimited by backslashes
        path := TStringList.Create;
        path.Delimiter := '\';
        path.StrictDelimiter := true;
        path.DelimitedText := objectPath;

        curSubpath := e;

        // traverse path
        for i := 0 to Pred(path.count) do begin
            curSubpath := ElementByPath(e, path[i]);
            if(not assigned(curSubpath)) then begin
                curSubpath := Add(e, path[i], true);
            end;
            e := curSubpath;
        end;

        // set result
        Result := e;
    end;

    // script functions
    {
        Get a script by name
    }
    function getScript(e: IInterface; scriptName: String): IInterface;
    var
        curScript, scripts: IInterface;
        i: integer;
    begin
        Result := nil;
        scripts := ElementByPath(e, 'VMAD - Virtual Machine Adapter\Scripts');

        scriptName := LowerCase(scriptName);

        for i := 0 to ElementCount(scripts)-1 do begin
            curScript := ElementByIndex(scripts, i);

            if(LowerCase(geevt(curScript, 'scriptName')) = scriptName) then begin
                Result := curScript;
                exit;
            end;
        end;
    end;

    {
        Get the first script in the element, no matter what
    }
    function getFirstScript(e: IInterface): IInterface;
    var
        curScript, scripts: IInterface;
        i: integer;
    begin
        Result := nil;
        scripts := ElementByPath(e, 'VMAD - Virtual Machine Adapter\Scripts');

        for i := 0 to ElementCount(scripts)-1 do begin
            Result := ElementByIndex(scripts, i);
            exit;
        end;
    end;

    {
        Gets the name for the first script, in case the object type or such depends on that
    }
    function getFirstScriptName(e: IInterface): string;
    var
        curScript, scripts: IInterface;
        i: integer;
    begin
        Result := '';
        curScript := getFirstScript(e);
        if(not assigned(curScript)) then exit;

        Result := GetElementEditValues(curScript, 'scriptName');
    end;

    {
        Like getScript, but if it doesn't exist, it will be added
    }
    function addScript(e: IInterface; scriptName: String): IInterface;
    var
        curScript, scripts: IInterface;
        i: integer;
    begin
        Result := nil;
        scripts := createElementByPath(e, 'VMAD\Scripts');


        for i := 0 to ElementCount(scripts)-1 do begin
            curScript := ElementByIndex(scripts, i);

            if(geevt(curScript, 'scriptName') = scriptName) then begin
                Result := curScript;
                exit;
            end;
        end;

        // otherwise append
        Result := ElementAssign(scripts, HighInteger, nil, False);//Add(propRoot, 'Property', true);
        SetElementEditValues(Result, 'scriptName', scriptName);
    end;

    {
        Gets a script property by name. Returns the raw IInterface representing it
    }
    function getRawScriptProp(script: IInterface; propName: String): IInterface;
    var
        propRoot, prop: IInterface;
        i: integer;
    begin
        propRoot := ElementByPath(script, 'Properties');
        Result := nil;

        if(not assigned(propRoot)) then begin
            exit;
        end;

        propName := LowerCase(propName);

        for i := 0 to ElementCount(propRoot)-1 do begin
            prop := ElementByIndex(propRoot, i);

            if(LowerCase(geevt(prop, 'propertyName')) = propName) then begin
                Result := prop;
                exit;
            end;
        end;
    end;

    {
        Gets a struct member by name. Returns the raw IInterface representing it
    }
    function getRawStructMember(struct: IInterface; memberName: String): IInterface;
    var
        member: IInterface;
        i: integer;
    begin
        Result := nil;

        memberName := LowerCase(memberName);

        for i := 0 to ElementCount(struct)-1 do begin
            member := ElementByIndex(struct, i);

            if(LowerCase(geevt(member, 'memberName')) = memberName) then begin
                Result := member;
                exit;
            end;
        end;
    end;

    {
        Gets a script property by name. Returns different things, depending on the type:
        - Int32: returns integer
        - Float: returns float
        - String: retuns string
        - Bool: returns boolean
        - Object: resolves what the property links to, returns IInterface
        - Struct: returns the raw property value
        - Any array: returns the raw property value
        - property doesn't exist: returns nil
    }
    function getScriptProp(script: IInterface; propName: String): variant;
    begin
        Result := getScriptPropDefault(script, propName, nil);
    end;

    {
        Extracts the value of a script property or struct member, returns a variant representing it
    }
    function getValueAsVariant(prop: IInterface; defaultValue: variant): variant;
    var
        typeStr, valueString: string;
        propVal: IInterface;
    begin
        typeStr := geevt(prop, 'Type');
        if(strStartsWith(typeStr, 'Array of') or (typeStr = 'Struct')) then begin

            Result := ElementByPath(prop, 'Value\'+typeStr);
            exit;
        end;

        // easy types
        if(typeStr = 'String') then begin
            Result := geevt(prop, typeStr);
            exit;
        end;

        if(typeStr = 'Int32') then begin
            Result := StrToInt(geevt(prop, typeStr));
            exit;
        end;

        if(typeStr = 'Float') then begin
            Result := StrToFloat(geevt(prop, typeStr));
            exit;
        end;

        if(typeStr = 'Bool') then begin
            Result := StrToBool(geevt(prop, typeStr));
            exit;
        end;

        // Object
        if(typeStr = 'Object') then begin
            propVal := ElementByPath(prop, 'Value\Object Union\Object v2\FormID');
            Result := LinksTo(propVal);
            exit;
        end;

        Result := defaultValue;
    end;

    {
        like getScriptProp, but if the property doesn't exist, the given default value will be returned
    }
    function getScriptPropDefault(script: IInterface; propName: String; defaultValue: variant): variant;
    var
        prop, propVal: IInterface;
        typeStr: string;
    begin
        prop := getRawScriptProp(script, propName);
        if(not assigned(prop)) then begin
            Result := defaultValue;
            exit;
        end;

        Result := getValueAsVariant(prop, defaultValue);
    end;

    function getScriptPropType(script: IInterface; propName: String): string;
    var
        prop, propVal: IInterface;
        typeStr: string;
    begin
        prop := getRawScriptProp(script, propName);
        if(not assigned(prop)) then begin
            Result := '';
            exit;
        end;

        Result := geevt(prop, 'Type');
    end;

    {
        Creates a raw script property and returns it
    }
    function createRawScriptProp(script: IInterface; propName: String): IInterface;
    var
        propRoot, prop: IInterface;
        i: integer;
    begin
        propRoot := ElementByPath(script, 'Properties');

        if(not assigned(propRoot)) then begin
            // try creating
            propRoot := Add(script, 'Properties', true);
            if(not assigned(propRoot)) then begin
                AddMessage('ERROR: SCRIPT HAS NO PROPERTIES. THIS IS BAD');
                exit;
            end;
        end;

        Result := nil;

        for i := 0 to ElementCount(propRoot)-1 do begin
            prop := ElementByIndex(propRoot, i);

            if(geevt(prop, 'propertyName') = propName) then begin

                Result := prop;
                exit;
            end;
        end;

        // if still alive, somehow append
        Result := ElementAssign(propRoot, HighInteger, nil, False);//Add(propRoot, 'Property', true);

        SetElementEditValues(Result, 'propertyName', propName);
    end;

    {
        Deletes a script property by name
    }
    procedure deleteScriptProp(script: IInterface; propName: String);
    var
        propRoot, prop: IInterface;
        i: integer;
    begin
        propRoot := ElementByPath(script, 'Properties');

        if(not assigned(propRoot)) then begin
            exit;
        end;

        for i := 0 to ElementCount(propRoot)-1 do begin
            prop := ElementByIndex(propRoot, i);

            if(geevt(prop, 'propertyName') = propName) then begin
                RemoveElement(propRoot, prop);
                exit;
            end;
        end;

    end;

    procedure deleteScriptProps(script: IInterface);
    var
        propRoot: IInterface;
    begin
        propRoot := ElementByPath(script, 'Properties');
        while (ElementCount(propRoot) > 0) do begin
            RemoveElement(propRoot, 0);
        end;
        // RemoveElement(script, propRoot);
    end;

    {
        Creates a raw struct member and returns it
    }
    function createRawStructMember(struct: IInterface; memberName: String): IInterface;
    var
        prop: IInterface;
        i: integer;
    begin
        Result := nil;

        for i := 0 to ElementCount(struct)-1 do begin
            prop := ElementByIndex(struct, i);

            if(geevt(prop, 'memberName') = memberName) then begin

                Result := prop;
                exit;
            end;
        end;
        // if still alive, somehow append
        Result := ElementAssign(struct, HighInteger, nil, False);

        SetElementEditValues(Result, 'memberName', memberName);
    end;

    {
        Delete a struct member by name
    }
    procedure deleteStructMember(struct: IInterface; memberName: String);
    var
        prop: IInterface;
        i: integer;
    begin

        for i := 0 to ElementCount(struct)-1 do begin
            prop := ElementByIndex(struct, i);

            if(geevt(prop, 'memberName') = memberName) then begin
                RemoveElement(struct, prop);
                exit;
            end;
        end;
    end;

    {
        Get or create a script property with a specified type. The result will have the given type, no matter what it had before
    }
    function getOrCreateScriptProp(script: IInterface; propName: String; propType: String): IInterface;
    begin
        Result := createRawScriptProp(script, propName);

        SetElementEditValues(Result, 'Type', propType);
    end;

    function getOrCreateScriptPropStruct(script: IInterface; propName: String): IInterface;
    begin
        Result := createRawScriptProp(script, propName);

        SetElementEditValues(Result, 'Type', 'Struct');

        Result := ElementByPath(Result, 'Value\Struct');
    end;

    function getOrCreateScriptPropArrayOfObject(script: IInterface; propName: String): IInterface;
    begin
        Result := createRawScriptProp(script, propName);

        SetElementEditValues(Result, 'Type', 'Array of Object');

        Result := ElementByPath(Result, 'Value\Array of Object');
    end;

    function getOrCreateScriptPropArrayOfStruct(script: IInterface; propName: String): IInterface;
    begin
        Result := createRawScriptProp(script, propName);

        SetElementEditValues(Result, 'Type', 'Array of Struct');

        Result := ElementByPath(Result, 'Value\Array of Struct');
    end;

    {
        Mostly a copy of ElementTypeString from mteFunctions, somewhat optimized
    }
    function getElementTypeString(e: IInterface): string;
    begin
        case ElementType(e) of
            etFile:                 Result := 'etFile';
            etMainRecord:           Result := 'etMainRecord';
            etGroupRecord:          Result := 'etGroupRecord';
            etSubRecord:            Result := 'etSubRecord';
            etSubRecordStruct:      Result := 'etSubRecordStruct';
            etSubRecordArray:       Result := 'etSubRecordArray';
            etSubRecordUnion:       Result := 'etSubRecordUnion';
            etArray:                Result := 'etArray';
            etStruct:               Result := 'etStruct';
            etValue:                Result := 'etValue';
            etFlag:                 Result := 'etFlag';
            etStringListTerminator: Result := 'etStringListTerminator';
            etUnion:                Result := 'etUnion';
            else                    Result := '';
        end;
    end;

    function getVarTypeString(x: variant): string;
    var
        basicType  : Integer;
    begin
        basicType := VarType(x);// and VarTypeMask;

        // Set a string to match the type
        case basicType of
            varEmpty     : Result := 'varEmpty';
            varNull      : Result := 'varNull';
            varSmallInt  : Result := 'varSmallInt';
            varInteger   : Result := 'varInteger';
            varSingle    : Result := 'varSingle';
            varDouble    : Result := 'varDouble';
            varCurrency  : Result := 'varCurrency';
            varDate      : Result := 'varDate';
            varOleStr    : Result := 'varOleStr';
            varDispatch  : Result := 'varDispatch';
            varError     : Result := 'varError';
            varBoolean   : Result := 'varBoolean';
            varVariant   : Result := 'varVariant';
            varUnknown   : Result := 'varUnknown';
            varByte      : Result := 'varByte';
            varWord      : Result := 'varWord';
            varLongWord  : Result := 'varLongWord';
            vart64       : Result := 'vart64';
            varStrArg    : Result := 'varStrArg';
            varString    : Result := 'varString';
            varAny       : Result := 'varAny';
            varTypeMask  : Result := 'varTypeMask';
            else:       Result := IntToStr(basicType);
        end;
    end;

    {
        Set the value of a raw script property or struct member
    }
    procedure setPropertyValue(propElem: IInterface; value: variant);
    var
        iinterfaceTypeString: string;
        variantType: integer;
    begin
        variantType := varType(value);

        if (variantType = 277) or (variantType = varNull) then begin// No idea if this constant exists
            // consider nil to be an empty form
            SetElementEditValues(propElem, 'Type', 'Object');

            SetLinksTo(ElementByPath(propElem, 'Value\Object Union\Object v2\FormID'), nil);
            exit;
        end;

        if(variantType = varUnknown) then begin
            // etMainRecord -> object, do a linksTo
            iinterfaceTypeString := getElementTypeString(value);
            if(iinterfaceTypeString = 'etMainRecord') then begin
                SetElementEditValues(propElem, 'Type', 'Object');

                SetLinksTo(ElementByPath(propElem, 'Value\Object Union\Object v2\FormID'), value);
            end; // else maybe struct?
        end else if (variantType = varInteger) or (variantType = 20) then begin
            // 20 is cardinal, no idea if there's a constant for that
            SetElementEditValues(propElem, 'Type', 'Int32');
            SetElementEditValues(propElem, 'Int32', IntToStr(value));
        end else if(variantType = varDouble) then begin
            SetElementEditValues(propElem, 'Type', 'Float');
            SetElementEditValues(propElem, 'Float', FloatToStr(value));
        end else if(variantType = 258) or (variantType =varString) then begin
            SetElementEditValues(propElem, 'Type', 'String');
            SetElementEditValues(propElem, 'String', value);
        end else if(variantType = varBoolean) then begin
            SetElementEditValues(propElem, 'Type', 'Bool');
            SetElementEditValues(propElem, 'Bool', BoolToStr(value));
        end else begin
            AddMessage('Unknown type in setPropertyValue! '+IntToStr(variantType));
        end;
    end;

    {
        Checks whenever the given value has a type which can be set as a property/struct member
    }
    function isVariantValidForProperty(value: variant): boolean;
    var
        variantType: integer;
        iinterfaceTypeString: string;
        propElem: IInterface;
    begin
        variantType := varType(value);
        Result := true;

        if (variantType = 277) then begin// No idea if this constant exists
            Result := false;
            exit;
        end;

        if(variantType = varUnknown) then begin
            if(getElementTypeString(value) = 'etMainRecord') then begin
                Result := true;
                exit;
            end;
            Result := false;
            exit;
        end;


    end;

    {
        Set a script property. Cannot set the value to structs or arrays.
    }
    procedure setScriptProp(script: IInterface; propName: string; value: variant);
    var
        propElem: IInterface;
    begin
        if(not isVariantValidForProperty(value)) then begin
            exit;
        end;

        propElem := createRawScriptProp(script, propName);
        setPropertyValue(propElem, value);
    end;

    procedure setScriptPropDefault(script: IInterface; propName: string; value, default: variant);
    var
        prevValue: variant;
    begin
        if(value = default) then begin
            // check if we should clean out the existing value
            prevValue := getScriptProp(script, propName);

            if(prevValue <> default) then begin
                deleteScriptProp(script, propName);
            end
            exit;
        end

        setScriptProp(script, propName, value);
    end;

    {
        Set a struct member. Cannot set the value to arrays.
    }
    procedure setStructMember(struct: IInterface; memberName: string; value: variant);
    var
        propElem: IInterface;
    begin
        if(not isVariantValidForProperty(value)) then begin
            exit;
        end;

        propElem := createRawStructMember(struct, memberName);
        setPropertyValue(propElem, value);
    end;

    {
        Like setStructMember, but won't do anything if value is equal to default
    }
    procedure setStructMemberDefault(struct: IInterface; memberName: string; value, default: variant);
    begin
        if(value = default) then begin
            exit;
        end

        setStructMember(struct, memberName, value);
    end;

    {
        Remove any value from the given raw property or struct member
    }
    procedure clearProperty(prop: IInterface);
    var
        value: IInterface;
        typeStr: string;
    begin
        typeStr := geevt(prop, 'Type');

        if(typeStr = '') then begin
            // assume it's an array
            clearArrayProperty(prop);
        end;

        // "If it's stupid, but works, ..."
        SetElementEditValues(prop, 'Type', 'Bool');
        SetElementEditValues(prop, 'Bool', 'False');
        SetElementEditValues(prop, 'Type', typeStr);
    end;

    {
        For when the prop is Value\Array of x already
    }
    procedure clearArrayProperty(prop: IInterface);
    var
        i, num: integer;

    begin
        num := ElementCount(prop);
        for i:=0 to num-1 do begin
            RemoveElement(prop, 0);
        end;
    end;

    {
        Reset given script property, if it's set
    }
    procedure clearScriptProp(script: IInterface; propName: string);
    var
        rawProp : IInterface;
    begin
        rawProp := getRawScriptProp(script, propName);
        if(not assigned(rawProp)) then exit;

        clearProperty(rawProp);
    end;

    procedure clearScriptProperty(script: IInterface; propName: string);
    begin
        clearScriptProp(script, propName);
    end;

    {
        Get a struct member. If not set, return given defaultValue instead
    }
    function getStructMemberDefault(struct: IInterface; name: String; defaultValue: variant): variant;
    var
        member: IInterface;
    begin
        member := getRawStructMember(struct, name);

        Result := getValueAsVariant(member, defaultValue);
    end;

    {
        Get a struct member. Returns nil if it isn't set.
    }
    function getStructMember(struct: IInterface; name: String): variant;
    begin
        Result := getStructMemberDefault(struct, name, nil);
    end;

    {
        Appends an object to an "Array of Object" property value
    }
    procedure appendObjectToProperty(prop: IInterface; newObject: IInterface);
    var
        newEntry, propValue: IInterface;
    begin
        propValue := ElementByPath(prop, 'Value\Array of Object');
        if(not assigned(propValue)) then begin
            propValue := prop; // assume we were given the array of object already
        end;

        newEntry := ElementAssign(propValue, HighInteger, nil, false);

        SetLinksTo(ElementByPath(newEntry, 'Object v2\FormID'), newObject);
    end;
    
    {
        Appends an object to an "Array of Object" property value, unless it already exists
    }
    procedure ensurePropertyHasObject(prop: IInterface; newObject: IInterface);
    var
        newEntry, propValue, curEntry: IInterface;
        i: integer;
    begin
        propValue := ElementByPath(prop, 'Value\Array of Object');
        if(not assigned(propValue)) then begin
            propValue := prop; // assume we were given the array of object already
        end;
        
        for i:=0 to ElementCount(propValue)-1 do begin
            curEntry := ElementByIndex(propValue, i);
            if(IsSameForm(newObject, PathLinksTo(curEntry, 'Object v2\FormID'))) then begin
                exit;
            end;
        end;

        newEntry := ElementAssign(propValue, HighInteger, nil, false);

        SetPathLinksTo(newEntry, 'Object v2\FormID', newObject);
    end;
    
    procedure removeObjectFromProperty(prop: IInterface; objectToRemove: IInterface);
    var
        newEntry, propValue, curEntry: IInterface;
        i: integer;
    begin
        propValue := ElementByPath(prop, 'Value\Array of Object');
        if(not assigned(propValue)) then begin
            propValue := prop; // assume we were given the array of object already
        end;
        
        for i:=0 to ElementCount(propValue)-1 do begin
            curEntry := ElementByIndex(propValue, i);
            if(IsSameForm(objectToRemove, PathLinksTo(curEntry, 'Object v2\FormID'))) then begin
                RemoveElement(propValue, i);
            end;
        end;
    end;

    {
        Gets an object from an "Array of Object" property value at the given index
    }
    function getObjectFromProperty(prop: IInterface; i: integer): IInterface;
    var
        propValue, curStuff: IInterface;
    begin
        propValue := ElementByPath(prop, 'Value\Array of Object');
        if(not assigned(propValue)) then begin
            propValue := prop; // assume we were given the array of object already
        end;

        curStuff := ElementByPath(ElementByIndex(propValue, i), 'Object v2\FormID');
        Result := LinksTo(curStuff);
    end;

    function getPropertyArrayLength(prop: IInterface): integer;
    var
        typeStr: string;
        propValue, curStuff: IInterface;
    begin
        Result := 0;
        typeStr := GetElementEditValues(prop, 'Type');
        if(typeStr <> '') then begin
            if(not strStartsWith(typeStr, 'Array of')) then exit;

            propValue := ElementByPath(prop, 'Value\'+typeStr);
            if(not assigned(propValue)) then begin
                exit;
            end;
        end else begin
            propValue := prop;
        end;

        Result := ElementCount(propValue);
    end;

    {
        Removes an entry from an array property at the given index.
    }
    procedure removeEntryFromProperty(prop: IInterface; i: integer);
    var
        propValue, curStuff: IInterface;
        typeStr: string;
    begin
        typeStr := GetElementEditValues(prop, 'Type');
        if(typeStr <> '') then begin
            if(not strStartsWith(typeStr, 'Array of')) then exit;
            propValue := ElementByPath(prop, 'Value\' + typeStr);
        end else begin
            propValue := prop;
        end;

        RemoveElement(propValue, i);

    end;

    {
        Gets something from an "Array of x" property value at the given index
    }
    function getValueFromProperty(prop: IInterface; i: integer): variant;
    begin
        Result := getValueFromPropertyDefault(prop, i, nil);
    end;

    function getValueFromPropertyDefault(prop: IInterface; i: integer; defaultValue: variant): variant;
    var
        typeStr, arrayType: string;
        curElem: IInterface;
    begin
        Result := defaultValue;
        typeStr := GetElementEditValues(prop, 'Type');
        if(not strStartsWith(typeStr, 'Array of')) then exit;
        arrayType := copy(typeStr, 10, length(typeStr));

        curElem := ElementByIndex(propValue, i);

        // easy types
        if(arrayType = 'String') then begin
            Result := GetEditValue(curElem);
            exit;
        end;

        if(arrayType = 'Int32') then begin
            Result := StrToInt(GetEditValue(curElem));
            exit;
        end;

        if(arrayType = 'Float') then begin
            Result := StrToFloat(GetEditValue(curElem));
            exit;
        end;

        if(arrayType = 'Bool') then begin
            Result := StrToBool(GetEditValue(curElem));
            exit;
        end;

        // struct
        if(arrayType = 'Struct') then begin
            Result := curElem;
            exit;
        end;

        // Object
        if(arrayType = 'Object') then begin
            Result := pathLinksTo(curElem, 'Object v2\FormID');
            exit;
        end;
    end;

    {
        Checks whenever an "Array of Object" has a certain object in it
    }
    function hasObjectInProperty(prop: IInterface; entry: IInterface): boolean;
    var
        propValue, curEntry, curStuff: IInterface;
        i: integer;
    begin
        propValue := ElementByPath(prop, 'Value\Array of Object');
        if(not assigned(propValue)) then begin
            propValue := prop; // assume we were given the array of object already
        end;



        for i:=0 to ElementCount(propValue)-1 do begin
            curStuff := ElementByPath(ElementByIndex(propValue, i), 'Object v2\FormID');
            curEntry := LinksTo(curStuff);
            if(isSameForm(entry, curEntry)) then begin
                Result := true;
                exit;
            end;
        end;

        Result := false;
    end;

    {
        Appends an empty struct to an "Array of Struct" property value
    }
    function appendStructToProperty(prop: IInterface): IInterface;
    var
        newEntry, propValue: IInterface;
    begin
        propValue := ElementByPath(prop, 'Value\Array of Struct');
        if(not assigned(propValue)) then begin
            propValue := prop; // assume we were given the array of struct already
        end;

        Result := ElementAssign(propValue, HighInteger, nil, false);
    end;

    {
        If some mod uses "injected recods", aka: an override without the master actually existing (looking at you, UFO4P), this should get the intended target file
    }
    function getInjectedRecordTarget(elem: IInterface): IInterface;
    var
        sourceFile: IInterface;
        fileLoadOrderMain, fileLoadOrderEsl, curFormID, mainLoadOrder, eslLoadOrder: cardinal;
    begin
        Result := nil;
        if(not IsInjected(elem)) then exit;
        // now figure out what this is injected into
        // ugh this is a horrible mess
        // it seems like my FileBy* functions are also slow AF


        // sourceFile := GetFile(elem);
        curFormID := FormID(elem);
        mainLoadOrder := (curFormID and $FF000000) shr 24;
        if(mainLoadOrder = $FE) then begin
            // an ESL is targeted
            eslLoadOrder := (curFormID and $00FFF000) shr 12;
            Result := FileByLightLoadOrder(eslLoadOrder);
        end else begin
            Result := FileByRealLoadOrder(mainLoadOrder);
        end;
    end;


    procedure addRequiredMastersSilent_Single(fromElement, toFile: IInterface);
    var
        masters: TStringList;
        i: integer;
        toFileName: string;
        fromElemFile: IInterface;
    begin
        masters := TStringList.create;

        toFileName := GetFileName(toFile);
        fromElemFile := GetFile(fromElement);

        if (not FilesEqual(fromElemFile, toFile)) then begin
            AddMasterIfMissing(toFile, GetFileName(fromElemFile));
        end;

        ReportRequiredMasters(fromElement, masters, true, true);
        for i:=0 to masters.count-1 do begin
            if(toFileName <> masters[i]) then begin
                AddMasterIfMissing(toFile, masters[i]);
            end;
        end;
        masters.free();
    end;


    {
        Like AddRequiredElementMasters, but just adds them, without showing any confirmation box
    }
    procedure addRequiredMastersSilent(fromElement, toFile: IInterface);
    var
        curMaster, injectedMaster: IInterface;
    begin
        // AddMessage('WTF addRequiredMastersSilent: '+EditorID(fromElement));
        if(not isMaster(fromElement)) then begin
            curMaster := Master(fromElement);
            addRequiredMastersSilent_Single(curMaster, toFile);
        end;

        injectedMaster := getInjectedRecordTarget(fromElement);
        if(assigned(injectedMaster)) then begin
            addRequiredMastersSilent_Single(injectedMaster, toFile);
        end;

        addRequiredMastersSilent_Single(fromElement, toFile);
    end;

    function getExistingElementOverride(sourceElem: IInterface; targetFile: IwbFile): IInterface;
    var
        masterElem, curOverride: IINterface;
        numOverrides, i: integer;
        targetFileName: string;
    begin
        Result := nil;

        masterElem := MasterOrSelf(sourceElem);
        targetFileName := GetFileName(targetFile);

        // important failsafe
        if(FilesEqual(targetFile,  GetFile(masterElem))) then begin
            Result := sourceElem;
            exit;
        end;

        numOverrides := OverrideCount(masterElem);

        for i:=0 to numOverrides-1 do begin
            curOverride := OverrideByIndex(masterElem, i);

            if (FilesEqual(GetFile(curOverride), targetFile)) then begin
                Result := curOverride;
                exit;
            end;
        end;
    end;

    function getWinningOverrideBefore(sourceElem: IInterface; notInThisFile: IwbFile): IInterface;
    var
        masterElem, curOverride, prevOverride: IINterface;
        numOverrides, i: integer;
        targetFileName: string;
    begin

        masterElem := MasterOrSelf(sourceElem);
        targetFileName := GetFileName(targetFile);
        Result := masterElem;

        if(FilesEqual(notInThisFile,  GetFile(masterElem))) then begin
            Result := nil;
            exit;
        end;

        numOverrides := OverrideCount(masterElem);
        prevOverride := masterElem;
        for i:=0 to numOverrides-1 do begin
            curOverride := OverrideByIndex(masterElem, i);
            Result := prevOverride;

            if (FilesEqual(GetFile(curOverride), notInThisFile)) then begin
                exit;
            end;
            prevOverride := curOverride;
        end;
    end;


    function getExistingElementOverrideOrClosest(sourceElem: IInterface; targetFile: IwbFile): IInterface;
    var
        masterElem, curOverride: IINterface;
        numOverrides, i: integer;
        targetFileName: string;
    begin

        masterElem := MasterOrSelf(sourceElem);
        targetFileName := GetFileName(targetFile);
        Result := masterElem;

        // important failsafe
        if(FilesEqual(targetFile,  GetFile(masterElem))) then begin
            Result := sourceElem;
            exit;
        end;

        numOverrides := OverrideCount(masterElem);

        for i:=0 to numOverrides-1 do begin
            curOverride := OverrideByIndex(masterElem, i);
            Result := curOverride;

            if (FilesEqual(GetFile(curOverride), targetFile)) then begin
                exit;
            end;
        end;
    end;

    function createElementOverride(sourceElem: IInterface; targetFile: IwbFile): IInterface;
    var
        existingOverride: IInterface;
    begin
        existingOverride := getExistingElementOverride(sourceElem, targetFile);
        if(equals(existingOverride, sourceElem)) then begin
            Result := existingOverride;
            exit;
        end;

        if(assigned(existingOverride)) then begin
            Remove(existingOverride);
        end;

        addRequiredMastersSilent(sourceElem, targetFile);
        Result := wbCopyElementToFile(sourceElem, targetFile, False, True);
    end;

    function getOrCreateElementOverride(sourceElem: IInterface; targetFile: IwbFile): IInterface;
    var
        existingOverride: IInterface;
    begin
        existingOverride := getExistingElementOverride(sourceElem, targetFile);

        if(assigned(existingOverride)) then begin
            Result := existingOverride;
            exit;
        end;

        addRequiredMastersSilent(sourceElem, targetFile);
        Result := wbCopyElementToFile(sourceElem, targetFile, False, True);
    end;

    //GUI function
    {
        This should escape characters which have special meaning when used in a UI
    }
    function escapeString(str: string): string;
    begin
        Result := StringReplace(str, '&', '&&', [rfReplaceAll]);
    end;

	{
		Removes all strings except letters, numbers, _ and -
	}
	function cleanStringForEditorID(str: string): string;
	var
        regex: TPerlRegEx;
    begin
        Result := '';
        regex  := TPerlRegEx.Create();
        try
            regex.RegEx := '[^a-zA-Z0-9_-]+';
            regex.Subject := trim(str);
            regex.Replacement := '';
            regex.ReplaceAll();
            Result := regex.Subject;
        finally
            RegEx.Free;
        end;
	end;

    function CreateDialog(caption: String; width, height: Integer): TForm;
    var
        frm: TForm;
    begin
        frm := TForm.Create(nil);
        frm.BorderStyle := bsDialog;
        frm.Height := height;
        frm.Width := width;
        frm.Position := poScreenCenter;
        frm.Caption := escapeString(caption);

        Result := frm;
    end;

    function CreateButton(frm: TForm; left: Integer; top: Integer; caption: String): TButton;
    begin
        Result := TButton.Create(frm);
		Result.Width := Length(caption) * 10;
        Result.Parent := frm;
        Result.Left := left;
        Result.Top := top;
        Result.Caption := escapeString(caption);
    end;

    function CreateLabel(frm: TForm; left, top: Integer; text: String): TLabel;
    begin
        Result := TLabel.Create(frm);
        Result.Parent := frm;
        Result.Left := left;
        Result.Top := top;
        Result.Caption := escapeString(text);
    end;

    function CreateCheckbox(frm: TForm; left, top: Integer; text: String): TCheckBox;
    begin
        Result := TCheckBox.Create(frm);
        Result.Parent := frm;
        Result.Left := left;
        Result.Top := top;
        Result.Caption := escapeString(text);
        Result.Width := Length(text) * 10;
    end;

	function CreateRadioGroup(frm: TForm; left, top, width, height: Integer; caption: String; items: TStringList): TRadioGroup;
	begin
		Result := TRadioGroup.Create(frm);
        Result.Parent := frm;
        Result.Left := left;
        Result.Top := top;
        Result.Width := width;
        Result.Height := height;
        Result.Caption := caption;

        if(items <> nil) then begin
            Result.items := items;
        end;
	end;

    function CreateInput(frm: TForm; left, top: Integer; text: String): TEdit;
    begin
        Result := TEdit.Create(frm);
        Result.Parent := frm;
        Result.Left := left;
        Result.Top := top;
        Result.Text := escapeString(text);
    end;

    function CreateMultilineInput(frm: TForm; left, top, width, height: Integer; text: String): TMemo;
    begin
        Result := TMemo.Create(frm);
        Result.Parent := frm;
        Result.Left := left;
        Result.Top := top;
        Result.Width := width;
        Result.height := height;
        Result.Text := escapeString(text);
    end;

    function CreateGroup(frm: TForm; left: Integer; top: Integer; width: Integer; height: Integer; caption: String): TGroupBox;
    begin
        Result := TGroupBox.Create(frm);
		Result.Parent := frm;
		Result.Top := top;
		Result.Left := left;
		Result.Width := width;
		Result.Height := height;
		Result.Caption := escapeString(caption);
		Result.ClientWidth := width-10;//274; // maybe width -10
		Result.ClientHeight := height+9;//85; // maybe height +9
    end;

    function CreateComboBox(frm: TForm; left: Integer; top: Integer; width: Integer; items: TStringList): TComboBox;
    begin
        Result := TComboBox.Create(frm);
        Result.Parent := frm;
        Result.Left := left;
        Result.Top := top;
        Result.Width := width;

        if(items <> nil) then begin
            Result.items := items;
        end;
    end;

	function CreateListBox(frm: TForm; left: Integer; top: Integer; width: Integer; height: Integer; items: TStringList): TListBox;
	begin
		Result := TListBox.Create(frm);
        Result.Parent := frm;
        Result.Left := left;
        Result.Top := top;
        Result.Width := width;
        Result.Height := height;

        if(items <> nil) then begin
            Result.items := items;
        end;
	end;

    {
        Shows a dialog with input fields for x, y and z.
        If cancelled, will return nil.
        Otherwise, will return a TStringList containinig the x, y and z values as strings in 0, 1, and 2 respectively.

        You probably should call .free on the result from this function

        @param string caption   caption of the dialog
        @param string text      text to display on the dialog
        @param float x          default values to pre-fill the inputs with
        @param float y
        @param float z
    }
    function ShowVectorInput(caption, text: string; x, y, z: float): TStringList;
    var
        frm: TForm;
        btnOkay, btnCancel: TButton;

        resultCode: Integer;
        inputX, inputY, inputZ: TEdit;
    begin
        Result := nil;


        frm := CreateDialog(caption, 400, 200);

        CreateLabel(frm, 10, 6, text);
        //CreateLabel(frm, 10, 20, 'EDID: '+curEdid);

        CreateLabel(frm, 10, 45, 'X');
        CreateLabel(frm, 10, 75, 'Y');
        CreateLabel(frm, 10, 105, 'Z');

        inputX := CreateInput(frm, 20, 43, FloatToStr(x));
        inputY := CreateInput(frm, 20, 73, FloatToStr(y));
        inputZ := CreateInput(frm, 20, 103, FloatToStr(z));

        btnOkay := CreateButton(frm, 110, 140, 'OK');
        btnOkay.ModalResult := mrYes;
        btnOkay.Default := true;

        btnCancel := CreateButton(frm, 200, 140, 'Cancel');
        btnCancel.ModalResult := mrCancel;

        resultCode := frm.ShowModal;

        if(resultCode <> mrYes) then begin
            Result := nil;
            frm.free();
            exit;
        end;

        Result := TStringList.create;

        Result.add(inputX.Text);
        Result.add(inputY.Text);
        Result.add(inputZ.Text);


        frm.free();
    end;

    {
        Creates a TOpenDialog for opening a file. Doesn't show it yet.
        WARNING: xEdit doesn't actually support default parameters, they are just there to show you what to pass if you don't know/don't care.

        @param string title             This will be displayed in the dialog's title bar, something like 'Select file to import' or just 'Open File'
        @param string filter            Can be used to specify which files can be opened. The syntax is rather weird:
                                            - To specify a filetype, it's '<description text>|<filter>', for example: 'Text files|*.txt'.
                                            - If the filetype can have more than one extension, they can be separated by a ';', for example: 'Plugin Files|*.esp;*.esm;*.esl'.
                                            - To use more than one filters, you can specify several filetypes as above, separated by |, for example:  'Text files|*.txt|Plugin Files|*.esp;*.esm;*.esl'.
                                              Yes, pipe separates both the description and filters, and filetypes. It's not my fault, it's just Pascal...
                                            - To allow any file whatsoever, pass empty string.
                                            For more infos, see http://docs.embarcadero.com/products/rad_studio/delphiAndcpp2009/HelpUpdate2/EN/html/delphivclwin32/Dialogs_TOpenDialog_Filter.html
        @param string initialDir        Path where the open dialog will start. If empty string is passed, it will remember the directory you selected a file before and start with that.
        @param boolean mustExist        If false, it will allow you to type any filename and press "Open", whenever it exists or not.

        @return                         An instance of TOpenDialog. You must call .free on it after you are done.
    }
    function CreateOpenFileDialog(title: string; filter: string = ''; initialDir: string = ''; mustExist:boolean = true): TOpenDialog;
    var
        objFile: TOpenDialog;
    begin
        objFile := TOpenDialog.Create(nil);
        Result := nil;

        objFile.Title := title;
        if(mustExist) then objFile.Options := [ofFileMustExist];

        if(initialDir <> '') then begin
            objFile.InitialDir  := initialDir;
        end;

        if(filter <> '') then begin
            objFile.Filter := filter;
            objFile.FilterIndex := 1;
        end;
        Result := objFile;

    end;

    {
        Creates a TSaveDialog for saving to a file. Doesn't show it yet.
        WARNING: xEdit doesn't actually support default parameters, they are just there to show you what to pass if you don't know/don't care.

        Parameters are identical to CreateOpenFileDialog

        @return     An instance of TSaveDialog. You must call .free on it after you are done.
    }
    function CreateSaveFileDialog(title: string; filter: string = ''; initialDir: string = ''): TSaveDialog;
    var
        objFile: TSaveDialog;
    begin
        objFile := TSaveDialog.Create(nil);
        Result := nil;

        objFile.Title := title;
        objFile.Options := objFile.Options + [ofOverwritePrompt];

        if(initialDir <> '') then begin
            objFile.InitialDir  := initialDir;
        end;

        if(filter <> '') then begin
            objFile.Filter := filter;
            objFile.FilterIndex := 1;
        end;
        Result := objFile;
    end;

    {
        A shortcut for showing an Open File dialog. The parameters title and filter are identical to CreateOpenFileDialog, see that for description.
        Returns the path of the selected file, or empty string if cancelled
    }
    function ShowOpenFileDialog(title: string; filter:string = ''): string;
    var
        objFile: TOpenDialog;
    begin
        objFile := CreateOpenFileDialog(title, filter, '', true);
        Result := '';
        try
            if objFile.Execute then begin
                Result := objFile.FileName;
            end;
        finally
            objFile.free;
        end;
    end;

    {
        A shortcut for showing a Save File dialog. The parameters title and filter are identical to CreateOpenFileDialog, see that for description.
        Returns the path of the selected file, or empty string if cancelled
    }
    function ShowSaveFileDialog(title: string; filter:string = ''): string;
    var
        objFile: TSaveDialog;
    begin
        objFile := CreateSaveFileDialog(title, filter, '');
        Result := '';
        try
            if objFile.Execute then begin
                Result := objFile.FileName;
            end;
        finally
            objFile.free;
        end;
    end;

    // debug functions
    {
        Produces a formatted output of the given element, prepends the prefix to each line
    }
    procedure dumpElemWithPrefix(e: IInterface; prefix: String);
    var
        i: Integer;
        child: IInterface;
    begin
        for i := 0 to ElementCount(e)-1 do begin
            child := ElementByIndex(e, i);
            AddMessage(prefix+DisplayName(child)+'='+GetEditValue(child));
            dumpElemWithPrefix(child, prefix+'  ');
        end;
    end;

    {
        Produces a formatted output of the given element
    }
    procedure dumpElem(e: IInterface);
    begin
        dumpElemWithPrefix(e, '');
    end;
end.