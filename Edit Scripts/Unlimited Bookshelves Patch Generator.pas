{
	Script to generate the right object bounds as patch for Unlimited Bookshelves.
	This should forward changes from the last mod modifying the object.
}
unit GenUnlimBookshelvesPatch;
//uses mtefunctions;

const
	UnLimPluginName = 'UnlimitedBookshelves.esp'; // name of the unlimited bookshelves esp
	patchPluginName = 'UnlimitedBookshelvesPatch.esp'; // name of the patch plugin that will be generated
	UnoffialPatchName = 'Unofficial Skyrim Special Edition Patch.esp'; // name of the Unofficial Skyrim patch to find if some record bounds are not found within Unlimited Bookshelves
	recordTypes = 'ALCH,BOOK,KEYM,MISC,SCRL,WEAP,ARMO'; //record types in unlimited bookshelves that need patching (in other words, any items except torches)
var
	patchPlugin: IInterface; // the plugin of the patch
	referenceList: TStringList; //list of all the known models and the associated reference record
	
//===========================================

function GetPlugin(PluginName : String): IInterface;
//function to get the plugin by name
var
 i : integer;
begin
	for i := 1 to Pred(FileCount) do begin
		if (GetFileName(FileByIndex(i)) = PluginName) then begin
			Result := FileByIndex(i);
			Exit;
		end;
	end;
end;


//==========================================

function AddRecursiveMaster(aeFile: IInterface; masterFile: IInterface): Boolean;
var
	i : integer;
begin
	for i := 0 to Pred(MasterCount(masterFile)) do begin
		AddRecursiveMaster(aeFile,MasterByIndex(masterFile,i));
	end;
	AddMasterIfMissing(aeFile,GetFileName(masterFile));
	Result := true;
end;


//==========================================

function EditedBounds(MyRecord: IInterface): Boolean;
begin
	if (GetElementEditValues(myRecord,'OBND\X1') = '0') and (GetElementEditValues(myRecord,'OBND\Y1') = '0') and (GetElementEditValues(myRecord,'OBND\Z1') = '0') and (GetElementEditValues(myRecord,'OBND\X2') = '0') and (GetElementEditValues(myRecord,'OBND\Y2') = '0') and (GetElementEditValues(myRecord,'OBND\Z2') = '0') then begin
		Result := false;
	end
	else begin
		Result := true;
	end;
end;

//==========================================

function Initialize: integer;
var
	RecTypesList : TStringList;
	LookupPlugins : TStringList;
	PatchedPlugins : TStringList;
	i, j, k, index, knownBoundscount: integer;
	f, g, item, itemovr, UnLimPlugin, PatchedRecord: IInterface;
	currentPluginName, modelString : String;
