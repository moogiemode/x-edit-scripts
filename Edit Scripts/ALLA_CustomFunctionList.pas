unit CustomFunctionList;

{
  ```pascal
  ```
}
{ General Notes
  If the code says it expects 'end;' but finds 'end of file' check that 'if' statements are followed by 'then' and 'for' statement are followed by 'do'
}

var
    slGlobal, slProcessTime, TemplateMegaListvar: TStringList;
    selectedRecord                           : IInterface;

    Recipes, MaterialList, TempPerkListExtra: TStringList;
    Ini,IniFileStreams                                     : TMemIniFile;
    HashedList, HashedTemperList            : THashedStringList;

    ignoreEmpty, disallowNP: boolean;
    DisKeyword, disWord,BOD2List,Megalist    : TStringList;
	IniPositions, modifiers:TStringList;
	InvalidEffect: TStringList;

    defaultOutputPlugin                                                                                        : string;
    defaultGenerateEnchantedVersions, defaultReplaceInLeveledList, defaultAllowDisenchanting, ProcessTime      : boolean;
    defaultBreakdownEnchanted, defaultBreakdownDaedric, defaultBreakdownDLC, defaultGenerateRecipes, Constant  : boolean;
    defaultChanceBoolean, defaultAutoDetect, defaultBreakdown, defaultOutfitSet, defaultCrafting, defaultTemper: boolean;
    defaultChanceMultiplier, defaultEnchMultiplier, defaultItemTier01, defaultItemTier02, defaultItemTier03    : integer;
    defaultItemTier04, defaultItemTier05, defaultItemTier06, defaultTemperLight, defaultTemperHeavy            : integer;
    firstRun, debugMsg                                                                                         : boolean;
	debugLevel                                                                                                 : integer;

/// ///////////////////////////// FILE BY NAME IS NATIVE PAST xEdit 4.1.x //////////////////////////////////
// Find loaded plugin by name
function FileByName(aPluginName: string): IInterface;
var
  i: Integer;
begin
  for i := 0 to Pred(FileCount) do begin
    Result := FileByIndex(i);
    if SameText(GetFileName(Result), aPluginName) then
      Exit;
  end;
  Result := nil;
end;
/// ///////////////////////////// FILE BY NAME IS NATIVE PAST xEdit 4.1.x //////////////////////////////////

// Find loaded plugin by name (if it exists)
function doesFileExist(aPluginName: string): boolean;
var
  i: Integer;
  a: IInterface;
begin
	result := false;
	for i := 0 to Pred(FileCount) do begin
		a := FileByIndex(i);
		if SameText(GetFileName(a), aPluginName) then
		begin		
			result := true;
			Exit;
		end;
	end;
end;

// Removes records dependent on a specified master
procedure RemoveMastersAuto(inputPlugin, outputPlugin: IInterface);
var
    slTemp, slRemove       : TStringList;
    tempRecord, tempelement: IInterface;
    tempString             : string;
    i, x, y                : integer;
begin
    // Begin debugMsg section
    

    // Initialize
    { Debug } if debugMsg then
        addMessage('[RemoveMastersAuto] RemoveMastersAuto( ' + GetFileName(inputPlugin) + ', ' + GetFileName(outputPlugin) + ' )');
    slTemp     := TStringList.Create;
    slRemove   := TStringList.Create;
    tempString := GetFileName(inputPlugin);

    // Work
    { Debug } if debugMsg then
        addMessage('[RemoveMastersAuto] for i := 0 to ' + IntToStr(Pred(ElementCount(outputPlugin))) + ' do begin');
    for i := ElementCount(outputPlugin) - 1 downto 0 do
    begin
        tempelement := elementbyindex(outputPlugin, i);
        { Debug } if debugMsg then
            addMessage('[RemoveMastersAuto] for x := 0 to ' + IntToStr(Pred(ElementCount(tempelement))) + ' do begin');
        for x := ElementCount(tempelement) - 1 downto 0 do
        begin
            tempRecord := elementbyindex(tempelement, x);
            ReportRequiredMasters(tempRecord, slTemp, false, true);
            { Debug } if debugMsg then
                msgList('[RemoveMastersAuto] slTemp := ', slTemp, '');
            for y := slTemp.Count - 1 downto 0 do
            begin
                { Debug } if debugMsg then
                    addMessage('[RemoveMastersAuto] if ( ' + slTemp[y] + ' = ' + tempString + ' ) then begin');
                if slTemp[y] = tempString then
                begin
                    slRemove.addObject(EditorID(tempRecord), tempRecord);
                    break;
                end;
            end;
        end;
    end;

    // Remove records
    for i := slRemove.Count - 1 downto 0 do
    begin
        { Debug } if debugMsg then
            addMessage('[RemoveMastersAuto] Remove( ' + slRemove[i] + ' );');
        Remove(ObjectToElement(slRemove.Objects[i]));
    end;

    // Finalize
    slTemp.clear;
    slRemove.clear;

    
    // End debugMsg section
end;

// Find where the selected record is referenced in leveled lists and make a 'Copy as Override' into a specified file.  Then replace all instances of inputRecord with replaceRecord in the override
procedure ReplaceInLeveledListAuto(inputRecord, replaceRecord, aPlugin: IInterface);
var
    LLrecord, LLcopy, masterRecord                            : IInterface;
    patchBool                                       : boolean;
    startTime, stopTime                                       : TDateTime;
    tempString, patchFileName, LLrecord_EditorID, LLrecord_Sig: string;
    i, x                                                      : integer;
begin
    // Initialize
    
    startTime := Time;
    { Debug } if debugMsg then
        addMessage('[ReplaceInLeveledListAuto] ReplaceInLeveledListAuto(' + EditorID(inputRecord) + ' with ' + EditorID(replaceRecord) + ' in ' + GetFileName(aPlugin) + ' );');

    patchBool := slContains(slGlobal, 'Patch');
    if patchBool then
        patchFileName := GetFileName(ObjectToElement(GetObject('Patch', slGlobal)));
    masterRecord      := MasterOrSelf(inputRecord);
    for i             := ReferencedByCount(masterRecord) - 1 downto 0 do
    begin
        LLrecord          := ReferencedByIndex(masterRecord, i);
        LLrecord_EditorID := EditorID(LLrecord);
        // records to skip
        if patchBool then
            if (GetFileName(GetFile(LLrecord)) <> patchFileName) then
                Continue;
        if not SameText(Signature(LLrecord), 'LVLI') then
            Continue;
        if SameText(LLrecord_EditorID, EditorID(replaceRecord)) then
            Continue;
        if ContainsText(LLrecord_EditorID, '++') or not IsHighestOverride(LLrecord, GetLoadOrder(aPlugin)) or (GetLoadOrder(GetFile(LLrecord)) > GetLoadOrder(aPlugin)) or (Length(LLrecord_EditorID) = 0) or FlagCheck(LLrecord, 'Special Loot') then
            Continue;

        if slContains(slGlobal, LLrecord_EditorID) then
            if (EditorID(masterRecord) = EditorID(ObjectToElement(slGlobal.Objects[slGlobal.IndexOf(LLrecord_EditorID)]))) then
                Continue;
        if LLcontains(LLrecord, masterRecord) then
        begin
            LLcopy := MainRecordByEditorID(GroupBySignature(aPlugin, 'LVLI'), LLrecord_EditorID);
            if not Assigned(LLcopy) then
                LLcopy := wbCopyElementToFile(LLrecord, aPlugin, false, true);
            { Debug } if debugMsg then
                addMessage('[ReplaceInLeveledListAuto] LLcopy := ' + EditorID(LLcopy));
            if Assigned(LLcopy) then
            begin
                { Debug } if debugMsg then
                    addMessage('[ReplaceInLeveledListAuto] LLreplace(' + EditorID(LLcopy) + ', ' + EditorID(masterRecord) + ', ' + EditorID(replaceRecord) + ' );');
                while LLcontains(LLcopy, masterRecord) do
                    LLreplace(LLcopy, masterRecord, replaceRecord);
            end;
        end;

    end;

    // Finalize
    stopTime := Time;
    if ProcessTime then
        addProcessTime('ReplaceInLeveledListAuto', TimeBtwn(startTime, stopTime));
end;

// Find where the selected record is referenced in leveled lists and make a 'Copy as Override' into a specified file.  Then replace all instances of inputRecord with replaceRecord in the override
procedure ReplaceInLeveledListByList(aList, bList: TStringList; aPlugin: IInterface);
var
    LLrecord, LLcopy, tempRecord, tempelement: IInterface;
    i, x, y, tempInteger, LoadOrder          : integer;
    tempBoolean, patchBool         : boolean;
    startTime, stopTime                      : TDateTime;
    slTemp, slLL                             : TStringList;
    LLrecord_EditorID, patchFileName         : string;
begin
    // Initialize
    
    if ProcessTime then
        startTime := Time;
    { Debug } if debugMsg then
        addMessage('[ReplaceInLeveledListByList] ReplaceInLeveledListByList(aList, bList, ' + GetFileName(aPlugin) + ' );');
    slTemp := TStringList.Create;
    slLL   := TStringList.Create;

    // For the 'Patch' function
    patchBool := slContains(slGlobal, 'Patch');
    if patchBool then
        patchFileName := GetFileName(ObjectToElement(GetObject('Patch', slGlobal)));

    // main work 1
    LoadOrder := GetLoadOrder(aPlugin);
    for i     := aList.Count - 1 downto 0 do
    begin
        tempRecord := ObjectToElement(aList.Objects[i]);
        for x      := ReferencedByCount(tempRecord) - 1 downto 0 do
        begin
            LLrecord          := ReferencedByIndex(tempRecord, x);
            LLrecord_EditorID := EditorID(LLrecord);
            if not(Signature(LLrecord) = 'LVLI') then
                Continue;
            // single mode
            if (GetFileName(GetFile(LLrecord)) <> patchFileName) then
                Continue;

            // Filter Invalid Entries
            { Debug } if debugMsg then
                addMessage('[ReplaceInLeveledListByList] LLrecord := ' + LLrecord_EditorID);
            if slContains(slLL, LLrecord_EditorID) then
                Continue;
            if ContainsText(LLrecord_EditorID, '++') or not(Length(LLrecord_EditorID) > 0) or not IsHighestOverride(LLrecord, GetLoadOrder(aPlugin)) or FlagCheck(LLrecord, 'Special Loot') then
                Continue;

            if slContains(slGlobal, LLrecord_EditorID) then
                if not(EditorID(tempRecord) = EditorID(ObjectToElement(slGlobal.Objects[slGlobal.IndexOf(LLrecord_EditorID)]))) then
                    Continue;

            if (LoadOrder <= GetLoadOrder(GetFile(LLrecord))) then
            begin
                if PreviousOverrideExists(LLrecord, LoadOrder) then
                begin
                    LLrecord := GetPreviousOverride(LLrecord, LoadOrder);
                end
                else
                    Continue;
            end
            else
                if debugMsg then
                    addMessage('[ReplaceInLeveledListByList] ' + LLrecord_EditorID + ' := ' + IntToStr(LoadOrder) + ' >= ' + IntToStr(GetLoadOrder(GetFile(LLrecord))));
            // Add Copy to List
            slLL.addObject(LLrecord_EditorID, LLrecord);

        end;
    end;

    { Debug } if debugMsg then
        msgList('[ReplaceInLeveledListByList] slLL := ', slLL, ' );');
    { Debug } if debugMsg then
        addMessage(' ');
    // work 2
    for i := slLL.Count - 1 downto 0 do
    begin
        LLrecord          := ObjectToElement(slLL.Objects[i]);
        LLrecord_EditorID := slLL[i];

        { Debug } if debugMsg then
            addMessage('[ReplaceInLeveledListByList] LLrecord := ' + LLrecord_EditorID);
        if not(Length(LLrecord_EditorID) > 0) then
            Continue;
        tempelement := ElementByName(LLrecord, 'Leveled List Entries');

        for x := LLec(LLrecord) - 1 downto 0 do
        begin
            tempRecord := elementbyindex(tempelement, x);
            slTemp.addObject(StrPosCopy(GetElementEditValues(tempRecord, 'LVLO\Reference'), ' ', true), GetElementNativeValues(tempRecord, 'LVLO\Level'));
        end;

        { Debug } if debugMsg then
            msgList('[ReplaceInLeveledListByList] slTemp := ', slTemp, ' );');
        for x := 0 to bList.Count - 1 do
        begin
            if slContains(slTemp, bList[x]) then
            begin
                tempRecord := ObjectToElement(bList.Objects[x]);
                if not slContains(slTemp, EditorID(tempRecord)) then
                begin
                    // Detect Pre-Existing List or Create Override
                    if not(LoadOrder = GetLoadOrder(GetFile(LLrecord))) then
                        LLcopy := wbCopyElementToFile(LLrecord, aPlugin, false, true)
                    else
                        LLcopy := LLrecord;
                    // Replace
                    LLreplace(LLcopy, ObjectToElement(aList.Objects[x]), tempRecord);
                end;
            end;
        end;
        slTemp.clear;
    end;

    // Finalize
    if ProcessTime then
    begin
        stopTime := Time;
        addProcessTime('ReplaceInLeveledListByList', TimeBtwn(startTime, stopTime));
    end;

    slTemp.Free;
    slLL.Free;
end;

// Find where the selected record is referenced in leveled lists and make a 'Copy as Override' into a specified file.  Then replace all instances of templateRecord with inputRecord in the override
function AddToLeveledListAuto(templateRecord: IInterface; inputRecord: IInterface; aPlugin: IInterface): string;
var
    LLrecord, LLcopy, masterRecord, inputEntry, tempRecord, tempelement: IInterface;
    tempBoolean, AddToEnchanted, patchBool                   : boolean;
    slRecords                                                          : TStringList;
    i, x, y, tempInteger                                               : integer;
    patchFileName                                                      : string;
begin
    // Begin debugMsg Section
    

    // Initialize
    slRecords := TStringList.Create;

    { Debug } if debugMsg then
        addMessage('[AddToLeveledListAuto] AddToLeveledListAuto(' + EditorID(templateRecord) + ', ' + EditorID(inputRecord) + ', ' + GetFileName(aPlugin) + ' );');
    // Pull patch info if present
    patchBool := slContains(slGlobal, 'Patch');
    if patchBool then
        patchFileName := GetFileName(ObjectToElement(GetObject('Patch', slGlobal)));
    masterRecord      := WinningOverride(templateRecord); { Debug }
    if debugMsg then
        addMessage('[AddToLeveledListAuto] masterRecord := ' + full(masterRecord));
    // This pulls the item out of chanceLeveledList in order to keep the addMessage statements consistent
    { Debug } if debugMsg then
        addMessage('[AddToLeveledListAuto] if ' + Signature(inputRecord) + ' = ''LVLI'' then begin');
    if (Signature(inputRecord) = 'LVLI') then
    begin { Debug }
        if debugMsg then
            addMessage('[AddToLeveledListAuto] Pred(LLec(inputRecord)) := ' + IntToStr(Pred(LLec(inputRecord))));
        for i := 0 to Pred(LLec(inputRecord)) do
        begin { Debug }
            if debugMsg then
                addMessage('[AddToLeveledListAuto] inputEntry := ' + GetElementEditValues(LLelementbyindex(inputRecord, i)));
            inputEntry := LLelementbyindex(inputRecord, i); { Debug }
            if debugMsg then
                addMessage('[AddToLeveledListAuto] if not (Signature(inputEntry) := ' + Signature(inputEntry) + ' = ''LVLI'') then Break; ');
            if not(Signature(inputEntry) = 'LVLI') then
                break;
        end;
    end else begin
        inputEntry := templateRecord;
        { Debug } if debugMsg then
            addMessage('[AddToLeveledListAuto] GetElementEditValues(inputEntry) := ' + GetElementEditValues(inputEntry) + ' EditorID(inputEntry := ' + EditorID(inputEntry));
    end;
    // addMessage('['+GetElementEditValues(inputEntry)+'] Processing '+IntToStr(ReferencedByCount(masterRecord))+' '+EditorID(inputEntry)+' References (This May Take A While)');
    { Debug } if debugMsg then
        addMessage('[AddToLeveledListAuto] Pred(ReferencedByCount(masterRecord)) := ' + IntToStr(Pred(ReferencedByCount(masterRecord))));
    // Begins analyzing records that reference masterRecord
    for i := 0 to Pred(ReferencedByCount(masterRecord)) do
    begin
        LLrecord := ReferencedByIndex(masterRecord, i);
        // Filter Invalid Entries
        if patchBool then
            if (GetFileName(GetFile(LLrecord)) <> patchFileName) then
                Continue;
        if ContainsText(EditorID(LLrecord), '++') or not(Length(EditorID(LLrecord)) > 0) or not IsHighestOverride(LLrecord, GetLoadOrder(aPlugin)) or not(Signature(LLrecord) = 'LVLI') or FlagCheck(LLrecord, 'Use All') or FlagCheck(LLrecord, 'Special Loot') then
            Continue;
        if slContains(slGlobal, EditorID(LLrecord)) then
            if (EditorID(inputRecord) = EditorID(ObjectToElement(slGlobal.Objects[slGlobal.IndexOf(EditorID(LLrecord))]))) then
                Continue;
        slRecords.addObject(EditorID(LLrecord), LLrecord);
    end;
    // Add Masters

    for i := 0 to slRecords.Count - 1 do
    begin
        LLrecord := ObjectToElement(slRecords.Objects[i]);
        // Detect Pre-Existing List
        { Debug } if debugMsg then
            addMessage('[AddToLeveledListAuto] LLcopy := MainRecordByEditorID(GroupBySignature(aPlugin, ''LVLI''), ' + EditorID(LLrecord) + ' );');
        LLcopy := MainRecordByEditorID(GroupBySignature(aPlugin, 'LVLI'), EditorID(LLrecord));
        // Create override if not already present
        if not Assigned(LLcopy) then
            LLcopy := wbCopyElementToFile(LLrecord, aPlugin, false, true);
        //RemoveInvalidEntries(LLcopy);
        { Debug } if debugMsg then
            addMessage('[AddToLeveledListAuto] LLrecord := ' + EditorID(ReferencedByIndex(masterRecord, i)));
        if not LLcontains(LLrecord, inputRecord) then
        begin
            tempelement := ElementByName(LLrecord, 'Leveled List Entries');
            for x       := 0 to Pred(LLec(LLrecord)) do
            begin { Debug }
                if debugMsg then
                    addMessage('[AddToLeveledListAuto] LLelementbyindex(LLrecord, x) := ' + EditorID(LLelementbyindex(LLrecord, x)));
                { Debug } if debugMsg then
                    addMessage('[AddToLeveledListAuto] if (GetLoadOrderFormID(masterRecord) := ' + IntToStr(GetLoadOrderFormID(masterRecord)) + ') = (GetLoadOrderFormID(LLelementbyindex(LLrecord, x)) := ' + IntToStr(GetLoadOrderFormID(LLelementbyindex(LLrecord, x))) + ') then begin');
                tempRecord := elementbyindex(tempelement, x);
                if GetElementEditValues(tempRecord, 'LVLO\Reference') = name(masterRecord) then
                begin
                    tempInteger := 0;
                    tempInteger := GetElementNativeValues(tempRecord, 'LVLO\Level');
                    if not(tempInteger > 0) then
                    begin
                        addToLeveledList(LLcopy, inputRecord, 1);
                    end
                    else
                        addToLeveledList(LLcopy, inputRecord, tempInteger);
                    addMessage(EditorID(inputRecord) + ' added to ' + EditorID(LLrecord));
                    break;
                end;
            end;
        end;
    end;

    
    // End debugMsg section
end;

// Find where the selected record is referenced in leveled lists and make a 'Copy as Override' into a specified file.  Then replace all instances of templateRecord with inputRecord in the override
procedure AddToLeveledListByList(aList: TStringList; aPlugin: IInterface);
var
    LLrecord, LLcopy, masterRecord, tempRecord, tempelement: IInterface;
    startTime, stopTime, tempStart, tempStop               : TDateTime;
    i, x, y, tempInteger, LoadOrder                        : integer;
    tempBoolean, Patch                           : boolean;
    slLL, slTemp, slTempList                               : TStringList;
    tempString                                             : string;
begin
    // Initialize
    
    startTime         := Time;
    slTempList        := TStringList.Create;
    slTemp            := TStringList.Create;
    slTemp.Sorted     := true;
    slTemp.Duplicates := dupIgnore;
    slLL              := TStringList.Create;

    { Debug } if debugMsg then
    begin
        addMessage('[AddToLeveledListByList] AddToLeveledListByList(aList, ' + GetFileName(aPlugin) + ' );');
        addMessage(' ');
        msgList('[AddToLeveledListByList] slGlobal := ', slGlobal, '');
        addMessage(' ');
        msgList('[AddToLeveledListByList] aList := ', aList, '');
        addMessage(' ');
        for i := 0 to slGlobal.Count - 1 do
            if ContainsText(slGlobal[i], '-//-') then
                addMessage('[AddToLeveledListByList] ' + slGlobal[i] + ' := ' + EditorID(ObjectToElement(slGlobal.Objects[i])));
        for i := 0 to slGlobal.Count - 1 do
            if ContainsText(slGlobal[i], '-/Level/-') then
                addMessage('[AddToLeveledListByList] ' + slGlobal[i] + ' := ' + IntToStr(integer(slGlobal.Objects[i])));
    end;
    Patch     := slContains(slGlobal, 'Patch');
    LoadOrder := GetLoadOrder(aPlugin);
    // Add Masters
    { Debug } if debugMsg then
        addMessage('[AddToLeveledListByList] Adding Masters');

    // Collect leveled lists
    addMessage('Beginning Leveled List Collection');
    // Custom Leveled List Input
    for i := 0 to slGlobal.Count - 1 do
        if ContainsText(slGlobal[i], '-/LeveledList/-') then
            slLL.addObject(StrPosCopy(slGlobal[i], '-/LeveledList/-', true), slGlobal.Objects[i]);
    // Leveled list from template
    for i := 0 to aList.Count - 1 do
    begin
        masterRecord := ObjectToElement(aList.Objects[i]);
        tempString   := EditorID(masterRecord);
        // If two records have the same template this prevents it from getting processed twice
        { Debug } if debugMsg then
            addMessage('[AddToLeveledListByList] If two records have the same template this prevents it from getting processed twice');
        if slContains(slTemp, tempString) then
            Continue
        else
            slTemp.Add(tempString);
        { Debug } if debugMsg then
            msgList('[AddToLeveledListByList] ', slTemp, '');
        addMessage('[' + IntToStr(i + 1) + '/' + IntToStr(aList.Count) + '] Collecting ' + tempString + ' Leveled Lists');
        { Debug } if debugMsg then
            addMessage('[AddToLeveledListByList] for x := 0 to ' + IntToStr(Pred(ReferencedByCount(masterRecord))) + ' do begin');
        for x := 0 to Pred(ReferencedByCount(masterRecord)) do
        begin
            LLrecord   := ReferencedByIndex(masterRecord, x);
            tempString := EditorID(LLrecord);
            { Debug } if debugMsg then
                addMessage('[AddToLeveledListByList] EditorID(LLrecord) := ' + tempString);
            // Filter Invalid Entries
            { Debug } if debugMsg then
                addMessage('[AddToLeveledListByList] Filter Invalid Entries');
            if slContains(slLL, tempString) then
                Continue;
            if ContainsText(tempString, '++') or (Length(tempString) <= 0) or not IsHighestOverride(LLrecord, LoadOrder) or not(Signature(LLrecord) = 'LVLI') or FlagCheck(LLrecord, 'Use All') or FlagCheck(LLrecord, 'Special Loot') then
                Continue;
            if not(LoadOrder >= GetLoadOrder(GetFile(LLrecord))) then
            begin
                if PreviousOverrideExists(LLrecord, LoadOrder) then
                begin
                    LLrecord := GetPreviousOverride(LLrecord, LoadOrder);
                end
                else
                    Continue;
            end
            else
                if debugMsg then
                    addMessage('[AddToLeveledListByList] ' + EditorID(LLrecord) + ' := ' + IntToStr(LoadOrder) + ' >= ' + IntToStr(GetLoadOrder(GetFile(LLrecord))));
            // Restricts the valid leveled lists to a single file (for 'Patch' function)
            { Debug } if debugMsg then
                addMessage('[AddToLeveledListByList] Restricts the valid leveled lists to a single file (for Patch function)');
            if Patch then
            begin
                tempString  := GetFileName(ObjectToElement(GetObject('Patch', slGlobal)));
                tempBoolean := false;
                // {Debug} if debugMsg then addMessage('[AddToLeveledListByList] for x := 0 to '+IntToStr(Pred(OverrideCount(LLrecord)))+' do begin');
                if (OverrideCount(LLrecord) > 0) then
                begin
                    for y := 0 to Pred(OverrideCount(LLrecord)) do
                    begin
                        { Debug } if debugMsg then
                            addMessage('[AddToLeveledListByList] if (GetFileName(GetFile(OverrideByIndex(' + EditorID(LLrecord) + ', ' + IntToStr(x) + '))) = ' + tempString + ') then begin');
                        if (GetFileName(GetFile(OverrideByIndex(LLrecord, y))) = tempString) then
                        begin
                            tempBoolean := true;
                            break;
                        end;
                    end;
                end
                else
                    if (GetFileName(GetFile(LLrecord)) = tempString) then
                        tempBoolean := true;
                if not tempBoolean then
                    Continue;
            end;
            // Add Copy to List
            slLL.addObject(EditorID(LLrecord), LLrecord);
        end;
    end;
    { Debug } if debugMsg then
        msgList('[AddToLeveledListByList] slLL := ', slLL, ' );');
    // Add Masters
    tempStart := Time;

    tempStop := Time;
    // addProcessTime('Add Masters', TimeBtwn(tempStart, tempStop));
    // Process Leveled Lists
    addMessage('Processing Leveled Lists');
    for i := 0 to slLL.Count - 1 do
    begin
        slTempList.clear;
        slTemp.clear;
        LLrecord := ObjectToElement(slLL.Objects[i]);
        { Debug } if debugMsg then
            addMessage('[AddToLeveledListByList] LLrecord := ' + EditorID(LLrecord));
        if (Length(EditorID(LLrecord)) <= 0) then
            Continue;
        tempelement := ElementByName(LLrecord, 'Leveled List Entries');
        for x       := 0 to Pred(LLec(LLrecord)) do
        begin
            tempRecord := elementbyindex(tempelement, x);
            slTemp.addObject(StrPosCopy(GetElementEditValues(tempRecord, 'LVLO\Reference'), ' ', true), StrToInt(GetElementEditValues(tempRecord, 'LVLO\Level'))); { Debug }
            if debugMsg then
                addMessage('[AddToLeveledListByList] slTemp.AddObject(' + StrPosCopy(GetElementEditValues(tempRecord, 'LVLO\Reference'), ' ', true) + ', ' + IntToStr(StrToInt(GetElementEditValues(tempRecord, 'LVLO\Level'))) + ' )');
        end; { Debug }
        if debugMsg then
            msgList('[AddToLeveledListByList] slTemp := ', slTemp, '');
        for x := 0 to aList.Count - 1 do
        begin
            tempRecord := ObjectToElement(GetObject(aList[x], slGlobal));
            { Debug } if debugMsg then
                addMessage('[AddToLeveledListByList] tempRecord := ' + EditorID(tempRecord));
            tempInteger := -1;
            // Custom input from 'Add To Leveled List' menu
            tempString := EditorID(LLrecord) + '-/Level/-' + EditorID(tempRecord);
            if slContains(slGlobal, tempString) then
            begin
                tempInteger := integer(GetObject(tempString, slGlobal)); { Debug }
                if debugMsg then
                    addMessage('[AddToLeveledListByList] Custom Level for ' + EditorID(tempRecord) + ' in ' + EditorID(LLrecord) + ' := ' + IntToStr(tempInteger));
                slGlobal.Delete(slGlobal.IndexOf(tempString));
                slGlobal.Delete(slGlobal.IndexOf(EditorID(LLrecord) + '-/LeveledList/-' + EditorID(tempRecord)));
                if (tempInteger <= 0) then
                    Continue;
            end;
            // Level from template
            if (tempInteger = -1) then
            begin
                tempString := EditorID(ObjectToElement(aList.Objects[x]));
                if slContains(slTemp, tempString) then
                    tempInteger := integer(GetObject(tempString, slTemp));
            end;
            { Debug } if debugMsg then
                addMessage('[AddToLeveledListByList] Level from ' + EditorID(LLrecord) + ' := ' + IntToStr(tempInteger));
            if (tempInteger = -1) then
                Continue;
            if (tempInteger = 0) then
                tempInteger := 1;
            // Detect Pre-Existing List or Create Override
            case GetLoadOrder(GetFile(LLrecord)) of
                LoadOrder:
                    LLcopy := LLrecord;
            else
                LLcopy := wbCopyElementToFile(LLrecord, aPlugin, false, true);
            end;
            { Debug } if debugMsg then
                addMessage('[AddToLeveledListByList] LLcopy := ' + EditorID(LLcopy));
            if not slContains(slTemp, EditorID(tempRecord)) then
            begin
                addToLeveledList(LLcopy, tempRecord, tempInteger); { Debug }
                if debugMsg then
                    addMessage('[AddToLeveledListByList] addToLeveledList(' + EditorID(LLcopy) + ', ' + EditorID(tempRecord) + ', ' + IntToStr(tempInteger) + ' )');
                slTempList.Add(EditorID(tempRecord));
            end;
        end;
        if (slTempList.Count > 0) then
            msgList('[' + IntToStr(i + 1) + '/' + IntToStr(slLL.Count) + '] ' + EditorID(LLrecord) + ' added: ', slTempList, '');
    end;

    // Finalize
    stopTime := Time;
    if ProcessTime then
        addProcessTime('AddToLeveledListByList', TimeBtwn(startTime, stopTime));
    slTempList.Free;
    slTemp.Free;
    slLL.Free;
end;

// Find where the selected record is referenced in leveled lists and make a 'Copy as Override' into a specified file.  Then replace all instances of templateRecord with inputRecord in the override
procedure AddOutfitByList(aList: TStringList; aPlugin: IInterface);
var
    LLrecord, LLcopy, masterRecord, tempRecord, tempelement, currentElement, primarySlotItem: IInterface;
    startTime, stopTime, tempStart, tempStop                                                : TDateTime;
    i, x, y, tempInteger, LoadOrder, tempCount, currentCount                                : integer;
    tempBoolean, Patch                                                            : boolean;
    slLL, slTemp, slTempList, slItem, slNames, slOutfits                                    : TStringList;
    tempString, commonString, Slot                                                          : string;
begin
    // Initialize
    
    startTime         := Time;
    slTempList        := TStringList.Create;
    slTemp            := TStringList.Create;
    slTemp.Sorted     := true;
    slTemp.Duplicates := dupIgnore;
    slOutfits         := TStringList.Create;
    slNames           := TStringList.Create;
    slItem            := TStringList.Create;
    slLL              := TStringList.Create;

    { Debug } if debugMsg then
    begin // Seperates the debug messages so they're a little easier to read
        addMessage('[AddOutfitByList] AddOutfitByList(aList, ' + GetFileName(aPlugin) + ' );');
        addMessage(' ');
        msgList('[AddOutfitByList] slGlobal := ', slGlobal, '');
        addMessage(' ');
        msgList('[AddOutfitByList] aList := ', aList, '');
        addMessage(' ');
        for i := 0 to slGlobal.Count - 1 do
            if ContainsText(slGlobal[i], '-//-') then
                addMessage('[AddOutfitByList] ' + slGlobal[i] + ' := ' + EditorID(ObjectToElement(slGlobal.Objects[i])));
        for i := 0 to slGlobal.Count - 1 do
            if ContainsText(slGlobal[i], '-/Level/-') then
                addMessage('[AddOutfitByList] ' + slGlobal[i] + ' := ' + IntToStr(integer(slGlobal.Objects[i])));
    end;
    Patch     := slContains(slGlobal, 'Patch'); // Whether or not we're using the 'Patch' QOL function
    LoadOrder := GetLoadOrder(aPlugin);
    // Add Masters
    { Debug } if debugMsg then
        addMessage('[AddOutfitByList] Adding Masters');

    // Collect Outfits
    for i := 0 to aList.Count - 1 do
    begin // Collect names
        if not(Signature(ObjectToElement(aList.Objects[i])) = 'ARMO') then
            Continue;
        tempRecord := ObjectToElement(GetObject(aList[i], slGlobal));
        slNames.addObject(Full(tempRecord), tempRecord);
    end;
    slTemp.CommaText := 'Bracers, Gloves, Glove, Cloak, Underwear, Panties, Lingerie, Skirt, Armlets, Armlet, Gauntlets, Helmet, Crown, Helm, Hood, Mask, Circlet, Headdress, Shield, Buckler, Boots, Shoes, Cuirass, Armor, Top, Pants, Robes, Scarf, Clothes, Cape, Hooded';
    for i            := 0 to slTemp.Count - 1 do // Remove junk words
        RemoveSubStr(slNames, slTemp[i]);
    { Debug } if debugMsg then
        msgList('[AddOutfitByList] slNames := ', slNames, '');
    tempInteger := 0; // Keeps track of where we are in the list
    while (slNames.Count > tempInteger) do
    begin                     // while tier 3
        tempBoolean := false; // Keeps track of whether or not the current entry is deleted
        if not(GetPrimarySlot(ObjectToElement(slNames.Objects[tempInteger])) = '00') then
        begin // Skips primary slot items
            Inc(tempInteger);
            Continue;
        end;
        commonString := Trim(slNames[tempInteger]); // String we're searching for
        while (Length(commonString) > 0) do
        begin // While tier 2
            { Debug } if debugMsg then
                addMessage('[AddOutfitByList] commonString := ' + commonString);
            slTemp.clear;
            for i := 0 to slNames.Count - 1 do
            begin
                if ContainsText(slNames[i], commonString) then
                begin // if there's another item with the same prefix add it to slTemp
                    tempelement := ObjectToElement(slNames.Objects[i]);
                    slTemp.addObject(EditorID(tempelement), tempelement);
                end;
            end;
            if (slTemp.Count > 1) then
            begin // If there's more than one item with the same name assemble an outfit
                { Debug } if debugMsg then
                    msgList('[AddOutfitByList] slTemp := ', slTemp, '');
                tempCount := 0; // Using the same trick again to keep track of where we are in the list
                while (slTemp.Count > tempCount) do
                begin // while tier 3
                    slItem.clear;
                    tempRecord := ObjectToElement(slTemp.Objects[tempCount]);
                    Slot       := GetPrimarySlot(tempRecord);
                    if (Slot <> '00') then
                    begin // Skips primary slot items
                        Inc(tempCount);
                        Continue;
                    end;
                    slGetFlagValues(tempRecord, slItem, false); // Get the BOD2 for this non-primary slot item
                    AddPrimarySlots(slItem);                    // Associate with primary slot
                    primarySlotItem := nil;
                    for i           := 0 to slTemp.Count - 1 do
                    begin // Associate the non-primary slot item with a primary-slot one of the same type
                        if (i = tempCount) then
                            Continue;
                        tempelement := ObjectToElement(slTemp.Objects[i]);
                        tempString  := GetPrimarySlot(tempelement);
                        if slContains(slItem, tempString) then
                        begin // if the outfit contains a primary slot item equal to the primary slot associated with this item then begin
                            primarySlotItem := tempelement;
                            Slot            := tempString;
                            break;
                        end;
                    end;
                    if Assigned(primarySlotItem) then
                    begin
                        LLrecord := MainRecordByEditorID(GroupBySignature(aPlugin, 'LVLI'), EditorID(primarySlotItem) + 'SubList');
                        if not Assigned(LLrecord) then
                            LLrecord := createLeveledList(aPlugin, EditorID(primarySlotItem) + 'SubList', slTempList, 0); // Create a 'Use All' leveled list to contain all the non-primary slot items associated with this primary slot
                    end else begin                                                                                        // if there isn't a same-type primary slot use any primary-slot item
                        for i := 0 to slTemp.Count - 1 do
                        begin // Associate the non-primary slot item with a primary-slot one of the same type
                            if (i = tempCount) then
                                Continue;
                            tempelement := ObjectToElement(slTemp.Objects[i]);
                            tempString  := GetPrimarySlot(tempelement);
                            if (GetPrimarySlot(tempelement) <> '00') then
                            begin // if the outfit contains a primary slot item equal to the primary slot associated with this item then begin
                                primarySlotItem := tempelement;
                                Slot            := tempString;
                                break;
                            end;
                        end;
                        if Assigned(primarySlotItem) then
                        begin // This is a hard-coded addition since this item won't be associated with the primary slot item in the main addition section
                            LLrecord := MainRecordByEditorID(GroupBySignature(aPlugin, 'LVLI'), EditorID(primarySlotItem) + 'SubList');
                            if not Assigned(LLrecord) then
                                LLrecord := createLeveledList(aPlugin, EditorID(primarySlotItem) + 'SubList', slTempList, 0); // Create a 'Use All' leveled list to contain all the non-primary slot items associated with this primary slot
                            if not LLcontains(LLrecord, tempRecord) then
                            begin
                                addToLeveledList(LLrecord, tempRecord, 1);
                                y := IndexOfObjectEDID(EditorID(tempRecord), slNames);
                                if (y <> -1) then
                                begin
                                    { Debug } if debugMsg then
                                        addMessage('[AddOutfitByList] slNames.Delete (' + EditorID(ObjectToElement(slNames.Objects[y])) + ');');
                                    slNames.Delete(y); // Remove from name list
                                end;
                                slTemp.Delete(tempCount); // Remove from outfit list
                                if slContains(aList, EditorID(tempRecord) + 'Original') then
                                begin
                                    { Debug } if debugMsg then
                                        addMessage('slContains(aList, ' + EditorID(tempRecord) + ') then begin');
                                    { Debug } if debugMsg then
                                        addMessage('[AddOutfitByList] aList.Delete (' + aList[aList.IndexOf(EditorID(tempRecord) + 'Original')] + ');');
                                    aList.Delete(aList.IndexOf(EditorID(tempRecord) + 'Original')); // Remove from leveled list addition
                                end;
                            end;
                        end;
                    end;
                    if not Assigned(primarySlotItem) then
                        break; // if there aren't any primary slot items in this outfit skip it entirely
                    // Leveled List Addition
                    { Debug } if debugMsg then
                        addMessage('[AddOutfitByList] primarySlotItem := ' + EditorID(primarySlotItem));
                    // Create Leveled List
                    { Debug } if debugMsg then
                        addMessage('[AddOutfitByList] Begin Outfit Creation');
                    slTempList.CommaText := '"Use All"';
                    { Debug } if debugMsg then
                        addMessage('[AddOutfitByList] addToLeveledList(' + EditorID(LLrecord) + ', ' + EditorID(primarySlotItem) + '), 1);');
                    if not LLcontains(LLrecord, primarySlotItem) then
                        addToLeveledList(LLrecord, primarySlotItem, 1);
                    { Debug } if debugMsg then
                        addMessage('[AddOutfitByList] LLrecord := ' + EditorID(LLrecord));
                    currentCount := 0; // Last 'while' loop, I promise
					for currentCount := pred(slTemp.count) downto 0 do 
					begin // Get all outfit items that are associated with this slot
                        currentElement := ObjectToElement(slTemp.Objects[currentCount]);
                        { Debug } if debugMsg then
                            addMessage('[AddOutfitByList] currentElement := ' + EditorID(currentElement));
                        if not(GetPrimarySlot(currentElement) = '00') then
                        begin // Skips primary slot items
                            Continue;
                        end;
                        slItem.clear;
                        slGetFlagValues(currentElement, slItem, false); // Get BOD2 slots
                        AddPrimarySlots(slItem);                        // Associate BOD2 with a primary slot
                        { Debug } if debugMsg then
                            msgList('[AddOutfitByList] ' + EditorID(currentElement) + ' Element BOD2 := ', slItem, '');
                        { Debug } if debugMsg then
                            msgList('[AddOutfitByList] if slContains (', slItem, '), ' + Slot);
                        if slContains(slItem, Slot) then
                        begin // if its associated with the current slot add it to the leveled list
                            { Debug } if debugMsg then
                                addMessage('[AddOutfitByList] addToLeveledList(' + EditorID(LLrecord) + ', ' + EditorID(currentElement) + '), 1);');
                            if not LLcontains(LLrecord, currentElement) then
                                addToLeveledList(LLrecord, currentElement, 1);
                            y := IndexOfObjectEDID(EditorID(currentElement), slNames);
                            if (y <> -1) then
                            begin
                                { Debug } if debugMsg then
                                    addMessage('[AddOutfitByList] slNames.Delete (' + EditorID(ObjectToElement(slNames.Objects[y])) + ');');
                                slNames.Delete(y); // Remove from name list
                            end;
                            { Debug } if debugMsg then
                                addMessage('[AddOutfitByList] slTemp.Delete (' + slTemp[currentCount] + ');');
                            slTemp.Delete(currentCount); // Remove from outfit list
                            if slContains(aList, EditorID(currentElement) + 'Original') then
                            begin
                                { Debug } if debugMsg then
                                    addMessage('slContains(aList, ' + EditorID(currentElement) + ') then begin');
                                { Debug } if debugMsg then
                                    addMessage('[AddOutfitByList] aList.Delete (' + aList[aList.IndexOf(EditorID(currentElement) + 'Original')] + ');');
                                aList.Delete(aList.IndexOf(EditorID(currentElement) + 'Original')); // Remove from leveled list addition
                            end;
                            if (currentCount = 0) then 
                                tempBoolean := true; // Only need to delete the current element in the master 'while' loop once
                        end;
                    end;
                    if (LLec(LLrecord) > 1) then
                    begin
                        if not slContains(slOutfits, EditorID(LLrecord)) then
                            slOutfits.addObject(EditorID(LLrecord), LLrecord);
                    end
                    else
                        Remove(LLrecord);
                end;   // while tier 3 end
                break; // if an outfit was assembled from this string exit the while loop
            end;
            if ContainsText(commonString, ' ') then
            begin // If an outfit is not found, shorten the number of words by 1 and check again
                commonString := Trim(StrPosCopy(commonString, ' ', true));
            end
            else
                break;
        end;                             // while tier 2 end
        if not tempBoolean then          // if not already deleted
            slNames.Delete(tempInteger); // Remove the name we just checked for
    end;                                 // while tier 1 end
    { Debug } if debugMsg then
        msgList('[AddOutfitByList] slOutfits := ', slOutfits, '');
    { Debug } if debugMsg then
        msgList('[AddOutfitByList] aList := ', aList, '');
    // Collect leveled lists
    addMessage('Beginning Leveled List Collection');
    // Custom Leveled List Input
    for i := 0 to slGlobal.Count - 1 do
        if ContainsText(slGlobal[i], '-/LeveledList/-') then
            slLL.addObject(StrPosCopy(slGlobal, '-/LeveledList/-', true), slGlobal.Objects[i]);
    // Leveled list from template
    for i := 0 to aList.Count - 1 do
    begin
        masterRecord := ObjectToElement(aList.Objects[i]);
        tempString   := EditorID(masterRecord);
        // If two records have the same template this prevents it from getting processed twice
        { Debug } if debugMsg then
            addMessage('[AddOutfitByList] If two records have the same template this prevents it from getting processed twice');
        if slContains(slTemp, tempString) then
            Continue
        else
            slTemp.Add(tempString);
        { Debug } if debugMsg then
            msgList('[AddOutfitByList] ', slTemp, '');
        addMessage('[' + IntToStr(i + 1) + '/' + IntToStr(aList.Count) + '] Collecting ' + tempString + ' Leveled Lists');
        { Debug } if debugMsg then
            addMessage('[AddOutfitByList] for x := 0 to ' + IntToStr(Pred(ReferencedByCount(masterRecord))) + ' do begin');
        for x := 0 to Pred(ReferencedByCount(masterRecord)) do
        begin
            LLrecord   := ReferencedByIndex(masterRecord, x);
            tempString := EditorID(LLrecord);
            { Debug } if debugMsg then
                addMessage('[AddOutfitByList] EditorID(LLrecord) := ' + tempString);
            // Filter Invalid Entries
            { Debug } if debugMsg then
                addMessage('[AddOutfitByList] Filter Invalid Entries');
            if slContains(slLL, tempString) then
                Continue;
            if ContainsText(tempString, '++') or (Length(tempString) <= 0) or not IsHighestOverride(LLrecord, LoadOrder) or not(Signature(LLrecord) = 'LVLI') or FlagCheck(LLrecord, 'Use All') or FlagCheck(LLrecord, 'Special Loot') then
                Continue;
            if not(LoadOrder >= GetLoadOrder(GetFile(LLrecord))) then
            begin
                if PreviousOverrideExists(LLrecord, LoadOrder) then
                begin
                    LLrecord := GetPreviousOverride(LLrecord, LoadOrder);
                end
                else
                    Continue;
            end
            else
                if debugMsg then
                    addMessage('[AddOutfitByList] ' + EditorID(LLrecord) + ' := ' + IntToStr(LoadOrder) + ' >= ' + IntToStr(GetLoadOrder(GetFile(LLrecord))));
            // Restricts the valid leveled lists to a single file (for 'Patch' function)
            { Debug } if debugMsg then
                addMessage('[AddOutfitByList] Restricts the valid leveled lists to a single file (for Patch function)');
            if Patch then
            begin
                tempString  := GetFileName(ObjectToElement(GetObject('Patch', slGlobal)));
                tempBoolean := false;
                // {Debug} if debugMsg then addMessage('[AddOutfitByList] for x := 0 to '+IntToStr(Pred(OverrideCount(LLrecord)))+' do begin');
                if (OverrideCount(LLrecord) > 0) then
                begin
                    for y := 0 to Pred(OverrideCount(LLrecord)) do
                    begin
                        { Debug } if debugMsg then
                            addMessage('[AddOutfitByList] if (GetFileName(GetFile(OverrideByIndex(' + EditorID(LLrecord) + ', ' + IntToStr(x) + '))) = ' + tempString + ') then begin');
                        if (GetFileName(GetFile(OverrideByIndex(LLrecord, y))) = tempString) then
                        begin
                            tempBoolean := true;
                            break;
                        end;
                    end;
                end
                else
                    if (GetFileName(GetFile(LLrecord)) = tempString) then
                        tempBoolean := true;
                if not tempBoolean then
                    Continue;
            end;
            // Add Copy to List
            slLL.addObject(EditorID(LLrecord), LLrecord);
        end;
    end;
    { Debug } if debugMsg then
        msgList('[AddOutfitByList] slLL := ', slLL, ' );');
    // Add Masters
    tempStart := Time;

    tempStop := Time;
    // addProcessTime('Add Masters', TimeBtwn(tempStart, tempStop));
    // Process Leveled Lists
    addMessage('Processing Leveled Lists');
    for i := 0 to slLL.Count - 1 do
    begin
        slTempList.clear;
        slTemp.clear;
        LLrecord := ObjectToElement(slLL.Objects[i]);
        { Debug } if debugMsg then
            addMessage('[AddOutfitByList] LLrecord := ' + EditorID(LLrecord));
        if (Length(EditorID(LLrecord)) <= 0) then
            Continue tempelement := ElementByName(LLrecord, 'Leveled List Entries');
        for x                    := 0 to Pred(LLec(LLrecord)) do
        begin
            tempRecord := elementbyindex(tempelement, x);
            slTemp.addObject(StrPosCopy(GetElementEditValues(tempRecord, 'LVLO\Reference'), ' ', true), StrToInt(GetElementEditValues(tempRecord, 'LVLO\Level'))); { Debug }
            if debugMsg then
                addMessage('[AddOutfitByList] slTemp.AddObject(' + StrPosCopy(GetElementEditValues(tempRecord, 'LVLO\Reference'), ' ', true) + ', ' + IntToStr(StrToInt(GetElementEditValues(tempRecord, 'LVLO\Level'))) + ' )');
        end; { Debug }
        if debugMsg then
            msgList('[AddOutfitByList] slTemp := ', slTemp, '');
        for x := 0 to aList.Count - 1 do
        begin
            tempRecord := ObjectToElement(GetObject(aList[x], slGlobal));
            { Debug } if debugMsg then
                addMessage('[AddOutfitByList] tempRecord := ' + EditorID(tempRecord));
            tempInteger := -1;
            // Custom input from 'Add To Leveled List' menu
            tempString := EditorID(LLrecord) + '-/Level/-' + EditorID(tempRecord);
            if slContains(slGlobal, tempString) then
            begin
                tempInteger := integer(GetObject(tempString, slGlobal)); { Debug }
                if debugMsg then
                    addMessage('[AddOutfitByList] Custom Level for ' + EditorID(tempRecord) + ' in ' + EditorID(LLrecord) + ' := ' + IntToStr(tempInteger));
                slGlobal.Delete(slGlobal.IndexOf(tempString));
                slGlobal.Delete(slGlobal.IndexOf(EditorID(LLrecord) + '-/LeveledList/-' + EditorID(tempRecord)));
                if (tempInteger <= 0) then
                    Continue;
            end;
            // Level from template
            if (tempInteger = -1) then
            begin
                tempString := EditorID(ObjectToElement(aList.Objects[x]));
                { Debug } if debugMsg then
                    addMessage('[AddOutfitByList] Find Template := ' + tempString);
                if slContains(slTemp, tempString) then
                    tempInteger := slTemp.Objects[slTemp.IndexOf(tempString)];
            end;
            { Debug } if debugMsg then
                addMessage('[AddOutfitByList] Level from ' + EditorID(LLrecord) + ' := ' + IntToStr(tempInteger));
            if (tempInteger = -1) then
                Continue;
            if (tempInteger = 0) then
                tempInteger := 1;
            // Detect Pre-Existing List or Create Override
            case GetLoadOrder(GetFile(LLrecord)) of
                LoadOrder:
                    LLcopy := LLrecord;
            else
                LLcopy := wbCopyElementToFile(LLrecord, aPlugin, false, true);
            end;
            { Debug } if debugMsg then
                addMessage('[AddOutfitByList] LLcopy := ' + EditorID(LLcopy));
            if not slContains(slTemp, EditorID(tempRecord)) then
            begin
                // {Debug} if debugMsg then msgList('[AddOutfitByList] if slContains(', slOutfits, '), '''+EditorID(tempRecord)+'SubList then');
                if slContains(slOutfits, EditorID(tempRecord) + 'SubList') then // if non-primary slots have been associated with this item add it instead
                    tempRecord := ObjectToElement(slOutfits.Objects[slOutfits.IndexOf(EditorID(tempRecord) + 'SubList')]);
                addToLeveledList(LLcopy, tempRecord, tempInteger); { Debug }
                if debugMsg then
                    addMessage('[AddOutfitByList] addToLeveledList(' + EditorID(LLcopy) + ', ' + EditorID(tempRecord) + ', ' + IntToStr(tempInteger) + ' )');
                slTempList.Add(EditorID(tempRecord));
            end;
        end;
        if (slTempList.Count > 0) then
            msgList('[' + IntToStr(i + 1) + '/' + IntToStr(slLL.Count) + '] ' + EditorID(LLrecord) + ' added: ', slTempList, '');
    end;

    // Finalize
    stopTime := Time;
    if ProcessTime then
        addProcessTime('AddOutfitByList', TimeBtwn(startTime, stopTime));
    slOutfits.Free;
    slNames.Free;
    slTempList.Free;
    slTemp.Free;
    slItem.Free;
    slLL.Free;
end;

// Reassembles and then adds to all outfits containing inputRecord
function AddToOutfitAuto(templateRecord: IInterface; inputRecord: IInterface; aPlugin: IInterface): string;
var
    tempLevelList, tempRecord, tempelement, masterLevelList, baseLevelList, subLevelList, vanillaLevelList, masterRecord, LVLIrecord, OTFTrecord, OTFTitems, OTFTitem, OTFTcopy, LLentry, Record_edid: IInterface;
    tempBoolean, LightArmorBoolean, HeavyArmorBoolean                                                                                                                                      : boolean;
    tempInteger, i, x, y, z, a, b                                                                                                                                                                    : integer;
    slTemp, slTempObject, slOutfit, slpair, slItem, slEnchantedList, slLevelList, slBlackList, slStringList, sl1, sl2                                                                                : TStringList;
    tempString, String1, commonString, OTFTrecord_edid                                                                                                                                               : string;
begin
    // If the OTFT draws from a series of level lists assemble complete outfits from the items in those lists.
    // In most cases OTFT records draw from a level list for each piece of the outfit (e.g. boots level list, helmet level list, etc.)
    // Identifies and assembles based on BOD2 slots
    // This assembles a level list of the entire 'Steel Plate' outfit so that npcs will USUALLY spawn with a complete outfit instead of a hodge-podge drawn from various level lists
    // This does not edit or remove the original list.  The original entries remain intact as a single outfit within the complete list of outfits in masterLevelList.
    // This means that, if there is 1 level list of the original outfit, 9 outfits are detected and assembled, and the script is adding 1 outfit, then you will StrToIntll have a 1/11 chance for a hodge-podge outfit <-- (1+9+1)
    // This is intended.  The goal is to improve the outfits, NEVER to remove existing entries or functionality (even if there is a lower chance to find those items).
    // The output should be A) A LL of selected Records B) LLs of outfit's original records C) A LL consiStrToIntng of the leftovers
    // Begin debugMsg Section
    

    // Initialize
    if not Assigned(slEnchantedList) then
        slEnchantedList := TStringList.Create
    else
        slEnchantedList.clear;
    if not Assigned(slStringList) then
        slStringList := TStringList.Create
    else
        slStringList.clear;
    if not Assigned(slTempObject) then
        slTempObject := TStringList.Create
    else
        slTempObject.clear;
    if not Assigned(slBlackList) then
        slBlackList := TStringList.Create
    else
        slBlackList.clear;
    if not Assigned(slLevelList) then
        slLevelList := TStringList.Create
    else
        slLevelList.clear;
    if not Assigned(slOutfit) then
        slOutfit := TStringList.Create
    else
        slOutfit.clear;
    if not Assigned(slItem) then
        slItem := TStringList.Create
    else
        slItem.clear;
    if not Assigned(slTemp) then
        slTemp := TStringList.Create
    else
        slTemp.clear;
    if not Assigned(slpair) then
        slpair := TStringList.Create
    else
        slpair.clear;
    if not Assigned(sl1) then
        sl1 := TStringList.Create
    else
        sl1.clear;
    if not Assigned(sl2) then
        sl2 := TStringList.Create
    else
        sl2.clear;

    // Common Function Output
    masterRecord := MasterOrSelf(templateRecord);

    /// /////////////////////////////////////////////////////////////////// OTFT RECORD DETECTION ///////////////////////////////////////////////////////////////////////////////////////
    // Find valid OTFT records
    { Debug } if debugMsg then
        addMessage('[AddToOutfitAuto] Begin OTFT Record Detection');
    { Debug } if debugMsg then
        addMessage('[AddToOutfitAuto] for i := 0 to Pred(ReferencedByCount(masterRecord)) :=' + IntToStr(Pred(ReferencedByCount(masterRecord))) + ' do begin');
    for i := 0 to Pred(ReferencedByCount(masterRecord)) do
    begin { Debug }
        if debugMsg then
            addMessage('[AddToOutfitAuto] LVLIrecord := ' + EditorID(ReferencedByIndex(masterRecord, i)));
        slTempObject.clear;
        LVLIrecord := ReferencedByIndex(masterRecord, i); { Debug }
        if debugMsg then
            addMessage('[AddToOutfitAuto] if (Signature(LVLIrecord) := ' + Signature(LVLIrecord) + '= ''LVLI'') then begin');
        if (Signature(LVLIrecord) = 'LVLI') then
        begin
            // Check for outfits that reference a list of items of a specific type (e.g. Boots, Gauntlets)
            while (Signature(LVLIrecord) = 'LVLI') do
            begin
                { Debug } if debugMsg then
                    addMessage('[AddToOutfitAuto] for x := 0 to Pred(ReferencedByCount(LVLIrecord)) := ' + IntToStr(Pred(ReferencedByCount(LVLIrecord))) + ' do begin');
                for x := 0 to Pred(ReferencedByCount(LVLIrecord)) do
                begin { Debug }
                    if debugMsg then
                        addMessage('[AddToOutfitAuto] OTFTrecord := ReferencedByIndex(LVLIrecord, x) := ' + EditorID(ReferencedByIndex(LVLIrecord, x)) + ';');
                    OTFTrecord := ReferencedByIndex(LVLIrecord, x); { Debug }
                    if debugMsg then
                        addMessage('[AddToOutfitAuto] if IsWinningOVerride(OTFTrecord) := ' + BoolToStr(IsWinningOVerride(OTFTrecord)) + ' and (Signature(OTFTrecord) := ' + Signature(OTFTrecord) + ' = ''OTFT'') and ContainsText(EditorID(OTFTrecord), ''Armor'') := ' + BoolToStr(ContainsText(EditorID(OTFTrecord), 'Armor')) + ' then begin');
                    if (Signature(OTFTrecord) = 'OTFT') then
                    begin
                        if not IsWinningOVerride(OTFTrecord) then
                            Continue;
                        // Check if OTFT references LVLI or is referenced more than once (to exclude outfits specifically for a single NPC)
                        tempBoolean := false;
                        if (ReferencedByCount(OTFTrecord) > 1) then
                            tempBoolean := true;
                        if not tempBoolean then
                            for y := 0 to Pred(ElementCount(ElementByPath(OTFTrecord, 'INAM'))) do
                                if (Signature(elementbyindex(ElementByPath(OTFTrecord, 'INAM'), y)) = 'LVLI') then
                                    tempBoolean := true;
                        if tempBoolean and (Signature(OTFTrecord) = 'OTFT') then
                            if not slContains(slOutfit, EditorID(OTFTrecord)) then
                                slOutfit.addObject(EditorID(OTFTrecord), OTFTrecord);
                    end
                    else
                        if (Signature(LVLIrecord) = 'LVLI') then
                        begin
                            slTempObject.addObject(EditorID(OTFTrecord), OTFTrecord);
                        end;
                end;
                if (slTempObject.Count > 0) then
                begin
                    LVLIrecord := ObjectToElement(slTempObject.Objects[0]);
                    slTempObject.Delete(0);
                end else begin
                    break;
                end;
            end;
        end else begin
            OTFTrecord := ReferencedByIndex(masterRecord, i); { Debug }
            if debugMsg then
                addMessage('[AddToOutfitAuto] if (Signature(OTFTrecord) := ' + Signature(OTFTrecord) + '= ''LVLI'') then begin');
            if IsWinningOVerride(OTFTrecord) and (Signature(OTFTrecord) = 'OTFT') then
                if not slContains(slOutfit, EditorID(OTFTrecord)) then
                    slOutfit.addObject(EditorID(OTFTrecord), OTFTrecord);
        end;
    end;
    /// /////////////////////////////////////////////////////////////////// RESTRUCTURE OTFT RECORDS ///////////////////////////////////////////////////////////////////////////////////
    { Debug } if debugMsg then
        addMessage('[AddToOutfitAuto] FormID Detection Complete; Restructuring OTFT records');
    { Debug } if debugMsg then
        msgList('[AddToOutfitAuto] slOutfit := ', slOutfit, '');
    if not(slOutfit.Count > 0) then
        Continue;
    for i := 0 to slOutfit.Count - 1 do
    begin
        OTFTcopy   := nil;
        OTFTrecord := WinningOverride(ObjectToElement(slOutfit.Objects[i])); { Debug }
        if debugMsg then
            addMessage('[AddToOutfitAuto] OTFTrecord := ' + EditorID(OTFTrecord));
        OTFTrecord_edid := EditorID(OTFTrecord);
        // Add Masters

        OTFTitems := ElementByPath(OTFTrecord, 'INAM');
        // Check for a previous script run
        if (ElementCount(OTFTitems) = 1) and (Signature(LinksTo(elementbyindex(OTFTitems, 0))) = 'LVLI') then
        begin
            { Debug } if debugMsg then
                addMessage('[AddToOutfitAuto] if tempInteger = 1 end else begin');
            masterLevelList := MainRecordByEditorID(GroupBySignature(aPlugin, 'LVLI'), (OTFTrecord_edid + '_Master'));
            // This is for outfits with a single level list that can be used in a new masterLevelList
            if not Assigned(masterLevelList) then
            begin
                slTemp.CommaText := '"Use All"';
                masterLevelList  := createLeveledList(aPlugin, OTFTrecord_edid + '_Master', slTemp, 0);
                vanillaLevelList := LinksTo(elementbyindex(OTFTitems, 0));
                for y            := 0 to 3 do
                    addToLeveledList(masterLevelList, vanillaLevelList, 1);
                addToLeveledList(masterLevelList, inputRecord, 1);
            end;
            // This section restructures the outfit if this is the first time the script is editing this outfit
        end else begin
            // Preps the leveled lists
            { Debug } if debugMsg then
                addMessage('[AddToOutfitAuto] Creating a new vanillaLevelList and masterLevelList if not already present');
            // Check if aPlugin already has a leveled list created for vanillaLevelList
            vanillaLevelList := MainRecordByEditorID(GroupBySignature(aPlugin, 'LVLI'), (OTFTrecord_edid + '_Original'));
            { Debug } if debugMsg and Assigned(vanillaLevelList) then
                addMessage('[AddToOutfitAuto] Pre-existing vanillaLevelList := ' + EditorID(vanillaLevelList))
                { Debug } else
                if debugMsg and not Assigned(vanillaLevelList) then
                    addMessage('[AddToOutfitAuto] Pre-existing vanillaLevelList not detected');
            if not Assigned(vanillaLevelList) then
            begin
                if (ElementCount(OTFTitems) > 1) then
                begin
                    slTemp.CommaText := '"Use All"';
                    vanillaLevelList := createLeveledList(aPlugin, OTFTrecord_edid + '_Original', slTemp, 0);
                    for y            := 0 to Pred(ElementCount(OTFTitems)) do
                        addToLeveledList(vanillaLevelList, LinksTo(elementbyindex(OTFTitems, y)), 1);
                end
                else
                    vanillaLevelList := elementbyindex(OTFTitems, 0);
            end;
            // Create masterlevellist if not already present
            masterLevelList := MainRecordByEditorID(GroupBySignature(aPlugin, 'LVLI'), (OTFTrecord_edid + '_Master'));
            { Debug } if debugMsg and Assigned(masterLevelList) then
                addMessage('[AddToOutfitAuto] Pre-existing masterLevelList := ' + EditorID(masterLevelList))
                { Debug } else
                if debugMsg and not Assigned(masterLevelList) then
                    addMessage('[AddToOutfitAuto] Pre-existing masterLevelList not detected');
            if not Assigned(masterLevelList) then
            begin
                slTemp.CommaText := '"Use All"';
                masterLevelList  := createLeveledList(aPlugin, OTFTrecord_edid + '_Master', slTemp, 0);
                for y            := 0 to 3 do
                    addToLeveledList(masterLevelList, vanillaLevelList, 1);
            end;
            { Debug } if debugMsg then
                addMessage('[AddToOutfitAuto] if not LLcontains(' + EditorID(masterLevelList) + ', ' + EditorID(inputRecord) + ' ) := ' + BoolToStr(LLcontains(masterLevelList, inputRecord)) + ' then begin');
            if not LLcontains(masterLevelList, inputRecord) then
            begin
                addToLeveledList(masterLevelList, inputRecord, 1);
                { Debug } if debugMsg then
                    addMessage('[AddToOutfitAuto] addToLeveledList(' + EditorID(masterLevelList) + ', ' + EditorID(inputRecord) + ', 1);');
            end;
        end;
        // This finishes restructuring the outfit so that new armor sets can be added as a whole set instead of piece by piece
        { Debug } if debugMsg then
            addMessage('[AddToOutfitAuto] if HasGroup(aPlugin, ''OTFT'') := ' + BoolToStr(HasGroup(aPlugin, 'OTFT')) + ' then');
        OTFTcopy := MainRecordByEditorID(GroupBySignature(aPlugin, 'OTFT'), OTFTrecord_edid);
        { Debug } if debugMsg then
            addMessage('[AddToOutfitAuto] if not Assigned(OTFTcopy) := ' + BoolToStr(Assigned(OTFTcopy)) + ' then begin');
        // If there is not already an override of OTFTcopy in aPlugin then create one
        if not Assigned(OTFTcopy) then
        begin
            { Debug } if debugMsg then
                addMessage('[AddToOutfitAuto] OTFTcopy := wbCopyElementToFile(' + OTFTrecord_edid + ', ' + GetFileName(aPlugin) + ', False, True)');
            OTFTcopy := wbCopyElementToFile(OTFTrecord, aPlugin, false, true);
        end;
        
        // End debugMsg Section
        /// /////////////////////////////////////////////////////////////////// ASSEMBLE OTFT FROM VANILLA ENTRIES - RECORD IDENTIFICATION /////////////////////////////////////////////////////////////////////////////
        // Begin debugMsg Section
        
        slEnchantedList.clear;
        slBlackList.clear;
        slLevelList.clear;
        slItem.clear;
        slTemp.clear;
        // Check if OTFT contains LVLI
        tempBoolean := false;
        // Checks if OTFT has a LVLI to be processed
        for x := 0 to Pred(ElementCount(ElementByPath(OTFTcopy, 'INAM'))) do
        begin
            if (Signature(LinksTo(elementbyindex(ElementByPath(OTFTcopy, 'INAM'), x))) = 'LVLI') then
            begin
                tempBoolean := true;
                break;
            end;
        end;
        { Debug } if debugMsg then
            addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] ' + EditorID(OTFTcopy) + ' contains LVLI := ' + BoolToStr(tempBoolean));
        // Get a complete list of all items and enchanted sets
        { Debug } if debugMsg then
            addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] Get a complete list of all items and enchanted sets');
        if tempBoolean then
        begin
            for x := 0 to Pred(ElementCount(ElementByPath(OTFTcopy, 'INAM'))) do
            begin
                // Commonly used functions; This is just to reduce the number of complicated functions that are called (and therefore reduce processing time)
                { Debug } if debugMsg then
                    addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] Commonly used functions');
                tempRecord  := WinningOverride(LinksTo(elementbyindex(ElementByPath(OTFTcopy, 'INAM'), x)));
                Record_edid := EditorID(tempRecord);
                // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] tempRecord := '+EditorID(tempRecord));
                tempBoolean := false;
                // Check lists for an identical item
                if slContains(slEnchantedList, Record_edid) or slContains(slLevelList, Record_edid) or slContains(slItem, Record_edid) then
                    tempBoolean := true;
                // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] ItemAlreadyAdded := '+BoolToStr(tempBoolean));
                if not tempBoolean then
                begin
                    if (Signature(tempRecord) = 'LVLI') then
                    begin
                        if ContainsText(EditorID(tempRecord), 'Ench') then
                        begin
                            if not slContains(slEnchantedList, Record_edid) then
                            begin
                                // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] slEnchantedList.Add('+EditorID(tempRecord)+' );');
                                slEnchantedList.addObject(Record_edid, tempRecord);
                            end;
                        end else begin
                            if not slContains(slLevelList, Record_edid) then
                            begin
                                // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] slTemp.Add(EditorID('+EditorID(tempRecord)+' ));');
                                slLevelList.addObject(Record_edid, tempRecord);
                            end;
                        end;
                    end else begin
                        if not slContains(slItem, Record_edid) then
                        begin
                            // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] slItem.Add(EditorID('+EditorID(tempRecord)+' ));');
                            slItem.addObject(Record_edid, tempRecord);
                        end;
                    end;
                end;
                // Leveled lists are often nested multiple times. This 'while' loop adds all their entries to a single list
                { Debug } if debugMsg and (slLevelList.Count > 0) then
                    addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] Leveled lists are often nested multiple times. This ''while'' loop adds all their entries to a single list');
                { Debug } if debugMsg then
                    msgList('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] slLevelList := ', slLevelList, '');
                while (slLevelList.Count > 0) do
                begin
                    for y := 0 to Pred(LLec(ObjectToElement(slLevelList.Objects[0]))) do
                    begin
                        tempRecord  := WinningOverride(LLelementbyindex(ObjectToElement(slLevelList.Objects[0]), y));
                        Record_edid := EditorID(tempRecord);
                        if not(Length(EditorID(tempRecord)) > 0) then
                            Continue;
                        // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] tempRecord := '+Record_edid);
                        if (Signature(tempRecord) = 'LVLI') then
                        begin
                            if ContainsText(EditorID(tempRecord), 'Ench') then
                            begin
                                if not slContains(slEnchantedList, Record_edid) then
                                begin
                                    // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] slEnchantedList.Add(EditorID('+Record_edid+' ));');
                                    slEnchantedList.addObject(Record_edid, tempRecord);
                                end;
                            end else begin
                                if not slContains(slLevelList, Record_edid) then
                                begin
                                    // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] slTempObject.Add(EditorID('+Record_edid+' ));');
                                    slTempObject.addObject(Record_edid, tempRecord);
                                end;
                            end;
                        end else begin
                            if not slContains(slItem, Record_edid) then
                            begin
                                // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] slItem.Add(EditorID('+Record_edid+' ));');
                                slItem.addObject(Record_edid, tempRecord);
                            end;
                        end;
                    end;
                    // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] slLevelList.Delete('+slLevelList[0]+' );');
                    slLevelList.Delete(0);
                    if (slLevelList.Count = 0) then
                    begin
                        for z := 0 to slTempObject.Count - 1 do
                        begin
                            if not slContains(slLevelList, slTempObject[z]) then
                            begin
                                // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] slLevelList.Add('+slTempObject[z]+' );');
                                slLevelList.addObject(slTempObject[z], ObjectToElement(slTempObject.Objects[z]));
                            end;
                        end;
                        slTempObject.clear;
                    end;
                    if (slLevelList.Count = -1) then
                        break;
                end;
            end;
            // If there are enchanted lists, replace them with a 'template' record.  For the sake of simplicity it will be replaced with the enchanted list later
            { Debug } if debugMsg then
                addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] If there are enchanted lists, make sure the original record is in the items list.  For the sake of simplicity it will be replaced with the enchanted list later');
            for x := 0 to slEnchantedList.Count - 1 do
            begin
                // Grab the template for the enchanted list.  These are also nested often
                { Debug } if debugMsg then
                    addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] tempRecord := ' + EditorID(WinningOverride(ObjectToElement(slEnchantedList.Objects[x]))));
                tempRecord := WinningOverride(ObjectToElement(slEnchantedList.Objects[x]));
                while (Signature(tempRecord) = 'LVLI') do
                begin
                    tempRecord := LLelementbyindex(tempRecord, 0);
                    { Debug } if debugMsg then
                        addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] tempRecord := ' + EditorID(tempRecord));
                end;
                // Check the list for the template item
                { Debug } if debugMsg then
                    addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] Check the list for the template item');
                if not slContains(slItem, EditorID(GetEnchTemplate(tempRecord))) then
                begin
                    // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] slItem.Add('+EditorID(tempRecord)+' );');
                    slItem.addObject(EditorID(GetEnchTemplate(tempRecord)), GetEnchTemplate(tempRecord));
                end;
            end;
            // This is the main section where similiar items are added to an outfit
            { Debug } if debugMsg then
                addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] This is the main section where similiar items are added to an outfit');
            { Debug } if debugMsg then
                msgList('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] slItem := ', slItem, '');
            for x := 0 to slItem.Count - 1 do
            begin
                slStringList.clear;
                // Exclude entries already added to lists by this script
                if slContains(slBlackList, slItem[x]) then
                    Continue
                    // Delete common junk words
                      slTemp.CommaText := 'Mask, Bracers, Armor, Helmet, Hood, Crown, Shield, Buckler, Cuirass, Greaves, Boots, Gloves, Gauntlets, Hood';
                slStringList.CommaText := full(WinningOverride(ObjectToElement(slItem.Objects[x])));
                { Debug } if debugMsg then
                    msgList('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] slStringList := ', slStringList, '');
                for y := 0 to slTemp.Count - 1 do
                    if slContains(slStringList, slTemp[y]) then
                        slStringList.Delete(slStringList.IndexOf(slTemp[y]));
                if slStringList.Count = 0 then
                    Continue;
                slTempObject.clear;
                // Search all slItem records for similiar words to the current record with decreasing levels of precision
                { Debug } if debugMsg then
                    addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] Search all slItem records for similiar words to the current record with decreasing levels of precision');
                { Debug } if debugMsg then
                    msgList('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] slStringList := ', slStringList, '');
                for y := 0 to slStringList.Count - 1 do
                begin
                    commonString := nil;
                    for z        := slStringList.Count - 1 downto 0 do
                    begin
                        commonString := Trim(commonString + ' ' + slStringList[z]);
                        // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] [Decreasing Precision] CommonString := '+CommonString);
                    end;
                    for z := 0 to slItem.Count - 1 do
                        if ContainsText(full(ObjectToElement(slItem.Objects[z])), commonString) then
                            if not(z = x) then
                                if not slContains(slTempObject, slItem[z]) then
                                    slTempObject.addObject(slItem[z], slItem.Objects[z]);
                    if (slTempObject.Count > 1) then
                        break;
                end;
                if not(slTempObject.Count > 1) then
                    Continue;
                { Debug } if debugMsg then
                    addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] Decreasing Precision Output := ' + commonString);
                { Debug } if debugMsg then
                    msgList('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] slTempObject := ', slTempObject, '');
                
                // End debugMsg section
                /// /////////////////////////////////////////////////////////////////// ASSEMBLE OTFT FROM VANILLA ENTRIES - OUTFIT GENERATION /////////////////////////////////////////////////////////////////////////////
                // Begin debugMsg section
                
                // Create and fill a level list for the outfit if one does not exist
                // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] Create and fill a level list for the outfit');
                tempString    := ('LLOutfit_' + RemoveSpaces(RemoveFileSuffix(GetFileName(GetFile(MasterOrSelf(tempRecord))))) + '_' + RemoveSpaces(commonString));
                tempLevelList := MainRecordByEditorID(GroupBySignature(aPlugin, 'LVLI'), tempString);
                { Debug } if debugMsg and Assigned(tempLevelList) then
                    addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] tempLevelList already exists; tempLevelList := ' + EditorID(tempLevelList));
                if not Assigned(tempLevelList) then
                begin
                    { Debug } if debugMsg then
                        addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] tempLevelList unassigned; Creating ' + tempString);
                    slTemp.CommaText := '"Use All"';
                    tempLevelList    := createLeveledList(aPlugin, tempString, slTemp, 0);
                    { Debug } if debugMsg then
                        msgList('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Begin vanilla outfit generation; slTempObject := ', slTempObject, '');
                    for y := 0 to slTempObject.Count - 1 do
                    begin
                        tempRecord  := ObjectToElement(slTempObject.Objects[y]);
                        Record_edid := slTempObject[y];
                        // Check to see if the record was used in a previous loop
                        // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Check to see if the record was used in a previous loop');
                        if slContains(slBlackList, slTempObject[y]) then
                            Continue;
                        // Check if a subLevelList is needed
                        { Debug } if debugMsg then
                            addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Check if a subLevelList is needed for ' + Record_edid);
                        sl1.clear;
                        sl2.clear;
                        tempBoolean := false;
                        // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] slGetFlagValues('+slTempObject[y]+', '+GetElementType+' , ''First Person Flags''), sl1, False);');
                        slGetFlagValues(tempRecord, sl1, false);
                        { Debug } if debugMsg then
                            msgList('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] sl1 := ', sl1, '');
                        { Debug } if debugMsg then
                            addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Check for items that don''t use a primary or vanilla slot');
                        // Check for items that don't use a primary or vanilla slot; All of these items get subLevelLists in order to implement a percent chance none
                        sl2.CommaText := '30, 32, 33, 37, 39'; // 30 - Head, 32 - Body, 33 - Gauntlers, 37 - Feet, 39 - Shield
                        for z         := 0 to sl2.Count - 1 do
                            if slContains(sl1, sl2[z]) then
                                tempBoolean := true;
                        { Debug } if debugMsg then
                            addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Primary slot check := ' + BoolToStr(tempBoolean));
                        // Check for common primary slot keywords; This is primarily for to account for mods that change the slot layout of helmets for compatability reasons
                        sl2.CommaText := 'Boots, Helmet, Shield, Cuirass, Gauntlets, Shield, Hands, Head, Body, Gloves, Bracers, Ring, Robes, Hood, Mask';
                        for z         := 0 to sl2.Count - 1 do
                            if ContainsText(Record_edid, sl2[z]) or ContainsText(full(tempRecord), sl2[z]) then
                                tempBoolean := true;
                        tempBoolean         := Flip(tempBoolean);
                        // Check for subLevelLists' slots
                        if not tempBoolean then
                        begin
                            { Debug } if debugMsg then
                                addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Check for subLevelLists'' slots');
                            for z := 0 to Pred(LLec(tempLevelList)) do
                            begin
                                if (Signature(LLelementbyindex(tempLevelList, z)) = 'LVLI') then
                                begin
                                    for a := 0 to sl1.Count - 1 do
                                    begin
                                        if ContainsText(EditorID(LLelementbyindex(tempLevelList, z)), sl1[a]) then
                                        begin
                                        tempBoolean := true;
                                        { Debug } if debugMsg then
                                        addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] subLevelList check := ' + BoolToStr(tempBoolean));
                                        { Debug } if debugMsg then
                                        addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] ContainsText(' + EditorID(LLelementbyindex(tempLevelList, z)) + ', ' + sl1[a] + ' )');
                                        break;
                                        end;
                                    end;
                                end;
                            end;
                        end;
                        // Check for items that use the same slot
                        if not tempBoolean then
                        begin
                            { Debug } if debugMsg then
                                addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Check for items that use the same slot');
                            for z := 0 to slTempObject.Count - 1 do
                            begin
                                if (z = y) then
                                    Continue;
                                sl2.clear;
                                slGetFlagValues(tempRecord, sl2, false);
                                // {Debug} if debugMsg then msgList('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] sl1 := ', sl1, '');
                                // {Debug} if debugMsg then msgList('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] sl2 := ', sl2, '');
                                for a := 0 to sl1.Count - 1 do
                                begin
                                    if slContains(sl2, sl1[a]) then
                                    begin
                                        tempBoolean := true;
                                        { Debug } if debugMsg then
                                        addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] same slot check := ' + BoolToStr(tempBoolean));
                                        // {Debug} if debugMsg then msgList('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] slContains(',sl2, ', '+sl1[a]+' )');
                                        break;
                                    end;
                                end;
                            end;
                        end;
                        // Create subLevelList
                        { Debug } if debugMsg then
                            addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Create subLevelList for ' + slTempObject[y] + ' := ' + BoolToStr(tempBoolean));
                        if tempBoolean then
                        begin
                            // Get pre-existing list or create a new one
                            String1     := nil;
                            for z       := 0 to sl1.Count - 1 do
                                String1 := Trim(String1 + ' ' + sl1[z]);
                            // Check for pre-existing subLevelList
                            { Debug } if debugMsg then
                                addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Check for pre-existing subLevelList');
                            subLevelList := MainRecordByEditorID(GroupBySignature(aPlugin, 'LVLI'), ('LLOutfit_' + RemoveSpaces(RemoveFileSuffix(GetFileName(GetFile(MasterOrSelf(tempRecord))))) + '_' + RemoveSpaces(commonString) + '_SubList_(BOD2: ' + String1 + ')'));
                            if Assigned(subLevelList) then
                            begin
                                { Debug } if debugMsg then
                                    addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Pre-existing sublist ' + EditorID(subLevelList) + ' detected; if not LLcontains(' + EditorID(tempLevelList) + ', ' + Record_edid + ' ) := ' + BoolToStr(LLcontains(tempLevelList, tempRecord)) + ' then begin');
                                if not LLcontains(subLevelList, tempRecord) then
                                begin
                                    addToLeveledList(subLevelList, tempRecord, 1);
                                    { Debug } if debugMsg then
                                        addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] addToLeveledList(' + EditorID(tempLevelList) + ', ' + slTempObject[y] + ', 1);');
                                end;
                                // Blacklist used items
                                if not slContains(slBlackList, Record_edid) then
                                    slBlackList.Add(Record_edid);
                            end;
                            // Create subLevelList if not already assigned
                            if not Assigned(subLevelList) then
                            begin
                                { Debug } if debugMsg then
                                    addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Creating new subLevelList');
                                slTemp.CommaText := '"Calculate from all levels <= player''s level", "Calculate for each item in count"';
                                subLevelList     := createLeveledList(aPlugin, ('LLOutfit_' + RemoveSpaces(RemoveFileSuffix(GetFileName(GetFile((MasterOrSelf(tempRecord)))))) + '_' + RemoveSpaces(commonString) + '_SubList_(BOD2: ' + String1 + ')'), slTemp, 0);
                                { Debug } if debugMsg then
                                    addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] addToLeveledList(' + EditorID(subLevelList) + ', ' + Record_edid + ', 1);');
                                addToLeveledList(subLevelList, tempRecord, 1);
                                // Items in non-primary or non-vanilla slots get an 80 percent chance none; This should include scarves, necklaces, etc.
                                sl2.clear;
                                sl2.CommaText := '30, 32, 33, 37, 39'; // 30 - Head, 32 - Body, 33 - Gauntlers, 37 - Feet, 39 - Shield
                                tempBoolean   := false;
                                for z         := 0 to sl2.Count - 1 do
                                    if ContainsText(String1, sl2[z]) then
                                        tempBoolean := true;
                                // Check for common primary slot keywords; This is primarily for to account for mods that change the slot layout of helmets for compatability reasons
                                sl2.CommaText := 'Boots, Helmet, Shield, Cuirass, Gauntlets, Shield, Hands, Head, Body, Gloves, Bracers, Ring, Robes, Hood, Mask';
                                for z         := 0 to sl2.Count - 1 do
                                    if ContainsText(Record_edid, sl2[z]) or ContainsText(full(tempRecord), sl2[z]) then
                                        tempBoolean := true;
                                if not tempBoolean then
                                    SetElementNativeValues(subLevelList, 'LVLD', 80); // Percent chance none
                                // Blacklist used items
                                if not slContains(slBlackList, Record_edid) then
                                    slBlackList.Add(Record_edid);
                            end;
                            { Debug } if debugMsg then
                                addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Identify Records by BOD2');
                            // Identify Records by BOD2
                            for z := 0 to slTempObject.Count - 1 do
                            begin
                                tempelement := ObjectToElement(slTempObject.Objects[z]);
                                sl2.clear;
                                slGetFlagValues(tempelement, sl2, false);
                                tempInteger := 0;
                                for a       := 0 to sl1.Count - 1 do
                                begin
                                    for b := 0 to sl2.Count - 1 do
                                    begin
                                        if ContainsText(sl2[b], sl1[a]) then
                                        begin
                                        // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] ContainsText('+sl2[b]+', '+sl1[a]+' )');
                                        Inc(tempInteger);
                                        end;
                                    end;
                                end;
                                if (tempInteger = sl1.Count) then
                                begin
                                    // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries] if not LLcontains('+EditorID(subLevelList)+', '+slTempObject[z]+' ) := '+BoolToStr(LLcontains(subLevelList, tempElement))+' then begin');
                                    if not LLcontains(subLevelList, tempelement) then
                                    begin
                                        { Debug } if debugMsg then
                                        addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] addToLeveledList(' + EditorID(subLevelList) + ', ' + slTempObject[z] + ', 1);');
                                        addToLeveledList(subLevelList, tempelement, 1);
                                    end;
                                    // Blacklist used items
                                    if not slContains(slBlackList, slTempObject[z]) then
                                        slBlackList.Add(slTempObject[z]);
                                end;
                            end;
                            // Check if the leveled list contains a template for an enchanted list
                            { Debug } if debugMsg then
                                addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Check if the leveled list contains a template for an enchanted list');
                            for a := 0 to slEnchantedList.Count - 1 do
                            begin
                                for b := 0 to Pred(LLec(subLevelList)) do
                                begin
                                    tempelement := ObjectToElement(slEnchantedList.Objects[a]);
                                    if ElementExists(LLelementbyindex(tempelement, 0), 'CNAM') then
                                    begin
                                        if (EditorID(LinksTo(ElementBySignature(LLelementbyindex(tempelement, 0), 'CNAM'))) = EditorID(LLelementbyindex(subLevelList, b))) then
                                        begin
                                        { Debug } if debugMsg then
                                        addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] LLreplace(' + EditorID(subLevelList) + ', ' + EditorID(LLelementbyindex(subLevelList, b)) + ', ' + slEnchantedList[a] + ' );');
                                        if not LLcontains(tempLevelList, tempelement) then
                                        LLreplace(tempLevelList, LLelementbyindex(subLevelList, b), tempelement);
                                        end;
                                    end
                                    else
                                        if ElementExists(LLelementbyindex(tempelement, 0), 'TNAM') then
                                        begin
                                        if (EditorID(LinksTo(ElementBySignature(LLelementbyindex(tempelement, 0), 'TNAM'))) = EditorID(LLelementbyindex(subLevelList, b))) then
                                        begin
                                        { Debug } if debugMsg then
                                        addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] LLreplace(' + EditorID(subLevelList) + ', ' + EditorID(LLelementbyindex(subLevelList, b)) + ', ' + slEnchantedList[a] + ' );');
                                        if not LLcontains(tempLevelList, tempelement) then
                                        LLreplace(tempLevelList, LLelementbyindex(subLevelList, b), tempelement);
                                        end;
                                        end;
                                end;
                            end;
                            // Check if another leveled list also covers the same BOD2 parts
                            { Debug } if debugMsg then
                                addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Check if another leveled list also covers the same BOD2 parts');
                            tempBoolean := false;
                            for z       := 0 to Pred(LLec(tempLevelList)) do
                            begin
                                if (Signature(LLelementbyindex(tempLevelList, z)) = 'LVLI') then
                                begin
                                    for a := 0 to sl1.Count - 1 do
                                    begin
                                        if ContainsText(EditorID(LLelementbyindex(tempLevelList, z)), sl1[a]) then
                                        begin
                                        String1       := StrPosCopy(EditorID(LLelementbyindex(tempLevelList, z)), '(', false);
                                        String1       := StrPosCopy(String1, ')', true);
                                        sl2.CommaText := String1;
                                        if (sl1.Count < sl2.Count) then
                                        begin
                                        if not LLcontains(LLelementbyindex(tempLevelList, z), subLevelList) then
                                        begin
                                        addToLeveledList(LLelementbyindex(tempLevelList, z), subLevelList, 1);
                                        tempBoolean := true;
                                        // Removes duplicate elements in the leveled list one level above
                                        // Example: A sublist for slot 40 is created and contains all items that occupy slot 40.  There is already a list in tempLevelList for items with slot 40 and slot 42.
                                        // This removes items that have slot bot slot 40 and slot 42, leaving only slot 40 items in the sublist
                                        for b := 0 to Pred(LLec(tempLevelList)) do
                                        if LLcontains(subLevelList, LLelementbyindex(tempLevelList, b)) then
                                        LLremove(subLevelList, LLelementbyindex(tempLevelList, b));
                                        // Sub-sublists don't need a percent chance none
                                        if ElementExists(subLevelList, 'LVLD') then
                                        Remove(ElementBySignature(subLevelList, 'LVLD'));
                                        end;
                                        end
                                        else
                                        if (sl1.Count > sl2.Count) then
                                        begin
                                        LLreplace(tempLevelList, LLelementbyindex(tempLevelList, z), subLevelList);
                                        if not LLcontains(subLevelList, LLelementbyindex(tempLevelList, z)) then
                                        begin
                                        { Debug } if debugMsg then
                                        addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] addToLeveledList(' + EditorID(subLevelList) + ', ' + EditorID(LLelementbyindex(tempLevelList, z)) + ', 1);');
                                        addToLeveledList(subLevelList, LLelementbyindex(tempLevelList, z), 1);
                                        tempBoolean := true;
                                        // Removes duplicate elements in the leveled list one level above
                                        for b := 0 to Pred(LLec(subLevelList)) do
                                        if LLcontains(tempLevelList, LLelementbyindex(tempLevelList, b)) then
                                        LLremove(tempLevelList, LLelementbyindex(tempLevelList, b));
                                        // Sub-sublists don't need a percent chance none
                                        if ElementExists(tempLevelList, 'LVLD') then
                                        Remove(ElementBySignature(tempLevelList, 'LVLD'));
                                        end;
                                        end;
                                        end;
                                    end;
                                end;
                            end;
                            if not tempBoolean and not LLcontains(tempLevelList, subLevelList) then
                                addToLeveledList(tempLevelList, subLevelList, 1);
                        end else begin
                            if not LLcontains(tempLevelList, tempRecord) then
                                addToLeveledList(tempLevelList, tempRecord, 1);
                            // Blacklist used items
                            if not slContains(slBlackList, slTempObject[y]) then
                                slBlackList.Add(slTempObject[y]);
                        end;
                    end;
                    // Check if the leveled list contains a template for an enchanted list
                    { Debug } if debugMsg then
                        addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Check if the leveled list contains a template for an enchanted list');
                    for z := 0 to slEnchantedList.Count - 1 do
                    begin
                        for a := 0 to Pred(LLec(tempLevelList)) do
                        begin
                            tempelement := ObjectToElement(slEnchantedList.Objects[z]);
                            if ElementExists(LLelementbyindex(tempelement, 0), 'CNAM') then
                            begin
                                if EditorID(LinksTo(ElementBySignature(LLelementbyindex(tempelement, 0), 'CNAM'))) = EditorID(LLelementbyindex(subLevelList, b)) then
                                begin
                                    { Debug } if debugMsg then
                                        addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] LLreplace(' + EditorID(tempLevelList) + ', ' + EditorID(LLelementbyindex(subLevelList, b)) + ', ' + slEnchantedList[z] + ' );');
                                    if not LLcontains(tempLevelList, tempelement) then
                                        LLreplace(tempLevelList, LLelementbyindex(subLevelList, b), tempelement);
                                end;
                            end
                            else
                                if ElementExists(LLelementbyindex(tempelement, 0), 'TNAM') then
                                begin
                                    if EditorID(LinksTo(ElementBySignature(LLelementbyindex(tempelement, 0), 'TNAM'))) = EditorID(LLelementbyindex(subLevelList, b)) then
                                    begin
                                        { Debug } if debugMsg then
                                        addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] LLreplace(' + EditorID(tempLevelList) + ', ' + EditorID(LLelementbyindex(subLevelList, b)) + ', ' + slEnchantedList[z] + ' );');
                                        if not LLcontains(tempLevelList, tempelement) then
                                        LLreplace(tempLevelList, LLelementbyindex(subLevelList, b), tempelement);
                                    end;
                                end;
                        end;
                    end;
                    // Remove outfits with no primary vanilla BOD2 slots
                    { Debug } if debugMsg then
                        addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Check ' + EditorID(tempLevelList) + ' for primary vanilla BOD2 slots');
                    tempBoolean := false;
                    for z       := 0 to Pred(LLec(tempLevelList)) do
                    begin
                        // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] LLelementbyindex(tempLevelList, z) := '+EditorID(LLelementbyindex(tempLevelList, z)));
                        // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Signature(LLelementbyindex(tempLevelList, z)) := '+Signature(LLelementbyindex(tempLevelList, z)));
                        if (Signature(LLelementbyindex(tempLevelList, z)) = 'LVLI') then
                        begin
                            // Check sublist
                            { Debug } if debugMsg then
                                addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Check if ' + EditorID(tempLevelList) + ' sublist ' + EditorID(LLelementbyindex(tempLevelList, z)) + ' is a script sublist');
                            // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] if ContainsText(EditorID('+EditorID(LLelementbyindex(tempLevelList, z))+', ''BOD2'') then begin');
                            if ContainsText(EditorID(LLelementbyindex(tempLevelList, z)), 'BOD2') or ContainsText(EditorID(LLelementbyindex(tempLevelList, z)), 'Ench') then
                            begin
                                sl1.clear;
                                tempString    := Trim(StrPosCopy(EditorID(LLelementbyindex(tempLevelList, z)), ':', false));
                                tempString    := Trim(StrPosCopy(tempString, ')', true));
                                sl1.CommaText := tempString;
                                sl2.clear;
                                sl2.CommaText := '30, 32, 33, 37, 39'; // 30 - Head, 32 - Body, 33 - Gauntlers, 37 - Feet, 39 - Shield
                                // This 'if' prevents tempLevelList deletion if the BOD2 list doesn't generate correctly
                                if (sl1.Count > 0) then
                                begin
                                    for a := 0 to sl1.Count - 1 do
                                        if slContains(sl2, sl1[a]) then
                                        tempBoolean := true;
                                end else begin
                                    addMessage('[ERROR] ' + EditorID(LLelementbyindex(tempLevelList, z)) + ' expected BOD2 did not generate correctly - [AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation]');
                                    tempBoolean := true;
                                end;
                            end;
                        end else begin
                            // Check normal item
                            { Debug } if debugMsg then
                                addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Check ' + EditorID(tempLevelList) + ' for a normal item');
                            sl1.clear;
                            slGetFlagValues(LLelementbyindex(tempLevelList, z), sl1, false);
                            sl2.CommaText := '30, 32, 33, 37, 39'; // 30 - Head, 32 - Body, 33 - Gauntlers, 37 - Feet, 39 - Shield
                            // This 'if' prevents tempLevelList deletion if the BOD2 list doesn't generate correctly
                            if (sl1.Count > 0) then
                            begin
                                for a := 0 to sl1.Count - 1 do
                                    if slContains(sl2, sl1[a]) then
                                        tempBoolean := true;
                            end else begin
                                addMessage('[ERROR] ' + EditorID(LLelementbyindex(tempLevelList, z)) + ' expected BOD2 did not generate correctly - [AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation]');
                                tempBoolean := true;
                            end;
                        end;
                    end;
                    if not tempBoolean then
                    begin
                        sl1.clear;
                        { Debug } if debugMsg then
                            for z := 0 to Pred(LLec(tempLevelList)) do
                                sl1.Add(EditorID(LLelementbyindex(tempLevelList, z)));
                        { Debug } if debugMsg then
                            msgList('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] ' + EditorID(tempLevelList) + ' := ', sl1, '');
                        { Debug } if debugMsg then
                            addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] Remove(' + EditorID(tempLevelList) + ' )');
                        Remove(tempLevelList);
                        Continue;
                    end else begin
                        { Debug } if debugMsg then
                            addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] ' + EditorID(tempLevelList) + ' does contain primary vanilla BOD2 slots');
                    end;
                end;
                
                // End debugMsg section
                /// /////////////////////////////////////////////////////////////////// ASSEMBLE OTFT FROM VANILLA ENTRIES - OUTFIT VARIATIONS /////////////////////////////////////////////////////////////////////////////
                // Begin debugMsg section
                
                if Assigned(tempLevelList) then
                begin
                    // If an outfit Master list requires additional BOD2 slots, make a variant of tempLevelList
                    for z := 0 to Pred(ElementCount(ElementBySignature(OTFTcopy, 'INAM'))) do
                    begin
                        sl1.clear;
                        sl2.clear;
                        tempRecord := WinningOverride(LinksTo(elementbyindex(ElementByPath(OTFTcopy, 'INAM'), z)));
                        // Get a list of expected BOD2 slots
                        { Debug } if debugMsg then
                            addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Variations] Get a list of expected BOD2 slots for ' + EditorID(tempRecord));
                        if (Signature(tempRecord) = 'LVLI') then
                        begin
                            for a := 0 to Pred(LLec(tempRecord)) do
                            begin
                                if (Signature(LLelementbyindex(tempRecord, a)) = 'LVLI') then
                                begin
                                    sl2.addObject(EditorID(LLelementbyindex(tempRecord, z)), LLelementbyindex(tempRecord, z));
                                end else begin
                                    slGetFlagValues(LLelementbyindex(tempRecord, a), sl1, false);
                                end;
                            end;
                            // This is a recursive check for nested leveled lists
                            { Debug } if debugMsg then
                                addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Variations] This is a recursive check for nested leveled lists');
                            { Debug } if debugMsg then
                                addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Variations] sl2.Count := ' + IntToStr(sl2.Count));
                            if (sl2.Count > 0) then
                            begin
                                while (sl2.Count > 0) do
                                begin
                                    tempelement := ObjectToElement(sl2.Objects[0]);
                                    if (LLec(tempelement) = 0) then
                                    begin
                                        sl2.Delete(0);
                                        Continue;
                                    end;
                                    // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Variations] for a := 0 to '+IntToStr(Pred(LLec(tempElement)))+' do begin');
                                    for a := 0 to Pred(LLec(tempelement)) do
                                    begin
                                        // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Variations] if ('+Signature(LLelementbyindex(tempElement, a))+' = ''LVLI'') then begin');
                                        if (Signature(LLelementbyindex(tempelement, a)) = 'LVLI') then
                                        begin
                                        // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Variations] if not slContains(sl1, '+EditorID(LLelementbyindex(tempElement, a))+' ) then');
                                        if not slContains(sl1, EditorID(LLelementbyindex(tempelement, a))) then
                                        begin
                                        // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Variations] sl2.Add('+EditorID(LLelementbyindex(tempElement, a))+' );');
                                        sl2.addObject(EditorID(LLelementbyindex(tempelement, a)), LLelementbyindex(tempelement, a));
                                        end;
                                        end else begin
                                        slGetFlagValues(LLelementbyindex(tempelement, a), sl1, false);
                                        end;
                                    end;
                                    sl2.Delete(0);
                                    // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Variations] sl2.Delete('+sl2[0]+' )');
                                end;
                            end;
                        end else begin
                            sl1.clear;
                            slGetFlagValues(tempRecord, sl1, false);
                        end;
                        // Check to see if the outfit contains any item or sublist covering these BOD2 slots
                        { Debug } if debugMsg then
                            addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Variations] Check to see if the outfit contains any item or sublist covering these BOD2 slots');
                        if (sl1.Count > 0) then
                        begin
                            tempBoolean := false;
                            for z       := 0 to Pred(LLec(tempLevelList)) do
                            begin
                                if (Signature(LLelementbyindex(tempLevelList, z)) = 'LVLI') then
                                begin
                                    // Check sublist
                                    { Debug } if debugMsg then
                                        addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Variations] Check if ' + EditorID(tempLevelList) + ' sublist ' + EditorID(LLelementbyindex(tempLevelList, z)) + ' is a script sublist');
                                    if ContainsText(EditorID(LLelementbyindex(tempLevelList, z)), 'BOD2') then
                                    begin
                                        sl2.clear;
                                        tempString    := Trim(StrPosCopy(EditorID(LLelementbyindex(tempLevelList, z)), ':', false));
                                        tempString    := Trim(StrPosCopy(tempString, ')', true));
                                        sl2.CommaText := tempString;
                                        // This 'if' prevents tempLevelList deletion if the BOD2 list doesn't generate correctly
                                        if (sl1.Count > 0) then
                                        begin
                                        for a := 0 to sl1.Count - 1 do
                                        if slContains(sl2, sl1[a]) then
                                        tempBoolean := true;
                                        end else begin
                                        addMessage('[ERROR] ' + EditorID(tempRecord) + ' expected BOD2 did not generate correctly - [AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Variations]');
                                        tempBoolean := true;
                                        end;
                                        { Debug } if debugMsg then
                                        msgList('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Variations] Check ' + EditorID(LLelementbyindex(tempLevelList, z)) + ' sublist for ', sl1, ' := ' + BoolToStr(tempBoolean));
                                        // Check enchanted list
                                        { Debug } if debugMsg then
                                        addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Variations] Check if ' + EditorID(LLelementbyindex(tempLevelList, z)) + ' is an enchanted list');
                                    end;
                                end else begin
                                    // Check normal item
                                    { Debug } if debugMsg then
                                        addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Variations] Check normal item');
                                    sl2.clear;
                                    slGetFlagValues(LLelementbyindex(tempLevelList, z), sl2, false);
                                    { Debug } if debugMsg then
                                        msgList('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Variations] Checking for ' + EditorID(tempRecord) + ' BOD2 sl1 := ', sl1, '');
                                    { Debug } if debugMsg then
                                        msgList('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Variations] Checking for ' + EditorID(LLelementbyindex(tempLevelList, z)) + ' BOD2 sl2 := ', sl2, '');
                                    // This 'if' prevents tempLevelList deletion if the BOD2 list doesn't generate correctly
                                    if (sl1.Count > 0) then
                                    begin
                                        for a := 0 to sl1.Count - 1 do
                                        if slContains(sl2, sl1[a]) then
                                        tempBoolean := true;
                                    end else begin
                                        addMessage('[ERROR] ' + EditorID(tempRecord) + ' expected BOD2 did not generate correctly - [AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Variations]');
                                        tempBoolean := true;
                                    end;
                                end;
                            end;
                            // If the generated outfit does not cover all the BOD2 slots the master outfit contains, create a copy and use that instead
                            // Example: Leather outfits often generate with only a cuirass.
                            // In this case, if an outfit consists of LItemBanditHelmet, LItemBanditCuirass, and LItemBanditBoots (a common setup)
                            // a variant of the leveled list with just the leather cuirass would generate containing the leather cuirass, LItemBanditHelmet, and LItemBanditBoots
                            if not tempBoolean then
                            begin
                                // {Debug} if debugMsg then addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Variations] if StrEndsWith('+EditorID(tempLevelList)+', '+EditorID(OTFTcopy)+' ) then begin');
                                if StrEndsWith(EditorID(tempLevelList), EditorID(OTFTcopy)) then
                                begin
                                    subLevelList := tempLevelList
                                end else begin
                                    subLevelList := MainRecordByEditorID(GroupBySignature(aPlugin, 'LVLI'), EditorID(tempLevelList) + '_' + EditorID(OTFTcopy));
                                end;
                                if not Assigned(subLevelList) then
                                begin
                                    subLevelList := wbCopyElementToFile(tempLevelList, aPlugin, true, true);
                                    SetElementEditValues(subLevelList, 'EDID', EditorID(tempLevelList) + '_' + EditorID(OTFTcopy));
                                end;
                                if Assigned(subLevelList) then
                                    tempLevelList := subLevelList;
                                if not LLcontains(tempLevelList, tempRecord) then
                                    addToLeveledList(tempLevelList, tempRecord, 1);
                            end;
                        end;
                    end;
                    // Add tempLevelList to masterLevelList if it is not already present
                    { Debug } if debugMsg then
                        addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] if not LLcontains(' + EditorID(masterLevelList) + ', ' + EditorID(tempLevelList) + ' ) := ' + BoolToStr(LLcontains(masterLevelList, tempLevelList)) + ' then begin');
                    if not LLcontains(masterLevelList, tempLevelList) then
                    begin
                        { Debug } if debugMsg then
                            addMessage('[AddToOutfitAuto] [Assemble OTFT From Vanilla Entries - Outfit Generation] addToLeveledList(' + EditorID(masterLevelList) + ', ' + EditorID(tempLevelList) + ', 1);');
                        addToLeveledList(masterLevelList, tempLevelList, 1);
                    end;
                end;
                // Blacklist used items
                if not slContains(slBlackList, slItem[x]) then
                    slBlackList.Add(slItem[x]);
            end;
        end;
        
        // End debugMsg Section
        /// /////////////////////////////////////////////////////////////////// SPECIFIC OTFT TYPES - PRE-CHECK ////////////////////////////////////////////////////////////////////////////////
        // Begin debugMsg Section
        
        // Checks for integer-keyword pairs (e.g. Shield20 becomes 20=Shield)
        // This checks each OTFT item for an integer-keyword pair (e.g. Shield20 becomes 20=Shield)
        slTemp.clear;
        slpair.clear;
        slTemp.CommaText := 'Bracers, Helmet, Hood, Crown, Shield, Buckler, Cuirass, Greaves, Boots, Gloves, Gauntlets';
        tempBoolean      := false;
        for x            := 0 to Pred(ElementCount(ElementByPath(OTFTcopy, 'INAM'))) do
        begin
            tempRecord := LinksTo(elementbyindex(ElementByPath(OTFTcopy, 'INAM'), x)); { Debug }
            if debugMsg then
                addMessage('[AddToOutfitAuto] [Pre-Check] tempRecord := ' + EditorID(tempRecord));
            { Debug } if debugMsg then
                addMessage('[AddToOutfitAuto] [Pre-Check] if Signature(' + EditorID(tempRecord) + ' ) := ' + Signature(tempRecord) + ' = ''LVLI'' then begin');
            if (Signature(tempRecord) = 'LVLI') then
            begin { Debug }
                if debugMsg then
                    addMessage('[AddToOutfitAuto] [Pre-Check] if (IntWithinStr(EditorID(tempRecord)) := ' + IntToStr(IntWithinStr(EditorID(tempRecord))) + ' ) <> -1) then begin');
                if (IntWithinStr(EditorID(tempRecord)) <> -1) then
                begin
                    for y := 0 to slTemp.Count - 1 do
                    begin { Debug }
                        if debugMsg then
                            addMessage('[AddToOutfitAuto] [Pre-Check] if ContainsText(' + EditorID(tempRecord) + ', ' + slTemp[y] + ' ) then begin');
                        if ContainsText(EditorID(tempRecord), slTemp[y]) then
                        begin
                            for z := 0 to slpair.Count - 1 do
                                if slpair.Names[z] = slTemp[y] then
                                    tempBoolean := true;
                            if not tempBoolean then
                            begin
                                slpair.Add(slAddValue(IntToStr(IntWithinStr(EditorID(tempRecord))), slTemp[y]));
                                { Debug } if debugMsg then
                                    msgList('[AddToOutfitAuto] [Pre-Check] slpair := ', slpair, '');
                            end;
                        end;
                    end;
                end;
            end;
        end;
        // This checks the OTFT EditorID for an integer-keyword pair
        if (IntWithinStr(EditorID(OTFTcopy)) <> -1) then
        begin
            for y := 0 to slTemp.Count - 1 do
            begin { Debug }
                if debugMsg then
                    addMessage('[AddToOutfitAuto] [Pre-Check] if (IntWithinStr(EditorID(OTFTcopy) := ' + IntToStr(IntWithinStr(EditorID(OTFTcopy))) + ' <> -1) then begin');
                if (IntWithinStr(EditorID(OTFTcopy)) <> -1) then
                begin { Debug }
                    if debugMsg then
                        addMessage('[AddToOutfitAuto] [Pre-Check] if ContainsText(' + EditorID(OTFTcopy) + ', ' + slTemp[y] + ' ) then begin');
                    if ContainsText(EditorID(OTFTcopy), slTemp[y]) then
                    begin
                        for z := 0 to slpair.Count - 1 do
                            if slpair.Names[z] = slTemp[y] then
                                tempBoolean := true;
                        if not tempBoolean then
                        begin
                            slpair.Add(slAddValue(IntToStr(IntWithinStr(EditorID(OTFTcopy))), slTemp[y]));
                            { Debug } if debugMsg then
                                msgList('[AddToOutfitAuto] [Pre-Check] slpair := ', slpair, '');
                        end;
                    end;
                end;
            end;
        end;
        /// /////////////////////////////////////////////////////////////////// SPECIFIC OTFT TYPES - INTEGER ////////////////////////////////////////////////////////////////////////////////
        if (slpair.Count > 0) then
        begin { Debug }
            if debugMsg then
                msgList('[AddToOutfitAuto] [Integer] slpair := ', slpair, '');
            // This is checking the input level list for keywords similiar to the identified keyword
            // This is ghetto fuzzy logic.  Example: If the pre-check identifies 'Gauntlets' then this
            // section would check the input record for entries containing 'Gauntlets, Gloves';
            tempBoolean := false;
            { Debug } if debugMsg then
                msgList('[AddToOutfitAuto] [Integer] slpair := ', slpair, '');
            for x := 0 to slpair.Count - 1 do
            begin
                { Debug } if debugMsg then
                    msgList('[AddToOutfitAuto] [Integer] slFuzzyItem(' + slpair.Names[x] + ', ', slTemp, ' )');
                // Check for inputRecord for all keywords related to the keyword detected in the OTFT 'EditorID' or 'INAM' items
                slTemp.clear;
                slFuzzyItem(slpair.Names[x], slTemp); { Debug }
                if debugMsg and (x = 0) then
                    msgList('[AddToOutfitAuto] [Integer] slTemp := ', slTemp, '');
                tempLevelList := nil;
                for y         := 0 to Pred(LLec(inputRecord)) do
                begin
                    tempRecord := LLelementbyindex(inputRecord, y); { Debug }
                    if debugMsg then
                        addMessage('[AddToOutfitAuto] [Integer] tempRecord := ' + EditorID(tempRecord));
                    for z := 0 to slTemp.Count - 1 do
                    begin { Debug }
                        if debugMsg then
                            addMessage('[AddToOutfitAuto] [Integer] if ContainsText(' + EditorID(tempRecord) + ', ' + slTemp[z] + ' ) or ContainsText(' + full(tempRecord) + ', ' + slTemp[z] + ' ) or HasKeyword(' + EditorID(tempRecord) + ', Armor' + slTemp[z] + ' ) or HasKeyword(' + EditorID(tempRecord) + ', Clothing' + slTemp[z] + ' ) then begin');
                        if ContainsText(EditorID(tempRecord), slTemp[z]) or ContainsText(FULL(tempRecord), slTemp[z]) or HasKeyword(tempRecord, 'Armor' + slTemp[z]) or HasKeyword(tempRecord, 'Clothing' + slTemp[z]) then
                        begin
                            // If more than one integer-keyword pair is detected we need to account for both (e.g. Shield20Helmet50
                            tempString     := nil;
                            for a          := 0 to slpair.Count - 1 do
                                tempString := tempString + slpair.Names[a] + slpair.ValueFromIndex[a]; { Debug }
                            if debugMsg then
                                addMessage('[AddToOutfitAuto] [Integer] tempString := ' + tempString);
                            // Check if aPlugin already has an identically named variant of inputRecord
                            // The result needs to be true for any combination of slpair entries
                            // Example: Either Gauntlets50Helmet50 or Helmet50Gauntlets50 will return true
                            if not Assigned(tempLevelList) then
                            begin
                                for a := 0 to Pred(ElementCount(GroupBySignature(aPlugin, 'LVLI'))) do
                                begin
                                    tempInteger := 0;
                                    for b       := 0 to slpair.Count - 1 do
                                        if ContainsText(EditorID(elementbyindex(GroupBySignature(aPlugin, 'LVLI'), a)), EditorID(inputRecord)) and ContainsText(EditorID(elementbyindex(GroupBySignature(aPlugin, 'LVLI'), a)), slpair.Names[b] + slpair.ValueFromIndex[b]) then
                                        Inc(tempInteger);
                                    if (tempInteger = slpair.Count) then
                                    begin { Debug }
                                        if debugMsg then
                                        addMessage('[AddToOutfitAuto] [Integer] Pre-existing variant of inputRecord detected: ' + EditorID(elementbyindex(GroupBySignature(aPlugin, 'LVLI'), a)));
                                        tempLevelList := elementbyindex(GroupBySignature(aPlugin, 'LVLI'), a);
                                        break;
                                    end;
                                end;
                            end
                            else
                                if debugMsg then
                                    addMessage('[AddToOutfitAuto] [Integer] tempLevelList already assigned');
                            // Create a new level list if a pre-existing one is not detected; This is a variant of inputRecord, NOT the sublist
                            if not Assigned(tempLevelList) then
                            begin { Debug }
                                if debugMsg then
                                    addMessage('[AddToOutfitAuto] [Integer] ' + EditorID(inputRecord) + ' variant not detected; Creating ' + EditorID(inputRecord) + '_' + tempString + ' level list');
                                tempLevelList := wbCopyElementToFile(inputRecord, aPlugin, true, true);
                                SetElementEditValues(tempLevelList, 'EDID', EditorID(inputRecord) + '_' + tempString);
                            end;
                            // Check if aPlugin already has an identically named sublist
                            { Debug } if debugMsg then
                                addMessage('[AddToOutfitAuto] [Integer] Checking for pre-existing ' + (EditorID(inputRecord) + '_Sublist_' + slpair.Names[x] + slpair.ValueFromIndex[x]) + ' subLevelList');
                            subLevelList := MainRecordByEditorID(GroupBySignature(aPlugin, 'LVLI'), (EditorID(inputRecord) + '_SubList_' + slpair.Names[x] + slpair.ValueFromIndex[x]));
                            // Add subLevelList to tempLevelList if not already added
                            if Assigned(subLevelList) then
                            begin
                                { Debug } if debugMsg then
                                    addMessage('[AddToOutfitAuto] [Integer] if not LLcontains(' + EditorID(tempLevelList) + ', ' + EditorID(subLevelList) + ' ) := ' + BoolToStr(LLcontains(tempLevelList, subLevelList)) + ' then begin');
                                if not LLcontains(tempLevelList, subLevelList) then
                                begin
                                    { Debug } if debugMsg then
                                        addMessage('[AddToOutfitAuto] [Integer] addToLeveledList(' + EditorID(tempLevelList) + ', ' + EditorID(subLevelList) + ', 1);');
                                    addToLeveledList(tempLevelList, subLevelList, 1);
                                end;
                            end;
                            // Create a new sub level list if a pre-existing one is not detected
                            if not Assigned(subLevelList) then
                            begin
                                slTemp.CommaText := '"Use All"';
                                subLevelList     := createLeveledList(aPlugin, (EditorID(inputRecord) + '_SubList_' + slpair.Names[x] + slpair.ValueFromIndex[x]), slTemp, (100 - StrToInt(slpair.ValueFromIndex[x])));
                                { Debug } if debugMsg then
                                    addMessage('[AddToOutfitAuto] [Integer] addToLeveledList(' + EditorID(subLevelList) + ', ' + EditorID(tempRecord) + ', 1);');
                                addToLeveledList(subLevelList, tempRecord, 1);
                            end;
                            if Assigned(subLevelList) then
                            begin
                                { Debug } if debugMsg then
                                    addMessage('[AddToOutfitAuto] [Integer] if not LLcontains(' + EditorID(tempLevelList) + ', ' + EditorID(subLevelList) + ' ) := ' + BoolToStr(LLcontains(tempLevelList, subLevelList)) + ' then begin');
                                if not LLcontains(tempLevelList, subLevelList) then
                                begin
                                    { Debug } if debugMsg then
                                        addMessage('[AddToOutfitAuto] [Integer] LLreplace(' + EditorID(tempLevelList) + ', ' + EditorID(tempRecord) + ', ' + EditorID(subLevelList) + ' );');
                                    LLreplace(tempLevelList, tempRecord, subLevelList);
                                end;
                            end;
                        end;
                    end;
                end;
            end;
            OTFTitem := RefreshList(OTFTcopy, 'INAM'); { Debug }
            if debugMsg then
                addMessage('[AddToOutfitAuto] [Integer] Refreshing ' + EditorID(OTFTcopy) + ' ''INAM'' Element');
            // Add the finished variant of the inputRecord level list to the OTFT
            if Assigned(tempLevelList) then
            begin
                { Debug } if debugMsg then
                    addMessage('[AddToOutfitAuto] [Integer] LLreplace(' + EditorID(masterLevelList) + ', ' + EditorID(tempLevelList) + ', 1);');
                { Debug } if debugMsg then
                    addMessage('[AddToOutfitAuto] [Integer] SetEditValue(' + GetEditValue(elementbyindex(ElementByPath(OTFTcopy, 'INAM'), 0)) + ', ' + ShortName(masterLevelList) + ');');
                LLreplace(masterLevelList, inputRecord, tempLevelList);
                SetEditValue(OTFTitem, ShortName(masterLevelList)); { Debug }
                if debugMsg then
                    addMessage('[AddToOutfitAuto] [Integer] SetEditValue(' + GetEditValue(OTFTitem) + ', ShortName(' + EditorID(tempLevelList) + ' ) := ' + ShortName(tempLevelList) + ' )');
            end
            else
                addMessage('[AddToOutfitAuto] [ERROR] tempLevelList output not generated for: ' + EditorID(OTFTcopy));
            /// /////////////////////////////////////////////////////////////////// SPECIFIC OTFT TYPES - NO/WITHOUT ////////////////////////////////////////////////////////////////////////////////
        end
        else
            if ContainsText(EditorID(OTFTcopy), 'No') or ContainsText(EditorID(OTFTcopy), 'without') then
            begin
                // Check for a keyword with the OTFT 'EDID'
                // Get a list of all keywords related to the keyword detected
                slTemp.CommaText := 'Mask, Bracers, Helmet, Hood, Crown, Shield, Buckler, Cuirass, Greaves, Boots, Gloves, Gauntlets';
                for x            := 0 to slTemp.Count - 1 do
                begin
                    if ContainsText(EditorID(OTFTcopy), slTemp[x]) then
                    begin
                        tempString := slTemp[x];
                        slFuzzyItem(slTemp[x], slTemp);
                        break;
                    end;
                end;
                // Checking GetElementEditValues, EditorID, and Keywords for relevant item types
                OTFTitem := RefreshList(OTFTcopy, 'INAM');
                { Debug } if debugMsg then
                    addMessage('[AddToOutfitAuto] [No/Without] No/Without OTFT detected');
                for y := 0 to Pred(LLec(inputRecord)) do
                begin
                    LLentry     := LLelementbyindex(inputRecord, y);
                    tempBoolean := false;
                    for z       := 0 to slTemp.Count - 1 do
                    begin
                        if ContainsText(EditorID(LLentry), slTemp[z]) then
                            tempBoolean := true;
                        if ContainsText(FULL(LLentry), slTemp[z]) then
                            tempBoolean := true;
                        if HasKeyword(LLentry, 'Armor' + slTemp[z]) or HasKeyword(LLentry, 'Clothing' + slTemp[z]) then
                            tempBoolean := true;
                    end;
                    if tempBoolean then
                    begin
                        tempInteger := y;
                        break;
                    end;
                end;
                if tempBoolean then
                begin
                    tempLevelList := wbCopyElementToFile(inputRecord, aPlugin, true, true);
                    SetElementEditValues(tempLevelList, 'EDID', EditorID(inputRecord) + '_No' + tempString);
                    Remove(elementbyindex(ElementByPath(inputRecord, 'Leveled List Entries'), tempInteger));
                    { Debug } if debugMsg then
                        addMessage('[AddToOutfitAuto] [No/Without] addToLeveledList(' + EditorID(masterLevelList) + ', ' + EditorID(tempLevelList) + ', 1);');
                    { Debug } if debugMsg then
                        addMessage('[AddToOutfitAuto] [No/Without] SetEditValue(' + GetEditValue(elementbyindex(ElementByPath(OTFTcopy, 'INAM'), 0)) + ', ' + ShortName(masterLevelList) + ');');
                    addToLeveledList(masterLevelList, tempLevelList, 1);
                    SetEditValue(OTFTitem, ShortName(masterLevelList));
                end else begin
                    { Debug } if debugMsg then
                        addMessage('[AddToOutfitAuto] [No/Without] SetEditValue(' + GetEditValue(elementbyindex(ElementByPath(OTFTcopy, 'INAM'), 0)) + ', ' + ShortName(masterLevelList) + ');');
                    SetEditValue(OTFTitem, ShortName(masterLevelList));
                end;
                /// /////////////////////////////////////////////////////////////////// SPECIFIC OTFT TYPES - SIMPLE ////////////////////////////////////////////////////////////////////////////////
            end
            else
                if ContainsText(EditorID(OTFTcopy), 'Simple') then
                begin
                    OTFTitem := RefreshList(OTFTcopy, 'INAM');
                    { Debug } if debugMsg then
                        addMessage('[AddToOutfitAuto] [Simple] Simple OTFT detected');
                    tempLevelList := wbCopyElementToFile(inputRecord, aPlugin, true, true);
                    SetElementEditValues(tempLevelList, 'EDID', EditorID(inputRecord) + '_Simple');
                    Remove(ElementByPath(tempLevelList, 'Leveled List Entries'));
                    Add(tempLevelList, 'Leveled List Entries', true);
                    //RemoveInvalidEntries(tempLevelList);
                    // Checking GetElementEditValues, EditorID, and Keywords for relevant item types
                    for y := 0 to Pred(LLec(inputRecord)) do
                    begin
                        LLentry          := LLelementbyindex(inputRecord, y);
                        slTemp.CommaText := 'Helm, Hood, Head, Boots, Shoes, Feet';
                        tempBoolean      := false;
                        for z            := 0 to slTemp.Count - 1 do
                        begin
                            if ContainsText(EditorID(LLentry), slTemp[z]) then
                                tempBoolean := true;
                            if ContainsText(FULL(LLentry), slTemp[z]) then
                                tempBoolean := true;
                            if HasKeyword(LLentry, 'Armor' + slTemp[z]) or HasKeyword(LLentry, 'Clothing' + slTemp[z]) then
                                tempBoolean := true;
                        end;
                        if tempBoolean then
                            addToLeveledList(tempLevelList, LLentry, 1);
                    end;
                end
                else
                    if ContainsText(EditorID(OTFTrecord), 'Bandit') then
                    begin
                        OTFTitem := RefreshList(OTFTcopy, 'INAM');
                        { Debug } if debugMsg then
                            addMessage('[AddToOutfitAuto] Bandit OTFT detected');
                        // Checking GetElementEditValues, EDID, and Keywords for relevant item types
                        for y := 0 to Pred(LLec(inputRecord)) do
                        begin
                            LLentry          := LLelementbyindex(inputRecord, y);
                            slTemp.CommaText := 'Gloves, Gauntlets, Hands';
                            tempBoolean      := false;
                            for z            := 0 to slTemp.Count - 1 do
                            begin
                                if ContainsText(EditorID(LLentry), slTemp[z]) then
                                    tempBoolean := true;
                                if ContainsText(FULL(LLentry), slTemp[z]) then
                                    tempBoolean := true;
                                if HasKeyword(LLentry, 'Armor' + slTemp[z]) or HasKeyword(LLentry, 'Clothing' + slTemp[z]) then
                                    tempBoolean := true;
                            end;
                            if tempBoolean then
                            begin
                                tempInteger := y;
                                break;
                            end;
                        end;
                        if tempBoolean then
                        begin
                            tempLevelList := wbCopyElementToFile(inputRecord, aPlugin, true, true);
                            SetElementEditValues(tempLevelList, 'EDID', EditorID(inputRecord) + '_Gauntlets50');
                            subLevelList := MainRecordByEditorID(GroupBySignature(aPlugin, 'LVLI'), EditorID(inputRecord) + '_SubList_Gauntlets50');
                            if not Assigned(subLevelList) then
                                slTemp.CommaText := '"Use All"';
                            subLevelList         := createLeveledList(aPlugin, EditorID(inputRecord) + '_SubList_Gauntlets50', slTemp, 50);
                            if not LLcontains(subLevelList, LLelementbyindex(inputRecord, tempInteger)) then
                            begin
                                { Debug } if debugMsg then
                                    addMessage('[AddToOutfitAuto] addToLeveledList(' + EditorID(subLevelList) + ', ' + EditorID(LLelementbyindex(inputRecord, tempInteger)) + ', 1);');
                                addToLeveledList(subLevelList, LLelementbyindex(inputRecord, tempInteger), 1);
                            end;
                            { Debug } if debugMsg then
                                addMessage('[AddToOutfitAuto] [Simple] addToLeveledList(' + EditorID(masterLevelList) + ', ' + EditorID(tempLevelList) + ', 1);');
                            { Debug } if debugMsg then
                                addMessage('[AddToOutfitAuto] [Simple] SetEditValue(' + GetEditValue(elementbyindex(ElementByPath(OTFTcopy, 'INAM'), 0)) + ', ' + ShortName(masterLevelList) + ');');
                            addToLeveledList(masterLevelList, tempLevelList, 1);
                            SetEditValue(OTFTitem, ShortName(masterLevelList));
                        end else begin
                            { Debug } if debugMsg then
                                addMessage('[AddToOutfitAuto] [Simple] SetEditValue(' + GetEditValue(elementbyindex(ElementByPath(OTFTcopy, 'INAM'), 0)) + ', ' + ShortName(masterLevelList) + ');');
                            SetEditValue(OTFTitem, ShortName(masterLevelList));
                        end;
                        /// /////////////////////////////////////////////////////////////////// SPECIFIC OTFT TYPES - OTHER ////////////////////////////////////////////////////////////////////////////////
                    end else begin
                        { Debug } if debugMsg then
                            addMessage('[AddToOutfitAuto] [Other] Other OTFT detected; SetEditValue(' + GetEditValue(elementbyindex(ElementByPath(OTFTcopy, 'INAM'), 0)) + ', ' + ShortName(masterLevelList) + ' );');
                        slTemp.CommaText := 'Shield, Buckler';
                        tempBoolean      := false;
                        for y            := 0 to Pred(ElementCount(ElementByPath(OTFTrecord, 'INAM'))) do
                        begin
                            for z := 0 to slTemp.Count - 1 do
                            begin
                                if ContainsText(EditorID(LLentry), slTemp[z]) then
                                    tempBoolean := true;
                                if ContainsText(full(LLentry), slTemp[z]) then
                                    tempBoolean := true;
                                if HasKeyword(LLentry, 'Armor' + slTemp[z]) or HasKeyword(LLentry, 'Clothing' + slTemp[z]) then
                                    tempBoolean := true;
                            end;
                            if tempBoolean then
                                tempInteger := y;
                        end;
                        OTFTitem := RefreshList(OTFTcopy, 'INAM');
                        if tempBoolean then
                        begin
                            tempBoolean := false;
                            for y       := 0 to Pred(LLec(inputRecord)) do
                            begin
                                tempRecord := LLelementbyindex(inputRecord, y);
                                for z      := 0 to slTemp.Count - 1 do
                                begin
                                    if ContainsText(EditorID(LLentry), slTemp[z]) then
                                        tempBoolean := true;
                                    if ContainsText(full(LLentry), slTemp[z]) then
                                        tempBoolean := true;
                                    if HasKeyword(LLentry, 'Armor' + slTemp[z]) or HasKeyword(LLentry, 'Clothing' + slTemp[z]) then
                                        tempBoolean := true;
                                end;
                            end;
                            if tempBoolean then
                            begin
                                tempLevelList := wbCopyElementToFile(inputRecord, aPlugin, true, true);
                                SetElementEditValues(tempLevelList, 'EDID', EditorID(inputRecord) + '_NoShield');
                                RemoveElement(elementbyindex(ElementByPath(tempLevelList, 'Leveled List Entries'), tempInteger));
                                { Debug } if debugMsg then
                                    addMessage('[AddToOutfitAuto] [Other] addToLeveledList(' + EditorID(masterLevelList) + ', ' + EditorID(tempLevelList) + ', 1);');
                                { Debug } if debugMsg then
                                    addMessage('[AddToOutfitAuto] [Other] SetEditValue(' + GetEditValue(elementbyindex(ElementByPath(OTFTcopy, 'INAM'), 0)) + ', ' + ShortName(masterLevelList) + ' );');
                                addToLeveledList(masterLevelList, tempLevelList, 1);
                                SetEditValue(OTFTitem, ShortName(masterLevelList));
                            end
                            else
                                SetEditValue(OTFTitem, ShortName(masterLevelList));
                        end
                        else
                            SetEditValue(OTFTitem, ShortName(masterLevelList));
                    end;
    end;

    // Finalize
    if Assigned(slEnchantedList) then
        slEnchantedList.Free;
    if Assigned(slStringList) then
        slStringList.Free;
    if Assigned(slTempObject) then
        slTempObject.Free;
    if Assigned(slBlackList) then
        slBlackList.Free;
    if Assigned(slLevelList) then
        slLevelList.Free;
    if Assigned(slOutfit) then
        slOutfit.Free;
    if Assigned(slItem) then
        slItem.Free;
    if Assigned(slTemp) then
        slTemp.Free;
    if Assigned(slpair) then
        slpair.Free;
    if Assigned(sl1) then
        sl1.Free;
    if Assigned(sl2) then
        sl2.Free;

    
    // End debugMsg Section
end;

// Find the type of Item
function ItemKeyword(inputRecord: IInterface): string;
var
    KWDAentries, KWDAkeyword: IInterface;
    slTemp                  : TStringList;
    i                       : integer;
begin
    // Begin debugMsg section
    
    // Initialize
	
	slTemp := TStringList.Create;

    // Function
    slTemp := IniPositions;
    { Debug } if debugMsg then
        for i := 0 to slTemp.Count - 1 do
            addMessage('[ItemKeyword] ' + slTemp[i]);
    KWDAentries := ElementByPath(inputRecord, 'KWDA'); { Debug }
    if debugMsg then
        addMessage('[ItemKeyword] Pred(ElementCount(KWDAentries)) :=' + IntToStr(Pred(ElementCount(KWDAentries))));
    for i := 0 to Pred(ElementCount(KWDAentries)) do
    begin { Debug }
        if debugMsg then
            addMessage('[ItemKeyword] LinksTo(elementbyindex(KWDAentries, i)) :=' + EditorID(LinksTo(elementbyindex(KWDAentries, i))));
        KWDAkeyword := LinksTo(elementbyindex(KWDAentries, i)); { Debug }
        if debugMsg then
            addMessage('[ItemKeyword] slTemp.Count-1 :=' + IntToStr(slTemp.Count - 1));
        for i := 0 to slTemp.Count - 1 do
        begin { Debug }
            if debugMsg then
                addMessage('[ItemKeyword] Result := ' + slTemp[i]);
            result := slTemp[i]; { Debug }
            if debugMsg then
                addMessage('[ItemKeyword] EditorID(KWDAkeyword) := ' + EditorID(KWDAkeyword) + ') = Result := ' + slTemp[i] + ') then Exit;');
            if (EditorID(KWDAkeyword) = result) then
            begin
                slTemp.Free;
                exit;
            end;
        end;
        result := nil;
    end;
    { Debug } if debugMsg then
        addMessage('[ItemKeyword] Result := nil; Exit;');

    // Finalize
    slTemp.Free;
    
    // End debugMsg section
end;

// Returns the BOD2 slot associated with the keyword
function KeywordToBOD2(aKeyword: string): string;
var
    slTemp  : TStringList;
    i       : integer;
begin
    // Begin debugMsg Section
    

    // Initialize
    slTemp := TStringList.Create;

    // Function
    { Debug } if debugMsg then
        addMessage('[KeywordToBOD2] KeywordToBOD2(' + aKeyword + ' );');
    slTemp.CommaText := 'ArmorHelmet, ClothingHead';
    if slContains(slTemp, aKeyword) then
        result       := '30';
    slTemp.CommaText := 'ArmorCuirass, ClothingBody';
    if slContains(slTemp, aKeyword) then
        result       := '32';
    slTemp.CommaText := 'ArmorGauntlets, ClothingHands';
    if slContains(slTemp, aKeyword) then
        result       := '33';
    slTemp.CommaText := 'ArmorBoots, ClothingFeet';
    if slContains(slTemp, aKeyword) then
        result       := '37';
    slTemp.CommaText := 'ArmorShield';
    if slContains(slTemp, aKeyword) then
        result       := '39';
    slTemp.CommaText := 'ClothingCirclet';
    if slContains(slTemp, aKeyword) then
        result       := '42';
    slTemp.CommaText := 'ClothingRing';
    if slContains(slTemp, aKeyword) then
        result       := '36';
    slTemp.CommaText := 'ClothingNecklace';
    if slContains(slTemp, aKeyword) then
        result := '35';
    { Debug } if debugMsg then
        addMessage('[KeywordToBOD2] Result := ' + result);

    // Finalize
    slTemp.Free;

    
    // End debugMsg Section
end;

// Checks to see if a string ends with an entered substring [mte functions]
function StrEndsWith(s1, s2: string): boolean;
var
    i, n1, n2: integer;
begin
    result := false;
    n1     := Length(s1);
    n2     := Length(s2);
    if (n1 < n2) then
        exit;
    result := (Copy(s1, n1 - n2 + 1, n2) = s2);
end;

// Appends a string to the end of the input string if it's not already there (from mte functions)
function AppendIfMissing(s1, s2: string): string;
begin
    result := s1;
    if not StrEndsWith(s1, s2) then
        result := s1 + s2;
end;

// This function will allow you to find the position of a substring in a string. If the iteration of the substring isn't found -1 is returned.
function ItPos(substr: string; str: string; it: integer): integer;
var
    i, found: integer;
begin
    // Begin debugMsg Section
    
    { Debug } if debugMsg then
        addMessage('[ItPos] substr := ' + substr);
    { Debug } if debugMsg then
        addMessage('[ItPos] str := ' + str);
    { Debug } if debugMsg then
        addMessage('[ItPos] it := ' + IntToStr(it));
    { Debug } if debugMsg then
        addMessage('[ItPos] Result := -1');
    result := -1;
    // addMessage('Called ItPos('+substr+', '+str+', '+IntToStr(it)+')');
    if it = 0 then
        exit;
    found := 0;
    for i := 1 to Length(str) do
    begin
        // addMessage('    Scanned substring: '+Copy(str, i, Length(substr)));
        if (Copy(str, i, Length(substr)) = substr) then
            Inc(found);
        if found = it then
        begin
            result := i;
            break;
        end;
    end;
    
    // End debugMsg Section
end;

// Gets a template from and enchanted record
function GetEnchTemplate(e: IInterface): IInterface;
begin
    if ElementExists(e, 'CNAM') then
    begin
        result := LinksTo(ElementBySignature(e, 'CNAM'));
        exit;
    end;
    if ElementExists(e, 'TNAM') then
    begin
        result := LinksTo(ElementBySignature(e, 'TNAM'));
        exit;
    end;
end;

// Checks if a string contains integers and then returns those integers
function IntWithinStr(aString: string): integer;
var
    i, x, tempInteger: integer;
    slTemp, slItem   : TStringList;
    tempString       : string;
begin
    // Begin debugMsg Section
    
    // Initialize
    if not Assigned(slTemp) then
        slTemp := TStringList.Create
    else
        slTemp.clear;
    if not Assigned(slItem) then
        slItem := TStringList.Create
    else
        slItem.clear;

    // Function
    slTemp.CommaText := '0, 1, 2, 3, 4, 5, 6, 7, 8, 9';
    for i            := 1 to Length(aString) do
    begin
        tempString := Copy(aString, i, 1);
        // {Debug} if debugMsg then addMessage('[IntWithinStr] tempString := '+tempString);
        for x := 0 to slTemp.Count - 1 do
        begin
            if (tempString = slTemp[x]) then
            begin { Debug }
                if debugMsg then
                    addMessage('[IntWithinStr] ' + tempString + ' = ' + slTemp[x]);
                if (slItem.Count = 0) then
                begin { Debug }
                    if debugMsg then
                        addMessage('[IntWithinStr] slItem.Count-1 = 0');
                    slItem.Add(tempString); { Debug }
                    if debugMsg then
                        addMessage('[IntWithinStr] slItem.Add(' + tempString + ' );');
                    tempInteger := i; { Debug }
                    if debugMsg then
                        addMessage('[IntWithinStr] tempInteger := ' + IntToStr(tempInteger));
                end else begin { Debug }
                    if debugMsg then
                        addMessage('[IntWithinStr] slItem.Count-1 <> 0');
                    { Debug } if debugMsg then
                        addMessage('[IntWithinStr] if not (' + IntToStr(i) + ' - ' + IntToStr(tempInteger) + ' > 1) then begin');
                    if not(i - tempInteger > 1) then
                    begin { Debug }
                        if debugMsg then
                            addMessage('[IntWithinStr] slItem.Add(' + tempString + ' );');
                        slItem.Add(tempString); { Debug }
                        if debugMsg then
                            addMessage('[IntWithinStr] if not ' + IntToStr(i) + ' - ' + IntToStr(tempInteger) + ' > 1) then begin');
                        tempInteger := i; { Debug }
                        if debugMsg then
                            addMessage('[IntWithinStr] tempInteger := ' + IntToStr(i));
                    end;
                end;
            end;
        end;
    end;
    { Debug } if debugMsg then
        addMessage('[IntWithinStr] if not slItem.Count := ' + IntToStr(slItem.Count) + ' = 0 then begin');
    tempString := nil;
    if not(slItem.Count = 0) then
    begin
        for i := 0 to slItem.Count - 1 do
        begin
            { Debug } if debugMsg then
                addMessage('[IntWithinStr] tempString := ' + tempString + ' + ' + slItem[i]);
            tempString := tempString + slItem[i];
        end;
        if (Length(tempString) > 0) then
            result := StrToInt(tempString);
        { Debug } if debugMsg then
            addMessage('[IntWithinStr] Result := ' + IntToStr(result));
    end
    else
        result := -1;

    // Finalize
    slTemp.Free;
    slItem.Free;
    
    // End debugMsg Section
end;

// Finds if StringList contains substring
function StrWithinSL(s: string; aList: TStringList): boolean;
var
    i       : integer;
begin
    // Begin debugMsg section
    

    { Debug } if debugMsg then
        addMessage('[StrWithinSL] s := ' + s);
    result := false;
    for i  := 0 to aList.Count - 1 do
    begin
        if ContainsText(aList[i], s) then
        begin
            result := true;
            break;
        end;
    end;

    
    // End debugMsg section
end;

// Finds if StringList contains substring
function ContainsTextSL(aList, bList: TStringList): boolean;
var
    i       : integer;
begin
    // Begin debugMsg section
    

    { Debug } if debugMsg then
        addMessage('[ContainsTextSL] s := ' + s);
    result := false;
    for i  := 0 to aList.Count - 1 do
    begin
        if StrWithinSL(aList[i], bList) then
        begin
            result := true;
            exit
        end;
    end;

    
    // End debugMsg section
end;

// Finds if StringList contains substring
function SLWithinStr(s: string; aList: TStringList): boolean;
var
    i       : integer;
begin
    // Begin debugMsg section
    

    { Debug } if debugMsg then
        addMessage('[SLWithinStr] s := ' + s);
    result := false;
    for i  := 0 to aList.Count - 1 do
    begin
        if ContainsText(s, aList[i]) then
        begin
            result := true;
            break;
        end;
    end;

    
    // End debugMsg section
end;

// Fills a TStringList with 'true' flag values; Boolean controls if list gets just numbers or the whole element name
procedure slGetFlagValues(e: IInterface; aList: TStringList; aBoolean: boolean);
var
    tempString, BinaryList: string;
    startTime, stopTime   : TDateTime;
    slTemp                : TStringList;
    i                     : integer;
begin
    // Initialize
    
    startTime := Time;
    if not Assigned(slTemp) then
        slTemp := TStringList.Create
    else
        slTemp.clear;

    // Function
    if (Signature(e) = 'ARMO') then
    begin
        { Debug } if debugMsg then
            msgList('[slGetFlagValues] slGetFlagValues(' + EditorID(e) + ', ', aList, ', ' + BoolToStr(aBoolean));
        slTemp.CommaText := FlagValues(ElementByPath(ElementBySignature(e, GetElementType(e)), 'First Person Flags'));
        { Debug } if debugMsg then
            msgList('[slGetFlagValues] FlagValues := ', slTemp, '');
        BinaryList := GetEditValue(ElementByPath(ElementBySignature(e, GetElementType(e)), 'First Person Flags'));
        { Debug } if debugMsg then
            addMessage('[slGetFlagValues] BinaryList := ' + BinaryList);
        if aBoolean then
        begin
            for i := 1 to Length(BinaryList) do
            begin
                if (Copy(BinaryList, i, 1) = '1') then
                begin
                    if (i + 2 <= slTemp.Count - 1) then
                    begin
                        tempString := slTemp[3 * (i - 1)] + ' ' + slTemp[3 * (i - 1) + 1] + ' ' + slTemp[3 * (i - 1) + 2];
                        if not slContains(aList, tempString) then
                            aList.Add(tempString);
                    end;
                end;
            end;
        end else begin
            for i := 1 to Length(BinaryList) do
            begin
                if (Copy(BinaryList, i, 1) = '1') then
                begin
                    if not slContains(aList, slTemp[3 * (i - 1)]) then
                    begin
                        { Debug } if debugMsg then
                            addMessage('[slGetFlagValues] aList.Add(' + slTemp[3 * (i - 1)] + ' );');
                        aList.Add(slTemp[3 * (i - 1)]);
                    end;
                end;
            end;
        end;
    end
    else
        if (Signature(e) = 'LVLI') then
        begin
            { Debug } if debugMsg then
                msgList('[slGetFlagValues] slGetFlagValues(' + EditorID(e) + ', ', aList, ', ' + BoolToStr(aBoolean));
            sl1.CommaText := '"Calculate from all levels <= player''s level", "Calculate for each item in count", "Use All", "Special Loot"';
            { Debug } if debugMsg then
                msgList('[slGetFlagValues] FlagValues := ', slTemp, '');
        end else begin
            aList.Add(Signature(e));
            slTemp.Free;
            exit;
        end;

    // Finalize
    slTemp.Free;
    stopTime := Time;
    if ProcessTime then
        addProcessTime('slGetFlagValues', TimeBtwn(startTime, stopTime));
    
end;

// Set Flag Values based on input string list
procedure slSetFlagValues(e: IInterface; aList: TStringList; aPlugin: IInterface);
var
    tempString, BinaryList: string;
    slTemp, sl1           : TStringList;
    tempRecord            : IInterface;
    i                     : integer;
begin
    // Begin debugMsg section
    

    // Initialize
    if not Assigned(slTemp) then
        slTemp := TStringList.Create
    else
        slTemp.clear;
    if not Assigned(sl1) then
        sl1 := TStringList.Create
    else
        sl1.clear;

    // Function
    { Debug } if debugMsg then
        msgList('[slSetFlagValues] slSetFlagValues(' + EditorID(e) + ', ', aList, ' )');
    if (Signature(e) = 'ARMO') then
    begin
        slTemp.CommaText := FlagValues(ElementByPath(ElementBySignature(e, GetElementType(e)), 'First Person Flags'));
        { Debug } if debugMsg then
            msgList('[slSetFlagValues] FlagValues := ', slTemp, '');
        BinaryList := GetEditValue(ElementByPath(ElementBySignature(e, GetElementType(e)), 'First Person Flags'));
        { Debug } if debugMsg then
            addMessage('[slSetFlagValues] BinaryList := ' + BinaryList);
        for i := 0 to slTemp.Count - 1 do
        begin
            // {Debug} if debugMsg then addMessage('[slSetFlagValues] if ('+IntToStr(i+2)+' <= '+IntToStr(slTemp.Count-1)+' ) then begin');
            if (3 * (i) + 2 <= slTemp.Count - 1) then
            begin
                tempString := slTemp[3 * (i)] + ' ' + slTemp[3 * (i) + 1] + ' ' + slTemp[3 * (i) + 2];
                if not slContains(sl1, tempString) then
                    sl1.Add(tempString);
                i := i + 3;
            end;
        end;
        { Debug } if debugMsg then
            msgList('[slSetFlagValues] sl1 := ', sl1, '');
        slTemp.clear;
        tempString := nil;
        for i      := 0 to sl1.Count - 1 do
        begin
            if slContains(aList, sl1[i]) then
            begin
                tempString := tempString + '1';
            end else begin
                tempString := tempString + '0';
            end;
        end;
        { Debug } if debugMsg then
            addMessage('[slSetFlagValues] New BinaryList := ' + tempString);
        if ContainsText(tempString, '1') then
            SetEditValue(ElementByPath(ElementBySignature(e, GetElementType(e)), 'First Person Flags'), Copy(tempString, 0, rPos(tempString, '1')));
    end
    else
        if (Signature(e) = 'LVLI') then
        begin
            // Make a copy of the list
            tempRecord := MainRecordByEditorID(GroupBySignature(aPlugin, 'LVLI'), EditorID(e));
            if not Assigned(tempRecord) then
            begin

                tempRecord := wbCopyElementToFile(e, aPlugin, false, true);
            end;

            // Assemble and assign new binary list
            sl1.CommaText := '"Calculate from all levels <= player''s level", "Calculate for each item in count", "Use All", "Special Loot"';
            { Debug } if debugMsg then
                msgList('[slGetFlagValues] FlagValues := ', sl1, '');
            { Debug } if debugMsg then
                msgList('[slSetFlagValues] sl1 := ', sl1, '');
            slTemp.clear;
            tempString := nil;
            for i      := 0 to sl1.Count - 1 do
            begin
                if slContains(aList, sl1[i]) then
                begin
                    tempString := tempString + '1';
                end else begin
                    tempString := tempString + '0';
                end;
            end;
            { Debug } if debugMsg then
                addMessage('[slSetFlagValues] New BinaryList := ' + Copy(tempString, 0, rPos(tempString, '1')));
            if ContainsText(tempString, '1') then
                SetEditValue(ElementBySignature(tempRecord, 'LVLF'), Copy(tempString, 0, rPos(tempString, '1')));
        end else begin
            aList.Add(Signature(e));
            slTemp.Free;
            exit;
        end;

    // Finalize
    slTemp.Free;
    sl1.Free;

    
    // End debugMsg section
end;

// Copies string preceding [TRUE] or following [FALSE] as string
function StrPosCopy(inputString: string; findString: string; inputBoolean: boolean): string;
begin
    // Begin debugMsg Section
    
    { Debug } if debugMsg then
        addMessage('[StrPosCopy] if ContainsText(inputString := ' + inputString + ', findString := ' + findString + ') then begin');
    if ContainsText(inputString, findString) then
    begin
        { Debug } if debugMsg then
            addMessage('[StrPosCopy] if not inputBoolean := ' + BoolToStr(inputBoolean) + ' then');
        if not inputBoolean then
        begin
            result := Copy(inputString, (ItPos(findString, inputString, 1) + Length(findString)), (Length(inputString) - ItPos(findString, inputString, 1)));
            { Debug } if debugMsg then
                addMessage('[StrPosCopy] Copy(inputString := ' + inputString + ', (ItPos(findString := ' + findString + ' inputString := ' + inputString + ', 1)+length(findString) := ' + IntToStr(Length(findString)) + ') := ' + IntToStr(ItPos(findString, inputString, 1)) + ', (length(inputString) := ' + IntToStr(Length(inputString)) + ' - ItPos(findstring, inputString, 1)) := ' + IntToStr(ItPos(findString, inputString, 1)) + ')');
            { Debug } if debugMsg then
                addMessage('[StrPosCopy] Result := ' + Copy(inputString, (ItPos(findString, inputString, 1) + Length(findString)), (Length(inputString) - ItPos(findString, inputString, 1))));
        end;
        { Debug } if debugMsg then
            addMessage('[StrPosCopy] if inputBoolean := ' + BoolToStr(inputBoolean) + ' then');
        if inputBoolean then
        begin
            result := Copy(inputString, 0, (ItPos(findString, inputString, 1) - 1));
            { Debug } if debugMsg then
                addMessage('[StrPosCopy] Copy(inputString := ' + inputString + ', 0, (ItPos(findString, inputString, 1)-1 := ' + IntToStr(ItPos(findString, inputString, 1) - 1) + '));');
            { Debug } if debugMsg then
                addMessage('[StrPosCopy] Result := ' + Copy(inputString, 0, (ItPos(findString, inputString, 1) - 1)));
        end;
    end
    else
        result := Trim(inputString);
    
    // End debugMsg Section
end;

// Copies from end instead of beginning
function StrPosCopyReverse(inputString: string; findString: string; inputBoolean: boolean): string;
begin
    if ContainsText(inputString, findString) then
    begin
        RemoveFromEnd(inputString, ' ');
        if (findString = ' ') then
            if Flip(inputBoolean) then
                result := RemoveFromEnd(ReverseString(Copy(ReverseString(inputString), 0, ItPos(findString, ReverseString(inputString), 2) - Length(findString))), ' ')
            else
                result := RemoveFromEnd(ReverseString(Copy(ReverseString(inputString), ItPos(findString, ReverseString(inputString), 2) - Length(findString)), (Length(ReverseString(inputString)) - ItPos(findString, inputString, 2))), ' ')
        else
            result := ReverseString(StrPosCopy(ReverseString(inputString), findString, Flip(inputBoolean)))
            // addMessage('[StrPosCopyReverse]'+ReverseString(inputString));
            // addMessage('[StrPosCopyReverse]'+StrPosCopy(ReverseString(inputString), ' ', Flip(inputBoolean)));
            // addMessage('[StrPosCopyReverse]'+ReverseString(StrPosCopy(ReverseString(inputString), ' ', Flip(inputBoolean))));
    end
    else
        result := inputString;
end;

function Full(e: IInterface): string;
begin
    result := GetElementEditValues(e, 'FULL');
end;

// This is just a ghetto way of replacing all the items with a single leveled list; Returns the first element in the list
function RefreshList(aRecord: IInterface; aString: string): IInterface;
begin
    // Begin debugMsg Section
    

    { Debug } if debugMsg then
        addMessage('[AddToOutfitAuto] Remove(ElementByPath(' + GetElementEditValues(aRecord, 'EditorID') + ', ''' + aString + '''));');
    Remove(ElementByPath(aRecord, aString));
    { Debug } if debugMsg then
        addMessage('[AddToOutfitAuto] Add(' + GetFileName(aRecord) + ', ''' + aString + ''', True);');
    Add(aRecord, aString, true);
    result := elementbyindex(ElementByPath(aRecord, aString), 0);

    
    // End debugMsg Section
end;

// Find a record by name (e.x. 'IronSword')
function RecordByName(aName: string; aGroupName: string; aFileName: string): IInterface;
var
    slTemp        : TStringList;
    i, slTempCount: integer;
begin
    // Initialize
    if not Assigned(slTemp) then
        slTemp := TStringList.Create
    else
        slTemp.clear;

    // Function
    if not(StrEndsWith(aFileName, '.esm') or StrEndsWith(aFileName, '.esl') or StrEndsWith(aFileName, '.exe')) then
        AppendIfMissing(aFileName, '.esp');
    if (aFileName = 'Skyrim.esm') then
    begin
        slTemp           := TStringList.Create;
        slTemp.CommaText := 'Skyrim.esm, Dawnguard.esm, HearthFires.esm, Dragonborn.esm';
    end else begin
        slTemp := TStringList.Create;
        slTemp.Add(aFileName);
    end;
    for slTempCount := 0 to slTemp.Count - 1 do
    begin
        for i := 0 to Pred(ElementCount(GroupBySignature(FileByName(slTemp[slTempCount]), aGroupName))) do
        begin
            if ContainsText(EditorID(elementbyindex(GroupBySignature(FileByName(slTemp[slTempCount]), aGroupName), i)), 'Ench') or ContainsText(GetElementEditValues(elementbyindex(GroupBySignature(FileByName(slTemp[slTempCount]), aGroupName), i)), 'Of') then
            begin
                Continue;
            end
            else
                if ContainsText(EditorID(elementbyindex(GroupBySignature(FileByName(slTemp[slTempCount]), aGroupName), i)), aName) then
                begin
                    result := elementbyindex(GroupBySignature(FileByName(slTemp[slTempCount]), aGroupName), i);
                    exit;
                end;
        end;
    end;

    // Finalize
    slTemp.Free;
end;

// Removes s1 from the end of s2, if found [mte functions]
function RemoveFromEnd(s1, s2: string): string;
begin
    result := s1;
    if StrEndsWith(s1, s2) then
        result := Copy(s1, 1, Length(s1) - Length(s2));
end;

// This adds a name-value pair in a way that allows for duplicate values
function slAddValue(aName, aValue: string): string;
var
    slTemp  : TStringList;
begin
    // Initialize
    if not Assigned(slTemp) then
        slTemp := TStringList.Create
    else
        slTemp.clear;

    // Function
    slTemp.Values[aValue] := aName;
    if (slTemp.Count > 0) then
        result := slTemp[0];

    // Finalize
    slTemp.Free;
end;

// Reverses a string.
function ReverseString(var s: string): string;
var
    i: integer;
begin
    result := '';
    for i  := Length(s) downto 1 do
    begin
        result := result + Copy(s, i, 1);
    end;
end;

// find the last position of a substring in a string [mte Functions]
function rPos(aString, substr: string): integer;
var
    i: integer;
begin
    result := -1;
    if (Length(aString) - Length(substr) < 0) then
        exit;
    for i := Length(aString) - Length(substr) downto 1 do
    begin
        if (Copy(aString, i, Length(substr)) = substr) then
        begin
            result := i;
            break;
        end;
    end;
end;

// Converts a boolean value into a string [mte Functions]
function BoolToStr(b: boolean): string;
begin
    if b then
        result := 'True'
    else
        result := 'False';
end;

// Converts string to boolean
function StrToBool(s: string): boolean;
begin
    if ContainsText(s, 'True') then
        result := true
    else
        result := false;
end;

// Searches for string within TStringList
function slContains(aList: TStringList; s: string): boolean;
var
    i       : integer;
begin
    // Begin debugMsg section
    

    result := false;
    { Debug } if debugMsg then
        msgList('[slContains] if ', aList, ' contains ' + s);
    if (aList.IndexOf(s) <> -1) then
        result := true;

    
    // End debugMsg section
end;

// Creates a leveled list
function createLeveledList(aPlugin: IInterface; aName: string; LVLF: TStringList; LVLD: integer): IInterface;
var
    startTime, stopTime: TDateTime;
    aLevelList         : IInterface;
begin
    // Initialize
    
    startTime := Time;

    { Debug } if debugMsg then
        msgList('[createLeveledList] createLeveledList(' + GetFileName(aPlugin) + ', ' + aName + ', ', LVLF, ', ' + IntToStr(LVLD) + ' );');
    aLevelList := createRecord(aPlugin, 'LVLI');
    SetElementEditValues(aLevelList, 'EDID', aName);
    slSetFlagValues(aLevelList, LVLF, aPlugin);
    if not(LVLD = 0) then
        SetElementEditValues(aLevelList, 'LVLD', LVLD);
    Add(aLevelList, 'Leveled List Entries', true);
    //RemoveInvalidEntries(aLevelList);
    result := aLevelList;
    { Debug } if debugMsg then
        addMessage('[createLeveledList] Result := ' + EditorID(result));

    // Finalize
    stopTime := Time;
    if ProcessTime then
        addProcessTime('createLeveledList', TimeBtwn(startTime, stopTime));
end;

// Converts Hex FormID to String
function HexToStr(aFormID: string): string;
begin
    result := IntToStr(StrToInt(aFormID));
end;

function Flip(inputBoolean: boolean): boolean;
begin
    if inputBoolean then
        result := false
    else
        result := true;
end;

// gets record by IntToStr HEX FormID [SkyrimUtils]
function getRecordByFormID(id: string): IInterface;
var
    startTime, stopTime: TDateTime;
    tmp                : IInterface;
begin
    // Initialize
    startTime := Time;

    // basically we took record like 00049BB7, and by slicing 2 first symbols, we get IntToStr file index, in this case Skyrim (00)
    tmp := FileByLoadOrder(StrToInt('$' + Copy(id, 1, 2)));

    // file was found
    if Assigned(tmp) then
    begin
        // look for this record in founded file, and return it
        tmp := RecordByFormID(tmp, StrToInt('$' + id), true);

        // check that record was found
        if Assigned(tmp) then
        begin
            result := tmp;
        end else begin // return nil if not
            result := nil;
        end;

    end else begin // return nil if not
        result := nil;
    end;

    // Finalize
    stopTime := Time;
    if ProcessTime then
        addProcessTime('getRecordByFormID', TimeBtwn(startTime, stopTime));
end;

// Checks for keyword [SkyrimUtils]
function HasKeyword(aRecord: IInterface; aString: string): boolean;
var
    tempRecord: IInterface;
    i         : integer;
begin
    // Begin debugMsg section
    

    result     := false;
    tempRecord := ElementByPath(aRecord, 'KWDA');
    for i      := 0 to Pred(ElementCount(tempRecord)) do
    begin
        { Debug } if debugMsg then
            addMessage('[HasKeyword] if (' + EditorID(LinksTo(elementbyindex(tempRecord, i))) + ' = ' + aString + ' ) then begin');
        if (EditorID(LinksTo(elementbyindex(tempRecord, i))) = aString) then
        begin
            { Debug } if debugMsg then
                addMessage('[HasKeyword] Result := True');
            result := true;
            break;
        end;
    end;

    
    // End debugMsg section
end;

// Gets a keyword list [SkyrimUtils]
procedure slKeywordList(aRecord: IInterface; out aList: TStringList);
var
    tempRecord: IInterface;
    i         : integer;
begin
    // Begin debugMsg section
    
    if debugMsg then
        addMessage('slKeywordList start');
    tempRecord := ElementByPath(aRecord, 'KWDA');
    if not Assigned(aList) then
        aList := TStringList.Create;
    for i     := 0 to ElementCount(tempRecord) - 1 do
        aList.Add(EditorID(LinksTo(elementbyindex(tempRecord, i))));
    if debugMsg then
        addMessage('slKeywordList complete');
    
    // End debugMsg section
end;

// Adds keyword [SkyrimUtils]
function AddKeyword(itemRecord: IInterface; keyword: IInterface): integer;
var
    keywordRef: IInterface;
begin
    // don't edit records, which already have this keyword
    if not HasKeyword(itemRecord, EditorID(keyword)) then
    begin
        // get all keyword entries of provided record
        keywordRef := ElementByName(itemRecord, 'KWDA');

        // record doesn't have any keywords
        if not Assigned(keywordRef) then
        begin
            Add(itemRecord, 'KWDA', true);
        end;
        // add new record in keywords list
        keywordRef := ElementAssign(ElementByPath(itemRecord, 'KWDA'), HighInteger, nil, false);
        // set provided keyword to the new entry
        SetEditValue(keywordRef, GetEditValue(keyword));
    end;
end;

procedure AppendDelimited(out aStringList: TStringList; aSourceText: string);
var
    sl: TStringList;
begin
    sl               := TStringList.Create;
    sl.commatext := aSourceText;
    aStringList.AddStrings(sl);
    sl.Free;
end;

procedure Compact(out aStringList: TStringList);
var
    slValueTiers: TStringList;
    slCIL2      : TStringList;
    slCIL       : TStringList;
    slValues    : TStringList;
    slEmpty     : TStringList;
    slPath2Temp : TStringList;
    slPaths     : TStringList;

    sCIP : string;
    sCIN : string;
    sCIS : string;
    sTemp: string;

    iCT : integer;
    iCIT: integer;
    iMax: integer;
    i   : integer;
    j   : integer;
    k   : integer;

    bDebug: boolean;

    kCI: IInterface;
begin
    bDebug := false;

    slPaths := TStringList.Create;

    // primary path
    sTemp := aStringList.Objects[aStringList.IndexOf('sPath1')];
    slPaths.addObject(Copy(sTemp, 0, Pos(':', sTemp) - 1), Copy(sTemp, Pos(':', sTemp), Length(sTemp) - 1));

    // secondary slPaths
    slPath2Temp := TStringList.Create;
    slPath2Temp := aStringList.Objects[4];

    for i := Pred(slPath2Temp.Count) downto 0 do
    begin
        sTemp := slPath2Temp.Objects[i];
        slPaths.addObject(Copy(sTemp, 0, Pos(':', sTemp) - 1), Copy(sTemp, Pos(':', sTemp) + 1, Length(sTemp)));
    end;

    slValues := TStringList.Create;
    iMax     := aStringList.Objects[5];

    for i := Pred(slPaths.Count) downto 0 do
    begin
        // initialize the slValues to have a proper name
        slEmpty := TStringList.Create;

        for i := 0 to Pred(slValues.Count) do
            slEmpty.addObject(IntToStr(i), 0);

        slValues.addObject(slPaths[i], slEmpty);
    end;

    i := 5;
    repeat
        if bDebug then
            addMessage('generating compacted comparison slValues');

        // get the value of sPath1 and slPath2 for each, and average them.
        slCIL  := TStringList.Create;
        slCIL  := aStringList.Objects[i]; // current r list
        slCIL2 := TStringList.Create;

        // process all items
        for j := 0 to Pred(Length(slCIL)) do
        begin
            sCIS := IntToStr(slCIL.Objects[j]);
            sCIP := Copy(sCIS, 0, Pos('|', sCIS) - 1);
            sCIN := Copy(sCIS, Pos('|', sCIS) + 1, Pos(':', sCIS) - 1);
            iCIT := StrToInt64Def(Copy(sCIS, Pos(':', sCIS) + 1, Length(sCIS)), 15);
            kCI  := RecordByEditorID(FileByName(sCIP), sCIN);

            slCIL2.Add(iCIT);
            slCIL2.Objects[j] := kCI;
        end;

        slCIL := slCIL2;
        slCIL2.Free;

        aStringList.addObject(aStringList[i] + 'slValues', slValues);

        i := i + 2;
    until i > aStringList.Count - 2;

    i := 5;

    repeat
        if bDebug then
            addMessage('generating compacted comparison slValues');

        // get the value of sPath1 and slPath2 for each, and average them.
        slCIL := aStringList.Objects[i]; // current r list

        for j := Pred(Length(slCIL)) downto 0 do
        begin // process all items
            kCI := ObjectToElement(slCIL.Objects[j]);
            iCT := StrToInt(slCIL[j]);

            // process all items over all slPaths
            for k := Pred(slPaths.Count) downto 0 do
            begin
                slValueTiers := slValues.Objects[k];

                if iCT > iMax then
                begin
                    addMessage('an r breached iMax level of selected template list');
                    Continue;
                end;

                // the extra math is for smoothing the curve a bit. probably could drop it easily.
                slValueTiers.Objects[iCT] := slValueTiers.Objects[iCT] + (StrToFloatDef(GetElementEditValues(kCI, slPaths[k]), 1) * slPaths.Objects[k]);
            end;
        end;

        aStringList.addObject(aStringList[i] + 'slValues', slValues);
        i := i + 2;
    until i > aStringList.Count - 2;
end;

function toUsable(aList: TStringList; grup: string): TStringList;
var
	plugin,tr: IInterface;
	edid,ts:string;
	bList:TStringList;
	i:integer;
begin
	bList := TStringList.Create;
	for i := 0 to pred(aList.Count) do begin
		ts := aList[i];
		//addMessage(ts);
		plugin := FileByName(copy(ts, 0, pos('|', ts) - 1));
		edid := copy(ts, pos('|', ts) + 1, length(ts));
		tR := MainRecordByEditorID(GroupBySignature(plugin, grup), edid);
		bList.addObject(edid, tr);
		//addmessage(editorID(tr));
	end;
	result := bList;
end;

function badCheck(A: IInterface, sig: string): boolean; //return true when record meets common improper conditions
var
	tempString:string;
begin
	if not signature(a) = sig then begin
		result := true;
		exit;
	end;
	if signature(a) = 'LVLI' then begin
		tempString := EditorID(a);
		if ContainsText(tempString, '++') 
		  or (Length(tempString) <= 0) 
		  or FlagCheck(a, 'Special Loot') then
			result := true;
	end;
	
end;

function templatelistfilter2(grup, filter1, filter2, itemset: string): TStringList;
var
	templist:TStringList;
begin
	tempList := TStringList.Create;
	{addmessage(itemset);
	addmessage(filter1);
	addmessage(filter2);}
	tempList := IniStringlist(itemset + ' - ' + filter1, filter2, '');
	templist.AddObject('comparison', comparisonGather(itemset + ' - ' + filter1));
	//msgListObject('templist notgendered ', templist, ' hope it works?');
	result := toUsable(templist, grup);
end;

function templatelistfilter2Gendered(grup, filter1, filter2, itemset: string;genders:TStringList): TStringList;
var
	tempLista:TStringList;
	templist:TStringList;
	i:integer;
	g:string;
begin
	tempLista := TStringList.Create;
	templist := TStringList.Create;
	templist.AddObject('comparison', comparisonGather(itemset + ' - ' + filter1));
	for i := 0 to pred(genders.count) do begin
		g := genders[i];
		tempList := IniStringlist(itemset + ' - ' + filter1 + ' - ' + g, filter2, '');
		templista.addObject(g, toUsable(templist, grup));
		templist.AddObject('comparison' + g, comparisonGather(itemset + ' - ' + filter1 + ' - ' + g));
	end;
	tempList := IniStringlist(itemset + ' - ' + filter1, filter2, '');
	//msgListObject('templist gendered', templist, 'hope it works?');
	templista.addobject('genderless', toUsable(templist, grup));
	result := templista;
end;

function templateFilter1(grup, filter1, itemset: string; filter2: TStringList): TStringList;
var
	templist:TStringList;
	genders:TStringList;
	gender:boolean;
	i:integer;
begin
	tempList := TStringList.Create;
	gender := ini.readBool(itemset, 'gendered', false);
	if not gender then begin
		for i := 0 to pred(filter2.count) do begin
			//msgListObject('templateFilter1g', templist, 'hope it works?');
			//addMessage(filter2[i]);
			templist.AddObject(filter2[i], templatelistfilter2(grup, filter1, filter2[i], itemset));
		end;
	end else begin
		genders := IniStringList(itemset, 'genderIndicator', '');
		for i := 0 to pred(filter2.count) do begin
			//msgListObject('templateFilter1ng', templist, 'hope it works?');
			//addMessage(filter2[i]);
			templist.AddObject(filter2[i], templatelistfilter2Gendered(grup, filter1, filter2[i], itemset,genders));
		end;
	end;
	result := tempList;
end;

function templateFilter0(grup, itemset: string; filter1, filter2: TStringList): TStringList;
var
	templist:TStringList;
	i:integer;
begin
	tempList := TStringList.create;
	for i := 0 to pred(filter1.count) do begin
		//msgListObject('templateFilter0', templist, 'hope it works?');
		//addMessage(filter1[i]);
		tempList.AddObject(filter1[i], templateFilter1(grup, filter1[i], itemset, filter2));
	end;
	result := tempList;
end;

function ComparisonGather(itemset: string): TStringList;
var
	cValue,cdescription,cdescriptor:TStringList;
	templist,tempList2:TStringList;
	ts,path,desType:string;
	cl,cm:string;
	i:integer;
begin
	cValue := TStringList.Create;
	cDescriptor := TStringList.Create;
	cDescription := TStringList.Create;
	//cvalue is easy. just p1 and the value.
	cvalue.Add('p1='+FloatToStr(IniFloatLast(itemset,'comparison1',1)));
	cvalue.Add('p2='+FloatToStr(IniFloatLast(itemset,'comparison2',0.875)));
	cvalue.Add('p3='+FloatToStr(IniFloatLast(itemset,'comparison3',0.75)));
	cvalue.Add('p4='+FloatToStr(IniFloatLast(itemset,'comparison4',0.625)));
	cvalue.Add('p5='+FloatToStr(IniFloatLast(itemset,'comparison5',0.5)));
	cvalue.Add('p6='+FloatToStr(IniFloatLast(itemset,'comparison6',0.375)));
	
	//cdescriptor is a little harder, type and path needed.
	for i := 0 to 5 do begin
		cl := 'p' + intToStr(i+1);
		tempList := TStringList.Create;
		ts := IniStringLast(itemset, 'descriptor' + IntToStr(i+1), '');
		path := copy(ts, 0,  pos('|', ts) - 1);
		desType := copy(ts, pos('|', ts) + 1, length(ts) - 1);
		tempList.Add('path='+path);
		tempList.Add('type='+desType);
		cDescriptor.addobject(cl, tempList);
		tempList.free;
	end;
	
	//cdescription is annoying. gotta include each item based on the type of cDescriptor.
	for i := 0 to 5 do begin
		cl := 'p' + intToStr(i+1);
		cm := 'descriptions1' + IntToStr(i+1);
		tempList2 := TStringList.Create;
		tempList := getObject(cl,cvalue);
		desType := getObject('type', tempList);
		if desType = 's' then begin
			//s is substrings within a string
			templist2 := IniStringlist(itemset, cm, '');
		end else if desType = 'b' then begin
			//b is substrings within a string - but only whole terms (spaces separate)
			templist2 := IniStringlist(itemset, cm, '');
		end else if desType = 'f' then begin
			//this is a specific formid
			
		end else if desType = 'n' then begin
			//this is a number. always assume float
			//this is unnecessary.
		end else if desType = 'e' then begin
			//this is a group of subelements
			templist2 := IniStringlist(itemset, cm, '');
			{for i := 0 to pred(templist2.count) do begin
				//should I implement this as assuming kywd? or should I assume nothing? should I keep this as just edids?
			end;}
		end;
		cDescription.AddObject(cl,templist2);
		tempList2.free;
	end;
	
	tempList := TStringList.Create;
	tempList.addObject('values', cValue);
	tempList.AddObject('descriptor', cDescriptor);
	tempList.AddObject('descriptions', cDescription);
	result := tempList;
end;

function templateitemsets(itemset: TStringList): TStringList;
var
	i:integer;
	ci, grup: string;
	outList,templist,filter1,filter2: TStringList;
	gruplist: TStringList;
begin
	outList := TStringList.Create;
	for i := 0 to pred(itemset.count) do begin
		ci := itemset[i];
		if debugMsg then addMessage('adding itemset group ' + ci + ' to template data');
		filter1 := IniStringList(ci, 'result1', '');
		if debugMsg then msgList(ci, filter1, 'itemset list contents for result 1');
		filter2 := IniStringList(ci, 'result2', '');
		if debugMsg then msgList(ci, filter2, 'itemset list contents for result 2');
		grup := IniStringFirst(ci, 'type', '');
		if debugMsg then addMessage(ci + ' ' + grup + '  itemset signature');
		templist := TStringList.Create;
		tempList.Add('grup='+grup);
		tempList.AddObject('split', splitfunc(ci, filter1, filter2));
		tempList.AddObject('template',  templateFilter0(grup, ci, filter1, filter2));
		outList.addObject(ci, tempList);
	end;
	result := outList;
end;

function TemplateEnchants(modifiers: TStringList): TStringList;
begin
	if (wbAppName = 'TES5') OR (wbAppName = 'SSE') then begin
		//due to changes, all but ench will work for fo4. just need to implement it properly
	end else if wbAppName = 'FO4' then begin
		//this probably wont ever be implemented, but gonna leave it here just in case? for scopes and such or whatever?
	end;
	//TODO. need to determine a lot of stuff for this to work right.
end;

procedure TemplateMegaList;
var
	itemset:TStringList;
begin
	Megalist := TStringList.Create;
	IniPositions := IniStringlist('values', 'position', '');
	itemset := IniStringlist('values', 'itemsets', '');
	//msgListObject('ml',itemset,'ml');
	//modifiers := IniStringlist('values', 'modifiers', '');
	Megalist.AddObject('items', templateitemsets(itemset));
	Megalist.AddObject('enchants', TemplateEnchants(modifiers));
end;

procedure BOD2Setup;
var
	i:integer;
begin
	BOD2List := TStringList.Create;
	for i := 30 to 60 do begin
		BOD2List.AddObject(IntToStr(i),IniStringAll('bod2', i, ''));
	end;
end;

function splitfunc(itemset: string; filter1, filter2: TStringList): TStringList;
var
	split1,split2,genderfil:string;
	templist,genderind:TStringList;
	gendered:boolean;
begin
	split1 := IniStringLast(itemset, 'split1', '');
	if debugMsg then addmessage('split1='+split1);
	split2 := IniStringLast(itemset, 'split2', '');
	if debugMsg then addmessage(split2);
	gendered := StrToBool(IniStringLast(itemset, 'gendered', false));
	tempList := TStringList.Create;
	if gendered then begin
		templist.addobject('gender', gendered);
		genderfil := IniStringLast(itemset, 'genderFilter', false);
		templist.add('genderFilter='+genderfil);
		genderind := IniStringlist(itemset, 'genderIndicator', false);
		templist.addobject('genderIndicator', genderind);
	end;
	tempList.Add('split1='+split1);
	if debugMsg then addmessage('split1='+templist.values['split1']);
	tempList.Add('split2='+split2);
	tempList.AddObject('result1', filter1);
	tempList.AddObject('result2', filter2);
	result := tempList;
end;

function IniStringLast(group, key, default: String): String;
var
	i:integer;
	memIniFile:TMemIniFile;
begin
	for i := 0 to Pred(IniFileStreams.Count) do
	begin
		memIniFile := IniFileStreams.Objects[i];
		default := memIniFile.ReadString(group, key, default);
	end;
	result := default;
end;

function IniStringFirst(group, key, default: String): String;
var
	i:integer;
	memIniFile:TMemIniFile;
begin
	for i := Pred(IniFileStreams.Count) downto 0 do
	begin
		memIniFile := IniFileStreams.Objects[i];
		default := memIniFile.ReadString(group, key, default);
	end;
	result := default;
end;

function IniStringAll(group, key, default: String): TStringList;
var
	i:integer;
	memIniFile:TMemIniFile;
	temp:string;
	tempList:TStringList;
begin
	templist := TStringList.Create;
	templist.Sorted     := True;
	templist.Duplicates := dupIgnore;
	for i := Pred(IniFileStreams.Count) downto 0 do
	begin
		memIniFile := IniFileStreams.Objects[i];
		temp := memIniFile.ReadString(group, key, '');
		if pos(temp, ',') < 0 then 
		AppendDelimited(tempList, temp);
	end;
	if tempList.Count < 1 then templist.add(default);
	result := tempList;
end;

function IniStringlist(group, key, default: String): TStringList;
var
	i:integer;
	memIniFile:TMemIniFile;
	templist:TStringList;
begin
	templist := TStringList.Create;
	for i := Pred(IniFileStreams.Count) downto 0 do
	begin
		memIniFile := IniFileStreams.Objects[i];
		//addmessage(memIniFile.ReadString(group, key, ''));
		if not assigned(templist) then 
			templist := DelimitedText(memIniFile.ReadString(group, key, ''))
		else
			AppendDelimited(templist, memIniFile.ReadString(group, key, ''));
	end;
	if tempList.Count < 1 then templist.add(default);
	templist.Sorted     := True;
	templist.Duplicates := dupIgnore;
	result := templist;
end;

function IniFloatFirst(group, key: String; default: double): double;
var
	i:integer;
	memIniFile:TMemIniFile;
	default:double;
begin
	for i := Pred(IniFileStreams.Count) downto 0 do
	begin
		memIniFile := IniFileStreams.Objects[i];
		default := memIniFile.ReadFloat(group, key, default);
	end;
	result := default;
end;

function IniFloatLast(group, key: String; default: double): double;
var
	i:integer;
	memIniFile:TMemIniFile;
	default:double;
begin
	for i := 0 to Pred(IniFileStreams.Count) do
	begin
		memIniFile := IniFileStreams.Objects[i];
		default := memIniFile.ReadFloat(group, key, default);
	end;
	result := default;
end;


procedure template;
var
	IniTemplates,memIniFile: TMemIniFile;
	i: integer;
	itemset:tStringList;
begin
    IniFileStreams   := TStringList.Create;
	
    // setup template files
    // ALLATemplate.ini
    // ALLAUserTemplate.ini
    // ALLA+<modname>+template.ini in data folder (ie: ALLAYggKeywords.espTemplate.ini)

    IniTemplates := TStringList.Create;
    IniTemplates.Add(ScriptsPath + 'ALLATemplate.ini');
    IniTemplates.Add(ScriptsPath + 'ALLAUserTemplate.ini');

    for i := 0 to Pred(FileCount) do
        if FileExists(DataPath + 'alla' + GetFileName(FileByIndex(i)) + 'template.ini') then
            IniTemplates.Add(DataPath + 'alla' + GetFileName(FileByIndex(i)) + 'template.ini');

    addMessage('[TemplateLists] detected ' + IntToStr(IniTemplates.Count) + ' Template Inis');

    for i := Pred(IniTemplates.Count) downto 0 do
    begin
        memIniFile := TMemIniFile.Create(IniTemplates[i]);

        IniFileStreams.addObject(IniTemplates[i], memIniFile);
    end;
	
	for i := Pred(IniTemplates.Count) downto 0 do
    begin
        memIniFile := TMemIniFile.Create(IniTemplates[i]);
        IniFileStreams.addObject(IniTemplates[i], memIniFile);
    end;
	memIniFile := TMemIniFile.Create(IniTemplates[1]);
	if not Assigned(memIniFile) then
		addMessage('stupid');
	IniFileStreams.addObject(IniTemplates[1], memIniFile);
	
	itemset := IniStringList('values','items','armor,weapons,ammo');
	
	templateMegalist;

	BOD2Setup;
end;

function GetTemplate(aRecord: IInterface): IInterface;
var
	CIS,CL: TStringList;
	grup:string;
	split,result1,result2:TStringList;
	split1,split2: string;
	g:boolean;
	gf:string;
	gI:TStringList;
	i:integer;
	cr:IInterface;
	cre:string;
	gender:string;
	p1:IInterface;
	cK:IInterface;
	j:integer;
	r1:string;
	p2: IInterface;
	r2:string;
	listr1,listr2,glist,comparison,CIST:TStringList;
	sig: string;
	cJ: string;
	l: integer;
begin
	addmessage('gettemplate for item: ' + Full(aRecord));
	sig := signature(aRecord);
	addmessage('current record signature is: ' + sig);
	CL := megalist.objects[0]; //get itemsets (list) from megalist
	for i := 0 to pred(CL.count) do begin
		CIS := CL.objects[i]; //get itemset (list) from itemsets
		grup := CIS.values['grup']; //get grup (string) from itemset
		addmessage(varTypeAsText(grup));
		AddMessage('current comparison signature is: ' + grup);
		if sig = grup then break;
	end;
	if not sameText(sig, grup) then begin
		result := aRecord;
		addmessage('no matching signature for ' + editorID(aRecord));
		exit;
	end;
	
	split := CIS.objects[CIS.indexOf('split')]; //get split (list) from itemset
	
	split1 := split.Values['split1'];
	split2 := split.Values['split2'];
	result1 := split.objects[split.indexof('result1')];//GetObject('result1', split);
	result2 := split.objects[split.indexof('result2')];//GetObject('result2', split);
	g := GetObject('gender', split); //get gender (string) from split
	while g do begin
		gF := split.Values['genderFilter']; //if gendered, get filter (string) from split
		gI := split.objects[split.indexof('genderIndicator')]; //if gendered, get indicator(s) (list) from split
		if (length(gF) = 0) or (length(gI) = 0) then begin
			result := aRecord;
			addMessage('gender filter not updated');
			g := false;
		end;
		addMessage('gender: ' + g);
		addmessage('genderf: ' + gf);
		msgList('genders available', gI, '');
		if StrEndsWith(gF, '/') then begin
			cP := ElementByPath(aRecord, gF);
			for i := 0 to pred(elementCount(cP)) do begin
				cK := ElementByIndex(cP, i);
				if length(GetEditValue(cK)) < 1 then begin //test to see if nested subrecord in element. probably a cleaner way to do it. hopefully someone sends it to me…
					cR := ElementByIndex(cK, 0);
					cRE := GetEditValue(cR);
					if slContains(gI, cRE) then begin
						for i := 0 to gI.count - 1 do begin
							if gI[i] = cRE then begin
								gender := gI[i];
								break;
							end;
						end;
					end;
				end else begin
					cR := cK;
					if slContains(gI, GetEditValue(cR)) then begin
						for i := 0 to gI.count - 1 do begin
							if gI[i] = cRE then begin
								gender := gI[i];
								break;
							end;
						end;
					end;
				end;
			end;
		end;
	end;
	
	//debug stuff
	AddMessage('splits: ' + split1);
	AddMessage('more splits: ' + split2);
	//addmessage('result type: ' + varTypeAsText(result1));
	msglist('results: ', result1, '');
	msglist('more results: ', result2, '');
	
	r1 := badnamingconvention(aRecord, split1, result1);
	r2 := badnamingconvention(aRecord, split2, result2);
	
	//r1, r2
	addMessage('results 1: ' + r1 + ' result 2: ' + r2);
	
	CIST := CIS.objects[CIS.indexOf('template')];
	if slContains(CIST, r1) then
		listr1 := CIST.objects[CIST.IndexOf(r1)];
	if not assigned(listr1) then begin
		addMessage('item doesnt have comparable item in inis. moving on.');
		result := aRecord;
		exit;
	end;
	addmessage(' ');
	msgList('CIST', CIST, '');
	addmessage(' ');
	msgList('LISTr1', listr1, '');
	addmessage(' ');
	if slContains(listr1, r2) then
		listr2 := listr1.objects[listr1.indexOf(r2)];
	if not assigned(listr2) then begin
		addMessage('item doesnt have comparable item in inis. moving on.');
		result := aRecord;
		exit;
	end;
	addmessage(' ');
	msgList('CIST', CIST, '');
	addmessage(' ');
	msgList('LISTr2', listr2, '');
	addmessage(' ');
	if g and assigned(gender) then begin
		if slContains(listr2, gender) then 
			glist := listr2.objects[listr2.indexof(gender)];
		comparison := listr2.objects[listr2.indexOf('comparison' + g)];
	end else if g then begin
		if slContains(listr2, 'genderless') then 
			glist := listr2.objects[listr2.indexof('genderless')];
		comparison := listr2.objects[listr2.indexOf('comparison')];
	end else begin
		gList := listr2.objects[0];
		comparison := listr2.objects[listr2.indexOf('comparison')];
	end;
	if not assigned(glist) then begin
		addMessage('item doesnt have comparable item in inis. moving on.');
		result := aRecord;
		exit;
	end;
	
	
	result := compare(aRecord, glist, comparison);
	addmessage('original: ' editorID(aRecord) + 'template: ' + EditorID(result));
	
end;

function badnamingconvention(aRecord: IInterface; split: string; result1: tStringList):string;
var
	p1: IInterface;
	i,j,l: integer;
	cK: IInterface;
	cJ: string;
	r1: string;
	temp: TStringList;
begin
	p1 := ElementByPath(aRecord, split);
	if ContainsText(split, 'flag') then begin
		temp := tStringList.create;
		slGetFlagValues(p1, temp, true);
		for i := 0 to result1.count - 1 do begin
			r1 := result1[i];
			if slWithinStr(r1, temp) then begin
				result := r1;
				exit;
			end;
		end;
	end;
	if StrEndsWith(GetEditValue(p1), '\') then begin
		for i := 0 to elementCount(p1) - 1 do begin
		cK := ElementByIndex(p1, i);
			if length(GetEditValue(cK)) < 1 then begin //test to see if nested subrecord in element. probably a cleaner way to do it exists.
				for l := 0 to elementCount(cK) do begin
					cJ := GetEditValue(ElementByIndex(cK, l));
					for j := 0 to result1.count - 1 do begin
						//addmessage('cJ0 ' + cJ);
						if cJ = result1[j] then begin
							r1 := result1[j];
							break;
						end;
					end;
				end;
			end else begin
				for j := 0 to result1.count - 1 do begin
					//addmessage('cK1 ' + GetEditValue(cK));
					if getEditValue(cK) = result1[j] then begin
						r1 := result1[j];
						break;
					end;
				end;
			end;
		end;
	end else begin
		cK := p1;
		if length(GetEditValue(cK)) < 1 then begin //test to see if nested subrecord in element. probably a cleaner way to do it exists.
			for l := 0 to elementCount(cK) do begin
				cJ := GetEditValue(ElementByIndex(cK, l));
				for j := 0 to result1.count - 1 do begin
					//addmessage('cJ1 ' + cJ);
					if cJ = result1[j] then begin
						r1 := result1[j];
						break;
					end;
				end;
			end;
		end else begin
			cJ := GetEditValue(cK);
			for i := 0 to result1.count - 1 do begin
				//addmessage('cJ2 ' + cJ);
				if cJ = result1[i] then begin
					r1 := result1[i];
					break;
				end;
			end;
		end;
	end;
	if length(r1) < 1 then begin
		addMessage('item doesnt have comparable item in inis. moving on.');
		result1 := aRecord;
		exit;
	end;
	addmessage(' ' + r1);
	result := r1;
end;

function compare(aRecord: IInterface; list,comps: tStringList): IInterface;
begin
	comparisonCount := 6;
	Value := comps.objects[comps.indexOf('values')];
	Descriptor := comps.objects[comps.indexOf('descriptor')];
	Description := comps.objects[comps.indexOf('descriptions')];
	for i := pred(list) to 0 do begin
		current := ObjectToElement(list.objects[i]);
		for j := 1 to comps do begin
			cs := 'p' + intToStr(j);
			cv := value.objects[value.indexOf(cs)];
			cdr := Descriptor.objects[Descriptor.indexOf(cs)];
			cdt := copy(cdr, cdr.length - 3, 2);
			cdr := delete(2, cdr);
			cdn := Description.objects[Description.indexOf(cs)];
			if cdt = '|n' then begin
				currentComp := StrToFloatDef(getelementeditvalue(current, cdr), 0);
				itemComp := StrToFloatDef(getelementeditvalue(aRecord, cdr),50);
				tvalue := tvalue + numcomp(itemComp,currentcomp,cv);
			end else if cdt = '|s' then begin
				currentComp := getelementeditvalue(current, cdr);
				itemComp := getelementeditvalue(aRecord, cdr);
				tValue := tvalue + strComp(itemComp,currentComp,cdr,cv);
			end else if cdt = '|b' then begin
				currentComp := ElementByName(current, cdr);
				itemComp := ElementByName(aRecord, cdr);
				tValue := tvalue + strComp(itemComp,currentComp,cdr,cv);
			end else if cdt = '|e' then begin
				currentComp := ElementByName(current, cdr);
				itemComp := ElementByName(aRecord, cdr);
				tValue := tvalue + edidComp(itemComp,currentComp,cv);
			end;
			
		end;
		if (j = 1) or (presentvalue > maxValue) then begin
			maxValue := presentvalue;
			bestItem := i;
		end;
	end;
	result := list.objects[i];
end;

function NumComp(v1,v2,c: double):double;
begin
	//v2 is from template
	//c is comparison value
	if v1 > v2 + 1 then begin
		result := 5*abs((v2/v1)*(v1/(c-v1+((2*v2)(v2/v1)))))
	end else if v2 > v1 + 1 then begin
		result := 5*abs((v2/v1)*(v1/(c-v1-((2*v2)(v2/v1)))))
	end else begin
		result := c;
	end;
end;

function strComp(v1,v2:string;des: tStringList;c: double):double;
begin
	for i := 0 to pred(des.count) do begin
		if ContainsText(v1,des[i]) and ContainsText(v2,des[i]) then begin
			a := a + 1;
		end;
	end;
	result := c * a;
end;

function substrComp(v1,v2:string;des: tStringList;c: double):double;
begin
	for i := 0 to pred(des.count) do begin
		for j := 0 to pred(elementCount(v1)) do begin
			for k := 0 to pred(elementCount(v2)) do begin
				if containsText(GetEditValue(ElementByIndex(v1,j)),des[i]) and  ContainsText(GetEditValue(ElementByIndex(v2,j)), des[i]) then begin
					a := a + 1;
				end;
			end;
		end;
	end;
	result := a * c;
end;

function edidComp(v1,v2:string;c:double):double;
begin
	for i := 0 to pred(ElementCount(v1)) do begin
		for j := 0 to pred(ElementCount(v2)) do begin
			if equals(v1,v2) then begin
				a := a + 1;
			end;
		end;
	end;
	result := a*c;
end;

function YggCompareStrings(aString, bString: TStringList): integer;
var
    a    : integer;
    b    : integer;
    i    : integer;
    j    : integer;
    tempi: integer;
    aList: TStringList;
    bList: TStringList;

begin
    a := Length(aString);
    b := Length(bString);
    if a > 5 then
    begin
        for i := 0 to a - 1 do
        begin
            for j := a - 1 downto i + 4 do
            begin
                aList.Add(Copy(aString, i, j));
            end;
        end;
    end
    else
        result := 0;

    if b > 5 then
    begin
        for i := 0 to bString - 1 do
        begin
            for j := bString - 1 downto i + 4 do
            begin
                bList.Add(Copy(bString, i, j));
            end;
        end;
    end
    else
        result := 0;

    tempi := CompareStringLists(aList, bList);
    if tempi / 10 > 1 then
        result := floor(tempi / 10)
    else
        if tempi > 1 then
            result := 1;
else
    result := 0;
end;

function CompareStringLists(aStringList: TStringList; aOtherStringList: TStringList): integer;
var
    i     : integer;
    iCount: integer;
    iIndex: integer;
begin
    aStringList.Sort;
    aOtherStringList.Sort;

    iCount := 0;
    for i  := 0 to Pred(aStringList.Count) do
    begin
        iIndex := aOtherStringList.IndexOf(aStringList[i]);

        if not(iIndex < 0) then
        begin
            aStringList.Delete[iIndex];
            iCount := iCount + 1;
        end;
    end;

    result := iCount;
end;

function SameKeywordCount(aRecord: IInterface; aOtherRecord: IInterface): integer;
var
    bDebug: boolean;
    i     : integer;
begin
    // Begin debugMsg section
    bDebug := false;

    result := false;

    kTempRecord := ElementBySignature(aRecord, 'KWDA');

    for i := 0 to Pred(ElementCount(kTempRecord)) do
        if HasKeyword(aOtherRecord, elementbyindex(kTempRecord, i)) then
            total := total + 1;

    bDebug := false;
    // End debugMsg section
end;

function SubTemplateSelector(aRecord: IInterface; aTemplateList: TStringList): TStringList;
var
    i            : integer;
    slSubTemplate: TStringList;
    slPartType   : TStringList;
    sCTLN        : string;
    sCTLN1       : string;
begin
    repeat
        i := i + 1;
    until i = aTemplateList.Count - 1 or ContainsText(aTemplateList[i], 'aKeywords');

    while i < aTemplateList.Count - 2 do
    begin
        if not ContainsText(aTemplateList[i], aKeywords) then
            break;

        slPartType := aTemplateList.Objects[i];
        sCTLN      := aTemplateList[i];
        sCTLN1     := aTemplateList[i - 1];

        slSubTemplate := TStringList.Create;

        if HasAKeyword(aRecord, slPartType) then
            if ContainsText(sCTLN, sCTLN1) then
            begin
                slSubTemplate.AddObjects(sCTLN1, aTemplateList.Objects[i - 1]);
                slSubTemplate.AddObjects(sCTLN1 + 'slValues', aTemplateList.Objects[aTemplateList.IndexOf(sCTLN1 + 'slValues')]);
                result := slSubTemplate;
                exit;
            end;

        i := i + 2;
    end;

end;

function GetTier(aRecord: IInterface; aTemplateList: TStringList; aTemplateMain: TStringList): TStringList;
var
    slPath2Temp   : TStringList;
    slPath2       : TStringList;
    slValueSublist: TStringList;
    slValue       : TStringList;
    sTemp         : string;
    sPath1        : string;
    dPrimePathCR  : Double;
    dPath1Comp    : Double;
    dPath2T       : Double;
    dPath2A       : Double;
    i             : integer;
    j             : integer;
    iTier         : integer;
begin
    // Result here will be a list of items in the iTier
    slValue := aTemplateList.Objects[1];

    // primary path for comparison
    sPath1 := Copy(aTemplateMain.Objects[3], 0, Pos(':', aTemplateMain.Objects[3]) - 1);

    // sPath1 mult value
    dPath1Comp := StrToFloatDef(Copy(sTemp, Pos(':', sTemp) + 1, sTemp.Length), 1);

    slPath2Temp := aTemplateMain.Objects[4];

    for i := Pred(slPath2Temp.Count) downto 0 do
    begin
        sTemp := slPath2Temp.Objects[i];

        slPath2.addObject(Copy(sTemp, 0, Pos(':', sTemp) - 1), StrToFloatDef(Copy(sTemp, Pos(':', sTemp) + 1, sTemp.Length), 1));
    end;

    slValueSublist := slValue.Objects[slValue.IndexOf(sPath1)];
    dPrimePathCR   := StrToFloatDef(GetElementEditValues(aRecord, sPath1), 1) * dPath1Comp;

    for i := 0 to Pred(slValueSublist.Count) do
    begin
        if dPrimePathCR > slValueSublist.Objects[i] + 1 then
            Continue;

        if dPrimePathCR < slValueSublist.Objects[i] - 1 then
        begin
            i := i - 1;
            break;
        end;

        break;
    end;

    iTier := i;

    addMessage('primary iTier for ' + DisplayName(aRecord) + ' is ' + iTier + ' processing secondary modifiers now');

    for i := 0 to Pred(slPath2.Count) do
    begin
        slValueSublist := slValue.Objects[slValue.IndexOf(slPath2[i])];

        for j := 0 to Pred(slValueSublist.Count) do
        begin
            if dPrimePathCR > slValueSublist.Objects[j] + 1 then
                Continue;

            if dPrimePathCR < slValueSublist.Objects[j] - 1 then
            begin
                j := j - 1;
                break;
            end;

            break;
        end;

        dPath2T := dPath2T + j;
    end;

    dPath2A := dPath2T / slPath2.Count;

    if iTier < dPath2A - 10 then
        iTier := iTier - 3
    else
        if iTier < dPath2A - 7 then
            iTier := iTier - 2
        else
            if iTier < dPath2A - 3 then
                iTier := iTier - 1
            else
                if iTier > dPath2A + 10 then
                    iTier := iTier + 3
                else
                    if iTier < dPath2A + 7 then
                        iTier := iTier + 2
                    else
                        if iTier < dPath2A + 3 then
                            iTier := iTier + 1;

    addMessage('with alternative slPaths, iTier is now ' + iTier);
end;

function TemplateListSelector(aRecord: IInterface): TStringList;
var
    slValues: TStringList;
    i       : integer;
begin
    // 2 options, find first applicable template section based on aIdents
    // find the most applicable. first easier.
    for i := 0 to Pred(TemplateMegaListvar.Count) do
    begin
        slValues := TemplateMegaListvar.Objects[i];

        if not StrWithinSL(Signature(aRecord), slValues.Objects[slValues.IndexOf('grup')]) then
            Continue;

        if not HasIdent(aRecord, slValues.Objects[slValues.IndexOf('identifier')]) then
            Continue;

        result := slValues;
        exit;
    end;
end;

function HasAKeyword(aRecord: IInterface; aKeywords: TStringList): boolean;
var
    bDebug     : boolean;
    kTempRecord: IInterface;
    i          : integer;
    j          : integer;
begin
    // Begin debugMsg section
    bDebug := false;

    result := false;

    kTempRecord := ElementBySignature(aRecord, 'KWDA');

    for i := 0 to Pred(ElementCount(kTempRecord)) do
    begin
        for j := 0 to Pred(aKeywords.Count) do
        begin
            if bDebug then
                addMessage('[HasAKeyword] if (' + EditorID(LinksTo(elementbyindex(kTempRecord, i))) + ' = ' + aKeywords[j] + ' ) then begin');

            if SameText(EditorID(LinksTo(elementbyindex(kTempRecord, i))), aKeywords[j]) then
            begin
                if bDebug then
                    addMessage('[HasAKeyword] Result := True');

                result := true;
                exit;
            end;
        end;
    end;

    bDebug := false;
    // End debugMsg section
end;

function HasIdent(aRecord: IInterface; aIdents: TStringList): boolean;
var
    sTempEDID: string;
    sTempName: string;
    i        : integer;
begin
    sTempEDID := EditorID(aRecord);
    sTempName := DisplayName(aRecord);

    result := false;

    for i := Pred(aIdents.Count) downto 0 do
        if ContainsText(sTempEDID, aIdents[i]) or ContainsText(sTempName, aIdents[i]) then
        begin
            result := true;
            exit;
        end;
end;

// gets templetes for books
// todo fix paths for SPIT\Half-cost Perk and SPIT/BASE COST
function BookTemplate(bookRecord: IInterface): IInterface;
var
    books, flags, tempSpellRecord: IInterface;
    halfCostPerk                 : string;
begin
    if (GetEditValue(ElementByPath(selectedRecord, 'DATA\Flags\Teaches spell'))) = '1' then
    begin                                                                            // checks if book is tome
        tempSpellRecord := LinksTo(ElementByPath(bookRecord, 'DATA\Flags\Teaches')); // spell from tome
        if not(LinksTo(ElementByPath(tempSpellRecord, 'SPIT\Half-cost Perk')) = nil) then
        begin
            halfCostPerk := GetElementEditValues(tempSpellRecord, 'SPIT\Half-cost Perk');
            { Debug } addMessage('halfCostPerk' + halfCostPerk);
            case extractInts(halfCostPerk, 1) of
                00:
                    begin
                        case ElementByPath(halfCostPerk, 'Novice', true) of
                            'Alteration':
                                result := getRecordByFormID('0009E2A7');
                            'Conjuration':
                                result := getRecordByFormID('0009E2AA');
                            'Destruction':
                                result := getRecordByFormID('0009CD52');
                            'Illusion':
                                result := getRecordByFormID('0009E2AD');
                            'Restoration':
                                result := getRecordByFormID('0009E2AE');
                        end;
                    end;
                25:
                    begin
                        case ElementByPath(halfCostPerk, 'Apprentice', true) of
                            'Alteration':
                                result := getRecordByFormID('000A26E3');
                            'Conjuration':
                                result := getRecordByFormID('0009CD54');
                            'Destruction':
                                result := getRecordByFormID('000A2702');
                            'Illusion':
                                result := getRecordByFormID('000A270F');
                            'Restoration':
                                result := getRecordByFormID('000A2720');
                        end;
                    end;
                50:
                    begin
                        case ElementByPath(halfCostPerk, 'Adept', true) of
                            'Alteration':
                                result := getRecordByFormID('000A26E7');
                            'Conjuration':
                                result := getRecordByFormID('000A26EE');
                            'Destruction':
                                result := getRecordByFormID('000A2708');
                            'Illusion':
                                result := getRecordByFormID('000A2714');
                            'Restoration':
                                result := getRecordByFormID('0010F64D');
                        end;
                    end;
                75:
                    begin
                        case ElementByPath(halfCostPerk, 'Expert', true) of
                            'Alteration':
                                result := getRecordByFormID('000A26E8');
                            'Conjuration':
                                result := getRecordByFormID('000A26F7');
                            'Destruction':
                                result := getRecordByFormID('0010F7F4');
                            'Illusion':
                                result := getRecordByFormID('000A2718');
                            'Restoration':
                                result := getRecordByFormID('000A2729');
                        end;
                    end;
                100:
                    begin
                        case ElementByPath(halfCostPerk, 'Master', true) of
                            'Alteration':
                                result := getRecordByFormID('000DD646');
                            'Conjuration':
                                result := getRecordByFormID('000A26FA');
                            'Destruction':
                                result := getRecordByFormID('000A270D');
                            'Illusion':
                                result := getRecordByFormID('000A2719');
                            'Restoration':
                                result := getRecordByFormID('000FDE7B');
                        end;
                    end;
            end;
        end else begin // uses restoration books as level list base
            case StrToInt(GetElementEditValues(tempSpellRecord, 'SPIT/BASE COST')) of
                0 .. 96:
                    result := getRecordByFormID('0009E2AE'); // novice
                97 .. 156:
                    result := getRecordByFormID('000A2720'); // aprentice
                157 .. 250:
                    result := getRecordByFormID('0010F64D'); // adept
                251 .. 644:
                    result := getRecordByFormID('000A2729'); // expert
            else
                result := getRecordByFormID('000FDE7B'); // master
            end;
        end;
    end;
end;

// extracts the specified integer (Natural Numbers only) from an input; returns -1 if no suitable number is not found
// O(10n) time complexity n =input string length
function extractInts(inputString: string; intToPull: integer): integer; // tested and works
const
    ints = '1234567890';
var
    i, j, currentInt: integer;
    flag1, flag2    : boolean;
    resultString    : string;
begin
    resultString := '';
    currentInt   := 0;
    flag1        := true;
    flag2        := true;
    for i        := 0 to (Length(inputString) - 1) do
    begin
        j := 0;
        while j < 10 do
        begin
            if Copy(inputString, i + 1, 1) = Copy(ints, j + 1, 1) then
            begin
                if flag1 then
                    currentInt := currentInt + 1;
                if (currentInt = intToPull) then
                    resultString := resultString + Copy(inputString, i + 1, 1);
                flag1            := false;
                flag2            := false;
                break;
            end;
            j := j + 1;
        end;
        if flag2 then
            flag1 := true;
        flag2     := true;
    end;
    if not(resultString = '') then
        result := StrToInt(resultString)
    else
        result := -1
end;

// Gets a HexFormID
function HexFormID(e: IInterface): string;
begin
    result := IntToHex(GetLoadOrderFormID(e), 8);
end;

// Adds requirement 'HasPerk' to Conditions list [SkyrimUtils]
function addPerkCondition(aList: IInterface; aPerk: IInterface): IInterface;
var
    newCondition, tempRecord: IInterface;
begin
    // Begin debugMsg section
    
    if not(name(aList) = 'Conditions') then
    begin
        if Signature(aList) = 'COBJ' then
        begin // record itself was provided
            tempRecord := ElementByPath(aList, 'Conditions');
            if not Assigned(tempRecord) then
            begin
                Add(aList, 'Conditions', true);
                aList        := ElementByPath(aList, 'Conditions');
                newCondition := elementbyindex(aList, 0); // xEdit will create dummy condition if new list was added
            end
            else
                aList := tempRecord;
        end;
    end;
    if not Assigned(newCondition) then
        newCondition := ElementAssign(aList, HighInteger, nil, false);
    // set type to Equal to
    SetElementEditValues(newCondition, 'CTDA - \Type', '10000000');
    // set some needed properties
    SetElementEditValues(ElementByPath(newCondition, 'CTDA'), 'Type', '10000000');
    SetElementEditValues(ElementByPath(newCondition, 'CTDA'), 'Comparison Value', '1');
    SetElementEditValues(ElementByPath(newCondition, 'CTDA'), 'Function', 'HasPerk');
    SetElementEditValues(ElementByPath(newCondition, 'CTDA'), 'Perk', GetEditValue(aPerk));
    SetElementEditValues(ElementByPath(newCondition, 'CTDA'), 'Run On', 'Subject');
    SetElementEditValues(ElementByPath(newCondition, 'CTDA'), 'Parameter #3', '-1');
    //RemoveInvalidEntries(aList);
    result   := newCondition;
    
    // End debugMsg section
end;

// Gets the relevant game value
function GetGameValue(aRecord: IInterface): string;
var
    slTemp  : TStringList;
    i       : integer;
begin
    // Initialize
    
    slTemp   := TStringList.Create;
    { Debug } if debugMsg then
        addMessage('GetGameValue(' + EditorID(aRecord) + ' );');

    // Function
    slTemp.CommaText := 'Circlet, Ring, Necklace';
    if (Signature(aRecord) = 'ARMO') then
    begin
        for i := 0 to slTemp.Count - 1 do
        begin
            if ContainsText(full(aRecord), slTemp[i]) or ContainsText(ItemKeyword(aRecord), slTemp[i]) or HasKeyword(aRecord, ('Clothing' + slTemp[i])) then
            begin
                result := GetElementEditValues(aRecord, 'DATA\Value');
                exit
            end;
        end;
        result := StrPosCopy(GetElementEditValues(aRecord, 'DNAM'), '.', true);
        exit;
    end
    else
        if (Signature(aRecord) = 'AMMO') then
        begin
            result := StrPosCopy(GetElementEditValues(aRecord, 'DATA\Damage'), '.', true);
            exit;
        end else begin
            result := GetElementEditValues(aRecord, 'DATA\Damage');
            exit;
        end;

    // Finalize
    slTemp.Free;
end;

// Gets the relevant game value type
function GetGameValueType(inputRecord: IInterface): string;
var
    slTemp: TStringList;
    i     : integer;
begin
    // Initialize
    slTemp := TStringList.Create;

    // Function
    slTemp.CommaText := 'Circlet, Ring, Necklace';
    if Signature(inputRecord) = 'ARMO' then
    begin
        for i := 0 to slTemp.Count - 1 do
        begin
            if ContainsText(GetElementEditValues(inputRecord, 'FULL'), slTemp[i]) or ContainsText(ItemKeyword(inputRecord), slTemp[i]) or (ItemKeyword(inputRecord) = ('Clothing' + slTemp[i])) then
            begin
                result := 'DATA\Value';
                exit;
            end;
        end;
        result := 'DNAM';
        exit;
    end else begin
        result := 'DATA\Damage';
        exit;
    end;

    // Finalize
    slTemp.Free;
end;

// Removes spaces from a string
function RemoveSpaces(inputString: string): string;
var
    tempString: string;
begin
    // Begin debugMsg Section
     { Debug }
    if debugMsg then
        addMessage('[RemoveSpaces] Trim(inputString := ' + inputString + ')');
    Trim(inputString); { Debug }
    if debugMsg then
        addMessage('[RemoveSpaces] tempString := inputString);');
    while (rPos(inputString, ' ') > 0) do
    begin
        { Debug } if debugMsg then
            addMessage('[RemoveSpaces] while (rPos(inputString, ' ') := ' + IntToStr(rPos(inputString, ' ')) + ' > 0) do begin');
        { Debug } if debugMsg then
            addMessage('[RemoveSpaces] inputString := ' + inputString);
        { Debug } if debugMsg then
            addMessage('[RemoveSpaces] tempString := ' + tempString);
        Delete(inputString, rPos(inputString, ' '), 1);
    end;
    { Debug } if debugMsg then
        addMessage('Result := ' + inputString);
    result   := inputString;
    
    // End debugMsg Section
end;

// Checks if a level list contains a record
function LLcontains(aLevelList, aRecord: IInterface): boolean;
var
    i       : integer;
begin
    // Begin debugMsg Section
    
    result   := false;
    { Debug } if debugMsg then
        addMessage('[LLcontains] LLcontains(' + EditorID(aLevelList) + ', ' + EditorID(aRecord) + ' );');
    for i := 0 to Pred(LLec(aLevelList)) do
    begin
        { Debug } if debugMsg then
            addMessage('[LLcontains] LLelementbyindex := ' + EditorID(LLelementbyindex(aLevelList, i)));
        // nb097 - Can't use ContainsText here - for group replacement this will always return true (group name is same EDID + '_Group')
        // if ContainsText(EditorID(LLebi(aLevelList, i)), EditorID(aRecord)) then begin
        if SameText(EditorID(LLelementbyindex(aLevelList, i)), EditorID(aRecord)) then
        begin
            { Debug } if debugMsg then
                addMessage('[LLcontains] if ' + EditorID(LLelementbyindex(aLevelList, i)) + ' = ' + EditorID(aRecord) + ' then begin');
            { Debug } if debugMsg then
                addMessage('[LLcontains] Result := True');
            result := true;
            exit;
        end;
    end;
    if debugMsg then
        addMessage('[LLcontains] Result := False');
    
    // End debugMsg Section
end;

// Removes a LL entry; Returns removed element
function LLremove(aLevelList, aRecord): IInterface;
var
    i       : integer;
begin
    for i := 0 to Pred(LLec(aLevelList)) do
    begin
        if ContainsText(LLelementbyindex(aLevelList, i), EditorID(aRecord)) then
        begin
            result := LLelementbyindex(aLevelList, i);
            Remove(elementbyindex(ElementByPath(aLevelList, 'Leveled List Entries'), i));
        end;
    end;
end;

// Finds the nth record in a level list
function IndexOfLL(aLevelList, aRecord): integer;
var
    i       : integer;
begin
    // Begin debugMsg Section
    
    result   := false;
    for i    := 0 to Pred(LLec(aLevelList)) do
    begin
        if debugMsg then
            addMessage('[IndexOfLL] if ' + GetElementEditValues(elementbyindex(ElementByPath(aLevelList, 'Leveled List Entries'), i), 'LVLO\Reference') + ', ' + ShortName(aRecord) + ' then begin');
        if ContainsText(GetElementEditValues(elementbyindex(ElementByPath(aLevelList, 'Leveled List Entries'), i), 'LVLO\Reference'), EditorID(aRecord)) then
        begin
            result := i;
            exit;
        end;
    end;
    
    // End debugMsg Section
end;

// Replaces aRecord with bRecord in aLevelList; Adds bRecord to aLevelList if aRecord is not detected; Returns true if replaced, false if added
function LLreplace(aLevelList, aRecord, bRecord: IInterface): boolean;
var
    i       : integer;
begin
    // Begin debugMsg Section
    

    result := false;
    for i  := 0 to Pred(LLec(aLevelList)) do
    begin
        { Debug } if debugMsg then
            addMessage('[LLreplace] ' + GetElementEditValues(elementbyindex(ElementByPath(aLevelList, 'Leveled List Entries'), i), 'LVLO\Reference'));
        if ContainsText(GetElementEditValues(elementbyindex(ElementByPath(aLevelList, 'Leveled List Entries'), i), 'LVLO\Reference'), EditorID(aRecord)) then
        begin
            { Debug } if debugMsg then
                addMessage('[LLreplace] SetEditValue(' + GetElementEditValues(elementbyindex(ElementByPath(aLevelList, 'Leveled List Entries'), i), 'LVLO\Reference') + ', ' + ShortName(bRecord) + ');');
            SetEditValue(ElementByPath(elementbyindex(ElementByPath(aLevelList, 'Leveled List Entries'), i), 'LVLO\Reference'), ShortName(bRecord));
            { Debug } if debugMsg then
                addMessage('[LLreplace] ' + EditorID(LLelementbyindex(aLevelList, i)) + ' = ' + EditorID(aRecord));
            exit;
        end;
    end;
    // addToLeveledList(aLevelList, bRecord, 1);
    // {Debug} if debugMsg then addMessage('[LLreplace] addToLeveledList('+EditorID(aLevelList)+', '+EditorID(bRecord)+', 1);');

    
    // End debugMsg Section
end;

// Check a records Flags for aFlag
function FlagCheck(aRecord: IInterface; aFlag: string): boolean;
begin
    result := false;
    if ElementExists(aRecord, 'LVLF') then                                           // If this record has a 'Flags' section
        if ElementExists(ElementByPath(aRecord, 'LVLF'), aFlag) then                 // If this record has the flag, 'aFlag'
            result := GetElementNativeValues(ElementByPath(aRecord, 'LVLF'), aFlag); // Return an integer value for this flag.  IIRC it's a binary for Flag on/off
end;

// Creates new record inside provided file [Skyrim Utils]
function createRecord(recordFile: IwbFile; recordSignature: string): IInterface;
var
    newRecordGroup: IInterface;
begin
    newRecordGroup := GroupBySignature(recordFile, recordSignature);
    if not Assigned(newRecordGroup) then
        newRecordGroup := Add(recordFile, recordSignature, true);
    result             := Add(newRecordGroup, recordSignature, true);
end;

// Removes invalid entries from containers and recipe items, from Leveled lists, npcs and spells [SkyrimUtils]
procedure RemoveInvalidEntries(aRecord: IInterface);
var
    record_sig, refName, countname: string;
    aList, tempRecord             : IInterface;
    i, aList_ec                   : integer;
begin
    // Initialize
    

    // Process
    record_sig := Signature(aRecord);
    // Assign areas to look through given signature
    if (record_sig = 'CONT') or (record_sig = 'COBJ') then
    begin
        aList     := ElementByName(aRecord, 'Items');
        refName   := 'CNTO\Item';
        countname := 'COCT';
    end
    else
        if (record_sig = 'LVLI') or (record_sig = 'LVLN') or (record_sig = 'LVSP') then
        begin
            aList     := ElementByName(aRecord, 'Leveled List Entries');
            refName   := 'LVLO\Reference';
            countname := 'LLCT';
        end
        else
            if (record_sig = 'OTFT') then
            begin
                aList   := ElementByName(aRecord, 'INAM');
                refName := 'item';
            end
            else
                if (record_sig = 'ARMA') then
                begin
                    aList := ElementByPath(aRecord, 'Additional Races');
                end;
    if not Assigned(aList) then
        exit;
    aList_ec := ElementCount(aList);
    for i    := aList_ec - 1 downto 0 do
    begin
        tempRecord := elementbyindex(aList, i);
        { Debug } if debugMsg then
            addMessage('[removeInvalidEntries] aList tempRecord := ' + GetEditValue(tempRecord));
        if (refName <> '') then
        begin
            if (Check(ElementByPath(tempRecord, refName)) <> '') then
                Remove(tempRecord);
        end else begin
            if (GetEditValue(tempRecord) = 'NULL - Null Reference [00000000]') then
                Remove(tempRecord);
        end;
    end;
    if Assigned(countname) then
    begin
        if (aList_ec <> ElementCount(aList)) then
        begin
            aList_ec := ElementCount(aList);
            if (aList_ec > 0) then
                SetElementNativeValues(aRecord, countname, aList_ec)
            else
                RemoveElement(aRecord, countname);
        end;
    end;
end;

// Remove invalid entries from containers (experimental)
procedure removeErrors(aRecord: IInterface);
var
    tempRecord, tempelement, currentElement: IInterface;
    slProcess                              : TStringList;
    i, x                                   : integer;
begin
    // Initialize
    
    slProcess := TStringList.Create;

    // Process
    for i := 0 to Pred(ElementCount(aRecord)) do
        slProcess.addObject(FullPath(elementbyindex(aRecord, i)), elementbyindex(aRecord, i));
    while (slProcess.Count > 0) do
    begin
        tempelement := ObjectToElement(slProcess.Objects[0]);
        { Debug } if debugMsg then
            addMessage('[removeErrors] tempElement := ' + name(tempelement));
        for i := 0 to Pred(ElementCount(tempelement)) do
        begin
            currentElement := elementbyindex(tempelement, i);
            { Debug } if debugMsg then
                addMessage('[removeErrors] currentElement := ' + name(currentElement));
            { Debug } if debugMsg then
                addMessage('[removeErrors] if not ContainsText(' + GetEditValue(currentElement) + ', Error) then begin);');
            if not ContainsText(GetEditValue(currentElement), 'Error') then
            begin
                if (ElementCount(currentElement) > 0) then
                begin
                    { Debug } if debugMsg then
                        addMessage('[removeErrors] slProcess.AddObject(' + name(currentElement) + ' );');
                    slProcess.addObject(FullPath(currentElement), currentElement);
                end;
            end else begin
                if (name(currentElement) = 'Item') then
                begin
                    addMessage('[removeErrors] ' + GetEditValue(currentElement) + ' Removed from ' + name(aRecord));
                    Remove(GetContainer(GetContainer(currentElement)));
                end else begin
                    addMessage('[removeErrors] ' + GetEditValue(currentElement) + ' Removed from ' + name(aRecord));
                    Remove(currentElement);
                end;
            end;
        end;
        // {Debug} if debugMsg then addMessage('[removeErrors] slProcess.Delete('+slProcess[0]+' );');
        slProcess.Delete(0);
    end;

    // Finalize
    slProcess := TStringList.Create;
end;

// Adds item record reference to the list [SkyrimUtils]
function addItem(aRecord: IInterface; aItem: IInterface; aCount: integer): IInterface;
var
    tempRecord: IInterface;
begin
    // Begin debugMsg section
    

    if not Assigned(ElementByPath(aRecord, 'Items')) then
        Add(aRecord, 'Items', true);
    tempRecord := ElementAssign(ElementByPath(aRecord, 'Items'), HighInteger, nil, false);
    SetElementEditValues(tempRecord, 'CNTO - Item\Item', name(aItem));
    SetElementEditValues(tempRecord, 'CNTO - Item\Count', aCount);
    result := tempRecord;

    
    // End debugMsg section
end;

// Adds it
// Adds item reference to the leveled list [SkyrimUtils]
// nb097 - renamed tempBoolean to newList
function addToLeveledList(aLeveledList, aRecord: IInterface; aLevel: integer): IInterface;
var
    tempRecord, currentList   : IInterface;
    i, tempInteger            : integer;
    tempString, previousRecord: string;
    newList         : boolean;
    slTemp                    : TStringList;
begin
    // Begin debugMgs section
    
    // nb097 - moved below line up so the debug message can show the editor ID of the current list
    currentList := aLeveledList;
    { Debug } if debugMsg then
        addMessage('[addToLeveledList] addToLeveledList(' + EditorID(currentList) + ', ' + EditorID(aRecord) + ', ' + IntToStr(aLevel) + ');');

    slTemp           := TStringList.Create;
    slTemp.CommaText := '"Calculate from all levels <= player''s level", "Calculate for each item in count"';

    // Check for leveled lists exceeding maximum entries
    // nb097 - may not be necessary: changed to 200; to accommodate for other mods adding to LL's via scripts
    while (LLec(currentList) >= 200) do
    begin
        // nb097 - reworked logic here to account for needing to expand beyond 9 lists
        if StrEndsWithInteger(previousRecord) then
        begin

            if StrEndsWith(EditorID(currentList), '9') then
            begin
                // nb097 - Is the second to last character an integer?
                if StrEndsWithInteger(RemoveFinalCharacter(EditorID(currentList))) then
                begin
                    tempString := Copy(EditorID(currentList), Length(EditorID(currentList)) - 1, 2) + IntToStr((StrToInt(Copy(EditorID(currentList), Length(EditorID(currentList)) - 1, 2)) + 1));
                    // nb097 - If not, add '10'
                end
                else
                    tempString := EditorID(currentList) + '10';
            end
            else
                tempString := RemoveFinalCharacter(EditorID(currentList)) + IntToStr((StrToInt(FinalCharacter(EditorID(currentList))) + 1));
        end
        else
            tempString := EditorID(currentList) + '1';

        { Debug } if debugMsg then
            addMessage('[addToLeveledList] addToLeveledList(' + EditorID(currentList) + ', ' + EditorID(aRecord) + ', ' + IntToStr(aLevel) + ') - tempString: ' + tempString);
        tempRecord := MainRecordByEditorID(GroupBySignature(GetFile(currentList), 'LVLI'), tempString);

        // nb097 - moved createLeveledList call out of if block; only create if not found
        if Assigned(tempRecord) then
        begin
            { Debug } if debugMsg then
                addMessage('[addToLeveledList] addToLeveledList(' + EditorID(currentList) + ', ' + EditorID(aRecord) + ', ' + IntToStr(aLevel) + ') - LL: ' + tempString + ' found!');
            currentList := tempRecord;
            // nb097 - added renamed bool variable to signify new list or not
            newList := false;
        end else begin
            currentList := createLeveledList(GetFile(currentList), tempString, slTemp, 0);
            { Debug } if debugMsg then
                addMessage('[addToLeveledList] addToLeveledList(' + EditorID(currentList) + ', ' + EditorID(aRecord) + ', ' + IntToStr(aLevel) + ') - LL: ' + tempString + ' created!');
            // nb097 - added renamed bool variable to signify new list or not
            newList := true;
        end;

        // If a sequential leveled list is found or there's an infinite loop create a new leveled list
        // nb097 - may not be necessary: changed to 200; to accommodate for other mods adding to LL's via scripts
        if (LLec(currentList) <= 200) or (previousRecord = EditorID(currentList)) then
        begin

            // Remove trailing integers
            while StrEndsWithInteger(tempString) do
            begin
                tempString := RemoveFinalCharacter(tempString);
            end;

            // Check for an existing group containing this leveled list
            tempString := tempString + '_Group';
            tempRecord := nil;
            tempRecord := MainRecordByEditorID(GroupBySignature(GetFile(currentList), 'LVLI'), tempString);

            // Add to exisitng group or create new group and run a replacement
            if Assigned(tempRecord) then
            begin
                { Debug } if debugMsg then
                    addMessage('[addToLeveledList] addToLeveledList(' + EditorID(currentList) + ', ' + EditorID(aRecord) + ', ' + IntToStr(aLevel) + ') - LL group: ' + tempString + ' found!');
                // nb097 - if new list, THEN add to group, not always
                if newList then
                begin
                    addToLeveledList(tempRecord, currentList, 1);
                    { Debug } if debugMsg then
                        addMessage('[addToLeveledList] addToLeveledList(' + EditorID(currentList) + ', ' + EditorID(aRecord) + ', ' + IntToStr(aLevel) + ') - LL group: ' + tempString + ' added ' + EditorID(currentList) + '!');
                end;
            end else begin
                tempRecord := createLeveledList(GetFile(currentList), tempString, slTemp, 0);
                { Debug } if debugMsg then
                    addMessage('[addToLeveledList] addToLeveledList(' + EditorID(currentList) + ', ' + EditorID(aRecord) + ', ' + IntToStr(aLevel) + ') - LL group: ' + tempString + ' created!');
                addToLeveledList(tempRecord, currentList, 1);
                { Debug } if debugMsg then
                    addMessage('[addToLeveledList] addToLeveledList(' + EditorID(currentList) + ', ' + EditorID(aRecord) + ', ' + IntToStr(aLevel) + ') - LL group: ' + tempString + ' added ' + EditorID(currentList) + '!');
                addToLeveledList(tempRecord, aLeveledList, 1);
                { Debug } if debugMsg then
                    addMessage('[addToLeveledList] addToLeveledList(' + EditorID(currentList) + ', ' + EditorID(aRecord) + ', ' + IntToStr(aLevel) + ') - LL group: ' + tempString + ' added ' + EditorID(aLeveledList) + '!');
                ReplaceInLeveledListAuto(aLeveledList, tempRecord, GetFile(aLeveledList));
                { Debug } if debugMsg then
                    addMessage('[addToLeveledList] addToLeveledList(' + EditorID(currentList) + ', ' + EditorID(aRecord) + ', ' + IntToStr(aLevel) + ') - LL group: ' + tempString + ' replaced ' + EditorID(aLeveledList) + ' with ' + EditorID(currentList) + '!');
            end;
            break;
        end;
        previousRecord := EditorID(currentList); // Prevent infinite loop
    end;

    slTemp.Free;
    tempRecord := ElementAssign(ElementByPath(currentList, 'Leveled List Entries'), HighInteger, nil, false);
    BeginUpdate(tempRecord);
    try
        SetElementEditValues(tempRecord, 'LVLO\Reference', name(aRecord));
        SetElementEditValues(tempRecord, 'LVLO\Count', 1);
        SetElementEditValues(tempRecord, 'LVLO\Level', aLevel);
    finally
        EndUpdate(tempRecord);
    end;
    result := tempRecord;

    
    // End debugMsg section
end;

// Creates COBJ record for item [SkyrimUtils]
function createRecipe(aRecord, aPlugin: IInterface): IInterface;
var
    recipe: IInterface;
begin
    recipe := createRecord(aPlugin, 'COBJ');
    SetElementEditValues(recipe, 'CNAM', name(aRecord));
    SetElementEditValues(recipe, 'NAM1', '1');
    Add(aRecord, 'items', true);
    result := recipe;
end;

// Gets an item type for slFuzzyItem
function GetItemType(aRecord: IInterface): string;
var
    slTemp, slBOD2: TStringList;
    i             : integer;
begin
    // End debugMsg section
    

    // Initialize
    { Debug } if debugMsg then
        addMessage('[GetItemType] GetItemType(' + EditorID(aRecord) + ' );');
    slTemp := TStringList.Create;
    slBOD2 := TStringList.Create;

    // Function
    if (Signature(aRecord) = 'WEAP') then
    begin
        slTemp.CommaText := 'Sword, Bow, WarAxe, Dagger, Greatsword, Mace, Warhammer, Battleaxe';
        // Prioritize keywords
        for i := 0 to slTemp.Count - 1 do
        begin
            if HasKeyword(aRecord, 'WeapType' + slTemp[i]) then
            begin
                result := slTemp[i];
                if debugMsg then
                    addMessage('[GetItemType] ' + result + ' Detected');
                slTemp.Free;
                slBOD2.Free;
                exit;
            end;
        end;
        // Check edid/GetElementEditValues for keywords
        for i := 0 to slTemp.Count - 1 do
        begin
            if ContainsText(full(aRecord), slTemp[i]) or ContainsText(EditorID(aRecord), slTemp[i]) then
            begin
                // Exception for the string 'Sword' being within the string 'Greatsword'
                if (slTemp[i] = 'Sword') then
                    if ContainsText(full(aRecord), 'Greatsword') or ContainsText(EditorID(aRecord), 'Greatsword') then
                        Continue;
                result := slTemp[i];
                if debugMsg then
                    addMessage('[GetItemType] ' + result + ' Detected');
                slTemp.Free;
                slBOD2.Free;
                exit;
            end;
        end;
        // Broad Default values based on skill/animation style
        if ContainsText(GetEditValue(ElementByPath(ElementBySignature(aRecord, 'DNAM'), 'Animation Type')), 'TwoHand') or ContainsText(GetEditValue(ElementByPath(ElementBySignature(aRecord, 'DNAM'), 'Skill')), 'TwoHand') then
        begin
            result := slTemp[slTemp.Count - 1];
        end
        else
            if ContainsText(GetEditValue(ElementByPath(ElementBySignature(aRecord, 'DNAM'), 'Animation Type')), 'Bow') or ContainsText(GetEditValue(ElementByPath(ElementBySignature(aRecord, 'DNAM'), 'Skill')), 'Archery') then
            begin
                result := slTemp[1];
            end else begin
                result := slTemp[0];
            end;
    end
    else
        if (Signature(aRecord) = 'AMMO') then
        begin
            // Get selected record type
            slTemp.CommaText := 'Arrow, Bolt';
            // Prioritize keywords
            for i := 0 to slTemp.Count - 1 do
            begin
                if HasKeyword(aRecord, 'WeapType' + slTemp[i]) then
                begin
                    result := slTemp[i];
                    if debugMsg then
                        addMessage('[GetItemType] ' + result + ' Detected');
                    slTemp.Free;
                    slBOD2.Free;
                    exit;
                end;
            end;
            // Check edid/GetElementEditValues for keywords
            for i := 0 to slTemp.Count - 1 do
            begin
                if ContainsText(Name(aRecord), slTemp[i]) or ContainsText(EditorID(aRecord), slTemp[i]) then
                begin
                    result := slTemp[i];
                    if debugMsg then
                        addMessage('[GetItemType] ' + result + ' Detected');
                    slTemp.Free;
                    slBOD2.Free;
                    exit;
                end;
            end;
            // Broad default value
            result := slTemp[0];
        end
        else
            if (Signature(aRecord) = 'ARMO') then
            begin
                // '30, 32, 33, 37, 39'; // 30 - Head, 32 - Body, 33 - Gauntlers, 37 - Feet, 39 - Shield
                slGetFlagValues(aRecord, slBOD2, false);
                { Debug } if debugMsg then
                    msgList('[Tier Assignment] slBOD2 := ', slBOD2, '');
                slTemp.CommaText := '30, 32, 33, 37, 39, 35, 36, 42'; // 30 - Head, 32 - Body, 33 - Gauntlets, 37 - Feet, 39 - Shield, 35 - Necklace, 36 - Ring, 42 - Circlet
                // For vanilla slots
                for i := 0 to slTemp.Count - 1 do
                begin
                    if slContains(slBOD2, slTemp[i]) then
                    begin
                        // This 'if' covers certain mods that change helmet BOD2
                        if (slTemp[i] = '42') then
                            if Assigned(ElementByPath(aRecord, 'DNAM')) then
                                if (GetElementEditValues(aRecord, 'DNAM') > 0) then
                                    result := '30';
                        if not Assigned(result) then
                            result := slTemp[i];
                        break;
                    end;
                end;
                // Non-vanilla slots prioritize keywords
                if debugMsg then
                    addMessage('[GetItemType] Non-vanilla slots prioritize keywords');
                if (result = '') then
                begin
                    { Debug } if debugMsg then
                        addMessage('[GetTemplate] Check Keywords');
                    for i := 0 to Pred(ElementCount(ElementByPath(aRecord, 'KWDA'))) do
                    begin
                        { Debug } if debugMsg then
                            addMessage('[GetTemplate] Keyword := ' + GetEditValue(elementbyindex(ElementByPath(aRecord, 'KWDA'), i)));
                        result := KeywordToBOD2(GetEditValue(elementbyindex(ElementByPath(aRecord, 'KWDA'), i)));
                        if (result <> '') then
                            break;
                    end;
                end;
                // Default BOD2 for items without keywords
                if debugMsg then
                    addMessage('[GetItemType] Default BOD2 for items without keywords');
                if (result = '') then
                begin
                    { Debug } if debugMsg then
                        addMessage('[GetTemplate] Check Non-Vanilla BOD2');
                    // Helmet
                    slTemp.CommaText := '31, 41, 55, 130, 131, 141, 150, 230';
                    for i            := 0 to slTemp.Count - 1 do
                        if slContains(slBOD2, slTemp[i]) then
                            result := '30';
                    // Body
                    slTemp.CommaText := '38, 40, 46, 49, 52, 53, 54, 56';
                    for i            := 0 to slTemp.Count - 1 do
                        if slContains(slBOD2, slTemp[i]) then
                            result := '32';
                    // Gauntlets
                    slTemp.CommaText := '38, 58, 57, 59';
                    for i            := 0 to slTemp.Count - 1 do
                        if slContains(slBOD2, slTemp[i]) then
                            result := '37';
                    // Boots
                    slTemp.CommaText := '34';
                    for i            := 0 to slTemp.Count - 1 do
                        if slContains(slBOD2, slTemp[i]) then
                            result := '33';
                    // Circlet
                    slTemp.CommaText := '43, 142';
                    for i            := 0 to slTemp.Count - 1 do
                    begin
                        if slContains(slBOD2, slTemp[i]) then
                        begin
                            result := '42';
                            if Assigned(ElementByPath(aRecord, 'DNAM')) then
                                if (GetElementEditValues(aRecord, 'DNAM') > 0) then
                                    result := '30';
                        end;
                    end;
                    // Necklace
                    slTemp.CommaText := '44, 45, 47, 143';
                    for i            := 0 to slTemp.Count - 1 do
                        if slContains(slBOD2, slTemp[i]) then
                            result := '35';
                    // Ring
                    slTemp.CommaText := '48, 60';
                    for i            := 0 to slTemp.Count - 1 do
                        if slContains(slBOD2, slTemp[i]) then
                            result := '36';
                end;
                // Convert BOD2 to EditorID
                { Debug } if debugMsg then
                    addMessage('[GetTemplate] Convert BOD2 to EditorID');
                slTemp.CommaText := '30-Helmet, 32-Cuirass, 33-Gauntlets, 37-Boots, 39-Shield, 35-Necklace, 36-Ring, 42-Circlet'; // 30 - Head, 32 - Body, 33 - Gauntlets, 37 - Feet, 39 - Shield, 35 - Necklace, 36 - Ring, 42 - Circlet
                for i            := 0 to slTemp.Count - 1 do
                begin
                    if ContainsText(slTemp[i], result) then
                    begin
                        result := StrPosCopy(slTemp[i], '-', false);
                        // addMessage('['+GetElementEditValues(aRecord)+'] '+Result+' Detected');
                        break;
                    end;
                end;
            end;

    // Finalize
    slTemp.Free;

    
    // End debugMsg section
end;

// Reduces a BOD2 to an associated BOD2
function AssociatedBOD2(aString: string): string;
var
    slTemp: TStringList;
    i     : integer;
begin
    slTemp := TStringList.Create;

    result := aString;
    // Helmet
    slTemp.CommaText := '31, 41, 55, 130, 131, 141, 150, 230';
    for i            := 0 to slTemp.Count - 1 do
        if (aString = slTemp[i]) then
            result := '30';
    // Body
    slTemp.CommaText := '38, 40, 46, 49, 52, 53, 54, 56';
    for i            := 0 to slTemp.Count - 1 do
        if (aString = slTemp[i]) then
            result := '32';
    // Gauntlets
    slTemp.CommaText := '38, 58, 57, 59';
    for i            := 0 to slTemp.Count - 1 do
        if (aString = slTemp[i]) then
            result := '37';
    // Boots
    slTemp.CommaText := '34';
    for i            := 0 to slTemp.Count - 1 do
        if (aString = slTemp[i]) then
            result := '33';
    // Circlet
    slTemp.CommaText := '43, 142';
    for i            := 0 to slTemp.Count - 1 do
        if (aString = slTemp[i]) then
            result := '42';
    // Necklace
    slTemp.CommaText := '44, 45, 47, 143';
    for i            := 0 to slTemp.Count - 1 do
        if (aString = slTemp[i]) then
            result := '35';
    // Ring
    slTemp.CommaText := '48, 60';
    for i            := 0 to slTemp.Count - 1 do
        if (aString = slTemp[i]) then
            result := '36';

    slTemp.Free;
end;

// Takes a single armor keyword and returns a list of all keywords related to it
procedure slFuzzyItem(aString: string; aList: TStringList);
var
    slTemp  : TStringList;
    i       : integer;
begin
    // Begin debugMsg Section
    

    // Initialize
    { Debug } if debugMsg then
        addMessage('[slFuzzyItem] inputString := ' + aString);
    if not Assigned(slTemp) then
        slTemp := TStringList.Create
    else
        slTemp.clear;

    // Function
    slTemp.CommaText := 'Helmet, Crown, Helm, Hood, Mask, Circlet, Headdress';
    for i            := 0 to slTemp.Count - 1 do
        if aString = slHelmet[i] then
            if not slContains(aList, slHelmet[i]) then
                aList.Add(slHelmet[i]);
    slTemp.CommaText := 'Bracers, Gloves, Gauntlets';
    for i            := 0 to slTemp.Count - 1 do
        if aString = slGauntlets[i] then
            if not slContains(aList, slGauntlets[i]) then
                aList.Add(slGauntlets[i]);
    slTemp.CommaText := 'Boots, Shoes';
    for i            := 0 to slTemp.Count - 1 do
        if aString = slBoots[i] then
            if not slContains(aList, slBoots[i]) then
                aList.Add(slBoots[i]);
    slTemp.CommaText := 'Cuirass, Armor';
    for i            := 0 to slTemp.Count - 1 do
        if aString = slCuirass[i] then
            if not slContains(aList, slCuirass[i]) then
                aList.Add(slCuirass[i]);
    slTemp.CommaText := 'Shield, Buckler';
    for i            := 0 to slTemp.Count - 1 do
        if aString = slShield[i] then
            if not slContains(aList, slShield[i]) then
                aList.Add(slShield[i]);
    { Debug } if debugMsg then
        msgList('[slFuzzyItem] Result := ', aList, '');

    // '30, 32, 33, 37, 39'; // 30 - Head, 32 - Body, 33 - Gauntlers, 37 - Feet, 39 - Shield
    // Finalize
    slTemp.Free;

    
    // End debugMsg Section
end;

// Reduces a list of armor keywords into a single armor keyword
function GetFuzzyItem(aString: string): string;
var
    slTemp  : TStringList;
    i       : integer;
begin
    // Begin debugMsg Section
    

    // Initialize
    { Debug } if debugMsg then
        addMessage('[slFuzzyItem] inputString := ' + aString);
    if not Assigned(slTemp) then
        slTemp := TStringList.Create
    else
        slTemp.clear;

    // Function
    slTemp.CommaText := 'Helmet, Crown, Helm, Hood, Mask, Circlet, Headdress';
    for i            := 0 to slTemp.Count - 1 do
        if aString = slHelmet[i] then
        begin
            result := 'Helmet';
            slTemp.Free;
            exit;
        end;
    slTemp.CommaText := 'Bracers, Gloves, Gauntlets, claws';
    for i            := 0 to slTemp.Count - 1 do
        if aString = slGauntlets[i] then
        begin
            result := 'Gauntlets';
            slTemp.Free;
            exit;
        end;
    slTemp.CommaText := 'Boots, Shoes';
    for i            := 0 to slTemp.Count - 1 do
        if aString = slBoots[i] then
        begin
            result := 'Boots';
            slTemp.Free;
            exit;
        end;
    slTemp.CommaText := 'Cuirass, Armor';
    for i            := 0 to slTemp.Count - 1 do
        if aString = slCuirass[i] then
        begin
            result := 'Cuirass';
            slTemp.Free;
            exit;
        end;
    slTemp.CommaText := 'Shield, Buckler';
    for i            := 0 to slTemp.Count - 1 do
        if aString = slShield[i] then
        begin
            result := 'Shield';
            slTemp.Free;
            exit;
        end;
    { Debug } if debugMsg then
        msgList('[slFuzzyItem] Result := ', aList, '');

    // Finalize
    if Assigned(slTemp) then
        slTemp.Free;

    
    // End debugMsg Section
end;

// Adds a TStringList to an addMessage on a single line
procedure msgList(s1: string; aList: TStringList; s2: string);
var
    i         : integer;
    tempString: string;
begin
    // Begin debugMsg section
    

    if not Assigned(aList) or (aList.Count = 0) then
    begin
        addMessage(s1 + 'EMPTY LIST' + s2);
        exit;
    end;
    for i := 0 to aList.Count - 1 do
    begin
        if (i = 0) then
        begin
            tempString := aList[0];
        end else begin
            tempString := tempString + ', ' + aList[i];
        end;
    end;
    addMessage(s1 + tempString + s2);

    
    // End debugMsg section
end;

// Adds a TStringList and its objects to an addMessage on a single line
procedure msgListObject(s1: string; aList: TStringList; s2: string);
var
    i         : integer;
    tempString: string;
begin
    // Begin debugMsg section
    

    if not Assigned(aList) or (aList.Count = 0) then
    begin
        addMessage(s1 + 'EMPTY LIST' + s2);
        exit;
    end;
    for i := 0 to aList.Count - 1 do
    begin
        if (i = 0) then
        begin
            tempString := aList[0];
        end else begin
            tempString := tempString + ', ' + aList[i] + ' (' + varTypeAsText(aList.Objects[i]) + ')';
        end;
    end;
    addMessage(s1 + tempString + s2);

    
    // End debugMsg section
end;

// Trims all the string in a list
function TrimList(aList: TStringList): TStringList;
var
    i       : integer;
begin
    for i        := 0 to aList.Count - 1 do
        aList[i] := Trim(aList[i]);
    result       := aList;
end;

// Gets ElementCount of the Leveled List Entries
function LLec(e: IInterface): integer;
begin
    result := ElementCount(ElementByPath(e, 'Leveled List Entries'));
end;

// Gets record from leveled list index
function LLelementbyindex(e: IInterface; i: integer): IInterface;
begin
    // Begin debugMsg section
    
    { Debug } if debugMsg then
        addMessage('[LLelementbyindex] e := ' + EditorID(e));
    // {Debug} if debugMsg then addMessage('[LLelementbyindex] elementbyindex := '+GetElementEditValues(elementbyindex(ElementByPath(e, 'Leveled List Entries'), i), 'LVLO\Reference'));
    { Debug } if debugMsg then
        addMessage('[LLelementbyindex] Result := ' + EditorID(LinksTo(ElementByPath(elementbyindex(ElementByPath(e, 'Leveled List Entries'), i), 'LVLO\Reference'))));
    result   := LinksTo(ElementByPath(elementbyindex(ElementByPath(e, 'Leveled List Entries'), i), 'LVLO\Reference'));
    
    // End debugMsg section
end;

// Removes any file suffixes from a File Name
function RemoveFileSuffix(inputString: string): string;
var
    slTemp  : TStringList;
    i       : integer;
begin
    // Begin debugMsg Section
    
    // Initialize
    { Debug } if debugMsg then
        addMessage('[RemoveFileSuffix] inputString := ' + inputString);
    if not Assigned(slTemp) then
        slTemp := TStringList.Create
    else
        slTemp.clear;

    // Function
    result           := inputString;
    slTemp.CommaText := '.esp, .esm, .exe, .esl';
    for i            := 0 to slTemp.Count - 1 do
    begin
        { Debug } if debugMsg then
            addMessage('[RemoveFileSuffix] if StrEndsWith(inputString, ' + slTemp[i] + ') := ' + BoolToStr(StrEndsWith(inputString, slTemp[i])));
        if StrEndsWith(inputString, slTemp[i]) then
        begin
            result := RemoveFromEnd(inputString, slTemp[i]);
            { Debug } if debugMsg then
                addMessage('[RemoveFileSuffix] Result := ' + inputString);
            exit;
        end;
    end;

    // Finalize
    slTemp.Free;
    
    // End debugMsg Section
end;

// Removes duplicate strings in a TStringList
procedure slRemoveDuplicates(aList: TStringList);
var
    i     : integer;
    slTemp: TStringList;
begin
    // Initialize
    slTemp := TStringList.Create;

    // Function
    for i := 0 to aList.Count - 1 do
        if not slContains(slTemp, aList[i]) then
            slTemp.Add(aList[i]);
    if (slTemp.Count > 0) then
    begin
        aList.Assign(slTemp);
    end;

    // Finalize
    slTemp.Free;
end;

// Creates a % Chance Leveled List
function createChanceLeveledList(aPlugin: IInterface; aName: string; Chance: integer; aRecord, aLevelList: IInterface): IInterface;
var
    chanceLevelList, nestedChanceLevelList: IInterface;
    tempBoolean                 : boolean;
    i, tempInteger                        : integer;
    slTemp                                : TStringList;
begin
    // Begin debugMsg section
    
    // The following section can be real confusing without examples.
    // If I have a 10% chance I need a Leveled List with 9 copies of the regular item and 1 copy of the enchantment Leveled List.  In math this looks like 1/10 = 10/100 = 10%.
    // If I have a 9% chance I need a Leveled List (List A) with 9 copies of the regular item and 1 copy of the enchantment Leveled List.
    // I also need ANOTHER list (List B) with 9 copies of the regular item and 1 copy of List A.  In math this looks like 1/10 * 9/10 = 9/100 (or 9%).
    // Similarly, if I have an 11% chance I need a Leveled List (List A) with 9 copies of the regular item and 1 copy of the enchantment Leveled List.
    // I also need ANOTHER list with 8 copies of the regular item, 1 copy of List A, and 1 copy of the enchantment list.  In math this looks like 1/10 + (1/10 * 9/10) = 11/100 (or 11%).

    // Initialize
    if Chance = 0 then
        exit;
    slTemp := TStringList.Create;

    // Create %chance list
    slTemp.CommaText := '"Calculate from all levels <= player''s level", "Calculate for each item in count"';
    chanceLevelList  := createLeveledList(aPlugin, aName, slTemp, 0);

    // If it's a 100% chance we just need a single leveled list
    if Chance = 100 then
    begin { Debug }
        if debugMsg then
            addMessage('[%Chance] Chance = 100; Removing chanceLevelList and assigning aLevelList to chanceLevelList for AddToLeveledListAuto input');
        Remove(chanceLevelList);
        chanceLevelList := aLevelList;
    end
    else
        if (Length(IntToStr(Chance)) = 1) then
        begin { Debug }
            if debugMsg then
                addMessage('[%Chance] for i := 0 to Chance do addToLeveledList(' + EditorID(nestedChanceLevelList) + ', ' + EditorID(aLevelList) + ', 1 );');
            for i := 0 to Chance do
                addToLeveledList(nestedChanceLevelList, aLevelList, 1); { Debug }
            if debugMsg then
                addMessage('[%Chance] while (LLec(nestedChanceLevelList) < 10) do addToLeveledList(' + EditorID(nestedChanceLevelList) + ', ' + EditorID(aRecord) + ', 1 );');
            while (LLec(nestedChanceLevelList) < 10) do
                addToLeveledList(nestedChanceLevelList, aRecord, 1);
            addToLeveledList(chanceLevelList, nestedChanceLevelList, 1);
            { Debug } if debugMsg then
                addMessage('[%Chance] while (LLec(' + EditorID(chanceLevelList) + ' ) < 10) do addToLeveledList(' + EditorID(chanceLevelList) + ', ' + EditorID(aRecord) + ', 1 );');
            while (LLec(chanceLevelList) < 10) do
                addToLeveledList(chanceLevelList, aRecord, 1);
        end else begin
            // Grab the second digit; If the second digit is 0 we don't need the nested leveled list; Example: 10, 20, 30, etc.
            { Debug } if debugMsg then
                addMessage('[%Chance] StrToInt(Copy(IntToStr(Chance), 2, 1)) := ' + Copy(IntToStr(Chance), 2, 1));
            tempInteger := StrToInt(Copy(IntToStr(Chance), 2, 1));
            if (tempInteger = 0) then
                tempBoolean := true
            else
                tempBoolean := false;
            { Debug } if debugMsg then
                addMessage('[%Chance] tempBoolean := ' + BoolToStr(tempBoolean));
            // Grab the first digit
            { Debug } if debugMsg then
                addMessage('[%Chance] StrToInt(Copy(IntToStr(Chance), 1, 1)) := ' + Copy(IntToStr(Chance), 1, 1));
            tempInteger := StrToInt(Copy(IntToStr(Chance), 1, 1));
            // Create the percent chance leveled list for 10, 20, 30, etc. (numbers that don't need the nested leveled list)
            if tempBoolean then
            begin { Debug }
                if debugMsg then
                    addMessage('[%Chance] if tempBoolean then begin for i := 0 to tempInteger-1 := ' + IntToStr(tempInteger - 1) + ' do addToLeveledList(' + EditorID(chanceLevelList) + ', ' + EditorID(aLevelList) + ', 1 ); while (LLec(chanceLevelList) :=' + IntToStr(LLec(chanceLevelList)) + ' < 10) do addToLeveledList(' + EditorID(chanceLevelList) + ', ' + EditorID(aRecord) + ', 1 );');
                for i := 0 to tempInteger - 1 do
                    addToLeveledList(chanceLevelList, aLevelList, 1);
                while (LLec(chanceLevelList) < 10) do
                    addToLeveledList(chanceLevelList, aRecord, 1);
            end else begin { Debug }
                if debugMsg then
                    addMessage('[%Chance] Not tempBoolean; Beginning nested list generation');
                // Create a nested leveled list for valid integers between 0 and 100 with a second digit greater than 0.  Example: 51, 52, 53, etc.
                { Debug } if debugMsg then
                    addMessage('[%Chance] Creating and preparing nestedchanceLevelList');
                nestedChanceLevelList := createLeveledList(aPlugin, Insert('nested', aName, ItPos(aName, 'e', 3)), slTemp, 0);
                // Fill the nested and chance leveled lists based on Chance
                for i := 0 to (StrToInt(Copy(IntToStr(Chance), 2, 1)) - 1) do
                    addToLeveledList(nestedChanceLevelList, aLevelList, 1);
                while (LLec(nestedChanceLevelList) < 10) do
                    addToLeveledList(nestedChanceLevelList, aRecord, 1);
                addToLeveledList(chanceLevelList, nestedChanceLevelList, 1);
                for i := 0 to tempInteger - 1 do
                    addToLeveledList(chanceLevelList, aLevelList, 1);
                while (LLec(chanceLevelList) < 10) do
                    addToLeveledList(chanceLevelList, aRecord, 1);
            end;
        end;
    result := chanceLevelList;

    // Finalize
    slTemp.Free;

    
    // End debugMsg section
end;

// Only first letter capitalized
function StrCapFirst(str: string): string;
var
    str, format_str: string;
begin
    // Begin debugMsg section
    

    { Debug } if debugMsg then
        addMessage('[StrCapFirst] ' + Uppercase(Copy(str, 1, 1)) + LowerCase(Copy(str, 2, Length(str))));
    result := Uppercase(Copy(str, 1, 1)) + LowerCase(Copy(str, 2, Length(str)));

    
    // End debugMsg section
end;

// Finds a TForm element by name
function ComponentByCaption(aString: string; aForm: TForm): TObject;
var
    i       : integer;
begin
    // Begin debugMsg section
    

    { Debug } if debugMsg then
        addMessage('[ComponentByCaption] aString := ' + aString);
    for i := aForm.ComponentCount - 1 downto 0 do
    begin
        if (aForm.Components[i].Caption = aString) then
        begin
            result := aForm.Components[i];
            exit;
        end;
    end;

    
    // End debugMsg Section
end;

// Finds a TForm element by name
function ComponentByTop(aTop: integer; aForm: TObject): TObject;
var
    i       : integer;
begin
    // Begin debugMsg section
    

    for i := aForm.ComponentCount - 1 downto 0 do
    begin
        if (aForm.Components[i].Top = aTop) then
        begin
            result := aForm.Components[i];
            exit;
        end;
    end;

    
    // End debugMsg Section
end;

// Caption Exists on TForm element
function CaptionExists(aString: string; aForm: TObject): boolean;
var
    Form    : TForm;
    i       : integer;
begin
    // Begin debugMsg section
    

    result := false;
    for i  := aForm.ComponentCount - 1 downto 0 do
    begin
        { Debug } if debugMsg then
            addMessage('[CaptionExists] if (' + aForm.Components[i].Caption + ' = ' + aString + ' ) then begin');
        if (aForm.Components[i].Caption = aString) then
        begin
            result := true;
        end;
    end;
    { Debug } if debugMsg then
        addMessage('[CaptionExists] Result := ' + BoolToStr(result));

    
    // End debugMsg section
end;

// Finds the longest common substring
function LongestCommonString(aList: TStringList): string;
var
    i, x, y, z: integer;
    tempString: string;
    slTemp    : TStringList;
begin
    // Begin debugMsg section
    

    // Initialize Local
    slTemp := TStringList.Create;

    // Function
    for i := 0 to aList.Count - 1 do
    begin
        tempString       := nil;
        slTemp.CommaText := aList[i];
        { Debug } if debugMsg then
            msgList('[LongestCommonString] slTemp := ', slTemp, '');
        for x := slTemp.Count - 1 downto 0 do
        begin
            tempString     := nil;
            for y          := 0 to x do
                tempString := Trim(tempString + ' ' + slTemp[y]);
            for y          := 0 to aList.Count - 1 do
            begin
                { Debug } if debugMsg then
                    addMessage('[LongestCommonString] ContainsText(' + aList[y] + ', ' + tempString + ' )');
                if ContainsText(aList[y], tempString) and (y <> i) then
                begin
                    if Assigned(result) then
                    begin
                        if (Length(tempString) > Length(result)) then
                            result := tempString;
                    end else begin
                        result := tempString;
                    end;
                end;
            end;
        end;
    end;

    if not Assigned(result) then
        result := aList[0];

    // Finalize Local
    slTemp.Free;

    
    // End debugMsg section
end;

function DecToRoman(Decimal: integer): string;
var
    slNumbers, slRomans: TStringList;
    i                  : integer;
begin
    // Initialize
    slNumbers := TStringList.Create;
    slRomans  := TStringList.Create;

    slNumbers.CommaText := '1, 4, 5, 9, 10, 40, 50, 90, 100, 400, 500, 900, 1000';
    slRomans.CommaText  := 'I, IV, V, IX, X, XL, L, XC, C, CD, D, CM, M';
    result              := '';
    for i               := 12 downto 0 do
    begin
        while (Decimal >= slNumbers[i]) do
        begin
            Decimal := Decimal - slNumbers[i];
            result  := result + slRomans[i];
        end;
    end;

    // Finalization
    slNumbers.Free;
    slRomans.Free;
end;

procedure Btn_Bulk_OnClick_Old(Sender: TObject);
begin
	
end;

// [FUNCTIONS SPECIFIC TO GENERATEENCHANTEDVERSIONSAUTO]
procedure Btn_Bulk_OnClick(Sender: TObject);
var
    lblAddPlugin, lblDetectedFileText, lblHelp        : TLabel;
    tempComponent, btnAdd, btnOk, btnCancel, btnRemove: TButton;
    ddAddPlugin, ddDetectedFile                       : TComboBox;
    slTemp, slFiles                                   : TStringList;
    ALLAfile, tempFile, tempRecord                    : IInterface;
    frm                                               : TForm;
    exist                                   : boolean;
    ALLAplugin                                        : string;
    i, x, y                                           : integer;
begin
    // Begin debugMsg section
    

    // Initialize
    slFiles       := TStringList.Create;
    slTemp        := TStringList.Create;
    frm           := Sender.Parent;
    tempComponent := AssociatedComponent('Output Plugin: ', Sender.Parent);
    ALLAplugin    := tempComponent.Caption;
    if not StrEndsWith(ALLAplugin, '.esl') or StrEndsWith(ALLAplugin, '.exe') or StrEndsWith(ALLAplugin, '.exe') then
        AppendIfMissing(ALLAplugin, '.esp');
	exist := false;
	ALLAfile := FileByName(ALLAplugin);
    if not assigned(ALLAfile) then begin
        if MessageDlg('Create a new plugin named ' + ALLAplugin + ' [YES] or cancel [NO]?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        begin
            AddNewFileName(ALLAplugin);
        end
        else
            exit;
    end;

    // Dialogue Box
    frm := TForm.Create(nil);
    try
        // Remove all previous TForm components
        btnOk     := nil;
        btnCancel := nil;

        // Parent Form; Entire Box
        frm.Width    := 850;
        frm.Height   := 200;
        frm.Position := poScreenCenter;
        frm.Caption  := 'Process Plugins in Bulk';

        // Currently Selected File Label
        lblDetectedFileText         := TLabel.Create(frm);
        lblDetectedFileText.Parent  := frm;
        lblDetectedFileText.Height  := 24;
        lblDetectedFileText.Top     := 68;
        lblDetectedFileText.Left    := 60;
        lblDetectedFileText.Caption := 'Output File: ';
        frm.Height                  := frm.Height + lblDetectedFileText.Height + 12;

        // Currently Selected File
        ddDetectedFile        := TComboBox.Create(frm);
        ddDetectedFile.Parent := frm;
        ddDetectedFile.Height := lblDetectedFileText.Height;
        ddDetectedFile.Top    := lblDetectedFileText.Top;
        ddDetectedFile.Left   := 205;
        ddDetectedFile.Width  := 480;
        ddDetectedFile.Items.Add(ALLAplugin);
        ddDetectedFile.ItemIndex := 0;

        // Add Plugin Label
        lblAddPlugin         := TLabel.Create(frm);
        lblAddPlugin.Parent  := frm;
        lblAddPlugin.Height  := lblDetectedFileText.Height;
        lblAddPlugin.Top     := lblDetectedFileText.Top + lblDetectedFileText.Height + 24;
        lblAddPlugin.Left    := lblDetectedFileText.Left;
        lblAddPlugin.Caption := 'Add Plugin: ';
        frm.Height           := frm.Height + lblAddPlugin.Height + 12;

        // Add Plugin Drop Down
        ddAddPlugin        := TComboBox.Create(frm);
        ddAddPlugin.Parent := frm;
        ddAddPlugin.Height := lblAddPlugin.Height;
        ddAddPlugin.Top    := lblAddPlugin.Top - 2;
        ddAddPlugin.Left   := ddDetectedFile.Left;
        ddAddPlugin.Width  := 480;
        for i              := 0 to FileCount - 1 do
            if not(StrEndsWith(GetFileName(FileByIndex(i)), '.exe') or slContains(slGlobal, GetFileName(FileByIndex(i)))) then
                ddAddPlugin.Items.Add(GetFileName(FileByIndex(i)));
        ddAddPlugin.AutoComplete := true;

        // Add Button
        btnAdd         := TButton.Create(frm);
        btnAdd.Parent  := frm;
        btnAdd.Caption := 'Add';
        btnAdd.Left    := ddAddPlugin.Left + ddAddPlugin.Width + 8;
        btnAdd.Top     := lblAddPlugin.Top;
        btnAdd.Width   := 100;
        btnAdd.OnClick := Btn_AddOrRemove_OnClick;

        // Ok Button
        btnOk             := TButton.Create(frm);
        btnOk.Parent      := frm;
        btnOk.Caption     := 'Ok';
        btnOk.Left        := (frm.Width div 2) - btnOk.Width - 8;
        btnOk.Top         := frm.Height - 80;
        btnOk.ModalResult := mrOk;

        // Cancel Button
        btnCancel             := TButton.Create(frm);
        btnCancel.Parent      := frm;
        btnCancel.Caption     := 'Cancel';
        btnCancel.Left        := btnOk.Left + btnOk.Width + 16;
        btnCancel.Top         := btnOk.Top;
        btnCancel.ModalResult := mrCancel;

        frm.ShowModal;
        // Displays a help message
        if (frm.ModalResult = mrOk) and (ddAddPlugin.Text <> '') and not CaptionExists('Remove', frm) then
        begin
            lblHelp         := TLabel.Create(frm);
            lblHelp.Parent  := frm;
            lblHelp.Height  := 24;
            lblHelp.Top     := btnAdd.Top + btnAdd.Height + 8;
            lblHelp.Left    := btnAdd.Left - 50;
            lblHelp.Caption := 'USE ADD BUTTON';
            frm.ShowModal;
        end;
        if (frm.ModalResult = mrOk) then
        begin
            // If list is empty
            if not CaptionExists('Remove', frm) then
                exit;
            // Output
            for i := 0 to slGlobal.Count - 1 do
                if ContainsText(slGlobal[i], 'Original') or ContainsText(slGlobal[i], 'Template') then
                    slTemp.Add(slGlobal[i]);
            for i := 0 to slTemp.Count - 1 do
                if (slGlobal.IndexOf(slTemp[i]) >= 0) then
                    slGlobal.Delete(slGlobal.IndexOf(slTemp[i]));
            slFiles.Assign(slGlobal);
            // Sender.Parent.Visible := False;
            tempComponent.Caption := ddDetectedFile.Text;
            slTemp.CommaText      := 'ARMO, AMMO, WEAP';
            { Debug } if debugMsg then
                msgList('[ELLR_Bulk_OnClick] slFiles := ', slFiles, '');
            for i := 0 to slFiles.Count - 1 do
            begin
                { Debug } if debugMsg then begin
					exist := assigned(FileByName(slFiles[i]));
                    addMessage('[ELLR_Bulk_OnClick] if FileByName(' + slFiles[i] + ' ) := ' + BoolToStr(exist) + ' then begin');
				end;
                if exist then
                begin
                    tempFile := FileByName(slFiles[i]);
                    { Debug } if debugMsg then
                        addMessage('[ELLR_Bulk_OnClick] tempFile := ' + GetFileName(tempFile));
                    { Debug } if debugMsg then
                        addMessage('[ELLR_Bulk_OnClick] for x := 0 to slTemp.Count-1 := ' + IntToStr(slTemp.Count - 1) + ' do begin');
                    for x := 0 to slTemp.Count - 1 do
                    begin
                        { Debug } if debugMsg then
                            addMessage('[ELLR_Bulk_OnClick] for y := 0 to Pred(ElementCount(GroupBySignature(' + GetFileName(tempFile) + ', ' + slTemp[x] + ' ))) := ' + IntToStr(Pred(ElementCount(GroupBySignature(ObjectToElement(slFiles.Objects[i]), slTemp[x])))) + ' do begin');
                        for y := 0 to Pred(ElementCount(GroupBySignature(tempFile, slTemp[x]))) do
                        begin
                            { Debug } if debugMsg then
                                addMessage('[ELLR_Bulk_OnClick] tempRecord := elementbyindex(GroupBySignature(' + GetFileName(tempFile) + ', ' + slTemp[x]'+), ' + IntToStr(x) + ' );');
                            tempRecord := elementbyindex(GroupBySignature(tempFile, slTemp[x]), y);
                            if not(Length(EditorID(tempRecord)) > 0) then
                                Continue;
                            { Debug } if debugMsg then
                                addMessage('[ELLR_Bulk_OnClick] tempRecord := ' + EditorID(tempRecord));
                            if not slContains(slGlobal, EditorID(tempRecord)) then
                            begin
                                slGlobal.addObject(EditorID(tempRecord) + 'Original', tempRecord);
                                slGlobal.addObject(EditorID(tempRecord) + 'Template', GetTemplate(tempRecord));
                            end;
                        end;
                    end;
                end;
            end;
            { Debug } if debugMsg then
                msgList('[ELLR_Bulk_OnClick] slGlobal := ', slGlobal, '');
            Sender.Parent.ModalResult := mrOk;
        end else begin
            tempComponent.Caption := ddDetectedFile.Text;
            slTemp.clear;
            for i := 0 to slGlobal.Count - 1 do begin
				
                if assigned(FileByName(slGlobal[i])) then
                    slTemp.Add(slGlobal[i]);
					
			end;
            for i := 0 to slTemp.Count - 1 do
                if (slGlobal.IndexOf(slTemp[i]) >= 0) then
                    slGlobal.Delete(slGlobal.IndexOf(slTemp[i]));
        end;
    finally
        frm.Free;
    end;

    // Finalize
    slFiles.Free;
    slTemp.Free;

    
    // End debugMsg Section
end;

procedure Btn_AddOrRemove_OnClick(Sender: TObject);
var
    btnAdd, btnRemove, btnOk, btnCancel: TButton;
    tempBoolean, exist       : boolean;
    lblPlugin                          : TLabel;
    i, tempInteger                     : integer;
    tempPlugin                         : string;
    GEVfile                            : IInterface;
    frm                                : TForm;
begin
    // Begin debugMsg section
    

    // Grab values from parent form
    frm := Sender.Parent;
    if CaptionExists('Remove Plugin: ', frm) then
    begin
        tempPlugin := AssociatedComponent('Remove Plugin: ', frm).Caption;
        { Debug } if debugMsg then
            addMessage('[Btn_AddOrRemove_OnClick] tempPlugin := ' + tempPlugin);
    end
    else
        if CaptionExists('Add Plugin: ', frm) then
        begin
            tempPlugin := AssociatedComponent('Add Plugin: ', frm).Caption;
            { Debug } if debugMsg then
                addMessage('[Btn_AddOrRemove_OnClick] tempPlugin := ' + tempPlugin);
        end;

    // Manipulate static list of added values
    { Debug } if debugMsg then
        addMessage('[Btn_AddOrRemove_OnClick] TLabel(Sender).Caption := ' + TLabel(Sender).Caption);
    if (TLabel(Sender).Caption = 'Add') then
    begin
        tempBoolean := false;
        for i       := 0 to frm.ComponentCount - 1 do
            if (frm.Components[i].Top >= 160) and (frm.Components[i].Caption = tempPlugin) then
                tempBoolean := true;
		exist := false;
		FileByName(tempPlugin);
        if not tempBoolean then
        begin
            // Expand form
            frm.Height := frm.Height + 36;
            // Shift existing components down
            TShift(160, 36, frm, false);
            // Remove Button
            btnRemove         := TButton.Create(frm);
            btnRemove.Parent  := frm;
            btnRemove.Caption := 'Remove';
            btnRemove.Left    := 70;
            btnRemove.Top     := 160;
            btnRemove.Width   := 100;
            btnRemove.OnClick := Btn_AddOrRemove_OnClick;
            // Remove Plugin label
            lblPlugin         := TLabel.Create(frm);
            lblPlugin.Parent  := frm;
            lblPlugin.Height  := 24;
            lblPlugin.Top     := btnRemove.Top + 2;
            lblPlugin.Left    := 205;
            lblPlugin.Caption := tempPlugin;
        end;
        slGlobal.Add(tempPlugin);
    end
    else
        if (TLabel(Sender).Caption = 'Remove') then
        begin
            slGlobal.Delete(slGlobal.IndexOf(ComponentByTop(Sender.Top + 2, frm).Caption));
            ComponentByTop(Sender.Top + 2, frm).Free;
            Sender.Visible := false;
            // Shift existing components up
            TShift(Sender.Top, 36, frm, true);
            // Shrink form
            frm.Height := frm.Height - 36;
        end;
end;

procedure GEV_Btn_Remove(Sender: TObject);
var
    lblRemovePlugin, lblDetectedFileText, lblDetectedFile: TLabel;
    btnAdd, btnOk, btnCancel, btnRemove                  : TButton;
    ddRemovePlugin                                       : TComboBox;
    slTemp                                               : TStringList;
    GEVfile, TF                                              : IInterface;
    frm_Remove                                           : TForm;
    exist                                             : boolean;
    GEVplugin                                            : string;
    i                                                    : integer;
begin
    // Begin debugMsg section
    

    // Initialize
    slTemp    := TStringList.Create;
    GEVplugin := ComponentByTop(ComponentByCaption('Output Plugin: ', Sender.Parent).Top - 2, Sender.Parent).Caption;
    if not StrEndsWith(GEVplugin, '.esl') then
        AppendIfMissing(GEVplugin, '.esp');
	TF := FileByName(GEVplugin);
    if assigned(TF) then
    begin
        GEVfile := TF;
    end else begin
        addMessage('[' + full(selectedRecord) + '] ' + GEVplugin + ' does not exist; Cannot use ''Remove'' on unspecified plugin');
        exit;
    end;

    // Dialogue Box
    frm_Remove := TForm.Create(nil);
    while not((frm_Remove.ModalResult = mrCancel) or (frm_Remove.ModalResult = mrOk)) do
    begin
        frm_Remove := TForm.Create(nil);
        try
            // Remove all previous TForm components
            btnOk     := nil;
            btnCancel := nil;

            // Parent Form; Entire Box
            frm_Remove.Width    := 850;
            frm_Remove.Height   := 200;
            frm_Remove.Position := poScreenCenter;
            frm_Remove.Caption  := 'Remove a Specified Master';

            // Currently Selected File Label
            lblDetectedFileText         := TLabel.Create(frm_Remove);
            lblDetectedFileText.Parent  := frm_Remove;
            lblDetectedFileText.Height  := 24;
            lblDetectedFileText.Top     := 68;
            lblDetectedFileText.Left    := 60;
            lblDetectedFileText.Caption := 'Currently Selected File: ';
            frm_Remove.Height           := frm_Remove.Height + lblDetectedFileText.Height + 12;

            // Currently Selected File
            lblDetectedFile         := TLabel.Create(frm_Remove);
            lblDetectedFile.Parent  := frm_Remove;
            lblDetectedFile.Height  := lblDetectedFileText.Height;
            lblDetectedFile.Top     := lblDetectedFileText.Top;
            lblDetectedFile.Left    := lblDetectedFileText.Left + (9 * Length(lblDetectedFileText.Caption)) + 85;
            lblDetectedFile.Caption := GEVplugin;

            // Remove Plugin label
            lblRemovePlugin         := TLabel.Create(frm_Remove);
            lblRemovePlugin.Parent  := frm_Remove;
            lblRemovePlugin.Height  := lblDetectedFileText.Height;
            lblRemovePlugin.Top     := lblDetectedFileText.Top + lblDetectedFileText.Height + 24;
            lblRemovePlugin.Left    := lblDetectedFileText.Left;
            lblRemovePlugin.Caption := 'Remove Plugin: ';
            frm_Remove.Height       := frm_Remove.Height + lblRemovePlugin.Height + 12;

            // Remove Plugin Drop Down
            ddRemovePlugin        := TComboBox.Create(frm_Remove);
            ddRemovePlugin.Parent := frm_Remove;
            ddRemovePlugin.Height := lblRemovePlugin.Height;
            ddRemovePlugin.Top    := lblRemovePlugin.Top - 2;
            ddRemovePlugin.Left   := lblRemovePlugin.Left + (9 * Length(lblRemovePlugin.Caption)) + 36;
            ddRemovePlugin.Width  := 480;
            for i                 := 0 to Pred(MasterCount(GEVfile)) do
                if not(StrEndsWith(GetFileName(MasterByIndex(GEVfile, i)), '.esm') or StrEndsWith(GetFileName(MasterByIndex(GEVfile, i)), '.exe') or slContains(slGlobal, GetFileName(MasterByIndex(GEVfile, i)))) then
                    ddRemovePlugin.Items.Add(GetFileName(MasterByIndex(GEVfile, i)));

            // Add Button
            btnAdd             := TButton.Create(frm_Remove);
            btnAdd.Parent      := frm_Remove;
            btnAdd.Caption     := 'Add';
            btnAdd.Left        := ddRemovePlugin.Left + ddRemovePlugin.Width + 8;
            btnAdd.Top         := lblRemovePlugin.Top;
            btnAdd.Width       := 100;
            btnAdd.ModalResult := mrRetry;
            btnAdd.OnClick     := Btn_AddOrRemove_OnClick;

            // Items to be removed
            { Debug } if debugMsg then
                msgList('[GEV_Btn_Remove] slGlobal := ', slGlobal, '');
            for i := 0 to slGlobal.Count - 1 do
            begin
				if assigned(FileByName(slGlobal[i])) then
                begin
                    // Remove Plugin label
                    lblRemovePlugin         := TLabel.Create(frm_Remove);
                    lblRemovePlugin.Parent  := frm_Remove;
                    lblRemovePlugin.Height  := 24;
                    lblRemovePlugin.Top     := slGlobal.Objects[i];
                    lblRemovePlugin.Left    := 188;
                    lblRemovePlugin.Caption := slGlobal[i];
                    frm_Remove.Height       := frm_Remove.Height + lblRemovePlugin.Height + 12;

                    // Remove Button
                    btnRemove             := TButton.Create(frm_Remove);
                    btnRemove.Parent      := frm_Remove;
                    btnRemove.Caption     := 'Remove';
                    btnRemove.Left        := 80;
                    btnRemove.Top         := slGlobal.Objects[i];
                    btnRemove.Width       := 100;
                    btnRemove.ModalResult := mrIgnore;
                    btnRemove.OnClick     := Btn_AddOrRemove_OnClick;
                end;
            end;

            // Ok Button
            btnOk             := TButton.Create(frm_Remove);
            btnOk.Parent      := frm_Remove;
            btnOk.Caption     := 'OK';
            btnOk.Left        := (frm_Remove.Width div 2) - btnOk.Width - 8;
            btnOk.Top         := frm_Remove.Height - 80;
            btnOk.ModalResult := mrOk;

            // Cancel Button
            btnCancel             := TButton.Create(frm_Remove);
            btnCancel.Parent      := frm_Remove;
            btnCancel.Caption     := 'Cancel';
            btnCancel.Left        := btnOk.Left + btnOk.Width + 16;
            btnCancel.Top         := btnOk.Top;
            btnCancel.ModalResult := mrCancel;

            if (frm_Remove.ShowModal = mrOk) then
            begin
                for i := 0 to slGlobal.Count - 1 do
                begin
                    if Assigned(FileByName(slGlobal[i])) then
                    begin

                        slTemp.Add(slGlobal[i]);
                    end;
                end;
                for i := 0 to slTemp.Count - 1 do
                    if (slGlobal.IndexOf(slTemp[i]) >= 0) then
                        slGlobal.Delete(slGlobal.IndexOf(slTemp[i]));
            end;
        finally
            frm_Remove.Free;
        end;
    end;

    // Finalize
    slTemp.Free;

    
    // End debugMsg Section
end;

function Btn_ItemTierLevels_OnClick(Sender: TObject): TStringList;
var
    lblTier01, lblTier02, lblTier03, lblTier04, lblTier05, lblTier06: TLabel;
    ddTier01, ddTier02, ddTier03, ddTier04, ddTier05, ddTier06      : TComboBox;
    tempBoolean                                           : boolean;
    btnOk, btnCancel                                                : TButton;
    i, tempInteger                                                  : integer;
    frm                                                             : TForm;
    tempObject                                                      : TObject;
begin
    // Get Sender Parameters
    frm := Sender.Parent;

    if not CaptionExists('Tier 01 appears at level: ', frm) then
    begin
        Sender.Caption := 'Confirm Tiers';
        // Shift Components Down
        { Debug } if debugMsg then
            addMessage('[Btn_ItemTierLevels_OnClick] Shift Components Down');
        frm.Height := frm.Height + 262;
        for i      := 0 to frm.ComponentCount - 1 do
        begin
            tempObject := nil;
            if (frm.Components[i].Top > Sender.Top) then
            begin
                tempObject  := frm.Components[i];
                tempInteger := tempObject.Top;
                if Assigned(tempObject) then
                begin
                    tempObject.Top := tempObject.Top + 262;
                end;
            end;
        end;
        // Tier 01 Label
        lblTier01         := TLabel.Create(frm);
        lblTier01.Parent  := frm;
        lblTier01.Height  := 24;
        lblTier01.Top     := Sender.Top + Sender.Height + 18;
        lblTier01.Left    := Sender.Left;
        lblTier01.Caption := 'Tier 01 appears at level: ';

        // Tier 01 Drop Down
        ddTier01        := TComboBox.Create(frm);
        ddTier01.Parent := frm;
        ddTier01.Height := lblTier01.Height;
        ddTier01.Top    := lblTier01.Top - 2;
        ddTier01.Left   := 530;
        ddTier01.Width  := 80;
        if slContains(slGlobal, 'ItemTier01') then
        begin
            ddTier01.Items.Add(IntToStr(slGlobal.Objects[slGlobal.IndexOf('ItemTier01')]));
        end else begin
            ddTier01.Items.Add(IntToStr(defaultItemTier01));
        end;
        ddTier01.ItemIndex := 0;

        // Tier 02 Label
        lblTier02         := TLabel.Create(frm);
        lblTier02.Parent  := frm;
        lblTier02.Height  := lblTier01.Height;
        lblTier02.Top     := lblTier01.Top + lblTier01.Height + 18;
        lblTier02.Left    := lblTier01.Left;
        lblTier02.Caption := 'Tier 02 appears at level: ';

        // Tier 02 Drop Down
        ddTier02        := TComboBox.Create(frm);
        ddTier02.Parent := frm;
        ddTier02.Height := lblTier02.Height;
        ddTier02.Top    := lblTier02.Top - 2;
        ddTier02.Left   := ddTier01.Left;
        ddTier02.Width  := ddTier01.Width;
        if slContains(slGlobal, 'ItemTier02') then
        begin
            ddTier02.Items.Add(IntToStr(slGlobal.Objects[slGlobal.IndexOf('ItemTier02')]));
        end else begin
            ddTier02.Items.Add(IntToStr(defaultItemTier02));
        end;
        ddTier02.ItemIndex := 0;

        // Tier 03 Label
        lblTier03         := TLabel.Create(frm);
        lblTier03.Parent  := frm;
        lblTier03.Height  := lblTier02.Height;
        lblTier03.Top     := lblTier02.Top + lblTier02.Height + 18;
        lblTier03.Left    := lblTier02.Left;
        lblTier03.Caption := 'Tier 03 appears at level: ';

        // Tier 03 Drop Down
        ddTier03        := TComboBox.Create(frm);
        ddTier03.Parent := frm;
        ddTier03.Height := lblTier03.Height;
        ddTier03.Top    := lblTier03.Top - 2;
        ddTier03.Left   := ddTier01.Left;
        ddTier03.Width  := ddTier01.Width;
        if slContains(slGlobal, 'ItemTier03') then
        begin
            ddTier03.Items.Add(IntToStr(slGlobal.Objects[slGlobal.IndexOf('ItemTier03')]));
        end else begin
            ddTier03.Items.Add(IntToStr(defaultItemTier03));
        end;
        ddTier03.ItemIndex := 0;

        // Tier 04 Label
        lblTier04         := TLabel.Create(frm);
        lblTier04.Parent  := frm;
        lblTier04.Height  := lblTier03.Height;
        lblTier04.Top     := lblTier03.Top + lblTier03.Height + 18;
        lblTier04.Left    := lblTier03.Left;
        lblTier04.Caption := 'Tier 04 appears at level: ';

        // Tier 04 Drop Down
        ddTier04        := TComboBox.Create(frm);
        ddTier04.Parent := frm;
        ddTier04.Height := lblTier04.Height;
        ddTier04.Top    := lblTier04.Top - 2;
        ddTier04.Left   := ddTier01.Left;
        ddTier04.Width  := ddTier01.Width;
        if slContains(slGlobal, 'ItemTier04') then
        begin
            ddTier04.Items.Add(IntToStr(slGlobal.Objects[slGlobal.IndexOf('ItemTier04')]));
        end else begin
            ddTier04.Items.Add(IntToStr(defaultItemTier04));
        end;
        ddTier04.ItemIndex := 0;

        // Tier 05 Label
        lblTier05         := TLabel.Create(frm);
        lblTier05.Parent  := frm;
        lblTier05.Height  := lblTier04.Height;
        lblTier05.Top     := lblTier04.Top + lblTier04.Height + 18;
        lblTier05.Left    := lblTier04.Left;
        lblTier05.Caption := 'Tier 05 appears at level: ';

        // Tier 05 Drop Down
        ddTier05        := TComboBox.Create(frm);
        ddTier05.Parent := frm;
        ddTier05.Height := lblTier05.Height;
        ddTier05.Top    := lblTier05.Top - 2;
        ddTier05.Left   := ddTier01.Left;
        ddTier05.Width  := ddTier01.Width;
        if slContains(slGlobal, 'ItemTier05') then
        begin
            ddTier05.Items.Add(IntToStr(slGlobal.Objects[slGlobal.IndexOf('ItemTier05')]));
        end else begin
            ddTier05.Items.Add(IntToStr(defaultItemTier05));
        end;
        ddTier05.ItemIndex := 0;

        // Tier 06 Label
        lblTier06         := TLabel.Create(frm);
        lblTier06.Parent  := frm;
        lblTier06.Height  := lblTier05.Height;
        lblTier06.Top     := lblTier05.Top + lblTier05.Height + 18;
        lblTier06.Left    := lblTier05.Left;
        lblTier06.Caption := 'Tier 06 appears at level: ';

        // Tier 06 Drop Down
        ddTier06        := TComboBox.Create(frm);
        ddTier06.Parent := frm;
        ddTier06.Height := lblTier06.Height;
        ddTier06.Top    := lblTier06.Top - 2;
        ddTier06.Left   := ddTier01.Left;
        ddTier06.Width  := ddTier01.Width;
        if slContains(slGlobal, 'ItemTier06') then
        begin
            ddTier06.Items.Add(IntToStr(slGlobal.Objects[slGlobal.IndexOf('ItemTier06')]));
        end else begin
            ddTier06.Items.Add(IntToStr(defaultItemTier06));
        end;
        ddTier06.ItemIndex := 0;
    end else begin
        Sender.Caption := 'Configure Tiers';
        for i          := 1 to 6 do
        begin
            if CaptionExists('Tier 0' + IntToStr(i) + ' appears at level: ', frm) then
            begin
                tempObject := ComponentByTop(ComponentByCaption('Tier 0' + IntToStr(i) + ' appears at level: ', frm).Top - 2, frm);
                if (IntWithinStr(tempObject.Text) > 0) then
                begin
                    if not slContains(slGlobal, 'ItemTier0' + IntToStr(i)) then
                    begin
                        slGlobal.addObject('ItemTier0' + IntToStr(i), IntWithinStr(tempObject.Text));
                    end else begin
                        slGlobal.Objects[slGlobal.IndexOf('ItemTier0' + IntToStr(i))] := IntWithinStr(tempObject.Text);
                    end;
                end;
            end;
            tempObject  := ComponentByCaption(('Tier 0' + IntToStr(i) + ' appears at level: '), frm);
            tempInteger := tempObject.Top;
            if Assigned(tempObject) then
                tempObject.Free;
            tempObject := ComponentByTop(tempInteger - 2, frm);
            if Assigned(tempObject) then
                tempObject.Free;
        end;
        // Shift Components Up
        { Debug } if debugMsg then
            addMessage('[Btn_ItemTierLevels_OnClick] Shift Components Up');
        frm.Height := frm.Height - 262;
        for i      := 0 to frm.ComponentCount - 1 do
        begin
            tempObject := nil;
            if (frm.Components[i].Top > Sender.Top) then
            begin
                tempObject  := frm.Components[i];
                tempInteger := tempObject.Top;
                if Assigned(tempObject) then
                begin
                    tempObject.Top := tempObject.Top - 262;
                end;
            end;
        end;
    end;
end;

procedure Btn_Temper_OnClick(Sender: TObject);
var
    lblTemperLight, lblTemperHeavy: TLabel;
    ddTemperLight, ddTemperHeavy  : TComboBox;
    tempBoolean         : boolean;
    btnOk, btnCancel              : TButton;
    i, tempInteger                : integer;
    slTemp                        : TStringList;
    frm                           : TForm;
    tempObject                    : TObject;
begin
    // Begin debugMsg section
    

    // Initialize
    slTemp := TStringList.Create;

    // Get Sender Parameters
    { Debug } if debugMsg then
        addMessage('[Btn_Temper_OnClick] Sender := ' + Sender.Caption);
    frm := Sender.Parent;

    slTemp.CommaText := '"# of Ingots - Light/One-Handed: ", "# of Ingots - Heavy/Two-Handed: "';
    if not CaptionExists(slTemp[0], frm) then
    begin
        // Shift Components Down
        { Debug } if debugMsg then
            addMessage('[Btn_Temper_OnClick] Shift Components Down');
        frm.Height := frm.Height + slTemp.Count * 44;
        TShift(Sender.Top + 3, slTemp.Count * 44, frm, false);
        Sender.Caption := 'Confirm Temper Recipe';
        // Temper Light Label
        { Debug } if debugMsg then
            addMessage('[Btn_Temper_OnClick] Temper Light Label');
        lblTemperLight         := TLabel.Create(frm);
        lblTemperLight.Parent  := frm;
        lblTemperLight.Height  := 24;
        lblTemperLight.Top     := Sender.Top + Sender.Height + 18;
        lblTemperLight.Left    := Sender.Left;
        lblTemperLight.Caption := '# of Ingots - Light/One-Handed: ';

        // Temper Light Drop Down
        { Debug } if debugMsg then
            addMessage('[Btn_Temper_OnClick] Temper Light Drop Down');
        ddTemperLight        := TComboBox.Create(frm);
        ddTemperLight.Parent := frm;
        ddTemperLight.Height := lblTemperLight.Height;
        ddTemperLight.Top    := lblTemperLight.Top - 2;
        ddTemperLight.Left   := 450;
        ddTemperLight.Width  := 80;
        if slContains(slGlobal, 'TemperLight') then
        begin
            ddTemperLight.Items.Add(IntToStr(slGlobal.Objects[slGlobal.IndexOf('TemperLight')]));
        end else begin
            ddTemperLight.Items.Add(IntToStr(defaultTemperLight));
        end;
        ddTemperLight.ItemIndex := 0;

        // Temper Heavy Label
        { Debug } if debugMsg then
            addMessage('[Btn_Temper_OnClick] Temper Heavy Label');
        lblTemperHeavy         := TLabel.Create(frm);
        lblTemperHeavy.Parent  := frm;
        lblTemperHeavy.Height  := lblTemperLight.Height;
        lblTemperHeavy.Top     := lblTemperLight.Top + lblTemperLight.Height + 18;
        lblTemperHeavy.Left    := lblTemperLight.Left;
        lblTemperHeavy.Caption := '# of Ingots - Heavy/Two-Handed: ';

        // Temper Heavy Drop Down
        { Debug } if debugMsg then
            addMessage('[Btn_Temper_OnClick] Temper Heavy Drop Down');
        ddTemperHeavy        := TComboBox.Create(frm);
        ddTemperHeavy.Parent := frm;
        ddTemperHeavy.Height := lblTemperHeavy.Height;
        ddTemperHeavy.Top    := lblTemperHeavy.Top - 2;
        ddTemperHeavy.Left   := ddTemperLight.Left;
        ddTemperHeavy.Width  := ddTemperLight.Width;
        if slContains(slGlobal, 'TemperHeavy') then
        begin
            ddTemperHeavy.Items.Add(IntToStr(slGlobal.Objects[slGlobal.IndexOf('TemperHeavy')]));
        end else begin
            ddTemperHeavy.Items.Add(IntToStr(defaultTemperHeavy));
        end;
        ddTemperHeavy.ItemIndex := 0;
    end else begin
        Sender.Caption := 'Configure Temper Recipe';
        // Set Result
        if slContains(slGlobal, 'TemperLight') then
        begin
            slGlobal.Objects[slGlobal.IndexOf('TemperLight')] := StrToInt(ComponentByTop(ComponentByCaption('# of Ingots - Light/One-Handed: ', frm).Top - 2, frm).Text);
        end
        else
            slGlobal.addObject('TemperLight', StrToInt(ComponentByTop(ComponentByCaption('# of Ingots - Light/One-Handed: ', frm).Top - 2, frm).Text));
        if slContains(slGlobal, 'TemperHeavy') then
        begin
            slGlobal.Objects[slGlobal.IndexOf('TemperHeavy')] := StrToInt(ComponentByTop(ComponentByCaption('# of Ingots - Heavy/Two-Handed: ', frm).Top - 2, frm).Text);
        end
        else
            slGlobal.addObject('TemperHeavy', StrToInt(ComponentByTop(ComponentByCaption('# of Ingots - Heavy/Two-Handed: ', frm).Top - 2, frm).Text));
        // Free Components
        for i := 0 to slTemp.Count - 1 do
        begin
            tempObject  := ComponentByCaption(slTemp[i], frm);
            tempInteger := tempObject.Top - 2;
            tempObject.Free;
            tempObject := ComponentByTop(tempInteger, frm);
            tempObject.Free;
        end;
        // Shift form
        TShift(Sender.Top + 3, slTemp.Count * 44, frm, true);
        frm.Height := frm.Height - slTemp.Count * 44;
    end;

    // Finalize
    slTemp.Free;

    
    // End debugMsg section
end;

procedure Btn_overwrite_OnClick(Sender: TObject);
begin
	
end;

procedure Btn_Breakdown_OnClick(Sender: TObject);
var
    lblEquipped, lblEnchanted, lblDaedric, lblChitin: TLabel;
    ckEquipped, ckEnchanted, ckDaedric, ckChitin    : TComboBox;
    tempBoolean                           : boolean;
    btnOk, btnCancel                                : TButton;
    i, tempInteger                                  : integer;
    slTemp                                          : TStringList;
    frm                                             : TForm;
    tempObject                                      : TObject;
begin
    // Begin debugMsg section
    

    // Initialize
    slTemp := TStringList.Create;

    // Get Sender Parameters
    { Debug } if debugMsg then
        addMessage('[Btn_Temper_OnClick] Sender := ' + Sender.Caption);
    { Debug } if debugMsg then
        msgList('[Btn_Temper_OnClick] slGlobal := ', slGlobal, '');
    frm := Sender.Parent;

    if not CaptionExists('Breakdown Equipped: ', frm) then
    begin
        // Shift Components
        { Debug } if debugMsg then
            addMessage('[Btn_Temper_OnClick] Shift Components Down');
        frm.Height := frm.Height + 172;
        TShift(Sender.Top + 3, 172, frm, false);
        Sender.Caption := 'Confirm Breakdown Recipe';

        // Breakdown Equipped Label
        { Debug } if debugMsg then
            addMessage('[Btn_Temper_OnClick] Breakdown Equipped Label');
        lblEquipped         := TLabel.Create(frm);
        lblEquipped.Parent  := frm;
        lblEquipped.Height  := 24;
        lblEquipped.Top     := Sender.Top + Sender.Height + 18;
        lblEquipped.Left    := Sender.Left;
        lblEquipped.Caption := 'Breakdown Equipped: ';

        // Breakdown Equipped Check Box
        { Debug } if debugMsg then
            addMessage('[Btn_Temper_OnClick] Breakdown Equipped Check Box');
        ckEquipped        := TCheckBox.Create(frm);
        ckEquipped.Parent := frm;
        ckEquipped.Height := lblEquipped.Height;
        ckEquipped.Top    := lblEquipped.Top - 2;
        ckEquipped.Left   := 465;
        ckEquipped.Width  := 80;
        if slContains(slGlobal, 'BreakdownEquipped') then
        begin
            ckEquipped.Checked := boolean(slGlobal.Objects[slGlobal.IndexOf('BreakdownEquipped')]);
        end
        else
            ckEquipped.Checked := false;

        // Breakdown Enchanted Label
        { Debug } if debugMsg then
            addMessage('[Btn_Temper_OnClick] Breakdown Enchanted Label');
        lblEnchanted         := TLabel.Create(frm);
        lblEnchanted.Parent  := frm;
        lblEnchanted.Height  := lblEquipped.Height;
        lblEnchanted.Top     := lblEquipped.Top + lblEquipped.Height + 18;
        lblEnchanted.Left    := lblEquipped.Left;
        lblEnchanted.Caption := 'Breakdown Enchanted: ';

        // Breakdown Enchanted Check Box
        { Debug } if debugMsg then
            addMessage('[Btn_Temper_OnClick] Breakdown Enchanted Check Box');
        ckEnchanted        := TCheckBox.Create(frm);
        ckEnchanted.Parent := frm;
        ckEnchanted.Height := lblEnchanted.Height;
        ckEnchanted.Top    := lblEnchanted.Top - 2;
        ckEnchanted.Left   := ckEquipped.Left;
        ckEnchanted.Width  := ckEquipped.Width;
        if slContains(slGlobal, 'BreakdownEnchanted') then
        begin
            ckEnchanted.Checked := boolean(slGlobal.Objects[slGlobal.IndexOf('BreakdownEnchanted')]);
        end
        else
            ckEnchanted.Checked := false;

        // Breakdown Daedric Label
        { Debug } if debugMsg then
            addMessage('[Btn_Temper_OnClick] Breakdown Daedric Label');
        lblDaedric         := TLabel.Create(frm);
        lblDaedric.Parent  := frm;
        lblDaedric.Height  := lblEnchanted.Height;
        lblDaedric.Top     := lblEnchanted.Top + lblEnchanted.Height + 18;
        lblDaedric.Left    := lblEnchanted.Left;
        lblDaedric.Caption := 'Breakdown Daedric: ';

        // Breakdown Daedric Check Box
        { Debug } if debugMsg then
            addMessage('[Btn_Temper_OnClick] Breakdown Daedric Check Box');
        ckDaedric        := TCheckBox.Create(frm);
        ckDaedric.Parent := frm;
        ckDaedric.Height := lblDaedric.Height;
        ckDaedric.Top    := lblDaedric.Top - 2;
        ckDaedric.Left   := ckEquipped.Left;
        ckDaedric.Width  := ckEquipped.Width;
        if slContains(slGlobal, 'BreakdownDaedric') then
        begin
            ckDaedric.Checked := boolean(slGlobal.Objects[slGlobal.IndexOf('BreakdownDaedric')]);
        end
        else
            ckDaedric.Checked := true;

        // Breakdown DLC Label
        { Debug } if debugMsg then
            addMessage('[Btn_Temper_OnClick] Breakdown DLC Label');
        lblChitin         := TLabel.Create(frm);
        lblChitin.Parent  := frm;
        lblChitin.Height  := lblDaedric.Height;
        lblChitin.Top     := lblDaedric.Top + lblDaedric.Height + 18;
        lblChitin.Left    := lblDaedric.Left;
        lblChitin.Caption := 'Breakdown DLC: ';

        // Breakdown DLC Check Box
        { Debug } if debugMsg then
            addMessage('[Btn_Temper_OnClick] Breakdown DLC Check Box');
        ckChitin        := TCheckBox.Create(frm);
        ckChitin.Parent := frm;
        ckChitin.Height := lblChitin.Height;
        ckChitin.Top    := lblChitin.Top - 2;
        ckChitin.Left   := ckEquipped.Left;
        ckChitin.Width  := ckEquipped.Width;
        if slContains(slGlobal, 'BreakdownDLC') then
        begin
            ckChitin.Checked := boolean(slGlobal.Objects[slGlobal.IndexOf('BreakdownDLC')]);
        end
        else
            ckChitin.Checked := true;
    end else begin
        // Set result
        tempObject := ComponentByTop(ComponentByCaption('Breakdown Equipped: ', frm).Top - 2, frm);
        if slContains(slGlobal, 'BreakdownEquipped') then
        begin
            slGlobal.Objects[slGlobal.IndexOf('BreakdownEquipped')] := tempObject.Checked;
        end
        else
            slGlobal.addObject('BreakdownEquipped', tempObject.Checked);
        tempObject := ComponentByTop(ComponentByCaption('Breakdown Enchanted: ', frm).Top - 2, frm);
        if slContains(slGlobal, 'BreakdownEnchanted') then
        begin
            slGlobal.Objects[slGlobal.IndexOf('BreakdownEnchanted')] := tempObject.Checked;
        end
        else
            slGlobal.addObject('BreakdownEnchanted', tempObject.Checked);
        tempObject := ComponentByTop(ComponentByCaption('Breakdown Daedric: ', frm).Top - 2, frm);
        if slContains(slGlobal, 'BreakdownDaedric') then
        begin
            slGlobal.Objects[slGlobal.IndexOf('BreakdownDaedric')] := tempObject.Checked;
        end
        else
            slGlobal.addObject('BreakdownDaedric', tempObject.Checked);
        tempObject := ComponentByTop(ComponentByCaption('Breakdown DLC: ', frm).Top - 2, frm);
        if slContains(slGlobal, 'BreakdownDLC') then
        begin
            slGlobal.Objects[slGlobal.IndexOf('BreakdownDLC')] := tempObject.Checked;
        end
        else
            slGlobal.addObject('BreakdownDLC', tempObject.Checked);
        { Debug } if debugMsg then
            msgList('[Btn_Temper_OnClick] slGlobal := ', slGlobal, '');
        // Free Components
        slTemp.CommaText := '"Breakdown Equipped: ", "Breakdown Enchanted: ", "Breakdown DLC: ", "Breakdown Daedric: ';
        for i            := 0 to slTemp.Count - 1 do
        begin
            tempObject  := ComponentByCaption(slTemp[i], frm);
            tempInteger := tempObject.Top - 2;
            tempObject.Free;
            tempObject := ComponentByTop(tempInteger, frm);
            tempObject.Free;
        end;
        // Shift form
        Sender.Caption := 'Configure Breakdown Recipe';
        TShift(Sender.Top + 3, 172, frm, true);
        frm.Height := frm.Height - 172;
    end;

    // Finalize
    slTemp.Free;

    
    // End debugMsg section
end;

procedure Btn_Crafting_OnClick(Sender: TObject);
var
    lblScaling           : TLabel;
    ckScaling            : TComboBox;
    tempBoolean: boolean;
    btnOk, btnCancel     : TButton;
    i, tempInteger       : integer;
    slTemp               : TStringList;
    frm                  : TForm;
    tempObject           : TObject;
begin
    // Begin debugMsg section
    

    // Initialize
    slTemp := TStringList.Create;

    // Get Sender Parameters
    { Debug } if debugMsg then
        addMessage('[Btn_Temper_OnClick] Sender := ' + Sender.Caption);
    frm := Sender.Parent;

    if not CaptionExists('Recipe Scaling: ', frm) then
    begin
        // Shift Components
        { Debug } if debugMsg then
            addMessage('[Btn_Temper_OnClick] Shift Components Down');
        frm.Height := frm.Height + 44;
        TShift(Sender.Top + 3, 44, frm, false);
        Sender.Caption := 'Confirm Crafting Recipe';

        // Enable Scaling Label
        { Debug } if debugMsg then
            addMessage('[Btn_Temper_OnClick] Enable Scaling Label');
        lblScaling         := TLabel.Create(frm);
        lblScaling.Parent  := frm;
        lblScaling.Height  := 24;
        lblScaling.Top     := Sender.Top + 40;
        lblScaling.Left    := Sender.Left;
        lblScaling.Caption := 'Recipe Scaling: ';

        // Enable Scaling
        { Debug } if debugMsg then
            addMessage('[Btn_Temper_OnClick] Enable Scaling Check Box');
        ckScaling        := TCheckBox.Create(frm);
        ckScaling.Parent := frm;
        ckScaling.Height := lblScaling.Height;
        ckScaling.Top    := lblScaling.Top - 2;
        ckScaling.Left   := 465;
        ckScaling.Width  := 80;
        if StrWithinSL('RecipeScaling', slGlobal) then
        begin
            for i := 0 to slGlobal.Count - 1 do
                if ContainsText(slGlobal[i], 'RecipeScaling') then
                    ckScaling.Checked := StrToBool(StrPosCopy(slGlobal[i], '=', false));
        end
        else
            ckScaling.Checked := true;
    end else begin
        Sender.Caption := 'Configure Crafting Recipe';
        // Set Result
        tempObject := ComponentByTop(ComponentByCaption('Recipe Scaling: ', frm).Top - 2, frm);
        if StrWithinSL('RecipeScaling', slGlobal) then
        begin
            for i := 0 to slGlobal.Count - 1 do
            begin
                if ContainsText(slGlobal[i], 'RecipeScaling') then
                begin
                    slGlobal[i] := 'RecipeScaling=' + BoolToStr(tempObject.Checked);
                    break;
                end;
            end;
        end
        else
            slGlobal.Add('RecipeScaling=' + BoolToStr(tempObject.Checked));
        // Free Components
        slTemp.CommaText := '"Recipe Scaling: "';
        for i            := 0 to slTemp.Count - 1 do
        begin
            tempObject  := ComponentByCaption(slTemp[i], frm);
            tempInteger := tempObject.Top - 2;
            tempObject.Free;
            tempObject := ComponentByTop(tempInteger, frm);
            tempObject.Free;
        end;
        // Shift form
        TShift(Sender.Top + 3, 44, frm, true);
        frm.Height := frm.Height - 44;
    end;

    // Finalize
    slTemp.Free;

    
    // End debugMsg section
end;

procedure ELLR_Btn_Patch(Sender: TObject);
var
    tempFile, tempRecord, tempelement, TF, TFA, TFB                   : IInterface;
    lbl_FileA_Add, lbl_FileA_From, lbl_FileB_To         : TLabel;
    dd_Patch, dd_FileA, dd_FileA_Plugin, dd_FileB_Plugin: TComboBox;
    btnOk, btnCancel                                    : TButton;
    slTemp                                              : TStringList;
    existA,existB                                            : boolean;
    i, x                                                : integer;
    frm                                                 : TForm;
begin
    // Begin debugMsg section
    

    // Initialize
    slTemp := TStringList.Create;

    // Dialogue Box
    frm := TForm.Create(nil);
    try
        // Parent Form
        frm.Width    := 1680;
        frm.Height   := 200;
        frm.Position := poScreenCenter;
        frm.Caption  := 'Patch Two Specific Files';

        // File A add caption
        lbl_FileA_Add         := TLabel.Create(frm);
        lbl_FileA_Add.Parent  := frm;
        lbl_FileA_Add.Height  := 24;
        lbl_FileA_Add.Top     := 68;
        lbl_FileA_Add.Left    := 60;
        lbl_FileA_Add.Caption := 'Add';

        // Items or Enchantments Drop Down
        dd_FileA        := TComboBox.Create(frm);
        dd_FileA.Parent := frm;
        dd_FileA.Height := 24;
        dd_FileA.Top    := lbl_FileA_Add.Top - 2;
        dd_FileA.Left   := lbl_FileA_Add.Left + (10 * Length(lbl_FileA_Add.Caption)) + 20;
        dd_FileA.Width  := 180;
        dd_FileA.Items.Add('Items');
        dd_FileA.Items.Add('Enchantments');
        dd_FileA.ItemIndex := 0;
        dd_FileA.OnClick   := ELLR_OnClick_Patch_ddFileA;

        // File A from caption
        lbl_FileA_From         := TLabel.Create(frm);
        lbl_FileA_From.Parent  := frm;
        lbl_FileA_From.Height  := 24;
        lbl_FileA_From.Top     := lbl_FileA_Add.Top;
        lbl_FileA_From.Left    := dd_FileA.Left + dd_FileA.Width + 8;
        lbl_FileA_From.Caption := 'from: ';

        // FileA Plugin Drop Down
        dd_FileA_Plugin        := TComboBox.Create(frm);
        dd_FileA_Plugin.Parent := frm;
        dd_FileA_Plugin.Height := 24;
        dd_FileA_Plugin.Top    := lbl_FileA_Add.Top - 2;
        dd_FileA_Plugin.Left   := lbl_FileA_From.Left + (10 * Length(lbl_FileA_From.Caption));
        dd_FileA_Plugin.Width  := 500;
        for i                  := 0 to Pred(FileCount) do
            dd_FileA_Plugin.Items.Add(GetFileName(FileByIndex(i)));
        dd_FileA_Plugin.AutoComplete := true;
        dd_FileA_Plugin.Sorted       := true;

        // File B Variable Label
        lbl_FileB_To         := TLabel.Create(frm);
        lbl_FileB_To.Parent  := frm;
        lbl_FileB_To.Height  := 24;
        lbl_FileB_To.Top     := dd_FileA.Top + 1;
        lbl_FileB_To.Left    := dd_FileA_Plugin.Left + dd_FileA_Plugin.Width + 8;
        lbl_FileB_To.Caption := 'to Leveled Lists from: ';

        // File B Plugin Drop Down
        dd_FileB_Plugin        := TComboBox.Create(frm);
        dd_FileB_Plugin.Parent := frm;
        dd_FileB_Plugin.Height := 24;
        dd_FileB_Plugin.Top    := dd_FileA.Top - 1;
        dd_FileB_Plugin.Left   := lbl_FileB_To.Left + (10 * Length(lbl_FileB_To.Caption) - 20);
        dd_FileB_Plugin.Width  := dd_FileA_Plugin.Width;
        for i                  := 0 to Pred(FileCount) do
            dd_FileB_Plugin.Items.Add(GetFileName(FileByIndex(i)));
        dd_FileB_Plugin.AutoComplete := true;
        dd_FileB_Plugin.Sorted       := true;

        // Ok Button
        btnOk             := TButton.Create(frm);
        btnOk.Parent      := frm;
        btnOk.Caption     := 'Ok';
        btnOk.Left        := (frm.Width div 2) - btnOk.Width - 8;
        btnOk.Top         := frm.Height - 80;
        btnOk.ModalResult := mrOk;

        // Cancel Button
        btnCancel             := TButton.Create(frm);
        btnCancel.Parent      := frm;
        btnCancel.Caption     := 'Cancel';
        btnCancel.Left        := btnOk.Left + btnOk.Width + 16;
        btnCancel.Top         := btnOk.Top;
        btnCancel.ModalResult := mrCancel;

        frm.ShowModal;
        if (frm.ModalResult = mrOk) then
        begin
			existA := false;
			existB := false;
			TFA := FileByName(dd_FileA_Plugin.Text);
			TFB := FileByName(dd_FileB_Plugin.Text);
            if Assigned(TFA) and assigned(TFB) then
            begin
                // Sender.Parent.Visible := False;
                slGlobal.clear;
				existA := false;
				TF := FileByName('Patch_' + dd_FileA_Plugin.Text + '_' + dd_FileB_Plugin.Text, existA);
                if not existA then
                begin
                    SetObject('ALLAfile', AddNewFileName('Patch_' + dd_FileA_Plugin.Text + '_' + dd_FileB_Plugin.Text), slGlobal);
                end
                else
                    SetObject('ALLAfile', TF, slGlobal);
                { Debug } if debugMsg then
                    addMessage('[ELLR_Btn_Patch] ALLAfile := ' + GetFileName(ObjectToElement(GetObject('ALLAfile', slGlobal))));
                SetObject('Patch', TFB, slGlobal);
                slTemp.CommaText := 'AMMO, ARMO, WEAP';
                for i            := 0 to slTemp.Count - 1 do
                begin
                    tempelement := GroupBySignature(TFA, slTemp[i]);
                    for x       := 0 to Pred(ElementCount(tempelement)) do
                    begin
                        tempRecord := elementbyindex(tempelement, x);
                        if not(Length(EditorID(tempRecord)) > 0) then
                            Continue SetObject(EditorID(tempRecord) + 'Original', tempRecord, slGlobal);
                        SetObject(EditorID(tempRecord) + 'Template', GetTemplate(tempRecord), slGlobal);
                    end;
                end;
            end;
            { Debug } if debugMsg then
                msgList('[ELLR_Btn_Patch] slGlobal := ', slGlobal, '');
            Sender.Parent.ModalResult := mrRetry;
        end;
    finally
        frm.Free;
    end;

    // Finalize
    slTemp.Free;

    
    // End debugMsg section
end;

procedure GEV_GeneralSettings;
var
    lblpercent, lblEnchantmentMultiplier, lblEnchantmentPercent, lblAllowUnenchanting, lblAddtoLL         : TLabel;
    lblChance, lblDetectedItem, lblDetectedItemText, lblGEVfile, ckPercent, ckAllowUnenchanting, ckAddtoLL: TCheckBox;
    btnOk, btnCancel, btnAdvanced, btnRemove, btnItemTierLevels, btnBulk, btnPatch                        : TButton;
    ddChance, ddEnchantmentMultiplier, ddGEVfile, ddAddtoLL                                               : TComboBox;
    tempBoolean                                                                                 : boolean;
    frm                                                                                                   : TForm;
    i                                                                                                     : integer;
begin
    // Begin debugMsg Section
    

    // Initialize Local
    if not Assigned(slGlobal) then
        slGlobal := TStringList.Create;

    frm := TForm.Create(nil);
    try
        // Parent Form; Entire Box
        frm.Width    := 650;
        frm.Height   := 180;
        frm.Position := poScreenCenter;
        frm.Caption  := 'Generate Enchanted Versions Settings';

        // Currently Selected Item Label
        lblDetectedItemText         := TLabel.Create(frm);
        lblDetectedItemText.Parent  := frm;
        lblDetectedItemText.Height  := 24;
        lblDetectedItemText.Top     := 80;
        lblDetectedItemText.Left    := 60;
        lblDetectedItemText.Caption := 'Currently Selected Item: ';
        frm.Height                  := frm.Height + lblDetectedItemText.Height + 18;

        // Currently Selected Item
        lblDetectedItem         := TLabel.Create(frm);
        lblDetectedItem.Parent  := frm;
        lblDetectedItem.Height  := lblDetectedItemText.Height;
        lblDetectedItem.Top     := lblDetectedItemText.Top;
        lblDetectedItem.Left    := lblDetectedItemText.Left + (10 * Length(lblDetectedItemText.Caption));
        lblDetectedItem.Caption := FULL(selectedRecord);

        // Output Plugin Label
        lblGEVfile         := TLabel.Create(frm);
        lblGEVfile.Parent  := frm;
        lblGEVfile.Height  := lblDetectedItemText.Height;
        lblGEVfile.Top     := lblDetectedItemText.Top + lblDetectedItemText.Height + 18;
        lblGEVfile.Left    := lblDetectedItemText.Left;
        lblGEVfile.Caption := 'Output Plugin: ';
        frm.Height         := frm.Height + lblGEVfile.Height + 18;

        // Output Plugin Edit Box
        ddGEVfile        := TComboBox.Create(frm);
        ddGEVfile.Parent := frm;
        ddGEVfile.Height := lblDetectedItemText.Height;
        ddGEVfile.Top    := lblGEVfile.Top - 2;
        ddGEVfile.Left   := lblGEVfile.Left + (9 * Length(lblGEVfile.Caption)) + 36;
        ddGEVfile.Width  := 280;
        if slContains(slGlobal, 'GEVfile') then
            ddGEVfile.Items.Add(GetFileName(ObjectToElement(GetObject('GEVfile', slGlobal))))
        else
            ddGEVfile.Items.Add(defaultOutputPlugin);
        ddGEVfile.ItemIndex := 0;

        // Item Tier Levels
        btnItemTierLevels         := TButton.Create(frm);
        btnItemTierLevels.Parent  := frm;
        btnItemTierLevels.Top     := lblGEVfile.Top + lblGEVfile.Height + 18;
        btnItemTierLevels.Height  := 24;
        btnItemTierLevels.Left    := lblGEVfile.Left + 10 * Length(btnItemTierLevels.Caption);
        btnItemTierLevels.Caption := 'Configure Tiers';
        btnItemTierLevels.Width   := 450;
        frm.Height                := frm.Height + btnItemTierLevels.Height + 18;
        btnItemTierLevels.OnClick := Btn_ItemTierLevels_OnClick;

        // Replace in Leveled List Label
        lblAddtoLL         := TLabel.Create(frm);
        lblAddtoLL.Parent  := frm;
        lblAddtoLL.Height  := lblDetectedItemText.Height;
        lblAddtoLL.Top     := btnItemTierLevels.Top + btnItemTierLevels.Height + 18;;
        lblAddtoLL.Left    := lblGEVfile.Left;
        lblAddtoLL.Caption := 'Replace in Leveled Lists: ';
        frm.Height         := frm.Height + lblAddtoLL.Height + 18;

        // Replace in Leveled List Check Box
        ckAddtoLL        := TCheckBox.Create(frm);
        ckAddtoLL.Parent := frm;
        ckAddtoLL.Height := lblAddtoLL.Height;
        ckAddtoLL.Left   := 485;
        ckAddtoLL.Top    := lblAddtoLL.Top;
        if slContains(slGlobal, 'ReplaceInLeveledList') then
            ckAddtoLL.Checked := boolean(GetObject('ReplaceInLeveledList', slGlobal))
        else
            ckAddtoLL.Checked := true;

        // Allow Unenchanting Label
        lblAllowUnenchanting         := TLabel.Create(frm);
        lblAllowUnenchanting.Parent  := frm;
        lblAllowUnenchanting.Height  := 24;
        lblAllowUnenchanting.Top     := lblAddtoLL.Top + lblAddtoLL.Height + 18;
        lblAllowUnenchanting.Left    := lblGEVfile.Left;
        lblAllowUnenchanting.Caption := 'Allow Unenchanting: ';
        frm.Height                   := frm.Height + lblAllowUnenchanting.Height + 18;

        // Allow Unenchanting Check Box
        ckAllowUnenchanting        := TCheckBox.Create(frm);
        ckAllowUnenchanting.Parent := frm;
        ckAllowUnenchanting.Height := 24;
        ckAllowUnenchanting.Top    := lblAllowUnenchanting.Top;
        ckAllowUnenchanting.Left   := ckAddtoLL.Left;
        if slContains(slGlobal, 'AllowDisenchanting') then
            ckAllowUnenchanting.Checked := boolean(GetObject('AllowDisenchanting', slGlobal))
        else
            ckAllowUnenchanting.Checked := true;

        // Percent Chance Label
        lblChance         := TLabel.Create(frm);
        lblChance.Parent  := frm;
        lblChance.Left    := lblGEVfile.Left;
        lblChance.Top     := lblAllowUnenchanting.Top + lblAllowUnenchanting.Height + 18;
        lblChance.Caption := 'Use Percent Chance: ';
        frm.Height        := frm.Height + lblChance.Height + 8;

        // Percent Chance Check Box
        ckPercent        := TCheckBox.Create(frm);
        ckPercent.Parent := frm;
        ckPercent.Height := lblGEVfile.Height;
        ckPercent.Left   := ckAddtoLL.Left;
        ckPercent.Top    := lblChance.Top;
        if slContains(slGlobal, 'ChanceBoolean') then
            ckPercent.Checked := boolean(GetObject('ChanceBoolean', slGlobal))
        else
            ckPercent.Checked := true;

        // Generate Enchanted Versions % Chance Label
        lblpercent         := TLabel.Create(frm);
        lblpercent.Parent  := frm;
        lblpercent.Height  := ddGEVfile.Height;
        lblpercent.Left    := ckPercent.Left + 20;
        lblpercent.Top     := lblChance.Top;
        lblpercent.Caption := '%';

        // Generate Enchanted Versions % Chance Edit Box
        ddChance        := TComboBox.Create(frm);
        ddChance.Parent := frm;
        ddChance.Height := lblpercent.Height;
        ddChance.Left   := lblpercent.Left + 25;
        ddChance.Top    := lblChance.Top - 3;
        ddChance.Width  := 80;
        if slContains(slGlobal, 'ChanceMultiplier') then
            ddChance.Items.Add(IntToStr(integer(slGlobal.Objects[slGlobal.IndexOf('ChanceMultiplier')])))
        else
            ddChance.Items.Add('10');
        ddChance.ItemIndex := 0;

        // Enchantment Multiplier Label
        lblEnchantmentMultiplier         := TLabel.Create(frm);
        lblEnchantmentMultiplier.Parent  := frm;
        lblEnchantmentMultiplier.Left    := lblGEVfile.Left;
        lblEnchantmentMultiplier.Top     := lblChance.Top + lblChance.Height + 18;
        lblEnchantmentMultiplier.Caption := 'Enchantment Strength: ';
        frm.Height                       := frm.Height + lblEnchantmentMultiplier.Height + 18;

        // Enchantment Multiplier Edit Box
        ddEnchantmentMultiplier        := TComboBox.Create(frm);
        ddEnchantmentMultiplier.Parent := frm;
        ddEnchantmentMultiplier.Height := lblEnchantmentMultiplier.Height;
        ddEnchantmentMultiplier.Left   := ddChance.Left;
        ddEnchantmentMultiplier.Top    := lblEnchantmentMultiplier.Top - 1;
        ddEnchantmentMultiplier.Width  := ddChance.Width;
        if slContains(slGlobal, 'EnchMultiplier') then
            ddEnchantmentMultiplier.Items.Add(IntToStr(integer(slGlobal.Objects[slGlobal.IndexOf('EnchMultiplier')])))
        else
            ddEnchantmentMultiplier.Items.Add('100');
        ddChance.ItemIndex                := 0;
        ddEnchantmentMultiplier.ItemIndex := 0;

        // Generate Enchanted Versions % Chance Label
        lblEnchantmentPercent         := TLabel.Create(frm);
        lblEnchantmentPercent.Parent  := frm;
        lblEnchantmentPercent.Height  := ddEnchantmentMultiplier.Height;
        lblEnchantmentPercent.Left    := lblpercent.Left;
        lblEnchantmentPercent.Top     := ddEnchantmentMultiplier.Top + 4;
        lblEnchantmentPercent.Caption := '%';

        if StrWithinSL('NoButtons', slGlobal) then
        begin
            frm.Height := frm.Height - 50;
            TShift(0, 50, frm, true);
        end else begin
            // Remove Button
            btnRemove         := TButton.Create(frm);
            btnRemove.Parent  := frm;
            btnRemove.Caption := 'Remove';
            btnRemove.Left    := lblGEVfile.Left;
            btnRemove.Top     := 20;
            btnRemove.Width   := 100;
            btnRemove.OnClick := GEV_Btn_Remove;

            // Patch Button
            btnPatch         := TButton.Create(frm);
            btnPatch.Parent  := frm;
            btnPatch.Caption := 'Patch';
            btnPatch.Left    := 285;
            btnPatch.Top     := 20;
            btnPatch.Width   := 100;
            btnPatch.OnClick := ELLR_Btn_Patch;

            // Bulk Button
            btnBulk         := TButton.Create(frm);
			btnBulk.Parent  := frm;
			btnBulk.Caption := 'DO NOT USE';
			btnBulk.ShowHint := 'vestigial method which has no use anymore. will be replaced with something better soon';
			btnBulk.Left    := frm.Width - 150;
			btnBulk.Top     := 20;
			btnBulk.Width   := 100;
			btnBulk.OnClick := Btn_Bulk_OnClick_Old;
        end;

        // Ok Button
        btnOk             := TButton.Create(frm);
        btnOk.Parent      := frm;
        btnOk.Caption     := 'Ok';
        btnOk.ModalResult := mrOk;
        btnOk.Left        := (frm.Width div 2) - btnOk.Width - 8;
        btnOk.Top         := frm.Height - 80;

        // Cancel Button
        btnCancel             := TButton.Create(frm);
        btnCancel.Parent      := frm;
        btnCancel.Caption     := 'Cancel';
        btnCancel.ModalResult := mrCancel;
        btnCancel.Left        := btnOk.Left + btnOk.Width + 16;
        btnCancel.Top         := btnOk.Top;

        // What happens when Ok is pressed
        frm.ShowModal;
        if (frm.ModalResult = mrOk) then
        begin
            if not StrEndsWith(ddGEVfile.Caption, '.esl') then
                AppendIfMissing(ddGEVfile.Caption, '.esp');
            SetObject('CancelAll', false, slGlobal);
            { Debug } if debugMsg then
                addMessage('[GEV_GeneralSettings] CancelAll := ' + BoolToStr(boolean(GetObject('CancelAll', slGlobal))));
            SetObject('GEVfile', FileByName(ddGEVfile.Caption), slGlobal);
            { Debug } if debugMsg then
                addMessage('[GEV_GeneralSettings] GEVfile := ' + GetFileName(ObjectToElement(GetObject('GEVfile', slGlobal))));
            SetObject('ChanceBoolean', ckPercent.Checked, slGlobal);
            { Debug } if debugMsg then
                addMessage('[GEV_GeneralSettings] ChanceBoolean := ' + BoolToStr(boolean(GetObject('ChanceBoolean', slGlobal))));
            SetObject('ReplaceInLeveledList', ckAddtoLL.Checked, slGlobal);
            { Debug } if debugMsg then
                addMessage('[GEV_GeneralSettings] ReplaceInLeveledList := ' + BoolToStr(boolean(GetObject('ReplaceInLeveledList', slGlobal))));
            SetObject('ChanceMultiplier', StrToInt(ddChance.Text), slGlobal);
            { Debug } if debugMsg then
                addMessage('[GEV_GeneralSettings] ChanceMultiplier := ' + IntToStr(integer(GetObject('ChanceMultiplier', slGlobal))));
            SetObject('AllowDisenchanting', ckAllowUnenchanting.Checked, slGlobal);
            { Debug } if debugMsg then
                addMessage('[GEV_GeneralSettings] AllowDisenchanting := ' + BoolToStr(boolean(GetObject('AllowDisenchanting', slGlobal))));
            SetObject('EnchMultiplier', StrToInt(ddEnchantmentMultiplier.Text), slGlobal);
            { Debug } if debugMsg then
                addMessage('[GEV_GeneralSettings] EnchMultiplier := ' + IntToStr(integer(GetObject('EnchMultiplier', slGlobal))));
        end;
    finally
        frm.Free;
    end;

    
    // End debugMsg Section
end;

// Creates an enchanted copy of the item record and returns it [From Generate Enchanted Versions]
function CreateEnchantedVersion(aRecord, aPlugin, objEffect, enchRecord: IInterface; suffix: string; enchAmount: integer; aBoolean: boolean): IInterface;
var
    startTime, stopTime: TDateTime;
    tempRecord         : IInterface;
    tempString         : string;
    enchCost           : integer;
begin
    // Initialize
    
    startTime := Time;

    { Debug } if debugMsg then
        addMessage('[CreateEnchantedVersion] Begin');
    { Debug } if debugMsg then
        addMessage('[CreateEnchantedVersions] CreateEnchantedVersion(' + EditorID(aRecord) + ', ' + GetFileName(aPlugin) + ', ' + EditorID(objEffect) + ', ' + EditorID(enchRecord) + ', ' + suffix + ', ' + IntToStr(enchAmount) + ' );');

    // Create new enchantment if one is not detected
    BeginUpdate(enchRecord);
    try
        { Debug } if debugMsg then
            addMessage('[CreateEnchantedVersions] SetElementEditValues(enchRecord, EditorID, ' + EditorID(aRecord) + '_' + EditorID(objEffect) + ' );');
        SetElementEditValues(enchRecord, 'EDID', EditorID(aRecord) + '_' + EditorID(objEffect));
        SetElementEditValues(enchRecord, 'EITM', GetEditValue(objEffect));
        if (enchAmount = 0) then
            enchAmount := 1;
        SetElementEditValues(enchRecord, 'EAMT', enchAmount);
        SetElementEditValues(enchRecord, 'FULL', FULL(aRecord) + ' of ' + Trim(suffix));
        // Set template so that enchanted version will use base record's COBJ
        if (Signature(aRecord) = 'WEAP') then
        begin
            { Debug } if debugMsg then
                addMessage('[CreateEnchantedVersions] SetElementEditValues(' + EditorID(enchRecord) + ', CNAM, ' + ShortName(aRecord) + ' );');
            SetElementEditValues(enchRecord, 'CNAM', ShortName(aRecord));
        end
        else
            if (Signature(aRecord) = 'ARMO') then
            begin
                { Debug } if debugMsg then
                    addMessage('[CreateEnchantedVersions] SetElementEditValues(' + EditorID(enchRecord) + ', TNAM, ' + ShortName(aRecord) + ' );');
                SetElementEditValues(enchRecord, 'TNAM', ShortName(aRecord));
            end;

        // Disallow enchanting
        if not aBoolean then
        begin
            if not HasKeyword(enchRecord, 'DisallowEnchanting') then
            begin
                enchRecord := wbCopyElementToFile(enchRecord, aPlugin, false, true);
                SetElementEditValues(enchRecord, 'EDID', EditorID(aRecord) + '_' + EditorID(objEffect) + '_DisallowEnchanting');
                AddKeyword(enchRecord, getRecordByFormID('000C27BD'));
            end;
        end;
    finally
        EndUpdate(enchRecord);
    end;

    // Finalize
    { Debug } if debugMsg then
        addMessage('[CreateEnchantedVersions] Result := ' + EditorID(enchRecord));
    result := enchRecord;
    if ProcessTime then
    begin
        stopTime := Time;
        addProcessTime('createEnchantedVersion', TimeBtwn(startTime, stopTime));
    end;
end;

// Generates enchanted versions of a list of records from a list of input files
procedure GenerateEnchantedVersionsAuto;
var
    slTemp, slItem, slItemTiers, slIndex, slFiles, slTempList, slRecords, slEnchanted, slExistingRecords, slBOD2: TStringList;
    tempRecord, tempelement, objEffect, enchLevelList, chanceLevelList, GEVfile, TF                             : IInterface;
    tempBoolean, AllowDisenchanting, ReplaceInLeveledList, exist                                      : boolean;
    tempString, suffix, record_sig, Record_edid, PatchFile, enchString                                          : string;
    startTime, stopTime, tempStartTime, tempStopTime, processStartTime, processStopTime                         : TDateTime;
    enchAmount, enchMultiplier                                                                                  : Float;
    i, x, y, z, tempInteger, enchCount                                                                          : integer;
begin
    // Initialize
    
    startTime := Time;
    if not Assigned(slExistingRecords) then
        slExistingRecords := TStringList.Create;
    if not Assigned(slEnchanted) then
        slEnchanted := TStringList.Create;
    if not Assigned(slItemTiers) then
        slItemTiers := TStringList.Create;
    if not Assigned(slTempList) then
        slTempList := TStringList.Create;
    if not Assigned(slRecords) then
        slRecords := TStringList.Create;
    if not Assigned(slGlobal) then
        slGlobal := TStringList.Create;
    if not Assigned(slIndex) then
        slIndex := TStringList.Create;
    if not Assigned(slFiles) then
        slFiles := TStringList.Create;
    if not Assigned(slBOD2) then
        slBOD2 := TStringList.Create;
    if not Assigned(slItem) then
        slItem := TStringList.Create;
    if not Assigned(slTemp) then
        slTemp := TStringList.Create;

    // Detect loaded plugins
    slTemp.CommaText := 'Skyrim.esm, Dawnguard.esm, Hearthfires.esm, Dragonborn.esm, HolyEnchants.esp, LostEnchantments.esp, "More Interesting Loot for Skyrim.esp", "Summermyst - Enchantments of Skyrim.esp", "Wintermyst - Enchantments of Skyrim.esp"';
    for i            := 0 to slTemp.Count - 1 do begin
		exist := false;
		TF := FileByName(slTemp[i]);
        if assigned(TF) then
            slFiles.addObject(Trim(slTemp[i]), TF);
	end;
    { Debug } if debugMsg then
        msgList('[GenerateEnchantedVersionsAuto] slFiles := ', slFiles, '');

    // Skips dlg if external input is present
    { Debug } if debugMsg then
        msgList('[GenerateEnchantedVersionsAuto] slGlobal := ', slGlobal, '');
    { Debug } if debugMsg then
        addMessage('[GenerateEnchantedVersionsAuto] AllowDisenchanting := ' + BoolToStr(boolean(GetObject('AllowDisenchanting', slGlobal))));
    AllowDisenchanting := boolean(GetObject('AllowDisenchanting', slGlobal));
    if slContains(slGlobal, 'AddtoLeveledList') then
        ReplaceInLeveledList := boolean(GetObject('AddtoLeveledList', slGlobal))
    else
        ReplaceInLeveledList := boolean(GetObject('ReplaceInLeveledList', slGlobal));
    GEVfile                  := ObjectToElement(GetObject('GEVfile', slGlobal));
    enchMultiplier           := integer(GetObject('EnchMultiplier', slGlobal));
    { Debug } if debugMsg then
        addMessage('[GenerateEnchantedVersionsAuto] enchMultiplier := ' + IntToStr(enchMultiplier));

    // Prep File
    if not Assigned(GEVfile) then
    begin
        GEV_GeneralSettings;
        GEVfile := ObjectToElement(GetObject('GEVfile', slGlobal));
    end;
    if Assigned(GEVfile) then
    begin
        // Create the necessary groups
        slTemp.CommaText := 'LVLI, ARMO, WEAP, COBJ, KYWD';
        for x            := 0 to slTemp.Count - 1 do
            if not HasGroup(GEVfile, slTemp[x]) then
                Add(GEVfile, slTemp[x], true);
    end else begin
        addMessage('[ERROR] [GenerateEnchantedVersionsAuto] GEVfile unassigned');
        if Assigned(slExistingRecords) then
            slExistingRecords.Free;
        if Assigned(slEnchanted) then
            slEnchanted.Free;
        if Assigned(slItemTiers) then
            slItemTiers.Free;
        if Assigned(slTempList) then
            slTempList.Free;
        if Assigned(slRecords) then
            slRecords.Free;
        if Assigned(slIndex) then
            slIndex.Free;
        if Assigned(slFiles) then
            slFiles.Free;
        if Assigned(slBOD2) then
            slBOD2.Free;
        if Assigned(slTemp) then
            slTemp.Free;
        if Assigned(slItem) then
            slItem.Free;
        exit;
    end;
    { Debug } if debugMsg then
        addMessage('[GenerateEnchantedVersionsAuto] AllowDisenchanting := ' + BoolToStr(boolean(GetObject('AllowDisenchanting', slGlobal))));

    // Load slRecords with all valid original records
    for i := 0 to slGlobal.Count - 1 do
        if ContainsText(slGlobal[i], 'Original') then
            SetObject(StrPosCopy(slGlobal[i], 'Original', true), slGlobal.Objects[i], slRecords);
    { Debug } if debugMsg then
        msgList('slGlobal := ', slGlobal, '');
    { Debug } if debugMsg then
        msgList('slRecords := ', slRecords, '');

    // Add masters
    tempStartTime := Time;

    tempStopTime := Time;
    if ProcessTime then
        addProcessTime('Add Masters', TimeBtwn(tempStartTime, tempStopTime));

    // Build indexes of loaded plugins
    tempStartTime := Time;
    { Debug } if debugMsg then
        addMessage('[GenerateEnchantedVersionsAuto] Build indexes of loaded plugins');
    slTemp.clear;
    // Get keywords
    for x := 0 to slRecords.Count - 1 do
    begin
        tempRecord := ObjectToElement(slRecords.Objects[x]);
        if (Signature(tempRecord) = 'ARMO') then
        begin
            slItem.clear;
            slGetFlagValues(tempRecord, slItem, false);
            // Add clothing type to keywords
            for y := 0 to slItem.Count - 1 do
            begin
                if not((slItem[y] = '35') or (slItem[y] = '36') or (slItem[y] = '42')) then
                    slItem[y] := slItem[y] + '-' + GetElementEditValues(tempRecord, GetElementType(tempRecord) + '\Armor Type');
            end;
            // This is an index for the BOD2 slots so they don't have to be generated again in 'Process'
            if (slItem.Count > 0) then
            begin
                for y          := 0 to slItem.Count - 1 do
                    tempString := tempString + ' ' + slItem[y];
                slBOD2.Add(EditorID(tempRecord) + '-//-' + tempString);
            end;
            // Non-vanilla armor types prioritize keywords over BOD2
            slTempList.CommaText := '30, 32, 33, 37, 39'; // 30 - Head, 32 - Body, 33 - Gauntlers, 37 - Feet, 39 - Shield
            for y                := 0 to slItem.Count - 1 do
                if not StrWithinSL(slItem[y], slTempList) then
                    if not slContains(slItem, AssociatedBOD2(slItem[y])) then
                        slItem.Add(AssociatedBOD2(slItem[y]));
            for y := 0 to slItem.Count - 1 do
                if not slContains(slTemp, slItem[y]) then
                    slTemp.Add(slItem[y]);
        end
        else
            if not slContains(slTemp, Signature(tempRecord)) then
                slTemp.Add(Signature(tempRecord));
        slClearEmptyStrings(slTemp);
    end;
    { Debug } if debugMsg then
        msgList('[GenerateEnchantedVersionsAuto] Keywords (slTemp) := ', slTemp, '');
    for x := 0 to slFiles.Count - 1 do
    begin
        tempInteger := ElementCount(GroupBySignature(ObjectToElement(slFiles.Objects[x]), 'ENCH'));
        enchCount   := enchCount + tempInteger;
        addMessage('Indexing ' + IntToStr(tempInteger) + ' Enchantments in ' + slFiles[x]);
        IndexObjEffect(ObjectToElement(slFiles.Objects[x]), slTemp, slIndex);
    end;
    if debugMsg then
        msgList('[GenerateEnchantedVersionsAuto] slIndex := ', slIndex, '');
    tempStopTime := Time;
    addProcessTime('Create Library of ' + IntToStr(enchCount) + ' Enchantments', TimeBtwn(tempStartTime, tempStopTime));

    // Set Item Tiers
    for x := 1 to 6 do
        SetObject('0' + IntToStr(x), integer(GetObject('ItemTier0' + IntToStr(x), slGlobal)), slItemTiers);

    // Get a list of existing records
    slExistingRecords.clear;
    slTemp.CommaText := 'ARMO, AMMO, WEAP';
    for x            := 0 to slTemp.Count - 1 do
    begin
        tempelement := GroupBySignature(GEVfile, slTemp[x]);
        for y       := 0 to Pred(ElementCount(tempelement)) do
            slExistingRecords.Add(EditorID(elementbyindex(tempelement, y)));
    end;
    // {Debug} if debugMsg then msgList('[GenerateEnchantedVersionsAuto] slExistingRecords := ', slExistingRecords, '');

    // Process
    processStartTime := Time;
    for i            := 0 to slRecords.Count - 1 do
    begin
        // Common function output
        { Debug } if debugMsg then
            msgList('[GenerateEnchantedVersionsAuto] slRecords := ', slRecords, '');
        selectedRecord := ObjectToElement(slRecords.Objects[i]);
        { Debug } if debugMsg then
            addMessage('[GenerateEnchantedVersionsAuto] selectedRecord := ' + EditorID(ObjectToElement(slRecords.Objects[i])));
        record_sig := Signature(selectedRecord);
        { Debug } if debugMsg then
            addMessage('[GenerateEnchantedVersionsAuto] record_sig := ' + record_sig);
        Record_edid := EditorID(selectedRecord);

        // Detect Pre-Existing Leveled Lists
        if ProcessTime then
            tempStartTime := Time;
        { Debug } if debugMsg then
            addMessage('[GenerateEnchantedVersionsAuto] Detecting Pre-Existing Leveled Lists');
        enchLevelList   := nil;
        chanceLevelList := nil;
        for x           := 0 to Pred(ReferencedByCount(selectedRecord)) do
        begin
            tempRecord := ReferencedByIndex(selectedRecord, x);
            if (Signature(tempRecord) = 'LVLI') then
            begin
                tempString := EditorID(tempRecord);
                if ContainsText(tempString, 'Ench') and ContainsText(tempString, '++') then
                begin
                    if ContainsText(tempString, 'Chance') then
                    begin
                        if not(GetLoadOrder(GEVfile) = GetLoadOrder(GetFile(tempRecord))) then
                            chanceLevelList := wbCopyElementToFile(tempRecord, GEVfile, false, true)
                        else
                            chanceLevelList := tempRecord;
                    end else begin
                        if not(GetLoadOrder(GEVfile) = GetLoadOrder(GetFile(tempRecord))) then
                            enchLevelList := wbCopyElementToFile(tempRecord, GEVfile, false, true)
                        else
                            enchLevelList := tempRecord;
                    end;
                end;
                if Assigned(enchLevelList) and Assigned(chanceLevelList) then
                    break;
            end;
        end;
        if ProcessTime then
        begin
            tempStopTime := Time;
            addProcessTime('[GEV] Detect Pre-Existing Leveled Lists', TimeBtwn(tempStartTime, tempStopTime));
        end;

        // Create new Leveled Lists if not already present
        { Debug } if debugMsg then
            addMessage('[GenerateEnchantedVersionsAuto] Create new Leveled Lists if not already present');
        if not Assigned(enchLevelList) then
        begin
            slTemp.CommaText := '"Calculate from all levels <= player''s level", "Calculate for each item in count"';
            { Debug } if debugMsg then
                msgList('createLeveledList(' + GetFileName(GEVfile) + ', LItem' + StrCapFirst(record_sig) + 'Ench' + Record_edid + '++, ', slTemp, ', 0 );');
            enchLevelList := createLeveledList(GEVfile, 'LItem' + StrCapFirst(record_sig) + 'Ench' + Record_edid + '++', slTemp, 0);
            addToLeveledList(enchLevelList, selectedRecord, 1);
        end;
        if not Assigned(chanceLevelList) then
        begin
            { Debug } if debugMsg then
                addMessage('[GenerateEnchantedVersionsAuto] createChanceLeveledList(' + GetFileName(GEVfile) + ', LItem' + StrCapFirst(record_sig) + 'EnchChance' + Record_edid + '++, ' + IntToStr(integer(GetObject('ChanceMultiplier', slGlobal))) + ', ' + Record_edid + ', ' + EditorID(enchLevelList) + ' );');
            chanceLevelList := createChanceLeveledList(GEVfile, 'LItem' + StrCapFirst(record_sig) + 'EnchChance' + Record_edid + '++', integer(GetObject('ChanceMultiplier', slGlobal)), selectedRecord, enchLevelList);
            slEnchanted.addObject(Record_edid, chanceLevelList);
        end;

        // Process records using the indexed list
        tempStartTime := Time;
        addMessage('[' + IntToStr(i + 1) + '/' + IntToStr(slRecords.Count) + '] Processing ' + Record_edid + ' enchanted versions');
        { Debug } if debugMsg then
            addMessage('record_sig := ' + record_sig);
        // Get BOD2 list from BOD2 index
        for x := 0 to slBOD2.Count - 1 do
        begin
            if (StrPosCopy(slBOD2[x], '-//-', true) = Record_edid) then
            begin
                slTemp.CommaText := StrPosCopy(slBOD2[x], '-//-', false);
                break;
            end;
        end;

        // Use library to add enchantments
        for x := 0 to slIndex.Count - 1 do
        begin
            objEffect  := nil;
            suffix     := StrPosCopy(slIndex[x], '-//-', true);
            enchString := StrPosCopy(slIndex[x], '-//-', false);
            if (record_sig = 'ARMO') then
            begin
                { Debug } if debugMsg then
                    msgList('[GenerateEnchantedVersionsAuto] slTemp := ', slTemp, '');
                if SLWithinStr(enchString, slTemp) then
                begin
                    objEffect := ObjectToElement(slIndex.Objects[x]);
                    { Debug } if debugMsg then
                        addMessage('[GenerateEnchantedVersionsAuto] objEffect := ' + EditorID(objEffect));
                end;
            end
            else
                if ContainsText(enchString, record_sig) then
                begin
                    objEffect := ObjectToElement(slIndex.Objects[x]);
                    { Debug } if debugMsg then
                        addMessage('[GenerateEnchantedVersionsAuto] objEffect := ' + EditorID(objEffect));
                end;
            if Assigned(objEffect) then
            begin
                tempInteger := GetEnchLevel(objEffect, slItemTiers); { Debug }
                if debugMsg then
                    addMessage('[GenerateEnchantedVersionsAuto] enchLevel := ' + IntToStr(tempInteger));
                if (tempInteger > 0) then
                begin
                    { Debug } if debugMsg then
                        addMessage('[GenerateEnchantedVersionsAuto] enchAmount := ' + IntToStr((enchMultiplier * GetElementNativeValues(objEffect, 'ENIT\Enchantment Amount')) div 100) + ' * ' + IntToStr(GetElementNativeValues(objEffect, 'ENIT\Enchantment Amount')));
                    enchAmount := (enchMultiplier * GetEnchAmount(tempInteger)) div 100;
                    // Pre-Existing records
                    if not slContains(slExistingRecords, EditorID(selectedRecord) + '_' + EditorID(objEffect)) then
                    begin
                        tempelement := wbCopyElementToFile(selectedRecord, GEVfile, true, true); { Debug }
                        if debugMsg then
                            addMessage('[GenerateEnchantedVersionsAuto] enchRecord := ' + EditorID(tempelement));
                    end
                    else
                        Continue;
                    // Generate Enchantment
                    tempRecord := CreateEnchantedVersion(selectedRecord, GEVfile, objEffect, tempelement, suffix, Round(enchAmount), AllowDisenchanting); { Debug }
                    if debugMsg then
                        addMessage('[GenerateEnchantedVersionsAuto] tempRecord := CreateEnchantedVersion(' + Record_edid + ', ' + GetFileName(GEVfile) + ', ' + EditorID(objEffect) + ', ' + EditorID(tempelement) + ', ' + StrPosCopy(FULL(objEffect), 'of', false) + ', ' + IntToStr(Round(enchAmount)) + ', ' + BoolToStr(AllowDisenchanting) + ' );');
                    addToLeveledList(enchLevelList, tempRecord, tempInteger); { Debug }
                    if debugMsg then
                        addMessage('[GenerateEnchantedVersionsAuto] AddToLeveledList(' + EditorID(enchLevelList) + ', ' + EditorID(tempRecord) + ', ' + IntToStr(tempInteger) + ' );');
                    slExistingRecords.Add(EditorID(tempRecord));
                end;
            end;
        end;

        // This replaces records in the vanilla leveled lists
        if ReplaceInLeveledList then
        begin
            // Add to enchanted lists
            tempelement := nil;
            if (Signature(selectedRecord) = 'WEAP') then
            begin
                tempelement := MainRecordByEditorID(GroupBySignature(FileByName('Skyrim.esm'), 'LVLI'), 'LItemEnch' + EditorID(ObjectToElement(GetObject(EditorID(selectedRecord) + 'Template', slGlobal)))); { Debug }
                if debugMsg then
                    addMessage('[GenerateEnchantedVersionsAuto] tempElement := ' + EditorID(tempelement));
            end
            else
                tempelement := MainRecordByEditorID(GroupBySignature(FileByName('Skyrim.esm'), 'LVLI'), 'LItemEnchArmor' + StrPosCopy(GetElementEditValues(selectedRecord, GetElementType(selectedRecord) + '\Armor Type'), ' ', true) + GetItemType(selectedRecord)); { Debug }
            if debugMsg then
                addMessage('[GenerateEnchantedVersionsAuto] tempElement := ' + EditorID(tempelement));
            if Assigned(tempelement) then
            begin
                tempRecord := nil;
                if HasFileOverride(tempelement, GEVfile) then
                begin
                    tempRecord := GetFileOverride(tempelement, GEVfile);
                end
                else
                    tempRecord := wbCopyElementToFile(selectedRecord, GEVfile, false, true);
                if Assigned(tempRecord) and Assigned(enchLevelList) then
                begin
                    { Debug } if debugMsg then
                        addMessage('[GenerateEnchantedVersionsAuto] if Assigned(tempRecord) and Assigned(enchLevelList) then ReplaceInLeveledListAuto(' + EditorID(tempRecord) + ', ' + EditorID(enchLevelList) + ', ' + GetFileName(GEVfile) + ' );');
                    ReplaceInLeveledListAuto(tempRecord, enchLevelList, GEVfile);
                end;
            end;
        end;

        // Process Time Messages
        if ProcessTime then
        begin
            tempStopTime := Time;
            addProcessTime('[GEV] Process Enchanted Versions', TimeBtwn(tempStartTime, tempStopTime));
        end;
    end;
    if ProcessTime then
    begin
        processStopTime := Time;
        addProcessTime('Generate Enchantments for ' + IntToStr(slRecords.Count) + ' Records', TimeBtwn(processStartTime, processStopTime));
    end;

    // Replace original with enchanted versions
    if ReplaceInLeveledList then
        ReplaceInLeveledListByList(slRecords, slEnchanted, GEVfile);

    // Set Result
    { Debug } if debugMsg then
        msgList('[GenerateEnchantedVersionsAuto] slGlobal := ', slGlobal, '');

    // Finalize
    if ProcessTime then
    begin
        stopTime := Time;
        addProcessTime('GenerateEnchantedVersionsAuto', TimeBtwn(startTime, stopTime));
    end;
    if Assigned(slExistingRecords) then
        slExistingRecords.Free;
    if Assigned(slEnchanted) then
        slEnchanted.Free;
    if Assigned(slItemTiers) then
        slItemTiers.Free;
    if Assigned(slTempList) then
        slTempList.Free;
    if Assigned(slRecords) then
        slRecords.Free;
    if Assigned(slIndex) then
        slIndex.Free;
    if Assigned(slFiles) then
        slFiles.Free;
    if Assigned(slBOD2) then
        slBOD2.Free;
    if Assigned(slTemp) then
        slTemp.Free;
    if Assigned(slItem) then
        slItem.Free;
end;

// Indexes an Object effect
procedure IndexObjEffect(aRecord: IInterface; BOD2List, aList: TStringList);
var
    slTemp, slBOD2, slFlagOutput, slEnchantmentSuffix, slTempList: TStringList;
    tempString, suffix, sortingSuffix                            : string;
    objEffect, tempRecord                                        : IInterface;
    tempBoolean                                        : boolean;
    startTime, stopTime                                          : TDateTime;
    i, x, y                                                      : integer;
begin
    // Initialize
    
    startTime           := Time;
    slEnchantmentSuffix := TStringList.Create;
    slFlagOutput        := TStringList.Create;
    slTempList          := TStringList.Create;
    slBOD2              := TStringList.Create;
    slTemp              := TStringList.Create;
    { Debug } if debugMsg then
        msgList('[IndexObjEffect] input BOD2 := ', BOD2List, '');

    // Function
    slTempList.CommaText := '35, 36, 42';
    for i := 0 to Pred(ElementCount(GroupBySignature(aRecord, 'ENCH'))) do
    begin

        // Clear info from previous loops
        suffix := nil;
        slEnchantmentSuffix.clear;
        slBOD2.Assign(BOD2List);
        tempBoolean      := false;

        // Skip invalid records
        
        objEffect := WinningOverride(elementbyindex(GroupBySignature(aRecord, 'ENCH'), i));
        if debugMsg then
            addMessage('[IndexObjEffect] objEffect := ' + EditorID(objEffect));
        tempString       := EditorID(objEffect);
        slTemp := InvalidEffect;
        if SLWithinStr(tempString, slTemp) then
            Continue;
        slTemp.clear;

        // Check for recognizable EditorID
        // Check for vanilla suffix
        for x := 1 to 6 do
            if StrEndsWith(tempString, '0' + IntToStr(x)) then
                tempBoolean := true;
        // Check for Sorting Mod prefix
        if not tempBoolean then
            if (Copy(tempString, 1, 2) = 'aa') then
                tempBoolean := true;
        // Check for Eldritch Magic Enchantments Prefix
        if not tempBoolean then
            if ContainsText(tempString, 'EldEnch') then
                tempBoolean := true;
        tempString          := nil;
        if not tempBoolean then
            Continue;

        // Search objEffect references for matching BOD2 slot
        for x := 0 to Pred(ReferencedByCount(objEffect)) do
        begin
            tempRecord := ReferencedByIndex(objEffect, x);
            // Store reference name for suffix determination
            if ContainsText(Name(tempRecord), 'of ') then
                slEnchantmentSuffix.Add(StrPosCopy(Name(tempRecord), 'of ', false));
            if (slBOD2.Count <= 0) then
                Continue;
            // {Debug} if debugMsg then addMessage('[IndexObjEffect] tempRecord := '+EditorID(tempRecord));
            if (Signature(tempRecord) = 'ARMO') then
            begin
                // Get this record's BOD2
                slFlagOutput.clear;
                slGetFlagValues(tempRecord, slFlagOutput, false);
                if not(slFlagOutput.Count > 0) then
                    Continue;
                // Evaluate BOD2
                for y := 0 to slFlagOutput.Count - 1 do
                begin
                    // Add clothing type to BOD2
                    if not SLWithinStr(slFlagOutput[y], slTempList) then
                        slFlagOutput[y] := Trim(slFlagOutput[y]) + '-' + Trim(GetElementEditValues(tempRecord, GetElementType(tempRecord) + '\Armor Type'));
                    // Add to this ObjEffect's BOD2 if not already present
                    if not slContains(slTemp, slFlagOutput[y]) then
                        slTemp.Add(slFlagOutput[y]);
                end;
            end
            else
                if not slContains(slTemp, Signature(tempRecord)) then
                    slTemp.Add(Signature(tempRecord));
            // If detected BOD2 matches input BOD2 add to this record's list
            for y := 0 to slTemp.Count - 1 do
            begin
                if slContains(slBOD2, slTemp[y]) then
                begin
                    tempString := Trim(tempString + ' ' + slTemp[y]);
                    slBOD2.Delete(slBOD2.IndexOf(slTemp[y]));
                end;
            end;
        end;
        { Debug } if debugMsg then
            addMessage('[IndexObjEffect] ' + EditorID(objEffect) + ' slBOD2 := ' + tempString);

        // Create slIndex entry if objEffect has valid slots
        if (tempString <> '') then
        begin
            // Sorting Mod Stuff
            // Determine item suffix
            suffix := MostCommonString(slEnchantmentSuffix);
            // If there is no enchantment name then use the objEffect name
            if (suffix = '') then
                suffix := StrPosCopy(GetEditValue(objEffect), 'of', false);
            if (sortingSuffix <> '') then
                suffix := suffix + ' ' + DecToRoman(StrToInt(sortingSuffix));

            // Make slIndex Entry
            { Debug } if debugMsg then
                addMessage('[IndexObjEffect] aList.AddObject(' + Trim(tempString) + ', ' + EditorID(objEffect) + ' );');
            aList.addObject(suffix + '-//-' + tempString, objEffect);
        end;

    end;

    // Finalize
    { Debug } if debugMsg then
        msgList('[IndexObjEffect] aList := ', aList, '');
    stopTime := Time;
    if ProcessTime then
        addProcessTime('IndexObjEffect', TimeBtwn(startTime, stopTime));
    slEnchantmentSuffix.Free;
    slFlagOutput.Free;
    slTempList.Free;
    slBOD2.Free;
    slTemp.Free;
end;

// Gets an Enchantment Amount from the level
function GetEnchAmount(aLevel: integer): integer;
begin
    // Initialize
    
    { Debug } if debugMsg then
        addMessage('[GetEnchAmount] GetEnchAmount(' + IntToStr(aLevel) + ' );');

    // Process
    case aLevel of
        1 .. 9:
            result := 500;
        10 .. 19:
            result := 1000;
        20 .. 29:
            result := 1500;
        30 .. 34:
            result := 2000;
        35 .. 39:
            result := 2500;
        40 .. 100:
            result := 3000;
    else
        addMessage('[GetEnchAmount] ' + IntToStr(aLevel) + ' not recognized');
    end;
    { Debug } if debugMsg then
        addMessage('[GetEnchAmount] Result := ' + IntToStr(result));
end;

// Gets an object by IntToStr EditorID
function IndexOfObjectEDID(s: string; aList: TStringList): integer;
var
    i       : integer;
begin
    // Begin debugMsg section
    

    { Debug } if debugMsg then
        msgList('[IndexOfObjectEDID] IndexOfObjectEDID ''' + s + ''', (', aList, ');');
    result := -1;
    for i  := 0 to aList.Count - 1 do
    begin
        if (EditorID(ObjectToElement(aList.Objects[i])) = s) then
        begin
            result := i;
            { Debug } if debugMsg then
                addMessage('[IndexOfObjectEDID] Result := ' + IntToStr(result));
        end;
    end;

    
    // End debugMsg section
end;

// Gets an object by IntToStr EditorID
function IndexOfObjectbyFULL(s: string; aList: TStringList): integer;
var
    i       : integer;
begin
    // Begin debugMsg section
    

    { Debug } if debugMsg then
        addMessage('[IndexOfObjectbyFULL] IndexOfObjectbyFULL(' + s + ', aList );');
    for i := 0 to aList.Count - 1 do
    begin
        if ContainsText(FULL(ObjectToElement(aList.Objects[i])), s) then
        begin
            result := i;
            { Debug } if debugMsg then
                addMessage('[IndexOfObjectbyFULL] Result := ' + IntToStr(result));
        end;
    end;

    
    // End debugMsg section
end;

function IsHighestOverride(aRecord: IInterface; aInteger: integer): boolean;
begin
    // Begin debugMsg section
    

    result := false;
    result := IsWinningOVerride(aRecord);
    { Debug } if debugMsg then
        addMessage('[IsHighestOverride] IsHighestOverride(' + EditorID(aRecord) + ', ' + GetFileName(FileByLoadOrder(aInteger)) + ' )');
    { Debug } if debugMsg then
        addMessage('[IsHighestOverride] if GetLoadOrder(' + GetFileName(GetFile(aRecord)) + ' ) := ' + IntToStr(GetLoadOrder(GetFile(aRecord))) + ' = ' + IntToStr(GetLoadOrder(GetFile(HighestOverrideOrSelf(aRecord, aInteger)))) + ' := GetLoadOrder(' + GetFileName(GetFile(HighestOverrideOrSelf(aRecord, aInteger))) + ' ) then');
    if (GetLoadOrder(GetFile(aRecord)) = GetLoadOrder(GetFile(HighestOverrideOrSelf(aRecord, aInteger)))) then
        result := true;
    { Debug } if debugMsg then
        addMessage('[IsHighestOverride] Result := ' + BoolToStr(result));

    
    // End debugMsg section
end;

// Creates new COBJ record to make item temperable [SkyrimUtils]
function MakeTemperable(aRecord: IInterface; lightInteger, heavyInteger: integer; aPlugin: IInterface): IInterface;
var
    recipeTemper, recipeCondition, tempRecord: IInterface;
    tempBoolean                              : boolean;
    slTemp                                   : TStringList;
    record_sig                               : string;
    ki, e, i                                 : integer;
    keywords, keyword, ci                    : IInterface;
begin
    // Begin debugMsg section
    

    // Initialize
    slTemp := TStringList.Create;

    // CHECK FOR PRE-EXISTING

    // Common function output
    { Debug } if debugMsg then
        addMessage('[MakeTemperable] MakeTemperable(' + EditorID(aRecord) + ', ' + IntToStr(lightInteger) + ', ' + IntToStr(heavyInteger) + ', ' + GetFileName(aPlugin) + ' );');
    record_sig := Signature(aRecord);
    { Debug } if debugMsg then
        addMessage('[MakeTemperable] record_sig := ' + record_sig);

    // Filter invalid records
    tempBoolean := false;
    if Assigned(ElementByPath(aRecord, 'CNAM')) then
        tempBoolean := true;
    if not tempBoolean then
        if not((record_sig = 'WEAP') or (record_sig = 'ARMO') or (record_sig = 'AMMO')) then
            tempBoolean := true;
    slTemp.CommaText    := 'Circlet, Ring, Necklace';
    if not tempBoolean then
        if StrWithinSL(GetEditValue(aRecord), slTemp) or StrWithinSL(EditorID(aRecord), slTemp) then
            tempBoolean := true;
    if not tempBoolean then
        for i := 0 to Pred(ReferencedByCount(aRecord)) do
            if (Signature(ReferencedByIndex(aRecord, i)) = 'COBJ') and ContainsText(EditorID(ReferencedByIndex(aRecord, i)), 'Temper') then
                tempBoolean := true;
    if not tempBoolean then
        if IsClothing(aRecord) then
            tempBoolean := true;
    if IsClothing(aRecord) then
        tempBoolean := true;
    if tempBoolean then
    begin
        slTemp.Free;
        exit;
    end;

    // Add conditions
    { Debug } if debugMsg then
        addMessage('[MakeTemperable] Add conditions');
    recipeTemper := FindRecipe(false, HashedTemperList, aRecord, aPlugin);
    if Assigned(recipeTemper) then
    begin
        { Debug } if debugMsg then
            addMessage('Recipe Found for: ' + name(aRecord) + ' emptying');
        BeginUpdate(recipeTemper);
        try
            for e := ElementCount(ElementByPath(recipeTemper, 'Items')) - 1 downto 0 do
            begin
                RemoveByIndex(ElementByPath(recipeTemper, 'Items'), e, false);
            end;
            for e := ElementCount(ElementByPath(recipeTemper, 'Conditions')) - 1 downto 0 do
            begin
                RemoveByIndex(ElementByPath(recipeTemper, 'Conditions'), e, false);
            end;
        finally
            EndUpdate(recipeTemper);
        end;
    end;
    if not Assigned(recipeTemper) then
    begin
        { Debug } if debugMsg then
            addMessage('No Recipe Found for: ' + name(aRecord) + ' Generating new one');
        recipeTemper := createRecord(aPlugin, 'COBJ');
        // add reference to the created object
        SetElementEditValues(recipeTemper, 'CNAM', name(aRecord));
        // set Created Object Count
        SetElementEditValues(recipeTemper, 'NAM1', '1');
    end;
    Add(recipeTemper, 'Conditions', true);
    // RemoveInvalidEntries(recipeTemper);
    recipeCondition := ElementByPath(recipeTemper, 'Conditions');
    BeginUpdate(recipeCondition);
    try
        SetElementEditValues(ElementByPath(recipeCondition, 'Condition\CTDA'), 'Type', '00010000');
        SetElementEditValues(ElementByPath(recipeCondition, 'Condition\CTDA'), 'Comparison Value', '1');
        SetElementEditValues(ElementByPath(recipeCondition, 'Condition\CTDA'), 'Function', 'EPTemperingItemIsEnchanted');
        SetElementEditValues(ElementByPath(recipeCondition, 'Condition\CTDA'), 'Run On', 'Subject');
        SetElementEditValues(ElementByPath(recipeCondition, 'Condition\CTDA'), 'Parameter #3', '-1');
    finally
        EndUpdate(recipeCondition);
    end;
    addPerkCondition(ElementByPath(recipeTemper, 'Conditions'), getRecordByFormID('0005218E')); // ArcaneBlacksmith

    { Debug } if debugMsg then
        addMessage('[MakeTemperable] if record_sig := ' + record_sig + ' = WEAP then begin');
    if (record_sig = 'WEAP') then
    begin
        SetElementEditValues(recipeTemper, 'BNAM', GetEditValue(getRecordByFormID('00088108')));
        { Debug } if debugMsg then
            addMessage('[MakeTemperable] GetFileName(GetFile(aRecord)) := ' + GetFileName(GetFile(aRecord)));
        SetElementEditValues(recipeTemper, 'EDID', 'TemperWeapon_' + Trim(RemoveSpaces(RemoveFileSuffix(GetFileName(GetFile(aRecord))))) + '_' + Trim(EditorID(aRecord)));
    end;
    { Debug } if debugMsg then
        addMessage('[MakeTemperable] if record_sig := ' + record_sig + ' = ARMO then begin');
    if (record_sig = 'ARMO') then
    begin
        SetElementEditValues(recipeTemper, 'BNAM', GetEditValue(getRecordByFormID('000ADB78')));
        { Debug } if debugMsg then
            addMessage('[MakeTemperable] GetFileName(GetFile(aRecord)) := ' + GetFileName(GetFile(aRecord)));
        SetElementEditValues(recipeTemper, 'EDID', 'TemperArmor_' + Trim(RemoveSpaces(RemoveFileSuffix(GetFileName(GetFile(aRecord))))) + '_' + Trim(EditorID(aRecord)));
    end;
    // Add valid combinations
    slTemp.clear;
    // Weapon
    slTemp.addObject('WeapMaterialIron', getRecordByFormID('0005ACE4'));
    slTemp.addObject('WeapMaterialSteel', getRecordByFormID('0005ACE5'));
    slTemp.addObject('WeapMaterialElven', getRecordByFormID('0005ADA0'));
    slTemp.addObject('WeapMaterialDwarven', getRecordByFormID('000DB8A2'));
    slTemp.addObject('WeapMaterialEbony', getRecordByFormID('0005AD9D'));
    slTemp.addObject('WeapMaterialDaedric', getRecordByFormID('0005AD9D'));
    slTemp.addObject('WeapMaterialWood', getRecordByFormID('0006F993'));
    slTemp.addObject('WeapMaterialSilver', getRecordByFormID('0005ACE3'));
    slTemp.addObject('WeapMaterialOrcish', getRecordByFormID('0005AD99'));
    slTemp.addObject('WeapMaterialGlass', getRecordByFormID('0005ADA1'));
    slTemp.addObject('WeapMaterialFalmer', getRecordByFormID('0003AD57'));
    slTemp.addObject('WeapMaterialFalmerHoned', getRecordByFormID('0003AD57'));
    slTemp.addObject('DLC1WeapMaterialDragonbone', getRecordByFormID('0003ADA4'));
    slTemp.addObject('DLC2WeaponMaterialStalhrim', getRecordByFormID('0402B06B'));
    // Armor
    slTemp.addObject('ArmorMaterialIron', getRecordByFormID('0005ACE4'));
    slTemp.addObject('ArmorMaterialStudded', getRecordByFormID('0005ACE4'));
    slTemp.addObject('ArmorMaterialElven', getRecordByFormID('0005AD9F'));
    slTemp.addObject('DLC2ArmorMaterialChitinLight', getRecordByFormID('0402B04E'));
    slTemp.addObject('DLC2ArmorMaterialChitinHeavy', getRecordByFormID('0402B04E'));
    slTemp.addObject('DLC1ArmorMaterielFalmerHeavy', getRecordByFormID('0003AD57'));
    slTemp.addObject('DLC1ArmorMaterielFalmerHeavyOriginal', getRecordByFormID('0003AD57'));
    slTemp.addObject('DLC1ArmorMaterialFalmerHardened', getRecordByFormID('0402B06B'));
    slTemp.addObject('DLC2ArmorMaterialBonemoldLight', getRecordByFormID('0401CD7C'));
    slTemp.addObject('DLC2ArmorMaterialBonemoldHeavy', getRecordByFormID('0401CD7C'));
    slTemp.addObject('ArmorMaterialScaled', getRecordByFormID('0005AD93'));
    slTemp.addObject('ArmorMaterialIronBanded', getRecordByFormID('0005AD93'));
    slTemp.addObject('DLC2ArmorMaterialStalhrimLight', getRecordByFormID('0402B06B'));
    slTemp.addObject('DLC2ArmorMaterialStalhrimHeavy', getRecordByFormID('0402B06B'));
    slTemp.addObject('DLC2ArmorMaterialNordicLight', getRecordByFormID('0005ADA0'));
    slTemp.addObject('DLC2ArmorMaterialNordicHeavy', getRecordByFormID('0005ADA0'));
    slTemp.addObject('ArmorMaterialElvenGilded', getRecordByFormID('0005ADA0'));
    slTemp.addObject('ArmorMaterialHide', getRecordByFormID('000DB5D2'));
    slTemp.addObject('ArmorMaterialLeather', getRecordByFormID('000DB5D2'));
    slTemp.addObject('DLC2ArmorMaterialMoragTong', getRecordByFormID('000DB5D2'));
    slTemp.addObject('ArmorMaterialSilver', getRecordByFormID('0005ACE3'));
    slTemp.addObject('ArmorMaterialGlass', getRecordByFormID('0005ADA1'));
    slTemp.addObject('ArmorMaterialEbony', getRecordByFormID('0005AD9D'));
    slTemp.addObject('ArmorMaterialDaedric', getRecordByFormID('0005AD9D'));
    slTemp.addObject('ArmorMaterialDwarven', getRecordByFormID('000DB8A2'));
    slTemp.addObject('ArmorMaterialDragonscale', getRecordByFormID('0003ADA3'));
    slTemp.addObject('ArmorMaterialDragonplate', getRecordByFormID('0003ADA4'));
    slTemp.addObject('ArmorMaterialSteel', getRecordByFormID('0005ACE5'));
    slTemp.addObject('ArmorMaterialImperialHeavy', getRecordByFormID('0005ACE5'));
    slTemp.addObject('ArmorMaterialImperialLight', getRecordByFormID('0005ACE5'));
    slTemp.addObject('ArmorMaterialSteelPlate', getRecordByFormID('0005ACE5'));
    slTemp.addObject('ArmorMaterialStormcloak', getRecordByFormID('0005ACE5'));
    slTemp.addObject('ArmorMaterialImperialStudded', getRecordByFormID('0005ACE5'));
    slTemp.addObject('DLC1ArmorMaterialDawnguard', getRecordByFormID('0005ACE5'));
    // Detect value
    if slTemp.Count > 0 then
    begin
        Add(recipeTemper, 'items', true);
        for i := 0 to slTemp.Count - 1 do
        begin
            { Debug } if debugMsg then
                addMessage('[MakeTemperable] if HasKeyword(' + EditorID(aRecord) + ', ' + slTemp[i] + ' ) then begin');
            if HasKeyword(aRecord, slTemp[i]) then
            begin
                { Debug } if debugMsg then
                    addMessage('[MakeTemperable] addItem(' + EditorID(recipeTemper) + ', ' + EditorID(ObjectToElement(slTemp.Objects[i])) + ', 1);');
                addItem(recipeTemper, ObjectToElement(slTemp.Objects[i]), 1);
            end;
        end;
    end else begin
        addMessage('[ERROR] [MakeTemperable] Keyword list did not generate');
        // Remove(recipeTemper);
        exit;
    end;
    //RemoveInvalidEntries(recipeTemper);
    {
      // If a vanilla keyword is not detected
      if (GetElementEditValues(recipeTemper, 'COCT') = '') then begin
      tempRecord := GetTemplate(aRecord);
      for i := 0 to slTemp.Count-1 do begin
      if debugMsg then addMessage('[MakeTemperable] if HasKeyword('+EditorID(tempRecord)+', '+slTemp[i]+' ) then begin');
      if HasKeyword(tempRecord, slTemp[i]) then begin
      if debugMsg then addMessage('[MakeTemperable] addItem('+EditorID(recipeTemper)+', '+EditorID(ObjectToElement(slTemp.Objects[i]))+', 1);');
      if ElementExists(aRecord, 'BOD2') then begin
      if debugMsg then addMessage('[MakeTemperable] if (GetElementEditValues(aRecord, BOD2\Armor Type) := '+GetElementEditValues(aRecord, 'BOD2\Armor Type')+' = Heavy Armor ) then begin');
      if (GetElementEditValues(aRecord, 'BOD2\Armor Type') = 'Heavy Armor') then begin
      addItem(recipeTemper, ObjectToElement(slTemp.Objects[i]), heavyInteger);
      end else if (GetElementEditValues(aRecord, 'BOD2\Armor Type') = 'Light Armor') then
      addItem(recipeTemper, ObjectToElement(slTemp.Objects[i]), lightInteger);
      end else if ElementExists(aRecord, 'DNAM\Skill') or ElementExists(aRecord, 'DNAM\Animation Type') then begin
      if (GetElementEditValues(aRecord, 'DNAM\Skill') =  'Two Handed') or ContainsText(GetElementEditValues(aRecord, 'DNAM\Animation Type'), 'TwoHand') then begin
      addItem(recipeTemper, ObjectToElement(slTemp.Objects[i]), heavyInteger);
      end else
      addItem(recipeTemper, ObjectToElement(slTemp.Objects[i]), lightInteger);
      end else
      addItem(recipeTemper, ObjectToElement(slTemp.Objects[i]), lightInteger);
      end;
      end;	
      end;
    }
    // above is where an unknown is found something to get it a temper recipe

    if GetElementEditValues(recipeTemper, 'COCT') = '' then
    begin
        { debug } if debugMsg then
            addMessage('[MakeTemperable] there was no vanilla keyword useable for a temper recipe');
        keywords := ElementByPath(aRecord, 'KWDA');
        for ki   := 0 to ElementCount(keywords) - 1 do
        begin
            keyword := elementbyindex(keywords, ki);
            if MaterialList.IndexOf(EditorID(keyword)) > 0 then
            begin
                { debug } if debugMsg then
                    addMessage('found valid keyword in ini');

                CurrentMaterials := MaterialList.Objects[MaterialList.IndexOf(EditorID(keyword))];
                ci               := ObjectToElement(CurrentMaterials.Objects[0]);
                if not EditorID(ci) = 'LeatherStrips' then
                    YggAdditem(recipeitems, ci, 1)
                else
                    YggAdditem(recipeitems, ObjectToElement(CurrentMaterials.Objects[1]), 1);

            end;
        end;
    end;

    { Debug } if debugMsg then
        addMessage('[makeTemperable] Result := ' + EditorID(recipeTemper));
    result := recipeTemper;

    // Finalize
    slTemp.Free;

    
    // End debugMsg section
end;

function isBlacklist(aRecord: IInterface): boolean;
var
    slTemp    : TStringList;
    counter, i: integer;
    word      : string;
begin
    counter := 0;
    if not Assigned(DisKeyword) then
        IniBlacklist;
    for i := DisKeyword.Count - 1 downto 0 do
        if HasKeyword(aRecord, DisKeyword[i]) then
		begin
			//addmessage('diskeyword');
            counter := 1;
		end;
    if not Assigned(disWord) then
        IniBlacklist;
    word  := LowerCase(EditorID(aRecord));
    for i := disWord.Count - 1 downto 0 do
        if ContainsText(word, disWord[i]) then
        begin
			//addmessage('disword');
            counter := 1;
		end;

    word  := LowerCase(name(aRecord));
    for i := disWord.Count - 1 downto 0 do
        if ContainsText(word, disWord[i]) then
        begin
			//addmessage('disword');
            counter := 1;
		end;

    if disallowNP then
    begin
        if IntToStr(GetElementNativeValues(aRecord, 'Record Header\Record Flags\Non-Playable')) < 0 then
        begin
			//addmessage('NP');
            counter := 1;
		end;
        if IntToStr(GetElementNativeValues(aRecord, 'DATA\Flags\Non-Playable')) < 0 then
        begin
			//addmessage('NP');
            counter := 1;
		end;
    end;

    if ignoreEmpty then
        if not Assigned(ElementByPath(aRecord, 'FULL - Name')) then
		begin
			//addmessage('Noname');
            counter := 1;
		end;
    if not IsWinningOVerride(aRecord) then
        begin
			//addmessage('loser');
            counter := 1;
		end;
    if counter = 0 then
        result := true
    else
        result := false;
end;

// Add get item count condition
procedure AddItemCondition(aRecord, aItem: IInterface; aCount: string);
var
    conditions, condition: IInterface;
begin
    

    { Debug } if debugMsg then
        addMessage('[AddItemCondition] AddItemCondition(' + EditorID(aRecord) + ', ' + EditorID(aItem) + ', ' + aCount + ');');
    conditions := ElementByPath(aRecord, 'Conditions');
    { Debug } if debugMsg then
        addMessage('[AddItemCondition] if not Assigned(conditions) :=' + BoolToStr(Assigned(conditions)) + ' then begin');
    if not Assigned(conditions) then
    begin
        Add(aRecord, 'Conditions', true);
        conditions := ElementByPath(aRecord, 'Conditions');
        condition  := ElementByPath(elementbyindex(conditions, 0), 'CTDA');
    end
    else
        condition := ElementByPath(ElementAssign(conditions, HighInteger, nil, false), 'CTDA');
    BeginUpdate(condition);
    try
        SetElementEditValues(condition, 'Type', '11000000'); // Greater than or equal to
        SetElementEditValues(condition, 'Comparison Value', aCount + '.0');
        SetElementEditValues(condition, 'Function', 'GetItemCount');
        SetElementEditValues(condition, 'Inventory Object', ShortName(aItem));
    finally
        EndUpdate(condition);
    end;
end;

// Add get item count condition
procedure AddGetItemCountCondition(rec: IInterface; s: string; aBoolean: boolean);
var
    conditions, condition: IInterface;
begin
    conditions := ElementByPath(rec, 'Conditions');
    if not Assigned(conditions) then
    begin
        Add(rec, 'Conditions', true);
        conditions := ElementByPath(rec, 'Conditions');
        condition  := ElementByPath(elementbyindex(conditions, 0), 'CTDA');
    end
    else
        condition := ElementByPath(ElementAssign(conditions, HighInteger, nil, false), 'CTDA');
    BeginUpdate(condition);
    try
        SetElementEditValues(condition, 'Type', '11000000'); // Greater than or equal to
        SetElementEditValues(condition, 'Comparison Value', '1.0');
        SetElementEditValues(condition, 'Function', 'GetItemCount');
        SetElementEditValues(condition, 'Inventory Object', s);
    finally
        EndUpdate(condition);
    end;
    if aBoolean then
    begin
        condition := ElementByPath(ElementAssign(conditions, HighInteger, nil, false), 'CTDA');
        BeginUpdate(condition);
        try
            SetElementEditValues(condition, 'Type', '10010000'); // Equal to / OR
            SetElementEditValues(condition, 'Comparison Value', '0.0');
            SetElementEditValues(condition, 'Function', 'GetEquipped');
            SetElementEditValues(condition, 'Inventory Object', s);
        finally
            EndUpdate(condition);
        end;
        condition := ElementByPath(ElementAssign(conditions, HighInteger, nil, false), 'CTDA');
        BeginUpdate(condition);
        try
            SetElementEditValues(condition, 'Type', '11000000'); // Greater than or equal to
            SetElementEditValues(condition, 'Comparison Value', '2.0');
            SetElementEditValues(condition, 'Function', 'GetItemCount');
            SetElementEditValues(condition, 'Inventory Object', s);
        finally
            EndUpdate(condition);
        end;
    end;
end;

function MakeBreakdown(aRecord, aPlugin: IInterface): IInterface;
var
    cobj, Items, item, recipeRecord, tempRecord   : IInterface;
    i, tempInteger, Count, LeatherCount, x, hc, rc: integer;
    tempBoolean                         : boolean;
    slTemp, slItem                                : TStringList;
    edid                                          : string;
begin
    // Begin debugMsg section
    

    // Initialize
    { Debug } if debugMsg then
        msgList('[MakeBreakdown] slGlobal := ', slGlobal, '');
    { Debug } if debugMsg then
        addMessage('[MakeBreakdown] MakeBreakdown(' + EditorID(aRecord) + ', ' + GetFileName(aPlugin) + ' );');
    slTemp := TStringList.Create;
    slItem := TStringList.Create;

    // Load crafting recipe or skip records that already have a breakdown recipe
    for i := 0 to Pred(ReferencedByCount(aRecord)) do
    begin
        tempRecord := ReferencedByIndex(aRecord, i);
        if (Signature(tempRecord) = 'COBJ') then
        begin
            if ContainsText(EditorID(tempRecord), 'Recipe') then
            begin
                { Debug } if debugMsg then
                    addMessage('[MakeBreakdown] Crafting recipe: ' + EditorID(tempRecord));
                cobj := tempRecord;
            end
            else
                if ContainsText(EditorID(tempRecord), 'Breakdown') then
                begin
                    { Debug } if debugMsg then
                        addMessage('[MakeBreakdown] Breakdown already exists: ' + EditorID(tempRecord));
                    slTemp.Free;
                    slItem.Free;
                    exit;
                end;
        end;
    end;

    // Skip invalid records
    { Debug } if debugMsg then
        addMessage('[MakeBreakdown] Skip invalid records');
    tempBoolean := false;
    if not Assigned(cobj) then
        tempBoolean := true;
    if not boolean(GetObject('BreakdownEnchanted', slGlobal)) then
        if Assigned(ElementByPath(cobj, 'EITM')) then
            tempBoolean := true;
    if not boolean(GetObject('BreakdownDaedric', slGlobal)) then
        if HasItem(cobj, 'DaedraHeart') then
            tempBoolean := true;
    if not boolean(GetObject('BreakdownDLC', slGlobal)) then
    begin
        slTemp.CommaText := 'DragonBone, DragonScales, DLC2ChitinPlate, ChaurusChitin, BoneMeal';
        for i            := 0 to slTemp.Count - 1 do
            if HasItem(cobj, slTemp[i]) then
                tempBoolean := true;
    end;
    if tempBoolean then
    begin
        slTemp.Free;
        slItem.Free;
        exit;
    end;

    // Common Function Output
    { Debug } if debugMsg then
        addMessage('[MakeBreakdown] Common Function Output');
    Items        := ElementByPath(cobj, 'Items');
    LeatherCount := 0;

    // Process ingredients
    { Debug } if debugMsg then
        addMessage('[MakeBreakdown] Process ingredients');
    for i := 0 to Pred(ElementCount(Items)) do
    begin
        item  := LinksTo(ElementByPath(elementbyindex(Items, i), 'CNTO - Item\Item'));
        Count := GetElementEditValues(elementbyindex(Items, i), 'CNTO - Item\Count');
        edid  := EditorID(item);
        { Debug } if debugMsg then
            addMessage('[MakeBreakdown] edid := ' + edid);
        { Debug } if debugMsg then
            addMessage('[MakeBreakdown] count := ' + IntToStr(Count));
        // if (edid = 'LeatherStrips') then Continue; // Why shouldn't leather strips be copied?
        slTemp.CommaText := 'ingot, bone, scale, chitin, stalhrim';
        for x            := 0 to slTemp.Count - 1 do
            if ContainsText(edid, slTemp[x]) then
                slItem.addObject(name(item), Count);
        if (edid = 'Leather01') then
            LeatherCount := Count;
    end;
    { Debug } if debugMsg then
        msgList('[MakeBreakdown] slItem := ', slItem, '');
    { Debug } if debugMsg then
        addMessage('[MakeBreakdown] LeatherCount := ' + IntToStr(LeatherCount));

    // Create breakdown recipeRecord at smelter or tanning rack
    { Debug } if debugMsg then
        addMessage('[MakeBreakdown] Create breakdown recipeRecord at smelter or tanning rack');
    if (slItem.Count > 0) then
    begin
        // Create at smelter
        { Debug } if debugMsg then
            addMessage('[MakeBreakdown] Create at smelter');
        if (slItem.Count = 1) and (integer(slItem.Objects[0]) = 1) then
        begin
            // Skip making breakdown recipeRecord, can't produce less than 1 ingot
            { Debug } if debugMsg then
                addMessage('[MakeBreakdown] Skip making breakdown recipeRecord, can''t produce less than 1 ingot');
        end else begin
            recipeRecord := Add(GroupBySignature(aPlugin, 'COBJ'), 'COBJ', true); { Debug }
            if debugMsg then
                addMessage('[MakeBreakdown] Make breakdown recipeRecord');
            slTemp.CommaText := 'EDID, COCT, Items, CNAM, BNAM, NAM1'; { Debug }
            if debugMsg then
                addMessage('[MakeBreakdown] Add elements');
            BeginUpdate(recipeRecord);
            try
                for i := 0 to slTemp.Count - 1 do
                    Add(recipeRecord, slTemp[i], true);
                SetElementEditValues(recipeRecord, 'EDID', 'Breakdown' + StrCapFirst(Signature(aRecord)) + '_' + Trim(RemoveSpaces(RemoveFileSuffix(GetFileName(GetFile(aRecord))))) + '_' + Trim(EditorID(aRecord)));
                SetElementNativeValues(recipeRecord, 'BNAM', $000A5CCE); // CraftingSmelter
            finally
                EndUpdate(recipeRecord);
            end;
            AddGetItemCountCondition(recipeRecord, ShortName(aRecord), boolean(GetObject('BreakdownEquipped', slGlobal)));
            // Add items
            { Debug } if debugMsg then
                addMessage('[MakeBreakdown] Add items');
            Items := ElementByPath(recipeRecord, 'Items');
            item  := elementbyindex(Items, 0);
            SetElementEditValues(item, 'CNTO - Item\Item', ShortName(aRecord));
            SetElementEditValues(item, 'CNTO - Item\Count', 1);
            SetElementEditValues(recipeRecord, 'COCT', 1);
            // Set created object stuff
            hc    := 0;
            x     := -1;
            for i := 0 to slItem.Count - 1 do
            begin
                // Skip single items
                // if (Integer(slItem.Objects[i])-1 <= 0) then Continue;
                // Use first Item subelement or create new one
                if (integer(slItem.Objects[i]) >= hc) then
                begin
                    hc := integer();
                    x  := i;
                end;
            end;
            if (x > -1) then
            begin
                SetElementEditValues(recipeRecord, 'CNAM', slItem[x]);
                tempInteger := integer(slItem.Objects[x]) - 1;
                if (tempInteger = 0) then
                    tempInteger := 1;
                SetElementEditValues(recipeRecord, 'NAM1', tempInteger);
            end else begin
                { Debug } if debugMsg then
                    addMessage('[MakeBreakdown] Remove(recipeRecord)');
                Remove(recipeRecord);
            end;
            Inc(rc);
        end;
    end
    else
        if (LeatherCount > 0) then
        begin { Debug }
            if debugMsg then
                addMessage('[MakeBreakdown] Create at tanning rack');
            recipeRecord     := Add(GroupBySignature(aPlugin, 'COBJ'), 'COBJ', true);
            slTemp.CommaText := 'EDID, COCT, Items, CNAM, BNAM, NAM1';
            BeginUpdate(recipeRecord);
            try
                for i := 0 to slTemp.Count - 1 do
                    Add(recipeRecord, slTemp[i], true);
                SetElementEditValues(recipeRecord, 'EDID', 'Breakdown' + StrCapFirst(Signature(aRecord)) + '_' + Trim(RemoveSpaces(RemoveFileSuffix(GetFileName(GetFile(aRecord))))) + '_' + Trim(EditorID(aRecord)));
                SetElementNativeValues(recipeRecord, 'BNAM', $0007866A); // CraftingTanningRack
                AddGetItemCountCondition(recipeRecord, ShortName(aRecord), boolean(GetObject('BreakdownEquipped', slGlobal)));
                // Add items to recipeRecord
                Items := ElementByPath(recipeRecord, 'Items');
                item  := elementbyindex(Items, 0);
                SetElementEditValues(item, 'CNTO - Item\Item', ShortName(aRecord));
                SetElementEditValues(item, 'CNTO - Item\Count', 1);
                SetElementEditValues(recipeRecord, 'COCT', 1);
                // Set created object stuff
                SetElementNativeValues(recipeRecord, 'CNAM', $000800E4); // LeatherStrips
                SetElementEditValues(recipeRecord, 'NAM1', 2);
            finally
                EndUpdate(recipeRecord);
            end;
            Inc(rc);
        end;

    // Finalize
    slTemp.Free;
    slItem.Free;

    
    // End debugMsg section
end;

// Shifts all TForm components up or down
procedure TShift(aInteger, bInteger: integer; aForm: TForm; aBoolean: boolean);
var
    i       : integer;
begin
    for i := 0 to aForm.ComponentCount - 1 do
    begin
        if (aForm.Components[i].Top >= aInteger) then
        begin
            if aBoolean then
            begin
                aForm.Components[i].Top := aForm.Components[i].Top - bInteger;
            end else begin
                aForm.Components[i].Top := aForm.Components[i].Top + bInteger;
            end;
        end;
    end;
end;

// Checks if an input record has an item matching the input EditorID.
function HasItem(aRecord: IInterface; s: string): boolean;
var
    name     : string;
    Items, li: IInterface;
    i        : integer;
begin
    result := false;
    Items  := ElementByPath(aRecord, 'Items');
    if not Assigned(Items) then
        exit;

    for i := 0 to Pred(ElementCount(Items)) do
    begin
        li   := elementbyindex(Items, i);
        name := EditorID(LinksTo(ElementByPath(li, 'CNTO - Item\Item')));
        if (name = s) then
        begin
            result := true;
            break;
        end;
    end;
end;

// Clears empty TStringList entries
procedure slClearEmptyStrings(aList: TStringList);
var
    slTemp: TStringList;
    i     : integer;
begin
    // Initialize
    slTemp := TStringList.Create;

    // Process
    for i := 0 to aList.Count - 1 do
        if (aList[i] = '') then
            slTemp.Add(aList[i]);
    for i := 0 to slTemp.Count - 1 do
        if (aList.IndexOf(slTemp[i]) >= 0) then
            aList.Delete(aList.IndexOf(slTemp[i]));

    // Finalize
    slTemp.Free;
end;

// Removes an entry that contains substr
procedure slDeleteString(s: string; aList: TStringList);
var
    i, tempInteger: integer;
    slTemp        : TStringList;
begin
    // Initialize
    slTemp := TStringList.Create;

    // Process
    if StrWithinSL(s, aList) then
    begin
        for i := 0 to aList.Count - 1 do
            if ContainsText(aList[i], s) then
                slTemp.Add(aList[i]);
        for i := 0 to slTemp.Count - 1 do
            if (aList.IndexOf(slTemp[i]) >= 0) then
                aList.Delete(aList.IndexOf(slTemp[i]));
    end;

    // Finalize
    slTemp.Free;
end;

// Gets an object associated with a string
function GetObject(s: string; aList: TStringList): TObject;
var
    tempString: string;
    i         : integer;
begin
    // Begin debugMsg section
    

    { Debug } if debugMsg then
        addMessage('[GetObject] GetObject(' + s + ', aList );');
    { Debug } if debugMsg then
        msgList('[GetObject] aList := ', aList, '');
    if slContains(slGlobal, s) then
        result := aList.Objects[aList.IndexOf(s)];

    
    // End debugMsg section
end;

// Gets an object associated with a string
function StringObject(s: string; aList: TStringList): string;
var
    tempString: string;
    i         : integer;
begin
    // Begin debugMsg section
    

    { Debug } if debugMsg then
        addMessage('[GetObject] GetObject(' + s + ', aList );');
    { Debug } if debugMsg then
        msgList('[GetObject] aList := ', aList, '');
    for i := 0 to aList.Count - 1 do
    begin
        if ContainsText(aList[i], s) then
        begin
            result := StrPosCopy(aList[i], '=', false);
            { Debug } if debugMsg then
                addMessage('[GetObject] Result := ' + result);
            exit;
        end;
    end;

    
    // End debugMsg section
end;

// Removes an entry that contains substr
procedure SetObject(s: string; aObject: Variant; aList: TStringList);
var
    i, tempInteger: integer;
begin
    // Begin debugMsg Section
    

    { Debug } if debugMsg then
        addMessage('[SetObject] SetObject(' + s + ', aObject, aList );');
    { Debug } if debugMsg then
        addMessage('[SetObject] aObject := ' + varTypeAsText(aObject));
    { Debug } if debugMsg then
        msgList('[SetObject] aList := ', aList, '');
    tempInteger := aList.IndexOf(s);
    if (tempInteger < 0) then
    begin
        for i := 0 to aList.Count - 1 do
        begin
            if (aList[i] = s) then
            begin
                tempInteger := i;
                break;
            end;
        end;
    end;
    if (tempInteger > -1) then
    begin
        aList.Objects[tempInteger] := aObject;
    end else begin
        aList.addObject(s, aObject);
    end;

    
    // End debugMsg section
end;

// Gets the component associated with a caption
function AssociatedComponent(s: string; frm: TForm): TObject;
begin
    result := ComponentByTop(ComponentByCaption(s, frm).Top - 2, frm)
end;

function PreviousOverrideExists(aRecord: IInterface; LoadOrder: integer): boolean;
var
     tempBoolean: boolean;
    tempRecord           : IInterface;
    i                    : integer;
begin
    // Begin debugMsg section
    

    result := false;
    if (OverrideCount(aRecord) > 0) then
    begin
        tempBoolean := false;
        for y       := Pred(OverrideCount(aRecord)) downto 0 do
        begin
            tempRecord := OverrideByIndex(aRecord, y);
            if (LoadOrder >= GetLoadOrder(GetFile(tempRecord))) then
            begin
                { Debug } if debugMsg then
                    addMessage('[PreviousOverrideExists] ' + EditorID(tempRecord) + ' := ' + IntToStr(LoadOrder) + ' >= ' + IntToStr(GetLoadOrder(GetFile(tempRecord))));
                result := true;
                exit;
            end;
        end;
    end;

    
    // End debugMsg section
end;

function GetPreviousOverride(aRecord: IInterface; LoadOrder: integer): IInterface;
var
    tempBoolean: boolean;
    tempRecord           : IInterface;
    i, y                 : integer;
begin
    // Begin debugMsg section
    

    result := nil;
    if (OverrideCount(aRecord) > 0) then
    begin
        tempBoolean := false;
        for y       := Pred(OverrideCount(aRecord)) downto 0 do
        begin
            tempRecord := OverrideByIndex(aRecord, y);
            if (LoadOrder >= GetLoadOrder(GetFile(tempRecord))) then
            begin
                { Debug } if debugMsg then
                    addMessage('[PreviousOverrideExists] ' + EditorID(tempRecord) + ' := ' + IntToStr(LoadOrder) + ' >= ' + IntToStr(GetLoadOrder(GetFile(tempRecord))));
                result := tempRecord;
                exit;
            end;
        end;
    end;

    
    // End debugMsg section
end;

function HasFileOverride(aRecord, aFile: IInterface): boolean;
var
    tempRecord: IInterface;
    i, y      : integer;
begin
    // Begin debugMsg section
    

    result := false;
    if (OverrideCount(aRecord) > 0) then
    begin
        for y := Pred(OverrideCount(aRecord)) downto 0 do
        begin
            tempRecord := OverrideByIndex(aRecord, y);
            if (GetLoadOrder(aFile) = GetLoadOrder(GetFile(tempRecord))) then
            begin
                { Debug } if debugMsg then
                    addMessage('[PreviousOverrideExists] ' + EditorID(tempRecord) + ' := ' + IntToStr(GetLoadOrder(aFile)) + ' >= ' + IntToStr(GetLoadOrder(GetFile(tempRecord))));
                result := true;
                exit;
            end;
        end;
    end;

    
    // End debugMsg section
end;

function GetFileOverride(aRecord, aFile: IInterface): IInterface;
var
    tempBoolean: boolean;
    tempRecord           : IInterface;
    i, y                 : integer;
begin
    // Begin debugMsg section
    

    result := nil;
    if (OverrideCount(aRecord) > 0) then
    begin
        tempBoolean := false;
        for y       := Pred(OverrideCount(aRecord)) downto 0 do
        begin
            tempRecord := OverrideByIndex(aRecord, y);
            if (GetLoadOrder(aFile) = GetLoadOrder(GetFile(tempRecord))) then
            begin
                { Debug } if debugMsg then
                    addMessage('[PreviousOverrideExists] ' + EditorID(tempRecord) + ' := ' + IntToStr(GetLoadOrder(aFile)) + ' >= ' + IntToStr(GetLoadOrder(GetFile(tempRecord))));
                result := tempRecord;
                exit;
            end;
        end;
    end;

    
    // End debugMsg section
end;

function GetEnchLevel(objEffect: IInterface; slItemTiers: TStringList): integer;
var
    tempBoolean: boolean;
    tempString           : string;
    i                    : integer;
begin
    // Initialize
    
    { Debug } if debugMsg then
        msgList('[GetEnchLevel] GetEnchLevel(' + EditorID(objEffect) + ', ', slItemTiers, ' );');
    { Debug } if debugMsg then
        for i := 0 to slItemTiers.Count - 1 do
            addMessage('[GetEnchLevel] slItemTiers[' + IntToStr(i + 1) + '] := ' + IntToStr(integer(slItemTiers.Objects[i])) + ';');
    result := -1;

    // Process
    tempString := Copy(EditorID(objEffect), Length(EditorID(objEffect)) - 1, 2);
    { Debug } if debugMsg then
        addMessage('[GetEnchLevel] tempString := ' + tempString);
    if slContains(slItemTiers, tempString) then
    begin
        result := integer(slItemTiers.Objects[slItemTiers.IndexOf(tempString)]);
        // This is specifically for 'More Interesting Loot' enchantments
    end
    else
        if (Copy(EditorID(objEffect), 1, 2) = 'aa') then
        begin
            tempString := EditorID(objEffect);
            if (Length(IntToStr(IntWithinStr(tempString))) = 1) then
            begin
                for i := 1 to 6 do
                begin
                    if slContains(slItemTiers, '0' + IntToStr(i)) then
                    begin
                        result := slItemTiers.Objects[slItemTiers.IndexOf('0' + IntToStr(i))]
                    end
                    else
                        result := slItemTiers.Objects[slItemTiers.Count - 1];
                end;
            end
            else
                if (IntWithinStr(tempString) = 10) then
                begin
                    result := slItemTiers.Objects[0];
                end
                else
                    if (IntWithinStr(tempString) > 50) and (IntWithinStr(tempString) < 100) then
                    begin
                        result := slItemTiers.Objects[slItemTiers.Count - 1];
                    end
                    else
                        if (IntWithinStr(tempString) > 100) and (IntWithinStr(tempString) <= 200) then
                        begin
                            if ContainsText(tempString, 'Greater') then
                            begin
                                result := slItemTiers.Objects[slItemTiers.Count - 1];
                            end
                            else
                                result := slItemTiers.Objects[(slItemTiers.Count div 2)];
                        end else begin
                            result := IntWithinStr(tempString);
                        end;
        end;
    { Debug } if debugMsg then
        addMessage('[GetEnchLevel] Result := ' + IntToStr(result) + ';');
    if (result = 0) then
        result := 1;
end;

// A copy function that allows you to copy from one position to another [mte functions]
function StrPosCopyBtwn(inputString, aString, bString: string): string;
var
    i, p1, p2: integer;
begin
    // Begin debugMsg section
    

    result := '';
    result := StrPosCopy(StrPosCopy(inputString, aString, false), bString, true);
    { Debug } if debugMsg then
        addMessage('[StrPosCopyBtwn] Result := ' + result);

    
    // End debugMsg section
end;

procedure GenderOnlyArmor(aString: string; aRecord, aPlugin: IInterface);
var
    tempRecord, tempelement, copyRecord, armorAddonRecord, armorAddonCopy, templateRecord, templateAddonRecord, Races: IInterface;
    slTemp                                                                                                           : TStringList;
    LoadOrder                                                                                              : boolean;
    i                                                                                                                : integer;
begin
    // Initialize
    
    LoadOrder := false;
    aRecord   := WinningOverride(aRecord);
    slTemp    := TStringList.Create;
    { Debug } if debugMsg then
        addMessage('[GenderOnlyArmor] GenderOnlyArmor(' + aString + ', ' + EditorID(aRecord) + ', ' + GetFileName(aPlugin) + ' );');
    if not((aString = 'Male') or (aString = 'Female')) then
    begin
        addMessage('[GenderOnlyArmor] ' + aString + ' not ''Male'' or ''Female''');
        exit;
    end;
    if (GetPrimarySlot(aRecord) = '00') then
        exit;
    templateRecord := ObjectToElement(GetObject(EditorID(aRecord) + 'Template', slGlobal));
    copyRecord     := aRecord; { Debug }
    if debugMsg then
        addMessage('[GenderOnlyArmor] copyRecord := ' + EditorID(aRecord));
    armorAddonRecord := LinksTo(ElementByPath(aRecord, 'Armature\MODL')); { Debug }
    if debugMsg then
        addMessage('[GenderOnlyArmor] armorAddonRecord := ' + EditorID(armorAddonRecord));
    if (GetLoadOrder(GetFile(aRecord)) = GetLoadOrder(aPlugin)) then
        LoadOrder := true; // Specifies if an Override is generated

    // Process
    { Debug } if debugMsg then
        addMessage('[GenderOnlyArmor] if ContainsText(aString, Female) then begin := ' + BoolToStr(ContainsText(aString, 'Female')));
    if (aString = 'Male') then
    begin
        { Debug } if debugMsg then
            addMessage('[GenderOnlyArmor] Male-Only Armor Detected');
        // Worn Armor (Armor Addon)
        if not(Length(GetElementEditValues(armorAddonRecord, 'Female world model\MOD3')) > 0) then
        begin
            if not LoadOrder then
                armorAddonRecord := wbCopyElementToFile(LinksTo(ElementByPath(aRecord, 'Armature\MODL')), aPlugin, false, true);
            Add(armorAddonRecord, 'Female world model', true);
            Add(armorAddonRecord, 'Female world model\MOD3', true);
            SetElementEditValues(armorAddonRecord, 'Female world model\MOD3', GetElementEditValues(WinningOverride(templateRecord), 'Female world model\MOD3'));
            if not(Length(GetElementEditValues(armorAddonRecord, 'Female world model\MOD3')) > 0) then
                SetElementEditValues(armorAddonRecord, 'Female world model\MOD3', GetElementEditValues(WinningOverride(templateRecord), 'Male world model\MOD2'));
        end;
        // Remove ElderRace
        for i := 0 to Pred(ElementCount(ElementByPath(armorAddonRecord, 'Additional Races'))) do
        begin
            if ContainsText(GetEditValue(elementbyindex(ElementByPath(armorAddonRecord, 'Additional Races'), i)), 'ElderRace') then
            begin
                armorAddonCopy := MainRecordByEditorID(GroupBySignature(aPlugin, 'ARMO'), EditorID(armorAddonRecord));
                if not Assigned(armorAddonCopy) then
                    armorAddonCopy := wbCopyElementToFile(armorAddonRecord, aPlugin, false, true);
                { Debug } if debugMsg then
                    addMessage('[GenderOnlyArmor] GetEditValue(elementbyindex(ElementByPath(armorAddonCopy, ' Additional Races '), i)) := ' + GetEditValue(elementbyindex(ElementByPath(armorAddonCopy, 'Additional Races'), i)));
                slTemp.Add(GetEditValue(elementbyindex(ElementByPath(armorAddonCopy, 'Additional Races'), i)));
                Remove(elementbyindex(ElementByPath(armorAddonCopy, 'Additional Races'), i));
            end;
        end;
        // Ground Armor
        if not(Length(GetElementEditValues(aRecord, 'Female world model\MOD4')) > 0) then
        begin
            if not LoadOrder then
                copyRecord := wbCopyElementToFile(aRecord, aPlugin, false, true);
            Add(copyRecord, 'Female world model', true);
            Add(copyRecord, 'Female world model\MOD4', true);
            SetElementEditValues(copyRecord, 'Female world model\MOD4', GetElementEditValues(WinningOverride(templateRecord), 'Female world model\MOD4'));
            if not(Length(GetElementEditValues(copyRecord, 'Female world model\MOD4')) > 0) then
                SetElementEditValues(copyRecord, 'Female world model\MOD4', GetElementEditValues(WinningOverride(templateRecord), 'Male world model\MOD2'));
        end;
    end
    else
        if ContainsText(aString, 'Female') then
        begin
            { Debug } if debugMsg then
                addMessage('[GenderOnlyArmor] Female-Only Armor Detected');
            // Worn Armor (Armor Addon)
            if not(Length(GetElementEditValues(armorAddonRecord, 'Male world model\MOD2')) > 0) then
            begin { Debug }
                if debugMsg then
                    addMessage('[GenderOnlyArmor] Worn Armor Begin');
                if not LoadOrder then
                    armorAddonRecord := wbCopyElementToFile(LinksTo(ElementByPath(aRecord, 'Armature\MODL')), aPlugin, false, true);
                Add(armorAddonRecord, 'Male world model', true);
                Add(armorAddonRecord, 'Male world model\MOD2', true);
                SetElementEditValues(armorAddonRecord, 'Male world model\MOD2', GetElementEditValues(LinksTo(ElementByPath(WinningOverride(templateRecord), 'Armature\MODL')), 'Male world model\MOD2'));
            end;
            // Remove ElderRace
            for i := 0 to Pred(ElementCount(ElementByPath(armorAddonRecord, 'Additional Races'))) do
            begin
                if ContainsText(GetEditValue(elementbyindex(ElementByPath(armorAddonRecord, 'Additional Races'), i)), 'ElderRace') then
                begin
                    armorAddonCopy := MainRecordByEditorID(GroupBySignature(aPlugin, 'ARMO'), EditorID(armorAddonRecord));
                    if not Assigned(armorAddonCopy) then
                        armorAddonCopy := wbCopyElementToFile(armorAddonRecord, aPlugin, false, true);
                    { Debug } if debugMsg then
                        addMessage('[GenderOnlyArmor] GetEditValue(elementbyindex(ElementByPath(armorAddonCopy, ''Additional Races''), i)) := ' + GetEditValue(elementbyindex(ElementByPath(armorAddonCopy, 'Additional Races'), i)));
                    slTemp.Add(GetEditValue(elementbyindex(ElementByPath(armorAddonCopy, 'Additional Races'), i)));
                    Remove(elementbyindex(ElementByPath(armorAddonCopy, 'Additional Races'), i));
                end;
            end;
            // Ground Armor
            { Debug } if debugMsg then
                addMessage('[GenderOnlyArmor] GetElementEditValues(aRecord, Male world model\MOD2) := ' + GetElementEditValues(aRecord, 'Male world model\MOD2'));
            if not(Length(GetElementEditValues(aRecord, 'Male world model\MOD2')) > 0) then
            begin
                if not LoadOrder then
                    copyRecord := wbCopyElementToFile(aRecord, aPlugin, false, true);
                Add(copyRecord, 'Male world model', true);
                Add(copyRecord, 'Male world model\MOD2', true);
                SetElementEditValues(copyRecord, 'Male world model\MOD2', GetElementEditValues(WinningOverride(templateRecord), 'Male world model\MOD2'));
            end;
        end
        else
            addMessage('[GenderOnlyArmor] aString := ' + aString + ' does not contain ''Male'' or ''Female''');

    // Create a new Armor Addon for ElderRace
    if (slTemp.Count > 0) then
    begin
        { Debug } if debugMsg then
            addMessage('[GenderOnlyArmor] Create a new Armor Addon for ElderRace');
        { Debug } if debugMsg then
            msgList('[GenderOnlyArmor] slTemp := ', slTemp, '');
        templateAddonRecord := wbCopyElementToFile(LinksTo(ElementByPath(templateRecord, 'Armature\MODL')), aPlugin, true, true);
        SetElementEditValues(templateAddonRecord, 'EDID', EditorID(armorAddonRecord) + '_OldPeople');
        { Debug } if debugMsg then
            addMessage('[GenderOnlyArmor] templateAddonRecord := ' + EditorID(templateAddonRecord));
        RefreshList(templateAddonRecord, 'Additional Races');
        for i := 0 to slTemp.Count - 1 do
        begin
            tempelement := ElementAssign(ElementByPath(templateAddonRecord, 'Additional Races'), HighInteger, nil, false);
            SetEditValue(tempelement, slTemp[i]);
        end;
        //RemoveInvalidEntries(templateAddonRecord);
        if not(GetLoadOrder(GetFile(copyRecord)) = GetLoadOrder(aPlugin)) then
            copyRecord := wbCopyElementToFile(aRecord, aPlugin, false, true);
        tempelement    := ElementAssign(ElementByPath(copyRecord, 'Armature'), HighInteger, nil, false);
        SetEditValue(tempelement, name(templateAddonRecord));
    end;

    // Finalize
    slTemp.Free;
end;

function IsFemaleOnly(aRecord: IInterface): boolean;
begin
    result := false;
    if not(Length(GetElementEditValues(aRecord, 'Male world model\MOD2')) > 0) then
        result := true;
    if not(Length(GetElementEditValues(LinksTo(ElementByPath(aRecord, 'Armature\MODL')), 'Male world model\MOD2')) > 0) then
        result := true;
end;

function HasGenderKeyword(aRecord: IInterface): boolean;
begin
    if (textInKeyword(aRecord, 'male', false)) or (textInKeyword(aRecord, 'female', false)) then
        result := true
    else
        result := false;
end;

function GetGenderFromKeyword(aRecord: IInterface): string;
begin
    result := '';
    if textInKeyword(aRecord, 'female', false) then
        result := 'Female'
    else
        if textInKeyword(aRecord, 'male', false) then
            result := 'Male';
end;

function IsClothing(aRecord: IInterface): boolean;
var
    tempString: string;
begin
    result := false;
    if not(Signature(aRecord) = 'ARMO') then
        exit;
    if ElementExists(aRecord, 'BODT') then
    begin
        tempString := 'BODT';
    end
    else
        tempString := 'BOD2';
    if (GetElementEditValues(aRecord, tempString + '\Armor Type') = 'Clothing') then
    begin
        result := true;
        exit;
    end;
    if ContainsText(EditorID(aRecord), 'Clothing') then
    begin
        result := true;
        exit;
    end;
    if textInKeyword(aRecord, 'clothing', false) then
        result := true;
    if ElementExists(aRecord, 'DNAM') then
    begin
        if (GetElementNativeValues(aRecord, 'DNAM') = 0) then
        begin
            result := true;
            exit;
        end;
    end
    else
        result := true;
end;

function textInKeyword(aRecord: IInterface; Text: string; checkCaps: boolean): boolean;
var
    keywords  : IInterface;
    tempString: string;
    i         : integer;
begin
    result := false;
    if not checkCaps then
        Text := LowerCase(Text);
    keywords := ElementByPath(aRecord, 'KWDA');
    for i    := 0 to ElementCount(keywords) - 1 do
    begin
        tempString := EditorID(LinksTo(elementbyindex(keywords, i)));
        if not checkCaps then
            tempString := LowerCase(tempString);
        if ContainsText(tempString, Text) then
        begin
            result := true;
            exit;
        end;
    end;
end;

function MostCommonString(aList: TStringList): string;
var
    i, x, tempInteger, Count: integer;
    slTemp                  : TStringList;
begin
    // Begin debugMsg Section
    

    // Initialize
    if debugMsg then
        msgList('[MostCommonString] MostCommonString(', aList, ');');
    slTemp := TStringList.Create;

    // Process
    tempInteger := 0;
    for i       := 0 to aList.Count - 1 do
    begin
        if slContains(slTemp, aList[i]) then
            Continue;
        Count := 0;
        for x := 0 to aList.Count - 1 do
            if (aList[x] = aList[i]) and (x <> i) then
                Inc(Count);
        if (Count > tempInteger) and (Count > 1) then
        begin
            result      := aList[i];
            tempInteger := Count;
        end;
        slTemp.Add(aList[i]);
    end;

    // Finalize
    if debugMsg then
        addMessage('[MostCommonString] Result := ' + result);
    slTemp.Free;

    
    // End debugMsg Section
end;

function GetElementType(aRecord: IInterface): string;
begin
    

    { Debug } if debugMsg then
        addMessage('[GetElementType] GetElementType(' + EditorID(aRecord) + ' );');
    { Debug } if debugMsg then
        addMessage('[GetElementType] Signature(' + EditorID(aRecord) + ' := ' + Signature(aRecord));
    if (Signature(aRecord) = 'ARMO') then
    begin
        if ElementExists(aRecord, 'BODT') then
        begin
            result := 'BODT';
        end
        else
            result := 'BOD2';
    end
    else
        if (Signature(aRecord) = 'LVLI') then
            result := 'LVLF';
end;

function TimeBtwn(Start, Stop: TDateTime): integer;
begin
    result := ((3600 * GetHours(Stop)) + (60 * GetMinutes(Stop)) + GetSeconds(Stop)) - ((3600 * GetHours(Start)) + (60 * GetMinutes(Start)) + GetSeconds(Start));
end;

function GetSeconds(aTime: TDateTime): integer;
var
    tempString: string;
begin
    tempString := TimeToStr(aTime);
    result     := StrToInt(Trim(IntWithinStr(StrPosCopy(StrPosCopy(tempString, ':', false), ':', false))));
end;

function GetMinutes(aTime: TDateTime): integer;
begin
    result := StrToInt(Trim(StrPosCopy(StrPosCopy(TimeToStr(aTime), ':', false), ':', true)));
end;

function GetHours(aTime: TDateTime): integer;
begin
    result := StrToInt(Trim(StrPosCopy(TimeToStr(aTime), ':', true)));
end;

function IntegerToTime(TotalTime: integer): string;
var
    TimeInteger, Hours, Minutes, Seconds     : integer;
    stringHours, stringMinutes, stringSeconds: string;
    tempString                               : string;
begin
    TimeInteger := TotalTime;
    // Hours
    while (TimeInteger > 3600) do
    begin
        TimeInteger := TimeInteger - 3600;
        Hours       := Hours + 1;
    end;
    if (Hours <= 0) then
    begin
        stringHours := '00';
    end
    else
        if (Hours < 10) then
            stringHours := '0' + IntToStr(Hours)
        else
            stringHours := IntToStr(Hours);
    // Minutes
    while (TimeInteger > 60) do
    begin
        TimeInteger := TimeInteger - 60;
        Minutes     := Minutes + 1;
    end;
    if (Minutes <= 0) then
    begin
        stringMinutes := '00';
    end
    else
        if (Minutes < 10) then
            stringMinutes := '0' + IntToStr(Minutes)
        else
            stringMinutes := IntToStr(Minutes);
    // Seconds
    if (TimeInteger <= 0) then
    begin
        stringSeconds := '00';
    end
    else
        if (TimeInteger < 10) then
            stringSeconds := '0' + IntToStr(TimeInteger)
        else
            stringSeconds := IntToStr(TimeInteger);
    result                := stringHours + ':' + stringMinutes + ':' + stringSeconds;
end;

procedure addProcessTime(aFunctionName: string; aTime: integer);
begin
    SetObject(aFunctionName, integer(GetObject(aFunctionName, slProcessTime)) + aTime, slProcessTime);
end;

function StrToOrd(aString: string): Int64;
var
    i, aLength: integer;
begin
    aLength := Length(aString);
    if (aLength > 9) then
        aString := Copy(aString, 1, 9);
    for i       := 0 to aLength do
        result  := result * 100 + ord(Copy(aString, i, 1));
end;

function GetPrimarySlot(aRecord: IInterface): string;
var
    slTemp, slBOD2: TStringList;
    i             : integer;
begin
    // Initialize
    
    { Debug } if debugMsg then
        addMessage('[GetPrimarySlot] GetPrimarySlot(' + EditorID(aRecord) + ' );');
    result := '00';
    slBOD2 := TStringList.Create;
    slTemp := TStringList.Create;

    // Process
    slGetFlagValues(aRecord, slBOD2, false);
    { Debug } if debugMsg then
        msgList('[GetPrimarySlot] slGetFlagValues := ', slBOD2, '');
    slTemp.CommaText := '30, 32, 33, 35, 36, 37, 39, 42';
    for i            := 0 to slTemp.Count - 1 do
    begin
        if slContains(slBOD2, slTemp[i]) then
        begin
            result := slTemp[i];
            break;
        end;
    end;
    { Debug } if debugMsg then
        addMessage('[GetPrimarySlot] Result := ' + result);

    // Finalize
    slBOD2.Free;
    slTemp.Free;
end;

procedure RemoveSubStr(aList: TStringList; aString: string);
var
    Count   : integer;
begin
    
    { Debug } if debugMsg then
        msgList('[RemoveSubStr] RemoveSubStr(', aList, ', ' + aString + ' );');
    Count := 0;
    while (aList.Count > Count) do
    begin
        while ContainsText(aList[Count], aString) do
        begin
            aList[Count] := Trim(Trim(StrPosCopy(aList[Count], aString, true)) + ' ' + Trim(StrPosCopy(aList[Count], aString, false)));
            { Debug } if debugMsg then
                addMessage('[RemoveSubStr] aList[Count] := ' + aList[Count]);
        end;
        Inc(Count);
    end;
end;

procedure AddPrimarySlots(aList: TStringList);
var
    tempString: string;
    i         : integer;
begin
    for i := 0 to aList.Count - 1 do
    begin // Associate current item with a primary slot
        tempString := AssociatedBOD2(aList[i]);
        if not slContains(aList, tempString) then
            aList.Add(tempString);
    end;
end;

function StrEndsWithInteger(aString: string): boolean;
var
    slTemp  : TStringList;
    i       : integer;
begin
    // Begin debugMsg section
    

    slTemp           := TStringList.Create;
    slTemp.CommaText := '0, 1, 2, 3, 4, 5, 6, 7, 8, 9';
    result           := true;
    for i            := 0 to slTemp.Count - 1 do
    begin
        if StrEndsWith(aString, slTemp[i]) then
        begin
            slTemp.Free;
            exit;
        end;
    end;
    result := false;
    slTemp.Free;
end;

function FinalCharacter(aString: string): string;
begin
    result := RightStr(aString, 1);
end;

function RemoveFinalCharacter(aString: string): string;
begin
    result := Copy(aString, 0, Length(aString) - 1);
end;

// stuff below this is probably added by yggdrasil75
function AddMasterBySignature(Signature: string; Patch: IInterface): integer;
var
    i       : integer;
    temp    : IInterface;
begin
    
    { Debug } if debugMsg then
        addMessage('Adding Masters with ' + Signature);
    for i := 0 to FileCount - 1 do
    begin
        temp := FileByIndex(i);
        if Pos(GetFileName(Patch), GetFileName(temp)) < 1 then
        begin
            if HasGroup(temp, Signature) then
            begin
                AddMasterIfMissing(Patch, GetFileName(temp));
            end;
        end;
    end;
end;

function GatherMaterials: integer;
var
    TempList                              : TStringList;
    FileIndex, GroupIndex, f              : integer;
    CurrentFile, CurrentGroup, CurrentKYWD: IInterface;
begin
    MaterialList                    := TStringList.Create;
    MaterialList.Sorted             := true;
    MaterialList.Duplicates         := dupIgnore;
    MaterialList.NameValueSeparator := ';';
    for FileIndex                   := 0 to FileCount - 1 do
    begin
        CurrentFile := FileByIndex(FileIndex);
        if HasGroup(CurrentFile, 'KYWD') then
        begin
            CurrentGroup   := GroupBySignature(CurrentFile, 'KYWD');
            for GroupIndex := 0 to ElementCount(CurrentGroup) - 1 do
            begin
                CurrentKYWD := EditorID(elementbyindex(CurrentGroup, GroupIndex));
                if Pos('material', LowerCase(CurrentKYWD)) > 0 then
                begin
                    MaterialList.Add(CurrentKYWD);
                end
                else
                    if Pos('materiel', LowerCase(CurrentKYWD)) > 0 then
                    begin
                        MaterialList.Add(CurrentKYWD);
                    end
                    else
                        if Pos('clothing', LowerCase(CurrentKYWD)) > 0 then
                        begin
                            MaterialList.Add(CurrentKYWD);
                        end;
            end;
        end;
    end;
    TempList               := TStringList.Create;
    TempList.DelimitedText := Ini.ReadString('Crafting', 'sKYWDList', '');
    if firstRun then
    begin
        for f := 0 to TempList.Count - 1 do
        begin
            MaterialListPrinter(TempList.strings[f]);
        end;
    end;
    IniToMatList;
    for f := MaterialList.Count - 1 downto 0 do
    begin
        if TempList.IndexOf(MaterialList.strings[f]) < 0 then
            MaterialListPrinter(MaterialList.strings[f]);
    end;
    MaterialList.AddStrings(TempList);
    TempList.Free;
    TempList.clear;
    Ini.WriteString('Crafting', 'sKYWDList', MaterialList.CommaText);
    Ini.UpdateFile;
end;

function MaterialListPrinter(CurrentKYWDName: string): integer;
var
    invalidStuff, ValidSignatures, Output, Input, TempList: TStringList;
    edid, TempSig                                         : string;
    item, CurrentKYWD, CurrentItem, CurrentReference      : IInterface;
    ItemIndex, RecipeCount, k, a, i, l, LimitIndex        : integer;
    y, amount, limit                                      : Double;
begin
    

    ValidSignatures               := TStringList.Create;
    ValidSignatures.DelimitedText := 'AMMO,ARMO,WEAP';
    invalidStuff                  := TStringList.Create;
    invalidStuff.DelimitedText    := 'ARMO,AMMO,WEAP,SLGM,BOOK';
    Input                         := TStringList.Create;
    Output                        := TStringList.Create;
    CurrentKYWD                   := TrueRecordByEDID(CurrentKYWDName);
    if not Assigned(CurrentKYWD) then
        exit;
    RecipeCount := 0;
    for k       := ReferencedByCount(CurrentKYWD) - 1 downto 0 do
    begin
        { Debug } if debugMsg then
            addMessage('Cycle ' + IntToStr(k) + ' for kywd ' + CurrentKYWDName);
        CurrentItem := ReferencedByIndex(CurrentKYWD, k);
        TempSig     := Signature(CurrentItem);
        if ValidSignatures.IndexOf(TempSig) < 0 then
            Continue;
        if not isBlacklist(CurrentItem) then
            Continue;
        { Debug } if debugMsg then
            addMessage('Passed Signature');
        for a := ReferencedByCount(CurrentItem) - 1 downto 0 do
        begin
            { Debug } if debugMsg then
                addMessage('Recipe Search ' + IntToStr(a));
            CurrentReference := ReferencedByIndex(CurrentItem, a);
            if not Pos('COBJ', Signature(CurrentReference)) > 0 then
                Continue;
            { Debug } if debugMsg then
                addMessage('it is a recipe');
            if not equals(CurrentItem, LinksTo(ElementByPath(CurrentReference, 'CNAM'))) then
                Continue;
            { Debug } if debugMsg then
                addMessage('item is output');
            if not IsWinningOVerride(CurrentReference) then
                Continue;
            if Length(GetElementEditValues(CurrentReference, 'COCT')) = 0 then
                Continue
            else
                l := StrToInt64Def(GetElementEditValues(CurrentReference, 'COCT'), 0) - 1;
            { Debug } if debugMsg then
                addMessage('standard recipe limitations');
            TempList := TStringList.Create;
            for i    := l downto 0 do
            begin
                item := LinksTo(elementbyindex(elementbyindex(elementbyindex(ElementByPath(CurrentReference, 'Items'), i), 0), 0));
                if invalidStuff.IndexOf(Signature(item)) >= 0 then
                    Continue;
                edid      := EditorID(item);
                ItemIndex := Input.IndexOf(edid);
                { Debug } if debugMsg then
                    addMessage('matlistprinter ' + IntToStr(TempList.Count));
                if ItemIndex < 0 then
                begin
                    TempList.Add(edid);
                    TempList.Add(IntToStr(1));
                    TempList.Add(IntToStr(1));
                    TempList.Objects[0] := item;
                    ItemIndex           := Input.addObject(edid, TempList);
                end
                else
                    TempList.Assign(Input.Objects[ItemIndex]);
                TempList.strings[1]      := IntToStr(StrToInt64Def(TempList.strings[1], 0) + 1);
                TempList.strings[2]      := IntToStr(StrToInt64Def(TempList.strings[2], 0) + StrToInt64Def(GetEditValue(elementbyindex(elementbyindex(elementbyindex(ElementByPath(CurrentReference, 'Items'), i), 0), 1)), 0));
                Input.Objects[ItemIndex] := TempList;
            end;
            RecipeCount := RecipeCount + 1;
        end;
    end;
    limit := 0;
    for a := Input.Count - 1 downto 0 do
    begin
        TempList := Input.Objects[a];
        if Length(TempList.strings[1]) = 0 then
        begin
            Input.Delete[a];
            Continue;
        end;
        if Length(TempList.strings[2]) = 0 then
        begin
            Input.Delete[a];
            Continue;
        end;
        if StrToInt64Def(TempList.strings[1], 0) < (RecipeCount / 2) then
            Input.Delete(a);
        if not StrToFloatDef(StrToInt64Def(TempList.strings[1], 0) / StrToInt64Def(TempList.strings[2], 1), 1) > limit then
            Continue;
        limit      := StrToInt64Def(TempList.strings[1], 0) / StrToInt64Def(TempList.strings[2], 1);
        LimitIndex := a;
    end;
    if limit > 0 then
        y := 1 / limit
    else
        y := 1;

    for a := Input.Count - 1 downto 0 do
    begin
        TempList := Input.Objects[a];
        if TempList.Count < 0 then
            Continue;
        item := ObjectToElement(TempList.Objects[0]);
        edid := TempList.strings[0];
        if StrToInt64Def(TempList.strings[2], 0) > 0 then
            amount := StrToFloat(TempList.strings[1]) / StrToFloat(TempList.strings[2])
        else
            Continue;
        if amount = 0.0 then
            Continue;
        Output.Add('i' + Signature(item) + ':' + GetFileName(GetFile(MasterOrSelf(item))) + '|' + edid + '=' + FloatToStr(amount * y));
    end;
    if ContainsText('Clothing', CurrentKYWDName) then
    begin
        if Output.Length < 1 then
        begin
            Output.Add('iMISC:Skyrim.esm|RuinsLinenPile01=1.0');
        end;
    end;
    Input.Free;
    Ini.WriteString('Crafting', CurrentKYWDName, Output.CommaText);
    Ini.UpdateFile;
    Output.Free;
end;

function IniProcess: integer;
var
    TalkToUser: integer;
begin
    firstRun := true;
    Ini      := TMemIniFile.Create(ScriptsPath + 'ALLA.ini');
    firstRun := Ini.ReadBool('Defaults', 'UpdateINI', true);
    Ini.WriteBool('Defaults', 'UpdateINI', false);
    Ini.UpdateFile;
end;

procedure IniBlacklist;
begin
    Ini     := TMemIniFile.Create(ScriptsPath + 'ALLA.ini');
    disWord := TStringList.Create;
    if Ini.ReadString('blacklist', 'disallowedWords', '1') = '1' then
    begin
        disWord.Add('skin');
        Ini.WriteString('blacklist', 'disallowedWords', disWord.CommaText);
    end
    else
        disWord.DelimitedText := Ini.ReadString('blacklist', 'disallowedWords', '1');
    if Ini.ReadBool('blacklist', 'disallownonplayable', true) then
    begin
        Ini.WriteBool('blacklist', 'disallownonplayable', true);
        disallowNP := Ini.ReadBool('blacklist', 'disallownonplayable', true);
    end;
    DisKeyword := TStringList.Create;
    if Ini.ReadString('blacklist', 'disallowedKeywords', '1') = '1' then
    begin
        DisKeyword.Add('DisallowEnchanting');
        DisKeyword.Add('unique');
        DisKeyword.Add('noCraft');
        DisKeyword.Add('Dummy');
        Ini.WriteString('blacklist', 'disallowedKeywords', DisKeyword.CommaText);
    end
    else
        DisKeyword.DelimitedText := Ini.ReadString('blacklist', 'disallowedKeywords', '1');
    if Ini.ReadBool('blacklist', 'ignoreEmpty', true) then
    begin
        Ini.WriteBool('blacklist', 'ignoreEmpty', true);
        ignoreEmpty := Ini.ReadBool('blacklist', 'ignoreEmpty', true);
    end;
    Ini.UpdateFile;
end;

procedure IniALLASettings;
var
	UpdateExistingRecipes: boolean;
begin
    Ini                 := TMemIniFile.Create(ScriptsPath + 'ALLA.ini');
    defaultOutputPlugin := Ini.ReadString('Defaults', 'OutputPlugin', 'Automated Leveled List Addition.esp');
    if not ContainsText(defaultOutputPlugin, '.esp') then
        defaultOutputPlugin := defaultOutputPlugin + '.esp';
    Ini.WriteString('Defaults', 'OutputPlugin', defaultOutputPlugin);
    defaultGenerateEnchantedVersions := Ini.ReadBool('Defaults', 'GenerateEnchanted', false);
    Ini.WriteBool('Defaults', 'GenerateEnchanted', defaultGenerateEnchantedVersions);
    defaultReplaceInLeveledList := Ini.ReadBool('Defaults', 'ReplaceInLL', true);
    Ini.WriteBool('defaults', 'ReplaceInLL', defaultReplaceInLeveledList);
    defaultAllowDisenchanting := Ini.ReadBool('Defaults', 'Disenchant', true);
    Ini.WriteBool('Defaults', 'Disenchant', defaultAllowDisenchanting);
    defaultBreakdownEnchanted := Ini.ReadBool('defaults', 'BreakdownEnchanted', true);
    Ini.WriteBool('Defaults', 'BreakdownEnchanted', defaultBreakdownEnchanted);
    defaultBreakdownDaedric := Ini.ReadBool('Defaults', 'BreakdownDaedric', true);
    Ini.WriteBool('Defaults', 'BreakdownDaedric', defaultBreakdownDaedric);
    defaultBreakdownDLC := Ini.ReadBool('Defaults', 'BreakdownDLC', true);
    Ini.WriteBool('Defaults', 'BreakdownDLC', defaultBreakdownDLC);
    defaultGenerateRecipes := Ini.ReadBool('Defaults', 'GenerateCrafting', true);
    Ini.WriteBool('Defaults', 'GenerateCrafting', defaultGenerateRecipes);
    defaultChanceBoolean := Ini.ReadBool('Defaults', 'defaultChanceBoolean', true);
    Ini.WriteBool('Defaults', 'defaultChanceBoolean', defaultChanceBoolean);
    defaultAutoDetect := Ini.ReadBool('Defaults', 'defaultAutoDetect', true);
    Ini.WriteBool('Defaults', 'defaultAutoDetect', defaultAutoDetect);
    defaultBreakdown := Ini.ReadBool('Defaults', 'defaultBreakdown', true);
    Ini.WriteBool('Defaults', 'defaultBreakdown', defaultBreakdown);
    defaultOutfitSet := Ini.ReadBool('Defaults', 'defaultOutfitSet', false);
    Ini.WriteBool('Defaults', 'defaultOutfitSet', defaultOutfitSet);
    defaultCrafting := Ini.ReadBool('Defaults', 'defaultCrafting', true);
    Ini.WriteBool('Defaults', 'defaultCrafting', defaultCrafting);
    defaultTemper := Ini.ReadBool('Defaults', 'defaultTemper', true);
    Ini.WriteBool('Defaults', 'defaultTemper', defaultTemper);
    defaultChanceMultiplier := Ini.ReadInteger('Defaults', 'defaultChanceMultiplier', 10);
    Ini.WriteInteger('Defaults', 'defaultChanceMultiplier', defaultChanceMultiplier);
    defaultEnchMultiplier := Ini.ReadInteger('Defaults', 'defaultEnchMultiplier', 100);
    Ini.WriteInteger('Defaults', 'defaultEnchMultiplier', defaultEnchMultiplier);
    defaultItemTier01 := Ini.ReadInteger('Defaults', 'defaultItemTier01', 1);
    Ini.WriteInteger('Defaults', 'defaultItemTier01', defaultItemTier01);
    defaultItemTier02 := Ini.ReadInteger('Defaults', 'defaultItemTier02', 10);
    Ini.WriteInteger('Defaults', 'defaultItemTier02', defaultItemTier02);
    defaultItemTier03 := Ini.ReadInteger('Defaults', 'defaultItemTier03', 20);
    Ini.WriteInteger('Defaults', 'defaultItemTier03', defaultItemTier03);
    defaultItemTier04 := Ini.ReadInteger('Defaults', 'defaultItemTier04', 30);
    Ini.WriteInteger('Defaults', 'defaultItemTier04', defaultItemTier04);
    defaultItemTier05 := Ini.ReadInteger('Defaults', 'defaultItemTier05', 35);
    Ini.WriteInteger('Defaults', 'defaultItemTier05', defaultItemTier05);
    defaultItemTier06 := Ini.ReadInteger('Defaults', 'defaultItemTier06', 40);
    Ini.WriteInteger('Defaults', 'defaultItemTier06', defaultItemTier06);
    defaultTemperLight := Ini.ReadInteger('Defaults', 'defaultTemperLight', 1);
    Ini.WriteInteger('Defaults', 'defaultTemperLight', defaultTemperLight);
    defaultTemperHeavy := Ini.ReadInteger('Defaults', 'defaultTemperHeavy', 2);
    Ini.WriteInteger('Defaults', 'defaultTemperHeavy', defaultTemperHeavy);
    ProcessTime := Ini.ReadBool('Defaults', 'ProcessTime', false);
    Ini.WriteBool('Defaults', 'ProcessTime', ProcessTime);
    Constant := Ini.ReadBool('Defaults', 'Constant', true);
    Ini.WriteBool('Defaults', 'Constant', Constant);
	debugmsg := Ini.ReadBool('Defaults', 'Debugmsg', false);
	Ini.WriteBool('defaults', 'debugmsg', debugmsg);
	debugLevel := Ini.ReadInteger('defaults', 'debugLevel', 1);
	Ini.WriteInteger('defaults', 'debugLevel', debugLevel);
	UpdateExistingRecipes := Ini.Readstring('defaults', 'CraftingReuse', true);
	Ini.WriteString('defaults', 'CraftingReuse', UpdateExistingRecipes);
	InvalidEffect := TStringList.Create;
	InvalidEffect.DelimitedText := Ini.ReadString('defaults', 'InvalidEnchantments', 'Nightingale, Chillrend, Frostmere, trap, Miraak, Base, Haknir');
	Ini.WriteString('defaults', 'InvalidEnchantments', InvalidEffect.CommaText);
	SetObject('Overwrite', UpdateExistingRecipes, slGlobal);
    SetObject('GenerateEnchantedVersions', defaultGenerateEnchantedVersions, slGlobal);
    SetObject('ReplaceInLeveledList', defaultReplaceInLeveledList, slGlobal);
    SetObject('AllowDisenchanting', defaultAllowDisenchanting, slGlobal);
    SetObject('BreakdownEnchanted', defaultBreakdownEnchanted, slGlobal);
    SetObject('ChanceMultiplier', defaultChanceMultiplier, slGlobal);
    SetObject('BreakdownDaedric', defaultBreakdownDaedric, slGlobal);
    SetObject('GenerateRecipes', defaultGenerateRecipes, slGlobal);
    SetObject('EnchMultiplier', defaultEnchMultiplier, slGlobal);
    SetObject('AddtoLeveledList', defaultAutoDetect, slGlobal);
    SetObject('ChanceBoolean', defaultChanceBoolean, slGlobal);
    SetObject('BreakdownDLC', defaultBreakdownDLC, slGlobal);
    SetObject('TemperLight', defaultTemperLight, slGlobal);
    SetObject('TemperHeavy', defaultTemperHeavy, slGlobal);
    SetObject('ItemTier01', defaultItemTier01, slGlobal);
    SetObject('ItemTier02', defaultItemTier02, slGlobal);
    SetObject('ItemTier03', defaultItemTier03, slGlobal);
    SetObject('ItemTier04', defaultItemTier04, slGlobal);
    SetObject('ItemTier05', defaultItemTier05, slGlobal);
    SetObject('ItemTier06', defaultItemTier06, slGlobal);
    SetObject('Breakdown', defaultBreakdown, slGlobal);
    SetObject('Crafting', defaultCrafting, slGlobal);
    SetObject('Temper', defaultTemper, slGlobal);
    Ini.UpdateFile;
end;

function IniToMatList: integer;
var
    i, t, f, as , MLI         : integer;
    cs, cg, cf, ce, ca        : string;
    MaterialsSublist, TempList: TStringList;
    item                      : IInterface;
begin
    

    for MLI := MaterialList.Count - 1 downto 0 do
    begin
        { debug } if debugMsg then
            addMessage('initomatlist (0), keyword: ' + MaterialList[MLI]);
        TempList               := TStringList.Create;
        MaterialsSublist       := TStringList.Create;
        TempList.DelimitedText := Ini.ReadString('Crafting', MaterialList.strings[MLI], '');
        for i                  := TempList.Count - 1 downto 0 do
        begin
            cs := TempList.strings[i];
            { debug } if debugMsg then
                addMessage('initomatlist (1): ' + cs);
            t  := Pos(':', cs);
            f  := Pos('|', cs);
            as := Pos('=', cs);
            if Copy(cs, 0, 1) = 'i' then
            begin
                cg   := Uppercase(Copy(cs, 2, 4));
                cf   := Copy(cs, t + 1, f - t - 1);
                ce   := Copy(cs, f + 1, as - f - 1);
                ca   := Copy(cs, as + 1, Length(cs) - as);
                item := MainRecordByEditorID(GroupBySignature(FileByName(cf), cg), ce);
                { Debug } if debugMsg then
                    addMessage('IniToMatList (2): ' + cg + ' ' + cf + ' ' + ce + ' ' + ca);
                MaterialsSublist.addObject(FloatToStr(ca), item);
                { Debug } // if debugMsg then addMessage('IniToMatList (3): ' + FloatToStr(ca) + ' ' + EditorID(item) + ' ' + EditorID(ObjectToElement(MaterialsSublist.Objects[MaterialsSublist.IndexOf(ca)])));
            end
            else
                if Pos('p', Copy(cs, 0, 1)) = 0 then
                begin
                    cf := Copy(cs, t + 1, f - 1);
                    ce := Copy(cs, f + 1, Length(cs) - 1);
                    MaterialsSublist.addObject('Perk', RecordByEDID(FileByName(cf), ce));
                    { Debug } if debugMsg then
                        addMessage('IniToMatList (4): ' + EditorID(item) + ' ' + EditorID(ObjectToElement(MaterialsSublist.Objects[MaterialsSublist.IndexOf(ca)])));
                end;
        end;
        MaterialList.Objects[MLI] := MaterialsSublist;
        // MaterialList.Objects[MLI] := TempList;
    end;
end;

function MakeCraftable(aRecord, aPlugin: IInterface): IInterface;
var
    recipeCraft, recipeCondition, recipeConditions, recipeItem, recipeitems, keywords: IInterface;
    amountOfMainComponent, ki, amountOfAdditionalComponent, e                        : integer;
	UpdateExistingRecipes: boolean;
begin
    

    recipeCraft := FindRecipe(false, HashedList, aRecord, aPlugin);
	UpdateExistingRecipes := GetObject('overwrite', slGlobal);
	if UpdateExistingRecipes then begin
		if Assigned(recipeCraft) then
		begin
			{ Debug } if debugMsg then
				addMessage('Recipe Found for: ' + name(aRecord) + ' emptying');
			BeginUpdate(recipeCraft);
			try
				for e := ElementCount(ElementByPath(recipeCraft, 'Items')) - 1 downto 0 do
				begin
					RemoveByIndex(ElementByPath(recipeCraft, 'Items'), e, false);
				end;
				for e := ElementCount(ElementByPath(recipeCraft, 'Conditions')) - 1 downto 0 do
				begin
					RemoveByIndex(ElementByPath(recipeCraft, 'Conditions'), e, false);
				end;
			finally
				EndUpdate(recipeCraft);
			end;
		end;
	end else if assigned(recipeCraft) then begin
		addMessage('ignoring existing recipes');
		exit;
	end;
    if not Assigned(recipeCraft) then
    begin
        { Debug } if debugMsg then
            addMessage('No Recipe Found for: ' + name(aRecord) + ' Generating new one');
        recipeCraft := createRecord(aPlugin, 'COBJ');
        // add reference to the created object
        SetElementEditValues(recipeCraft, 'CNAM', name(aRecord));
        // set Created Object Count
        SetElementEditValues(recipeCraft, 'NAM1', '1');
    end;

    // {Debug} if debugMsg then addMessage('checkpoint');
    // recipeCraft := FindCraftingRecipe;
    // add required items list
    Add(recipeCraft, 'items', true);
    // get reference to required items list inside recipe
    recipeitems := ElementByPath(recipeCraft, 'items');
    // trying to figure out propper requirements amount
    if HasKeyword(aRecord, 'ArmorHeavy') then
    begin // if it is heavy armor, base the amount of materials on the weight
        { debug } if debugMsg then
            addMessage('recipe is for heavy');
        amountOfMainComponent := 0;
        if Assigned(recipeitems) and Assigned(aRecord) then
            amountOfMainComponent   := MaterialAmountHeavy(amountOfMainComponent, amountOfAdditionalComponent, recipeitems, aRecord);
        amountOfAdditionalComponent := ceil(2);
        keywords                    := ElementByPath(aRecord, 'KWDA');
    end
    else
        if HasKeyword(aRecord, 'ArmorLight') then
        begin // Light armor is based on rating
            { debug } if debugMsg then
                addMessage('recipe is for light');
            amountOfMainComponent       := materialAmountLight(amountOfMainComponent, amountOfAdditionalComponent, recipeitems, aRecord);
            amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
            if amountOfAdditionalComponent < 1 then
                amountOfAdditionalComponent := 1;
            if amountOfMainComponent < 1 then
                amountOfMainComponent := 1;
            if amountOfMainComponent > 10 then
                amountOfMainComponent := 10;
            if amountOfAdditionalComponent > 15 then
                amountOfAdditionalComponent := 15;
            YggAdditem(recipeitems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
            keywords := ElementByPath(aRecord, 'KWDA');
        end
        else
            if HasKeyword(aRecord, 'ArmorClothing') then
            begin // clothing
                // uses -1.4ln(x/10)+10 for value to get amount
                { Debug } if debugMsg then
                    addMessage(name(aRecord) + ' is Clothing');
                if StrToFloat(GetElementEditValues(aRecord, 'DATA\Value')) < 42 then
                begin
                    amountOfMainComponent := 5;
                end
                else
                    if StrToFloat(GetElementEditValues(aRecord, 'DATA\Value')) < 173 then
                    begin
                        amountOfMainComponent := 4;
                    end
                    else
                        if StrToFloat(GetElementEditValues(aRecord, 'DATA\Value')) < 730 then
                        begin
                            amountOfMainComponent := 3;
                        end
                        else
                            if StrToFloat(GetElementEditValues(aRecord, 'DATA\Value')) < 3020 then
                            begin
                                amountOfMainComponent := 2;
                            end
                            else
                                if StrToFloat(GetElementEditValues(aRecord, 'DATA\Value')) > 3020 then
                                    amountOfMainComponent := 1;

                // uses -2.5ln(-x+51)+10 for weight to get a second amount and add to first.
                if StrToFloat(GetElementEditValues(aRecord, 'DATA\Weight')) >= 50 then
                begin
                    amountOfMainComponent := amountOfMainComponent + 5;
                end
                else
                    if StrToFloat(GetElementEditValues(aRecord, 'DATA\Weight')) > 48 then
                    begin
                        amountOfMainComponent := amountOfMainComponent + 4;
                    end
                    else
                        if StrToFloat(GetElementEditValues(aRecord, 'DATA\Weight')) > 46 then
                        begin
                            amountOfMainComponent := amountOfMainComponent + 3;
                        end
                        else
                            if StrToFloat(GetElementEditValues(aRecord, 'DATA\Weight')) > 40 then
                            begin
                                amountOfMainComponent := amountOfMainComponent + 2;
                            end
                            else
                                if StrToFloat(GetElementEditValues(aRecord, 'DATA\Weight')) > 26 then
                                begin
                                    amountOfMainComponent := amountOfMainComponent + 1;
                                end
                                else
                                    amountOfMainComponent := amountOfMainComponent + 0;
                amountOfAdditionalComponent               := floor(amountOfMainComponent / 3);
                if amountOfAdditionalComponent < 1 then
                    amountOfAdditionalComponent := 1;
                if amountOfMainComponent < 1 then
                    amountOfMainComponent := 1;

            end
            else
                if HasKeyword(aRecord, 'ArmorJewelry') then
                begin // jewelry
                    { Debug } if debugMsg then
                        addMessage(name(aRecord) + ' is Jewelry');
                    if StrToFloat(GetElementEditValues(aRecord, 'DATA\Value')) < 42 then
                    begin
                        amountOfMainComponent := 5;
                    end
                    else
                        if StrToFloat(GetElementEditValues(aRecord, 'DATA\Value')) < 173 then
                        begin
                            amountOfMainComponent := 4;
                        end
                        else
                            if StrToFloat(GetElementEditValues(aRecord, 'DATA\Value')) < 730 then
                            begin
                                amountOfMainComponent := 3;
                            end
                            else
                                if StrToFloat(GetElementEditValues(aRecord, 'DATA\Value')) < 3020 then
                                begin
                                    amountOfMainComponent := 2;
                                end
                                else
                                    if StrToFloat(GetElementEditValues(aRecord, 'DATA\Value')) > 3020 then
                                        amountOfMainComponent := 1;
                    amountOfAdditionalComponent               := floor(StrToFloat(GetElementEditValues(aRecord, 'DATA\Weight')) * 0.2 / 3);
                    if amountOfAdditionalComponent < 1 then
                        amountOfAdditionalComponent := 1;
                    if amountOfMainComponent < 1 then
                        amountOfMainComponent := 1;

                    YggAdditem(recipeitems, getRecordByFormID('0005AD9E'), amountOfMainComponent); // gold
                    keywords := ElementByPath(aRecord, 'KWDA');

                end else begin
                    { debug } if debugMsg then
                        addMessage(name(aRecord) + ' is not clothing, jewelry, or armor');
                    amountOfMainComponent       := 3;
                    amountOfAdditionalComponent := 2;
                    keywords                    := ElementByPath(aRecord, 'KWDA');

                end;

    for ki := 0 to ElementCount(keywords) - 1 do
    begin
        { Debug } if debugMsg then
            addMessage('makcraftable ' + GetEditValue(elementbyindex(keywords, ki)));
        MatByKYWD(EditorID(LinksTo(elementbyindex(keywords, ki))), recipeitems, amountOfMainComponent);
    end;

    // set EditorID for recipe
    if Pos('ARMO', Signature(aRecord)) > 0 then
        SetElementEditValues(recipeCraft, 'EDID', 'RecipeArmor' + GetElementEditValues(aRecord, 'EDID'));
    if Pos('AMMO', Signature(aRecord)) > 0 then
        SetElementEditValues(recipeCraft, 'EDID', 'RecipeAmmo' + GetElementEditValues(aRecord, 'EDID'));
    if Pos('WEAP', Signature(aRecord)) > 0 then
        SetElementEditValues(recipeCraft, 'EDID', 'RecipeWeapon' + GetElementEditValues(aRecord, 'EDID'));

    // add reference to the workbench keyword
    Workbench(amountOfMainComponent, amountOfAdditionalComponent, recipeCraft, recipeCondition, recipeConditions, recipeItem, recipeitems, aRecord);

    // remove nil record in items requirements, if any
    //RemoveInvalidEntries(recipeCraft);

    if GetElementEditValues(recipeCraft, 'COCT') = '' then
    begin
        { Debug } if debugMsg then
            addMessage('no item requirements was specified for - ' + name(aRecord));
        Remove(recipeCraft);
        // YggAdditem(recipeItems, getRecordByFormID('0005AD9E'), 10); // gold
    end
    else
        if not Assigned(ElementByPath(recipeCraft, 'COCT')) then
        begin
            { Debug } if debugMsg then
                addMessage('no item requirements was specified for - ' + name(aRecord));
            Remove(recipeCraft);
            // YggAdditem(recipeItems, getRecordByFormID('0005AD9E'), 10); // gold
        end
        else
            if not Assigned(ElementByPath(recipeCraft, 'Items')) then
            begin
                { Debug } if debugMsg then
                    addMessage('no item requirements was specified for - ' + name(aRecord));
                Remove(recipeCraft);
                // YggAdditem(recipeItems, getRecordByFormID('0005AD9E'), 10); // gold
            end
            else
                if ElementCount(ElementByPath(recipeCraft, 'Items')) < 1 then
                begin
                    { Debug } if debugMsg then
                        addMessage('no item requirements was specified for - ' + name(aRecord));
                    Remove(recipeCraft);
                    // YggAdditem(recipeItems, getRecordByFormID('0005AD9E'), 10); // gold
                end;
end;

function YggcreateRecord(recordSignature: string; plugin: IInterface): IInterface;
var
    newRecordGroup: IInterface;
begin
    // get category in file
    newRecordGroup := GroupBySignature(plugin, recordSignature);

    // create record and return it
    result := ElementAssign(newRecordGroup, LowInteger, nil, false);
    // Result := Add(newRecordGroup, recordSignature, true);
end;

function MaterialAmountHeavy(amountOfMainComponent, amountOfAdditionalComponent: integer; recipeitems, aRecord: IInterface): integer;
var
    temp: Double;
begin
    temp := StrToFloat(GetElementEditValues(aRecord, 'DATA\Weight'));
    if HasKeyword(aRecord, 'ArmorCuirass') then
    begin
        amountOfMainComponent := floor(temp * 0.3);
        if amountOfMainComponent < 10 then
            amountOfMainComponent := 10;
        if amountOfMainComponent > 15 then
            amountOfMainComponent   := 15;
        amountOfAdditionalComponent := floor(amountOfMainComponent / 5);
        if amountOfAdditionalComponent < 1 then
            amountOfAdditionalComponent := 1;
        if amountOfAdditionalComponent > 3 then
            amountOfAdditionalComponent := 3;
        YggAdditem(recipeitems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
        YggAdditem(recipeitems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
    end
    else
        if HasKeyword(aRecord, 'ArmorBoots') then
        begin
            amountOfMainComponent := ceil(temp * 0.7);
            if amountOfMainComponent < 3 then
                amountOfMainComponent := 3;
            if amountOfMainComponent > 7 then
                amountOfMainComponent   := 7;
            amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
            if amountOfAdditionalComponent < 1 then
                amountOfAdditionalComponent := 1;
            if amountOfAdditionalComponent > 3 then
                amountOfAdditionalComponent := 3;
            YggAdditem(recipeitems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
            YggAdditem(recipeitems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
        end
        else
            if HasKeyword(aRecord, 'ArmorGauntlets') then
            begin
                amountOfMainComponent := floor(temp * 0.7);
                if amountOfMainComponent < 4 then
                    amountOfMainComponent := 4;
                if amountOfMainComponent > 7 then
                    amountOfMainComponent   := 7;
                amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
                if amountOfAdditionalComponent < 1 then
                    amountOfAdditionalComponent := 1;
                if amountOfAdditionalComponent > 3 then
                    amountOfAdditionalComponent := 3;
                YggAdditem(recipeitems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
                YggAdditem(recipeitems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
            end
            else
                if HasKeyword(aRecord, 'ArmorHelmet') then
                begin
                    amountOfMainComponent := ceil(temp * 0.3);
                    if amountOfMainComponent < 2 then
                        amountOfMainComponent := 2;
                    if amountOfMainComponent > 5 then
                        amountOfMainComponent   := 5;
                    amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
                    if amountOfAdditionalComponent < 1 then
                        amountOfAdditionalComponent := 1;
                    if amountOfAdditionalComponent > 3 then
                        amountOfAdditionalComponent := 3;
                    YggAdditem(recipeitems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
                    YggAdditem(recipeitems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
                end
                else
                    if HasKeyword(aRecord, 'ArmorPants') then
                    begin
                        amountOfMainComponent := floor(temp * 0.7);
                        if amountOfMainComponent < 3 then
                            amountOfMainComponent := 3;
                        if amountOfMainComponent > 8 then
                            amountOfMainComponent   := 8;
                        amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
                        if amountOfAdditionalComponent < 1 then
                            amountOfAdditionalComponent := 1;
                        if amountOfAdditionalComponent > 3 then
                            amountOfAdditionalComponent := 3;
                        YggAdditem(recipeitems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
                        YggAdditem(recipeitems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
                    end
                    else
                        if HasKeyword(aRecord, 'ArmorUnderwear') then
                        begin
                            amountOfMainComponent := 1;
                        end
                        else
                            if HasKeyword(aRecord, 'ArmorUnderwearTop') then
                            begin
                                amountOfMainComponent := 2;
                            end
                            else
                                if HasKeyword(aRecord, 'ArmorShirt') then
                                begin
                                    amountOfMainComponent := floor(temp * 0.7);
                                    if amountOfMainComponent < 3 then
                                        amountOfMainComponent := 3;
                                    if amountOfMainComponent > 8 then
                                        amountOfMainComponent   := 8;
                                    amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
                                    if amountOfAdditionalComponent < 1 then
                                        amountOfAdditionalComponent := 1;
                                    if amountOfAdditionalComponent > 3 then
                                        amountOfAdditionalComponent := 3;
                                    YggAdditem(recipeitems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
                                    YggAdditem(recipeitems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
                                end else begin
                                    amountOfMainComponent := ceil(random(5));
                                    if amountOfMainComponent < 1 then
                                        amountOfMainComponent := 1;
                                    if amountOfMainComponent > 5 then
                                        amountOfMainComponent   := 5;
                                    amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
                                    if amountOfAdditionalComponent < 1 then
                                        amountOfAdditionalComponent := 1;
                                    if amountOfAdditionalComponent > 3 then
                                        amountOfAdditionalComponent := 3;
                                    YggAdditem(recipeitems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
                                    YggAdditem(recipeitems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
                                end;
    result := amountOfMainComponent;
end;

function materialAmountLight(amountOfMainComponent, amountOfAdditionalComponent: integer; recipeitems, aRecord: IInterface): integer;
var
    temp: Double;
begin
    temp := StrToFloat(GetElementEditValues(aRecord, 'DATA\Weight'));
    if HasKeyword(aRecord, 'ArmorCuirass') then
    begin
        amountOfMainComponent := floor(temp * 0.3);
        if amountOfMainComponent < 10 then
            amountOfMainComponent := 10;
        if amountOfMainComponent > 15 then
            amountOfMainComponent   := 15;
        amountOfAdditionalComponent := floor(amountOfMainComponent / 5);
        if amountOfAdditionalComponent < 1 then
            amountOfAdditionalComponent := 1;
        if amountOfAdditionalComponent > 3 then
            amountOfAdditionalComponent := 3;
        YggAdditem(recipeitems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
        YggAdditem(recipeitems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
    end
    else
        if HasKeyword(aRecord, 'ArmorBoots') then
        begin
            amountOfMainComponent := ceil(temp * 0.7);
            if amountOfMainComponent < 3 then
                amountOfMainComponent := 3;
            if amountOfMainComponent > 7 then
                amountOfMainComponent   := 7;
            amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
            if amountOfAdditionalComponent < 1 then
                amountOfAdditionalComponent := 1;
            if amountOfAdditionalComponent > 3 then
                amountOfAdditionalComponent := 3;
            YggAdditem(recipeitems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
            YggAdditem(recipeitems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
        end
        else
            if HasKeyword(aRecord, 'ArmorGauntlets') then
            begin
                amountOfMainComponent := floor(temp * 0.7);
                if amountOfMainComponent < 4 then
                    amountOfMainComponent := 4;
                if amountOfMainComponent > 7 then
                    amountOfMainComponent   := 7;
                amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
                if amountOfAdditionalComponent < 1 then
                    amountOfAdditionalComponent := 1;
                if amountOfAdditionalComponent > 3 then
                    amountOfAdditionalComponent := 3;
                YggAdditem(recipeitems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
                YggAdditem(recipeitems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
            end
            else
                if HasKeyword(aRecord, 'ArmorHelmet') then
                begin
                    amountOfMainComponent := ceil(temp * 0.3);
                    if amountOfMainComponent < 2 then
                        amountOfMainComponent := 2;
                    if amountOfMainComponent > 5 then
                        amountOfMainComponent   := 5;
                    amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
                    if amountOfAdditionalComponent < 1 then
                        amountOfAdditionalComponent := 1;
                    if amountOfAdditionalComponent > 3 then
                        amountOfAdditionalComponent := 3;
                    YggAdditem(recipeitems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
                    YggAdditem(recipeitems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
                end
                else
                    if HasKeyword(aRecord, 'ArmorPants') then
                    begin
                        amountOfMainComponent := floor(temp * 0.7);
                        if amountOfMainComponent < 3 then
                            amountOfMainComponent := 3;
                        if amountOfMainComponent > 8 then
                            amountOfMainComponent   := 8;
                        amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
                        if amountOfAdditionalComponent < 1 then
                            amountOfAdditionalComponent := 1;
                        if amountOfAdditionalComponent > 3 then
                            amountOfAdditionalComponent := 3;
                        YggAdditem(recipeitems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
                        YggAdditem(recipeitems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
                    end
                    else
                        if HasKeyword(aRecord, 'ArmorUnderwear') then
                        begin
                            amountOfMainComponent := 1;
                        end
                        else
                            if HasKeyword(aRecord, 'ArmorUnderwearTop') then
                            begin
                                amountOfMainComponent := 2;
                            end
                            else
                                if HasKeyword(aRecord, 'ArmorShirt') then
                                begin
                                    amountOfMainComponent := floor(temp * 0.7);
                                    if amountOfMainComponent < 3 then
                                        amountOfMainComponent := 3;
                                    if amountOfMainComponent > 8 then
                                        amountOfMainComponent   := 8;
                                    amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
                                    if amountOfAdditionalComponent < 1 then
                                        amountOfAdditionalComponent := 1;
                                    if amountOfAdditionalComponent > 3 then
                                        amountOfAdditionalComponent := 3;
                                    YggAdditem(recipeitems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
                                    YggAdditem(recipeitems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
                                end else begin
                                    amountOfMainComponent := ceil(random(5));
                                    if amountOfMainComponent < 1 then
                                        amountOfMainComponent := 1;
                                    if amountOfMainComponent > 5 then
                                        amountOfMainComponent   := 5;
                                    amountOfAdditionalComponent := floor(amountOfMainComponent / 3);
                                    if amountOfAdditionalComponent < 1 then
                                        amountOfAdditionalComponent := 1;
                                    if amountOfAdditionalComponent > 3 then
                                        amountOfAdditionalComponent := 3;
                                    YggAdditem(recipeitems, getRecordByFormID('000800E4'), amountOfAdditionalComponent); // LeatherStrips
                                    YggAdditem(recipeitems, getRecordByFormID('0005ACE4'), amountOfAdditionalComponent); // IngotIron
                                end;
    result := amountOfMainComponent;
end;

function FindRecipe(Create: boolean; List: TStringList; aRecord, Patch: IInterface): IInterface;
var
    recipeCraft: IInterface;
begin
    

    if List.IndexOf(LowerCase(EditorID(WinningOverride(aRecord)))) >= 0 then
    begin
        result := wbCopyElementToFile(ObjectToElement(List.Objects[List.IndexOf(EditorID(aRecord))]), Patch, false, true);
    end else begin
        if Create then
        begin
            recipeCraft := YggcreateRecord('COBJ');
            { Debug } if debugMsg then
                addMessage('No Recipe Found');

            // add reference to the created object
            SetElementEditValues(recipeCraft, 'CNAM', name(aRecord));
            // set Created Object Count
            SetElementEditValues(recipeCraft, 'NAM1', '1');
            result := recipeCraft;
        end;
    end;
end;

function Workbench(amountOfMainComponent, amountOfAdditionalComponent: integer; recipeCraft, recipeCondition, recipeConditions, recipeItem, recipeitems, aRecord: IInterface): IInterface;
begin
    

    if Signature(aRecord) = 'ARMO' then
    begin
        if HasKeyword(aRecord, 'ArmorClothing') then
            SetElementEditValues(recipeCraft, 'BNAM', GetEditValue(getRecordByFormID('0007866A'))) // tanning rack for clothing
        else
            SetElementEditValues(recipeCraft, 'BNAM', GetEditValue(getRecordByFormID('00088105'))); // forge
    end;
    if Signature(aRecord) = 'AMMO' then
        SetElementEditValues(recipeCraft, 'BNAM', GetEditValue(getRecordByFormID('00088108'))); // Sharpening wheel
    if Signature(aRecord) = 'WEAP' then
        SetElementEditValues(recipeCraft, 'BNAM', GetEditValue(getRecordByFormID('00088105'))); // forge
    { Debug } if debugMsg then
        addMessage('Finished Tailoring');
end;

function MatByKYWD(keyword: string; recipeitems: IInterface; amountOfMainComponent: integer): integer;
var
    CurrentMaterials: TStringList;
    a               : integer;
begin
    

    if MaterialList.IndexOf(keyword) < 0 then
        exit;
    { Debug } if debugMsg then
        addMessage('work');
    CurrentMaterials := MaterialList.Objects[MaterialList.IndexOf(keyword)];
    for a            := CurrentMaterials.Count - 1 downto 0 do
    begin
        { Debug } if debugMsg then
            addMessage('work 2');
        if Pos('Perk', CurrentMaterials.strings[a]) > 0 then
        begin
            { Debug } if debugMsg then
                addMessage('work 3 perk');
            // YggAddPerkCondition(recipeitems, ObjectToElement(CurrentMaterials.Objects[a]));
        end else begin
            { Debug } if debugMsg then
                addMessage('MatByKYWD: ' + name(ObjectToElement(CurrentMaterials.Objects[a])));
            YggAdditem(recipeitems, ObjectToElement(CurrentMaterials.Objects[a]), ceil(StrToFloat(CurrentMaterials.strings[a]) * amountOfMainComponent * (random(1) + 0.5)));
        end;
        tempPerkFunction(keyword, recipeitems, amountOfMainComponent);
    end;
end;

function InitializeRecipes: integer;
var
    f, r                                        : integer;
    BNAM, CurrentFile, CurrentGroup, CurrentItem: IInterface;
    StationEDID, temp                           : string;
begin
    

    Recipes            := TStringList.Create;
    Recipes.Duplicates := dupIgnore;
    Recipes.Sorted;

    for f := FileCount - 1 downto 0 do
    begin
        CurrentFile := FileByIndex(f);
        if HasGroup(CurrentFile, 'COBJ') then
        begin
            CurrentGroup := GroupBySignature(CurrentFile, 'COBJ');
            for r        := ElementCount(CurrentGroup) - 1 downto 0 do
            begin
                CurrentItem := elementbyindex(CurrentGroup, r);
                BNAM        := LinksTo(ElementByPath(CurrentItem, 'BNAM'));
                temp        := LowerCase(EditorID(WinningOverride(LinksTo(ElementByPath(CurrentItem, 'CNAM')))));
                StationEDID := LowerCase(EditorID(BNAM));
                if IsWinningOVerride(CurrentItem) then
                begin
                    if not(ContainsText(StationEDID, 'armortable')) and not(ContainsText(StationEDID, 'sharpening')) and (ContainsText(StationEDID, 'forge') or (ContainsText(StationEDID, 'skyforge'))) and not(ContainsText(StationEDID, 'cook')) then
                    begin
                        Recipes.addObject(temp, CurrentItem);
                        if debugMsg then
                            addMessage('adding recipe ' + name(CurrentItem));
                    end
                    else
                        if (StationEDID = 'Smelter') then
                        begin
                            Items := ElementByPath(CurrentItem, 'Items');
                            for i := ElementCount(Items) - 1 downto 0 do
                            begin
                                item    := WinningOverride(LinksTo(ElementByPath(elementbyindex(Items, i), 'CNTO\Item')));
                                sigItem := Signature(item);
                            end;
                        end;
                end;
            end;
        end else begin
            Continue;
        end;
    end;
    HashedList := THashedStringList.Create;
    HashedList.Assign(Recipes);
    // temper
    Recipes            := TStringList.Create;
    Recipes.Duplicates := dupIgnore;
    Recipes.Sorted;

    for f := FileCount - 1 downto 0 do
    begin
        CurrentFile := FileByIndex(f);
        if HasGroup(CurrentFile, 'COBJ') then
        begin
            CurrentGroup := GroupBySignature(CurrentFile, 'COBJ');
            for r        := ElementCount(CurrentGroup) - 1 downto 0 do
            begin
                CurrentItem := elementbyindex(CurrentGroup, r);
                BNAM        := LinksTo(ElementByPath(CurrentItem, 'BNAM'));
                temp        := LowerCase(EditorID(WinningOverride(LinksTo(ElementByPath(CurrentItem, 'CNAM')))));
                StationEDID := LowerCase(EditorID(BNAM));
                if IsWinningOVerride(CurrentItem) then
                begin
                    if (ContainsText(StationEDID, 'armortable')) or (ContainsText(StationEDID, 'sharpening')) and not(ContainsText(StationEDID, 'cook')) then
                    begin
                        Recipes.addObject(temp, CurrentItem);
                        if debugMsg then
                            addMessage('adding recipe ' + name(CurrentItem));
                    end
                    else
                        if (StationEDID = 'Smelter') then
                        begin
                            Items := ElementByPath(CurrentItem, 'Items');
                            for i := ElementCount(Items) - 1 downto 0 do
                            begin
                                item    := WinningOverride(LinksTo(ElementByPath(elementbyindex(Items, i), 'CNTO\Item')));
                                sigItem := Signature(item);
                            end;
                        end;
                end;
            end;
        end else begin
            Continue;
        end;
    end;
    HashedTemperList := THashedStringList.Create;
    HashedTemperList.Assign(Recipes);
end;

function tempPerkFunction(keyword: string; recipeitems: IInterface; amountOfMainComponent: integer): integer;
var
    CurrentMaterials: IInterface;
    a               : integer;
begin
    if TempPerkListExtra.IndexOf(keyword) < 0 then
        exit;
    YggAddPerkCondition(recipeitems, ObjectToElement(TempPerkListExtra.Objects[TempPerkListExtra.IndexOf(keyword)]));
end;

procedure tempPerkFunctionSetup;
begin
    TempPerkListExtra            := TStringList.Create;
    TempPerkListExtra.Sorted     := true;
    TempPerkListExtra.Duplicates := dupIgnore;
    TempPerkListExtra.addObject('ArmorMaterialDragonscale', getRecordByFormID('00052190'));
    TempPerkListExtra.addObject('ArmorMaterialDragonplate', getRecordByFormID('00052190'));
    TempPerkListExtra.addObject('ArmorMaterialDaedric', getRecordByFormID('000CB413'));
    TempPerkListExtra.addObject('ArmorMaterialDwarven', getRecordByFormID('000CB40E'));
    TempPerkListExtra.addObject('ArmorMaterialEbony', getRecordByFormID('000CB412'));
    TempPerkListExtra.addObject('ArmorMaterialElven', getRecordByFormID('000CB40F'));
    TempPerkListExtra.addObject('ArmorMaterialElvenGilded', getRecordByFormID('000CB40F'));
    TempPerkListExtra.addObject('ArmorMaterialBonemoldHeavy', getRecordByFormID('000CB40D'));
    TempPerkListExtra.addObject('DLC2ArmorMaterialBonemoldHeavy', getRecordByFormID('000CB40D'));
    TempPerkListExtra.addObject('ArmorMaterialGlass', getRecordByFormID('000CB411'));
    TempPerkListExtra.addObject('ArmorMaterialImperialHeavy', getRecordByFormID('000CB40D'));
    TempPerkListExtra.addObject('ArmorMaterialOrcish', getRecordByFormID('000CB410'));
    TempPerkListExtra.addObject('ArmorMaterialScaled', getRecordByFormID('000CB414'));
    TempPerkListExtra.addObject('ArmorMaterialSteel', getRecordByFormID('000CB40D'));
    TempPerkListExtra.addObject('ArmorMaterialSteelPlate', getRecordByFormID('000CB414'));
    TempPerkListExtra.addObject('ArmorMaterialNordicHeavy', getRecordByFormID('000CB414'));
    TempPerkListExtra.addObject('DLC2ArmorMaterialNordicHeavy', getRecordByFormID('000CB414'));
    TempPerkListExtra.addObject('ArmorMaterialStalhrimHeavy', getRecordByFormID('000CB412'));
    TempPerkListExtra.addObject('DLC2ArmorMaterialStalhrimHeavy', getRecordByFormID('000CB412'));
    TempPerkListExtra.addObject('ArmorMaterialStalhrimLight', getRecordByFormID('000CB412'));
    TempPerkListExtra.addObject('DLC2ArmorMaterialStalhrimLight', getRecordByFormID('000CB412'));
    TempPerkListExtra.addObject('ArmorMaterialBonemoldHeavy2', getRecordByFormID('000CB40D'));
    TempPerkListExtra.addObject('ArmorMaterialChitinHeavy', getRecordByFormID('000CB40F'));
    TempPerkListExtra.addObject('DLC2ArmorMaterialChitinHeavy', getRecordByFormID('000CB40F'));
    TempPerkListExtra.addObject('ArmorMaterialChitinLight', getRecordByFormID('000CB40F'));
    TempPerkListExtra.addObject('DLC2ArmorMaterialChitinLight', getRecordByFormID('000CB40F'));
end;

function TrueRecordByEDID(edid: string): IInterface;
var
    a       : integer;
    temp    : IInterface;
begin
    
    for a    := FileCount - 1 downto 0 do
    begin
        temp := MainRecordByEditorID(GroupBySignature(FileByIndex(a), 'KYWD'), edid);
        if Assigned(temp) then
            break;
    end;
    if not Assigned(temp) then
    begin
        { Debug } if debugMsg then
            addMessage('there is a typo in a edid');
    end;
    result := temp;
end;

// adds item record reference to the list
function YggAdditem(List: IInterface; item: IInterface; amount: integer): IInterface;
var
    newItem : IInterface;
    listName: string;
begin
    
    // add new item to list
    newItem  := ElementAssign(List, HighInteger, nil, false);
    listName := name(List);
    { debug } if debugMsg then
        addMessage('Current COBJ is ' + name(newItem));
    if Length(listName) = 0 then
    begin
        { debug } if debugMsg then
            addMessage('Crafting Recipe doesnt have proper item list');
        exit;
    end;
    // COBJ
    if listName = 'Items' then
    begin
        // set item reference
        SetElementEditValues(newItem, 'CNTO - Item\Item', GetEditValue(item));
        // set amount
        SetElementEditValues(newItem, 'CNTO - Item\Count', amount);
    end;
    { debug } if debugMsg then
        addMessage('item added');
    // remove nil records from list
    YggremoveInvalidEntries(List);

    result := newItem;
end;

procedure YggremoveInvalidEntries(rec: IInterface);
var
    i, num                             : integer;
    lst, ent                           : IInterface;
    recordSignature, refName, countname: string;
begin
    recordSignature := Signature(rec);

    // containers and constructable objects
    if (recordSignature = 'CONT') or (recordSignature = 'COBJ') then
    begin
        lst       := ElementByName(rec, 'Items');
        refName   := 'CNTO\Item';
        countname := 'COCT';
    end

    num := ElementCount(lst);
    // check from the end since removing items will shift indexes
    for i := num - 1 downto 0 do
    begin
        // get individual entry element
        ent := elementbyindex(lst, i);
        // Check() returns error string if any or empty string if no errors
        if Check(ElementByPath(ent, refName)) <> '' then
            Remove(ent);
    end;

    // has counter
    if Assigned(countname) then
    begin
        // update counter subrecord
        if num <> ElementCount(lst) then
        begin
            num := ElementCount(lst);
            // set new value or remove subrecord if list is empty (like CK does)
            if num > 0 then
                SetElementNativeValues(rec, countname, num)
            else
                RemoveElement(rec, countname);
        end;
    end;
end;

// adds requirement 'HasPerk' to Conditions list
function YggAddPerkCondition(List: IInterface; perk: IInterface): IInterface;
var
    newCondition, tmp: IInterface;
begin
    if not(name(List) = 'Conditions') then
    begin
        if Signature(List) = 'COBJ' then
        begin // record itself was provided
            tmp := ElementByPath(List, 'Conditions');
            if not Assigned(tmp) then
            begin
                Add(List, 'Conditions', true);
                List         := ElementByPath(List, 'Conditions');
                newCondition := elementbyindex(List, 0); // xEdit will create dummy condition if new list was added
            end else begin
                List := tmp;
            end;
        end;
    end;

    if not Assigned(newCondition) then
    begin
        // create condition
        newCondition := ElementAssign(List, HighInteger, nil, false);
    end;

    // set type to Equal to
    SetElementEditValues(newCondition, 'CTDA\Type', '10000000');

    // set some needed properties
    SetElementEditValues(newCondition, 'CTDA\Comparison Value', '1');
    SetElementEditValues(newCondition, 'CTDA\Function', 'HasPerk');
    SetElementEditValues(newCondition, 'CTDA\Perk', GetEditValue(perk));
    SetElementEditValues(newCondition, 'CTDA\Run On', 'Subject');
    // don't know what is this, but it should be equal to -1, if Function Runs On Subject
    SetElementEditValues(newCondition, 'CTDA\Parameter #3', '-1');

    // remove nil records from list
    //RemoveInvalidEntries(List);

    result := newCondition;
end;

end.
