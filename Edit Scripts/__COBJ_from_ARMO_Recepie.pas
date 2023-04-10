{
	Purpose: Create COBJ records (crafting recepie) from ARMO records
	Game: The Elder Scrolls V: Skyrim
	Author: fireundubh <fireundubh@gmail.com> (original), MustDy <MustDy@yandex.ru> (editor)
	Version: 2.0
}

unit UserScript;

var
  baserecord: IInterface;
  
//============================================================================
function Initialize: integer;
	begin
		baserecord := RecordByFormID(FileByIndex(0), $000A30C3, true);
		if not Assigned(baserecord) then begin
			AddMessage('Can not find base record');
			Result := 1;
			Exit;
		end;
	end;

//============================================================================
function Process(e: IInterface): integer;
	var
		r, kwda: IInterface;
		formid: Cardinal;
		itemformid: Cardinal;
		keyword, bnam, cnam: string;
		i, iMaterials, additionalMaterials, AdditionalStrips: integer;
	
	begin
	
		//script will cycle trough all given records (which were highlighted before 'apply script')
	
		if Signature(e) <> 'ARMO' then
			Exit;
			
		iMaterials := 0;
		
		//Checking for material and defining relevant material to craft
		//Check is based on the aromor piece keywords
		
		kwda := ElementBySignature(e, 'KWDA');
		for i := 0 to ElementCount(kwda) - 1 do begin
			keyword := lowercase(GetEditValue(ElementByIndex(kwda, i)));
			
			//If one of the material keywords was found, saves the material type and crafting place (tannig rack for leather, forge for other)
			
			if (pos('daedric', keyword) > 0) then begin
				iMaterials := iMaterials + 10;
				cnam := 'IngotEbony "Ebony Ingot" [MISC:0005AD9D]';
				bnam := 'CraftingSmithingForge [KYWD:00088105]';
			end;
			
			if (pos('ebony', keyword) > 0) then begin
				iMaterials := iMaterials + 10;
				cnam := 'IngotEbony "Ebony Ingot" [MISC:0005AD9D]';
				bnam := 'CraftingSmithingForge [KYWD:00088105]';
			end;
			
			if (pos('dragonplate', keyword) > 0) then begin
				iMaterials := iMaterials + 10;
				cnam := 'DragonBone "Dragon Bone" [MISC:0003ADA4]';
				bnam := 'CraftingSmithingForge [KYWD:00088105]';
			end;
			
			if (pos('dragonscale', keyword) > 0) then begin
				iMaterials := iMaterials + 10;
				cnam := 'DragonScales "Dragon Scales" [MISC:0003ADA3]';
				bnam := 'CraftingSmithingForge [KYWD:00088105]';
			end;
			
			if (pos('dwarven', keyword) > 0) then begin
				iMaterials := iMaterials + 10;
				cnam := 'IngotDwarven "Dwarven Metal Ingot" [MISC:000DB8A2]';
				bnam := 'CraftingSmithingForge [KYWD:00088105]';
			end;
			
			if (pos('elven', keyword) > 0) then begin
				iMaterials := iMaterials + 10;
				cnam := 'IngotMoonstone "Moonstone Ingot" [MISC:0005AD9F]';
				bnam := 'CraftingSmithingForge [KYWD:00088105]';
			end;
			
			if (pos('glass', keyword) > 0) then begin
				iMaterials := iMaterials + 10;
				cnam := 'IngotMalachite "Malachite Ingot" [MISC:0005ADA1]';
				bnam := 'CraftingSmithingForge [KYWD:00088105]';
			end;
			
			if (pos('iron', keyword) > 0) then begin
				iMaterials := iMaterials + 10;
				cnam := 'IngotIron "Iron Ingot" [MISC:0005ACE4]';
				bnam := 'CraftingSmithingForge [KYWD:00088105]';
			end;
			
			if (pos('leather', keyword) > 0) then begin
				iMaterials := iMaterials + 10;
				cnam := 'Leather01 "Leather" [MISC:000DB5D2]';
				bnam := 'CraftingTanningRack [KYWD:0007866A]';
			end;
			
			if (pos('hide', keyword) > 0) then begin
				iMaterials := iMaterials + 10;
				cnam := 'Leather01 "Leather" [MISC:000DB5D2]';
				bnam := 'CraftingTanningRack [KYWD:0007866A]';
			end;
			
			if (pos('orcish', keyword) > 0) then begin
				iMaterials := iMaterials + 10;
				cnam := 'IngotOrichalcum "Orichalcum Ingot" [MISC:0005AD99]';
				bnam := 'CraftingSmithingForge [KYWD:00088105]';
			end;
			
			if (pos('stalhrim', keyword) > 0) then begin
				iMaterials := iMaterials + 10;
				cnam := 'DLC2OreStalhrim "Stalhrim" [MISC:0302B06B]';
				bnam := 'CraftingSmithingForge [KYWD:00088105]';
			end;
			
			if (pos('nordic', keyword) > 0) then begin
				iMaterials := iMaterials + 10;
				cnam := 'IngotQuicksilver "Quicksilver Ingot" [MISC:0005ADA0]';
				bnam := 'CraftingSmithingForge [KYWD:00088105]';
			end;
			
			if (pos('steel', keyword) > 0) or (pos('advanced', keyword) > 0) then begin
				iMaterials := iMaterials + 10;
				cnam := 'IngotSteel "Steel Ingot" [MISC:0005ACE5]';
				bnam := 'CraftingSmithingForge [KYWD:00088105]';
			end;
			
			//start of adding additional quantity of materials for different type of armor. Could be modified/omitted if you do not need it
			
			if (pos('heavy', keyword) > 0) then begin
				additionalMaterials := additionalMaterials + 2;
			end;
			
			if (pos('light', keyword) > 0) then begin
				additionalMaterials := additionalMaterials + 1;
			end;
			
			if (pos('cuirass', keyword) > 0) then begin
				additionalMaterials := additionalMaterials + 3;
			end;
			
			if (pos('helmet', keyword) > 0) then begin
				additionalMaterials := additionalMaterials + 1;
			end;
			
			if (pos('gauntlets', keyword) > 0) then begin
				additionalMaterials := additionalMaterials + 2;
			end;
			
			if (pos('boots', keyword) > 0) then begin
				additionalMaterials := additionalMaterials + 2;
			end;
			
			//end of adding additional quantity of materials based on armor type
			
		end;
		
		//if no materials were found and script could not decide which bench to use, defaulting to tanning rack
		
		if (iMaterials = 0) then begin
			bnam := 'CraftingTanningRack [KYWD:0007866A]';
		end;
		
		//Making sure that the actual number of materials will be at least 1 in case of improper keywording
		
		if (additionalMaterials < 1) then begin
			additionalMaterials := additionalMaterials + 1;
			AddMessage(GetElementEditValues(e, 'EDID') + ': No additional materials were added, quantity defaulted to 1. PLease check armor Type type keywords');
		end;
		
		AddMessage(IntToStr(iMaterials) + ' material(s) found');
		
		//Creating new COBJ record
		
		r := wbCopyElementToFile(baserecord, GetFile(e), true, true);
		if not Assigned(r) then begin
			AddMessage('Can''t copy base record as new');
			Result := 1;
			Exit;
		end;
		
		//Setting output as original armor piece
		
		SetElementEditValues(r, 'CNAM', GetElementEditValues(e, 'Record Header\FormID'));

		//Defining record name (Recepie+EditorID of the original armor piece). Feel free to modify if you need another naming convention
		
		SetElementEditValues(r, 'EDID', 'Recipe' + GetElementEditValues(e, 'EDID'));
		
		//Adding COBJ values
		
		SetElementEditValues(r, 'COCT', 1);
		SetElementEditValues(r, 'DESC', GetElementEditValues(e, 'FULL'));
		SetElementEditValues(r, 'Items\Item\CNTO\Count', additionalMaterials);
		SetElementEditValues(r, 'BNAM', bnam);
		SetElementEditValues(r, 'NAM1', 1);
		
		//Setting crafting material

		
		if (iMaterials > 0) then begin						
			SetElementEditValues(r, 'Items\Item\CNTO\Item', cnam);
			AddMessage(GetElementEditValues(e, 'EDID') + ': Success');
		end;
		
		//If no materials found previously, defaulting to steel ingot
		
		if (iMaterials = 0) then begin
			SetElementEditValues(r, 'Items\Item\CNTO\Item', 'IngotSteel "Steel Ingot" [MISC:0005ACE5]');
			AddMessage(GetElementEditValues(e, 'EDID') + ': Success. Material defaulted to Steel ingot as no item materials found - please check armor Material keywords');
		end;
		
	end;
	
end.
