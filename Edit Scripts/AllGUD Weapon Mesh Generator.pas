{	README:
	Build AllGUD compatible Meshes from weapons and shields.
	
	You can scan either the SELECTED plugins (not loaded plugins, but selected plugins), or a Folder.
	Scanning plugins is recommended as it will warn you if unable to find the required .nif to generate AllGUD meshes from.

	Scans weapons & shield .nifs and creates new ones using the templates.
		Only copies over and changes relevant information for a static display:
			*AllGUD extends the DSR standard, the mod makes use of the same names & nodes for Staves & Left-Hand equipment.
			-Generated files use AllGUD or DSR naming scheme.
			-PRN strings (which determine skeleton node) changed AllGUD or DSR nodes.
			-Right-hand meshes have their Scb renamed
			-Left-hand meshes are mirrored
			-Left-hands that use scabbards get an additional mesh with an empty scabbard for when weapons are drawn.
			-Shields have an additional mesh generated to accommodate backpacks &| cloaks.
			-LE Bows do not retain their skin & bone data.
			-SE Bows have shape data moved from skin partition to BSTriShape and transcend beyond skin and bones
			
	Reproducing Errors:
		1. Check the xEdit version
		2. Download the mod the model came from
		3. Use the same generation method
		4. 
		
	Known causes of CTD as a result of failed mesh generation.
		- Skin Instance got through, typically for bows.
		- Static Display failure to purge Extra Data List
}

unit AllGUDMeshGen;
	
// GLOBAL VARIABLES
const
	//Make sure the template paths exist.
	SETemplatePath = 'AllGUD\SE Templates\Template.nif';
	LETemplatePath = 'AllGUD\LE Templates\Template.nif';
	PreferencesPath = 'AllGUD\Weapon Preferences.txt';
	PluginBlacklist = 'AllGUD\Blacklist.txt';	//Authors that don't want their meshes to be generated can instruct users to add their plugin here.
	PI = 3.14159265359;
	indexSourcePath = 0;
	indexDestPath = 1;
	
	InvalidWeapon = 0;
	
	iTypeSword = 1;
	iTypeDagger = 2;
	iTypeMace = 3;
	iTypeAxe = 4;
	iTypeStaff = 5;
	iTypeTwoHandMelee = 6;
	iTypeTwoHandRange = 7;
	iTypeShield = 8;
	
	iCatOneHandMelee = 1;
	iCatTwoHandMelee = 2;
	iCatShield = 3;
	iCatTwoHandRange = 4;
	iCatStaff = 5;
	
var
	slPreferences, slLog, slModels, slFailed, slBlacklist, ContainerChoice: TStringList;
	bGenerateMeshes, bPatchOneHand, bPatchBack, bPatchBows, bPatchShields, bPatchStaves, bMirrorStaves, bDetailedMessages, bScanRecords, bCheckArchives, bUseTemplates: Boolean;
	bMeshHasController, bModelsHadAlternateTextures: Boolean;
	SourcePathInput, DestinationPathInput: TEdit;
	SourcePathLength, countPatched, countSkipped, countGenerated, countFailed: Integer;
	DataPathMeshes, SavPrefPath, LineBreak, SourcePath, DestinationPath: String;
	
//	DIRECTORY SELECTION
procedure ResetDataPath;
begin
	//Set input folder to skyrim data\meshes\. Allowing xEdit to get meshes from any enabled mods.
	SourcePathInput.Text := DataPathMeshes;
	slPreferences[0] := DataPathMeshes;
	slPreferences.SaveToFile(SavPrefPath);
end;
procedure PickPath(Sender: TObject);
var
	s: string;
	iIndex: integer;
begin
	//Select Directory and save user's paths for future instances of the script.
	if Sender = SourcePathInput then begin
		iIndex := indexSourcePath;
		s := slPreferences[iIndex];
		s := SelectDirectory('Select folder to generate meshes for', '', s, '');
	end
	else begin
		iIndex := indexDestPath;
		s := slPreferences[iIndex];
		s := SelectDirectory('Select folder for generated meshes', '', s, '');
	end;
	
	if s <> '' then begin
		if iIndex = indexSourcePath then begin
			SourcePathInput.Text := s + '\';
		end else begin
			If pos('\meshes', lowercase(s)) = 0 then s := s + '\meshes';
			DestinationPathInput.Text := s + '\';
		end;
		slPreferences[iIndex] := s + '\';
		slPreferences.SaveToFile(SavPrefPath);
	end;
 end;


//	LOGGING
procedure DetailedLog(line: String);
begin
	//Logs string.
	//Add messages only if user enabled the option.
	//Messages significantly slow the runtime.
	slLog.add('['+TimeToStr(Time)+'] '+line);
	if bDetailedMessages then addmessage(line);
