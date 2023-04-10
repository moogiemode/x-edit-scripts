{
	Ruddy88's R88 ESLify Script
	Skyrim SE and Fallout 4
	
	Aim: This is a script that will be run via a BAT file to automatically flag appropriate plugins as ESL by using the XEdit -PseudoESL command switch.
	It will Identify any plugins with a load order index of FE, that does not currently have an ESL flag, and load a dialog selection window allowing you to easily see which mods are appropriate for ESL flagging, then will assign the ESL flags based on your selection.
	
	Requires: XEdit, MXPF (Included in download)
	Credits:
	MatorTheEternal (For MXPF and assisting me with pascal coding in the past).
	The team behind XEdit (For... well... Xedit).
}

unit UserScript;

uses 'lib\mxpf';

var
	UserRevert: Boolean;


// Dialogue form prep
procedure PrepareDialog(frm: TForm; caption: String; height, width: Integer);
begin
  frm.BorderStyle := bsDialog;
  frm.Height := height;
  frm.Width := width;
  frm.Position := poScreenCenter;
  frm.Caption := caption;
end;


Procedure ShowRevertForm;
var
  frm: TForm;
  lblPrompt: TLabel;
  btnRevert, btnContinue: TButton;
  i: Integer;
begin
  frm := TForm.Create(nil);
  try
    PrepareDialog(frm, '::: REVERT CHANGES? :::', 145, 220);
    lblPrompt := ConstructLabel(frm, frm, 16, 20, 40, 240 - 60, 'Would you like to revert changes? Press YES to revert or NO to continue', ''); 
    
    btnRevert := TButton.Create(frm);
    btnRevert.Parent := frm;
    btnRevert.Left := frm.Width div 2 - btnRevert.Width - 8;
    btnRevert.Top := lblPrompt.Top + 65;
    btnRevert.Caption := 'Revert';
    btnRevert.ModalResult := mrYes;
    
    btnContinue := TButton.Create(frm);
    btnContinue.Parent := frm;
    btnContinue.Left := btnRevert.Left + btnRevert.Width + 8;
    btnContinue.Top := btnRevert.Top;
    btnContinue.Caption := 'Continue';
    btnContinue.ModalResult := mrNo;

    i := frm.ShowModal;
    UserRevert := i = 6;

  finally
    frm.Free;
  end;
end;



function MultipleFileSelectString(sPrompt: String; var sFiles: String): Boolean;
var
  sl: TStringList;
begin
  sl := TStringList.Create;
  try
    Result := MultipleFileSelect(sl, (sPrompt));
    sFiles := sl.CommaText;
  finally
    sl.Free;
  end;
end;

// File Selection dialogue displays only valid ESPFE candidates without ESM flags
function MultipleFileSelect(var sl: TStringList; prompt: string): Boolean;
const
  spacing = 24;
var
  frm: TForm;
  pnl: TPanel;
  lastTop, contentHeight: Integer;
  cbArray: Array[0..4351] of TCheckBox;
  lbl, lbl2: TLabel;
  sb: TScrollBox;
  i: Integer;
  f: IInterface;
  sFileName: String;