begin
	//create list of plugins
	//go through the plugin and its masters (in reverse order)
	//if there is any model in there which has not been accounted for in the reference list
	//and its dimensions aren't 0
	//add it to the list
	
	RecTypesList := TStringList.Create;
	RecTypesList.Delimiter := ',';
	RecTypesList.StrictDelimiter := True;
	RecTypesList.DelimitedText := recordTypes; // made a list of all record types for which we could have changed the object bounds.
	
	PatchedPlugins := TStringList.Create;
	
	//===========================================================================
	AddMessage('Pre-process check and setup');
	
	UnLimPlugin := GetPlugin(UnLimPluginName); // this is the plugin of Unlimited Bookshelves
	patchPlugin := GetPlugin(patchPluginName); //this is or will be the patch plugin
	
	if not Assigned(UnLimPlugin) then begin // just in case we don't have Unlimited Bookshelves loaded and someone still tries to use the script.
		MessageDlg('UnlimitedBookshelves.esp not loaded', mtInformation, [mbOk], 0);
		Exit;
	end;
	
	if not Assigned(patchPlugin) then begin //if the plugin patch does not exist yet, create it
		patchPlugin := AddNewFileName(patchPluginName);
	end
	else begin //if it does exist already, remove any previously existing records in it
		for i := Pred(RecordCount(patchPlugin)) downto 0 do begin
			Remove(RecordByIndex(patchPlugin,i));
		end;
		SortMasters(patchPlugin);
		CleanMasters(patchPlugin);
		AddMessage('Removed all records from previous patch');
	end;
	
	if not Assigned(patchPlugin) then begin
		MessageDlg('Cannot create plugin patch', mtInformation, [mbOk], 0);
		Exit;
	end;

	AddMasterIfMissing(patchPlugin,GetFileName(UnLimPlugin));
	
	
	//==========================================================================
	AddMessage('Generating model reference list');
	
	//creating a list of all plugins to look through for reference models
	LookupPlugins := TStringList.Create;
	LookupPlugins.Delimiter :='|';
	LookupPlugins.StrictDelimiter := True;
	//add Unlimited Bookshelves itself
	LookupPlugins.AddObject(UnLimPluginName,UnLimPlugin);
	//add the masters in reverse order
	for i := MasterCount(UnLimPlugin) downto 1 do begin
		LookupPlugins.AddObject(GetFileName(MasterByIndex(UnLimPlugin,i-1)),MasterByIndex(UnLimPlugin,i-1));
	end;
	
	referenceList := TStringList.Create;
	
	//creating the reference list which maps the model string to an example record
	//go through the plugin and its masters
	for i := 0 to Pred(LookupPlugins.Count) do begin
		f := ObjectToElement(LookupPlugins.Objects[i]);
		AddMessage('Looking in ' + GetFileName(f));
		for i := 0 to (Pred(RecTypesList.Count)-1) do begin // for every item type in the plugin (except armour, the last one)
			g := GroupBySignature(f,RecTypesList[i]); // get all the records in this group
			for j := 0 to Pred(ElementCount(g)) do begin // for every record
				item := ElementByIndex(g, j);
				modelString := GetElementEditValues(item,'Model\MODL');
				if not (modelString = '') then begin
					index := referenceList.IndexOf(modelString); //if model not in there, proceed
					if (index = -1) then begin
					//if the model bounds are not all 0, add it as a reference
					//if (GetElementEditValues(item,'Model\MODL') = '') then AddMessage('Model Bounds are 0!');
					if EditedBounds(item) then
						referenceList.AddObject(modelString,item);
					end;
				end;
			end;
		end;
		//do the same for armour, but check in a different editor location
		g:= GroupBySignature(f,RecTypesList[RecTypesList.Count-1]);
		for j := 0 to Pred(ElementCount(g)) do begin // for every record
			item := ElementByIndex(g, j);
			{ if (EditorID(item) = 'ClothesWarlockRobes') then begin }
				{ AddMessage('The model is in there: ' + GetElementEditValues(item,'Male world model\MOD2')); }
				{ AddMessage('Its index: ' + inttostr(index)); }
				{ AddMessage('its model index' + inttostr(referenceList.IndexOf('Clothes\Warlock\WarlockRobesGND.nif'))) }
			{ end; }
			modelString := GetElementEditValues(item,'Male world model\MOD2');
			if not (modelString = '') then begin
				index := referenceList.IndexOf(modelString); //check whether the mesh is already listed
				if (index = -1) then begin
					//if the model bounds are not 0, add it as a reference
					if EditedBounds(item) then
						referenceList.AddObject(modelString,item);
				end;
			end;
		end;
	end;
	
	//=========================================================================
	//patch all records which use the same models and have 0,0,0,0,0,0 object bounds.
	//for all plugins with a higher index than the Unlimited Bookshelves esp: - just add them all, keep track of which should actually be added
	AddMessage('Patching records...');
	
	{ for i := 0 to Pred(FileCount()) do begin }
		{ f := fileByLoadOrder(i); }
		{ if not (GetFileName(f) = patchPluginName) then begin }
		{ AddMasterIfMissing(patchPlugin,GetFileName(f)); }
		{ end; }
	{ end; }
	
	PatchedPlugins := TStringList.Create;
	PatchedPlugins.Delimiter := '|';
	PatchedPlugins.StrictDelimiter := True;//sorting this didn't seem to have any influence on program time
	PatchedPlugins.Add(UnLimPluginName);
	
	referenceList.Sorted := True;//makes the program slightly faster, in testing consistently 15 vs 16 seconds - before or after reference list creation doesn't seem to matter
	
	for i := GetLoadOrder(UnLimPlugin)+1 to Pred(FileCount()-1) do begin
		f := FileByLoadOrder(i);
		CurrentPluginName := GetFileName(f);
		if CurrentPluginName =  patchPluginName then Continue;
		AddMessage('Processing: ' + GetFileName(f));
		for i := 0 to (Pred(RecTypesList.Count)-1) do begin//for every group (except armour, which has a different location to look into for models)
			g := GroupBySignature(f,RecTypesList[i]);
			for j := 0 to Pred(ElementCount(g)) do begin // for every record
				item := ElementByIndex(g, j);
				//only do this if it is the winning override (i.e. the last edit of this record)
				if isWinningOverride(item) then begin
					index := referenceList.IndexOf(GetElementEditValues(item,'Model\MODL')); //check whether the mesh is listed
					if not (index = -1) then begin
						//if the model bounds are all 0, it's probably not intended to be changed this way, patch it
						if not EditedBounds(item) then begin
							//keep track of for which plugins we patched records
							if (PatchedPlugins.IndexOf(CurrentPluginName) = -1) then begin
								if (AddRecursiveMaster(patchPlugin,f)) then PatchedPlugins.Add(CurrentPluginName);
							end;
							//copy as override
							PatchedRecord := wbCopyElementToFile(item, patchPlugin, False, True);
							//get the correct bounds and fix it
							ElementAssign(ElementByPath(PatchedRecord, 'OBND'), LowInteger, ElementByPath(ObjectToElement(referenceList.Objects[index]), 'OBND'), False);
						end;
					end;
				end;
			end;
		end;
		//now do the same for armour
		g := GroupBySignature(f,RecTypesList[Pred(RecTypesList.Count)]);
		for j := 0 to Pred(ElementCount(g)) do begin // for every record
			item := ElementByIndex(g, j);
			//only do this if it is the winning override (i.e. the last edit of this record)
			if isWinningOverride(item) then begin
				index := referenceList.IndexOf(GetElementEditValues(item,'Male world model\MOD2')); //check whether the mesh is listed
				if not (index = -1) then begin
					//if the model bounds are all 0, it's probably not intended to be changed this way, patch it
					if not EditedBounds(item) then begin
						//keep track of for which plugins we patched records
						if (PatchedPlugins.IndexOf(CurrentPluginName) = -1) then begin
							if (AddRecursiveMaster(patchPlugin,f)) then begin
							PatchedPlugins.Add(CurrentPluginName);
							end;
						end;
						//copy as override
						PatchedRecord := wbCopyElementToFile(item, patchPlugin, False, True);
						//get the correct bounds and fix it
						ElementAssign(ElementByPath(PatchedRecord, 'OBND'), LowInteger, ElementByPath(ObjectToElement(referenceList.Objects[index]), 'OBND'), False);
					end;
				end;
			end;
		end;
		CleanMasters(patchPlugin)
	end
	
	AddMessage('Done patching records, correcting masters');
	
	SortMasters(patchPlugin);
	CleanMasters(patchPlugin);
	
	for i := 0 to Pred(PatchedPlugins.Count) do begin
		AddMasterIfMissing(patchPlugin,PatchedPlugins[i]);
	end;
	
	SortMasters(patchPlugin);
	
	Result := 1;
	
	RecTypesList.Free;
	LookupPlugins.Free;
	PatchedPlugins.Free;
	
end;
//=========================================================================================


function Finalize: integer;
begin
	Result := 0;
end;

end.