end;
procedure Log(line: String);
begin
	//Log string and add a message to xEdit.
	addmessage(line);
	slLog.add('['+TimeToStr(Time)+'] '+line);	
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
		Log('Error: Unable to locate ' + aSourcePath);
	end else begin
		SourceF := TFileStream.Create(aSourcePath, fmOpenRead);
		try
			DestF := TFileStream.Create(aDestinationPath, fmCreate);
			DestF.CopyFrom(SourceF, SourceF.Size);
		except
			Log(#9'Error: Unable to write to ' + aDestinationPath);
		end;
		SourceF.Free;
		DestF.Free;
	end;
end;


//	BLOCK FUNCTIONS
function IsBloodMesh(aMeshBlock: TwbNifBlock;): Boolean;
var
	i, j: integer;
	SubBlock, SubSubBlock: TwbNifBlock;
	Element, textureElement: TdfElement;
	sL: TStringList;
begin
	//Check if the TriShape is a bloodmesh.
	//Blood meshes don't get used for the armor and just take up space.
	
	//Let's just scan the textures for 'BloodEdge'??? That's like the only commonality I can find.
		//Especially since there's a mod with a SE Mesh that has improper data that makes it cause CTD and this is the only thing I can use to catch it.
	if (aMeshBlock.BlockType = 'BSTriShape') or (aMeshBlock.BlockType = 'NiTriShape') or (aMeshBlock.BlockType = 'NiTriStrips') then begin
		SubBlock := TwbNifBlock(aMeshBlock.Elements['Shader Property'].LinksTo);
		if Assigned(SubBlock) then begin
			if SubBlock.BlockType = 'BSEffectShaderProperty' then begin
				if SubBlock.NativeValues['Shader Flags 2\Weapon_Blood'] <> 0 then begin
					Result := true;
					exit;
				end;
			end
			else if SubBlock.BlockType = 'BSLightingShaderProperty' then begin
				SubSubBlock := TwbNifBlock(SubBlock.Elements['Texture Set'].LinksTo);
				if Assigned(SubSubBlock) then begin
					if SubSubBlock.BlockType = 'BSShaderTextureSet' then begin
						textureElement := SubSubBlock.Elements['Textures'];
						if (pos('blood\bloodedge', lowercase(textureElement[0].EditValue)) > 0) then begin
							Result := true;
							exit;
						end;
						if (pos('blood\bloodhit', lowercase(textureElement[0].EditValue)) > 0) then begin
							//Skullcrusher
							Result := true;
							exit;
						end;
					end;
				end;
			end;
		end;
		
		//NiTriShape blood has a NiStringExtraData sub-block named 'Keep' and 'NiHide' as its data.
		//This was the original, dunno if Kesta needed it for something specific or not?
			//Saw some meshes that couldn't keep this straight, and had NiHide/Keep reversed.
		Element := aMeshBlock.Elements['Extra Data List'];
		for i := 0 to Pred(Element.Count) do begin
			SubBlock := TwbNifBlock(Element[i].LinksTo);
			if Assigned(SubBlock) then begin
				if SubBlock.BlockType = 'NiStringExtraData' then begin 
					if SameText(SubBlock.EditValues['Name'], 'Keep') and SameText(SubBlock.EditValues['Data'], 'NiHide') then begin
						Result := True;
					end;
				end;
			end;
		end;
	end;
end;

function RenamePrn(aiWeaponType: Integer; abMirror: Boolean): String;
begin
	if aiWeaponType = iTypeSword then begin
		if abMirror then
			Result := 'WeaponSwordLeft'
		else
			Result := 'WeaponSwordArmor';
	end
	else if aiWeaponType = iTypeDagger then begin
		if abMirror then
			Result := 'WeaponDaggerLeft'
		else
			Result := 'WeaponDaggerArmor';
	end
	else if aiWeaponType = iTypeAxe then begin
		if abMirror then
			Result := 'WeaponAxeLeft'
		else
			Result := 'WeaponAxeArmor';
	end
	else if aiWeaponType = iTypeMace then begin
		if abMirror then
			Result := 'WeaponMaceLeft'
		else
			Result := 'WeaponMaceArmor';
	end
	else if aiWeaponType = iTypeStaff then begin
		if abMirror then
			Result := 'WeaponStaffLeft'
		else
			Result := 'WeaponStaff';
	end
	else if aiWeaponType = iTypeTwoHandMelee then begin
			Result := 'WeaponBackArmor';
	end
	else if aiWeaponType = iTypeTwoHandRange then begin
			Result := 'WeaponBowArmor';
	end
	else if aiWeaponType = iTypeShield then begin
		Result := 'ShieldBack';
	end;
end;


//	VERTEX DATA MANIPULATION
procedure TransferVertexData(aPartition, aBlockShape: TwbNifBlock);
var
	Parts, Part, ElementPartition, ElementBlock: TdfElement;
begin
	//Get the first partition, where Triangles and the rest is stored
		//Haven't seen any with multiple partitions.
		//Not sure how that would work, revisit if there's a problem.
	Parts := aPartition.Elements['Partitions'];
	Part := Parts[0];
	
	//Copy Vertex Data from NiSkinPartition
	ElementPartition := aPartition.Elements['Vertex Data'];
	aBlockShape.NativeValues['Num Vertices'] := ElementPartition.Count;
	ElementBlock := aBlockShape.Elements['Vertex Data'];
	ElementBlock.Assign(ElementPartition);
	
	//Copy Triangles from Partition of NiSkinPartition
	ElementPartition := Part.Elements['Triangles'];
	aBlockShape.NativeValues['Num Triangles'] := ElementPartition.Count;
	ElementBlock := aBlockShape.Elements['Triangles'];
	ElementBlock.Assign(ElementPartition);
	
	aBlockShape.UpdateBounds;
end;

procedure MirrorBlock(aBlock: TwbNifBlock);
var
	Block: TwbNifBlock;
	Element: TdfElement;
	i: Integer;
	ListChildBlocks: TList;
begin
	DetailedLog(#9#9'Mirroring Block: '+inttostr(aBlock.Index));
	if (aBlock.BlockType = 'BSTriShape') or (aBlock.BlockType = 'NiTriShape') then begin
		ApplyTransform(aBlock);	//In case things are at an angle where flipping x would produce incorrect results.
		FlipAlongX(aBlock);
	end else begin
		Element := aBlock.Elements['Children'];
		if Assigned(Element) then begin
			ListChildBlocks := TList.Create;
			for i := 0 to Pred(Element.Count) do begin
				Block := TwbNifBlock(Element[i].LinksTo);
				if Assigned(Block) then begin
					if(ListChildBlocks.IndexOf(Block.Index) >= 0) then continue;
					Tlist(ListChildBlocks).Add(Block.Index);
					MirrorBlock(Block);
				end;
			end;
			ListChildBlocks.Free;
		end;
	end;
end;

procedure FlipAlongX(aTriShape: TwbNifBlock);
var
	i, n: integer;
	sl: TStringList;
	TriShapeData: TwbNifBlock;
	ref, vertices, normals, triangles: TdfElement;
begin
	sl := TStringList.Create;
	sl.Delimiter := ' ';
	sl.StrictDelimiter := false;
  
	if (aTriShape.BlockType = 'BSTriShape') then begin
		n := aTriShape.NativeValues['Num Vertices'];
		vertices := aTriShape.Elements['Vertex Data'];
		try
			for i := 0 to Pred(n) do begin
				vertices[i].NativeValues['Vertex\X'] := -vertices[i].NativeValues['Vertex\X'];
				//BSTriShape normals use ByteVector3 instead of Vector3
				vertices[i].EditValues['Normal\X'] := FloatToStr(-StrToFloat(vertices[i].EditValues['Normal\X']));
			end;
		
			n := aTriShape.NativeValues['Num Triangles'];
			triangles := aTriShape.Elements['Triangles'];
			for i := 0 to Pred(n) do begin
				sl.DelimitedText := triangles[i].EditValue;
				triangles[i].EditValue := sl[1] + ' ' + sl[0] + ' ' + sl[2];
			end;
		except
			Log('Error: Data for Block:'+inttostr(aTriShape.Index)+' not found'#13#10#9'Search for this message in the log to find the affected mesh');
		end;
		
		aTriShape.UpdateBounds;
		try //Non-vital
			aTriShape.UpdateTangents;
		except
			Log('Error: Something went wrong when updating the Tangent for the left-hand variant(s) of this mesh'#13#10#9'Search the log for this message to find the affected mesh. These procedures can be applied manually using NifSkope.');
		end;
	end
	else if (aTriShape.BlockType = 'NiTriShape') or (aTriShape.BlockType = 'NiTriStrips') then begin
		TriShapeData := TwbNifBlock(aTriShape.Elements['Data'].LinksTo);
		if Assigned(TriShapeData) then begin 
			if (TriShapeData.BlockType = 'NiTriShapeData') or (TriShapeData.BlockType = 'NiTriStripsData') then begin
				n := TriShapeData.NativeValues['Num Vertices'];
				vertices := TriShapeData.Elements['Vertices'];
				normals := TriShapeData.Elements['Normals'];
				
				for i := 0 to Pred(n) do begin
					vertices[i].NativeValues['X'] := -vertices[i].NativeValues['X'];
					if Assigned(normals) then begin
						normals[i].NativeValues['X'] := -normals[i].NativeValues['X'];
					end;
				end;
				
				n := TriShapeData.NativeValues['Num Triangles'];
				triangles := TriShapeData.Elements['Triangles'];
				if Assigned(triangles) then
					for i := 0 to Pred(n) do begin
						sl.DelimitedText := triangles[i].EditValue;
						triangles[i].EditValue := sl[1] + ' ' + sl[0] + ' ' + sl[2];
					end;
				
				TriShapeData.UpdateBounds;
				try //Non-vital
					TriShapeData.UpdateTangents;
				except
					Log('Error: Something went wrong when updating the Tangent for the left-hand variant(s) of this mesh'#13#10#9'Search the log for this message to find the affected mesh. This procedure can be applied manually using NifSkope.');
				end;
			end;
		end;
	end;
	sl.Free;
end;

procedure ApplyTransform(aTriShape: TwbNifBlock);
var
  scale: single;                       // Transform scale.
  translation: array[0..2] of single;  // Transform translation.
  rotation: array[0..8] of single;     // Transform rotation matrix.

  pX, pY, pZ: single; // point coordinates.
  tX, tY, tZ: single; // transformed point coordinates.

  TriShapeData: TwbNifBlock; // Shape Data to transform point.

  // stuff to iterate over things.
  ref, vertices, normals, triangles: TdfElement;
  i, n: integer;
begin
	scale := aTriShape.NativeValues['Transform\Scale'];
	translation[0] := aTriShape.NativeValues['Transform\Translation\X'];
	translation[1] := aTriShape.NativeValues['Transform\Translation\Y'];
	translation[2] := aTriShape.NativeValues['Transform\Translation\Z'];
	
	rotation[0] := RoundTo(aTriShape.NativeValues['Transform\Rotation\[0]'], -4);
	rotation[1] := RoundTo(aTriShape.NativeValues['Transform\Rotation\[1]'], -4);
	rotation[2] := RoundTo(aTriShape.NativeValues['Transform\Rotation\[2]'], -4);
	rotation[3] := RoundTo(aTriShape.NativeValues['Transform\Rotation\[3]'], -4);
	rotation[4] := RoundTo(aTriShape.NativeValues['Transform\Rotation\[4]'], -4);
	rotation[5] := RoundTo(aTriShape.NativeValues['Transform\Rotation\[5]'], -4);
	rotation[6] := RoundTo(aTriShape.NativeValues['Transform\Rotation\[6]'], -4);
	rotation[7] := RoundTo(aTriShape.NativeValues['Transform\Rotation\[7]'], -4);
	rotation[8] := RoundTo(aTriShape.NativeValues['Transform\Rotation\[8]'], -4);
	
	//Check if anything is transformed
	if (scale = 1)
	and (translation[0] = 0) and (translation[1] = 0) and (translation[2] = 0)
	and (rotation[0]=1) and (rotation[1]=0) and (rotation[2]=0)
	and (rotation[3]=0) and (rotation[4]=1) and (rotation[5]=0)
	and (rotation[6]=0) and (rotation[7]=0) and (rotation[8]=1)
		then exit;
	

	if (aTriShape.BlockType = 'BSTriShape') then begin
		n := aTriShape.NativeValues['Num Vertices'];
		vertices := aTriShape.Elements['Vertex Data'];
		
		try
			for i := 0 to Pred(n) do begin			
				pX := vertices[i].NativeValues['Vertex\X'];
				pY := vertices[i].NativeValues['Vertex\Y'];
				pZ := vertices[i].NativeValues['Vertex\Z'];

				tX := (pX * rotation[0] + pY * rotation[1] + pZ * rotation[2]) * scale + translation[0];
				tY := (pX * rotation[3] + pY * rotation[4] + pZ * rotation[5]) * scale + translation[1];
				tZ := (pX * rotation[6] + pY * rotation[7] + pZ * rotation[8]) * scale + translation[2];

				vertices[i].NativeValues['Vertex\X'] := tX;
				vertices[i].NativeValues['Vertex\Y'] := tY;
				vertices[i].NativeValues['Vertex\Z'] := tZ;
				
				//SE uses ByteVector3 for normals, so grab their edit values
				pX := vertices[i].EditValues['Normal\X'];
				pY := vertices[i].EditValues['Normal\Y'];
				pZ := vertices[i].EditValues['Normal\Z'];
				
				tX := (pX * rotation[0] + pY * rotation[1] + pZ * rotation[2]);
				tY := (pX * rotation[3] + pY * rotation[4] + pZ * rotation[5]);
				tZ := (pX * rotation[6] + pY * rotation[7] + pZ * rotation[8]);

				vertices[i].EditValues['Normal\X'] := tX;
				vertices[i].EditValues['Normal\Y'] := tY;
				vertices[i].EditValues['Normal\Z'] := tZ;
				
			end;
		except
			Log('Error: Block Data for: '+inttostr(aTriShape.Index)+' not found'#13#10#9'Search for this message in the log to find the affected mesh');
		end;
		aTriShape.UpdateBounds;
		try //Non-vital
			aTriShape.UpdateTangents;
		except
			Log('Error: Something went wrong when updating the Tangent for the left-hand variant(s) of this mesh'#13#10#9'Search the log for this message to find the affected mesh. These procedures can easily be performed using NifSkope.');
		end;
	end
	else begin
		TriShapeData := TwbNifBlock(aTriShape.Elements['Data'].LinksTo);
		if Assigned(TriShapeData) then begin 
			if (TriShapeData.BlockType = 'NiTriShapeData') or (TriShapeData.BlockType = 'NiTriStripsData') then begin
				n := TriShapeData.NativeValues['Num Vertices'];
				vertices := TriShapeData.Elements['Vertices'];
				normals := TriShapeData.Elements['Normals'];
				for i := 0 to Pred(n) do begin
					pX := vertices[i].NativeValues['X'];
					pY := vertices[i].NativeValues['Y'];
					pZ := vertices[i].NativeValues['Z'];

					tX := (pX * rotation[0] + pY * rotation[1] + pZ * rotation[2]) * scale + translation[0];
					tY := (pX * rotation[3] + pY * rotation[4] + pZ * rotation[5]) * scale + translation[1];
					tZ := (pX * rotation[6] + pY * rotation[7] + pZ * rotation[8]) * scale + translation[2];

					vertices[i].NativeValues['X'] := tX;
					vertices[i].NativeValues['Y'] := tY;
					vertices[i].NativeValues['Z'] := tZ;
					
					if Assigned(normals) then begin
						pX := normals[i].NativeValues['X'];
						pY := normals[i].NativeValues['Y'];
						pZ := normals[i].NativeValues['Z'];

						tX := (pX * rotation[0] + pY * rotation[1] + pZ * rotation[2]);
						tY := (pX * rotation[3] + pY * rotation[4] + pZ * rotation[5]);
						tZ := (pX * rotation[6] + pY * rotation[7] + pZ * rotation[8]);

						normals[i].NativeValues['X'] := tX;
						normals[i].NativeValues['Y'] := tY;
						normals[i].NativeValues['Z'] := tZ;
					end;
					
				end;
				TriShapeData.UpdateBounds;				
				try //Non-vital
					TriShapeData.UpdateTangents;
				except
					Log('Error: Something went wrong when updating the Tangent for the left-hand variant(s) of this mesh'#13#10#9'Search the log for this message to find the affected mesh. This procedure can be applied manually using NifSkope.');
				end;
			end;
		end;
	end;
	
	aTriShape.EditValues['Transform\Translation'] := '0.000000 0.000000 0.000000';
	aTriShape.EditValues['Transform\Rotation']    := '0.000000 0.000000 0.000000';
	aTriShape.EditValues['Transform\Scale']       := '1.000000';
end;

procedure ApplyTransformToChild(aParentBlock, aChildBlock: TwbNifBlock; abIsBow: Boolean);
var
	i: Integer;
	PScale, CScale: single;
	PTranslation, CTranslation: array[0..2] of single;
	PRotation, CRotation: array[0..8] of single;
	Block: TwbNifBlock;
	Element: TdfElement;
	ListChildBlocks: TList;
begin	
	DetailedLog(#9'Applying Transform of Block:'+inttostr(aParentBlock.Index)+' to its Child:'+inttostr(aChildBlock.Index));
	
	PScale := aParentBlock.NativeValues['Transform\Scale'];
	PTranslation[0] := aParentBlock.NativeValues['Transform\Translation\X'];
	PTranslation[1] := aParentBlock.NativeValues['Transform\Translation\Y'];
	PTranslation[2] := aParentBlock.NativeValues['Transform\Translation\Z'];
	PRotation[0] := RoundTo(aParentBlock.NativeValues['Transform\Rotation\[0]'], -4);
	PRotation[1] := RoundTo(aParentBlock.NativeValues['Transform\Rotation\[1]'], -4);
	PRotation[2] := RoundTo(aParentBlock.NativeValues['Transform\Rotation\[2]'], -4);
	PRotation[3] := RoundTo(aParentBlock.NativeValues['Transform\Rotation\[3]'], -4);
	PRotation[4] := RoundTo(aParentBlock.NativeValues['Transform\Rotation\[4]'], -4);
	PRotation[5] := RoundTo(aParentBlock.NativeValues['Transform\Rotation\[5]'], -4);
	PRotation[6] := RoundTo(aParentBlock.NativeValues['Transform\Rotation\[6]'], -4);
	PRotation[7] := RoundTo(aParentBlock.NativeValues['Transform\Rotation\[7]'], -4);
	PRotation[8] := RoundTo(aParentBlock.NativeValues['Transform\Rotation\[8]'], -4);
	
	CScale := aChildBlock.NativeValues['Transform\Scale'];
	CTranslation[0] := aChildBlock.NativeValues['Transform\Translation\X'];
	CTranslation[1] := aChildBlock.NativeValues['Transform\Translation\Y'];
	CTranslation[2] := aChildBlock.NativeValues['Transform\Translation\Z'];
	CRotation[0] := RoundTo(aChildBlock.NativeValues['Transform\Rotation\[0]'], -4);
	CRotation[1] := RoundTo(aChildBlock.NativeValues['Transform\Rotation\[1]'], -4);
	CRotation[2] := RoundTo(aChildBlock.NativeValues['Transform\Rotation\[2]'], -4);
	CRotation[3] := RoundTo(aChildBlock.NativeValues['Transform\Rotation\[3]'], -4);
	CRotation[4] := RoundTo(aChildBlock.NativeValues['Transform\Rotation\[4]'], -4);
	CRotation[5] := RoundTo(aChildBlock.NativeValues['Transform\Rotation\[5]'], -4);
	CRotation[6] := RoundTo(aChildBlock.NativeValues['Transform\Rotation\[6]'], -4);
	CRotation[7] := RoundTo(aChildBlock.NativeValues['Transform\Rotation\[7]'], -4);
	CRotation[8] := RoundTo(aChildBlock.NativeValues['Transform\Rotation\[8]'], -4);
	
	//Multiply the Scalar
	aChildBlock.NativeValues['Transform\Scale'] := PScale*CScale;
	
	//Adjust the Translation
	aChildBlock.NativeValues['Transform\Translation\X'] := (CTranslation[0] * PRotation[0] + CTranslation[1] * PRotation[1] + CTranslation[2] * PRotation[2]) * PScale + PTranslation[0];
	aChildBlock.NativeValues['Transform\Translation\Y'] := (CTranslation[0] * PRotation[3] + CTranslation[1] * PRotation[4] + CTranslation[2] * PRotation[5]) * PScale + PTranslation[1];
	aChildBlock.NativeValues['Transform\Translation\Z'] := (CTranslation[0] * PRotation[6] + CTranslation[1] * PRotation[7] + CTranslation[2] * PRotation[8]) * PScale + PTranslation[2];
	
	
	//Matrix Multiplication
	aChildBlock.NativeValues['Transform\Rotation\[0]'] := RoundTo(PRotation[0]*CRotation[0] + PRotation[1]*CRotation[3] + PRotation[2]*CRotation[6] , -4);
	aChildBlock.NativeValues['Transform\Rotation\[1]'] := RoundTo(PRotation[0]*CRotation[1] + PRotation[1]*CRotation[4] + PRotation[2]*CRotation[7] , -4);
	aChildBlock.NativeValues['Transform\Rotation\[2]'] := RoundTo(PRotation[0]*CRotation[2] + PRotation[1]*CRotation[5] + PRotation[2]*CRotation[8] , -4);
	
	aChildBlock.NativeValues['Transform\Rotation\[3]'] := RoundTo(PRotation[3]*CRotation[0] + PRotation[4]*CRotation[3] + PRotation[5]*CRotation[6] , -4);
	aChildBlock.NativeValues['Transform\Rotation\[4]'] := RoundTo(PRotation[3]*CRotation[1] + PRotation[4]*CRotation[4] + PRotation[5]*CRotation[7] , -4);
	aChildBlock.NativeValues['Transform\Rotation\[5]'] := RoundTo(PRotation[3]*CRotation[2] + PRotation[4]*CRotation[5] + PRotation[5]*CRotation[8] , -4);
	
	aChildBlock.NativeValues['Transform\Rotation\[6]'] := RoundTo(PRotation[6]*CRotation[0] + PRotation[7]*CRotation[3] + PRotation[8]*CRotation[6] , -4);
	aChildBlock.NativeValues['Transform\Rotation\[7]'] := RoundTo(PRotation[6]*CRotation[1] + PRotation[7]*CRotation[4] + PRotation[8]*CRotation[7] , -4);
	aChildBlock.NativeValues['Transform\Rotation\[8]'] := RoundTo(PRotation[6]*CRotation[2] + PRotation[7]*CRotation[5] + PRotation[8]*CRotation[8] , -4);
	
	Element := aChildBlock.Elements['Controller'];
	If Assigned(Element) then begin
		Block := TwbNifBlock(Element.LinksTo);
		If Assigned(Block) then
			if(Block.BlockType = 'NiTransformController') then begin
				bMeshHasController := true;
				if not bUseTemplates then
					exit;
			end;
	end;
	
	Element := aChildBlock.Elements['Children'];
	if Assigned(Element) then begin
		ListChildBlocks := TList.Create;
		for i := 0 to Pred(Element.Count) do begin
			Block := TwbNifBlock(Element[i].LinksTo);
			if Assigned(Block) then
				if(ListChildBlocks.IndexOf(Block.Index) >= 0) then continue;
				Tlist(ListChildBlocks).Add(Block.Index);
				ApplyTransformToChild(aChildBlock, Block, abIsBow);
		end;
		
		if abIsBow then exit;
		
		aChildBlock.EditValues['Transform\Translation'] := '0.000000 0.000000 0.000000';
		aChildBlock.EditValues['Transform\Rotation']    := '0.000000 0.000000 0.000000';
		aChildBlock.EditValues['Transform\Scale']       := '1.000000';
		ListChildBlocks.Free;
	end;
end;

//	METHOD 1 -- DUPLICATE A TEMPLATE AND ADD BLOCKS TO IT
function CopyBlockAsChildOf(aSourceBlock, aParentBlock: TwbNifBlock): TwbNifBlock;
var
	i, j: integer;
	ref, Element: TdfElement;
	BlockDest, SubBlockSrc, SubBlockDest, SubSubBlockSrc, SubSubBlockDest: TwbNifBlock;
	Nif: TwbNifFile;
	ListChildBlocks: TList;
begin
	if not Assigned(aSourceBlock) then exit;

	
	if (aSourceBlock.BlockType = 'BSTriShape') or (aSourceBlock.BlockType = 'NiTriShape') or (aSourceBlock.BlockType = 'NiTriStrips') then begin
		if IsBloodMesh(aSourceBlock) then exit;
		
		BlockDest := aParentBlock.AddChild(aSourceBlock.BlockType);
		BlockDest.Assign(aSourceBlock);
		Nif := aParentBlock.NifFile;
		
		if not (aSourceBlock.BlockType = 'BSTriShape') then begin
			SubBlockSrc := TwbNifBlock(aSourceBlock.Elements['Data'].LinksTo);
			if Assigned(SubBlockSrc) then begin
				//Copy NiTriShapeData, only necessary for NiTriShapes/Strips, not BSTriShape
				SubBlockDest := Nif.AddBlock(SubBlockSrc.BlockType);
				SubBlockDest.Assign(SubBlockSrc);
				BlockDest.NativeValues['Data'] := SubBlockDest.Index;
			end;
		end;
		
		SubBlockSrc := TwbNifBlock(aSourceBlock.Elements['Shader Property'].LinksTo);
		if Assigned(SubBlockSrc) then begin
			if (SubBlockSrc.BlockType = 'BSLightingShaderProperty') then begin
				//Copy BSLightingShaderProperty and BSShaderTextureSet SubBlock
				SubBlockDest := Nif.AddBlock(SubBlockSrc.BlockType);
				SubBlockDest.Assign(SubBlockSrc);
				BlockDest.NativeValues['Shader Property'] := SubBlockDest.Index;
				SubBlockDest.NativeValues['Shader Flags 1\Skinned'] := 0; // remove unecessary skinning on bows.
				SubBlockDest.NativeValues['Controller'] := -1; // remove controllers and do them manually if needed
				
				SubBlockDest.NativeValues['Texture Set'] := -1; //Copy texture set, remove if not assigned
				SubSubBlockSrc := TwbNifBlock(SubBlockSrc.Elements['Texture Set'].LinksTo);
				if Assigned(SubSubBlockSrc) then begin
					SubSubBlockDest := Nif.AddBlock('BSShaderTextureSet');
					SubSubBlockDest.Assign(SubSubBlockSrc);
					SubBlockDest.NativeValues['Texture Set'] := SubSubBlockDest.Index;
				end;
			end
			else if (SubBlockSrc.BlockType = 'BSEffectShaderProperty') then begin
				//Copy the BSEffectShaderProperty
				SubBlockDest := Nif.AddBlock(SubBlockSrc.BlockType);
				SubBlockDest.Assign(SubBlockSrc);
				BlockDest.NativeValues['Shader Property'] := SubBlockDest.Index;
				SubBlockDest.NativeValues['Shader Flags 1\Skinned'] := 0; // remove unecessary skinning on bows.
				SubBlockDest.NativeValues['Controller'] := -1; // remove controllers and do them manually if needed
			end;
		end;
			
		SubBlockSrc := TwbNifBlock(aSourceBlock.Elements['Alpha Property'].LinksTo);
		if Assigned(SubBlockSrc) then begin
			//Copy the NiAlphaProperty
			SubBlockDest := Nif.AddBlock(SubBlockSrc.BlockType);
			SubBlockDest.Assign(SubBlockSrc);
			BlockDest.NativeValues['Alpha Property'] := SubBlockDest.Index;
		end;
		
		//Can cause CTD if a blood mesh got through
		Element := BlockDest.Elements['Extra Data List'];
		if Assigned(Element) then
			Element.SetToDefault();
			
	end
	
	else if SameText(aSourceBlock.EditValues['Name'], 'NonStickScb') then begin
		//Multipart scabbard, Apply transform down and attach and child tri-shapes to the scabbard block
		BlockDest := aParentBlock.AddChild(aSourceBlock.BlockType);
		BlockDest.Assign(aSourceBlock);
		Element := BlockDest.Elements['Children'];
		if Assigned(Element) then
			Element.SetToDefault();
		
		Element := aSourceBlock.Elements['Children'];
		if Assigned(Element) then begin
			ListChildBlocks := TList.Create;
			for i := 0 to Pred(Element.Count) do begin
				SubBlockSrc := TwbNifBlock(Element[i].LinksTo);
				if Assigned(SubBlockSrc) then begin
					if(ListChildBlocks.IndexOf(SubBlockSrc.Index) >= 0) then continue;
					Tlist(ListChildBlocks).Add(SubBlockSrc.Index);
					DetailedLog(#9#9'Processing Block: '+inttostr(SubBlockSrc.Index));
					CopyBlockAsChildOf(SubBlockSrc, BlockDest);
				end;
			end;
			ListChildBlocks.Free;
		end;
	end
	else begin
		//Non-scabbard, non-trishape
		//Apply Transforms all the way down until a trishape is reached
		Element := aSourceBlock.Elements['Children'];
		if Assigned(Element) then begin
			ListChildBlocks := TList.Create;
			for i := 0 to Pred(Element.Count) do begin
				SubBlockSrc := TwbNifBlock(Element[i].LinksTo);
				if Assigned(SubBlockSrc) then begin
					if(ListChildBlocks.IndexOf(SubBlockSrc.Index) >= 0) then continue;
					Tlist(ListChildBlocks).Add(SubBlockSrc.Index);
					DetailedLog(#9#9'Processing Block: '+inttostr(SubBlockSrc.Index));
					CopyBlockAsChildOf(SubBlockSrc, aParentBlock);
				end;
			end;
			ListChildBlocks.Free;
		end;
	end;
end;

procedure RemoveSkin(aBlock: TwbNifBlock); //#FunctionNameRedFlag
//Removes skin from a loaded nif file, run on source before the rest.
var
	i: Integer;
	Element: TdfElement;
	SubBlock, SubSubBlock: TwbNifBlock;
	Nif: TwbNifFile; 
	ListChildBlocks: TList;
begin
	if not Assigned(aBlock) then
		exit;
	
	//Basically just remove anything related to skin
	Nif := aBlock.NifFile;
	if (aBlock.BlockType = 'BSTriShape') or (aBlock.BlockType = 'NiTriShape') or (aBlock.BlockType = 'NiTriStrips') then begin
		//Remove skin flag from shader		
		SubBlock := TwbNifBlock(aBlock.Elements['Shader Property'].LinksTo);
		if Assigned(SubBlock) then begin
			SubBlock.NativeValues['Shader Flags 1\Skinned'] := 0; // remove unecessary skinning on bows.
		end;
		
		//Remove skin from BSTriShape
		if aBlock.BlockType = 'BSTriShape' then begin
			SubBlock := TwbNifBlock(aBlock.Elements['Skin'].LinksTo);
			if Assigned(SubBlock) then begin
				aBlock.NativeValues['VertexDesc\VF\VF_SKINNED'] := 0; //Clear skinned flag
				aBlock.NativeValues['Data Size'] := 1; //Allow 'Vertex Data' and 'Triangles' Elements to be edited.
				TransferVertexData(Nif.Blocks[SubBlock.NativeValues['Skin Partition']], aBlock);
				
				//Check for all scale transforms.
				//On the first bone, hope all bones have the same scale here! cause seriously, what the heck could you do if they weren't?
				Element := SubBlock.Elements['Bones'];
				If Assigned(Element) then begin
					SubSubBlock :=  TwbNifBlock(Element[0].LinksTo);
					If Assigned(SubSubBlock) then begin
						aBlock.NativeValues['Transform\Scale'] := aBlock.NativeValues['Transform\Scale'] * SubSubBlock.NativeValues['Transform\Scale'];
					end;
				end;
				
				//In the Skin Data
				SubSubBlock := TwbNifBlock(SubBlock.Elements['Data'].LinksTo);
				If Assigned(SubSubBlock) then begin
					Element := SubSubBlock.Elements['Skin Transform'];
					If Assigned(Element) then begin
						aBlock.NativeValues['Transform\Scale'] := aBlock.NativeValues['Transform\Scale'] * Element.NativeValues['Scale'];
					end;
					
					//In the bone List of the Skin Data
					Element := SubSubBlock.Elements['Bone List'];
					If Assigned(Element) then begin
						Element := Element[0].Elements['Skin Transform'];
						If Assigned(Element) then begin
							aBlock.NativeValues['Transform\Scale'] := aBlock.NativeValues['Transform\Scale'] * Element.NativeValues['Scale'];
						end;
					end;
				end;
				
				Nif.Delete(SubBlock.NativeValues['Skin Partition']);
				Nif.Delete(SubBlock.NativeValues['Data']);
				Nif.Delete(SubBlock.Index);
			end;
		end
		//Remove skin from NiTriShape
		else begin
			SubBlock := TwbNifBlock(aBlock.Elements['Skin Instance'].LinksTo);
			if Assigned(SubBlock) then begin
				
				//Check for all scale transforms.
				//On the first bone, hope all bones have the same scale here! cause seriously, what the heck could you do if they weren't?
				Element := SubBlock.Elements['Bones'];
				If Assigned(Element) then begin
					SubSubBlock :=  TwbNifBlock(Element[0].LinksTo);
					If Assigned(SubSubBlock) then begin
						aBlock.NativeValues['Transform\Scale'] := aBlock.NativeValues['Transform\Scale'] * SubSubBlock.NativeValues['Transform\Scale'];
					end;
				end;
				
				//In the Skin Data
				SubSubBlock := TwbNifBlock(SubBlock.Elements['Data'].LinksTo);
				If Assigned(SubSubBlock) then begin
					Element := SubSubBlock.Elements['Skin Transform'];
					If Assigned(Element) then begin
						aBlock.NativeValues['Transform\Scale'] := aBlock.NativeValues['Transform\Scale'] * Element.NativeValues['Scale'];
					end;
					
					//In the bone List of the Skin Data
					Element := SubSubBlock.Elements['Bone List'];
					If Assigned(Element) then begin
						Element := Element[0].Elements['Skin Transform'];
						If Assigned(Element) then begin
							aBlock.NativeValues['Transform\Scale'] := aBlock.NativeValues['Transform\Scale'] * Element.NativeValues['Scale'];
						end;
					end;
				end;
				
				Nif.Delete(SubBlock.NativeValues['Skin Partition']);
				Nif.Delete(SubBlock.NativeValues['Data']);
				Nif.Delete(SubBlock.Index);
			end;
		end;
	end else begin //Non-trishape, FIND THE CHILDREN AND REMOVE THEIR SKIN!
		Element := aBlock.Elements['Children'];
		if Assigned(Element) then begin
			ListChildBlocks := TList.Create;
			for i := 0 to Pred(Element.Count) do begin
				SubBlock := TwbNifBlock(Element[i].LinksTo);
				if Assigned(SubBlock) then begin
					if(ListChildBlocks.IndexOf(SubBlock.Index) >= 0) then continue;
					Tlist(ListChildBlocks).Add(SubBlock.Index);
					DetailedLog(#9#9'Processing Block:'+inttostr(SubBlock.Index));
					RemoveSkin(SubBlock);
				end;
			end;
			ListChildBlocks.Free;
		end;
	end;
end;

procedure RenameScb(aBlock: TwbNifBlock);
var
	i:integer;
	Element: TdfElement;
	ChildBlock: TwbNifBlock;
	ListChildBlocks: TList;
begin
	aBlock.EditValues['Name'] := StringReplace(lowercase(aBlock.EditValues['Name']), 'scb', 'NonStickScb', rfIgnoreCase);
	
	Element := aBlock.Elements['Children'];
	If Assigned(Element) then begin
		ListChildBlocks := TList.Create;
		for i := 0 to Pred(Element.Count) do begin
			if(ListChildBlocks.IndexOf(Block.Index) >= 0) then continue;
			Tlist(ListChildBlocks).Add(Block.Index);
			ChildBlock := TwbNifBlock(Element[i].LinksTo);
			if Assigned(ChildBlock) then
				RenameScb(ChildBlock);
		end;
		ListChildBlocks.Free;
	end;
end;

procedure GenerateMeshes(FileSrc: string; PrnIndex: Integer; aNifSourceFile: TwbNifFile; abArchived: Boolean; aiWeaponType, aiWeaponCategory: integer; abSSEmesh: Boolean);
var
	ListChildBlocks, ListRootChildren: TList;
	i, ScbIndex: integer;
	Element: TdfElement;
	SubFolder, BaseFile, AllGUDMesh, TemplatePath, TemplateFile: string;
	DestBlock, SrcBlock, Block, SubBlock: TwbNifBlock;
	Nif: TwbNifFile;
begin
	//Get File & Subfolder paths to create the new files
	SubFolder := ExtractFilePath(FileSrc);
	ForceDirectories(DestinationPath + SubFolder);
	BaseFile := ExtractFileName(FileSrc);
	BaseFile := StringReplace(BaseFile, ExtractFileExt(FileSrc), '', rfIgnoreCase);
	
	//Template file, seperate versions for LE & SE
	if abSSEmesh then begin
		TemplatePath := ScriptsPath + SETemplatePath;
		DetailedLog(#9'Template: Special Edition');
	end
	else begin
		TemplatePath := ScriptsPath + LETemplatePath;
		aNifSourceFile.SpellTriangulate();
		DetailedLog(#9'Template: Legendary Edition');
	end;
	
	ScbIndex := -1;
	//Populate the list of child blocks, have to use these to Apply Transforms from non-trishapes to their kids
	ListRootChildren := TList.Create;
	Element := aNifSourceFile.Blocks[0].Elements['Children'];
	for i := 0 to Pred(Element.Count) do begin
		Block := TwbNifBlock(Element[i].LinksTo);
		If Assigned(Block) then begin
			If (ListRootChildren.IndexOf(Block.Index) = -1) then begin
				//Remove skin
				RemoveSkin(Block);
				Tlist(ListRootChildren).Add(Block.Index);
				If pos('scb', lowercase(Block.EditValues['Name'])) > 0 then
					ScbIndex := Block.Index; // Save Scb independently to also use in Scb mesh.
			end;
		end;
	end;
	
	//Rename Scabbard
	if (ScbIndex > 0) then begin
		RenameScb(aNifSourceFile.Blocks[ScbIndex]);
	end;
	bMeshHasController := false;
	
	//Apply Transforms for all non-shapes. EXCEPT BONES
	for i := 0 to Pred(ListRootChildren.Count) do begin
		SrcBlock := aNifSourceFile.Blocks[ListRootChildren[i]];
		//Don't do this for shapes, Don't remove Transforms of Shapes in case they need to be mirrored
		if not ((SrcBlock.BlockType = 'BSTriShape') or (SrcBlock.BlockType = 'NiTriShape') or (SrcBlock.BlockType = 'NiTriStrips')) then begin
			Element := SrcBlock.Elements['Controller'];
				If Assigned(Element) then begin
					Block := TwbNifBlock(Element.LinksTo);
					If Assigned(Block) then
						if(Block.BlockType = 'NiTransformController') then begin
							bMeshHasController := true;
							if not(bUseTemplates) then continue;
						end;
				end;
			Element := SrcBlock.Elements['Children'];
			If Assigned(Element) then begin
				ListChildBlocks := TList.Create;
				if pos('_MidBone', SrcBlock.EditValues['Name']) > 0 then begin
					for i := 0 to Pred(Element.Count) do begin
						Block := TwbNifBlock(Element[i].LinksTo);
						if Assigned(Block) then begin
							if(ListChildBlocks.IndexOf(Block.Index) >= 0) then continue;
							Tlist(ListChildBlocks).Add(Block.Index);
							ApplyTransformToChild(SrcBlock, Block, True);
						end;
					end;
				end else begin
					for i := 0 to Pred(Element.Count) do begin
						Block := TwbNifBlock(Element[i].LinksTo);
						if Assigned(Block) then begin
							if(ListChildBlocks.IndexOf(Block.Index) >= 0) then continue;
							Tlist(ListChildBlocks).Add(Block.Index);
							ApplyTransformToChild(SrcBlock, Block, False);
						end;
					end;
				end;
				ListChildBlocks.Free;
			end;
				
			if pos('_MidBone', SrcBlock.EditValues['Name']) > 0 then continue;
				
			SrcBlock.EditValues['Transform\Translation'] := '0.000000 0.000000 0.000000';
			SrcBlock.EditValues['Transform\Rotation']    := '0.000000 0.000000 0.000000';
			SrcBlock.EditValues['Transform\Scale']       := '1.000000';
		end;
	end;
	
	if bMeshHasController then begin
		if bUseTemplates then begin
			Log(#9+'Notification: '+FileSrc+' contains a NiTransformController block.'+#13#10#9#9+'It will not be transfered to a Static Display. Use Dynamic Display if this is meant to be animated while sheathed. Crossbows are not typically animated while sheathed.');
		end	else
			DetailedLog(#9'Mesh contains a NiTransformController, ApplyTransform for the block(s) leading to or using a NiTransformController have not been performed. This won''t matter unless it is a multi-part scabbard or needs to be mirrored (or maybe it''s something new).');
	end;

//MESH #1
	DetailedLog(#9'Attempting to generate AllGUD Mesh');
	
	//Create Mesh
		//Base display mesh, using DSR & AllGUD naming conventions.
	if aiWeaponCategory = iCatShield then
		AllGUDMesh := DestinationPath + SubFolder + BaseFile + 'OnBack.nif'
	else if aiWeaponCategory = iCatStaff then
		AllGUDMesh := DestinationPath + SubFolder + BaseFile + 'Right.nif'
	else
		AllGUDMesh := DestinationPath + SubFolder + BaseFile + 'Armor.nif';
		
	if bUseTemplates then begin
		TemplateFile := TemplatePath;
		CopyFileKst(TemplateFile, AllGUDMesh);
		PrnIndex := 1;
	end
	else begin
		aNifSourceFile.SaveToFile(AllGUDMesh);
	end;

	Nif := TwbNifFile.Create;
	Nif.LoadFromFile(AllGUDMesh);
	//Assign Prn
	Nif.Blocks[PrnIndex].EditValues['Data'] := RenamePrn(aiWeaponType, false);
	
	//Edit Blocks
	if bUseTemplates then begin//TEMPLATE
		//Copy the relevant Blocks
		for i := 0 to Pred(ListRootChildren.Count) do begin
			DetailedLog(#9#9'Processing Block:'+inttostr(ListRootChildren[i]));
			SrcBlock := aNifSourceFile.Blocks[ListRootChildren[i]];
			CopyBlockAsChildOf(SrcBlock, Nif.Blocks[0]);
		end;
	end;
	
	//Save and finish
	Nif.SaveToFile(AllGUDMesh);
	Nif.Free;
	DetailedLog(#9'Successfully generated ' + AllGUDMesh);
	Inc(countGenerated);

	
//MESH #2 Left-hand DSR-style one-hand melee and staff
	if (aiWeaponCategory = iCatOneHandMelee) or (aiWeaponCategory = iCatStaff) then begin
		DetailedLog(#9'Attempting to generate Left-Hand mesh');
		
		//Mirror the shapes
		if not ((aiWeaponCategory = iCatStaff) and not (bMirrorStaves)) then begin
			if not (bUseTemplates) and bMeshHasController then begin
				Log(#9'Warning: ' +FileSrc+ ' contains a NiTransformController and is attempting to mirror into a left-hand mesh. This may not go well. Post to AllGUD if you encounter one of these as it will probably need a custom patch.');
			end;
			DetailedLog(#9#9'Mirroring Weapon');
			for i := 0 to Pred(ListRootChildren.Count) do begin
				SrcBlock := aNifSourceFile.Blocks[ListRootChildren[i]];
				MirrorBlock(SrcBlock);
			end;
			//aNifSourceFile.SpellFaceNormals; //currently bugged in xEdit 4.0.3, will be needed in the future.
				//TODO: Wait for thies to be fixed.
			DetailedLog(#9#9'Mirroring Complete');
		end;
		
		//Create File
		AllGUDMesh := DestinationPath + SubFolder + BaseFile + 'Left.nif';
		
		if bUseTemplates then begin
			TemplateFile := TemplatePath;
			CopyFileKst(TemplateFile, AllGUDMesh);
		end
		else begin
			aNifSourceFile.SaveToFile(AllGUDMesh);
		end;
			
		Nif := TwbNifFile.Create;
		Nif.LoadFromFile(AllGUDMesh);
		//Assign Prn
		Nif.Blocks[PrnIndex].EditValues['Data'] := RenamePrn(aiWeaponType, True);
		
		//Edit Blocks
		if bUseTemplates then begin	//TEMPLATE
			//Copy main TriShapes
			for i := 0 to Pred(ListRootChildren.Count) do begin
				DetailedLog(#9#9'Processing Block: '+inttostr(ListRootChildren[i]));
				SrcBlock := aNifSourceFile.Blocks[ListRootChildren[i]];
				CopyBlockAsChildOf(SrcBlock, Nif.Blocks[0]);
			end;
		end;

		//Save and finish
		Nif.SaveToFile(AllGUDMesh);
		Nif.Free;
		DetailedLog(#9'Successfully generated ' + AllGUDMesh);
		Inc(countGenerated);

//MESH #3 Scabbard by itself for an empty left-hand sheath to use while weapons are drawn
		if (ScbIndex > 0) then begin
			DetailedLog(#9'Attempting to generate Left-Scabbard mesh');
			
			//Create File - ALWAYS TEMPLATE FOR SHEATH.NIF
			AllGUDMesh := DestinationPath + SubFolder + BaseFile + 'Sheath.nif';
			TemplateFile := TemplatePath;
			CopyFileKst(TemplateFile, AllGUDMesh);
			Nif := TwbNifFile.Create;
			Nif.LoadFromFile(AllGUDMesh);

			//Assign Prn
			Nif.Blocks[1].EditValues['Data'] := RenamePrn(aiWeaponType, True);

			//Copy the scabbard
			DetailedLog(#9#9'Processing Scabbard: '+inttostr(ScbIndex));
			SrcBlock := aNifSourceFile.Blocks[ScbIndex];
			CopyBlockAsChildOf(SrcBlock, Nif.Blocks[0]);

			//Save and finish
			Nif.SaveToFile(AllGUDMesh);
			Nif.Free;
			DetailedLog(#9'Successfully generated ' + AllGUDMesh);
			Inc(countGenerated)
		end;
	end
	
//MESH #4 Shield but translate z by -5 to adjust for backpacks/cloaks
	else if (aiWeaponCategory = iCatShield) then begin
		DetailedLog(#9'Attempting to generate Shield-Adjusted-for-Cloak mesh');

		//Create file
		AllGUDMesh := DestinationPath + SubFolder + BaseFile + 'OnBackClk.nif';
		
		if bUseTemplates then begin
			TemplateFile := TemplatePath;
			CopyFileKst(TemplateFile, AllGUDMesh);
		end
		else begin
			aNifSourceFile.SaveToFile(AllGUDMesh);
		end;
			
		Nif := TwbNifFile.Create;
		Nif.LoadFromFile(AllGUDMesh);
		
		//Assign Prn
		Nif.Blocks[PrnIndex].EditValues['Data'] := RenamePrn(aiWeaponType, false);
		
		//Edit Blocks
		if bUseTemplates then begin
			//Copy Shield models
			for i := 0 to Pred(ListRootChildren.Count) do begin
				DetailedLog(#9#9'Processing Block:'+inttostr(ListRootChildren[i]));
				SrcBlock := aNifSourceFile.Blocks[ListRootChildren[i]];
				//Translate Z of each Child block of Root by -5
				Element := SrcBlock.Elements['Transform'];
				If Assigned(Element) then
					SrcBlock.NativeValues['Transform\Translation\Z'] := SrcBlock.NativeValues['Transform\Translation\Z'] - 5;
				//Slothability said -4.5 was the most common one. original DSR meshes had -5 i believe?
				
				CopyBlockAsChildOf(SrcBlock, Nif.Blocks[0]);
			end;
		end;
		
		//Save and Finish
		Nif.SaveToFile(AllGUDMesh);
		Nif.Free;
		DetailedLog(#9'Successfully generated ' + AllGUDMesh);
		Inc(countGenerated);
	end;
	ListRootChildren.Free;
end;

//	PROCESS MESHES AND DECIDE ACTION
procedure ProcessMesh(aSourceFile: string; aNif: TwbNifFile; abArchived: boolean; iWeaponType: Integer);
var
	//aNif: TwbNifFile;
	Prn: string;
	Element: TdfElement;
	Block: TwbNifBlock;
	i, iWeaponCat, PrnIndex: integer;
	bDoPatch, bSEMesh: Boolean;
begin
	//Might take a while for big folders, but let's save whenever a file starts to get processed, so we know if it has a problem.
	slLog.SaveToFile(ScriptsPath+'AllGUD\Log.txt');

	//Iterate over all blocks in a nif file and identify Blocks of Interest(BSFadeNode, Prn, Scb, etc.)
	//TriShapes indexes are stored in the TList
	
	bSEMesh := (aNif.NifVersion >= nfSSE);
	//Find NiStringExtraData
	Element := aNif.Blocks[0].Elements['Extra Data List'];
	for i := 0 to Pred(Element.Count) do begin
		Block := TwbNifBlock(Element[i].LinksTo);
		if Assigned(Block) then begin
			if Block.BlockType = 'NiStringExtraData' then begin
				if SameText(Block.EditValues['Name'], 'Prn') then begin
					PrnIndex := Block.Index;
					
					if iWeaponType = InvalidWeapon then begin	//WeaponType was not assigned from Record, assign based on Prn
						Prn := Block.EditValues['Data'];	//Get Current
						if SameText(Prn, 'WeaponDagger') then begin
							iWeaponType := iTypeDagger;
						end
						else if SameText(Prn, 'WeaponSword') then begin
							iWeaponType := iTypeSword;
						end
						else if SameText(Prn, 'WeaponAxe') then begin
							iWeaponType := iTypeAxe;
						end
						else if SameText(Prn, 'WeaponMace') then begin
							iWeaponType := iTypeMace;
						end
						else if (SameText(Prn, 'WeaponStaff') and (pos('Right.nif',aSourceFile) = 0)) then begin
							iWeaponType := iTypeStaff;
							//Filter out meshes using DSR file naming convention.
							//Vanilla staves may have incorrect Prn, USP fixed Staff01
						end
						else if SameText(Prn, 'WeaponBack') then begin
							iWeaponType := iTypeTwoHandMelee;
						end
						else if SameText(Prn, 'WeaponBow') then begin
							iWeaponType := iTypeTwoHandRange;
						end
						else if SameText(Prn, 'SHIELD') then begin
							iWeaponType := iTypeShield;
						end;
					end else if iWeaponType = iTypeStaff then begin
						//Sword of amazement brought this up. Staves can't share with OneHand meshes since they both use '*Left.nif'
						//So One Hand Weapon Node in the Prn beats Keyword:WeapoTypeStaff
						Prn := Block.EditValues['Data'];	//Get Current
						if SameText(Prn, 'WeaponDagger') then begin
							iWeaponType := iTypeDagger;
						end
						else if SameText(Prn, 'WeaponSword') then begin
							iWeaponType := iTypeSword;
						end
						else if SameText(Prn, 'WeaponAxe') then begin
							iWeaponType := iTypeAxe;
						end
						else if SameText(Prn, 'WeaponMace') then begin
							iWeaponType := iTypeMace;
						end
					end;
					
					iWeaponCat := InvalidWeapon;
					if iWeaponType = InvalidWeapon then break;
					
					//Categorize the weapon
					if iWeaponType = iTypeSword then begin
						iWeaponCat := iCatOneHandMelee;
					end
					else if iWeaponType = iTypeDagger then begin
						iWeaponCat := iCatOneHandMelee;
					end
					else if iWeaponType = iTypeAxe then begin
						iWeaponCat := iCatOneHandMelee;
					end
					else if iWeaponType = iTypeMace then begin
						iWeaponCat := iCatOneHandMelee;
					end
					else if iWeaponType = iTypeStaff then begin
						iWeaponCat := iCatStaff;
					end
					else if iWeaponType = iTypeTwoHandMelee then begin
						iWeaponCat := iCatTwoHandMelee;
					end
					else if iWeaponType = iTypeTwoHandRange then begin
						iWeaponCat := iCatTwoHandRange;
					end
					else if iWeaponType = iTypeShield then begin
						iWeaponCat := iCatShield;
					end;
				end;
				break;
			end
		end;
	end;
	

	if iWeaponCat = InvalidWeapon then begin
		DetailedLog(#9'Skipped: Not a valid weapon or shield');
		Inc(countSkipped);
	end
	else begin
	
		if (iWeaponCat = iCatOneHandMelee) then begin
			DetailedLog(#9'Category: One-handed melee weapon');
			bDoPatch := bPatchOneHand;
		end
		else if iWeaponCat = iCatTwoHandMelee then begin
			DetailedLog(#9'Category: Two-handed melee weapon');
			bDoPatch := bPatchBack;
		end
		else if iWeaponCat = iCatShield then begin
			DetailedLog(#9'Category: Shield');
			bDoPatch := bPatchShields;
		end
		else if iWeaponCat = iCatTwoHandRange then begin
			DetailedLog(#9'Category: Ranged weapon');
			bDoPatch := bPatchBows;
		end
		else if iWeaponCat = iCatStaff then begin
			DetailedLog(#9'Category: Staff');
			bDoPatch := bPatchStaves;
		end;
		
		if bDoPatch then begin
		//	for i := 0 to Pred(Nif.BlocksCount) do begin
		//		Block := Nif.Blocks[i];
			//Now works off children of the root, to apply transforms down
			GenerateMeshes(aSourceFile, PrnIndex, aNif, abArchived, iWeaponType, iWeaponCat, bSEMesh);
			Inc(countPatched);
		end
		else begin
			DetailedLog(#9'Skipped: Script is not generating files for this weapontype');
			Inc(countSkipped);
		end;
	end;
	
	DetailedLog('Finished processing file'#13#10);
end;

procedure ProcessMeshes;
var
	TDirectory: TDirectory;
	SourceFiles: TStringDynArray;
	i, j, fileCount, fileCountInResources: integer;
	FilePathInData, FilePathInSource, ResourceUsed: string;
	MeshInfo: TStringList;
	Nif: TwbNifFile;
begin
	countPatched := 0;
	countSkipped := 0;
	countGenerated := 0;
	countFailed := 0;

	//TDirectory.GetFiles returns TStringDynArray, but we store filepaths from Plugins in a list because it can ignore duplicates. Dunno how to do that for DynArray.
	//So I decided to convert TStringDynArray to a TStringList, instead of duplicating the for loop for each option. To keep things clean.
	if bScanRecords then begin
		Log('Finished scanning.');
		if bModelsHadAlternateTextures then Log('One or more records contained an Alternate Texture, scroll up to find the plugins you should run the Alternate Texture script on.')
		else Log('No Alternate Textures have been detected. You do not need to run the Alternate Texture script.');
		fileCount := slModels.Count();
		Log(inttostr(fileCount) + ' unique models have been found in records.');
	end
	else begin
		Log('Scanning for .nif files in ' + SourcePath);
		SourceFiles := TDirectory.GetFiles(SourcePath, '*.nif', soAllDirectories);
		for i:=0 to Pred(Length(SourceFiles)) do begin
			if getKeyState(VK_ESCAPE) < 0 then begin
					Log(LineBreak);
					Log('''Esc'' key detected. Terminating Script.');
					bGenerateMeshes := False;
				exit;
			end;
			slModels.Add('0/' + SourceFiles[i]);
		end;
		fileCount := slModels.Count();
		Log(inttostr(fileCount) + ' models found in the Source Directory');
	end;
	SourcePathLength := Length(SourcePath);
	
	if fileCount = 0 then begin
		Log('No models have been found');
		if bScanRecords then
			Log(#9'Were any plugins actually selected? After loading files into xEdit, click a plugin in the list to select it'+
			#13#10#9+'This script does not operate on selected records, only selected plugins.')
		else
			Log(#9'Make sure the directory selected as your Input Folder is the one you meant to');
			slModels.Free;
		exit;
	end;
	
	Log(LineBreak);
	Log('Beginning mesh generation');
	If not bDetailedMessages then
		addmessage(#9'You do not have detailed messages enabled. To save time, progress messages will not appear, only errors or notifications'#13#10#9'If you want to view the progress, you can open the output folder to watch the meshes appear');
	Log(LineBreak);
	
	MeshInfo := TStringList.Create;
	MeshInfo.Delimiter := '/';
	MeshInfo.StrictDelimiter := true;
	
	for i := 0 to (fileCount-1) do begin
		//Stop if escape is pressed, it only checks between processing files, so key must be held down.
		if not bGenerateMeshes then begin
			Log(LineBreak);
			Log(inttostr(i) + ' meshes were processed. ' + inttostr(fileCount-i) + ' meshes have not been checked.');
			slModels.Free;
			MeshInfo.Free;
			exit;
		end;
		if getKeyState(VK_ESCAPE) < 0 then begin
			Log(LineBreak);
			Log('''Esc'' key detected. Terminating Script.');
			Log(inttostr(i) + ' meshes were processed. ' + inttostr(fileCount-i) + ' meshes have not been checked.');
			slModels.Free;
			MeshInfo.Free;
			exit;
		end;
		MeshInfo.DelimitedText := slModels[i];
		//MeshInfo[0] = WeaponType used by script
		//MeshInfo[1] = Source path
		if SameText(lowercase(ExtractFileExt(MeshInfo[1])), '.nif') then begin
			FilePathInData := copy(MeshInfo[1],Length(DataPath)+1,Length(MeshInfo[1]));
			FilePathInSource := copy(MeshInfo[1],SourcePathLength+1,Length(MeshInfo[1]));
			DetailedLog('Processing: .\' + FilePathInSource);
			Nif := TwbNifFile.Create;
			if bScanRecords and bCheckArchives and ResourceExists(FilePathInData) then begin //If scanning plugins then load from archives/data. ASSUMPTION: load order of loose files and archives will determine the source. That neither loose nor archive has priority over the other.
				ContainerChoice := TStringList.Create;
				fileCountInResources := inttostr(ResourceCount(FilePathInData, ContainerChoice));
				if fileCountInResources > 1 then begin
					ResourceUsed := StringReplace(ContainerChoice[Pred(fileCountInResources)], DataPath, '', rfIgnoreCase);
					If ResourceUsed = '' then ResourceUsed := 'Loose Files';
					DetailedLog(#9'Mesh is located in more than one resource. The version being used was found in: ' + ResourceUsed);
				end;
				try
					Nif.LoadFromResource(FilePathInData);
					ProcessMesh(FilePathInSource, Nif, True, strtoint(MeshInfo[0]));
				except
					Log('ERROR: Something went wrong when trying to process ' + FilePathInData + #13#10#9'Check the Log for details');
					slFailed.Add(#9+FilePathInData);
					Inc(countFailed);
				end;
				ContainerChoice.Free;
			end
			else if FileExists(MeshInfo[1]) then begin //Folder to folder should not check inside archives to prevent contamination.
				try
					Nif.LoadFromFile(MeshInfo[1]);
					ProcessMesh(FilePathInSource, Nif, False, strtoint(MeshInfo[0]));
				except
					Log('ERROR: Something went wrong when trying to process ' + FilePathInSource + #13#10#9'Check the Log for details');
					slFailed.Add(#9+FilePathInSource);
					Inc(countFailed);
				end;
			end
			else begin
				Log('Unable to locate: .\' + FilePathInSource + #13#10#9'Check the log for the associated record to find where this model came from. It may not have come with the mod or is packed in an unloaded archive.');
				slFailed.Add(#9+FilePathInSource);
				Inc(countFailed);
			end;
			Nif.Free
		end;
	end;
	
	slModels.Free;
	MeshInfo.Free;

end;

function Initialize: Integer;
var
	i: Integer;
	pixelRatio: single;
	window: TForm;
	rgInputSelect, rgProductionTechnique: TRadioGroup;
	rbPlugin, rbFolder, rbTemplate, rbSource: TRadioButton;
	gbWeaponTypes, gbSourceFolder, gbSourcePlugin, gbOutputFolder: TGroupBox;
	start, pathreset: TButton;
	lDataPathWarning, lTimeRequirementWarning, lStopHint: TLabel;
	checkOneHand, checkBack, checkBows, checkShields, checkStaves, checkMirrorStaves, enableMessages, scanRecords, checkArchives, alternateMirrorMethod: TCheckBox;
	indexCheckOne, indexCheckBack, indexCheckBow, indexCheckShield, indexCheckStaves, indexMirrorStaves, indexPlugin, indexArchive, indexTemplate, indexDetailed: integer;
begin
	ScriptProcessElements := [etFile];  // process function will only get the files the user selected, instead of everything.
	
	indexCheckOne := 2;
	indexCheckBack := 3;
	indexCheckBow := 4;
	indexCheckShield := 5;
	indexCheckStaves := 6;
	indexMirrorStaves := 7;
	indexPlugin := 8;
	indexArchive := 9;
	indexTemplate := 10;
	indexDetailed := 11;
	
	//Locate previously used paths.
	DataPathMeshes := DataPath + 'meshes\';
	SavPrefPath := ScriptsPath + PreferencesPath;
	LineBreak := '-------------------------';
	slLog := TStringList.Create;
	bGenerateMeshes := false;
	bModelsHadAlternateTextures := False;

	slModels := TStringList.Create;
	slModels.Sorted := True;
	slModels.Duplicates := dupIgnore;

	slFailed := TStringList.Create;
	slFailed.Sorted := True;
	
	slBlacklist := TStringList.Create;
	If FileExists(ScriptsPath+PluginBlacklist) then
		slBlacklist.LoadFromFile(ScriptsPath+PluginBlacklist);
	for i := 0 to Pred(slBlacklist.Count()) do begin
		if pos('//', slBlacklist[i]) > 0 then begin
			slBlacklist[i] := Trim(Copy(slBlacklist[i], 0, Pred(pos('//', slBlacklist[i]))));
			//Not delim since we're just discarding comments
		end;
	end;
	
	slPreferences := TStringList.Create;
	if FileExists(SavPrefPath) then begin
		slPreferences.LoadFromFile(SavPrefPath);
	end
	else begin
		ForceDirectories(ExtractFilePath(SavPrefPath));
		//Declare new paths
		slPreferences.Add(DataPath + 'meshes\');
		slPreferences.Add('');
		while slPreferences.Count < 12 do
			slPreferences.Add('True');
		slPreferences[indexMirrorStaves] := 'False';
		slPreferences[indexDetailed] := 'False';
	end;
		
	//Trim to size
	while slPreferences.Count < 12 do
	slPreferences.Add('');
	while slPreferences.Count > 12 do
	slPreferences.Delete(slPreferences.Count-1);

	pixelRatio := Screen.PixelsPerInch/96;
	//addmessage(floattostr(Screen.PixelsPerInch));
	
	window := TForm.Create(nil);
	try
		window.Caption := 'AllGUD Mesh Generator';
		window.Width := 512*pixelRatio;
		window.Height := 400*pixelRatio;
		window.Position := poScreenCenter;
		window.BorderStyle := bsDialog;
		
		//Weapon Filtering
		gbWeaponTypes := TGroupBox.Create(window);
		gbWeaponTypes.Parent := window;
		gbWeaponTypes.Top := 4*pixelRatio;
		gbWeaponTypes.Left := 8*pixelRatio;
		gbWeaponTypes.Caption := 'This script will generate meshes for..';
		gbWeaponTypes.Font.Size := 9;
		gbWeaponTypes.ClientHeight := 72*pixelRatio;
		gbWeaponTypes.ClientWidth := 236*pixelRatio;
		
		checkOneHand := TCheckBox.Create(window);
		checkOneHand.Parent := gbWeaponTypes;
		checkOneHand.Top := 16*pixelRatio;
		checkOneHand.Left := 8*pixelRatio;
		checkOneHand.Width := 98*pixelRatio;
		checkOneHand.Caption := ' One-hand melee';
		checkOneHand.Font.Size := 8;
		If SameText('True', slPreferences[indexCheckOne]) then
			checkOneHand.State := cbChecked;
		
		checkBack := TCheckBox.Create(window);
		checkBack.Parent := gbWeaponTypes;
		checkBack.Top := 32*pixelRatio;
		checkBack.Left := 8*pixelRatio;
		checkBack.Width := 98*pixelRatio;
		checkBack.Caption := ' Two-hand melee';
		checkBack.Font.Size := 8;
		If SameText('True', slPreferences[indexCheckBack]) then
			checkBack.State := cbChecked;
		
		checkShields := TCheckBox.Create(window);
		checkShields.Parent := gbWeaponTypes;
		checkShields.Top := 48*pixelRatio;
		checkShields.Left := 8*pixelRatio;
		checkShields.Width := 91*pixelRatio;
		checkShields.Caption := ' Shield-On-Back';
		checkShields.Font.Size := 8;
		If SameText('True', slPreferences[indexCheckShield]) then
			checkShields.State := cbChecked;

		checkBows := TCheckBox.Create(window);
		checkBows.Parent := gbWeaponTypes;
		checkBows.Top := 16*pixelRatio;
		checkBows.Left := 120*pixelRatio;
		checkBows.Width := 108*pixelRatio;
		checkBows.Caption := ' Bows && Crossbows';
		checkBows.Font.Size := 8;
		If SameText('True', slPreferences[indexCheckBow]) then
			checkBows.State := cbChecked;
		
		checkStaves := TCheckBox.Create(window);
		checkStaves.Parent := gbWeaponTypes;
		checkStaves.Top := 32*pixelRatio;
		checkStaves.Left := 120*pixelRatio;
		checkStaves.Width := 52*pixelRatio;
		checkStaves.Caption := ' Staves';
		checkStaves.Font.Size := 8;
		If SameText('True', slPreferences[indexCheckStaves]) then
			checkStaves.State := cbChecked;
			
		//Method of finding models
		rgInputSelect := TRadioGroup.Create(window);
		rgInputSelect.Parent := window;
		rgInputSelect.Top := 4*pixelRatio;
		rgInputSelect.Left := 250*pixelRatio;
		rgInputSelect.ClientHeight := 72*pixelRatio;
		rgInputSelect.ClientWidth := 250*pixelRatio;
		rgInputSelect.Caption := 'The script will look in..';
		rgInputSelect.Font.Size := 9;
		
		rbPlugin := TRadioButton.Create(window);
		rbPlugin.Parent := rgInputSelect;
		rbPlugin.Top := 20*pixelRatio;
		rbPlugin.Left := 8*pixelRatio;
		rbPlugin.Width:= 114*pixelRatio;
		rbPlugin.Caption := 'The Selected Plugins';
		rbPlugin.Font.Size := 8;
		If SameText('True', slPreferences[indexPlugin]) then
			rbPlugin.Checked := cbChecked;
		
		checkArchives := TCheckBox.Create(window);
		checkArchives.Parent := rgInputSelect;
		checkArchives.Top := 20*pixelRatio;
		checkArchives.Left := 128*pixelRatio;
		checkArchives.Width := 104*pixelRatio;
		checkArchives.Caption := 'Archives (readme)';
		checkArchives.Font.Size := 8;
		checkArchives.Hint :=
			'Loose Files WILL win'#13#10
			'If more than one version of the file exists in your archives, it will be logged as a detail.'#13#10
			'Folder to folder will not check archives to prevent unforseen conflicts';
		checkArchives.ShowHint := true;
		If SameText('True', slPreferences[indexArchive]) then
			checkArchives.State := cbChecked;
		
		rbFolder := TRadioButton.Create(window);
		rbFolder.Parent := rgInputSelect;
		rbFolder.Top := 44*pixelRatio;
		rbFolder.Left := 8*pixelRatio;
		rbFolder.Width:= 215*pixelRatio;
		rbFolder.Caption := 'The Input Folder (Will not check Archives)';
		rbFolder.Font.Size := 8;
		If not SameText('True', slPreferences[indexPlugin]) then
			rbFolder.Checked := cbChecked;
		
		//Input Folder selection
		gbSourceFolder := TGroupBox.Create(window);
		gbSourceFolder.Parent := window;
		gbSourceFolder.Top := 80*pixelRatio;
		gbSourceFolder.Left := 8*pixelRatio;
		gbSourceFolder.ClientHeight := 90*pixelRatio;
		gbSourceFolder.ClientWidth := 492*pixelRatio;
		gbSourceFolder.Caption := 'Input Folder';
		gbSourceFolder.Font.Size := 12;
		
		SourcePathInput := TEdit.Create(window);
		SourcePathInput.Parent := gbSourceFolder;
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
		pathreset.Parent := gbSourceFolder;
		pathreset.Top := 20*pixelRatio;
		pathreset.Left := 411*pixelRatio;
		pathreset.Caption := 'Data Folder';
		pathreset.Font.Size := 8;
		pathreset.OnClick := ResetDataPath;

		lTimeRequirementWarning := TLabel.Create(window);
		lTimeRequirementWarning.Parent := gbSourceFolder;
		lTimeRequirementWarning.Top := 46*pixelRatio;
		lTimeRequirementWarning.Left := 8*pixelRatio;
		lTimeRequirementWarning.Caption :=
			'If you are running xEdit through a Mod Manager, using your Skyrim Data directory will scan all'#13#10
			'    loose files for weapons and shields. This could take a very long time.'#13#10
			'If scanning Plugins, you can skip this selection, as the data path will automatically be used'
			;
		lTimeRequirementWarning.Font.Size := 8;
		
		//Output Folder selection
		gbOutputFolder := TGroupBox.Create(window);
		gbOutputFolder.Parent := window;
		gbOutputFolder.Top := 175*pixelRatio;
		gbOutputFolder.Left := 8*pixelRatio;
		gbOutputFolder.ClientHeight := 90*pixelRatio;
		gbOutputFolder.ClientWidth := 492*pixelRatio;
		gbOutputFolder.Caption := 'Output Meshes Folder';
		gbOutputFolder.Font.Size := 12;

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

		lDataPathWarning := TLabel.Create(window);
		lDataPathWarning.Parent := gbOutputFolder;
		lDataPathWarning.Top := 46*pixelRatio;
		lDataPathWarning.Left := 16*pixelRatio;
		lDataPathWarning.Caption :=
			'Do not use your Skyrim Data Directory unless you know what you''re doing.'#13#10
			'  Path should end with \meshes\ when scanning plugins.'#13#10
			#9'It is recommended you create a new folder in your mod directory for your output!';
		lDataPathWarning.Font.Size := 8;
		
		//Method of generating models
		rgProductionTechnique := TRadioGroup.Create(window);
		rgProductionTechnique.Parent := window;
		rgProductionTechnique.Top := 270*pixelRatio;
		rgProductionTechnique.Left := 8*pixelRatio;
		rgProductionTechnique.ClientHeight := 48*pixelRatio;
		rgProductionTechnique.ClientWidth := 492*pixelRatio;
		rgProductionTechnique.Caption := 'The script will produce a... (Mouseover options for details)';
		rgProductionTechnique.Font.Size := 9;
		
		rbTemplate := TRadioButton.Create(window);
		rbTemplate.Parent := rgProductionTechnique;
		rbTemplate.Top := 20*pixelRatio;
		rbTemplate.Left := 30*pixelRatio;
		rbTemplate.Width:= 242*pixelRatio;
		rbTemplate.Caption := 'Static Display (Recommended for Most Meshes)';
		rbTemplate.Font.Size := 8;
		If SameText('True', slPreferences[indexTemplate]) then
			rbTemplate.Checked := cbChecked;
		rbTemplate.Hint :=
			'A Static Display copies only the most necessary blocks into a template file to simply display a sheathed weapon'#13#10
			'This removes things like Intermediary blocks, Blood Splatter blocks, Physics Data, and Animated Parts, which normally aren''t necessary for displays.'#13#10
			'There are of course exceptions, like the exceptional Eyecandy Staff of Magnus or Elianora Master Wizard''s Staff'#13#10
			'Until HDT equipment is updated for AllGUD nodes, you''ll likely want MOST of your weapons to be static, with a few exceptions for Dynamic'#13#10#10
			'The main Benefits of this option are:'#13#10
			'Minimal file size. Which, given the number of meshes that you have to generate, can be quite the difference'#13#10
			'Guaranteed Perfect Mirroring. NiTransformControllers will not produce the expected end-result when using the ApplyTransform method of Mirroring Shapes';
		rbTemplate.ShowHint := true;
		
		rbSource := TRadioButton.Create(window);
		rbSource.Parent := rgProductionTechnique;
		rbSource.Top := 20*pixelRatio;
		rbSource.Left := 300*pixelRatio;
		rbSource.Width:= 92*pixelRatio;
		rbSource.Caption := 'Dynamic Display';
		rbSource.Font.Size := 8;
		If not SameText('True', slPreferences[indexTemplate]) then
			rbSource.Checked := cbChecked;
		rbSource.Hint :=
			'A Dynamic Display makes as few edits as necessary to convert to AllGUD format, generally resulting in a larger than necessary file size.'#13#10
			'The most notable blocks which are not removed in a Dynamic Display are:'#13#10
			'NiTransformController Blocks for moving parts, see Eyecandy Staff of Magnus or Elianora Master Wizard''s Staff'#13#10
			'bhkCollisionObject/bhkRigidBody Blocks, which are used for physics including HDT (correct me if I''m wrong)';
		rbSource.ShowHint := true;
		
		//Stop Hint
		lStopHint := TLabel.Create(window);
		lStopHint.Parent := window;
		lStopHint.Top := 320*pixelRatio;
		lStopHint.Left := 185*pixelRatio;
		lStopHint.Caption := 'Hold ''Esc'' at anytime to stop';

		//Mirror Left Staves
		checkMirrorStaves := TCheckBox.Create(window);
		checkMirrorStaves.Parent := window;
		checkMirrorStaves.Top := 340*pixelRatio;
		checkMirrorStaves.Left := 8*pixelRatio;
		checkMirrorStaves.Width := 105*pixelRatio;
		checkMirrorStaves.Caption := ' Mirror Left Staves';
		checkMirrorStaves.Font.Size := 8;
		If SameText('True', slPreferences[indexMirrorStaves]) then
			checkMirrorStaves.State := cbChecked;
		checkMirrorStaves.Hint := 'Check your Left-hand Staff in game to determine if you should check this box.';
		checkMirrorStaves.ShowHint := true;
		
		//Start Button
		start := TButton.Create(window);
		start.Parent := window;
		start.Top := 340*pixelRatio;
		start.Left := 216*pixelRatio; //window.Width / 2 - 40;
		start.Caption := 'Start';
		start.Font.Size := 10;
		start.ModalResult := mrOk;
		
		//Enable Message Spam?
		enableMessages := TCheckBox.Create(window);
		enableMessages.Parent := window;
		enableMessages.Top := 340*pixelRatio;
		enableMessages.Left := 350*pixelRatio;
		enableMessages.width := 143*pixelRatio;
		enableMessages.Caption := ' Enable Detailed Messages';
		If SameText('True', slPreferences[indexDetailed]) then
			enableMessages.Checked := cbChecked;
		enableMessages.Hint := 'Detailed messages will slow the process. All activity will still be logged.';
		enableMessages.ShowHint := true;
		
		window.ActiveControl := start;
		
		if window.ShowModal = mrOk then begin
			bGenerateMeshes := true;
			DestinationPath := IncludeTrailingBackslash(DestinationPathInput.Text);
			SourcePath := IncludeTrailingBackslash(SourcePathInput.Text);
			
			addmessage(#13);
			Log(wbAppName + ' xEdit version: ' + inttostr(wbVersionNumber));
			
			bDetailedMessages := enableMessages.Checked;
			if bDetailedMessages then begin
				slPreferences[indexDetailed] := 'True';
			end else begin
				slPreferences[indexDetailed] := 'False';
				addmessage('Detailed messages are not enabled. Hold ''Esc'' at anytime to stop');
			end;
			
			bPatchOneHand := checkOneHand.Checked;
			if bPatchOneHand then begin
				slPreferences[indexCheckOne] := 'True';
				Log('  will process One-hand melee meshes');
			end else begin
				slPreferences[indexCheckOne] := 'False';
				Log('  will skip One-hand meshes');
			end;
			
			bPatchBack := checkBack.Checked;
			if bPatchBack then begin
				slPreferences[indexCheckBack] := 'True';
				Log('  will process Two-hand melee meshes');
			end else begin
				slPreferences[indexCheckBack] := 'False';
				Log('  will skip Two-hand meshes');
			end;
			
			bPatchBows := checkBows.Checked;
			if bPatchBows then begin
				slPreferences[indexCheckBow] := 'True';
				Log('  will process Ranged meshes');
			end else begin
				slPreferences[indexCheckBow] := 'False';
				Log('  will skip Ranged meshes');
			end;
			
			bPatchShields := checkShields.Checked;
			if bPatchShields then begin
				slPreferences[indexCheckShield] := 'True';
				Log('  will process Shield meshes');
			end else begin
				slPreferences[indexCheckShield] := 'False';
				Log('  will skip Shield meshes');
			end;
			
			bPatchStaves := checkStaves.Checked;
			if bPatchStaves	then begin
				slPreferences[indexCheckStaves] := 'True';
				Log('  will process Staff meshes');
			end else begin
				slPreferences[indexCheckStaves] := 'False';
				Log('  will skip Staff meshes');
			end;
			
			bMirrorStaves := checkMirrorStaves.Checked;
			if bMirrorStaves then begin
				slPreferences[indexMirrorStaves] := 'True';
				Log('  will mirror Left Staff Meshes');
			end else begin
				slPreferences[indexMirrorStaves] := 'False';
				Log('  will not mirror Left Staff Meshes');
			end;
			
			bUseTemplates := rbTemplate.Checked;
			if bUseTemplates then begin
				slPreferences[indexTemplate] := 'True';
				Log('  will create Static displays from the template');
			end else begin
				slPreferences[indexTemplate] := 'False';
				Log('  will create Dynamic displays by duplicating the source');
			end;
			
			bCheckArchives := checkArchives.Checked;
			if bCheckArchives then begin
				slPreferences[indexArchive] := 'True';
			end else begin
				slPreferences[indexArchive] := 'False';
			end;
			
			bScanRecords := rbPlugin.Checked;
			if bScanRecords then begin
				slPreferences[indexPlugin] := 'True';
				if bCheckArchives then begin
					Log('  will scan the selected Plugins for model paths in .bsa Archives and Loose Files');
				end else begin
					Log('  will scan the selected Plugins for model paths in Loose Files only');
				end;
			end else begin
				slPreferences[indexPlugin] := 'False';
				Log('  will scan for .nifs in ' + SourcePath);
			end;
			
			slPreferences[indexSourcePath] := SourcePath;
			slPreferences.SaveToFile(SavPrefPath); //Save current settings before possible error
			
			if not ForceDirectories(DestinationPath) then begin
				Log('ERROR: Output Directory is not a valid destination'#13#10'It is recommended you create a new empty mod and set that as your output.'#13#10);
				bGenerateMeshes := false;
				exit;
			end;
			slPreferences[indexDestPath] := DestinationPath;
			slPreferences.SaveToFile(SavPrefPath); //Destination is valid, save it, prevents first-time users from getting a '\' as output in future cases.
			Log( '  will create meshes in: ' + DestinationPath);
			
			if bScanRecords then begin
				Log(LineBreak);
				Log('Starting scan of selected plugins for ARMO, WEAP, and STAT records');
				SourcePath := DataPathMeshes;
			end;
			
			//Save manual path entries so people don't have to use the selection dialog.
		end;
	finally
		slPreferences.Free;
		window.Free;
	end;
end;

function Process(e: IInterface): Integer;
var
	bAddRecord: boolean;
	i, j, iRecordCount, iType: Integer;
	BodySlot: Cardinal;
	s, k, sAA: string;
	rec, group, kwda, recAA, ModS: IInterface;
begin
	if not bScanRecords then exit; //Don't process if using folder instead.
	if not bGenerateMeshes then exit;	//Stop processing records if 'ESC' was pressed.
	if slBlacklist.Find(GetFileName(e),i) then begin
		Log(LineBreak);
		Log(GetFileName(e) + ' is on the plugin blacklist. An alternate patch may be available.'#13#10#9'The Blacklist should contain more details. It can be found at Edit Scripts\'+PluginBlacklist);
		DetailedLog(LineBreak);
		exit;
	end;
	Log(LineBreak);
	Log(GetFileName(e)+' is being checked for WEAP and ARMO[Shield] records');
	DetailedLog(LineBreak);
	
	//Check WEAP records
	group := GroupBySignature(e, 'WEAP');
	iRecordCount := Pred(ElementCount(group));
	Log(#9 + InttoStr(iRecordCount + 1) + ' WEAP records found.');
	DetailedLog(LineBreak);
	for i := 0 to iRecordCount do begin
		if getKeyState(VK_ESCAPE) < 0 then begin
				Log(LineBreak);
				Log('''Esc'' key detected. Terminating Script.');
				bGenerateMeshes := false;
			exit;
		end;
		bAddRecord := false;
		rec := WinningOverride(ElementByIndex(group, i));
		
		//Check for weapon-type by keyword. Is there a more efficient way?
		//Thinking about replacing this with AnimationType.
		kwda := ElementBySignature(rec, 'KWDA');
		for j:= 0 to Pred(ElementCount(kwda)) do begin
			k := GetEditValue(ElementByIndex(kwda, j));
			if SameText(k,'WeapTypeDagger [KYWD:0001E713]') then begin
				if bPatchOneHand then bAddRecord := true;
				iType := iTypeDagger;
				break;
			end
			else if SameText(k, 'WeapTypeSword [KYWD:0001E711]') then begin
				if bPatchOneHand then bAddRecord := true;
				iType := iTypeSword;
				break;
			end
			else if SameText(k, 'WeapTypeWarAxe [KYWD:0001E712]') then begin
				if bPatchOneHand then bAddRecord := true;
				iType := iTypeAxe;
				break;
			end
			else if SameText(k, 'WeapTypeMace [KYWD:0001E714]') then begin
				if bPatchOneHand then bAddRecord := true;
				iType := iTypeMace;
				break;
			end
			else if SameText(k, 'WeapTypeGreatsword [KYWD:0006D931]') then begin
				if bPatchBack then bAddRecord := true;
				iType := iTypeTwoHandMelee;
				break;
			end
			else if SameText(k, 'WeapTypeWarhammer [KYWD:0006D930]') then begin
				if bPatchBack then bAddRecord := true;
				iType := iTypeTwoHandMelee;
				break;
			end
			else if SameText(k, 'WeapTypeBattleaxe [KYWD:0006D932]') then begin
				if bPatchBack then bAddRecord := true;
				iType := iTypeTwoHandMelee;
				break;
			end
			else if SameText(k, 'WeapTypeBow [KYWD:0001E715]') then begin
				//crossbows also have this keyword
				if bPatchBows then bAddRecord := true;
				iType := iTypeTwoHandRange;
				break;
			end
			else if SameText(k, 'WeapTypeStaff [KYWD:0001E716]') then begin
				if bPatchStaves then bAddRecord := true;
				iType := iTypeStaff;
				break;
			end
		end;
		
		//Backup animation check if no vanilla keyword? Could I use kywd edit value instead?
		if not bAddRecord then begin
			k := GetElementEditValues(rec, 'DNAM\Animation Type');
			if (k = 'OneHandSword') then begin
				//currently required for: SSM Spears
				if bPatchOneHand then bAddRecord := true;
				iType := iTypeSword;
			end;
		end;
		
		
		//Valid weapon type
		//DNAM\Flags\0x80\ is the non-playable flag for weapons
		//Doesn't filter out the last remaining Dummy Weapons that don't have this flag.
		if bAddRecord and (GetElementNativeValues(rec, 'DNAM\Flags\0x80') = 0) then begin
			s := GetElementEditValues(rec, 'Model\MODL');
			If pos('meshes\', lowercase(s)) = 1 then
				s := StringReplace(lowercase(s), 'meshes\', '', rfIgnoreCase);
			DetailedLog(#9 + '[' + IntToHex(FormID(rec), 8) + '] has model: '+ s);
			slModels.Add(InttoStr(iType) + '/' + DataPathMeshes+s);
			
			ModS := ElementByPath(rec, 'Model\MODS');
			if Assigned(ModS) then begin
				Log(#9#9 + '[' + IntToHex(FormID(rec), 8) + '] has an Alternate Texture. Please run AllGUD''s AlternateTextureModelsplosion script script on this plugin.');
				bModelsHadAlternateTextures := true;
			end;
		end;
	end;
	DetailedLog(LineBreak);
	
	//Check ARMO records for shields
	if bPatchShields then begin
		group := GroupBySignature(e, 'ARMO');
		iRecordCount := Pred(ElementCount(group));
		Log(#9+ InttoStr(iRecordCount + 1) + ' ARMO records found.');
		DetailedLog(LineBreak);
		for i := 0 to iRecordCount do begin
			if getKeyState(VK_ESCAPE) < 0 then begin
					Log(LineBreak);
					Log('''Esc'' key detected. Terminating Script.');
					bGenerateMeshes := false;
				exit;
			end;
			//Skip anything that isn't type Shield or anything that is Non-playable.
			rec := ElementByIndex(group, i);
			k := GetElementEditValues(rec, 'ETYP');
			
			//SE and LE plugins have different non-playable flags, check both.
			if SameText(k, 'Shield [EQUP:000141E8]') and (GetElementNativeValues(rec,'Record Header\Record Flags\0x00000004') = 0) and (GetElementNativeValues(rec, 'BODT\General Flags\0x00000010') = 0) then begin
				{//Future versions of AllGUD will only use the AA model.
				s := GetElementEditValues(rec, 'Male world model\MOD2');
				iType := iCatShield;
				slModels.Add(InttoStr(iType) + '/' + DataPathMeshes+s);
				DetailedLog(#9 + '[' + IntToHex(FormID(rec), 8) +'] has model: '+ s);
				}
				recAA := WinningOverride(LinksTo(ElementByPath(rec, 'Armature\MODL')));
				sAA := GetElementEditValues(recAA, 'Male world model\MOD2');
				If pos('meshes\', lowercase(sAA)) = 1 then
					sAA := StringReplace(lowercase(sAA), 'meshes\', '', rfIgnoreCase);
				iType := iTypeShield;
				slModels.Add(InttoStr(iType) + '/' + DataPathMeshes+sAA);
				DetailedLog(#9 + '[' + IntToHex(FormID(recAA), 8) +'] has model: '+ sAA);

				ModS := ElementByPath(recAA, 'Male world model\MO2S');
				if Assigned(ModS) then begin
					Log(#9#9 + '[' + IntToHex(FormID(recAA), 8) + '] has an Alternate Texture. Please run AllGUD''s AlternateTextureModelsplosion script on this plugin.');
					bModelsHadAlternateTextures := true;
				end;
			end;
		end;
	end
	else Log(#9'ARMO records will be skipped.');
	
	//Check STAT records (Rare case, maintain a list of plugins where it matters?)
	if SameText(GetFileName(e),'Unique Uniques.esp') or SameText(GetFileName(e),'UniqueWeaponsRedone.esp') then begin
		group := GroupBySignature(e, 'STAT');
		iRecordCount := Pred(ElementCount(group));
		Log(#9 + InttoStr(iRecordCount + 1) + ' STAT records found.');
		DetailedLog(LineBreak);
		for i := 0 to iRecordCount do begin
			if getKeyState(VK_ESCAPE) < 0 then begin
					Log(LineBreak);
					Log('''Esc'' key detected. Terminating Script.');
					bGenerateMeshes := false;
				exit;
			end;
			rec := ElementByIndex(group, i);
			s := GetElementEditValues(rec, 'Model\MODL');
			if (pos('weapon', lowercase(s)) > 0) or ((pos('armor', lowercase(s)) > 0)) then begin
			
				If pos('meshes\', lowercase(s)) = 1 then
					s := StringReplace(lowercase(s), 'meshes\', '', rfIgnoreCase);
				DetailedLog(#9 + '[' + IntToHex(FormID(rec), 8) + '] has model: '+ s);
				iType := InvalidWeapon;
				slModels.Add(InttoStr(iType) + '/' + DataPathMeshes+s);
			end;
		end;
		DetailedLog(LineBreak);
	end;
end;

function Finalize: Integer;
begin
	slBlacklist.Free;
	if not bGenerateMeshes then begin
		slModels.Free;
		slFailed.Free;
		slLog.SaveToFile(ScriptsPath+'AllGUD\Log.txt');
		addmessage(#13#10'The log has been saved to ' + ScriptsPath + 'AllGUD\Log.txt'#13#10);
		slLog.Free;
		exit;
	end;
	//AddMessage(slModels.Text);
	Log(LineBreak);
	ProcessMeshes;
	Log(LineBreak);
	
	//List info cause people are sure to want it.
	if countPatched = 1 then
		Log(inttostr(countPatched) + ' weapon or shield has been patched')
	else
		Log(inttostr(countPatched) + ' weapons and/or shields have been patched');
	
	if countSkipped = 1 then
		Log(inttostr(countSkipped) + ' mesh was skipped')
	else
		Log(inttostr(countSkipped) + ' meshes were skipped');
	
	if countGenerated = 1 then
		Log(inttostr(countGenerated) + ' mesh has been generated'#13#10)
	else
		Log(inttostr(countGenerated) + ' meshes have been generated'#13#10);
	
	if countFailed > 0 then begin
		if countFailed = 1 then
			Log(inttostr(countFailed) + ' file failed to generate meshes. Check the Log for Details')
		else 
			Log(inttostr(countFailed) + ' files failed to generate meshes. Check the Log for Details');
		Log(#10 + slFailed.Text);
		Log('You can search the file path in the log to find the associated record. If you need help, upload the log to your preferred cloud service/file hosting site, and make a bug report. It is incredibly hard to diagnose issues without the Log');
	end;
	
	if bModelsHadAlternateTextures then Log('REMINDER: Run the AlternateTextureModelsplosion script for plugins containing records flagged during the scanning process');
	
	slFailed.Free;
	slLog.SaveToFile(ScriptsPath+'AllGUD\Log.txt');
	addmessage(#13#10'The Log has been saved to ' + ScriptsPath + 'AllGUD\Log.txt'#13#10#9'If you encounter an error in-game, make sure to upload this somewhere, like on a cloud-drive'#13#10);

	slLog.Free;
	Result := 1;
	//Now go upload some screenshots to bring in more converts.
end;

end.
