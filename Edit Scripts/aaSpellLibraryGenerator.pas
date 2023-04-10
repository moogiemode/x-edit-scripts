{
    A script to automatically generate a spell library for Spellforge from any combination of spell mods.
}
unit userscript;


type override_index = record
    filename : string;
    start_pos : integer;
    end_pos : integer;
end;
type override_record = record
    plugin_name : string;
    spell_name : string;
    have_principle_val : boolean;
    principle_0_val : boolean;
    principle_1_val : boolean;
    principle_2_val : boolean;
    principle_3_val : boolean;
    school_val : integer;
    level_val : integer;
    method_val : integer;
    delivery_val : integer;
    exclude_val : integer;
    dependent_filename : string; // optional from here on out
    exclusive_filename : string;
    exclusive_tome_name : string;
end;
type item_list = record
    arr : array [ 0..1024] of integer;
    count : integer;
end;

var 
    main_file : IwbFile; // Skyrim.esm
    dino_file : IwbFile; // DinoSpellDiscovery.esp
    patch_file : IwbFile; // this is the file created/edited by the script
    patch_filename : string; // name to use for patch_file, default DinoSpellDiscovery - Spells Patch.esp
    override_filename : string; // path to a config file listing spells to treat differently than the script infers
    patch_from_scratch : boolean; // option in first dialog: clear flists if patch file exists?
    update_override_file : boolean; // option in last dialog: add changes made in any popups to override config file?
    confirm_level : integer; // option in first dialog: which spells should show a popup to confirm details?
                             // 0 is minimal; 1 is any not in the override file; 2 is all spells
    override_lines : TStringList; // plaintext lines of override file
    override_file_indices : array [ 0..999] of override_index; // a filename and start and end line for override info for each file (e.g. Skyrim.esm)
    override_file_count : integer; // the total number of files found in the override config file
    mgef_array : array [ 0..19] of IInterface; // to be filled by get_mgef_list() and accessed elsewhere
    perk_array : array [ 0..24] of IInterface; // filled in Initialize()
    spell_override_array : array [ 0..99] of IInterface; // fill with main records from files that touch the spell
    spell_override_count : integer; // number of files touching this spell currently
    spell_override_idx : integer; // index of record version currently used
    curr_override_line : override_record; // updated for each record; override info, if found, for the current spell
    school : integer; // values filled in for the current record
    level : integer;
    method : integer;
    delivery : integer;
    exclude_as_reward : integer; // 0 is no; 1 is yes; 2 is skip adding to patch altogether
    principle_0 : boolean; // this is a very silly way to do it
    principle_1 : boolean; // but there's some kind of typing quirk with a bool array and this was easier
    principle_2 : boolean;
    principle_3 : boolean;
    dependent_filename, exclusive_filename, exclusive_tome_name : string;
    inferred_school, inferred_level, inferred_method, inferred_delivery : integer; // guessed values; will need to update override config if they are changed later, so these are stored for comparison
    inferred_principle_0, inferred_principle_1, inferred_principle_2, inferred_principle_3 : boolean;
    principle_names : array [0..19] of string; // principle names to display on form
    parent_box : TComboBox; // used for form updating; display the proper principles when school is changed
    child_box : TCheckListBox;
    principle_flist_array : array [ 0..19] of IInterface; // FLST records in the patch; these will be modified
    delivery_flist_array : array [ 0..2] of IInterface;
    method_flist_array : array [ 0..1] of IInterface;
    level_flist_array : array [ 0..4] of IInterface;
    rewards_exclude_flist : IInterface;
    spell_list, tome_list, scrl_list, weap_list : item_list; // for checking patch integrity at the end
    files_to_skip : TStringList; // if the winning override of a record is from one of these, use an earlier override

// split a string around a character and add the pieces to to_fill
// 'abc,d,' will add 'abc', 'd', and '' to to_fill
procedure split_delim_line (line : string; delimiter : char; to_fill : TStringList);
var
    curr_substr : string;
    curr_pos : integer;
begin
    curr_substr := line;
    repeat
        curr_pos := Pos(delimiter, curr_substr);
        if curr_pos = 0 then begin
            to_fill.Add(curr_substr);
            curr_substr := '';
        end else begin
            to_fill.Add(sub_str(curr_substr, 1, (curr_pos - 1)));
            curr_substr := sub_str(curr_substr, (curr_pos + 1), Length(curr_substr));
            if Length(curr_substr) = 0 then
                to_fill.Add('');
        end;
    until Length(curr_substr) = 0;
    
end;

// Pos(), but starting from the end; no support for offset
// not particularly performant
function reverse_pos (little_str, big_str : string) : integer;
var
    i : integer;
begin
    for i := (Length(big_str) - Length(little_str) + 1) downto 0 do begin
        if sub_str(big_str, i, Length(little_str)) = little_str then begin
            Result := i;
            Exit;
        end;
    end;
end;

// requires global variable override_filename to contain a path to a config file
// fills override_lines (TStringList) and override_file_indices (array), both global variables
// modified global variable override_file_count
// all of these are effectively started from scratch
// theoretically it should work to call this a second time with a different config file to switch to using it
// but I have not tested any such functionality
function load_overrides : boolean;
var
    i : integer;
    len : integer;
    current_filename : string;
    current_pos : integer;
begin
    Result := False;
    override_file_count := 0;
    current_filename := '';
    if Assigned(override_lines) then begin // just in case this function is called twice
        override_lines.Free;
    end;
    override_lines := TStringList.Create;
    override_lines.LoadFromFile(override_filename);
    for i := 0 to (override_lines.Count - 1) do begin // for each line in the override file
        len := Length(override_lines[i]);
        if len = 0 then
            Continue;
        if (sub_str(override_lines[i], 1, 1) = '[') then begin
            // line with file e.g. [Skyrim.esm]
            // ignores anything after the close bracket, so this line can be [Skyrim.esm],,,,,, for example
            // (which can happen if file is edited by MS Excel or similar)
            // be aware if a spell name is [lorem ipsum], that line would erroneously be assumed to be a file name
            current_pos := reverse_pos(']', override_lines[i]);
            if current_pos = 0 then begin
                AddMessage('ERROR: config file line ' + inttostr(i) + ' is missing a close bracket; "' + override_lines[i] + '"');
                Result := True;
                break;
            end;
            current_filename := sub_str(override_lines[i], 2, (current_pos-2));
            override_file_indices[override_file_count].filename := current_filename;
            override_file_indices[override_file_count].start_pos := i + 1;
            if override_file_count > 0 then
                override_file_indices[override_file_count - 1].end_pos := i - 1;
            override_file_count := override_file_count + 1;
        end;
    end;
    if override_file_count > 0 then
        override_file_indices[override_file_count - 1].end_pos := override_lines.Count - 1;
end;

// replace contents of override_filename with updated ones
// does check update_override_file
procedure write_overrides;
var
    i : integer;
begin
    if update_override_file then begin
        override_lines.SaveToFile(override_filename);
    end;
    override_lines.Free;
end;

// fill curr_override_line with details from the given line
function fill_override_line_from_string(line, filename : string) : boolean;
var
    i : integer;
    split_line : TStringList;
    split_principles : TStringList;
begin
    Result := True;
    
    // other previous results will always be overwritten, but principles must be zeroed
    curr_override_line.principle_0_val := False;
    curr_override_line.principle_1_val := False;
    curr_override_line.principle_2_val := False;
    curr_override_line.principle_3_val := False;
    
    // because they may simply be absent
    curr_override_line.dependent_filename := '';
    curr_override_line.exclusive_filename := '';
    curr_override_line.exclusive_tome_name := '';
    
    split_line := TStringList.Create;   
    split_delim_line(line, ',', split_line);
    if (split_line.Count >= 7) and (split_line.Count <= 10) then begin
        curr_override_line.plugin_name := filename;
        curr_override_line.spell_name := split_line[0];
        if Length(split_line[1]) = 0 then begin
            curr_override_line.have_principle_val := False;
        end else begin
            curr_override_line.have_principle_val := True;
            for i := 1 to Length(split_line[1]) do begin
                case strtoint(sub_str(split_line[1],i,1)) of
                    0 : curr_override_line.principle_0_val := True;
                    1 : curr_override_line.principle_1_val := True;
                    2 : curr_override_line.principle_2_val := True;
                    3 : curr_override_line.principle_3_val := True;
                else
                    AddMessage('Warning: invalid principle: ' + split_line[1][i]);
                    Result := False;
                end;
            end;
        end;
        for i := 2 to 6 do begin
            if split_line[i] = '' then
                split_line[i] := '-1';
        end;
        curr_override_line.school_val := strtoint(split_line[2]);
        curr_override_line.level_val := strtoint(split_line[3]);
        curr_override_line.method_val := strtoint(split_line[4]);
        curr_override_line.delivery_val := strtoint(split_line[5]);
        curr_override_line.exclude_val := strtoint(split_line[6]);
        if split_line.Count >= 8 then begin
            curr_override_line.dependent_filename := split_line[7];
        end;
        if split_line.Count >= 9 then begin
            curr_override_line.exclusive_filename := split_line[8];
        end;
        if split_line.Count >= 10 then begin
            curr_override_line.exclusive_tome_name := split_line[9];
        end;
    end else begin
        Result := False;
    end;
    split_line.Free;
end;

// search override file for a line that matches the spell_name under a heading for the given file
// requires that override_file_indices and override_lines be populated (presumably by load_overrides)
function fill_override_line(filename, spell_name : string) : boolean;
var
    i : integer;
    start_pos : integer;
    end_pos : integer;
    comma_pos : integer;
    line_ok : boolean;
begin
    start_pos := -1;
    end_pos := -1;
    line_ok := False;
    Result := False;
    for i := 0 to (override_file_count - 1) do begin
        if override_file_indices[i].filename = filename then begin // if there are overrides for filename
            start_pos := override_file_indices[i].start_pos;
            end_pos := override_file_indices[i].end_pos;
            break;
        end;
    end;
    if start_pos <> -1 then begin
        for i := start_pos to end_pos do begin // for each override under filename
            comma_pos := Pos(',', override_lines[i]);
            if (Length(override_lines[i]) = 0) then begin
                
            end else if (comma_pos = 0) then begin
                AddMessage('WARNING: line ' + inttostr(i) + ' is invalid; override file: ' + filename);
            end else if sub_str(override_lines[i], 1, (comma_pos - 1)) = spell_name then begin
                line_ok := fill_override_line_from_string(override_lines[i], filename);
                if not line_ok then begin
                    AddMessage('WARNING: line ' + inttostr(i) + ' is invalid, skipping; override file: ' + filename);
                    Exit;
                end;
                
                Result := True;
                Exit;
            end;
        end;
    end;
end;

// make from scratch an override line for the given spell
// uses the global variables for school and other properties
function construct_override_line(spell_name : string) : string;
var
    included_principle : boolean;
begin
    included_principle := (inferred_principle_0 <> principle_0) or (inferred_principle_1 <> principle_1) or (inferred_principle_2 <> principle_2) or (inferred_principle_3 <> principle_3);
    Result := spell_name + ',';
    if included_principle then begin
        if principle_0 then begin
            Result := Result + '0'
        end;
        if principle_1 then begin
            Result := Result + '1';
        end;
        if principle_2 then begin
            Result := Result + '2';
        end;
        if principle_3 then begin
            Result := Result + '3';
        end;
    end;
    Result := Result + ',';
    if (inferred_school <> school) or included_principle then // if principle is specified, school must be also
        Result := Result + inttostr(school);
    Result := Result + ',';
    if (inferred_level <> level) or included_principle then // ...and level, as auto-detect gets both
        Result := Result + inttostr(level);
    Result := Result + ',';
    if inferred_method <> method then
        Result := Result + inttostr(method);
    Result := Result + ',';
    if inferred_delivery <> delivery then
        Result := Result + inttostr(delivery);
    Result := Result + ',' + inttostr(exclude_as_reward);
    if (dependent_filename <> '') or (exclusive_filename <> '') or (exclusive_tome_name <> '') then
        Result := Result + ',' + dependent_filename + ',' + exclusive_filename + ',' + exclusive_tome_name;
