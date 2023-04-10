{
  Change playable flag on selected HDPT records.
  Only alter the playable flag if the original value is not -1 (undefined).
}

unit UserScript;

function Process(e: IInterface): integer;
var
  iPlayable: integer;
begin
  // Only process HDPT records
  if Signature(e) <> 'HDPT' then
    Exit;

  // Get the current playable flag value
  iPlayable := GetElementNativeValues(e, 'DATA\Playable');

  // Only alter the playable flag if the original value is not -1 (undefined)
  if (iPlayable <> 0) then
    SetElementNativeValues(e, 'DATA\Playable', 0);

  Result := 0;
end;

end.