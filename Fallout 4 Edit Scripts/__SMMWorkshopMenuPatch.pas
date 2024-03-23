unit __SMMWorkshopMenuPatch;

uses praFunctions, mteFunctions, praUtil, moogieUtils;

var
	patchFile: IwbFile;
	patchFileCreated: boolean;
	mainFileKeywords, patchFileKeywords: TList;
	questRecord: IInterface;

//============================================================================

function Initialize: integer;
	var 
		i: integer;
		keywordRecord: IInterface;
	begin
		mainFileKeywords := TList.Create;
		patchFileKeywords := TList.Create;
	end;

//============================================================================

function GetNewKeyword(selectedKeyword: IInterface): IInterface;
	var
		idx: integer;
		copiedKeyword, linkedKeyword, referencedMenu: IInterface;
		newEditorId: string;
	begin
		linkedKeyword := LinksTo(selectedKeyword);
		if (mainFileKeywords.IndexOf(linkedKeyword) = -1) then begin
			copiedKeyword := wbCopyElementToFile(linkedKeyword, patchFile, true, true);
			SetElementEditValues(copiedKeyword, 'EDID', 'SMM_' + GetElementEditValues(linkedKeyword, 'EDID') + '_' + (GetFilteredFileName(selectedKeyword, true)));
			//TODO - CREATE QUEST HERE TO INSERT KEYWORD INTO MENU VIA SMM
			referencedMenu := GetReferencedFormID(linkedKeyword);
			CreateSMMQuestForKeyword(copiedKeyword, referencedMenu);
			mainFileKeywords.Add(linkedKeyword);
			patchFileKeywords.Add(copiedKeyword);
			// AddMessage('Adding keyword to main file list');
		end;
		idx := mainFileKeywords.IndexOf(linkedKeyword);
		Result := ObjectToElement(patchFileKeywords[idx]);
	end;
//ObjectToElement(mainFileKeywords[i])
//if (lst.IndexOf(s) = -1) then lst.Add(s);

//============================================================================

	function GetReferencedFormID(e: IInterface): IInterface;
		var
			i: integer;
		begin
		for i := 0 to ReferencedByCount(e) - 1 do begin
			if Signature(ReferencedByIndex(e, i)) = 'FLST' then begin
				Result := ReferencedByIndex(e, i);
				exit;
			end;
		end;
		Result := -1;
	end;

//============================================================================