end;

// for debugging: print filenames and their index range in the current override file
// (assumes override_file_indices is populated)
procedure print_current_overrides;
var
    i : integer;
begin
    AddMessage('current overrides: ' + inttostr(override_file_count));
    for i := 0 to (override_file_count - 1) do begin
        AddMessage(override_file_indices[i].filename + ': ' + inttostr(override_file_indices[i].start_pos) + ' - ' + inttostr(override_file_indices[i].end_pos));
    end;
end;

// update the override file with the current spell, using spell_name and under filename
// assumes override_lines & override_file_indices are populated
procedure write_override_line(filename, spell_name : string);
var
    i : integer;
    filename_idx : integer;
begin
    filename_idx := -1;
    for i := 0 to (override_file_count - 1) do begin // is there already an override section for this file?
        if override_file_indices[i].filename = filename then begin
            filename_idx := i;
            break;
        end;
    end;
    if filename_idx = -1 then begin // add an empty section for filename
        override_lines.Add('[' + filename + ']');
        filename_idx := override_file_count;
        override_file_indices[filename_idx].filename := filename;
        override_file_indices[filename_idx].start_pos := override_lines.Count;
        override_file_indices[filename_idx].end_pos := override_lines.Count - 1;
        override_file_count := override_file_count + 1;
    end;
    
    // does spell_name already have an override_line?
    for i := override_file_indices[filename_idx].start_pos to override_file_indices[filename_idx].end_pos do begin
        if sub_str(override_lines[i], 1, (Pos(',', override_lines[i]) - 1)) = spell_name then begin
            override_lines[i] := construct_override_line(spell_name); // if so, replace it
            Exit;
        end;
    end;
    override_file_indices[filename_idx].end_pos := override_file_indices[filename_idx].end_pos + 1;
    override_lines.Insert(override_file_indices[filename_idx].end_pos, construct_override_line(spell_name));
    // for sections following this one, if there are any, increment positions to account for the added line
    for i := (filename_idx + 1) to (override_file_count - 1) do begin
        override_file_indices[i].start_pos := override_file_indices[i].start_pos + 1;
        override_file_indices[i].end_pos := override_file_indices[i].end_pos + 1;
    end;
end;

// debugging - print all child elements of the item
procedure DumpTrace(item : IInterface);
var
    i : integer;
    count_recv : integer;
begin
    count_recv := ElementCount(item);
    AddMessage('    Dump trace, element count = ' + inttostr(count_recv));
    for i := 0 to (count_recv - 1) do begin
        AddMessage('    ' + FullPath(ElementByIndex(item, i)));
        AddMessage('    ' + GetEditValue(ElementByIndex(item, i)));
    end;
end;

// config dialog - set patch name, override config file name, 
// whether to clear an existing patch, which spells to pop up a confirm dialog for
function show_init_options : boolean;
var
    options_form : TForm;
    ok_button, cancel_button : TButton;
    confirm_unknown_radio, confirm_no_override_radio, confirm_all_radio : TRadioButton;
    confirm_group : TRadioGroup;
    filename_label : TLabeledEdit;
    patch_label : TLabeledEdit;
    update_radio, from_scratch_radio : TRadioButton;
    patch_group : TRadioGroup;
    running_top : integer;
begin
    Result := True;
    options_form := TForm.Create(nil);
    try
        options_form.Caption := 'Spell Library Generator Options';
        options_form.Width := Min(410, Screen.Width - 50);
        options_form.Position := poScreenCenter;
        options_form.KeyPreview := True;
        running_top := 30;
        
        patch_label := TLabeledEdit.Create(options_form);
        patch_label.Parent := options_form;
        patch_label.LabelPosition := lpAbove;
        patch_label.EditLabel.Caption := 'Library file to create or update:';
        patch_label.Left := 15;
        patch_label.Height := 50;
        patch_label.Top := running_top;
        patch_label.Width := options_form.Width - 50;
        patch_label.Text := patch_filename;
        running_top := running_top + patch_label.Height;
        
        patch_group := TRadioGroup.Create(options_form);
        patch_group.Parent := options_form;
        patch_group.Left := 15;
        patch_group.Top := running_top;
        patch_group.Width := options_form.Width - 50;
        patch_group.Height := 50;
        patch_group.Caption := 'If library file already exists:';
        patch_group.ClientWidth := 350;
        patch_group.ClientHeight := 50;
        running_top := running_top + patch_group.Height + 40;
        
        update_radio := TRadioButton.Create(patch_group);
        update_radio.Parent := patch_group;
        update_radio.Left := 10;
        update_radio.Width := 120;
        update_radio.Top := 20;
        update_radio.Caption := 'Append new spells';
        update_radio.Checked := False;
        
        from_scratch_radio := TRadioButton.Create(patch_group);
        from_scratch_radio.Parent := patch_group;
        from_scratch_radio.Left := update_radio.Left + update_radio.Width + 20;
        from_scratch_radio.Width := 190;
        from_scratch_radio.Top := 20;
        from_scratch_radio.Caption := 'Clear library and start from scratch';
        from_scratch_radio.Checked := True;
        
        filename_label := TLabeledEdit.Create(options_form);
        filename_label.Parent := options_form;
        filename_label.LabelPosition := lpAbove;
        filename_label.EditLabel.Caption := 'Configuration file';
        filename_label.Left := 15;
        filename_label.Height := 50;
        filename_label.Top := running_top;
        filename_label.Width := options_form.Width - 50;
        filename_label.Text := override_filename;
        running_top := running_top + filename_label.Height;
        
        confirm_group := TRadioGroup.Create(options_form);
        confirm_group.Parent := options_form;
        confirm_group.Left := 15;
        confirm_group.Top := running_top;
        confirm_group.Width := options_form.Width - 50;
        confirm_group.Height := 90;
        confirm_group.Caption := 'Pop up confirmation for spell details:';
        confirm_group.ClientWidth := options_form.Width - 50;
        confirm_group.ClientHeight := 90;
        running_top := running_top + confirm_group.Height + 20;
        
        confirm_unknown_radio := TRadioButton.Create(confirm_group);
        confirm_unknown_radio.Parent := confirm_group;
        confirm_unknown_radio.Left := 10;
        confirm_unknown_radio.Width := 200;
        confirm_unknown_radio.Top := 20;
        confirm_unknown_radio.Caption := 'If script cannot infer details';
        confirm_unknown_radio.Checked := True;
        
        confirm_no_override_radio := TRadioButton.Create(confirm_group);
        confirm_no_override_radio.Parent := confirm_group;
        confirm_no_override_radio.Left := 10;
        confirm_no_override_radio.Width := 200;
        confirm_no_override_radio.Top := 40;
        confirm_no_override_radio.Caption := 'For all spells not in the config';
        confirm_no_override_radio.Checked := False;
        
        confirm_all_radio := TRadioButton.Create(confirm_group);
        confirm_all_radio.Parent := confirm_group;
        confirm_all_radio.Left := 10;
        confirm_all_radio.Width := 200;
        confirm_all_radio.Top := 60;
        confirm_all_radio.Caption := 'For all spells';
        confirm_all_radio.Checked := False;
        
        ok_button := TButton.Create(options_form);
        ok_button.Parent := options_form;
        ok_button.Top := running_top;
        ok_button.Width := (options_form.Width/3);
        ok_button.Left := (options_form.Width/4) - (ok_button.Width/2) - 10;
        ok_button.Caption := 'OK';
        ok_button.ModalResult := mrOk;
        
        cancel_button := TButton.Create(options_form);
        cancel_button.Parent := options_form;
        cancel_button.Top := running_top;
        cancel_button.Width := (options_form.Width/3);
        cancel_button.Left := (options_form.Width*3/4) - (cancel_button.Width/2) - 10;
        cancel_button.Caption := 'Cancel';
        cancel_button.ModalResult := mrCancel;
        running_top := running_top + cancel_button.Height + 50;
        
        options_form.Height := Min(running_top, Screen.Height - 50);
        
        if options_form.ShowModal = mrCancel then begin
            Result := True;
        end else begin
            patch_filename := patch_label.Text;
            patch_from_scratch := from_scratch_radio.Checked;
            override_filename := filename_label.Text;
            if confirm_all_radio.Checked then begin
                confirm_level := 2;
            end else if confirm_no_override_radio.Checked then begin
                confirm_level := 1;
            end else begin
                confirm_level := 0;
            end;
            Result := False;
        end;
    finally
        options_form.Free;
    end;
end;

// helper function for confirm dialog - when school is changed, update principles box to match
procedure set_principles_box(principle_box : TCheckListBox; school : integer);
begin
    principle_box.Items.Clear;
    if school <> -1 then begin
        principle_box.Items.Add(principle_names[school*4]);
        principle_box.Items.Add(principle_names[school*4 + 1]);
        principle_box.Items.Add(principle_names[school*4 + 2]);
        principle_box.Items.Add(principle_names[school*4 + 3]);
    end else begin
        principle_box.Items.Add('0');
        principle_box.Items.Add('1');
        principle_box.Items.Add('2');
        principle_box.Items.Add('3');
    end;
    if principle_0 then begin
        principle_box.Items[0] := principle_box.Items[0] + ' (inferred)';
        principle_box.Checked[0] := True;
    end;
    if principle_1 then begin
        principle_box.Items[1] := principle_box.Items[1] + ' (inferred)';
        principle_box.Checked[1] := True;
    end;
    if principle_2 then begin
        principle_box.Items[2] := principle_box.Items[2] + ' (inferred)';
        principle_box.Checked[2] := True;
    end;
    if principle_3 then begin
        principle_box.Items[3] := principle_box.Items[3] + ' (inferred)';
        principle_box.Checked[3] := True;
    end;
end;

// dummy procedure to set as OnChange for the school dropdown box (in show_confirm)
procedure combo_box_on_change;
begin
    set_principles_box(child_box, parent_box.ItemIndex);
end;

// confirm pop-up dialog for spells that require user clarification
// depending on confirm_level:
//     0 - confirm only when the script cannot infer one or more spell properties
//     1 - confirm when a spell does not already have a record in the config override file
//         (this means every spell must be confirmed once, but will be automatically handled on repeat runs)
//     2 - confirm for every spell record
// returns:
//     0 - canceled, exit program
//     1 - OK, accept selections and continue
//     2 - changed file; swap to new record version and pop up dialog again
function show_confirm (warning_str, spell_name_str, spell_desc_str, override_list_str, curr_file_str, matching_items_str, distribution_str : string) : integer;
const
    max_line_length = 100;
    max_lines = 5;
var
    options_form : TForm;
    ok_button, cancel_button : TButton;
    warning_label, spell_name_label, spell_desc_label, matching_items_label, distribution_label : TLabel;
    override_list_label : TLabel;
    skip_once_button, skip_always_button : TButton;
    can_skip : boolean;
    school_box, level_box, method_box, delivery_box : TComboBox;
    principle_box : TCheckListBox;
    exclude_0_radio, exclude_1_radio, exclude_2_radio : TRadioButton;
    exclude_group : TRadioGroup;
    plugin_label : TLabel;
    dependent_label, exclusive_label, tome_label : TLabeledEdit;
    running_top : integer;
    i : integer;
    j : integer;
    line_count : integer;
    next_space_idx : integer;
    split_str : string;
    modal_result : TModalResult;
