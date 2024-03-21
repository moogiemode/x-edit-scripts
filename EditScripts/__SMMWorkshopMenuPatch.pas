unit __SMMWorkshopMenuPatch;

uses praFunctions, mteFunctions, praUtil;

var
	patchFile: IwbFile;
	patchFileCreated: boolean;
	mainFileKeywords: TStringList;
	patchFileKeywords: TStringList;

//============================================================================

function Initialize: integer;
	var 
		i: integer;
		keywordRecord: IInterface;
	begin
		mainFileKeywords := TStringList.Create;
		patchFileKeywords := TStringList.Create;
	end;

//============================================================================

function GetKeywordIndex(keyword: IInterface): integer;
	var
		i: integer;
	begin
		for i := 0 to mainFileKeywords.Count-1 do begin
			AddMessage(mainFileKeywords[i]);
			// if (IntToHex(FormID(mainFileKeywords[i]), 8) = IntToHex(FormID(keyword), 8)) then begin
			// 	Result := i;
			// 	exit;
			// end;
		end;
		mainFileKeywords.Add(GetElementEditValues(keyword, 'EDID'));
		AddMessage('Keyword index: ' + IntToStr(mainFileKeywords.Count-1));
		Result := mainFileKeywords.Count-1;
	end;

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
				// if not patchFileCreated then begin
				// 	patchFileCreated := true;
				// 	patchFile := AddNewFileName('moo SMM a' + GetFileName(e), true);
				// 	AddMessage('Creating patch file');
				// end;

				// // add the required masters to the patch file
				// AddRequiredElementMasters(e, patchFile, false);
				// // copy the current record as a new record to the patch file
				// newCraftingRecipe := wbCopyElementToFile(e, patchFile, false, true);
				// // newCraftingRecipe := getOverrideForElem(e, patchFile); //TEST this should perform the 2 above function calls of adding master and copying the record

				// AddMessage(GetElementEditValues(keywordRecord, 'EDID') + IntToHex(FormID(keywordRecord), 8));
				// add keyword to list
				// mainFileKeywords.Add(keywordRecord);
				// patchFileKeywords.Add(newCraftingRecipe);
				GetKeywordIndex(keywordRecord);





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