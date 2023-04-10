{	README:
	This script scans for Back Center meshes and creates the other meshes off them.
	Male and females have different transforms
	Male and females have different node attachments
	
	Positions are hardcoded, so if you want to adjust them you must edit them in the script below.
	
	TODO:
		Make positions adjustable in the Window before hitting start.
}

unit AllGUDMeshGen;
	
// GLOBAL VARIABLES
const
	PreferencesPath = 'AllGUD\Items Preferences.txt';
	indexFolderPath = 0;
	//Male/Female	Back-Inner/Back-Outer/Front/FrontLeft	X/Y/Z translation or P/Yaw/R rotation
	indexMBIX = 1;
	indexMBIY = 2;
	indexMBIR = 3;
	indexMBOX = 4;
	indexMBOY = 5;
	indexMBOR = 6;
	indexMFX = 7;
	indexMFY = 8;
	indexMFZ = 9;
	indexMFYaw = 10;
	indexMFP = 11;
	indexMFR = 12;
	indexFBIX = 13;
	indexFBIY = 14;
	indexFBIR = 15;
	indexFBOX = 16;
	indexFBOY = 17;
	indexFBOR = 18;
	indexFFX = 19;
	indexFFY = 20;
	indexFFZ = 21;
	indexFFYaw = 22;
	indexFFP = 23;
	indexFFR = 24;
	indexFFLR = 25;
var
	slPreferences: TStringList;
	SourcePathInput: TEdit;
	SourcePathLength: Integer;
	SourcePath, SavPrefPath: String;
	bWindowCreated, bGreenLight: Boolean;
	
	tMBIX, tMBIY, tMBIR: TEdit;
	tMBOX, tMBOY, tMBOR: TEdit;
	tMFX, tMFY, tMFZ, tMFP, tMFYaw, tMFR: TEdit;
	fMBIX, fMBIY, fMBIR: single;
	fMBOX, fMBOY, fMBOR: single;
	fMFX, fMFY, fMFZ, fMFP, fMFYaw, fMFR: single;
	
	tFBIX, tFBIY, tFBIR: TEdit;
	tFBOX, tFBOY, tFBOR: TEdit;
	tFFX, tFFY, tFFZ, tFFP, tFFYaw, tFFR, tFFLR: TEdit;
	fFBIX, fFBIY, fFBIR: single;
	fFBOX, fFBOY, fFBOR: single;
	fFFX, fFFY, fFFZ, fFFP, fFFYaw, fFFR, fFFLR: single;

//	DIRECTORY SELECTION
procedure PickPath(Sender: TObject);
var
	s: string;
	iIndex: integer;
begin
	//Select Directory and save user's paths for future instances of the script.
	if Sender = SourcePathInput then begin
		iIndex := 0;
		s := slPreferences[iIndex];
		s := SelectDirectory('Select folder to generate meshes for', '', s, '');
	end;

	if s <> '' then begin
		SourcePathInput.Text := s + '\';
		slPreferences[iIndex] := s + '\';
		slPreferences.SaveToFile(SavPrefPath);
	end;
end;

procedure ResetMBI();
begin
	slPreferences[indexMBIX] := '4';
	slPreferences[indexMBIY] := '0.75';
	slPreferences[indexMBIR] := '17.5';
	if(bWindowCreated) then begin
		tMBIX.Text := slPreferences[indexMBIX];
		tMBIY.Text := slPreferences[indexMBIY];
		tMBIR.Text := slPreferences[indexMBIR];
	end;
end;
procedure ResetMBO();
begin
	slPreferences[indexMBOX] := '5.5';
	slPreferences[indexMBOY] := '2';
	slPreferences[indexMBOR] := '50';
	if(bWindowCreated) then begin
		tMBOX.Text := slPreferences[indexMBOX];
		tMBOY.Text := slPreferences[indexMBOY];
		tMBOR.Text := slPreferences[indexMBOR];
	end;
end;
procedure ResetMF();
begin
	slPreferences[indexMFX] := '4';
	slPreferences[indexMFY] := '7.5';
	slPreferences[indexMFZ] := '0';
	
	slPreferences[indexMFYaw] := '0';
	slPreferences[indexMFP] := '0';
	slPreferences[indexMFR] := '140';
	
	if(bWindowCreated) then begin
		tMFX.Text := slPreferences[indexMFX];
		tMFY.Text := slPreferences[indexMFY];
		tMFZ.Text := slPreferences[indexMFZ];
		tMFYaw.Text := slPreferences[indexMFYaw];
		tMFP.Text := slPreferences[indexMFP];
		tMFR.Text := slPreferences[indexMFR];
	end;
end;

procedure ResetFBI();
begin
	slPreferences[indexFBIX] := '1';
	slPreferences[indexFBIY] := '0.5';
	slPreferences[indexFBIR] := '25';
	if(bWindowCreated) then begin
		tFBIX.Text := slPreferences[indexFBIX];
		tFBIY.Text := slPreferences[indexFBIY];
		tFBIR.Text := slPreferences[indexFBIR];
	end;