begin
    Result := 1;
    options_form := TForm.Create(nil);
    try
        options_form.Caption := 'Spell Library Generator';
        options_form.Width := Min(600, Screen.Width - 50);
        options_form.Height := Min(600, Screen.Height - 50);
        options_form.Position := poScreenCenter;
        options_form.KeyPreview := True;
        running_top := 10;
        
        if Length(warning_str) > 0 then begin
            warning_label := TLabel.Create(options_form);
            warning_label.Parent := options_form;
            warning_label.Top := running_top;
            warning_label.Left := 15;
            warning_label.Caption := warning_str;
            running_top := running_top + warning_label.Height + 15;
        end;
        
        spell_name_label := TLabel.Create(options_form);
        spell_name_label.Parent := options_form;
        spell_name_label.Top := running_top;
        spell_name_label.Left := 15;
        spell_name_label.Caption := spell_name_str;
        running_top := running_top + spell_name_label.Height + 15;
        
        spell_desc_label := TLabel.Create(options_form);
        spell_desc_label.Parent := options_form;
        spell_desc_label.Top := running_top;
        spell_desc_label.Left := 15;
        split_str := 'Spell description: ' + #10;
        i := 0;
        line_count := 0;
        while (i <= Length(spell_desc_str)) do begin
            if (line_count >= max_lines) then begin
                split_str := sub_str(split_str, 1, Length(split_str)-1) + '(...)';
                break;
            end;
            next_space_idx := max_line_length;
            if (Length(spell_desc_str) - i) > max_line_length then begin
                for j := max_line_length downto 1 do begin
                    if spell_desc_str[i+j] = ' ' then begin
                        next_space_idx := j;
                        break;
                    end;
                end;
            end;
            split_str := split_str + sub_str(spell_desc_str, i+1, next_space_idx) + #10;
            i := i + next_space_idx;
            line_count := line_count + 1;
        end;
        spell_desc_label.Caption := split_str;
        running_top := running_top + spell_desc_label.Height;

        can_skip := (spell_override_idx > 0);
        override_list_label := TLabel.Create(options_form);
        override_list_label.Parent := options_form;
        override_list_label.Top := running_top;
        override_list_label.Left := 15;
        if can_skip then begin
            override_list_label.Caption := 'Plugins that touch this spell:' + #10 + override_list_str + 'Are spell changes made by: <' + curr_file_str + '>' + #10 + ' irrelevant to your configurations here?' + #10 + 'If so, select _skip_ to use configurations from the file above this one in the list instead.' + #10;
        end else begin
            override_list_label.Caption := 'Plugins that touch this spell:' + #10 + override_list_str + 'Now configuring for the base file (' + curr_file_str + ')' + #10;
        end;
        running_top := running_top + override_list_label.Height;

        if can_skip then begin
            skip_once_button := TButton.Create(options_form);
            skip_once_button.Parent := options_form;
            skip_once_button.Top := running_top;
            skip_once_button.Width := (options_form.Width/3);
            skip_once_button.Left := (options_form.Width/4) - (skip_once_button.Width/2) - 10;
            skip_once_button.Caption := 'Skip file once';
            skip_once_button.ModalResult := mrYes;
            skip_once_button.Default := False;

            skip_always_button := TButton.Create(options_form);
            skip_always_button.Parent := options_form;
            skip_always_button.Top := running_top;
            skip_always_button.Width := (options_form.Width/3);
            skip_always_button.Left := (options_form.Width*3/4) - (skip_always_button.Width/2) - 10;
            skip_always_button.Caption := 'Skip file always';
            skip_always_button.ModalResult := mrAll;
            running_top := running_top + skip_always_button.Height + 10;
        end;
        
        matching_items_label := TLabel.Create(options_form);
        matching_items_label.Parent := options_form;
        matching_items_label.Top := running_top;
        matching_items_label.Left := 15;
        matching_items_label.Caption := matching_items_str;
        running_top := running_top + matching_items_label.Height + 15;
        
        distribution_label := TLabel.Create(options_form);
        distribution_label.Parent := options_form;
        distribution_label.Top := running_top;
        distribution_label.Left := 15;
        distribution_label.Caption := distribution_str;
        running_top := running_top + distribution_label.Height + 15;
        
        school_box := TComboBox.Create(options_form);
        school_box.Parent := options_form;
        school_box.Top := running_top;
        school_box.Left := 15;
        school_box.Height := 50;
        school_box.Width := options_form.Width - 50;
        school_box.Style := lbOwnerDrawVariable;
        school_box.Items.Add('Alteration');
        school_box.Items.Add('Conjuration');
        school_box.Items.Add('Destruction');
        school_box.Items.Add('Illusion');
        school_box.Items.Add('Restoration');
        if school <> -1 then begin
            school_box.Items[school] := school_box.Items[school] + ' (inferred)';
            school_box.ItemIndex := school;
        end;
        parent_box := school_box;
        school_box.OnChange := combo_box_on_change;
        running_top := running_top + school_box.Height + 10;
        
        principle_box := TCheckListBox.Create(options_form);
        principle_box.Parent := options_form;
        principle_box.Top := running_top;
        principle_box.Left := 15;
        principle_box.Height := 65;
        principle_box.Width := options_form.Width - 50;
        set_principles_box(principle_box, school);
        child_box := principle_box;
        running_top := running_top + principle_box.Height + 10;
        
        level_box := TComboBox.Create(options_form);
        level_box.Parent := options_form;
        level_box.Top := running_top;
        level_box.Left := 15;
        level_box.Height := 50;
        level_box.Width := options_form.Width - 50;
        level_box.Style := lbOwnerDrawVariable;
        level_box.Items.Add('Novice');
        level_box.Items.Add('Apprentice');
        level_box.Items.Add('Adept');
        level_box.Items.Add('Expert');
        level_box.Items.Add('Master');
        if level <> -1 then begin
            level_box.Items[level] := level_box.Items[level] + ' (inferred)';
            level_box.ItemIndex := level;
        end;
        running_top := running_top + level_box.Height + 10;
        
        method_box := TComboBox.Create(options_form);
        method_box.Parent := options_form;
        method_box.Top := running_top;
        method_box.Left := 15;
        method_box.Height := 50;
        method_box.Width := options_form.Width - 50;
        method_box.Style := lbOwnerDrawVariable;
        method_box.Items.Add('Concentration');
        method_box.Items.Add('Fire and Forget');
        method_box.Items[method] := method_box.Items[method] + ' (inferred)';
        method_box.ItemIndex := method;
        running_top := running_top + method_box.Height + 10;
        
        delivery_box := TComboBox.Create(options_form);
        delivery_box.Parent := options_form;
        delivery_box.Top := running_top;
        delivery_box.Left := 15;
        delivery_box.Height := 50;
        delivery_box.Width := options_form.Width - 50;
        delivery_box.Style := lbOwnerDrawVariable;
        delivery_box.Items.Add('Aimed');
        delivery_box.Items.Add('Location');
        delivery_box.Items.Add('Self');
        delivery_box.Items[delivery] := delivery_box.Items[delivery] + ' (inferred)';
        delivery_box.ItemIndex := delivery;
        running_top := running_top + delivery_box.Height + 10;
        
        exclude_group := TRadioGroup.Create(options_form);
        exclude_group.Parent := options_form;
        exclude_group.Left := 15;
        exclude_group.Top := running_top;
        exclude_group.Width := options_form.Width - 50;
        exclude_group.Height := 90;
        exclude_group.Caption := 'Set spell category:';
        exclude_group.ClientWidth := options_form.Width - 50;
        exclude_group.ClientHeight := 80;
        running_top := running_top + exclude_group.Height + 10;
        
        exclude_0_radio := TRadioButton.Create(exclude_group);
        exclude_0_radio.Parent := exclude_group;
        exclude_0_radio.Left := 10;
        exclude_0_radio.Width := options_form.Width - 50;
        exclude_0_radio.Top := 20;
        exclude_0_radio.Caption := 'Normal (allows all functions)';
        exclude_0_radio.Checked := (exclude_as_reward = 0);
        
        exclude_1_radio := TRadioButton.Create(exclude_group);
        exclude_1_radio.Parent := exclude_group;
        exclude_1_radio.Left := 10;
        exclude_1_radio.Width := options_form.Width - 50;
        exclude_1_radio.Top := 20 + exclude_0_radio.Height;
        exclude_1_radio.Caption := 'Restricted (spell forging not allowed unless enabled via config, other functions allowed)';
        exclude_1_radio.Checked := (exclude_as_reward = 1);
        
        exclude_2_radio := TRadioButton.Create(exclude_group);
        exclude_2_radio.Parent := exclude_group;
        exclude_2_radio.Left := 10;
        exclude_2_radio.Width := options_form.Width - 50;
        exclude_2_radio.Top := 20 + exclude_0_radio.Height + exclude_1_radio.Height;
        exclude_2_radio.Caption := 'Skip (will be unknown to the mod, no functions will work on it)';
        exclude_2_radio.Checked := (exclude_as_reward = 2);
        
        plugin_label := TLabel.Create(options_form);
        plugin_label.Parent := options_form;
        plugin_label.Top := running_top;
        plugin_label.Left := 15;
        plugin_label.Caption := 'Advanced; these options will cause this spell to be skipped by default when conditions are met on future runs of' + #10 + 'the patcher.  This is intended as a convenience for mod authors or those making patches for multiple load orders.' + #10 + 'If you are unsure, do not modify them.';
        running_top := running_top + plugin_label.Height + 30;

        dependent_label := TLabeledEdit.Create(options_form);
        dependent_label.Parent := options_form;
        dependent_label.LabelPosition := lpAbove;
        dependent_label.EditLabel.Caption := 'Skip unless this plugin is present:';
        dependent_label.Left := 15;
        dependent_label.Height := 50;
        dependent_label.Top := running_top;
        dependent_label.Width := (options_form.Width - 70)/3;
        dependent_label.Text := dependent_filename;

        exclusive_label := TLabeledEdit.Create(options_form);
        exclusive_label.Parent := options_form;
        exclusive_label.LabelPosition := lpAbove;
        exclusive_label.EditLabel.Caption := 'Skip when this plugin is present:';
        exclusive_label.Left := 25 + dependent_label.Width;
        exclusive_label.Height := 50;
        exclusive_label.Top := running_top;
        exclusive_label.Width := (options_form.Width - 70)/3;
        exclusive_label.Text := exclusive_filename;
        
        tome_label := TLabeledEdit.Create(options_form);
        tome_label.Parent := options_form;
        tome_label.LabelPosition := lpAbove;
        tome_label.EditLabel.Caption := 'Skip if tome name matches:';
        tome_label.Left := 35 + dependent_label.Width + exclusive_label.Width;
        tome_label.Height := 50;
        tome_label.Top := running_top;
        tome_label.Width := (options_form.Width - 70)/3;
        tome_label.Text := exclusive_tome_name;
        running_top := running_top + tome_label.Height;
        
        ok_button := TButton.Create(options_form);
        ok_button.Parent := options_form;
        ok_button.Top := running_top;
        ok_button.Width := (options_form.Width/3);
        ok_button.Left := (options_form.Width/4) - (ok_button.Width/2) - 10;
        ok_button.Caption := 'OK';
        ok_button.ModalResult := mrOk;
        ok_button.Default := True;
        
        cancel_button := TButton.Create(options_form);
        cancel_button.Parent := options_form;
        cancel_button.Top := running_top;
        cancel_button.Width := (options_form.Width/3);
        cancel_button.Left := (options_form.Width*3/4) - (cancel_button.Width/2) - 10;
        cancel_button.Caption := 'Cancel and Exit';
        cancel_button.ModalResult := mrCancel;
        running_top := running_top + cancel_button.Height + 70;
        
        options_form.Height := Min(running_top, Screen.Height - 50);
        
        modal_result := options_form.ShowModal;
        if modal_result = mrCancel then begin
            spell_override_idx := -1;
            Result := 0;
        end else if modal_result = mrOK then begin
            school := school_box.ItemIndex;
            principle_0 := principle_box.Checked[0];
            principle_1 := principle_box.Checked[1];
            principle_2 := principle_box.Checked[2];
            principle_3 := principle_box.Checked[3];
            level := level_box.ItemIndex;
            method := method_box.ItemIndex;
            delivery := delivery_box.ItemIndex;
            dependent_filename := dependent_label.Text;
            exclusive_filename := exclusive_label.Text;
            exclusive_tome_name := tome_label.Text;
            if exclude_0_radio.Checked then begin
                exclude_as_reward := 0;
            end else if exclude_1_radio.Checked then begin
                exclude_as_reward := 1;
            end else if exclude_2_radio.Checked then begin
                exclude_as_reward := 2;
            end;
            spell_override_idx := -1;
            Result := 1;
        end else begin
            if modal_result = mrAll then begin
                files_to_skip.Add(curr_file_str);
            end;
            spell_override_idx := spell_override_idx - 1;
            Result := 2;
        end;
    finally
        options_form.Free;
    end;