begin
  Result := false;
  frm := TForm.Create(nil);
  try
    frm.Position := poScreenCenter;
    frm.Width := 300;
    frm.Height := 600;
    frm.BorderStyle := bsDialog;
    frm.Caption := '::: R88 ESLify Converter :::';
    
    // create scrollbox
    sb := TScrollBox.Create(frm);
    sb.Parent := frm;
    sb.Align := alTop;
    sb.Height := 500;
    
    // create label
    lbl := TLabel.Create(sb);
    lbl.Parent := sb;
    lbl.Caption := 'Showing results from PseudoESL';
    lbl.Font.Style := [fsBold];
    lbl.Left := 8;
    lbl.Top := 10;
    lbl.Width := 270;
    lbl.WordWrap := true;
    lbl2 := TLabel.Create(sb);
    lbl2.Parent := sb;
    lbl2.Caption := 'Please Review Files for ESL flagging';
    lbl2.Font.Style := [fsItalic];
    lbl2.Left := 8;
    lbl2.Top := lbl.Top + lbl.Height + 12;
    lbl2.Width := 250;
    lbl2.WordWrap := true;
    lastTop := lbl2.Top + lbl2.Height + 12 - spacing;
			
    // create checkboxes
    for i := 0 to FileCount - 2 do begin
      f := FileByLoadOrder(i);
      sFileName := (GetFileName(f));
			if (POS('[FE', Name(f)) = 1) 
			and (GetElementNativeValues(ElementByIndex(f, 0), 'Record Header\Record Flags\ESM') = 0)
			and (GetElementNativeValues(ElementByIndex(f, 0), 'Record Header\Record Flags\ESL') = 0)
			and not (SameText(ExtractFileExt(sFileName), '.esl')) then begin
				cbArray[i] := TCheckBox.Create(sb);
				cbArray[i].Parent := sb;
				cbArray[i].Caption := Format(' [%s] %s', [IntToHex(i, 2), GetFileName(f)]);
				cbArray[i].Top := lastTop + spacing;
				cbArray[i].Width := 260;
				lastTop := lastTop + spacing;
				cbArray[i].Left := 12;
				cbArray[i].Checked := true;
			end;
    end;
    
    contentHeight := spacing*(i + 2) + 150;
    if frm.Height > contentHeight then
      frm.Height := contentHeight;
    
    // create modal buttons
    cModal(frm, frm, frm.Height - 70);
    sl.Clear;
    
    if frm.ShowModal = mrOk then begin
      Result := true;
      for i := 0 to FileCount - 2 do begin
        f := FileByLoadOrder(i);
        sFileName := (GetFileName(f));
				if (POS('[FE', Name(f)) = 1) 
				and (GetElementNativeValues(ElementByIndex(f, 0), 'Record Header\Record Flags\ESM') = 0)
				and (GetElementNativeValues(ElementByIndex(f, 0), 'Record Header\Record Flags\ESL') = 0)
				and not SameText(ExtractFileExt(GetFileName(f)), '.esl') then
          if (cbArray[i].Checked) then
						sl.Add(sFileName)
					else 
						Continue
      end;
    end;
  finally
    frm.Free;
  end;
end;

function Initialize: Integer;
var
  i: Integer;
  f: IInterface;
  sFiles: String;
	sFilesSL, slLog: TStringList;

begin
  InitializeMXPF;
	
	sFilesSL := TStringList.Create;
	
	// Creates an ESLify directory in DATA (or overwrite) for LOGS
	if not DirectoryExists(DataPath + 'ESLify') then begin
		CreateDir(DataPath + 'ESLify');
		AddMessage('ESLify Directory created at ' + DataPath + '\');
	end;

	if (FileExists(DataPath + 'ESLify\ESLify_LOG.txt')) then begin
		slLog := TSTringlist.Create;
		slLog.LoadFromFile(DataPath + 'ESLify\ESLify_LOG.txt');
		if slLog.Count > 0 then begin
			ShowRevertForm;
			if UserRevert then begin
				AddMessage('User Reverting');
				for i := 0 to Pred(FileCount) do begin
					f := FileByIndex(i);
					if (slLog.IndexOf(GetFileName(f)) <> -1)
					and (GetElementNativeValues(ElementByIndex(f, 0), 'Record Header\Record Flags\ESL') <> 0) then begin
						SetElementNativeValues(ElementByIndex(f, 0), 'Record Header\Record Flags\ESL', 0);
						AddMessage('Reverting changes to ' + GetFileName(f));
					end;
				end;
				slLog.Free;
				slLog.SaveToFile(DataPath + 'ESLify\ESLify_LOG.txt');
				AddMessage('All files have been reverted');
				Exit;
			end;
		end;
	end;

	// Load file selection for valid ESPFE candidates
  if not MultipleFileSelectString(('Please review files for ESL flagging'), sFiles) then begin
		AddMessage('User Aborted');
    exit;
	end;
	// Convert delimited sFiles string in to TSTringlist for index searching and LOG export
	
	sFilesSL.CommaText := sFiles;
	
	// Exit program if no files are selected
	if sFilesSL.Count <= 0 then begin
		AddMessage('No files selected, process aborted');
		exit;
	end;
	
	// Iterate through loaded files. Compares against sFilesSL stringlist and flags selected files as ESL
	for i := 0 to Pred(FileCount) do begin
		f := FileByIndex(i);
		if sFilesSL.IndexOf(GetFileName(f)) <> -1 then begin
				SetElementNativeValues(ElementByIndex(f, 0), 'Record Header\Record Flags\ESL', 1);
				AddMessage('Flagging ' + GetFileName(f) + ' as ESL');
		end;
	end;
	
	AddMessage('ESLifying complete');
	AddMessage('Exporting to ESLify_LOG.txt');
	
	// Creates directory in DATA to store LOG file
	
	sFilesSL.SaveToFile(DataPath + 'ESLify\ESLify_LOG.txt');
	AddMessage('Log complete');
	sFilesSL.free;
end;
end.