end;
procedure ResetFBO();
begin
	slPreferences[indexFBOX] := '2';
	slPreferences[indexFBOY] := '1';
	slPreferences[indexFBOR] := '50';
	if(bWindowCreated) then begin
		tFBOX.Text := slPreferences[indexFBOX];
		tFBOY.Text := slPreferences[indexFBOY];
		tFBOR.Text := slPreferences[indexFBOR];
	end;
end;
procedure ResetFF();
begin
	slPreferences[indexFFX] := '1';
	slPreferences[indexFFY] := '-4.5';
	slPreferences[indexFFZ] := '2';
	
	slPreferences[indexFFYaw] := '-10';
	slPreferences[indexFFP] := '5';
	slPreferences[indexFFR] := '145';
	slPreferences[indexFFLR] := '135';
	if(bWindowCreated) then begin
		tFFX.Text := slPreferences[indexFFX];
		tFFY.Text := slPreferences[indexFFY];
		tFFZ.Text := slPreferences[indexFFZ];
		tFFYaw.Text := slPreferences[indexFFYaw];
		tFFP.Text := slPreferences[indexFFP];
		tFFR.Text := slPreferences[indexFFR];
		tFFLR.Text := slPreferences[indexFFLR];
	end;
end;

// FILE FUNCTIONS
procedure CopyFileKst(aSourcePath, aDestinationPath: string);
var
SourceF, DestF: TFileStream;
begin
	//Copy file from source
		//When used for this script, source exists is checked before running, but destination folder might not, due to lack of Write permission, so try it instead of just opening it.
		//I mean..things are gonna screw up if there's no write permission regardless. But I think I had one case during testing where I couldn't make folders but could still make files? it was weird.
	If not FileExists(aSourcePath) then begin
		AddMessage('Error: Unable to locate ' + aSourcePath);
	end else begin
		SourceF := TFileStream.Create(aSourcePath, fmOpenRead);
		try
			DestF := TFileStream.Create(aDestinationPath, fmCreate);
			DestF.CopyFrom(SourceF, SourceF.Size);
		except
			AddMessage(#9'Error: Unable to write to ' + aDestinationPath);
		end;
		SourceF.Free;
		DestF.Free;
	end;
end;

procedure GenerateMeshes(FileSrc: string; ListTriShape: TList; aNifSourceFile: TwbNifFile);
var
	i: integer;
	TransX, TransY, TransZ, RotY, RotP, RotR, RotRLeft: single;
	bFemaleMesh: boolean;
	SubFolder, BaseFile, NewPositionMesh, TemplatePath, TemplateFile: string;
	Block: TwbNifBlock;
	Nif: TwbNifFile;
	ListChoppingBlock: TList;
	Element: TdfElement;
begin
	//Get File & Subfolder paths to create the new files
	SubFolder := ExtractFilePath(FileSrc);
	BaseFile := ExtractFileName(FileSrc);
	BaseFile := StringReplace(BaseFile, '.nif', '', rfIgnoreCase);
	bFemaleMesh := (pos('Female', FileSrc) > 0);
	TemplateFile := SourcePath + FileSrc;
	
	for i := 0 to Pred(ListTriShape.Count) do begin
		Block := aNifSourceFile.Blocks[ListTriShape[i]];
		if not (
		(Block.NativeValues['Transform\Translation\X'] = 0) and
		(Block.NativeValues['Transform\Translation\Y'] = 0) and
		(Block.NativeValues['Transform\Translation\Z'] = 0)
		)then
			addmessage(#9'Warning: Translation is not Zero''d: '+Block.EditValues['Transform\Translation']+#13#10#9'Apply Transform to NiNode');
		if not (
		(RoundTo(Block.NativeValues['Transform\Rotation\[0]'], -4) = 1) and
		(RoundTo(Block.NativeValues['Transform\Rotation\[1]'], -4) = 0) and
		(RoundTo(Block.NativeValues['Transform\Rotation\[2]'], -4) = 0) and
		(RoundTo(Block.NativeValues['Transform\Rotation\[3]'], -4) = 0) and
		(RoundTo(Block.NativeValues['Transform\Rotation\[4]'], -4) = 1) and
		(RoundTo(Block.NativeValues['Transform\Rotation\[5]'], -4) = 0) and
		(RoundTo(Block.NativeValues['Transform\Rotation\[6]'], -4) = 0) and
		(RoundTo(Block.NativeValues['Transform\Rotation\[7]'], -4) = 0) and
		(RoundTo(Block.NativeValues['Transform\Rotation\[8]'], -4) = 1)
		)then
			addmessage(#9'Warning: Rotation is not Zero''d: '+Block.EditValues['Transform\Rotation']+#13#10#9'Apply Transform to NiNode');
	end;
	
//BCL BCR Positions
	if bFemaleMesh then begin
		TransX := fFBIX;
		TransY := fFBIY;
		RotR := fFBIR;
	end else begin
		TransX := fMBIX;
		TransY := fMBIY;
		RotR := fMBIR;
	end;
	
//MESH #1	-BCL
	//Create Mesh
	NewPositionMesh := SourcePath + StringReplace(FileSrc, 'BC', 'BCL', [0]);
	CopyFileKst(TemplateFile, NewPositionMesh);

	Nif := TwbNifFile.Create;
	Nif.LoadFromFile(NewPositionMesh);
	
	//Edit Blocks
	for i := 0 to Pred(ListTriShape.Count) do begin
		Block := Nif.Blocks[ListTriShape[i]];
		Block.NativeValues['Transform\Translation\X'] := -TransX;
		Block.NativeValues['Transform\Translation\Y'] := TransY;
		Block.EditValues['Transform\Rotation'] := '0.0 0.0 '+floattostr(-RotR);
	end;
	
	//Save and finish
	Nif.SaveToFile(NewPositionMesh);
	Nif.Free;
	
//MESH #2	-BCR
	//Create Mesh
	NewPositionMesh := SourcePath + StringReplace(FileSrc, 'BC', 'BCR', [0]);
	CopyFileKst(TemplateFile, NewPositionMesh);

	Nif := TwbNifFile.Create;
	Nif.LoadFromFile(NewPositionMesh);
	
	//Edit Blocks
	for i := 0 to Pred(ListTriShape.Count) do begin
		Block := Nif.Blocks[ListTriShape[i]];
		Block.NativeValues['Transform\Translation\X'] := TransX;
		Block.NativeValues['Transform\Translation\Y'] := TransY;
		Block.EditValues['Transform\Rotation'] := '0.0 0.0 '+floattostr(RotR);
	end;
	
	//Save and finish
	Nif.SaveToFile(NewPositionMesh);
	Nif.Free;
	
//BL BR Positions
	if bFemaleMesh then begin
		TransX := fFBOX;
		TransY := fFBOY;
		RotR := fFBOR;
	end else begin
		TransX := fMBOX;
		TransY := fMBOY;
		RotR := fMBOR;
	end;
	
//MESH #3	-BL
	//Create Mesh
	NewPositionMesh := SourcePath + StringReplace(FileSrc, 'BC', 'BL', [0]);
	CopyFileKst(TemplateFile, NewPositionMesh);

	Nif := TwbNifFile.Create;
	Nif.LoadFromFile(NewPositionMesh);
	
	//Edit Blocks
	for i := 0 to Pred(ListTriShape.Count) do begin
		Block := Nif.Blocks[ListTriShape[i]];
		Block.NativeValues['Transform\Translation\X'] := -TransX;
		Block.NativeValues['Transform\Translation\Y'] := TransY;
		Block.EditValues['Transform\Rotation'] := '0.0 0.0 '+floattostr(-RotR);
	end;
	
	//Save and finish
	Nif.SaveToFile(NewPositionMesh);
	Nif.Free;
	
//MESH #4	-BR
	//Create Mesh
	NewPositionMesh := SourcePath + StringReplace(FileSrc, 'BC', 'BR', [0]);
	CopyFileKst(TemplateFile, NewPositionMesh);

	Nif := TwbNifFile.Create;
	Nif.LoadFromFile(NewPositionMesh);
	
	//Edit Blocks
	for i := 0 to Pred(ListTriShape.Count) do begin
		Block := Nif.Blocks[ListTriShape[i]];
		Block.NativeValues['Transform\Translation\X'] := TransX;
		Block.NativeValues['Transform\Translation\Y'] := TransY;
		Block.EditValues['Transform\Rotation'] := '0.0 0.0 '+floattostr(RotR);
	end;
	
	//Save and finish
	Nif.SaveToFile(NewPositionMesh);
	Nif.Free;
	
//FL FR Positions
	if bFemaleMesh then begin
		TransX := fFFX;
		TransY := fFFY;
		TransZ := fFFZ;
		RotY := fFFYaw;
		RotP := fFFP;
		RotR := fFFR;
		RotRLeft := fFFLR	;	//Female idle stance has the left leg much further forward. Looks like 10deg less than Right leg to avoid potion strap going through the crotch.
		//Potions should have??? different positions due to the Y Rotation difference
		if (pos('Potion', FileSrc) > 0) then begin
			TransZ := 0;
			RotY := 0;
			RotP := 0;
		end;
	end else begin
		TransX := fMFX;
		TransY := fMFY;
		TransZ := fMFZ;
		RotY := fMFYaw;
		RotP := fMFP;
		RotR := fMFR;
		RotRLeft := fMFR;
		//Potions should have??? different positions due to the Y Rotation difference
		if (pos('Potion', FileSrc) > 0) then begin
			TransZ := 0;
			RotY := 0;
			RotP := 0;
		end;
	end;
	
//MESH #5	-FL
	//Create Mesh
	NewPositionMesh := SourcePath + StringReplace(FileSrc, 'BC', 'FL', [0]);
	CopyFileKst(TemplateFile, NewPositionMesh);

	Nif := TwbNifFile.Create;
	Nif.LoadFromFile(NewPositionMesh);
	
	//Edit Blocks
	for i := 0 to Pred(ListTriShape.Count) do begin
		Block := Nif.Blocks[ListTriShape[i]];
		Block.NativeValues['Transform\Translation\X'] := -TransX;
		Block.NativeValues['Transform\Translation\Y'] := TransY;
		Block.NativeValues['Transform\Translation\Z'] := TransZ;
		Block.EditValues['Transform\Rotation'] := floattostr(RotY) + ' ' + floattostr(-RotP) + ' ' +floattostr(-RotRLeft);
	end;
	
	//Save and finish
	Nif.SaveToFile(NewPositionMesh);
	Nif.Free;
	
//MESH #6	-FR
	//Create Mesh
	NewPositionMesh := SourcePath + StringReplace(FileSrc, 'BC', 'FR', [0]);
	CopyFileKst(TemplateFile, NewPositionMesh);

	Nif := TwbNifFile.Create;
	Nif.LoadFromFile(NewPositionMesh);
	
	//Edit Blocks
	for i := 0 to Pred(ListTriShape.Count) do begin
		Block := Nif.Blocks[ListTriShape[i]];
		Block.NativeValues['Transform\Translation\X'] := TransX;
		Block.NativeValues['Transform\Translation\Y'] := TransY;
		Block.NativeValues['Transform\Translation\Z'] := TransZ;
		Block.EditValues['Transform\Rotation'] := floattostr(RotY) + ' ' + floattostr(RotP) + ' ' +floattostr(RotR);
	end;
	
	//Save and finish
	Nif.SaveToFile(NewPositionMesh);
	Nif.Free;
end;

//	PROCESS MESHES AND DECIDE ACTION
procedure ProcessMesh(aSourceFile: string; aNif: TwbNifFile);
var
	ListTriShape: TList;
	//aNif: TwbNifFile;
	Prn: string;
	Element: TdfElement;
	Root, Block: TwbNifBlock;
	i: integer;
	bDoPatch, bSEMesh: Boolean;
begin
	//Iterate over all blocks in a nif file and identify Blocks of Interest(BSFadeNode, Prn, Scb, etc.)
	//TriShapes indexes are stored in the StringList
	ListTriShape := TList.Create;
	
	Root := aNif.Blocks[0];
	//Find NiStringExtraData
		
	//Find only the shapes that are the children of Root.
	Element := Root.Elements['Children'];
	for i := 0 to Pred(Element.Count) do begin
		Block := TwbNifBlock(Element[i].LinksTo);
		if Assigned(Block) then begin
			if (Block.BlockType = 'NiNode') then begin
				Tlist(ListTriShape).Add(Block.Index);
			end;
		end;
	end;
	
	GenerateMeshes(aSourceFile, ListTriShape, aNif);

	ListTriShape.Free;
end;

procedure ProcessMeshes;
var
	TDirectory: TDirectory;
	SourceFiles: TStringDynArray;
	i, j, fileCount, fileCountInResources: integer;
	FileSrc, FilePathInData, FilePathInSource, ResourceUsed: string;
	Nif: TwbNifFile;
begin
	SourceFiles := TDirectory.GetFiles(SourcePath, '*BC.nif', soAllDirectories);
	fileCount := Length(SourceFiles);

	SourcePathLength := Length(SourcePath);
	if fileCount > 0 then begin
		for i := 0 to Pred(fileCount) do begin
			FileSrc := SourceFiles[i];
			if (pos('Instruments', FileSrc) <= 0) then begin	//Skip instruments
				addmessage('Processing ' + FileSrc);
				if SameText(lowercase(ExtractFileExt(FileSrc)), '.nif') then begin
					FilePathInSource := copy(FileSrc,SourcePathLength+1,Length(FileSrc));
					
					Nif := TwbNifFile.Create;
					if FileExists(FileSrc) then begin //Folder to folder should not check inside archives to prevent contamination.
						Nif.LoadFromFile(FileSrc);
						ProcessMesh(FilePathInSource, Nif);
					end;
					Nif.Free
				end;
			end;
		end;
	end;
end;

function Initialize: Integer;
var
	i: Integer;
	pixelRatio: Single;
	window: TForm;
	gbSourceFolder: TGroupBox;
	lMBI, lMBO, lMFT, lMFR, lFBI, lFBO, lFFT, lFFR, lFFL: Tlabel;
	rbMBI, rbMBO, rbMF, rbFBI, rbFBO, rbFF: TButton;
	gbMale, gbMBI, gbMBO, gbMF, gbFemale, gbFBI, gbFBO, gbFF: TGroupBox;
	start: TButton;
begin
	bWindowCreated := False;
	bGreenLight := False;
	//Locate previously used paths.
	SavPrefPath := ScriptsPath + PreferencesPath;

	slPreferences := TStringList.Create;
	if FileExists(SavPrefPath) then begin
		slPreferences.LoadFromFile(SavPrefPath);
	end
	else begin
		//Declare new paths
		slPreferences.Add('');
		while slPreferences.Count < 26 do
			slPreferences.Add('');
		ResetMBI();
		ResetMBO();
		ResetMF();
		ResetFBI();
		ResetFBO();
		ResetFF();
	end;
	

	while slPreferences.Count < 26 do
		slPreferences.Add('');
	while slPreferences.Count > 26 do
		slPreferences.Delete(slPreferences.Count-1);
	
	pixelRatio := Screen.PixelsPerInch/96;
	
	window := TForm.Create(nil);
	try
		window.Caption := 'AllGUD Item Generator';
		window.Width := 512*pixelRatio;
		window.Height := 450*pixelRatio;
		window.Position := poScreenCenter;
		window.BorderStyle := bsDialog;
		window.scaled := true;
		
		//Input Folder selection
		gbSourceFolder := TGroupBox.Create(window);
		gbSourceFolder.Parent := window;
		gbSourceFolder.Top := 4*pixelRatio;
		gbSourceFolder.Left := 4*pixelRatio;
		gbSourceFolder.ClientHeight := 56*pixelRatio;
		gbSourceFolder.ClientWidth := 496*pixelRatio;
		gbSourceFolder.Caption := 'Input Folder';
		gbSourceFolder.Font.Size := 12;
		
		SourcePathInput := TEdit.Create(window);
		SourcePathInput.Parent := gbSourceFolder;
		SourcePathInput.Top := 22*pixelRatio;
		SourcePathInput.Left := 8*pixelRatio;
		SourcePathInput.Width := 480*pixelRatio;
		SourcePathInput.Caption := slPreferences[0];
		SourcePathInput.Font.Size := 8;
		SourcePathInput.Hint :=
			'Select Input Folder';
		SourcePathInput.ShowHint := true;
		SourcePathInput.OnClick := PickPath;
		
		//MALE ITEM POSITIONS
		gbMale := TGroupBox.Create(window);
		gbMale.Parent := window;
		gbMale.Top := 64*pixelRatio;
		gbMale.Left := 4*pixelRatio;
		gbMale.ClientHeight := 154*pixelRatio;
		gbMale.ClientWidth := 448*pixelRatio;
		gbMale.Caption := 'Male';
		gbMale.Font.Size := 12;
		
		//MBI
		gbMBI := TGroupBox.Create(window);
		gbMBI.Parent := gbMale;
		gbMBI.Top := 24*pixelRatio;
		gbMBI.Left := 8*pixelRatio;
		gbMBI.ClientHeight := 122*pixelRatio;
		gbMBI.ClientWidth := 106*pixelRatio;
		gbMBI.Caption := 'BCR && BCL';
		gbMBI.Font.Size := 8;
		
		lMBI := TLabel.Create(window);
		lMBI.Parent := gbMBI;
		lMBI.Top := 16*pixelRatio;
		lMBI.Left := 8*pixelRatio;
		lMBI.Caption :=
			'Trans\X'#13#10#10
			'Trans\Y'#13#10#10
			'Rotat\R';
		
		tMBIX := TEdit.Create(window);
		tMBIX.Parent := gbMBI;
		tMBIX.Top := 14*pixelRatio;
		tMBIX.Left := 50*pixelRatio;
		tMBIX.Width := 48*pixelRatio;
		tMBIX.Caption := slPreferences[indexMBIX];
		
		tMBIY := TEdit.Create(window);
		tMBIY.Parent := gbMBI;
		tMBIY.Top := 40*pixelRatio;
		tMBIY.Left := 50*pixelRatio;
		tMBIY.Width := 48*pixelRatio;
		tMBIY.Caption := slPreferences[indexMBIY];
		
		tMBIR := TEdit.Create(window);
		tMBIR.Parent := gbMBI;
		tMBIR.Top := 66*pixelRatio;
		tMBIR.Left := 50*pixelRatio;
		tMBIR.Width := 48*pixelRatio;
		tMBIR.Caption := slPreferences[indexMBIR];
		
		rbMBI := TButton.Create(window);
		rbMBI.Parent := gbMBI;
		rbMBI.Top := 90*pixelRatio;
		rbMBI.Left := 16*pixelRatio;
		rbMBI.Caption := 'Reset';
		rbMBI.OnClick  := ResetMBI;

		//MBO
		gbMBO := TGroupBox.Create(window);
		gbMBO.Parent := gbMale;
		gbMBO.Top := 24*pixelRatio;
		gbMBO.Left := 122*pixelRatio;
		gbMBO.ClientHeight := 122*pixelRatio;
		gbMBO.ClientWidth := 106*pixelRatio;
		gbMBO.Caption := 'BR && BL';
		gbMBO.Font.Size := 8;
		
		lMBO := TLabel.Create(window);
		lMBO.Parent := gbMBO;
		lMBO.Top := 16*pixelRatio;
		lMBO.Left := 8*pixelRatio;
		lMBO.Caption :=
			'Trans\X'#13#10#10
			'Trans\Y'#13#10#10
			'Rotat\R';
		
		tMBOX := TEdit.Create(window);
		tMBOX.Parent := gbMBO;
		tMBOX.Top := 14*pixelRatio;
		tMBOX.Left := 50*pixelRatio;
		tMBOX.Width := 48*pixelRatio;
		tMBOX.Caption := slPreferences[indexMBOX];
		
		tMBOY := TEdit.Create(window);
		tMBOY.Parent := gbMBO;
		tMBOY.Top := 40*pixelRatio;
		tMBOY.Left := 50*pixelRatio;
		tMBOY.Width := 48*pixelRatio;
		tMBOY.Caption := slPreferences[indexMBOY];
		
		tMBOR := TEdit.Create(window);
		tMBOR.Parent := gbMBO;
		tMBOR.Top := 66*pixelRatio;
		tMBOR.Left := 50*pixelRatio;
		tMBOR.Width := 48*pixelRatio;
		tMBOR.Caption := slPreferences[indexMBOR];
		
		rbMBO := TButton.Create(window);
		rbMBO.Parent := gbMBO;
		rbMBO.Top := 90*pixelRatio;
		rbMBO.Left := 16*pixelRatio;
		rbMBO.Caption := 'Reset';
		rbMBO.OnClick  := ResetMBO;
		
		//MF
		gbMF := TGroupBox.Create(window);
		gbMF.Parent := gbMale;
		gbMF.Top := 24*pixelRatio;
		gbMF.Left := 236*pixelRatio;
		gbMF.ClientHeight := 122*pixelRatio;
		gbMF.ClientWidth := 204*pixelRatio;
		gbMF.Caption := 'FR && FL';
		gbMF.Font.Size := 8;
		
		lMFT := TLabel.Create(window);
		lMFT.Parent := gbMF;
		lMFT.Top := 16*pixelRatio;
		lMFT.Left := 8*pixelRatio;
		lMFT.Caption :=
			'Trans\X'#13#10#10
			'Trans\Y'#13#10#10
			'Trans\Z';
		
		tMFX := TEdit.Create(window);
		tMFX.Parent := gbMF;
		tMFX.Top := 14*pixelRatio;
		tMFX.Left := 50*pixelRatio;
		tMFX.Width := 48*pixelRatio;
		tMFX.Caption := slPreferences[indexMFX];
		
		tMFY := TEdit.Create(window);
		tMFY.Parent := gbMF;
		tMFY.Top := 40*pixelRatio;
		tMFY.Left := 50*pixelRatio;
		tMFY.Width := 48*pixelRatio;
		tMFY.Caption := slPreferences[indexMFY];
		
		tMFZ := TEdit.Create(window);
		tMFZ.Parent := gbMF;
		tMFZ.Top := 66*pixelRatio;
		tMFZ.Left := 50*pixelRatio;
		tMFZ.Width := 48*pixelRatio;
		tMFZ.Caption := slPreferences[indexMFZ];
		
		lMFR := TLabel.Create(window);
		lMFR.Parent := gbMF;
		lMFR.Top := 16*pixelRatio;
		lMFR.Left := 106*pixelRatio;
		lMFR.Caption :=
			'Rotat\Y'#13#10#10
			'Rotat\P'#13#10#10
			'Rotat\R';
		
		tMFYaw := TEdit.Create(window);
		tMFYaw.Parent := gbMF;
		tMFYaw.Top := 14*pixelRatio;
		tMFYaw.Left := 148*pixelRatio;
		tMFYaw.Width := 48*pixelRatio;
		tMFYaw.Caption := slPreferences[indexMFYaw];
		
		tMFP := TEdit.Create(window);
		tMFP.Parent := gbMF;
		tMFP.Top := 40*pixelRatio;
		tMFP.Left := 148*pixelRatio;
		tMFP.Width := 48*pixelRatio;
		tMFP.Caption := slPreferences[indexMFP];
		
		tMFR := TEdit.Create(window);
		tMFR.Parent := gbMF;
		tMFR.Top := 66*pixelRatio;
		tMFR.Left := 148*pixelRatio;
		tMFR.Width := 48*pixelRatio;
		tMFR.Caption := slPreferences[indexMFR];
		
		rbMF := TButton.Create(window);
		rbMF.Parent := gbMF;
		rbMF.Top := 90*pixelRatio;
		rbMF.Left := 65*pixelRatio;
		rbMF.Caption := 'Reset';
		rbMF.OnClick  := ResetMF;
		
		
		//FEMALE ITEM POSITIONS
		gbFemale := TGroupBox.Create(window);
		gbFemale.Parent := window;
		gbFemale.Top := 224*pixelRatio;
		gbFemale.Left := 4*pixelRatio;
		gbFemale.ClientHeight := 154*pixelRatio;
		gbFemale.ClientWidth := 496*pixelRatio;
		gbFemale.Caption := 'Female';
		gbFemale.Font.Size := 12;
		
		//FBI
		gbFBI := TGroupBox.Create(window);
		gbFBI.Parent := gbFemale;
		gbFBI.Top := 24*pixelRatio;
		gbFBI.Left := 8*pixelRatio;
		gbFBI.ClientHeight := 122*pixelRatio;
		gbFBI.ClientWidth := 106*pixelRatio;
		gbFBI.Caption := 'BCR && BCL';
		gbFBI.Font.Size := 8;
		
		lFBI := TLabel.Create(window);
		lFBI.Parent := gbFBI;
		lFBI.Top := 16*pixelRatio;
		lFBI.Left := 8*pixelRatio;
		lFBI.Caption :=
			'Trans\X'#13#10#10
			'Trans\Y'#13#10#10
			'Rotat\R';
		
		tFBIX := TEdit.Create(window);
		tFBIX.Parent := gbFBI;
		tFBIX.Top := 14*pixelRatio;
		tFBIX.Left := 50*pixelRatio;
		tFBIX.Width := 48*pixelRatio;
		tFBIX.Caption := slPreferences[indexFBIX];
		
		tFBIY := TEdit.Create(window);
		tFBIY.Parent := gbFBI;
		tFBIY.Top := 40*pixelRatio;
		tFBIY.Left := 50*pixelRatio;
		tFBIY.Width := 48*pixelRatio;
		tFBIY.Caption := slPreferences[indexFBIY];
		
		tFBIR := TEdit.Create(window);
		tFBIR.Parent := gbFBI;
		tFBIR.Top := 66*pixelRatio;
		tFBIR.Left := 50*pixelRatio;
		tFBIR.Width := 48*pixelRatio;
		tFBIR.Caption := slPreferences[indexFBIR];
		
		rbFBI := TButton.Create(window);
		rbFBI.Parent := gbFBI;
		rbFBI.Top := 90*pixelRatio;
		rbFBI.Left := 16*pixelRatio;
		rbFBI.Caption := 'Reset';
		rbFBI.OnClick  := ResetFBI;

		//FBO
		gbFBO := TGroupBox.Create(window);
		gbFBO.Parent := gbFemale;
		gbFBO.Top := 24*pixelRatio;
		gbFBO.Left := 122*pixelRatio;
		gbFBO.ClientHeight := 122*pixelRatio;
		gbFBO.ClientWidth := 106*pixelRatio;
		gbFBO.Caption := 'BR && BL';
		gbFBO.Font.Size := 8;
		
		lFBO := TLabel.Create(window);
		lFBO.Parent := gbFBO;
		lFBO.Top := 16*pixelRatio;
		lFBO.Left := 8*pixelRatio;
		lFBO.Caption :=
			'Trans\X'#13#10#10
			'Trans\Y'#13#10#10
			'Rotat\R';
		
		tFBOX := TEdit.Create(window);
		tFBOX.Parent := gbFBO;
		tFBOX.Top := 14*pixelRatio;
		tFBOX.Left := 50*pixelRatio;
		tFBOX.Width := 48*pixelRatio;
		tFBOX.Caption := slPreferences[indexFBOX];
		
		tFBOY := TEdit.Create(window);
		tFBOY.Parent := gbFBO;
		tFBOY.Top := 40*pixelRatio;
		tFBOY.Left := 50*pixelRatio;
		tFBOY.Width := 48*pixelRatio;
		tFBOY.Caption := slPreferences[indexFBOY];
		
		tFBOR := TEdit.Create(window);
		tFBOR.Parent := gbFBO;
		tFBOR.Top := 66*pixelRatio;
		tFBOR.Left := 50*pixelRatio;
		tFBOR.Width := 48*pixelRatio;
		tFBOR.Caption := slPreferences[indexFBOR];
		
		rbFBO := TButton.Create(window);
		rbFBO.Parent := gbFBO;
		rbFBO.Top := 90*pixelRatio;
		rbFBO.Left := 16*pixelRatio;
		rbFBO.Caption := 'Reset';
		rbFBO.OnClick  := ResetFBO;
		
		//FF
		gbFF := TGroupBox.Create(window);
		gbFF.Parent := gbFemale;
		gbFF.Top := 24*pixelRatio;
		gbFF.Left := 236*pixelRatio;
		gbFF.ClientHeight := 122*pixelRatio;
		gbFF.ClientWidth := 252*pixelRatio;
		gbFF.Caption := 'FR && FL';
		gbFF.Font.Size := 8;
		
		lFFT := TLabel.Create(window);
		lFFT.Parent := gbFF;
		lFFT.Top := 16*pixelRatio;
		lFFT.Left := 8*pixelRatio;
		lFFT.Caption :=
			'Trans\X'#13#10#10
			'Trans\Y'#13#10#10
			'Trans\Z';
		
		tFFX := TEdit.Create(window);
		tFFX.Parent := gbFF;
		tFFX.Top := 14*pixelRatio;
		tFFX.Left := 50*pixelRatio;
		tFFX.Width := 48*pixelRatio;
		tFFX.Caption := slPreferences[indexFFX];
		
		tFFY := TEdit.Create(window);
		tFFY.Parent := gbFF;
		tFFY.Top := 40*pixelRatio;
		tFFY.Left := 50*pixelRatio;
		tFFY.Width := 48*pixelRatio;
		tFFY.Caption := slPreferences[indexFFY];
		
		tFFZ := TEdit.Create(window);
		tFFZ.Parent := gbFF;
		tFFZ.Top := 66*pixelRatio;
		tFFZ.Left := 50*pixelRatio;
		tFFZ.Width := 48*pixelRatio;
		tFFZ.Caption := slPreferences[indexFFZ];
		
		lFFR := TLabel.Create(window);
		lFFR.Parent := gbFF;
		lFFR.Top := 16*pixelRatio;
		lFFR.Left := 106*pixelRatio;
		lFFR.Caption :=
			'Rotat\Y'#13#10#10
			'Rotat\P'#13#10#10
			'Rotat\R'#13#10#10
			'Front-Left Rotat\R';
		
		tFFYaw := TEdit.Create(window);
		tFFYaw.Parent := gbFF;
		tFFYaw.Top := 14*pixelRatio;
		tFFYaw.Left := 148*pixelRatio;
		tFFYaw.Width := 48*pixelRatio;
		tFFYaw.Caption := slPreferences[indexFFYaw];
		
		tFFP := TEdit.Create(window);
		tFFP.Parent := gbFF;
		tFFP.Top := 40*pixelRatio;
		tFFP.Left := 148*pixelRatio;
		tFFP.Width := 48*pixelRatio;
		tFFP.Caption := slPreferences[indexFFP];
		
		tFFR := TEdit.Create(window);
		tFFR.Parent := gbFF;
		tFFR.Top := 66*pixelRatio;
		tFFR.Left := 148*pixelRatio;
		tFFR.Width := 48*pixelRatio;
		tFFR.Caption := slPreferences[indexFFR];
		
		tFFLR := TEdit.Create(window);
		tFFLR.Parent := gbFF;
		tFFLR.Top := 92*pixelRatio;
		tFFLR.Left := 198*pixelRatio;
		tFFLR.Width := 48*pixelRatio;
		tFFLR.Caption := slPreferences[indexFFLR];
		
		rbFF := TButton.Create(window);
		rbFF.Parent := gbFF;
		rbFF.Top := 90*pixelRatio;
		rbFF.Left := 16*pixelRatio;
		rbFF.Caption := 'Reset';
		rbFF.OnClick  := ResetFF;
		
		//Start Button
		start := TButton.Create(window);
		start.Parent := window;
		start.Top := 386*pixelRatio;
		start.Left := 216*pixelRatio; //window.Width / 2 - 40;
		start.Caption := 'Start';
		start.Font.Size := 10;
		start.ModalResult := mrOk;

		bWindowCreated := True;
		window.ActiveControl := start;
		
		if window.ShowModal = mrOk then begin
			bGreenLight := True;
			
			SourcePath := IncludeTrailingBackslash(SourcePathInput.Text);
			AddMessage(#13#10'Processing Meshes located in: ' + SourcePath);
			
			slPreferences[indexMBIX] := tMBIX.Text;
			slPreferences[indexMBIY] := tMBIY.Text;
			slPreferences[indexMBIR] := tMBIR.Text;
			slPreferences[indexMBOX] := tMBOX.Text;
			slPreferences[indexMBOY] := tMBOY.Text;
			slPreferences[indexMBOR] := tMBOR.Text;
			slPreferences[indexMFX] := tMFX.Text;
			slPreferences[indexMFY] := tMFY.Text;
			slPreferences[indexMFZ] := tMFZ.Text;
			slPreferences[indexMFYaw] := tMFYaw.Text;
			slPreferences[indexMFP] := tMFP.Text;
			slPreferences[indexMFR] := tMFR.Text;
			slPreferences[indexFBIX] := tFBIX.Text;
			slPreferences[indexFBIY] := tFBIY.Text;
			slPreferences[indexFBIR] := tFBIR.Text;
			slPreferences[indexFBOX] := tFBOX.Text;
			slPreferences[indexFBOY] := tFBOY.Text;
			slPreferences[indexFBOR] := tFBOR.Text;
			slPreferences[indexFFX] := tFFX.Text;
			slPreferences[indexFFY] := tFFY.Text;
			slPreferences[indexFFZ] := tFFZ.Text;
			slPreferences[indexFFYaw] := tFFYaw.Text;
			slPreferences[indexFFP] := tFFP.Text;
			slPreferences[indexFFR] := tFFR.Text;
			slPreferences[indexFFLR] := tFFLR.Text;
			slPreferences.SaveToFile(SavPrefPath);
			
			fMBIX := strtofloat(tMBIX.Text);
			fMBIY := strtofloat(tMBIY.Text);
			fMBIR := strtofloat(tMBIR.Text);
			fMBOX := strtofloat(tMBOX.Text);
			fMBOY := strtofloat(tMBOY.Text);
			fMBOR := strtofloat(tMBOR.Text);
			fMFX := strtofloat(tMFX.Text);
			fMFY := strtofloat(tMFY.Text);
			fMFZ := strtofloat(tMFZ.Text);
			fMFYaw := strtofloat(tMFYaw.Text);
			fMFP := strtofloat(tMFP.Text);
			fMFR := strtofloat(tMFR.Text);
			fFBIX := strtofloat(tFBIX.Text);
			fFBIY := strtofloat(tFBIY.Text);
			fFBIR := strtofloat(tFBIR.Text);
			fFBOX := strtofloat(tFBOX.Text);
			fFBOY := strtofloat(tFBOY.Text);
			fFBOR := strtofloat(tFBOR.Text);
			fFFX := strtofloat(tFFX.Text);
			fFFY := strtofloat(tFFY.Text);
			fFFZ := strtofloat(tFFZ.Text);
			fFFYaw := strtofloat(tFFYaw.Text);
			fFFP := strtofloat(tFFP.Text);
			fFFR := strtofloat(tFFR.Text);
			fFFLR := strtofloat(tFFLR.Text);
		end;
		
		ScriptProcessElements := [etFile];  // process function will only get the files the user selected, instead of everything.
	finally
		slPreferences.Free;
		window.Free;
	end;
end;

function Process(e: IInterface): Integer;
begin
end;

function Finalize: Integer;
begin
	if(bGreenLight)then
		ProcessMeshes;

	Result := 1;
	//Now go upload some screenshots to bring in more converts.
end;

end.