end;

// final config dialog; update override file with any new overrides from confirm pop-ups, or leave as before?
function show_finalize_options : boolean;
var
    options_form : TForm;
    ok_button : TButton;
    update_radio, no_update_radio : TRadioButton;
    update_group : TRadioGroup;
    running_top : integer;
begin
    Result := True;
    options_form := TForm.Create(nil);
    try
        options_form.Caption := 'Spell Library Generator Finalize';
        options_form.Width := 300;
        options_form.Height := 180;
        options_form.Position := poScreenCenter;
        options_form.KeyPreview := True;
        running_top := 30;
        
        update_group := TRadioGroup.Create(options_form);
        update_group.Parent := options_form;
        update_group.Left := 15;
        update_group.Top := running_top;
        update_group.Width := 250;
        update_group.Height := 50;
        update_group.Caption := 'Overwrite config with updated spell info?';
        update_group.ClientWidth := 250;
        update_group.ClientHeight := 50;
        running_top := running_top + update_group.Height + 20;
        
        update_radio := TRadioButton.Create(update_group);
        update_radio.Parent := update_group;
        update_radio.Left := 10;
        update_radio.Top := 20;
        update_radio.Caption := 'Yes';
        update_radio.Checked := True;
        
        no_update_radio := TRadioButton.Create(update_group);
        no_update_radio.Parent := update_group;
        no_update_radio.Left := update_radio.Left + update_radio.Width + 20;
        no_update_radio.Top := 20;
        no_update_radio.Caption := 'No';
        no_update_radio.Checked := False;
        
        ok_button := TButton.Create(options_form);
        ok_button.Parent := options_form;
        ok_button.Top := running_top;
        ok_button.Width := 100;
        ok_button.Left := (options_form.Width/2) - (ok_button.Width/2) - 10;
        ok_button.Caption := 'OK';
        ok_button.Anchors := [akRight, akBottom];
        ok_button.ModalResult := mrOk;
        
        running_top := running_top + ok_button.Height + 20;
        
        if options_form.ShowModal = mrOk then begin
            update_override_file := update_radio.Checked;
            Result := False;
        end else begin
            Result := True;
        end;
    finally
        options_form.Free;
    end;
end;

function check_skip(spell_name, override_list, first_file : string): boolean;
var
    options_form : TForm;
    ok_button, cancel_button : TButton;
    running_top : integer;
begin
    AddMessage('Spell "' + spell_name + '" is modified by files (in load order):');
    AddMessage(override_list);
    AddMessage('A library entry exists for file "' + first_file + '"; use it and ignore all following patches?  This is recommended if following patches do not change spell classification.');

    options_form := TForm.Create(nil);
    try
        options_form.Caption := 'Spell Discovery Auto-Patcher';
        options_form.Width := 300;
        options_form.Height := 180;
        options_form.Position := poScreenCenter;
        options_form.KeyPreview := True;
        running_top := 30;

        
        ok_button := TButton.Create(options_form);
        ok_button.Parent := options_form;
        ok_button.Top := running_top;
        ok_button.Width := 100;
        ok_button.Left := (options_form.Width/4) - (ok_button.Width/2) - 10;
        ok_button.Caption := 'OK';
        ok_button.Anchors := [akRight, akBottom];
        ok_button.ModalResult := mrOk;
        
        cancel_button := TButton.Create(options_form);
        cancel_button.Parent := options_form;
        cancel_button.Top := running_top;
        cancel_button.Width := 100;
        cancel_button.Left := (options_form.Width*3/4) - (cancel_button.Width/2) - 10;
        cancel_button.Caption := 'Cancel';
        cancel_button.Anchors := [akRight, akBottom];
        cancel_button.ModalResult := mrCancel;
        running_top := running_top + cancel_button.Height + 20;
        
        if options_form.ShowModal = mrCancel then begin
            Result := True;
        end else begin
            update_override_file := update_radio.Checked;
            Result := False;
        end;
    finally
        options_form.Free;
    end;
end;

// helper function; like SubStr, but if the substring would go past the end of s, just cut it off with no error
function sub_str (const s : string; start_pos : integer; count : integer) : string;
var
    i : integer;
    s_arr : string;
begin
    s_arr := s;
    Result := '';
    for i := start_pos to (start_pos + count - 1) do begin
        if (i > Length(s)) or (i < 1) then
            break;
        Result := Result + s_arr[i];
    end;
end;

// fill_principles_* functions attempt to guess what principle describes the passed-in record (assumed to be MGEF)
// each generally functions by checking the effect archetype, what AV (if any) it modifies, and attached keywords
// these functions will not make a guess for Script-type effects, unless they are tagged with certain keywords

// {modification, construct, force, abstract}
function fill_principles_alteration(e : IInterface) : boolean;
var
    i : integer;
    archetype : string;
    primary_av : string;
    keywords : IInterface;
    keyword_count : integer;
begin
    Result := False;
    archetype := GetElementEditValues(e, 'DATA\DATA\Archtype');
    primary_av := GetElementEditValues(e, 'DATA\DATA\Actor Value');
    if (archetype = 'Value Modifier') or (archetype = 'Peak Value Modifier') then begin
        if primary_av = 'Water Breathing' then begin
            principle_3 := True;
            Result := True;
        end else if primary_av = 'Water Walking' then begin
            principle_2 := True;
            Result := True;
        end else if (primary_av = 'Heal Rate') or (primary_av = 'Magicka Rate') or (primary_av = 'Stamina Rate') or (primary_av = 'Speed Mult') or (primary_av = 'Damage Resist') or (primary_av = 'Poison Resist') or (primary_av = 'Fire Resist') or (primary_av = 'Electric Resist') or (primary_av = 'Frost Resist') or (primary_av = 'Magic Resist') or (primary_av = 'Disease Resist') or (primary_av = 'Weapon Speed Mult') or (primary_av = 'Heal Rate Mult') or (primary_av = 'Magicka Rate Mult') or (primary_av = 'Stamina Rate Mult') then begin
            principle_0 := True;
            Result := True;
        end;
    end else if (archetype = 'Light') then begin
        principle_1 := True;
        Result := True;
    end else if (archetype = 'Telekinesis') or (archetype = 'Lock') or (archetype = 'Open') then begin
        principle_2 := True;
        Result := True;
    end else if (archetype = 'Paralysis') or (archetype = 'Stagger') or (archetype = 'Grab Actor') then begin
        principle_2 := True;
        Result := True;
    end else if (archetype = 'Detect Life') then begin
        principle_3 := True;
        Result := True;
    end;
    //if not Result then begin
    keywords := ElementByPath(e, 'KWDA');
    keyword_count := ElementCount(keywords);
    for i := 0 to (keyword_count - 1) do begin
        if Equals(LinksTo(ElementByIndex(keywords, i)), RecordByFormID(main_file, $0001ea70, True)) then begin
            principle_2 := True; // MagicParalysis
            Result := True;
        end;
    end;
    //end;
end;

// {daedric, necromantic, spirit, bindings}
function fill_principles_conjuration(e : IInterface) : boolean;
var
    i : integer;
    archetype : string;
    primary_av : string;
    related_id : IInterface;
    summoned_race : IInterface;
    keywords : IInterface;
    keyword_count : integer;
begin
    Result := False;
    archetype := GetElementEditValues(e, 'DATA\DATA\Archtype');
    primary_av := GetElementEditValues(e, 'DATA\DATA\Actor Value');
    related_id := LinksTo(ElementByPath(e, 'DATA\DATA\Assoc. Item'));
    
    if (archetype = 'Summon Creature') then begin
        // retrieve keywords for the summoned creature race
        summoned_race := LinksTo(ElementByPath(related_id, 'RNAM'));
        keywords := ElementByPath(summoned_race, 'KWDA');
        keyword_count := ElementCount(keywords);
        for i := 0 to (keyword_count - 1) do begin
            if Equals(LinksTo(ElementByIndex(keywords, i)), RecordByFormID(main_file, $00013797, True)) then begin
                principle_0 := True; // ActorTypeDaedra
                Result := True;
            end else if Equals(LinksTo(ElementByIndex(keywords, i)), RecordByFormID(main_file, $00013796, True)) then begin
                principle_1 := True; // ActorTypeUndead
                Result := True;
            end;
        end;
        if (keyword_count > 0) and not (principle_0 or principle_1) then begin
            principle_2 := True; // summon spells that aren't daedra or undead
            Result := True;
        end;
    end else if (archetype = 'Reanimate') then begin
        principle_1 := True;
        Result := True;
    end else if (archetype = 'Bound Weapon') or (archetype = 'Soul Trap') then begin
        principle_3 := True;
        Result := True;
    end;
    
    keywords := ElementByPath(e, 'KWDA');
    keyword_count := ElementCount(keywords);
    for i := 0 to (keyword_count - 1) do begin
        if Equals(LinksTo(ElementByIndex(keywords, i)), RecordByFormID(main_file, $0002482B, True)) then begin
            principle_1 := True; // MagicSummonUndead
            Result := True;
        end;
    end;
end;

// {fire, frost, shock, unaspected}
function fill_principles_destruction(e : IInterface) : boolean;
var
    mgef_keywords : IInterface;
    keyword_count : integer;
    resist_value : string;
    i : integer;
begin
    Result := False;
    mgef_keywords := ElementByPath(e, 'KWDA');
    keyword_count := ElementCount(mgef_keywords);
    resist_value := GetElementEditValues(e, 'DATA\DATA\Resist Value');
    for i := 0 to (keyword_count - 1) do begin
        if Equals(LinksTo(ElementByIndex(mgef_keywords, i)), RecordByFormID(main_file, $0001cead, True)) or (resist_value = 'Resist Fire') then begin
            principle_0 := True;
            Result := True;
        end;
        if Equals(LinksTo(ElementByIndex(mgef_keywords, i)), RecordByFormID(main_file, $0001ceae, True)) or (resist_value = 'Resist Frost') then begin
            principle_1 := True;
            Result := True;
        end;
        if Equals(LinksTo(ElementByIndex(mgef_keywords, i)), RecordByFormID(main_file, $0001ceaf, True)) or (resist_value = 'Resist Shock') then begin
            principle_2 := True;
            Result := True;
        end;
    end;
end;

// {concealing, overwhelming, projection, arcane}
function fill_principles_illusion(e : IInterface) : boolean;
var
    i : integer;
    archetype : string;
    primary_av : string;
    related_id : IInterface;
    keywords : IInterface;
    curr_keyword : IInterface;
    keyword_count : integer;
begin
    Result := False;
    archetype := GetElementEditValues(e, 'DATA\DATA\Archtype');
    primary_av := GetElementEditValues(e, 'DATA\DATA\Actor Value');
    related_id := LinksTo(ElementByPath(e, 'DATA\DATA\Assoc. Item'));
    
    if (archetype = 'Invisibility') then begin
        principle_0 := True;
        Result := True;
    end else if (archetype = 'Calm') or (archetype = 'Demoralize') or (archetype = 'Frenzy') or (archetype = 'Rally')  then begin
        principle_1 := True;
        Result := True;
    end else if (archetype = 'Peak Value Modifier') then begin
        if (primary_av = 'Movement Noise Mult') then begin
            principle_0 := True;
            Result := True;
        end else if (primary_av = 'Aggression') or (primary_av = 'Confidence') or (primary_av = 'Energy') or (primary_av = 'Morality') or (primary_av = 'Assistance') then begin
            principle_1 := True;
            Result := True;
        end else if (primary_av = 'Health') or (primary_av = 'Magicka') or (primary_av = 'Stamina') then begin
            principle_2 := True;
            Result := True;
        end;
    end else if (archetype = 'Guide') or (archetype = 'Dispel') then begin
        principle_3 := True;
        Result := True;
    end;
    
    keywords := ElementByPath(e, 'KWDA');
    keyword_count := ElementCount(keywords);
    for i := 0 to (keyword_count - 1) do begin
        curr_keyword := LinksTo(ElementByIndex(keywords, i));
        if Equals(curr_keyword, RecordByFormID(main_file, $00078098, True)) or // MagicInfluence
           Equals(curr_keyword, RecordByFormID(main_file, $000424EE, True)) or // MagicInfluenceCharm
           Equals(curr_keyword, RecordByFormID(main_file, $000424E0, True)) or // MagicInfluenceFear
           Equals(curr_keyword, RecordByFormID(main_file, $000c44b6, True)) then begin // MagicInfluenceFrenzy
            principle_1 := True;
            Result := True;
        end;
    end;