function CreateSMMQuestForKeyword(keyword: IInterface; menu: IInterface): IInterface;
	var
		questRecord, questScript, scriptProperty, structElements, curStruct, curMember: IInterface;
	begin
		questRecord := CreateNewRecordInFile(patchFile, 'QUST');
		SetElementEditValues(questRecord, 'EDID', 'SMM_' + GetElementEditValues(keyword, 'EDID') + '_Quest');
		questScript := AddScript(questRecord, 'SettlementMenuManager:MenuInstaller');


		scriptProperty := createRawScriptProp(questScript, 'Author');
		SetElementEditValues(scriptProperty, 'Type', 'String');
		SetElementEditValues(scriptProperty, 'String', 'moogie');


		curStruct := appendStructToProperty(getOrCreateScriptPropArrayOfStruct(questScript, 'Menus'));

		CreateAndSetStructMember(curStruct, 'ModMenu', 'Object', keyword);

		CreateAndSetStructMember(curStruct, 'TargetMenu', 'Object', menu);


		// setPropertyValue(scriptProperty, menu);

		// structElements := ElementByPath(scriptProperty, 'Value\Array of Struct');
		// curStruct := Add(structElements, 'Member', true);
		AddMessage(Path(curStruct));





				// AddMessage('Creating quest for keyword: ' + GetElementEditValues(questScript, 'Properties\0\propertyName'));
		// scriptProperties := ElementByPath(questScript, 'Properties');
		// currentScriptProperty := ElementAssign(scriptProperties, HighInteger, nil, false);
		// SetElementEditValues(currentScriptProperty, 'propertyName', 'Author');
		// SetElementEditValues(currentScriptProperty, 'Type', 'String');
		// SetElementEditValues(currentScriptProperty, 'String', 'moogie');

		// currentScriptProperty := ElementAssign(scriptProperties, HighInteger, nil, false);
		// SetElementEditValues(currentScriptProperty, 'propertyName', 'Menus');
		// SetElementEditValues(currentScriptProperty, 'Type', 'Array of Struct');
		// scriptValues := ElementByPath(currentScriptProperty, 'Value\Array of Struct');
		// SetToDefault(curMember);
		// // SetElementNativeValues(curMember, 'memberName', 'ModMenu');
		// // SetElementEditValues(currentStruct, 'Flags', 'Edited');



		// if (menu <> -1) then begin
		// end;


		//create the second member and add it with the flst that comes from references

		Result := questRecord;
	end;


  // ElementAssign(ElementByPath(recBOOK, 'VMAD'), LowInteger, ElementByPath(tplBook, 'VMAD'), False);
  // props := ElementByPath(recBOOK, 'VMAD\Data\Scripts\Script\Properties');
  // prop := ElementByIndex(props, 0);
  // SetElementEditValues(prop, 'String', GetElementEditValues(recBOOK, 'FULL'));
  // prop := ElementByIndex(props, 2);
  // SetElementEditValues(prop, 'Value\Object Union\Object v2\FormID', Name(recSOUN));


//============================================================================

function Process(e: IInterface): integer;
	var
		recKeywords, keywordRecord, newCraftingRecipe: IInterface;
		i: Integer;
	begin
		// check if signature of the current record is COBJ meaning constructible object, if not we exit
		if (signature(e) <> 'COBJ') then begin exit; end;

		// get all the keywords of the record and assign it to recKeywords
		recKeywords := ElementBySignature(e, 'FNAM');

		// loop through all the keywords
		for i := 0 to ElementCount(recKeywords)-1 do begin
			// assign the current keyword to keywordRecord
			keywordRecord := LinksTo(ElementByIndex(recKeywords, i));

			// check if the keywordRecord belongs to the same file as the main file (file at index 0)
			if(GetFileName(keywordRecord) = GetFileName(FileByIndex(0))) then begin
				// check if the keywordRecord is a recipe filter keyword, if it is not continue to the next keyword
				if (GetElementEditValues(keywordRecord, 'TNAM') <> 'Recipe Filter') then begin continue; end;
				// check if patch file exists and if not create it and flip the switch for patch created to true
				if not patchFileCreated then begin
					patchFileCreated := true;
					patchFile := AddNewFileName('moo SMM ' + IntToStr(Random(10000)) + GetFilteredFileName(e, false), true);
					AddMessage('Creating patch file');
				end;

				// add the required masters to the patch file
				AddRequiredElementMasters(e, patchFile, false);
				// copy the current record as a new record to the patch file
				newCraftingRecipe := wbCopyElementToFile(e, patchFile, false, true);
				// newCraftingRecipe := getOverrideForElem(e, patchFile); //TEST this should perform the 2 above function calls of adding master and copying the record

				AddMessage(GetFilteredFileName(ElementByIndex(recKeywords, i), true));

				SetElementNativeValues(newCraftingRecipe, 'FNAM\[' + IntToStr(i) + ']', FormID(GetNewKeyword(ElementByIndex(recKeywords, i))));





			end;
		end;
	end;
end.


//============================================================================

function Finalize: integer;
	begin
		// free the memory used by the lists
		mainFileKeywords.Free;
		patchFileKeywords.Free;
	end;


//LinksTo(ElementBySignature(e, 'COCT')) = 0
//GetFileName(e) => gets the file name that the record is in
//FileByIndex(0) => gets the main file
// addRequiredMastersSilent