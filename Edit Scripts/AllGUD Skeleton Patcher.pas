{
  AllGUD Skeleton Patcher
}
unit AllGUDnifPatcher;

const
	PreferencesPath = 'AllGUD\Skeleton Preferences.txt';
	indexSourcePath = 0;
	indexDestPath = 1;

var
	DataPathSkeletons, SavDirPath, DestinationPath, SourcePath: String;
	slPreferences: TStringList;
    SourcePathInput, DestinationPathInput: TEdit;
	

procedure PickPath(Sender: TObject);
var
	s: string;
	iIndex: integer;
begin
	if Sender = SourcePathInput then begin
		iIndex := indexSourcePath;
	s := slPreferences[iIndex];
	s := SelectDirectory('Select folder to patch skeletons for', '', s, '');
	end
	else begin
		iIndex := indexDestPath;
	s := slPreferences[iIndex];
	s := SelectDirectory('Select folder for patched skeletons', '', s, '');
	end;
	
	if s <> '' then begin
		if iIndex = indexSourcePath then begin
			SourcePathInput.Text := s + '\';
		end else begin
			if pos('\meshes', lowercase(s)) = 0 then s := s + '\meshes\actors\character'
			else if pos('\actors', lowercase(s)) = 0 then s := s + '\actors\character'
			else if pos('\character', lowercase(s)) = 0 then s := s + '\character';
			DestinationPathInput.Text := s + '\';
		end;
		
		slPreferences[iIndex] := s + '\';
		slPreferences.SaveToFile(SavDirPath);
	end;
 end;
 
procedure ResetDataPath;
begin
	SourcePathInput.Text := DataPathSkeletons;
	slPreferences[indexSourcePath] := DataPathSkeletons;
	slPreferences.SaveToFile(SavDirPath);
end;



procedure PatchSkeleton(asFile: string);
var
	Nif: TwbNifFile;
	Block, NodeBlock, ChildBlock: TwbNifBlock;
	ref, HeaderStrings, children: TdfElement;
	i, j, iNodesFound: integer;
	bCheckedForHuman: Boolean;
	bFoundSword, bFoundDagger, bFoundAxe, bFoundMace, bFoundBack, bFoundBow, bWeaponFound: Boolean;
	bFoundLeftSword, bFoundLeftDagger, bFoundLeftAxe, bFoundLeftMace, bFoundLeftStaff, bFoundStaff, bFoundShield: Boolean;
	sString: String;
begin	
	ForceDirectories(DestinationPath + ExtractFilePath(asFile));
	
	Nif := TwbNifFile.Create;
	Nif.LoadFromFile(SourcePath + asFile);
	HeaderStrings := Nif.Header.Elements['Strings'];
	