end;

// {righteous, defensive, curing, consuming}
function fill_principles_restoration(e : IInterface) : boolean;
var
    i : integer;
    archetype : string;
    primary_av : string;
    related_id : IInterface;
    detrimental : boolean;
    keywords : IInterface;
    curr_keyword : IInterface;
    keyword_count : integer;
    conditions : IInterface;
    curr_condition : IInterface;
    condition_invert : boolean;
    condition_count : integer;
    resist_value : string;
begin
    Result := False;
    archetype := GetElementEditValues(e, 'DATA\DATA\Archtype');
    primary_av := GetElementEditValues(e, 'DATA\DATA\Actor Value');
    related_id := LinksTo(ElementByPath(e, 'DATA\DATA\Assoc. Item'));
    detrimental := (sub_str(GetElementEditValues(e, 'DATA\DATA\Flags'),3,1) = '1');
    
    conditions := ElementByPath(e, 'Conditions');
    condition_count := ElementCount(conditions);
    
    if (archetype = 'Turn Undead') then begin
        principle_0 := True;
        Result := True;
    end else if (archetype = 'Peak Value Modifier') then begin
        if not detrimental then begin
            principle_1 := True;
            Result := True;
        end;
    end else if (archetype = 'Value Modifier') and (primary_av = 'Health') then begin
        if not detrimental then begin
            principle_2 := True;
            Result := True;
        end else begin
            // if damage is done, check the conditions
            for i := 0 to (condition_count - 1) do begin
                curr_condition := ElementByIndex(ElementByIndex(conditions, i),0);
                condition_invert := (GetElementNativeValues(curr_condition, 'Comparison Value') = 0);
                if GetElementEditValues(curr_condition, 'Function') = 'HasKeyword' then begin
                    curr_keyword := LinksTo(ElementByPath(curr_condition, 'Parameter #1'));
                    if Equals(curr_keyword, RecordByFormID(main_file, $00013796, True)) then begin // ActorTypeUndead
                        if condition_invert then begin // works on non-undead
                            principle_3 := True;
                        end else begin // works on undead
                            principle_0 := True;
                        end;
                        Result := True;
                    end;
                end else if (GetElementEditValues(curr_condition, 'Function') = 'IsUndead') then begin
                    if condition_invert then begin // works on non-undead
                        principle_3 := True;
                    end else begin // works on undead
                        principle_0 := True;
                    end;
                    Result := True;
                end;
            end;
        end;
    end;
    
    keywords := ElementByPath(e, 'KWDA');
    keyword_count := ElementCount(keywords);
    
    for i := 0 to (keyword_count - 1) do begin
        curr_keyword := LinksTo(ElementByIndex(keywords, i));
        if Equals(curr_keyword, RecordByFormID(main_file, $000BD83F, True)) then begin // MagicTurnUndead
            principle_0 := True;
            Result := True;
        end else if Equals(curr_keyword, RecordByFormID(main_file, $0001EA69, True)) then begin // MagicWard
            principle_1 := True;
            Result := True;
        end else if Equals(curr_keyword, RecordByFormID(main_file, $0001CEB0, True)) then begin // MagicRestoreHealth
            principle_2 := True;
            Result := True;
        end;
    end;
    
    resist_value := GetElementEditValues(e, 'DATA\DATA\Resist Value');
    if resist_value = 'Poison Resist' then begin
        principle_3 := True;
        Result := True;
    end;
end;

// debug - print all keywords attached to the given record
procedure print_keywords(form : IInterface);
var
    i : integer;
    keywords : IInterface;
    keyword_count : integer;
begin
    keywords := ElementByPath(form, 'KWDA');
    keyword_count := ElementCount(keywords);
    for i := 0 to (keyword_count - 1) do begin
        AddMessage('    ' + GetEditValue(ElementByIndex(keywords, i)));
    end;
end;

// debug - print some information about a MGEF that I found useful when designing the fill_principles_* functions
procedure print_principles_info(e : IInterface);
begin
    AddMessage('');
    AddMessage(FullPath(e));
    AddMessage('    ' + GetElementEditValues(e, 'DATA\DATA\Archtype'));
    AddMessage('    ' + GetElementEditValues(e, 'DATA\DATA\Actor Value'));
    AddMessage('    ' + GetElementEditValues(e, 'DATA\DATA\Resist Value'));
    AddMessage('    ' + GetElementEditValues(e, 'DATA\DATA\Assoc. Item'));
    print_keywords(e);
end;

// top-level function to guess at principles for the current spell
// assumes mgef_array (global) is filled and mgef_count corresponds to that
// presumably from running get_mgef_list()
function fill_principles(school : integer; mgef_count : integer) : boolean;
var
    i : integer;
    sure_about_result : boolean;
    had_nested_spell : boolean;
    nested_spell : IInterface;
begin
    Result := False;
    sure_about_result := False;
    
    if school = 0 then begin
        for i := 0 to (mgef_count - 1) do begin
            //print_principles_info(mgef_array[i]);
            if fill_principles_alteration(mgef_array[i]) then
                sure_about_result := True;
        end;
    end else if school = 1 then begin
        for i := 0 to (mgef_count - 1) do begin
            //print_principles_info(mgef_array[i]);
            if fill_principles_conjuration(mgef_array[i]) then
                sure_about_result := True;
        end;
    end else if school = 2 then begin
        for i := 0 to (mgef_count - 1) do begin
            //print_principles_info(mgef_array[i]);
            if fill_principles_destruction(mgef_array[i]) then
                sure_about_result := True;
        end;
        if (not (principle_0 or principle_1 or principle_2)) then begin
            principle_3 := True; // set to unaspected if not fire, frost, or shock
        end;
    end else if school = 3 then begin
        for i := 0 to (mgef_count - 1) do begin
            //print_principles_info(mgef_array[i]);
            if fill_principles_illusion(mgef_array[i]) then
                sure_about_result := True;
        end;
    end else if school = 4 then begin
        for i := 0 to (mgef_count - 1) do begin
            //print_principles_info(mgef_array[i]);
            if fill_principles_restoration(mgef_array[i]) then
                sure_about_result := True;
        end;
    end else begin // this happens for spells that don't have a vanilla half-cost perk
        // commenting because it's not really important to have that warning printed, there'll be a popup anyway
        //AddMessage('WARNING: invalid school passed in: ' + inttostr(school));
    end;
    
    if (not sure_about_result) then begin
        //AddMessage('WARNING: not sure about this principle result!');
        Result := False;
    end else begin
        Result := True;
    end;
end;

// populate mgef_array with effects from s (assumed SPEL)
// start_idx is the index from which to start adding to the array
// allow_recurse, if true, means this function will add MGEF from associated cloaks and hazards (depth-first)
function get_mgef_list(s : IInterface; start_idx : integer = 0; allow_recurse : boolean = True) : integer;
var
    i : integer;
    mgef_count : integer;
    max_count : integer;
    array_pos : integer;
    current_effect : IInterface;
    archetype : string;
begin
    max_count := 20;
    array_pos := start_idx;
    mgef_count := ElementCount(ElementByPath(s, 'Effects'));
    for i := 0 to (mgef_count - 1) do begin
        if array_pos >= max_count then begin
            AddMessage('WARNING: clipping to ' + inttostr(max_count) + ' first MGEF');
            break;
        end;
        
        current_effect := LinksTo(ElementByIndex(ElementByIndex(ElementByPath(s, 'Effects'), i), 0));
        mgef_array[array_pos] := current_effect;
        array_pos := array_pos + 1;
        if allow_recurse then begin
            archetype := GetElementEditValues(current_effect, 'DATA\DATA\Archtype');
            if archetype = 'Cloak' then begin
                array_pos := get_mgef_list(LinksTo(ElementByPath(current_effect, 'DATA\DATA\Assoc. Item')), array_pos, allow_recurse);
            end else if archetype = 'Spawn Hazard' then begin
                array_pos := get_mgef_list(LinksTo(ElementByPath(LinksTo(ElementByPath(current_effect, 'DATA\DATA\Assoc. Item')), 'DATA\Spell')), array_pos, allow_recurse);
            end;
        end;
    end;
    Result := array_pos;
end;

// infer school and level from associated half-cost perk
// returns (school*5) + level
// (if none matches, return -1)
function get_school_and_level(s : IInterface) : integer;
var
    i : integer;
    perk : IInterface;
begin
    perk := LinksTo(ElementByPath(s, 'SPIT\Half-cost Perk'));
    //AddMessage('    ' + FullPath(s));
    //AddMessage('    ' + FullPath(perk));
    for i := 0 to 24 do begin
        if Equals(perk, perk_array[i]) then begin
            Result := i;
            Exit;
        end;
    end;
    Result := -1;
end;

// construct a string that will be displayed in a confirm dialog
// this string lists other records that reference the item
// so for a spell tome, this might be a merchant chest and leveled list
// (the basic idea here is to let the user distinguish spells that are only available via quest,
//  so they can be excluded from discovery if desired)
function get_distribution_str(item : IInterface; max_count : integer) : string;
var
    i : integer;
    count : integer;
    added : integer;
    elem : IInterface;
begin
    Result := 'Distribution:';
    count := ReferencedByCount(item);
    added := 0;
    for i := 0 to (count-1) do begin // put leveled lists first (only so many items will be displayed, so prioritize)
        if added >= max_count then begin
            Result := Result + #10 + '(...)';
            Exit;
        end;
        elem := ReferencedByIndex(item, i);
        if (Signature(elem) = 'LVLI') then begin
            Result := Result + #10 + ' - ' + Name(elem);
            added := added + 1;
        end;
    end;
    for i := 0 to (count-1) do begin // containers, recipes, and quest/dialogue entries follow leveled lists
        if added >= max_count then begin
            Result := Result + #10 + '(...)';
            Exit;
        end;
        elem := ReferencedByIndex(item, i);
        if (Signature(elem) = 'CONT') or (Signature(elem) = 'COBJ') or (Signature(elem) = 'QUST') or (Signature(elem) = 'DIAL') or (Signature(elem) = 'INFO') then begin
            Result := Result + #10 + ' - ' + Name(elem);
            added := added + 1;
        end;
    end;
    for i := 0 to (count-1) do begin // anything else comes after
        if added >= max_count then begin
            Result := Result + #10 + '(...)';
            Exit;
        end;
        elem := ReferencedByIndex(item, i);
        if (Signature(elem) <> 'LVLI') and (Signature(elem) <> 'CONT') and (Signature(elem) <> 'COBJ') and (Signature(elem) <> 'QUST') and (Signature(elem) <> 'DIAL') and (Signature(elem) <> 'INFO') then begin
            Result := Result + #10 + ' - ' + Name(elem);
            added := added + 1;
        end;
    end;
end;

// remove all items from the given flist
procedure clear_flist(flist : IInterface);
var
    i : integer;
    form_ids : IInterface;
begin
    form_ids := ElementByPath(flist, 'FormIDs');
    while (ElementCount(form_ids) > 0) do begin
        RemoveElement(form_ids, LastElement(form_ids));
    end;
end;

// add elem to flist
// will correctly handle an flist that was created empty and does not yet have FormIDs
procedure add_to_flist(flist : IInterface; elem : IInterface);
var
    form_ids : IInterface;
    intermediate : IInterface;
    main_record : IwbMainRecord;
    containing_file : IwbFile;
    master_count : integer;
    i : integer;
