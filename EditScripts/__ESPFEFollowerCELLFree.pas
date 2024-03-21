{
  Automatically convert follower plugins to ESPFE. ESPFEFollower - Cell record free edition.
  Author: MaskedRPGFan https://www.nexusmods.com/users/22822094 maskedrpgfan@gmail.com
  Version: 1.4.0
  Hotkey: Ctrl+Alt+F
}
unit __ESPFEFollower;

interface
implementation
uses xEditAPI, SysUtils, StrUtils, Windows;

const
    iESLMaxRecords = $800; // max possible new records in ESL
    iESLMaxFormID  = $fff; // max allowed FormID number in ESL

var
    Verbose    : boolean;
	DeleteReplaced: boolean;

// 0 - OK
// 1 - OK, but must compact FormIDs
// 2 - CELL - disabled in this version
// 3 - Too many new records
function TestRecords(plugin: IInterface): Integer;
var
    i                           : Integer;
    e                           : IInterface;
    RecCount, RecMaxFormID, fid : Cardinal;
    HasCELL                     : Boolean;
begin
    Result := 0;
    // iterate over all records in plugin
    for i := 0 to Pred(RecordCount(plugin)) do begin
        e := RecordByIndex(plugin, i);
        
        // override doesn't affect ESL
        if not IsMaster(e) then
            Continue;
          
        //if Signature(e) = 'CELL' then begin
        //    Result := 2;
        //    Exit;
        //end;
            
        // increase the number of new records found
        Inc(RecCount);
        
        // no need to check for more if we are already above the limit
        if RecCount > iESLMaxRecords then begin
            Result := 3; // too many new records, can't be ESL
            Exit;
        end;
            
        // get raw FormID number
        fid := FormID(e) and $FFFFFF;
        
        // determine the max one
        if fid > RecMaxFormID then
            RecMaxFormID := fid;
    end;
  
    if RecMaxFormID <= iESLMaxFormID then
        Exit;            // AddMessage(#9'Can be turned into ESL by adding ESL flag in TES4 header')

    Result := 1;     // AddMessage(#9'Can be turned into ESL by compacting FormIDs first, then adding ESL flag in TES4 header');
end;


// -1 - Master plugin
// 0  - OK
// 1  - OK, but must compact FormIDs
// 2  - CELL - disabled in this version
// 3  - Too many new records
function TestPlugin(plugin: IInterface): Integer;
begin
    // skip the game master
    if GetLoadOrder(plugin) = 0 then begin
        Result := -1;
        Exit;
    end;

    if (GetElementNativeValues(ElementByIndex(plugin, 0), 'Record Header\Record Flags\ESL') = 0) and not SameText(ExtractFileExt(GetFileName(plugin)), '.esl') then begin
        Result := TestRecords(plugin);
    end;
end;


procedure CreateFaceMesh(MeshOldPath, MeshNewPath, OldFormID, NewFormID : string);
var
    Nif              : TwbNifFile;
    Block            : TwbNifBlock;
    el               : TdfElement;
    Elements         : TList;
    i, j, k          : Integer;
    s, s2            : WideString;
    bChanged         : Boolean;