//Check if Skeleton has been patched before.
	iNodesFound := 0;
	for i := 0 to Pred(HeaderStrings.count) do begin
		//Check in reverse order because they'll be at the end if they are.
		//Should I also check for WeaponX nodes here to see if skeleton is valid? Script is pretty fast anyways, don't really need to bother.
		sString := HeaderStrings[Pred(HeaderStrings.count)-i].EditValue;
		if sString = 'WeaponSwordArmor' then begin
			bFoundSword := true;
			Inc(iNodesFound);
		end
		else if sString = 'WeaponDaggerArmor' then begin
			bFoundDagger := true;
			Inc(iNodesFound);
		end
		else if sString = 'WeaponAxeArmor' then begin
			bFoundAxe := true;
			Inc(iNodesFound);
		end
		else if sString = 'WeaponMaceArmor' then begin
			bFoundMace := true;
			Inc(iNodesFound);
		end
		else if sString = 'WeaponBackArmor' then begin
			bFoundBack := true;
			Inc(iNodesFound);
		end
		else if sString = 'WeaponBowArmor' then begin
			bFoundBow := true;
			Inc(iNodesFound);
		end;
		if iNodesFound = 6 then break;
	end;
	if iNodesFound = 6 then begin
		//Already Patched
		addmessage(#9'This Skeleton already has the required AllGUD Armor Nodes');
		Nif.Free;
		exit;
	end else begin
		iNodesFound := 0;
		for i := 0 to Pred(HeaderStrings.count) do begin
			//Check in reverse order because they'll be at the end if they are.
			//Should I also check for WeaponX nodes here to see if skeleton is valid? Script is pretty fast anyways, don't really need to bother.
			sString := HeaderStrings[Pred(HeaderStrings.count)-i].EditValue;
			if sString = 'WeaponSwordLeft' then begin
				bFoundLeftSword := true;
				Inc(iNodesFound);
			end
			else if sString = 'WeaponDaggerLeft' then begin
				bFoundLeftDagger := true;
				Inc(iNodesFound);
			end
			else if sString = 'WeaponAxeLeft' then begin
				bFoundLeftAxe := true;
				Inc(iNodesFound);
			end
			else if sString = 'WeaponMaceLeft' then begin
				bFoundLeftMace := true;
				Inc(iNodesFound);
			end
			else if sString = 'WeaponStaff' then begin
				bFoundStaff := true;
				Inc(iNodesFound);
			end
			else if sString = 'WeaponStaffLeft' then begin
				bFoundLeftStaff := true;
				Inc(iNodesFound);
			end
			else if sString = 'ShieldBack' then begin
				bFoundShield := true;
				Inc(iNodesFound);
			end;
			if iNodesFound = 7 then break;
		end;
		If not bFoundLeftSword then addmessage('WARNING: This skeleton does not have a WeaponSwordLeft node');
		If not bFoundLeftDagger then addmessage('WARNING: This skeleton does not have a WeaponDaggerLeft node');
		If not bFoundLeftAxe then addmessage('WARNING: This skeleton does not have a WeaponAxeLeft node');
		If not bFoundLeftMace then addmessage('WARNING: This skeleton does not have a WeaponMaceLeft node');
		If not bFoundStaff then addmessage('WARNING: This skeleton does not have a WeaponStaff node');
		If not bFoundLeftStaff then addmessage('WARNING: This skeleton does not have a WeaponStaffLeft node');
		If not bFoundShield then addmessage('WARNING: This skeleton does not have a ShieldBack node');
		
	end;

	//Count any that've been found, in case there was a botched job that only patched some.
	iNodesFound := 0;
	if bFoundSword then begin
		addMessage(#9'Mesh contained WeaponSwordArmor');
		inc(iNodesFound);
	end;
	if bFoundDagger then begin
		addMessage(#9'Mesh contained WeaponDaggerArmor');
		inc(iNodesFound);
	end;
	if bFoundAxe then begin
		addMessage(#9'Mesh contained WeaponAxeArmor');
		inc(iNodesFound);
	end;
	if bFoundMace then begin
		addMessage(#9'Mesh contained WeaponMaceArmor');
		inc(iNodesFound);
	end;
	if bFoundBack then begin
		addMessage(#9'Mesh contained WeaponBackArmor');
		inc(iNodesFound);
	end;
	if bFoundBow then begin
		addMessage(#9'Mesh contained WeaponBowArmor');
		inc(iNodesFound);
	end;
	
	Nif.Header.Elements['Strings'].count := Nif.Header.Elements['Strings'].count + 6 - iNodesFound;
	
//Check the blocks to find the Weapon nodes
	for i := 0 to Pred(Nif.BlocksCount) do begin
		if(iNodesFound = 6) then break;
		Block := Nif.Blocks[i];
		if(Block.BlockType = 'NiNode') then begin
			//Check for Human species on First NiNode
			//Might be too specific?
			if not bCheckedForHuman then begin
				for j := 0 to Pred(Block.RefsCount) do begin
					ref := Block.Refs[j];
					NodeBlock := TwbNifBlock(ref.LinksTo);
					if Assigned(NodeBlock) then begin
						if(NodeBlock.BlockType = 'NiStringExtraData') then begin
							if(NodeBlock.EditValues['Name'] = 'species') then begin
								if(NodeBlock.EditValues['Data'] = 'Human') then begin
									bCheckedForHuman := true;
								end
								else break;
							end;
						end;
					end;
				end;
				if not bCheckedForHuman then begin
					Nif.Free;
					exit; //If the first NiNode doesn't have human species then skip it.
				end;
			end;
			
			//Check if it has children
			children := Block.Elements['Children'];
			if (children.Count = 0) then continue;
			for j := 0 to Pred(children.Count) do begin
				bWeaponFound := false;
				ChildBlock := TwbNifBlock(children[j].LinksTo);
				if Assigned(ChildBlock) then begin
					//Check if it's a WeaponX Node
					if (pos('Weapon', ChildBlock.EditValues['Name']) = 1) then begin
						if not bFoundSword then begin
							if(ChildBlock.EditValues['Name'] = 'WeaponSword') then begin
								addmessage(#9'Detected ' + ChildBlock.EditValues['Name']);
								bFoundSword := true;
								bWeaponFound := true;
							end;
						end;
						if not bFoundDagger then begin
							if(ChildBlock.EditValues['Name'] = 'WeaponDagger') then begin
								addmessage(#9'Detected ' + ChildBlock.EditValues['Name']);
								bFoundDagger := true;
								bWeaponFound := true;
							end;
						end;
						if not bFoundAxe then begin
							if(ChildBlock.EditValues['Name'] = 'WeaponAxe') then begin
								addmessage(#9'Detected ' + ChildBlock.EditValues['Name']);
								bFoundAxe := true;
								bWeaponFound := true;
							end;
						end;
						if not bFoundMace then begin
							if(ChildBlock.EditValues['Name'] = 'WeaponMace') then begin
								addmessage(#9'Detected ' + ChildBlock.EditValues['Name']);
								bFoundMace := true;
								bWeaponFound := true;
							end;
						end;
						if not bFoundBack then begin
							if(ChildBlock.EditValues['Name'] = 'WeaponBack') then begin
								addmessage(#9'Detected ' + ChildBlock.EditValues['Name']);
								bFoundBack := true;
								bWeaponFound := true;
							end;
						end;
						if not bFoundBow then begin
							if(ChildBlock.EditValues['Name'] = 'WeaponBow') then begin
								addmessage(#9'Detected ' + ChildBlock.EditValues['Name']);
								bFoundBow := true;
								bWeaponFound := true;
							end;
						end;
						
						if bWeaponFound then begin
							//Brief attempt at setting new node to child of the weapon node didn't work with XPMSE
							NodeBlock := Nif.CopyBlock(ChildBlock.Index);
                            NodeBlock.EditValues['Name'] := ChildBlock.EditValues['Name'] + 'Armor';
                            ChildBlock := children.add;
                            ChildBlock.nativevalue := NodeBlock.index;
							Inc(iNodesFound);
						end;
					end;
				end;
			end;
		end;
	end;
	
	if (iNodesFound = 6) then begin
		addMessage(#9'All required Weapon Nodes patched by this Script have been found. Saving Changes.');
		Nif.saveToFile(DestinationPath+asFile);
		addMessage(#9'Changes have been saved to: '+ DestinationPath+asFile);
	end
	else begin
		addmessage(#9'Unable to locate the required default Weapon nodes or AllGUD nodes');
	end;
	Nif.Free;
end;

procedure StartSkeletonPatch(asSourceFolder: string);
var
    TDirectory: TDirectory;
	SourceFiles: TStringDynArray;
	i, fileCount: integer;
	sFilePath: string;
begin
	addmessage(#13#10'Scanning for .nif files in ' + asSourceFolder);
	addmessage('Outputting files to ' + DestinationPath);
	SourceFiles := TDirectory.GetFiles(asSourceFolder, '*.nif', soAllDirectories);
	fileCount := Length(SourceFiles);
	addmessage(inttostr(fileCount) + ' models found in the Source Directory');
	
	if fileCount > 0 then begin
		for i := 0 to Pred(fileCount) do begin
			sFilePath := SourceFiles[i];
			//if(pos('character\', lowercase(sFilePath)) = 0) then continue;
			if(pos('skeleton', lowercase(sFilePath)) = 0) then continue; //Skip facial features and the like
			addMessage(#13#10'Patching Skeleton: ' + sFilePath);
			PatchSkeleton(copy(sFilePath,Length(asSourceFolder)+1,Length(sFilePath)));
		end;
	end
	else begin
		addmessage('No Skeletons found, make sure you''ve selected the correct closet. I mean, Directory.');
	end;
end;

// Init
function Initialize: Integer;
var
	pixelRatio: Single;
	doPatch: Boolean;
    window: TForm;
	gbFolder, gbOutputFolder: TGroupBox;
	UseageInfo, OutputInfo: TLabel;
    start, pathreset: TButton;
begin

	DataPathSkeletons := DataPath + 'meshes\actors\character\';
	SavDirPath := ScriptsPath + PreferencesPath;
	doPatch := True;
	
	slPreferences := TStringList.Create;
	if FileExists(SavDirPath) then begin
		slPreferences.LoadFromFile(SavDirPath);
	end
	else begin
		ForceDirectories(ExtractFilePath(SavDirPath));
		//Declare new paths
		slPreferences.Add(DataPathSkeletons);
		slPreferences.Add('');
	end;
	
	//Trim to size
	while slPreferences.Count < 2 do
	slPreferences.Add('');
	while slPreferences.Count > 2 do
	slPreferences.Delete(slPreferences.Count-1);
	
	pixelRatio := Screen.PixelsPerInch/96;
	
    window := TForm.Create(nil);
    try
		window.Caption := 'AllGUD Skeleton Patcher';
		window.Width := 512*pixelRatio;
		window.Height := 270*pixelRatio;
		window.Position := poScreenCenter;
		window.BorderStyle := bsDialog;
		
		gbFolder := TGroupBox.Create(window);
		gbFolder.Parent := window;
		gbFolder.Top := 8*pixelRatio;
		gbFolder.Left := 8*pixelRatio;
		gbFolder.ClientHeight := 104*pixelRatio;
		gbFolder.ClientWidth := 492*pixelRatio;
		gbFolder.Caption := 'Skeleton Folder';
		gbFolder.Font.Size := 12;
		
		SourcePathInput := TEdit.Create(window);
		SourcePathInput.Parent := gbFolder;
		SourcePathInput.Top := 22*pixelRatio;
		SourcePathInput.Left := 8*pixelRatio;
		SourcePathInput.Width := 400*pixelRatio;
		SourcePathInput.Caption := slPreferences[indexSourcePath];
		SourcePathInput.Font.Size := 8;
		SourcePathInput.Hint :=
			'Select Input Folder';
		SourcePathInput.ShowHint := true;
		SourcePathInput.OnClick := PickPath;
		
		pathreset := TButton.Create(window);
		pathreset.Parent := gbFolder;
		pathreset.Top := 20*pixelRatio;
		pathreset.Left := 411*pixelRatio;
		pathreset.Caption := 'Reset';
		pathreset.Font.Size := 8;
		pathreset.OnClick := ResetDataPath;
		pathreset.Hint := 'Set to Data\meshes\actors\character\';
		pathreset.ShowHint := true;
		
		UseageInfo := TLabel.Create(window);
		UseageInfo.Parent := gbFolder;
		UseageInfo.Top := 46*pixelRatio;
		UseageInfo.Left := 12*pixelRatio;
		UseageInfo.Caption := 
			'Patches Human skeletons that have all six WeaponX Nodes.'#13#10
			'  AllGUD''s WeaponXArmor nodes will be added and the file will be overwritten.'#13#10
			'Staff, Shield-on-Back, and Left-hand nodes are not added. Most skeleton mods have these.'#13#10
			#9#9#9'      No changes are made to existing nodes.';
		UseageInfo.Font.Size := 8;
		
		gbOutputFolder := TGroupBox.Create(window);
		gbOutputFolder.Parent := window;
		gbOutputFolder.Top := 116*pixelRatio;
		gbOutputFolder.Left := 8*pixelRatio;
		gbOutputFolder.ClientHeight := 76*pixelRatio;
		gbOutputFolder.ClientWidth := 492*pixelRatio;
		gbOutputFolder.Caption := 'Output Skeleton Folder';
		gbOutputFolder.Font.Size := 12;
		
		OutputInfo := TLabel.Create(window);
		OutputInfo.Parent := gbOutputFolder;
		OutputInfo.Top := 46*pixelRatio;
		OutputInfo.Left := 12*pixelRatio;
		OutputInfo.Caption := 
			'Output path MUST end with ''\meshes\actors\character\'' if you are using default Input.'#13#10
			'  If weapons are under your feet, use Directory-Selection Dialog Box instead of copy-pasting.';
		OutputInfo.Font.Size := 8;

		DestinationPathInput := TEdit.Create(window);
		DestinationPathInput.Parent := gbOutputFolder;
		DestinationPathInput.Top := 22*pixelRatio;
		DestinationPathInput.Left := 8*pixelRatio;
		DestinationPathInput.Width := 400*pixelRatio;
		DestinationPathInput.Caption := slPreferences[indexDestPath];
		DestinationPathInput.Font.Size := 8;
		DestinationPathInput.Hint := 'Select Output Destination';
		DestinationPathInput.ShowHint := true;
		DestinationPathInput.OnClick := PickPath;
		
		start := TButton.Create(window);
		start.Parent := window;
		start.Top := 200*pixelRatio;
		start.Left := 216*pixelRatio; //window.Width / 2 - 40;
		start.Caption := 'Start';
		start.Font.Size := 10;
		start.ModalResult := mrOk;
	
        window.ActiveControl := start;
        if window.ShowModal = mrOk then begin
			SourcePath := IncludeTrailingBackslash(SourcePathInput.Text);
			DestinationPath := IncludeTrailingBackslash(DestinationPathInput.Text);
			if not ForceDirectories(DestinationPath) then begin
				AddMessage('ERROR: Output Directory is not a valid destination'#13#10);
				doPatch := False;
				//Not exiting to make sure memory is freed.
			end;
			if doPatch then begin
				if pos('\meshes\actors\character', lowercase(DestinationPath)) = 0 then
					AddMessage(#13#10#9'WARNING!'#13#10#9#9'The Output path does not end with the normal folders for character meshes.'#13#10#9'Please move patched skeleton files to the correct folder after the patcher has finished.'#13#10#9#9'Failure to do so will result in weapons appearing underneath the feet.'#13#10#9'YOU HAVE BEEN WARNED!');
			
				slPreferences[indexSourcePath] := SourcePath;
				slPreferences[indexDestPath] := DestinationPath;
				slPreferences.SaveToFile(SavDirPath);
				StartSkeletonPatch(SourcePathInput.Text);
				
				if pos('\meshes\actors\character', lowercase(DestinationPath)) = 0 then
					AddMessage(#13#10#9'WARNING!'#13#10#9#9'The Output path does not end with the normal folders for character meshes.'#13#10#9'Please move patched skeleton files to the correct folder after the patcher has finished.'#13#10#9#9'Failure to do so will result in weapons appearing underneath the feet.'#13#10#9'YOU HAVE BEEN WARNED!');
			end;
        end;

    finally
		slPreferences.Free;
		window.Free;
    end;

    Result := 1;
end;

end.