begin
    form_ids := ElementByPath(flist, 'FormIDs');
    if not Assigned(form_ids) then begin
        form_ids := Add(flist, 'FormIDs', False);
        intermediate := ElementByIndex(form_ids, 0);
    end else begin
        intermediate := ElementAssign(form_ids, HighInteger, nil, False);
    end;
    // main_record is the base version of the record to add
    // (if USSEP changes a SPEL record (elem), we only need to add the Skyrim.esm version of the record (main_record)
    //  and don't need USSEP as a master)
    main_record := MasterOrSelf(ContainingMainRecord(elem));
    containing_file := GetFile(main_record);
    master_count := MasterCount(containing_file);
    AddMasterIfMissing(patch_file, GetFileName(containing_file));
    for i := 0 to (master_count - 1) do begin
        // being extra paranoid here about trying to add all masters that might be necessary
        AddMasterIfMissing(patch_file, GetFileName(MasterByIndex(containing_file, i)));
    end;
    
    SetEditValue(intermediate, ShortName(main_record));
end;

// runs once at the beginning
function Initialize: integer;
var
    i : integer;
    found_base : boolean;
    found_patch : boolean;
    patch_prefix : string;
begin
    Result := 0;

    // defaults
    override_filename := ScriptsPath + 'aaSpellLibraryGenerator.csv';
    patch_filename := 'Spellforge - Library - Base - Custom.esp';
    // testing defaults
    //override_filename := ScriptsPath + 'a.csv';
    //patch_filename := 'tester.esp';
    
    if show_init_options() then begin // options dialog; if canceled, exit
        Result := 1;
        Exit;
    end;
    if load_overrides() then begin // read override file; if canceled, exit
        Result := 1;
        Exit;
    end;
    
    main_file := FileByIndex(0);
    // by default, reference info is not built for Skyrim.esm, so do it once at the beginning
    if ContainerStates(main_file) and (1 shl csRefsBuild) = 0 then begin
        AddMessage('Building reference info for Skyrim.esm...');
        BuildRef(main_file);
    end;
    
    // locate the mod main file and (if existing) the patch file
    // there is probably a better way to do this, but I don't know what it is
    AddMessage('Checking for main mod and pre-existing library file...');
    for i := 0 to (FileCount - 1) do begin
        if GetFileName(FileByLoadOrder(i)) = 'Spellforge.esp' then begin
            dino_file := FileByLoadOrder(i);
            found_base := True;
        end;
        if GetFileName(FileByLoadOrder(i)) = patch_filename then begin
            patch_file := FileByLoadOrder(i);
            found_patch := True;
        end;
    end;
    if (not found_base) then begin
        AddMessage('ERROR: Spellforge.esp must be loaded to use the generator');
        Result := 1;
        Exit;
    end;
    if (not found_patch) then begin
        // create patch and give it Skyrim.esm and DinoSpellDiscovery.esp as master
        patch_file := AddNewFileName(patch_filename);
        AddMasterIfMissing(patch_file, GetFileName(main_file));
        AddMasterIfMissing(patch_file, GetFileName(dino_file));
        
        // create FLST overrides from patch file records
        principle_flist_array[0] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple00'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[0], 'EDID', 'aaSimpleFListPrinciple00');
        principle_flist_array[1] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple01'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[1], 'EDID', 'aaSimpleFListPrinciple01');
        principle_flist_array[2] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple02'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[2], 'EDID', 'aaSimpleFListPrinciple02');
        principle_flist_array[3] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple03'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[3], 'EDID', 'aaSimpleFListPrinciple03');
        principle_flist_array[4] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple04'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[4], 'EDID', 'aaSimpleFListPrinciple04');
        principle_flist_array[5] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple05'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[5], 'EDID', 'aaSimpleFListPrinciple05');
        principle_flist_array[6] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple06'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[6], 'EDID', 'aaSimpleFListPrinciple06');
        principle_flist_array[7] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple07'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[7], 'EDID', 'aaSimpleFListPrinciple07');
        principle_flist_array[8] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple08'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[8], 'EDID', 'aaSimpleFListPrinciple08');
        principle_flist_array[9] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple09'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[9], 'EDID', 'aaSimpleFListPrinciple09');
        principle_flist_array[10] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple10'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[10], 'EDID', 'aaSimpleFListPrinciple10');
        principle_flist_array[11] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple11'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[11], 'EDID', 'aaSimpleFListPrinciple11');
        principle_flist_array[12] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple12'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[12], 'EDID', 'aaSimpleFListPrinciple12');
        principle_flist_array[13] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple13'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[13], 'EDID', 'aaSimpleFListPrinciple13');
        principle_flist_array[14] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple14'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[14], 'EDID', 'aaSimpleFListPrinciple14');
        principle_flist_array[15] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple15'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[15], 'EDID', 'aaSimpleFListPrinciple15');
        principle_flist_array[16] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple16'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[16], 'EDID', 'aaSimpleFListPrinciple16');
        principle_flist_array[17] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple17'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[17], 'EDID', 'aaSimpleFListPrinciple17');
        principle_flist_array[18] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple18'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[18], 'EDID', 'aaSimpleFListPrinciple18');
        principle_flist_array[19] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListPrinciple19'), patch_file, False, False);
        SetElementEditValues(principle_flist_array[19], 'EDID', 'aaSimpleFListPrinciple19');
        
        delivery_flist_array[0] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListDeliveryAimed'), patch_file, False, False);
        SetElementEditValues(delivery_flist_array[0], 'EDID', 'aaSimpleFListDeliveryAimed');
        delivery_flist_array[1] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListDeliveryLocation'), patch_file, False, False);
        SetElementEditValues(delivery_flist_array[1], 'EDID', 'aaSimpleFListDeliveryLocation');
        delivery_flist_array[2] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListDeliverySelf'), patch_file, False, False);
        SetElementEditValues(delivery_flist_array[2], 'EDID', 'aaSimpleFListDeliverySelf');
        
        method_flist_array[0] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListMethodConcentration'), patch_file, False, False);
        SetElementEditValues(method_flist_array[0], 'EDID', 'aaSimpleFListMethodConcentration');
        method_flist_array[1] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListMethodFireForget'), patch_file, False, False);
        SetElementEditValues(method_flist_array[1], 'EDID', 'aaSimpleFListMethodFireForget');
        
        level_flist_array[0] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListLevel0Novice'), patch_file, False, False);
        SetElementEditValues(level_flist_array[0], 'EDID', 'aaSimpleFListLevel0Novice');
        level_flist_array[1] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListLevel1Apprentice'), patch_file, False, False);
        SetElementEditValues(level_flist_array[1], 'EDID', 'aaSimpleFListLevel1Apprentice');
        level_flist_array[2] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListLevel2Adept'), patch_file, False, False);
        SetElementEditValues(level_flist_array[2], 'EDID', 'aaSimpleFListLevel2Adept');
        level_flist_array[3] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListLevel3Expert'), patch_file, False, False);
        SetElementEditValues(level_flist_array[3], 'EDID', 'aaSimpleFListLevel3Expert');
        level_flist_array[4] := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListLevel4Master'), patch_file, False, False);
        SetElementEditValues(level_flist_array[4], 'EDID', 'aaSimpleFListLevel4Master');
        
        rewards_exclude_flist := wbCopyElementToFile(MainRecordByEditorID(GroupBySignature(dino_file, 'FLST'), 'aaSimpleFListRewardsExclude'), patch_file, False, False);
        SetElementEditValues(rewards_exclude_flist, 'EDID', 'aaSimpleFListRewardsExclude');
        
        AddMessage('No existing ' + patch_filename + ' found, created from scratch');
    end else begin
        // if patch file exists, retrieve FLST records
        principle_flist_array[0] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), 'aaSimpleFListPrinciple00');
        if Assigned(principle_flist_array[0]) then begin
            patch_prefix := 'aaSimpleFList';
        end else begin
            patch_prefix := 'aaSimpleFListPatch';
            principle_flist_array[0] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle00');
        end;
        principle_flist_array[1] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle01');
        principle_flist_array[2] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle02');
        principle_flist_array[3] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle03');
        principle_flist_array[4] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle04');
        principle_flist_array[5] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle05');
        principle_flist_array[6] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle06');
        principle_flist_array[7] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle07');
        principle_flist_array[8] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle08');
        principle_flist_array[9] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle09');
        principle_flist_array[10] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle10');
        principle_flist_array[11] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle11');
        principle_flist_array[12] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle12');
        principle_flist_array[13] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle13');
        principle_flist_array[14] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle14');
        principle_flist_array[15] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle15');
        principle_flist_array[16] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle16');
        principle_flist_array[17] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle17');
        principle_flist_array[18] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle18');
        principle_flist_array[19] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Principle19');
        
        delivery_flist_array[0] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'DeliveryAimed');
        delivery_flist_array[1] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'DeliveryLocation');
        delivery_flist_array[2] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'DeliverySelf');
        
        method_flist_array[0] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'MethodConcentration');
        method_flist_array[1] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'MethodFireForget');
        
        level_flist_array[0] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Level0Novice');
        level_flist_array[1] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Level1Apprentice');
        level_flist_array[2] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Level2Adept');
        level_flist_array[3] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Level3Expert');
        level_flist_array[4] := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'Level4Master');
        
        rewards_exclude_flist := MainRecordByEditorID(GroupBySignature(patch_file, 'FLST'), patch_prefix + 'RewardsExclude');
        
        // clear FLST if start from scratch was chosen in initialization dialog
        if patch_from_scratch then begin
            for i := 0 to 19 do begin
                clear_flist(principle_flist_array[i]);
            end;
            for i := 0 to 2 do begin
                clear_flist(delivery_flist_array[i]);
            end;
            for i := 0 to 1 do begin
                clear_flist(method_flist_array[i]);
            end;
            for i := 0 to 4 do begin
                clear_flist(level_flist_array[i]);
            end;
            clear_flist(rewards_exclude_flist);
            CleanMasters(patch_file);
            AddMessage('Found ' + patch_filename + ', cleared out formlists to start from scratch');
        end else begin
            AddMessage('Found ' + patch_filename + ', will add to existing formlists');
        end;
    end;
    
    // half-cost perks associated with each spell
    // will use these to infer the school and level of each spell
    // alteration
    perk_array[0] := RecordByFormID(main_file, $000f2ca6, True);
    perk_array[1] := RecordByFormID(main_file, $000c44b7, True);
    perk_array[2] := RecordByFormID(main_file, $000c44b8, True);
    perk_array[3] := RecordByFormID(main_file, $000c44b9, True);
    perk_array[4] := RecordByFormID(main_file, $000c44ba, True);
    
    // conjuration
    perk_array[5] := RecordByFormID(main_file, $000f2ca7, True);
    perk_array[6] := RecordByFormID(main_file, $000c44bb, True);
    perk_array[7] := RecordByFormID(main_file, $000c44bc, True);
    perk_array[8] := RecordByFormID(main_file, $000c44bd, True);
    perk_array[9] := RecordByFormID(main_file, $000c44be, True);
    
    // destruction
    perk_array[10] := RecordByFormID(main_file, $000f2ca8, True);
    perk_array[11] := RecordByFormID(main_file, $000c44bf, True);
    perk_array[12] := RecordByFormID(main_file, $000c44c0, True);
    perk_array[13] := RecordByFormID(main_file, $000c44c1, True);
    perk_array[14] := RecordByFormID(main_file, $000c44c2, True);
    
    // illusion
    perk_array[15] := RecordByFormID(main_file, $000f2ca9, True);
    perk_array[16] := RecordByFormID(main_file, $000c44c3, True);
    perk_array[17] := RecordByFormID(main_file, $000c44c4, True);
    perk_array[18] := RecordByFormID(main_file, $000c44c5, True);
    perk_array[19] := RecordByFormID(main_file, $000c44c6, True);
    
    // restoration
    perk_array[20] := RecordByFormID(main_file, $000f2caa, True);
    perk_array[21] := RecordByFormID(main_file, $000c44c7, True);
    perk_array[22] := RecordByFormID(main_file, $000c44c8, True);
    perk_array[23] := RecordByFormID(main_file, $000c44c9, True);
    perk_array[24] := RecordByFormID(main_file, $000c44ca, True);
    
    principle_names[0] := 'Modification'; // alteration
    principle_names[1] := 'Construct';
    principle_names[2] := 'Force';
    principle_names[3] := 'Abstract';
    principle_names[4] := 'Daedric';      // conjuration
    principle_names[5] := 'Necromantic';
    principle_names[6] := 'Spirit';
    principle_names[7] := 'Bindings';
    principle_names[8] := 'Fire';         // destruction
    principle_names[9] := 'Frost';
    principle_names[10] := 'Shock';
    principle_names[11] := 'Unaspected';
    principle_names[12] := 'Concealing';  // illusion
    principle_names[13] := 'Overwhelming';
    principle_names[14] := 'Projection';
    principle_names[15] := 'Arcane';
    principle_names[16] := 'Righteous';   // restoration
    principle_names[17] := 'Defensive';
    principle_names[18] := 'Curing';
    principle_names[19] := 'Consuming';

    files_to_skip := TStringList.Create;
	
    AddMessage('Initialization complete. Starting spell categorization, this will take a while...');
