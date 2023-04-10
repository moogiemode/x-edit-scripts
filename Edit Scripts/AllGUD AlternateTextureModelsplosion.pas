{
	NO UI, READ THE README FOR INSTRUCTIONS
	This script was created to patch AllGUD & Alternate Texture'd Shields
	Script was adapted from 'Check for invalid alternate textures.pas'
	
	It would be impractical to implement alternate texture support for AllGUD's one-record style of armor display.
	Therefore, a unique model for each painted shield texture option must be created.
}
unit AllGUDAlternateTextures;

var
  DataPathMeshes, ModelPathRemovePrefix, ModelPathRemoveSuffix: String;
  PatchedPlugin: IwbFile;
  bForceExit: boolean;

procedure CopyFileKst(aSourcePath, aDestinationPath: string);
var
SourceF, DestF: TFileStream;
begin
	//Copy file from source
	If FileExists(aSourcePath) then begin
		SourceF := TFileStream.Create(aSourcePath, fmOpenRead);
	end
	else begin
		addmessage(aSourcePath + ' Does NOT exist')
	end;
	
	try
		DestF := TFileStream.Create(aDestinationPath, fmCreate);
	except
		Log('Destination does not exist');
		SourceF.Free;
	finally
	end;
	DestF.CopyFrom(SourceF, SourceF.Size);
	SourceF.Free;
	DestF.Free;
end;

procedure GenerateAlternateMesh(e: IInterface; aMODL, aMODS: string; abFemale:Boolean);
var
  modl, mods, tex, texset, texsettex, femMod: IInterface;
  i, j, idx, iResourceIndex, iThreeDIndex, iThreeDCount: integer;
  model, node, newFile, newTexturePath: string;
  ContainerChoice: TStringList;
  ListChoppingBlock: TList;
  Nif: TwbNifFile;
  Block, ShaderBlock, TextureBlock: TwbNifBock;
  BlockTextures: TdfElement;
  newElement: IwbElement;
