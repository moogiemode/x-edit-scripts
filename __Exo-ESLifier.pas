{
  Convert plugin to ESL by retaining lower 3 hex digits if possible. By PJM.
}
unit ExoESLifier;
var
	HasCELL, IsESL, IsBroken, SkipPlugins: Boolean;
	Plugin, pFile: IInterface;
	nFixed, nFailed, nErr: Integer;
	PluginName: string;
	MinID: Cardinal;

function Process(e: IInterface): Integer;
var
	NewFixedID, NewID, OldID: Cardinal;
	Success: Boolean;
	i: Integer;

begin
	pFile := getfile(e);
  	If not assigned(plugin) then begin
		Plugin := pFile;
		PluginName := Getfilename(Plugin);
		If GetIsESL(Plugin) then begin
			AddMessage('Warning: Plugin '+PluginName+' is already flagged ESL');
			Result := 1;
			Exit;
		end;
		if GetElementNativeValues(ElementByIndex(plugin, 0), 'HEDR\Version') < 1.0 then begin
			AddMessage('Warning: '+PluginName+' has an older Header Version so less FormIDs can be converted safely');
			MinId := $800;
		End;
	end else if not equals(pFile,plugin) then begin
		If not SkipPlugins then
			AddMessage('Warning: Only one Mod at a time can be updated by this script. Only '+PluginName+' being processed');
		SkipPlugins := true;
		Exit;
	end;
    
    // override doesn't affect ESL
    if not IsMaster(e) then Exit;							// No overrides
    
    if Signature(e) = 'CELL' then HasCell := True;			// Doesn't work ESLified
        
	if (FormID(e) and $FFF000) = 0 then Exit;				// doesn't require fixing
	
	If (FormID(e) and $FFF) < MinID then begin				// Make sure we don't convert to an invalid FormID
		AddMessage('Warning: '+Signature(e)+' '+IntToHex(OldID,8)+' cannot be converted');
		inc(nFailed);
		IsESL := false;
		Exit;
	End;

	OldID := GetLoadOrderFormID(e);
	NewID := OldID  and $FF000FFF;
	NewFixedID := FixedFormID(e) and $FF000FFF;
	If RecordByFormID(Plugin,NewFixedID,false) <> Nil then begin
		AddMessage('Warning: '+Signature(e)+' '+IntToHex(OldID,8)+' cannot be converted');
		inc(nFailed);
		IsESL := false;
		Exit;
	End;
	
	For i:= 0 to ReferencedByCount(e)-1 do
		If not equals(Getfile(ReferencedByIndex(e, i)),Plugin) then begin
			AddMessage('Warning: '+Signature(e)+' '+IntToHex(OldID,8)+' is referenced in another Plugin so cannot be converted');
			inc(nFailed);
			IsESL := false;
			Exit;
		end;
	
// first change formid of references (thank you Zilav for this)
	Success := True;
	while ReferencedByCount(e) > 0 do
		Success := Success and CompareExchangeFormID(ReferencedByIndex(e, 0), OldID, NewID);
	
	SetLoadOrderFormID(e,NewID);
	If not success then begin
		AddMessage('Error: '+Signature(e)+' '+IntToHex(OldID,8)+' only partially converted to '+IntToHex(NewID,8));
		IsBroken := true;
		inc(nErr);
	end else begin
//		AddMessage('Info: '+Signature(e)+' '+IntToHex(OldID,8)+' converted to '+IntToHex(NewID,8));
		inc(nFixed);
	end;
  
end;
  
function Initialize: integer;
begin
	IsESL := true;
	IsBroken := False;
	SkipPlugins := false;
	MinID := 1;
end;

Function Finalize: integer;
Begin
	
	If IsBroken then
		AddMessage('Error: Some Forms have references that failed to be updated!');

	if HasCELL then
		AddMessage('Warning: Plugin has new CELL(s) which won''t work when turned into ESL and overridden by other mods (game bug)');

	AddMessage('Info: '+inttostr(nFixed)+' records ESLified, '+inttostr(nErr)+' Failed conversion, '+inttostr(nFailed)+' would conflict so left as is');
	if IsESL then begin
		AddMessage('Success: Plugin '+PluginName+' has been turned into an esl');
		SetIsESL(Plugin,true);
	end else
		AddMessage('Warning: Plugin '+PluginName+' still needs to have some FormIDs compacted so not ESLified');
end;

end.