end;

// helper function: when adding records to principle FLST, add spell followed by scroll, tome, and staff in any order
// checking master file for each record should avoid issues if records are overridden by another file
procedure add_to_principle_list(idx : integer; matching_spell, matching_book, matching_scroll, matching_staff : IInterface; matching_scroll_found, matching_staff_found : boolean);
begin
    add_to_flist(principle_flist_array[idx], matching_spell);
    add_to_flist(principle_flist_array[idx], matching_book);
    if matching_scroll_found then begin
        add_to_flist(principle_flist_array[idx], matching_scroll);
    end;
    if matching_staff_found then begin
        add_to_flist(principle_flist_array[idx], matching_staff);
    end;
end;

function safe_to_add() : boolean;
begin
    Result := False;
    if exclude_as_reward = 2 then begin
        Result := True;
    end else if (principle_0 or principle_1 or principle_2 or principle_3) and (school >= 0) and (school < 5) and (delivery >= 0) and (delivery < 3) and (method >= 0) and (method < 2) and (level >= 0) and (level < 5) then begin
        Result := True;
    end;
end;

function init_override(base_spell, winning_spell : IInterface): string;
var
    main_record : IInterface;
    curr_record : IInterface;
    spell_name : string;
    file_name : string;
    file_label : string;
    i : integer;
    j : integer;
begin
    Result := '';
    spell_override_count := 0;
    spell_name := GetElementEditValues(winning_spell, 'FULL');
    main_record := ContainingMainRecord(base_spell);
    for i := -1 to (OverrideCount(main_record)-1) do begin
        if i < 0 then begin
            curr_record := main_record;
        end else begin
            curr_record := OverrideByIndex(main_record, i);
        end;
        file_name := GetFileName(GetFile(curr_record));
        if (files_to_skip.IndexOf(file_name) >= 0) then begin
            file_label := ' (skipped)';
        end else begin
            spell_override_array[spell_override_count] := curr_record;
            spell_override_count := spell_override_count + 1;
        
            file_label := '';
            for j := 0 to (override_file_count - 1) do begin
                if file_name = override_file_indices[j].filename then begin
                    file_label := ' (has properties in override)';
                    break;
                end;
            end;
        end;
        Result := Result + ' - ' + file_name + file_label + #10;
    end;
    spell_override_idx := spell_override_count - 1;
end;

function update_override(curr_spell : IInterface) : boolean;
var
    spell_name : string;
begin
    spell_name := GetElementEditValues(curr_spell, 'FULL');
    Result := fill_override_line(GetFileName(GetFile(curr_spell)), spell_name);
end;



// for each record
function Process(e: IInterface): integer;
var 
    i : integer;
    j : integer;
    mgef_count : integer;
    mgef_ref_count : integer;
    ench_ref_count : integer;
    keyword_count : integer;
    mgef_keywords : IInterface;
    int_recv : integer;
    str_recv : string;
    form_recv : IInterface;
    weap_recv : IInterface;
    spell_name : string;
    spell_edid : string;
    tome_name : string;
    matching_book : IInterface;
    matching_spell : IInterface;
    half_cost_perk : IInterface;
    matching_scroll : IInterface;
    matching_staff : IInterface;
    matching_scroll_found : boolean;
    matching_staff_found : boolean;
    override_found : boolean;
    override_has_dependency : boolean;
    sure_about_result : boolean;
    confirm_result : integer;
    matching_items_str : string;
    description_str : string;
    override_list_str : string;
    warning_message : string;
begin
    Result := 0;
    // run this function for spell tomes specifically
    // (there are many spells that are not meant to be used directly; doing it this way avoids learning those)
    if (Signature(e) <> 'BOOK') then
      Exit;
    matching_book := WinningOverride(e);
    if GetElementEditValues(matching_book, 'DATA\Flags\Teaches Spell') <> '1' then
        Exit;
    
    // just to be safe: generally this should not need to run, but in case someone has wonky xEdit settings
    if ContainerStates(GetFile(e)) and (1 shl csRefsBuild) = 0 then begin
        AddMessage('Building reference info for ' + GetFileName(GetFile(e)) + '...');
        BuildRef(GetFile(e));
    end;
    // Process will be run for base record as well as overrides; only continue when using base record
    if not IsMaster(e) then begin
        Exit;
    end;

    matching_scroll_found := False;
    matching_staff_found := False;
    override_found := False;
    sure_about_result := True;

    tome_name := GetElementEditValues(matching_book, 'FULL');
    
    school := -1;
    level := -1;
    method := -1;
    delivery := -1;
    principle_0 := False;
    principle_1 := False;
    principle_2 := False;
    principle_3 := False;
    dependent_filename := '';
    exclusive_filename := '';
    exclusive_tome_name := '';

        
    
    matching_spell := LinksTo(ElementByPath(matching_book, 'DATA\Teaches'));
    AddMessage('Processing spell: ' + Name(matching_spell));
    override_list_str := init_override(matching_spell, WinningOverride(matching_spell));
    
    while (spell_override_idx >= 0) do begin
        matching_scroll_found := False;
        matching_staff_found := False;
        override_found := False;
        sure_about_result := True;

        tome_name := GetElementEditValues(matching_book, 'FULL');
    
        school := -1;
        level := -1;
        method := -1;
        delivery := -1;
        principle_0 := False;
        principle_1 := False;
        principle_2 := False;
        principle_3 := False;
        dependent_filename := '';
        exclusive_filename := '';
        exclusive_tome_name := '';

        //override_found := fill_override_line(GetFileName(GetFile(matching_spell)), spell_name);
        matching_spell := spell_override_array[spell_override_idx];
        override_found := update_override(matching_spell);
        spell_name := GetElementEditValues(matching_spell, 'FULL');
        spell_edid := GetElementEditValues(matching_spell, 'EDID');
        if (curr_override_line.exclusive_tome_name <> '') and (curr_override_line.exclusive_tome_name = tome_name) then begin
            AddMessage('Skipping; excluded tome name: ' + tome_name);
            Exit;
        end;
        
        // retrieve MGEF corresponding to this spell
        mgef_count := get_mgef_list(matching_spell, 0, False);
        if mgef_count > 0 then begin
            // concatenate descriptions for all magic effects
            description_str := '';
            for i := 0 to (mgef_count - 1) do begin
                description_str := description_str + GetElementEditValues(mgef_array[i], 'DNAM');
            end;
            // search for scrolls and staves that use the first MGEF in this spell
            mgef_ref_count := ReferencedByCount(MasterOrSelf(mgef_array[0]));
            for j := 0 to (mgef_ref_count - 1) do begin
                form_recv := ReferencedByIndex(MasterOrSelf(mgef_array[0]), j);
                if Signature(form_recv) = 'SCRL' then begin
                    if (not matching_scroll_found) then begin
                        matching_scroll := WinningOverride(form_recv);
                        matching_scroll_found := True;
                    end else if (Pos(spell_name, GetElementEditValues(matching_scroll, 'FULL')) = 0) and (Pos(spell_name, GetElementEditValues(form_recv, 'FULL')) <> 0) then begin
                        matching_scroll := WinningOverride(form_recv);
                    end;
                end else if (Signature(form_recv) = 'ENCH') and (GetElementEditValues(form_recv, 'ENIT\Enchant Type') = 'Staff Enchantment') then begin
                    ench_ref_count := ReferencedByCount(form_recv);
                    for i := 0 to (ench_ref_count - 1) do begin
                        weap_recv := ReferencedByIndex(form_recv, i);
                        if (not matching_staff_found) then begin
                            matching_staff := WinningOverride(weap_recv);
                            matching_staff_found := True;
                        end else if (Pos(spell_name, GetElementEditValues(matching_staff, 'FULL')) = 0) and (Pos(spell_name, GetElementEditValues(weap_recv, 'FULL')) <> 0) then begin
                            matching_staff := WinningOverride(weap_recv);
                        end;
                    end;
                end;
            end;
        end else begin
            AddMessage('WARNING: spell with no effects, skipping: "' + spell_name + '", ID: ' + spell_edid);
            Exit;
        end;

        
    
        
        // if there is an override line and it specifies a school
        if override_found and (curr_override_line.school_val <> -1) then begin
            // if both a principle and level are also specified, fill those in
            if curr_override_line.have_principle_val and curr_override_line.level_val <> -1 then begin
                // principles will get done later
                school := curr_override_line.school_val;
                level := curr_override_line.level_val;
                inferred_school := -1; // setting these ensures correct values will be written if an override is changed
                inferred_level := -1; // (so if method is changed in a popup, school and level will still be written)
            end else begin
                AddMessage('WARNING: to override the school of a spell you must also specify the level and at least one principle, as the script cannot auto-detect them!  Skipping.');
                Exit;
            end;
        end;
        
        // if school is unspecified, infer
        if school = -1 then begin
            int_recv := get_school_and_level(matching_spell);
            if int_recv = -1 then begin
                school := -1;
                level := -1;
            end else begin
                school := int_recv div 5;
                level := int_recv - (school*5);
            end;
            inferred_school := school;
            inferred_level := level;
            // check for override level here, in case level is specified but school is not
            if override_found and (curr_override_line.level_val <> -1) then begin
                level := curr_override_line.level_val;
                inferred_level := -1;
            end;
        end;
        
        // method override or infer
        if override_found and (curr_override_line.method_val <> -1) then begin
            method := curr_override_line.method_val;
            inferred_method := -1;
        end else begin
            str_recv := GetElementEditValues(matching_spell, 'SPIT\Cast Type');
            if str_recv = 'Concentration' then begin
                method := 0;
            end else if str_recv = 'Fire and Forget' then begin
                method := 1;
            end else begin
                AddMessage('WARNING: spell "' + spell_name + '" is neither concentration nor fire & forget, skipping');
                Exit;
            end;
            inferred_method := method;
        end;
        
        // delivery override or infer
        if override_found and (curr_override_line.delivery_val <> -1) then begin
            delivery := curr_override_line.delivery_val;
            inferred_delivery := -1; // force into overwrite
        end else begin
            str_recv := GetElementEditValues(matching_spell, 'SPIT\Target Type');
            if (str_recv = 'Aimed') or (str_recv = 'Target Actor') then begin
                delivery := 0;
            end else if str_recv = 'Target Location' then begin
                delivery := 1;
            end else if str_recv = 'Self' then begin
                delivery := 2;
            end else begin
                AddMessage('WARNING: spell "' + spell_name + '" does not have an expected delivery, skipping');
                Exit;
            end;
            inferred_delivery := delivery;
        end;

        
        
        // principles override or infer
        if override_found and curr_override_line.have_principle_val then begin
            principle_0 := curr_override_line.principle_0_val;
            principle_1 := curr_override_line.principle_1_val;
            principle_2 := curr_override_line.principle_2_val;
            principle_3 := curr_override_line.principle_3_val;
            inferred_principle_0 := (not principle_0); // force overwrite to write these
        end else begin
            mgef_count := get_mgef_list(matching_spell, 0, True);
            sure_about_result := fill_principles(school, mgef_count);
            inferred_principle_0 := principle_0;
            inferred_principle_1 := principle_1;
            inferred_principle_2 := principle_2;
            inferred_principle_3 := principle_3;
        end;

        
        
        // manage confirm popup behavior in various situations
        str_recv := GetElementEditValues(matching_spell, 'SPIT\Type');
        if str_recv <> 'Spell' then
            sure_about_result := False;
        
        if confirm_level < 2 and override_found then begin
            sure_about_result := True;
        end;
        if (confirm_level = 2) or ((confirm_level = 1) and (not override_found)) then
            sure_about_result := False;
        

        if override_found and (curr_override_line.exclude_val <> -1) then begin
            exclude_as_reward := curr_override_line.exclude_val;
            if exclude_as_reward = 2 then begin
                sure_about_result := True;
            end else begin
                // check for a required file if the override line has one
                // only include if the dependency is present
                if curr_override_line.dependent_filename <> '' then begin
                    dependent_filename := curr_override_line.dependent_filename;
                    override_has_dependency := False;
                    for i := 0 to (FileCount - 1) do begin
                        if GetFileName(FileByLoadOrder(i)) = dependent_filename then begin
                            override_has_dependency := True;
                            break;
                        end;
                    end;
                    if not override_has_dependency then begin
                        exclude_as_reward := 2;
                    end;
                end;
                // check for a mutually exclusive file if the override line has one
                // do not include if it is present
                if curr_override_line.exclusive_filename <> '' then begin
                    exclusive_filename := curr_override_line.exclusive_filename;
                    for i := 0 to (FileCount - 1) do begin
                        if GetFileName(FileByLoadOrder(i)) = exclusive_filename then begin
                            exclude_as_reward := 2;
                            break;
                        end;
                    end;
                end;
            end;
        end else begin
            exclude_as_reward := 0; // default is to include in patch
        end;
        
        if (not sure_about_result) or (not safe_to_add()) then begin
            warning_message := '';
            matching_items_str := 'Found associated items:' + #10;
            if str_recv <> 'Spell' then // warning message for Lesser Power etc
                matching_items_str := matching_items_str + 'WARNING: spell tome points to type "' + str_recv + '" instead of a spell' + #10;
            // list tome, scroll, and staff associated
            matching_items_str := matching_items_str + ' - ' + sub_str(Name(matching_book), Pos('"', Name(matching_book)), 1000);
            if matching_scroll_found then begin
                matching_items_str := matching_items_str + #10 + ' - ' + sub_str(Name(matching_scroll), Pos('"', Name(matching_scroll)), 1000);
            end else begin
                matching_items_str := matching_items_str + #10 + ' - no matching scroll';
            end;
            if matching_staff_found then begin
                matching_items_str := matching_items_str + #10 + ' - ' + sub_str(Name(matching_staff), Pos('"', Name(matching_staff)), 1000);
            end else begin
                matching_items_str := matching_items_str + #10 + ' - no matching staff';
            end;
        end;
        // while any property is uncertain, or if at least one confirmation is desired, pop up dialog
        while (not sure_about_result) or (not safe_to_add()) do begin
            // show message
            confirm_result := show_confirm(warning_message, 'Confirm details for ' + spell_name + ' (' + GetFileName(GetFile(e)) + '):', description_str, override_list_str, GetFileName(GetFile(matching_spell)), matching_items_str, get_distribution_str(e, 10));
            if confirm_result = 0 then begin
                AddMessage('Canceled; stopping script');
                Result := 1;
                check_finalize();
                Exit;
            end else if confirm_result = 1 then begin
                // after user has closed dialog (and if they did not hit cancel)
                if safe_to_add() then begin
                    write_override_line(GetFileName(GetFile(matching_spell)), spell_name);
                    sure_about_result := True;
                    spell_override_idx := -1;
                    break;
                end;
                warning_message := 'WARNING: please ensure you have selected at least one principle and a school, delivery, method, and level.';
            end else if confirm_result = 2 then begin
                break;
            end;
        end;
        if sure_about_result then
            break;
    end;
    
    // if not skipped, add to various FLST
    if not (exclude_as_reward = 2) then begin
        if (not safe_to_add()) then begin
            AddMessage('WARNING: somehow exited confirm early; this will cause an error.  Please report this log to the script author.');
        end;
    
        AddMessage('Adding with: ' + inttostr(school) + ', ' + inttostr(delivery) + ', ' + inttostr(method) + ', ' + inttostr(level));
        if principle_0 then begin
            add_to_principle_list((school*4), matching_spell, matching_book, matching_scroll, matching_staff, matching_scroll_found, matching_staff_found);
        end;
        if principle_1 then begin
            add_to_principle_list((school*4 + 1), matching_spell, matching_book, matching_scroll, matching_staff, matching_scroll_found, matching_staff_found);
        end;
        if principle_2 then begin
            add_to_principle_list((school*4 + 2), matching_spell, matching_book, matching_scroll, matching_staff, matching_scroll_found, matching_staff_found);
        end;
        if principle_3 then begin
            add_to_principle_list((school*4 + 3), matching_spell, matching_book, matching_scroll, matching_staff, matching_scroll_found, matching_staff_found);
        end;
        
        add_to_flist(delivery_flist_array[delivery], matching_spell);
        add_to_flist(method_flist_array[method], matching_spell);
        add_to_flist(level_flist_array[level], matching_spell);
        if (exclude_as_reward = 1) then begin
            add_to_flist(rewards_exclude_flist, matching_spell);
        end;
        
    end;