begin
	//Has model
  modl := ElementByPath(e, aMODL);
  if not Assigned(modl) then
    Exit;
	//Has alternate texture
  mods := ElementByPath(e, aMODS);
  if not Assigned(mods) then
    Exit;

	//model is a .nif
  model := GetEditValue(modl);
  if not SameText(ExtractFileExt(model), '.nif') then
    Exit;
    
	//Extracted the file
  if not ResourceExists('meshes\'+model) then begin
    AddMessage(FullPath(modl) + ' file not found: ' + model);
    Exit;
  end;
  
	addmessage('Alternate Texture set found for ['+IntToHex(FormID(e), 8)+'] in ' + GetFileName(GetFile(e)));
	Nif := TwbNifFile.Create;
	Nif.LoadFromResource('meshes\'+model);
	ListChoppingBlock := TList.Create;
		
	for i := 0 to Pred(ElementCount(mods)) do begin
		//1: Get all the vaiables
		tex := ElementByIndex(mods, i);
		iThreeDIndex := GetElementEditValues(tex, '3D Index');
		iThreeDCount := 0;
		texset := LinksTo((ElementByName(tex, 'New Texture')));
		texsettex := ElementByName(texset, 'Textures (RGB/A)');

		//2: Load the nif
		newFile := ExtractFilePath(model) + StringReplace(StringReplace(EditorID(e), ModelPathRemovePrefix, '', rfIgnoreCase), ModelPathRemoveSuffix, '', rfIgnoreCase) + '.nif';
		If abFemale then
			newFile := ExtractFilePath(model) + StringReplace(StringReplace(EditorID(e), ModelPathRemovePrefix, '', rfIgnoreCase), ModelPathRemoveSuffix, '', rfIgnoreCase) + 'Female.nif';

		//3: Find the associated BSShaderTextureSet
		for j := 0 to Pred(Nif.BlocksCount) do begin
			Block := Nif.Blocks[j];
			if (Block.BlockType = 'BSTriShape') or (Block.BlockType = 'NiTriShape') or (Block.BlockType = 'NiTriStrips') then begin
				If (iThreeDCount = iThreeDIndex) then begin
					//4: Change the newModel's texture set at the index
					//4a: Exception, hide the shape if it's a null texture set, probably not totally correct but I haven't found one that I can really test this on.
					If(GetElementEditValues(texset,'EDID') = 'NullTextureSet') then begin
						//TList(ListChoppingBlock).Add(Block.Index);
						Block.NativeValues['Flags'] := 1;
						ForceDirectories(ExtractFilePath(DataPathMeshes + newFile));
						Nif.SaveToFile(DataPathMeshes + newFile);
						break;
					end;
					ShaderBlock := TwbNifBlock(Block.Elements['Shader Property'].LinksTo);
					If(ShaderBlock.BlockType = 'BSEffectShaderProperty') then begin
						//4b: BSEffectShaderProperty, they only have 2 textures and the only one I saw using this was a NullTextureSet soooo have to test later when I encounter a real one.
						ShaderBlock.EditValues['Source Texture'] := GetElementEditValues(texsettex, 'TX00 - Difuse');
					end else begin
						//4c: BSLightingShaderProperty
						TextureBlock := TwbNifBlock(ShaderBlock.Elements['Texture Set'].LinksTo);
						BlockTextures := TextureBlock.Elements['Textures'];
						
						try	//Not ever texture block has all 8 paths, try them to avoid error if it does not
							newTexturePath := GetElementEditValues(texsettex, 'TX00 - Difuse');
							If not SameText (newTexturePath, '') then
								newTexturePath := 'textures\'+newTexturePath;
							BlockTextures[0].EditValue := newTexturePath;
							
							newTexturePath := GetElementEditValues(texsettex, 'TX01 - Normal/Gloss');
							If not SameText (newTexturePath, '') then
								newTexturePath := 'textures\'+newTexturePath;
							BlockTextures[1].EditValue := newTexturePath;
							
							newTexturePath := GetElementEditValues(texsettex, 'TX02 - Environment Mask/Subsurface Tint');
							If not SameText (newTexturePath, '') then
								newTexturePath := 'textures\'+newTexturePath;
							BlockTextures[2].EditValue := newTexturePath;
							
							newTexturePath := GetElementEditValues(texsettex, 'TX03 - Glow/Detail Map');
							If not SameText (newTexturePath, '') then
								newTexturePath := 'textures\'+newTexturePath;
							BlockTextures[3].EditValue := newTexturePath;
							
							newTexturePath := GetElementEditValues(texsettex, 'TX04 - Height');
							If not SameText (newTexturePath, '') then
								newTexturePath := 'textures\'+newTexturePath;
							BlockTextures[4].EditValue := newTexturePath;
							
							newTexturePath := GetElementEditValues(texsettex, 'TX05 - Environment');
							If not SameText (newTexturePath, '') then
								newTexturePath := 'textures\'+newTexturePath;
							BlockTextures[5].EditValue := newTexturePath;
							
							newTexturePath := GetElementEditValues(texsettex, 'TX06 - Multilayer');
							If not SameText (newTexturePath, '') then
								newTexturePath := 'textures\'+newTexturePath;
							BlockTextures[6].EditValue := newTexturePath;
							
							newTexturePath := GetElementEditValues(texsettex, 'TX07 - Backlight Mask/Specular');
							If not SameText (newTexturePath, '') then
								newTexturePath := 'textures\'+newTexturePath;
							BlockTextures[7].EditValue := newTexturePath;
						except
						end;
					end;
					ForceDirectories(ExtractFilePath(DataPathMeshes + newFile));
					Nif.SaveToFile(DataPathMeshes + newFile);
					break;
				end else begin
					Inc(iThreeDCount);
				end;
			end;
		end;
	end;
	if(ListChoppingBlock.Count > 0)then
		for i := 0 to Pred(ListChoppingBlock.Count) do begin
			Nif.Delete(ListChoppingBlock[Pred(ListChoppingBlock.Count) - i]);
			Nif.SaveToFile(DataPathMeshes + newFile);
		end;
	ListChoppingBlock.Free;
	Nif.Free;
	
	//5: Update record (of the patch) with new model path and no alternate textures
	//5a: Add masters.
	If not HasMaster(PatchedPlugin, GetFileName(GetFile(e))) then begin
		AddMasterIfMissing(PatchedPlugin, GetFileName(GetFile(e)));
		for j := 0 to Pred(MasterCount(GetFile(e))) do begin
			if (Length(GetFileName(MasterByIndex(GetFile(e),j))) > 0) then
			AddMasterIfMissing(PatchedPlugin, GetFileName(MasterByIndex(GetFile(e),j)));
		end;
	end;
	//5b: Make record changes
	newElement := wbCopyElementToFile(e, PatchedPlugin, false, true);
	SetEditValue(ElementByPath(newElement, aMODL), newFile);
	RemoveElement(newElement, aMODS);
	//ASSUMING THAT SHIELD DOESN'T HAVE 2 DIFFERENT MODEL PATHS FOR MALE/FEMALE, because why would it?
		RemoveElement(newElement, 'Female world model\MO3T');
		RemoveElement(newElement, 'Female world model\MO3S');
		RemoveElement(newElement, 'Female world model\MOD3');

	AddMessage(#9'['+ IntToHex(FormID(e), 8)+']''s model path is now assigned to ' + newFile + #13#10);
	
end;

  
function Initialize: integer;
var
	NewFileName: String;
begin
	ScriptProcessElements := [etFile];
	DataPathMeshes := DataPath + 'meshes\';
	AddMessage(#13#10'STOP! Who would remove alternate texture sets must answer me these questions three, ere correctly textured models he see.'#13#10'First! What... is your name? (Enter a name for the new Patch, such as ''[ModName] AllGUD Patch'')');
//	If wbAppName = 'SSE' then begin
//		PatchedPlugin := AddNewFile(True);	//esl
//	end else
		PatchedPlugin := AddNewFile;	//esp
		
		
	bForceExit := false;
	if (GetFileName(PatchedPlugin) = '') then begin
		addmessage('Dialog box canceled or Plugin Name not valid, ending script');
		bForceExit := true;
	end;
	if (bForceExit = false) then begin
		AddMessage('Second! What... is the Prefix found in the EditorID? This only affects the generated filename. (You can leave this blank)');
		InputQuery('String1 to Remove', 'String will be removed from EditorID when assigning Model Paths. This can be left blank.', ModelPathRemovePrefix);
		AddMessage('Third! What... is the air-speed velocity of an unladen Swallow?.. I mean.. What is the Suffix Found in the EditorID? (You can leave this blank)');
		InputQuery('String2 to Remove', 'String will be removed from EditorID when assigning Model Paths. This can be left blank.', ModelPathRemoveSuffix);
	end;
	AddMessage(#13);
end;

function Process(e: IInterface): integer;
var
	i, iRecordCount: Integer;
	group, rec, ArmorAddon: IInterface;
begin
	if bForceExit then exit;
	
	
	AddMessage(GetFileName(e)+' is being checked for WEAP and ARMO[Shield] records with alternate textures');
	group := GroupBySignature(e, 'WEAP');
	iRecordCount := Pred(ElementCount(group));
	AddMessage(#9 + InttoStr(iRecordCount + 1) + ' WEAP records found.'#13#10'----------------');
	for i := 0 to iRecordCount do begin
		if getKeyState(VK_ESCAPE) < 0 then begin
			bForceExit := true;
			exit;
		end;
		rec := WinningOverride(ElementByIndex(group, i));
		
		GenerateAlternateMesh(rec, 'Model\MODL', 'Model\MODS', false);
	end;
	AddMessage('Finished checking WEAP records');
	
	AddMessage('----------------');
	
	group := GroupBySignature(e, 'ARMO');
	iRecordCount := Pred(ElementCount(group));
	AddMessage(#9+ InttoStr(iRecordCount + 1) + ' ARMO records found.'#13#10'----------------');
	for i := 0 to iRecordCount do begin
		if getKeyState(VK_ESCAPE) < 0 then begin
			bForceExit := true;
			exit;
		end;
		rec := ElementByIndex(group, i);
		If(GetElementEditValues(rec, 'ETYP') = 'Shield [EQUP:000141E8]') then begin
			ArmorAddon := WinningOverride(LinksTo(ElementByPath(rec, 'Armature\MODL'))); 
			GenerateAlternateMesh(ArmorAddon, 'Male world model\MOD2', 'Male world model\MO2S', false);
		end;
	end;
	AddMessage('Finished checking ARMO records');
end;

function Finalize: integer;
begin
	AddMessage('Alternate Texture Script has finished. Rerun the Mesh Generator script on the ORIGINAL plugin (To filter for Shield records)');
end;

end.