begin
    Nif := TwbNifFile.Create;
    Nif.LoadFromFile(MeshOldPath);
    
    Elements := TList.Create;
    
    if Verbose then AddMessage(Format('Processed face %s --> %s. FormID %s --> %s.', [MeshOldPath, MeshNewPath, OldFormID, NewFormID]));
    
    // Iterate over all blocks in a nif file and locate elements holding textures.
    for i := 0 to Pred(Nif.BlocksCount) do begin
        Block := Nif.Blocks[i];
        
        if Block.BlockType = 'BSShaderTextureSet' then begin
            el := Block.Elements['Textures'];
            for j := 0 to Pred(el.Count) do
                Elements.Add(el[j]);
        end; 
    end;
    
    AddMessage(Format('Found %d elements.', [Elements.Count]));

    // Skip to the next file if nothing was found.
    if Elements.Count = 0 then Exit;
    
    // Do text replacement in collected elements.
    for k := 0 to Pred(Elements.Count) do begin
        if not Assigned(Elements[k]) then Continue
        el := TdfElement(Elements[k]);
        
        // Getting file name stored in element.
        s := el.EditValue;
        // Skip to the next element if empty.
        if s = '' then Continue;
        
        // Perform replacements, trim whitespaces just in case.
        s2 := Trim(s);
        s2 := StringReplace(s2, OldFormID, NewFormID, [rfIgnoreCase, rfReplaceAll]);
        
        // If element's value has changed.
        if s <> s2 then begin
            // Store it.
            el.EditValue := s2;
            
            // Report.
            if Verbose then AddMessage(#13#10 + MeshOldPath);
            if Verbose then AddMessage(#9 + el.Path + #13#10#9#9'"' + s + '"'#13#10#9#9'"' + el.EditValue + '"');
        end;
        

		// Create the same folders structure as the source file in the destination folder.
		s := ExtractFilePath(MeshNewPath);
		if not DirectoryExists(s) then
			if not ForceDirectories(s) then
				raise Exception.Create('Can not create destination directory ' + s);
	
		// Get the root of the last processed element (the file element itself) and save.
		el.Root.SaveToFile(MeshNewPath);
		if Verbose then AddMessage(Format('Processed face %s.', [MeshNewPath]));
    end;
    
    // Clear mark and elements list.
    bChanged := False;
    Elements.Clear;    
    Elements.Free;
    Nif.Free;    
end;


function GenerateFacePath(BasePath: string; FormID: Cardinal; TextureMode: bool): string;
begin
    if TextureMode then
        Result := Format('%s%s.dds', [BasePath, IntToHex64(FormID and $FFFFFF, 8)]);
    if not TextureMode then
        Result := Format('%s%s.nif', [BasePath, IntToHex64(FormID and $FFFFFF, 8)]);
end;

procedure SetDes(plugin: IInterface);
var
	des 			: String;
begin

	if( not ElementExists(ElementByIndex(plugin, 0), 'SNAM - Description')) then begin
		Add(ElementByIndex(plugin, 0), 'SNAM', true);
	end;
	des := GetElementNativeValues(ElementByIndex(plugin, 0), 'SNAM - Description') + ' ESPFE+';
	SetElementNativeValues(ElementByIndex(plugin, 0), 'SNAM - Description', des);
end;

function CompactFollowerPluginToESL(plugin: IInterface): Integer;
var
    i, j            : Integer;
    CurrentRecord   : IInterface;
    m, t            : IInterface;
    NewFormID       : Cardinal;
    NewFormID2      : Cardinal;
    OldFormID       : Cardinal;
    LoadOrder       : Cardinal;
    FaceMeshPath    : string;
    FaceTexturePath : string;
    VoicePath       : string;
    TextureOldPath  : string;
    TextureNewPath  : string;
    MeshOldPath     : string;
    MeshNewPath     : string;
    CopyResult      : bool;
    OldInfoFormIDs  : TStringList; 
    NewInfoFormIDs  : TStringList;
    TDirectory      : TDirectory;
    Files           : TWideStringDynArray;
    FilesWav        : TWideStringDynArray;
    FilesLip        : TWideStringDynArray;
    FilesXwm        : TWideStringDynArray;
    f, f2           : WideString;
    exists          : boolean;
	ConvertedVoices : Integer;
	ConvertedFaces  : Integer;
	MissingFaces    : Integer;
	NotConvertedVoices : Integer;
	NotConvertedFaces  : Integer;
	DeletedFiles : Integer;
begin
    Result            := 0;
    NewFormID         := StrToInt64('$' + IntToHex64(2048, 6));
    FaceMeshPath      := Format('%smeshes\Actors\Character\FaceGenData\FaceGeom\%s\', [DataPath, GetFileName(plugin)]);
    FaceTexturePath   := Format('%stextures\Actors\Character\FaceGenData\FaceTint\%s\', [DataPath, GetFileName(plugin)]);
    VoicePath         := Format('%ssound\voice\%s\', [DataPath, GetFileName(plugin)]);
    if DirectoryExists(VoicePath) then begin
        Files             := TDirectory.GetFiles(VoicePath, '*.fuz*', soAllDirectories);
        FilesWav          := TDirectory.GetFiles(VoicePath, '*.wav*', soAllDirectories);
        FilesLip          := TDirectory.GetFiles(VoicePath, '*.lip*', soAllDirectories);
        FilesXwm          := TDirectory.GetFiles(VoicePath, '*.xwm*', soAllDirectories);
	end;
    OldInfoFormIDs     := TStringList.Create;
    NewInfoFormIDs     := TStringList.Create;
	
	ConvertedVoices := 0;
	ConvertedFaces  := 0;
	MissingFaces	:= 0;
	NotConvertedVoices := 0;
	NotConvertedFaces  := 0;
	DeletedFiles := 0;
    
	LoadOrder			:= StrToInt64('$' + IntToHex64(GetLoadOrder(plugin), 2) + '000000');
    exists := true;
    while exists do begin
		NewFormID2 := NewFormID or LoadOrder;
        t := RecordByFormID(plugin, NewFormID2, true);
        // This FormID already exists.
        if Assigned(t) then begin
            if Verbose then AddMessage(Format('Record [%s][%s] %d exists.', [IntToHex64(NewFormID, 8), Name(t), Length(Name(t))]));
            // increment formid
            Inc(NewFormID);
        end;
        if not Assigned(t) then exists := false;
    end;
    
    AddMessage('Plugin ' + GetFileName(plugin) + ' will be processed with ' + IntToStr(RecordCount(plugin)) + ' records.');
    
    // Iterate over all records in plugin.
    for i := 0 to Pred(RecordCount(plugin)) do begin
        CurrentRecord     := RecordByIndex(plugin, i);
        OldFormID         := GetLoadOrderFormID(CurrentRecord);
		NewFormID2        := ((OldFormID and $FF000000) or NewFormID);
        
        // Is in valid range, get next record.
        if (FormID(CurrentRecord) and $FFFFFF) <= iESLMaxFormID then begin
            if Verbose then AddMessage(Format('Record [%s]%s is valid.', [IntToHex64(OldFormID, 8), Name(CurrentRecord)]));
			if Signature(CurrentRecord) = 'NPC_' then Inc(NotConvertedFaces);
			if Signature(CurrentRecord) = 'INFO' then Inc(NotConvertedVoices);
            continue;
        end;
        
        // Is identical.
        if (NewFormID and $FFFFFF) = (OldFormID and $FFFFFF) then begin
            Inc(NewFormID);
			NewFormID2        := ((OldFormID and $FF000000) or NewFormID);
            continue;
        end;
        
        // The record in question might originate from master file.
        m := MasterOrSelf(CurrentRecord);
        // Skip overridden records.
        if not Equals(m, CurrentRecord) then
            continue;
        
        if Verbose then AddMessage(Format('[%3.0d] Changing FormID from [%s] to [%s] on %s', [i, IntToHex64(OldFormID, 8), IntToHex64(NewFormID2, 8), Name(CurrentRecord)]));
        
        if Signature(CurrentRecord) = 'NPC_' then begin
            TextureOldPath    := GenerateFacePath(FaceTexturePath, OldFormID, true);
            TextureNewPath    := GenerateFacePath(FaceTexturePath, NewFormID, true);
			If FileExists(TextureOldPath) then
				CopyFile(TextureOldPath, TextureNewPath, CopyResult);
				if DeleteReplaced then begin
					DeleteFile(TextureOldPath);
					Inc(DeletedFiles);
					if Verbose then AddMessage(Format('Deleted: %s', [TextureOldPath]));
				end
			Else
				AddMessage(Format('Face texture %s missing!', [TextureOldPath]));

            
            MeshOldPath    := GenerateFacePath(FaceMeshPath, OldFormID, false);
            MeshNewPath    := GenerateFacePath(FaceMeshPath, NewFormID, false);
			If FileExists(MeshOldPath) then
			begin
				CreateFaceMesh(MeshOldPath, MeshNewPath, IntToHex64(OldFormID and $FFFFFF, 8), IntToHex64(NewFormID and $FFFFFF, 8));
				if DeleteReplaced then begin
					DeleteFile(MeshOldPath);
					Inc(DeletedFiles);
					if Verbose then AddMessage(Format('Deleted: %s', [MeshOldPath]));
				end;
				Inc(ConvertedFaces);
			end
			Else
			begin
				AddMessage(Format('Face mesh %s missing!', [MeshOldPath]));
				Inc(MissingFaces);
			end;
        end;
        
        if Signature(CurrentRecord) = 'INFO' then begin
            OldInfoFormIDs.Add(IntToHex64(OldFormID and $FFFFFF, 6));
            NewInfoFormIDs.Add(IntToHex64(NewFormID and $FFFFFF, 6));
        end;

        UpdateRefs(CurrentRecord);
        
        // First change formid of references,
        while ReferencedByCount(CurrentRecord) > 0 do
            CompareExchangeFormID(ReferencedByIndex(CurrentRecord, 0), OldFormID, NewFormID2);

        // Change formid of record.
        SetLoadOrderFormID(CurrentRecord, NewFormID2 );
        UpdateRefs(CurrentRecord);

        exists := true;
        while exists do begin
            // increment formid
            Inc(NewFormID);
			NewFormID2        := LoadOrder or NewFormID;
            t := RecordByFormID(plugin, NewFormID2, true);
            // This FormID already exists.
            if Assigned(t) then
                if Verbose then AddMessage(Format('Record [%s][%s] %d exists.', [IntToHex64(NewFormID2, 8), Name(t), Length(Name(t))]));
            if not Assigned(t) then exists := false;
        end;
    end;

    SetElementNativeValues(ElementByIndex(plugin, 0), 'HEDR - Header\Next Object ID', NewFormID);
        
    // Processing voice files.
    for i := 0 to Pred(Length(Files)) do begin
        f := Files[i];
        
        // Perform replacements.
        for j := 0 to Pred(OldInfoFormIDs.Count) do begin
            // replace if text to find is not empty
            f2 := StringReplace(f, OldInfoFormIDs[j], NewInfoFormIDs[j], [rfIgnoreCase, rfReplaceAll]);
            if f <> f2 then begin 
                CopyFile(f, f2, CopyResult);
				if DeleteReplaced then begin
					DeleteFile(f);
					Inc(DeletedFiles);
					if Verbose then AddMessage(Format('Deleted: %s', [f]));
				end;
                if Verbose then AddMessage(Format('%s --> %s', [f, f2]));
				Inc(ConvertedVoices);
                break;
            end;
        end;
    end;
    for i := 0 to Pred(Length(FilesWav)) do begin
        f := FilesWav[i];
        
        // Perform replacements.
        for j := 0 to Pred(OldInfoFormIDs.Count) do begin
            // replace if text to find is not empty
            f2 := StringReplace(f, OldInfoFormIDs[j], NewInfoFormIDs[j], [rfIgnoreCase, rfReplaceAll]);
            if f <> f2 then begin 
                CopyFile(f, f2, CopyResult);
				if DeleteReplaced then begin
					DeleteFile(f);
					Inc(DeletedFiles);
					if Verbose then AddMessage(Format('Deleted: %s', [f]));
				end;
                if Verbose then AddMessage(Format('%s --> %s', [f, f2]));
				Inc(ConvertedVoices);
                break;
            end;
        end;
    end;
    for i := 0 to Pred(Length(FilesLip)) do begin
        f := FilesLip[i];
        
        // Perform replacements.
        for j := 0 to Pred(OldInfoFormIDs.Count) do begin
            // replace if text to find is not empty
            f2 := StringReplace(f, OldInfoFormIDs[j], NewInfoFormIDs[j], [rfIgnoreCase, rfReplaceAll]);
            if f <> f2 then begin 
                CopyFile(f, f2, CopyResult);
				if DeleteReplaced then begin
					DeleteFile(f);
					Inc(DeletedFiles);
					if Verbose then AddMessage(Format('Deleted: %s', [f]));
				end;
                if Verbose then AddMessage(Format('%s --> %s', [f, f2]));
				Inc(ConvertedVoices);
                break;
            end;
        end;
    end;
    for i := 0 to Pred(Length(FilesXwm)) do begin
        f := FilesXwm[i];
        
        // Perform replacements.
        for j := 0 to Pred(OldInfoFormIDs.Count) do begin
            // replace if text to find is not empty
            f2 := StringReplace(f, OldInfoFormIDs[j], NewInfoFormIDs[j], [rfIgnoreCase, rfReplaceAll]);
            if f <> f2 then begin 
                CopyFile(f, f2, CopyResult);
				if DeleteReplaced then begin
					DeleteFile(f);
					if Verbose then AddMessage(Format('Deleted: %s', [f]));
				end;
                if Verbose then AddMessage(Format('%s --> %s', [f, f2]));
				Inc(ConvertedVoices);
                break;
            end;
        end;
    end;
    AddMessage(Format('Converted FaceGenData: %d, not converted: %d, missing: %d.', [ConvertedFaces, NotConvertedFaces, MissingFaces]));
    AddMessage(Format('Converted voice files: %d, not converted: %d.', [ConvertedVoices, NotConvertedVoices]));
    AddMessage(Format('Deleted files: %d.', [DeletedFiles]));
end;

function Initialize: integer;
var
    Plugin: IInterface;
begin
    ScriptProcessElements       := [etFile];
    Verbose                     := true;
	DeleteReplaced				:= true;
end;

function Process(plugin: IInterface): integer;
var
    State:     Integer;
begin
	if (GetElementNativeValues(ElementByIndex(plugin, 0), 'Record Header\Record Flags\ESL') == false) then begin
        AddMessage('Plugin ' + GetFileName(plugin) + ' has an ESL flag in the TES4 header. I assume it is already converted to ESPFE.');
        Exit;
	end;

    State := TestPlugin(plugin);
    if( State = 0 ) then begin
        SetElementNativeValues(ElementByIndex(plugin, 0), 'Record Header\Record Flags\ESL', 1);
		SetDes(plugin);
        AddMessage('Plugin ' + GetFileName(plugin) + ' was turned into ESPFE by adding ESL flag in TES4 header.');
        Exit;
    end;
    
    if( State = 1 ) then begin
        CompactFollowerPluginToESL(plugin);
        SetElementNativeValues(ElementByIndex(plugin, 0), 'Record Header\Record Flags\ESL', 1);
		SetDes(plugin);
        AddMessage('Plugin ' + GetFileName(plugin) + ' was turned into ESPFE by compacting FormIDs and adding ESL flag in TES4 header.');
        Exit;
    end;
    
    //if( State = 2 ) then AddMessage('Plugin ' + GetFileName(plugin) + ' has CELL record and cant be processed due to Skyrim engine bug.');
    if( State = 3 ) then AddMessage('Plugin ' + GetFileName(plugin) + ' has too many records.');
end;


function Finalize: integer;
begin
  Result := 0;
end;

end.