end;

function check_finalize : boolean;
begin
    if show_finalize_options() then begin // overwrite with new confirm popup choices?
        Result := True; // cancel
    end else begin
        Result := False;
        write_overrides;
    end;
end;

function add_item_to_array(item_type : string; item : integer) : boolean;
var
    i : integer;
begin
    Result := False;
    
    // array-to-array assignment not supported, as far as I can tell
    if item_type = 'SPEL' then begin
        for i := 0 to (spell_list.count - 1) do begin
            if spell_list.arr[i] = item then begin
                Result := True;
                Exit;
            end;
        end;
        spell_list.arr[spell_list.count] := item;
        spell_list.count := spell_list.count + 1;
    end else if item_type = 'BOOK' then begin
        for i := 0 to (tome_list.count - 1) do begin
            if tome_list.arr[i] = item then begin
                Result := True;
                Exit;
            end;
        end;
        tome_list.arr[tome_list.count] := item;
        tome_list.count := tome_list.count + 1;
    end else if item_type = 'SCRL' then begin
        for i := 0 to (scrl_list.count - 1) do begin
            if scrl_list.arr[i] = item then begin
                Result := True;
                Exit;
            end;
        end;
        scrl_list.arr[scrl_list.count] := item;
        scrl_list.count := scrl_list.count + 1;
    end else if item_type = 'WEAP' then begin
        for i := 0 to (weap_list.count - 1) do begin
            if weap_list.arr[i] = item then begin
                Result := True;
                Exit;
            end;
        end;
        weap_list.arr[weap_list.count] := item;
        weap_list.count := weap_list.count + 1;
    end;
end;

function item_in_flist(flist : IInterface; item : integer) : boolean;
var
    i : integer;
    form_ids : IInterface;
begin
    Result := False;
    form_ids := ElementByPath(flist, 'FormIDs');
    if not Assigned(form_ids) then begin
        Exit;
    end else begin
        for i := 0 to ElementCount(form_ids) do begin
            if FormID(ContainingMainRecord(LinksTo(ElementByIndex(form_ids, i)))) = item then begin
                Result := True;
                Exit;
            end;
        end;
    end;
end;

function check_patch_integrity : boolean;
var
    p, d, m, l : integer;
    i : integer;
    max_count : integer;
    current_ids : IInterface;
    current_form : IInterface;
    current_formid : integer;
    current_spell : IInterface;
    duplicate_message, missing_message, overflow_message : string;
begin
    Result := True;
    AddMessage('Library integrity check ==========================================');
    
    duplicate_message := '; please try re-generating library from scratch.  You should not need to re-select properties for any spell, as long as you have been choosing to overwrite the config.  If left as-is, this will not cause initialization to fail but you may see strange behavior.';
    missing_message := '; please try re-generating library from scratch.  You should not need to re-select properties for any spell, as long as you have been choosing to overwrite the config.  If left as-is, library will fail to initialize in-game.';
    overflow_message := ', exceeding the hard maximum of 512; please resolve any duplicates before taking action on this message.  This library will fail to initialize in-game, as the maximum spells per principle supported is 512.  You may wish to entirely skip some spells that are currently excluded from discovery.';
    
    for p := 0 to 19 do begin
        spell_list.count := 0;
        tome_list.count := 0;
        scrl_list.count := 0;
        weap_list.count := 0;
        current_ids := ElementByPath(principle_flist_array[p], 'FormIDs');
        if Assigned(current_ids) then begin
            AddMessage('Principle list ' + inttostr(p) + '; checking...');
            max_count := ElementCount(current_ids);
            for i := 0 to (max_count - 1) do begin
                current_form := LinksTo(ElementByIndex(current_ids, i));
                current_formid := FixedFormID(ContainingMainRecord(current_form));
                if Signature(current_form) = 'SPEL' then begin
                    if add_item_to_array('SPEL', current_formid) then begin
                        AddMessage('    WARNING: Duplicate spell: ' + ShortName(current_form) + duplicate_message);
                    end;
                    if not (item_in_flist(delivery_flist_array[0], current_formid) or item_in_flist(delivery_flist_array[1], current_formid) or item_in_flist(delivery_flist_array[2], current_formid)) then begin
                        AddMessage('    ERROR: no delivery found for spell: ' + ShortName(current_form) + missing_message);
                        Result := False;
                        Exit;
                    end else if not (item_in_flist(method_flist_array[0], current_formid) or item_in_flist(method_flist_array[1], current_formid)) then begin
                        AddMessage('    ERROR: no method found for spell: ' + ShortName(current_form) + missing_message);
                        Result := False;
                        Exit;
                    end else if not (item_in_flist(level_flist_array[0], current_formid) or item_in_flist(level_flist_array[1], current_formid) or item_in_flist(level_flist_array[2], current_formid) or item_in_flist(level_flist_array[3], current_formid) or item_in_flist(level_flist_array[4], current_formid)) then begin
                        AddMessage('    ERROR: no level found for spell: ' + ShortName(current_form) + missing_message);
                        Result := False;
                        Exit;
                    end;
                end else if Signature(current_form) = 'BOOK' then begin
                    if add_item_to_array('BOOK', current_formid) then begin
                        AddMessage('    WARNING: Duplicate tome: ' + ShortName(current_form) + duplicate_message);
                    end;
                end else if Signature(current_form) = 'SCRL' then begin
                    if add_item_to_array('SCRL', current_formid) then begin
                        AddMessage('    WARNING: Duplicate scroll: ' + ShortName(current_form) + duplicate_message);
                    end;
                end else if Signature(current_form) = 'WEAP' then begin
                    if add_item_to_array('WEAP', current_formid) then begin
                        AddMessage('    WARNING: Duplicate staff: ' + ShortName(current_form) + duplicate_message);
                    end;
                end;
                if spell_list.count = 1024 then begin
                    AddMessage('    At least 1024 spells in principle list; terminating count early.');
                end;
            end;
            if spell_list.count > 512 then begin
                AddMessage('    ERROR: Spell count in this principle list is ' + inttostr(spell_list.count) + overflow_message);
                Result := False;
                Exit;
            end else begin
                AddMessage('    Spell count in this principle list is ' + inttostr(spell_list.count) + '; ok.');
            end;
        end else begin
            AddMessage('Principle list ' + inttostr(p) + ' empty; ok.');
        end;
        
    end;
end;

// called once at the end
function Finalize: integer;
begin
    //if not check_patch_integrity() then begin
    //    AddMessage('ERROR: Patch is nonfunctional with one or more issues; please resolve before using in-game!');
    //end;
    files_to_skip.Free;
    if check_finalize() then begin
        Result := 1;
    end else begin
        Result := 0;
    end;
end;

end.
