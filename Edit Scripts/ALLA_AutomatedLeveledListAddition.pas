{
  Script automatically detects where an item should go in the leveled lists.  It then integrates that item into the lists automatically.
  Additionally, there is an option to generate enchanted and tempered versions of the items.
}

unit AutomatedLeveledListAddition;

uses
    ALLA_CustomFunctionList;

// Global variables are set at the beginning so you are not prompted for each selected record
var
    selectedRecord, templateRecord: IInterface;
    slGlobal, slProcessTime       : TStringList;
    skipCount                     : Integer;
    CancelAll                     : Boolean;
    additionTemplatedSelectedIndex: Integer;

    defaultOutputPlugin                                                                                        : string;
    defaultGenerateEnchantedVersions, defaultReplaceInLeveledList, defaultAllowDisenchanting, ProcessTime      : Boolean;
    defaultBreakdownEnchanted, defaultBreakdownDaedric, defaultBreakdownDLC, defaultGenerateRecipes, Constant  : Boolean;
    defaultChanceBoolean, defaultAutoDetect, defaultBreakdown, defaultOutfitSet, defaultCrafting, defaultTemper: Boolean;
    defaultChanceMultiplier, defaultEnchMultiplier, defaultItemTier01, defaultItemTier02, defaultItemTier03    : Integer;
    defaultItemTier04, defaultItemTier05, defaultItemTier06, defaultTemperLight, defaultTemperHeavy            : Integer;

    /// /////////////////////////////////////////////////////////////////// SCRIPT-SPECIFIC FUNCTIONS //////////////////////////////////////////////////////////////////////////////////////
procedure ELLR_OnClick_SelectedItem(Sender: TObject);
var
    lblSelectedItemText, lblSelectedValue, lblSelectedGoldValueText: TLabel;
    ddSelectedItem, ddSelectedValue, ddSelectedGoldValue           : TComboBox;
    debugMsg, tempBoolean                                          : Boolean;
    tempRecord, templateRecord, captionRecord                      : IInterface;
    slTemp                                                         : TStringList;
    tempObject                                                     : TObject;
    tempString                                                     : string;
    frm                                                            : TForm;
    i                                                              : Integer;
begin
    // Begin debugMsg section
    debugMsg := False;

    // Initialize
    slTemp := TStringList.Create;

    // Set sender form components
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SelectedItem] Set sender form components');
    frm                 := Sender.Parent;
    tempRecord          := ObjectToElement(Sender.Items.Objects[Sender.ItemIndex]);
    lblSelectedItemText := ComponentByCaption('Selected Item: ', frm);
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SelectedItem] lblSelectedItemText.Caption := ' + lblSelectedItemText.Caption);
    ddSelectedItem := AssociatedComponent('Selected Item: ', frm);
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SelectedItem] ddSelectedItem.Caption := ' + ddSelectedItem.Caption);
    lblSelectedValue := ComponentByTop(Sender.Top + 1, frm);
    ddSelectedValue  := ComponentByTop(78, frm);

    // Confirm edit box changes
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SelectedItem] Confirm edit box changes');
    slTemp.Assign(ddSelectedItem.Items);
    tempString := ddSelectedItem.Items[IndexOfObjectbyFULL(full(selectedRecord), slTemp)];
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SelectedItem] tempString := ' + tempString);
    if (Length(full(selectedRecord)) > 0) then
        if (full(selectedRecord) <> full(selectedRecord)) or (ddSelectedValue.Text <> GetGameValue(selectedRecord)) then
            tempBoolean := True;
    if CaptionExists('Value: ', frm) then
    begin
        ddSelectedGoldValue := ComponentByTop(ComponentByCaption('Value: ', frm).Top + 38, frm);
        if not ContainsText(GetGameValueType(selectedRecord), 'Value') then
            if ((ddSelectedGoldValue.Text <> geev(selectedRecord, 'DATA\Value')) and (Length(ddSelectedGoldValue.Text) > 0)) then
                tempBoolean := True;
    end;
    if tempBoolean then
    begin
        if (MessageDlg('Do you wish to save changes to ' + full(selectedRecord) + ' [YES] or discard [NO]?', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
        begin
            if (tempString <> full(selectedRecord)) and (Length(tempString) > 0) then
            begin
                slGlobal[slGlobal.IndexOf(EditorID(selectedRecord))] := tempString;
                if slContains(slGlobal, EditorID(selectedRecord) + 'Template') then
                    slGlobal[slGlobal.IndexOf(EditorID(selectedRecord) + 'Template')] := tempString + 'Template';
                seev(selectedRecord, 'FULL', tempString);
                { Debug } if debugMsg then
                    addmessage('seev(selectedRecord, ''FULL'', full(selectedRecord) := ' + full(selectedRecord) + ' )');
            end;
            if (ddSelectedValue.Text <> GetGameValue(selectedRecord)) and (IntWithinStr(ddSelectedValue.Text) > 0) then
            begin
                { Debug } if debugMsg then
                    addmessage('seev( ' + EditorID(selectedRecord) + ', ' + GetGameValueType(selectedRecord) + ', ' + GetGameValue(selectedRecord) + ' )');
                senv(selectedRecord, GetGameValueType(selectedRecord), IntWithinStr(ddSelectedValue.Text));
            end;
            if CaptionExists('Value: ', frm) then
            begin
                if not ContainsText(GetGameValueType(selectedRecord), 'Value') then
                    if (ddSelectedGoldValue.Text <> geev(selectedRecord, 'DATA\Value')) and (Length(ddSelectedGoldValue.Text) > 0) then
                        senv(selectedRecord, 'DATA\Value', IntWithinStr(ddSelectedGoldValue.Text));
            end;
        end;
    end;

    // Change template record
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SelectedItem] Change template record');
    if CaptionExists('Item: ', frm) then
    begin
        tempObject := AssociatedComponent('Item: ', frm);
        if (tempObject.Text <> '') then
        begin
            tempRecord := ObjectToElement(tempObject.Items.Objects[tempObject.ItemIndex]);
            if (MessageDlg('Do you wish to change the template of ' + full(selectedRecord) + ' to ' + full(tempRecord) + '?', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
                SetObject(EditorID(selectedRecord) + 'Template', tempRecord, slGlobal);
        end;
    end;

    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SelectedItem] ContainsText(GetGameValueType(tempRecord) := ' + GetGameValueType(tempRecord) + ', Value)');
    if not ContainsText(GetGameValueType(tempRecord), 'Value') and not CaptionExists('Value: ', frm) then
    begin
        // Gold Value Label
        lblSelectedGoldValueText         := TLabel.Create(frm);
        lblSelectedGoldValueText.Parent  := frm;
        lblSelectedGoldValueText.Height  := 24;
        lblSelectedGoldValueText.Left    := 660;
        lblSelectedGoldValueText.Top     := lblSelectedItemText + 40;
        lblSelectedGoldValueText.Caption := 'Value: ';
        // Gold Value Combo Box
        ddSelectedGoldValue        := TComboBox.Create(frm);
        ddSelectedGoldValue.Parent := frm;
        ddSelectedGoldValue.Height := 24;
        ddSelectedGoldValue.Left   := lblSelectedValue.Left;
        ddSelectedGoldValue.Top    := lblSelectedGoldValueText.Top + 40;
        ddSelectedGoldValue.Width  := 120;
        ddSelectedGoldValue.Items.Add(geev(tempRecord, 'DATA\Value'));
        ddSelectedGoldValue.ItemIndex := 0;
    end
    else
        if not ContainsText(GetGameValueType(tempRecord), 'Value') and CaptionExists('Value: ', frm) then
        begin
            ddSelectedGoldValue := ComponentByTop(ComponentByCaption('Value: ', frm).Top + 38, frm);
            ddSelectedGoldValue.Items.Clear;
            ddSelectedGoldValue.Items.Add(geev(tempRecord, 'DATA\Value'));
            ddSelectedGoldValue.ItemIndex := 0;
        end
        else
            if CaptionExists('Value: ', frm) then
            begin
                lblSelectedGoldValueText := ComponentByCaption('Value: ', frm);
                ddSelectedGoldValue      := ComponentByTop(lblSelectedGoldValueText.Top + 38, frm);
                lblSelectedGoldValueText.Free;
                ddSelectedGoldValue.Free;
            end;

    // Selected Value Label
    if ContainsText(GetGameValueType(tempRecord), 'DNAM') then
    begin
        lblSelectedValue.Caption := 'Armor: ';
    end else begin
        lblSelectedValue.Caption := StrPosCopy(GetGameValueType(tempRecord), '\', False) + ': ';
    end;

    // Selected Value Combo Box
    ddSelectedValue.Items.Clear;
    ddSelectedValue.Items.Add(GetGameValue(tempRecord));
    ddSelectedValue.ItemIndex := 0;
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SelectedItem] ddSelectedValue := ' + ddSelectedValue.Text);

    // Suggested Template
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SelectedItem] Suggested Template');

    if CaptionExists('Current: ', frm) then
    begin
        if slContains(slGlobal, EditorID(tempRecord) + 'Template') then
        begin
            templateRecord                                                            := ObjectToElement(GetObject(EditorID(tempRecord) + 'Template', slGlobal));
            ComponentByTop(ComponentByCaption('Current: ', frm).Top + 1, frm).Caption := full(templateRecord) + ' (' + StrPosCopy(GetGameValueType(templateRecord), '\', False) + ': ' + GetGameValue(templateRecord) + ')';
        end else begin
            captionRecord                                                             := ObjectToElement(GetTemplate(WinningOverride(ObjectToElement((tempRecord)))));
            ComponentByTop(ComponentByCaption('Current: ', frm).Top + 1, frm).Caption := full(captionRecord) + ' (' + StrPosCopy(GetGameValueType(captionRecord), '\', False) + ': ' + GetGameValue(captionRecord) + ')';
        end
    end;

    // Finalize
    selectedRecord := ObjectToElement(Sender.Items.Objects[Sender.ItemIndex]);
    slTemp.Free;

    debugMsg := False;
    // End debugMsg section
end;

procedure ELLR_OnClick_Patch_ddFileA(Sender: TObject);
var
    i  : Integer;
    frm: TForm;
begin
    frm := Sender.Parent;
    if (Sender.Text = 'Items') then
    begin
        ComponentByTop(Sender.Top + 1, frm).Caption := 'to Leveled Lists from: ';
        ComponentByTop(Sender.Top - 1, frm).Left    := ComponentByTop(Sender.Top - 1, frm).Left + 75;
    end
    else
        if (Sender.Text = 'Enchantments') then
        begin
            ComponentByTop(Sender.Top + 1, frm).Caption := 'to Items from: ';
            ComponentByTop(Sender.Top - 1, frm).Left    := ComponentByTop(Sender.Top - 1, frm).Left - 75;
        end;
end;

procedure ELLR_Btn_SelectedItem(Sender: TObject);
var
    lblSelectedValue, lblSelectedGoldValueText, lblSelectedItemText, lblSex: TLabel;
    ddSelectedItem, ddSelectedValue, ddSelectedGoldValue, ddSex            : TComboBox;
    templateRecord, tempRecord, tempElement, outputFile                    : IInterface;
    debugMsg, tempBoolean                                                  : Boolean;
    btnOk, btnCancel                                                       : TButton;
    tempObject                                                             : TObject;
    slTemp                                                                 : TStringList;
    tempString                                                             : string;
    ckSex                                                                  : TCheckBox;
    i                                                                      : Integer;
    frm                                                                    : TForm;
begin
    // Begin debugMsg Section
    debugMsg := False;

    // Initialize
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SelectedItem] Sender := ' + Sender.Text);
    { Debug } if debugMsg then
        msgList('[ELLR_Btn_SelectedItem] slGlobal := ', slGlobal, '');
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SelectedItem] outputFile := ' + GetFileName(outputFile));
    slTemp := TStringList.Create;

    frm := TForm.Create(nil);
    try
        // Parent Form; Entire Box
        frm.Width    := 800;
        frm.Height   := 300;
        frm.Position := poScreenCenter;
        frm.Caption  := 'Selected Records Settings';

        // Selected Item Label
        lblSelectedItemText         := TLabel.Create(frm);
        lblSelectedItemText.Parent  := frm;
        lblSelectedItemText.Left    := 24;
        lblSelectedItemText.Top     := 40;
        lblSelectedItemText.Caption := 'Selected Item: ';

        // Selected Item Combo Box
        ddSelectedItem        := TComboBox.Create(frm);
        ddSelectedItem.Parent := frm;
        ddSelectedItem.Left   := 10 * Length(lblSelectedItemText.Caption) + 20;
        ddSelectedItem.Top    := lblSelectedItemText.Top - 2;
        ddSelectedItem.Width  := 480;
        for i                 := 0 to slGlobal.Count - 1 do
            if ContainsText(slGlobal[i], 'Original') then
                ddSelectedItem.Items.AddObject(full(ObjectToElement(slGlobal.Objects[i])), slGlobal.Objects[i]);
        ddSelectedItem.ItemIndex := 0;
        tempRecord               := ObjectToElement(ddSelectedItem.Items.Objects[ddSelectedItem.ItemIndex]);
        { Debug } if debugMsg then
            addmessage('[ELLR_Btn_SelectedItem] tempRecord := ' + EditorID(tempRecord));
        ddSelectedItem.OnClick := ELLR_OnClick_SelectedItem;

        // Selected Value Label
        lblSelectedValue        := TLabel.Create(frm);
        lblSelectedValue.Parent := frm;
        lblSelectedValue.Left   := 660;
        lblSelectedValue.Top    := lblSelectedItemText.Top - 1;
        if ContainsText(GetGameValueType(tempRecord), 'DNAM') then
        begin
            lblSelectedValue.Caption := 'Armor: ';
        end
        else
            lblSelectedValue.Caption := StrPosCopy(GetGameValueType(tempRecord), '\', False) + ': ';

        // Selected Value Combo Box
        ddSelectedValue        := TComboBox.Create(frm);
        ddSelectedValue.Parent := frm;
        ddSelectedValue.Left   := lblSelectedValue.Left;
        ddSelectedValue.Top    := lblSelectedItemText.Top + 38;
        ddSelectedValue.Width  := 120;
        ddSelectedValue.Items.Add(GetGameValue(tempRecord));
        ddSelectedValue.ItemIndex := 0;
        { Debug } if debugMsg then
            addmessage('[ELLR_Btn_SelectedItem] ddSelectedValue := ' + ddSelectedValue.Text);

        // Sex Check Box
        ckSex        := TCheckBox.Create(frm);
        ckSex.Parent := frm;
        ckSex.Left   := 625;
        ckSex.Top    := lblSelectedItemText.Top + 46;
        ckSex.Width  := 24;

        // Sex Combo Box
        ddSex        := TComboBox.Create(frm);
        ddSex.Parent := frm;
        ddSex.Left   := ddSelectedItem.Left;
        ddSex.Top    := lblSelectedItemText.Top + 39;
        ddSex.Width  := 120;
        ddSex.Items.Add('Male');
        ddSex.Items.Add('Female');
        ddSex.ItemIndex := 0;
        { Debug } if debugMsg then
            addmessage('[ELLR_Btn_SelectedItem] ddSex := ' + ddSex.Text);

        // Sex Label
        lblSex         := TLabel.Create(frm);
        lblSex.Parent  := frm;
        lblSex.Left    := ddSex.Left + ddSex.Width + 10;
        lblSex.Top     := lblSelectedItemText.Top + 40;
        lblSex.Caption := 'Only Armor';

        { Debug } if debugMsg then
            addmessage('[ELLR_Btn_SelectedItem] ContainsText(GetGameValueType(tempRecord) := ' + GetGameValueType(tempRecord) + ', Value)');
        if not ContainsText(GetGameValueType(tempRecord), 'Value') then
        begin
            lblSelectedGoldValueText         := TLabel.Create(frm);
            lblSelectedGoldValueText.Parent  := frm;
            lblSelectedGoldValueText.Left    := 660;
            lblSelectedGoldValueText.Top     := 118;
            lblSelectedGoldValueText.Caption := 'Value: ';

            ddSelectedGoldValue        := TComboBox.Create(frm);
            ddSelectedGoldValue.Parent := frm;
            ddSelectedGoldValue.Left   := lblSelectedValue.Left;
            ddSelectedGoldValue.Top    := lblSelectedGoldValueText.Top + 38;
            ddSelectedGoldValue.Width  := ddSelectedValue.Width;
            ddSelectedGoldValue.Items.Add(geev(tempRecord, 'DATA\Value'));
            ddSelectedGoldValue.ItemIndex := 0;
        end;

        // Ok Button
        btnOk             := TButton.Create(frm);
        btnOk.Parent      := frm;
        btnOk.Caption     := 'Ok';
        btnOk.Left        := (frm.Width div 2) - btnOk.Width - 8;
        btnOk.Top         := frm.Height - 80;
        btnOk.ModalResult := mrOk;

        // Cancel Button
        btnCancel             := TButton.Create(frm);
        btnCancel.Parent      := frm;
        btnCancel.Caption     := 'Cancel';
        btnCancel.Left        := btnOk.Left + btnOk.Width + 16;
        btnCancel.Top         := btnOk.Top;
        btnCancel.ModalResult := mrCancel;

        // What happens when Ok is pressed
        selectedRecord := tempRecord;
        frm.ShowModal;
        tempRecord  := ObjectToElement(ddSelectedItem.Items.Objects[ddSelectedItem.ItemIndex]);
        tempBoolean := False;
        if (frm.ModalResult = mrOk) then
        begin
            Sender.Caption := ddSelectedItem.Items[ddSelectedItem.ItemIndex];
        end
        else
            if (frm.ModalResult = mrRetry) then
            begin
            end;
        if ckSex.Checked then
            tempBoolean := True;
        if (Length(full(tempRecord)) > 0) then
            if (full(tempRecord) <> full(tempRecord)) or (ddSelectedValue.Text <> GetGameValue(tempRecord)) then
                tempBoolean := True;
        if not ContainsText(GetGameValueType(tempRecord), 'Value') then
            if Assigned(ddSelectedGoldValue.Text) then
                if ((ddSelectedGoldValue.Text <> geev(tempRecord, 'DATA\Value')) and (Length(ddSelectedGoldValue.Text) > 0)) then
                    tempBoolean := True;
        if tempBoolean then
        begin
            if MessageDlg('Do you wish to save changes to ' + full(tempRecord) + ' [YES] or discard [NO]?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
            begin
                if ckSex.Checked then
                begin
                    if not slContains(slGlobal, 'ALLAfile') then
                    begin
                        tempString := AssociatedComponent('Output Plugin: ', Sender.Parent).Caption;
                        if not DoesFileExist(tempString) then
                        begin
                            if MessageDlg('Create a new plugin named ' + tempString + ' [YES] or cancel [NO]?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
                            begin
                                { Debug } if debugMsg then
                                    addmessage('tempString := AddNewFileName( ' + tempString + ' );');
                                SetObject('ALLAfile', AddNewFileName(tempString), slGlobal);
                            end;
                        end
                        else
                            outputFile := FileByName(tempString);
                    end
                    else
                        outputFile := ObjectToElement(GetObject('ALLAfile', slGlobal));
                    GenderOnlyArmor(ddSex.Text, tempRecord, outputFile);
                end;
                if (ddSelectedItem.Text <> full(tempRecord)) and (Length(full(tempRecord)) > 0) then
                begin
                    slGlobal[slGlobal.IndexOf(EditorID(tempRecord))] := ddSelectedItem.Text;
                    { Debug } if debugMsg then
                        addmessage('[ELLR_Btn_SelectedItem] tempRecord := ' + EditorID(ObjectToElement(GetObject(EditorID(tempRecord) + 'Template', slGlobal))));
                    slGlobal[slGlobal.IndexOf(EditorID(tempRecord) + 'Template')] := ddSelectedItem.Text + 'Template';
                    seev(tempRecord, 'FULL', ddSelectedItem.Text);
                    { Debug } if debugMsg then
                        addmessage('seev(tempRecord, ''FULL'', full(tempRecord) := ' + full(tempRecord) + ' )');
                end;
                if (ddSelectedValue.Text <> GetGameValue(tempRecord)) and (IntWithinStr(ddSelectedValue.Text) > 0) then
                begin
                    { Debug } if debugMsg then
                        addmessage('seev( ' + EditorID(tempRecord) + ', ' + GetGameValueType(tempRecord) + ', ' + GetGameValue(tempRecord) + ' )');
                    senv(tempRecord, GetGameValueType(tempRecord), IntWithinStr(ddSelectedValue.Text));
                end;
                if CaptionExists('Value: ', frm) then
                begin
                    if not ContainsText(GetGameValueType(tempRecord), 'Value') then
                        if (ddSelectedGoldValue.Text <> GetElementEditValues(tempRecord, 'DATA\Value')) and (Length(ddSelectedGoldValue.Text) > 0) then
                            senv(tempRecord, 'DATA\Value', IntWithinStr(ddSelectedGoldValue.Text));
                end;
            end;
        end;
    finally
        frm.Free;
    end;

    { Debug } debugMsg := False;
    // End debugMsg Section
end;

procedure ELLR_Btn_Plugin(Sender: TObject);
var
    tempComponent, ddALLAplugin, ddGEVfile, ddRecipefile: TComboBox;
    lblALLAplugin, lblGEVfile, lblRecipefile            : TLabel;
    btnOk, btnCancel                                    : TButton;
    ALLAfile, TF                                            : IInterface;
    debugMsg, exist                                            : Boolean;
    i                                                   : Integer;
    frm                                                 : TForm;
begin
    // Begin debugMsg Section
    debugMsg := False;

    // Initialize
    tempComponent := AssociatedComponent('Output Plugin: ', Sender.Parent);

    frm := TForm.Create(nil);
    try
        // Parent Form; Entire Box
        frm.Width    := 600;
        frm.Height   := 150;
        frm.Position := poScreenCenter;
        frm.Caption  := 'Output Plugin Settings';

        // ELLR Plugin Label
        lblALLAplugin         := TLabel.Create(frm);
        lblALLAplugin.Parent  := frm;
        lblALLAplugin.Top     := 30;
        lblALLAplugin.Left    := 30;
        lblALLAplugin.Caption := 'One-Click Leveled List Addition Plugin: ';
        frm.Height            := frm.Height + 80;

        // ELLR Plugin Edit Box
        ddALLAplugin        := TComboBox.Create(frm);
        ddALLAplugin.Parent := frm;
        ddALLAplugin.Top    := lblALLAplugin.Top + 40;
        ddALLAplugin.Left   := lblALLAplugin.Left;
        ddALLAplugin.Width  := 500;
        ddALLAplugin.Items.Add(tempComponent.Caption);
        ddALLAplugin.ItemIndex := 0;

        // GEV Plugin Label
        lblGEVfile         := TLabel.Create(frm);
        lblGEVfile.Parent  := frm;
        lblGEVfile.Top     := ddALLAplugin.Top + 40;
        lblGEVfile.Left    := lblALLAplugin.Left;
        lblGEVfile.Caption := 'Generate Enchanted Versions Plugin: ';
        frm.Height         := frm.Height + 80;

        // GEV Plugin Edit Box
        ddGEVfile        := TComboBox.Create(frm);
        ddGEVfile.Parent := frm;
        ddGEVfile.Top    := lblGEVfile.Top + 40;
        ddGEVfile.Left   := lblGEVfile.Left;
        ddGEVfile.Width  := 500;
        if slContains(slGlobal, 'GEVfile') then
        begin
            ddGEVfile.Items.Add(GetFileName(ObjectToElement(GetObject('GEVfile', slGlobal))));
        end
        else
            ddGEVfile.Items.Add(tempComponent.Caption);
        ddGEVfile.ItemIndex := 0;

        // Recipe Plugin Label
        lblRecipefile         := TLabel.Create(frm);
        lblRecipefile.Parent  := frm;
        lblRecipefile.Height  := lblALLAplugin.Height;
        lblRecipefile.Top     := ddGEVfile.Top + 40;
        lblRecipefile.Left    := lblALLAplugin.Left;
        lblRecipefile.Caption := 'Generate Recipes Plugin: ';
        frm.Height            := frm.Height + 80;

        // Recipe Plugin Edit Box
        ddRecipefile        := TComboBox.Create(frm);
        ddRecipefile.Parent := frm;
        ddRecipefile.Height := lblALLAplugin.Height;
        ddRecipefile.Top    := lblRecipefile.Top + 40;
        ddRecipefile.Left   := lblRecipefile.Left;
        ddRecipefile.Width  := 500;
        if slContains(slGlobal, 'RecipeFile') then
        begin
            ddRecipefile.Items.Add(GetFileName(ObjectToElement(GetObject('RecipeFile', slGlobal))));
        end
        else
            ddRecipefile.Items.Add(tempComponent.Caption);
        ddRecipefile.ItemIndex := 0;

        // Ok Button
        btnOk             := TButton.Create(frm);
        btnOk.Parent      := frm;
        btnOk.Caption     := 'Ok';
        btnOk.Left        := (frm.Width div 2) - btnOk.Width - 8;
        btnOk.Top         := frm.Height - 80;
        btnOk.ModalResult := mrOk;

        // Cancel Button
        btnCancel             := TButton.Create(frm);
        btnCancel.Parent      := frm;
        btnCancel.Caption     := 'Cancel';
        btnCancel.Left        := btnOk.Left + btnOk.Width + 16;
        btnCancel.Top         := btnOk.Top;
        btnCancel.ModalResult := mrCancel;

        // What happens when Ok is pressed
        frm.ShowModal;
        if (frm.ModalResult = mrOk) then
        begin
            tempComponent.Caption := ddALLAplugin.Text;
            if DoesFileExist(ddALLAplugin.Text) then
            begin
                // addmessage('[File Prep] '+ddALLAplugin.Text+' detected; Preparing file');
                SetObject('ALLAfile', FileByName(ddALLAplugin.Text), slGlobal);
            end else begin
                if MessageDlg('Create a new plugin named ' + ddALLAplugin.Text + ' [YES] or cancel [NO]?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
                begin
                    { Debug } if debugMsg then
                        addmessage('ddALLAplugin.Text := AddNewFileName( ' + ddALLAplugin.Text + ' );');
                    ALLAfile := AddNewFileName(ddALLAplugin.Text);
                end;
            end;
            if DoesFileExist(ddGEVfile.Text) then
            begin
                // addmessage('[File Prep] '+ddGEVfile.Text+' detected; Preparing file');
                SetObject('ALLAfile', FileByName(ddGEVfile.Text), slGlobal);
            end else begin
                if MessageDlg('Create a new plugin named ' + ddGEVfile.Text + ' [YES] or cancel [NO]?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
                begin
                    { Debug } if debugMsg then
                        addmessage('ddGEVfile.Text := AddNewFileName( ' + ddGEVfile.Text + ' );');
                    ALLAfile := AddNewFileName(ddGEVfile.Text);
                end;
            end;
            if DoesFileExist(ddRecipefile.Text) then
            begin
                // addmessage('[File Prep] '+ddRecipefile.Text+' detected; Preparing file');
                SetObject('ALLAfile', FileByName(ddRecipefile.Text), slGlobal);
            end else begin
                if MessageDlg('Create a new plugin named ' + ddRecipefile.Text + ' [YES] or cancel [NO]?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
                begin
                    { Debug } if debugMsg then
                        addmessage('ddRecipefile.Text := AddNewFileName( ' + ddRecipefile.Text + ' );');
                    ALLAfile := AddNewFileName(ddRecipefile.Text);
                end;
            end;
        end else begin
        end;
    finally
        frm.Free;
    end;

    debugMsg := False;
    // End debugMsg Section
end;

procedure ELLR_Btn_Remove(Sender: TObject);
var
    lblRemovePlugin, lblDetectedFileText              : TLabel;
    tempComponent, btnAdd, btnOk, btnCancel, btnRemove: TButton;
    ddRemovePlugin, ddDetectedFile                    : TComboBox;
    slTemp                                            : TStringList;
    ALLAfile                                          : IInterface;
    frm                                               : TForm;
    debugMsg, exist                                          : Boolean;
    ELLRplugin                                        : string;
    i                                                 : Integer;
begin
    // Begin debugMsg section
    debugMsg := False;

    // Initialize
    slTemp        := TStringList.Create;
    tempComponent := ComponentByTop(ComponentByCaption('Output Plugin: ', Sender.Parent).Top - 2, Sender.Parent);
    ELLRplugin    := tempComponent.Caption;
    if not StrEndsWith(ELLRplugin, '.esl') then
        AppendIfMissing(ELLRplugin, '.esp');
    if DoesFileExist(ELLRplugin) then
    begin
        ALLAfile := FileByName(ELLRplugin);
    end else begin
        addmessage(ELLRplugin + ' does not exist; Cannot use ''Remove'' on unspecified plugin');
        Exit;
    end;

    // Dialogue Box
    frm := TForm.Create(nil);
    try
        // Remove all previous TForm components
        btnOk     := nil;
        btnCancel := nil;

        // Parent Form; Entire Box
        frm.Width    := 850;
        frm.Height   := 200;
        frm.Position := poScreenCenter;
        frm.Caption  := 'Remove a Specified Master';

        // Currently Selected File Label
        lblDetectedFileText         := TLabel.Create(frm);
        lblDetectedFileText.Parent  := frm;
        lblDetectedFileText.Height  := 24;
        lblDetectedFileText.Top     := 68;
        lblDetectedFileText.Left    := 60;
        lblDetectedFileText.Caption := 'Selected File: ';
        frm.Height                  := frm.Height + lblDetectedFileText.Height + 12;

        // Currently Selected File
        ddDetectedFile        := TComboBox.Create(frm);
        ddDetectedFile.Parent := frm;
        ddDetectedFile.Height := lblDetectedFileText.Height;
        ddDetectedFile.Top    := lblDetectedFileText.Top;
        ddDetectedFile.Left   := 230;
        ddDetectedFile.Width  := 480;
        ddDetectedFile.Items.Add(ELLRplugin);
        ddDetectedFile.ItemIndex := 0;

        // Remove Plugin label
        lblRemovePlugin         := TLabel.Create(frm);
        lblRemovePlugin.Parent  := frm;
        lblRemovePlugin.Height  := lblDetectedFileText.Height;
        lblRemovePlugin.Top     := lblDetectedFileText.Top + lblDetectedFileText.Height + 24;
        lblRemovePlugin.Left    := lblDetectedFileText.Left;
        lblRemovePlugin.Caption := 'Remove Plugin: ';
        frm.Height              := frm.Height + lblRemovePlugin.Height + 12;

        // Remove Plugin Drop Down
        ddRemovePlugin        := TComboBox.Create(frm);
        ddRemovePlugin.Parent := frm;
        ddRemovePlugin.Height := lblRemovePlugin.Height;
        ddRemovePlugin.Top    := lblRemovePlugin.Top - 2;
        ddRemovePlugin.Left   := lblRemovePlugin.Left + (9 * Length(lblRemovePlugin.Caption)) + 36;
        ddRemovePlugin.Width  := 480;
        for i                 := 0 to Pred(MasterCount(ALLAfile)) do
            if not(StrEndsWith(GetFileName(MasterByIndex(ALLAfile, i)), '.esm') or StrEndsWith(GetFileName(MasterByIndex(ALLAfile, i)), '.exe') or slContains(slGlobal, GetFileName(MasterByIndex(ALLAfile, i)))) then
                ddRemovePlugin.Items.Add(GetFileName(MasterByIndex(ALLAfile, i)));
        ddRemovePlugin.AutoComplete := True;

        // Add Button
        btnAdd         := TButton.Create(frm);
        btnAdd.Parent  := frm;
        btnAdd.Caption := 'Add';
        btnAdd.Left    := ddRemovePlugin.Left + ddRemovePlugin.Width + 8;
        btnAdd.Top     := lblRemovePlugin.Top;
        btnAdd.Width   := 100;
        btnAdd.OnClick := Btn_AddOrRemove_OnClick;

        // Ok Button
        btnOk             := TButton.Create(frm);
        btnOk.Parent      := frm;
        btnOk.Caption     := 'Ok';
        btnOk.Left        := (frm.Width div 2) - btnOk.Width - 8;
        btnOk.Top         := frm.Height - 80;
        btnOk.ModalResult := mrOk;

        // Cancel Button
        btnCancel             := TButton.Create(frm);
        btnCancel.Parent      := frm;
        btnCancel.Caption     := 'Cancel';
        btnCancel.Left        := btnOk.Left + btnOk.Width + 16;
        btnCancel.Top         := btnOk.Top;
        btnCancel.ModalResult := mrCancel;

        frm.ShowModal;
        // Displays a help message
        if (frm.ModalResult = mrOk) and (ddRemovePlugin.Text <> '') and not CaptionExists('Remove', frm) then
        begin
            lblHelp         := TLabel.Create(frm);
            lblHelp.Parent  := frm;
            lblHelp.Height  := 24;
            lblHelp.Top     := btnAdd.Top + btnAdd.Height + 8;
            lblHelp.Left    := btnAdd.Left - 50;
            lblHelp.Caption := 'USE ADD BUTTON';
            frm.ShowModal;
        end;
        if (frm.ModalResult = mrOk) then
        begin
            tempComponent.Caption := ddDetectedFile.Text;
            slTemp.Clear;
            for i := 0 to slGlobal.Count - 1 do
            begin
                if DoesFileExist(slGlobal[i]) then

                begin
                    slTemp.Add(slGlobal[i]);
                end;
            end;
            for i := 0 to slTemp.Count - 1 do
                if (slGlobal.IndexOf(slTemp[i]) >= 0) then
                    slGlobal.Delete(slGlobal.IndexOf(slTemp[i]));
        end else begin
            tempComponent.Caption := ddDetectedFile.Text;
            slTemp.Clear;
            for i := 0 to slGlobal.Count - 1 do
                if DoesFileExist(slGlobal[i]) then
							 
                    slTemp.Add(slGlobal[i]);
	   
            for i := 0 to slTemp.Count - 1 do
                if (slGlobal.IndexOf(slTemp[i]) >= 0) then
                    slGlobal.Delete(slGlobal.IndexOf(slTemp[i]));
        end;
    finally
        frm.Free;
    end;

    // Finalize
    slTemp.Free;

    debugMsg := False;
    // End debugMsg Section
end;

procedure ELLR_Btn_GenerateRecipes;
var
    btnOk, btnCancel, btnCrafting, btnTemper, btnBreakdown,btnoverwrite: TButton;
    ckCrafting, ckTemper, ckBreakdown,ckoverwrite                     : TCheckBox;
    slTemp                                                : TStringList;
    debugMsg                                              : Boolean;
    i                                                     : Integer;
    frm                                                   : TForm;
begin
    // Begin debugMsg section
    debugMsg := False;

    // Initialize
    slTemp := TStringList.Create;

    frm := TForm.Create(nil);
    try
        // Parent Form; Entire Box
        frm.Width    := 610;
        frm.Height   := 170;
        frm.Position := poScreenCenter;
        frm.Caption  := 'Recipe Settings';

        // Crafting Recipe Button
        btnCrafting         := TButton.Create(frm);
        btnCrafting.Parent  := frm;
        btnCrafting.Top     := 70;
        btnCrafting.Left    := 90;
        btnCrafting.Caption := 'Generate Crafting Recipe';
        btnCrafting.Width   := 400;
        frm.Height          := frm.Height + 42;
        // btnCrafting.OnClick := Btn_Crafting_OnClick;

        // Crafting Recipe Check Box
        ckCrafting        := TCheckBox.Create(frm);
        ckCrafting.Parent := frm;
        ckCrafting.Height := 24;
        ckCrafting.Left   := 500;
        ckCrafting.Top    := btnCrafting.Top + 2;
        if slContains(slGlobal, 'Crafting') then
        begin
            { Debug } if debugMsg then
                addmessage('[ELLR_Btn_GenerateRecipes] ckCrafting.Checked := ' + BoolToStr(Boolean(GetObject('Crafting', slGlobal))));
            ckCrafting.Checked := Boolean(GetObject('Crafting', slGlobal));
        end
        else
            ckCrafting.Checked := True;

        // Temper Recipe Button
        btnTemper         := TButton.Create(frm);
        btnTemper.Parent  := frm;
        btnTemper.Top     := btnCrafting.Top + 40;
        btnTemper.Left    := btnCrafting.Left;
        btnTemper.Caption := 'Generate Temper Recipe';
        btnTemper.Width   := btnCrafting.Width;
        frm.Height        := frm.Height + 42;
        // btnTemper.OnClick := Btn_Temper_OnClick;

        // Temper Recipe Check Box
        ckTemper        := TCheckBox.Create(frm);
        ckTemper.Parent := frm;
        ckTemper.Height := 24;
        ckTemper.Left   := ckCrafting.Left;
        ckTemper.Top    := btnTemper.Top + 2;
        if slContains(slGlobal, 'Temper') then
        begin
            ckTemper.Checked := Boolean(GetObject('Temper', slGlobal));
        end
        else
            ckTemper.Checked := True;

        // Breakdown Button
        btnBreakdown         := TButton.Create(frm);
        btnBreakdown.Parent  := frm;
        btnBreakdown.Top     := btnTemper.Top + 40;
        btnBreakdown.Left    := btnCrafting.Left;
        btnBreakdown.Caption := 'Generate Breakdown Recipe';
        btnBreakdown.Width   := btnCrafting.Width;
        frm.Height           := frm.Height + 42;
        btnBreakdown.OnClick := Btn_Breakdown_OnClick;

        // Break it Down Recipe Check Box
        ckBreakdown        := TCheckBox.Create(frm);
        ckBreakdown.Parent := frm;
        ckBreakdown.Left   := ckCrafting.Left;
        ckBreakdown.Top    := btnBreakdown.Top + 2;
        if slContains(slGlobal, 'Breakdown') then
        begin
            ckBreakdown.Checked := Boolean(GetObject('Breakdown', slGlobal));
        end
        else
            ckBreakdown.Checked := True;
			
		// overwrite Button
        btnoverwrite         := TButton.Create(frm);
        btnoverwrite.Parent  := frm;
        btnoverwrite.Top     := btnBreakdown.Top + 40;
        btnoverwrite.Left    := btnCrafting.Left;
        btnoverwrite.Caption := 'Overwrite existing recipe?';
        btnoverwrite.Width   := btnCrafting.Width;
        frm.Height           := frm.Height + 42;
        btnoverwrite.OnClick := Btn_overwrite_OnClick;

        // Break it Down Recipe Check Box
        ckoverwrite        := TCheckBox.Create(frm);
        ckoverwrite.Parent := frm;
        ckoverwrite.Left   := ckCrafting.Left;
        ckoverwrite.Top    := btnoverwrite.Top + 2;
        if slContains(slGlobal, 'overwrite') then
        begin
            ckoverwrite.Checked := Boolean(GetObject('overwrite', slGlobal));
        end
        else
            ckoverwrite.Checked := True;

        // Ok Button
        btnOk             := TButton.Create(frm);
        btnOk.Parent      := frm;
        btnOk.Caption     := 'Ok';
        btnOk.Left        := (frm.Width div 2) - btnOk.Width - 8;
        btnOk.Top         := frm.Height - 80;
        btnOk.ModalResult := mrOk;

        // Cancel Button
        btnCancel             := TButton.Create(frm);
        btnCancel.Parent      := frm;
        btnCancel.Caption     := 'Cancel';
        btnCancel.Left        := btnOk.Left + btnOk.Width + 16;
        btnCancel.Top         := btnOk.Top;
        btnCancel.ModalResult := mrCancel;

        frm.ShowModal;
        if (frm.ModalResult = mrOk) then
        begin
            // Crafting Results
            SetObject('Crafting', ckCrafting.Checked, slGlobal);
            if CaptionExists('Recipe Scaling: ', frm) then
                SetObject('RecipeScaling', AssociatedComponent('Recipe Scaling: ', frm).Checked, slGlobal);
            // Temper Results
            SetObject('Temper', ckTemper.Checked, slGlobal);
            if CaptionExists('# of Ingots - Light/One-Handed: ', frm) then
                SetObject('TemperLight', StrToInt(AssociatedComponent('# of Ingots - Light/One-Handed: ', frm).Text), slGlobal);
            if CaptionExists('# of Ingots - Heavy/Two-Handed: ', frm) then
                SetObject('TemperHeavy', StrToInt(AssociatedComponent('# of Ingots - Heavy/Two-Handed: ', frm).Text), slGlobal);
            // Breakdown Results
            SetObject('Breakdown', ckBreakdown.Checked, slGlobal);
            slTemp.CommaText := '"Breakdown Equipped: ", "Breakdown Enchanted: ", "Breakdown Daedric: ", "Breakdown DLC: "';
            for i            := 0 to slTemp.Count - 1 do
                if CaptionExists(slTemp[i], frm) then
                    SetObject(RemoveSpaces(StrPosCopy(slTemp[i], ':', True)), AssociatedComponent(slTemp[i], frm).Checked, slGlobal);
            { Debug } if debugMsg then
                msgList('[ELLR_Btn_GenerateRecipes] slGlobal := ', slGlobal, '');
        end;
    finally
        frm.Free;
    end;

    // Finalize
    slTemp.Free;

    debugMsg := False;
    // End debugMsg section
end;

procedure ELLR_OnClick_Remove(Sender: TObject);
var
    tempObject, tempElement: TObject;
    debugMsg               : Boolean;
    frm                    : TForm;
begin
    // Begin debugMsg section
    debugMsg := False;

    frm        := Sender.Parent;
    tempObject := AssociatedComponent('Current Lists: ', frm);
    // SetObject(EditorID(ObjectToElement(tempObject.Items.Objects[tempObject.ItemIndex]))+'-/LeveledList/-'+EditorID(selectedRecord), tempObject.Items.Objects[tempObject.ItemIndex], slGlobal);
    SetObject(EditorID(ObjectToElement(tempObject.Items.Objects[tempObject.ItemIndex])) + '-/Level/-' + EditorID(selectedRecord), 0, slGlobal);
    if (tempObject.ItemIndex > -1) then
        tempObject.Items.Delete(tempObject.ItemIndex);
    tempElement := ComponentByTop(83, frm);
    tempElement.Items.Assign(tempObject.Items);

    debugMsg := False;
    // End debugMsg section
end;

procedure ELLR_OnClick_ClearAll(Sender: TObject);
var
    tempRecord: IInterface;
    tempObject: TObject;
    i         : Integer;
    frm       : TForm;
begin
    frm := Sender.Parent;
    if MessageDlg('Clear all leveled lists [YES] or [NO]?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
        tempObject := AssociatedComponent('Current Lists: ', frm);
        for i      := 0 to tempObject.Items.Count - 1 do
        begin
            SetObject(EditorID(ObjectToElement(tempObject.Items.Objects[i])) + '-/LeveledList/-' + EditorID(selectedRecord), tempObject.Items.Objects[i], slGlobal);
            SetObject(EditorID(ObjectToElement(tempObject.Items.Objects[i])) + '-/Level/-' + EditorID(selectedRecord), 0, slGlobal);
        end
        tempObject.Items.Clear;
        tempObject.Text := '';
    end;
end;

procedure ELLR_OnClick_ddFile(Sender: TObject);
var
    tempRecord: IInterface;
    tempObject: TObject;
    debugMsg  : Boolean;
    i         : Integer;
    frm       : TForm;
begin
    // Begin debugMsg Section
    debugMsg := False;

    frm := Sender.Parent;
    { Debug } if debugMsg then
        addmessage('[ELLR_OnClick_ddFile] Sender.Text := ' + Sender.Text);
    tempRecord := FileByName(Sender.Text);
    { Debug } if debugMsg then
        addmessage('[ELLR_OnClick_ddFile] tempRecord := ' + GetFileName(tempRecord));
    tempObject := AssociatedComponent('Leveled List: ', frm);
    { Debug } if debugMsg then
        addmessage('[ELLR_OnClick_ddFile] Assigned(tempObject) := ' + BoolToStr(Assigned(tempObject)));
    tempObject.Items.Clear;
    for i := 0 to Pred(ElementCount(GroupBySignature(tempRecord, 'LVLI'))) do
        tempObject.Items.AddObject(EditorID(ElementByIndex(GroupBySignature(tempRecord, 'LVLI'), i)), ElementByIndex(GroupBySignature(tempRecord, 'LVLI'), i));
    tempObject.ItemIndex := 0;

    debugMsg := False;
    // End debugMsg section
end;

procedure ELLR_OnClick_ddSuggested(Sender: TObject);
var
    ddSuggestedInvisible, ddLevel: TComboBox;
    tempRecord                   : IInterface;
    tempObject                   : TObject;
    tempString, currentString    : string;
    debugMsg                     : Boolean;
    i                            : Integer;
    frm                          : TForm;
begin
    // Begin debugMsg Section
    debugMsg := False;

    frm           := Sender.Parent;
    ddLevel       := AssociatedComponent('Level: ', frm);
    currentString := IntToStr(IntWithinStr(ddLevel.Text));
    { Debug } if debugMsg then
        addmessage('[ELLR_OnClick_ddSuggested] currentString := ' + currentString);
    ddLevel.Items.Clear;
    ddLevel.Items.Add(StrToInt(Trim(StrPosCopyBtwn(Sender.Text, ':', ')'))));
    ddLevel.ItemIndex    := 0;
    ddSuggestedInvisible := ComponentByTop(83, frm);
    if (ddSuggestedInvisible.ItemIndex <> -1) then
        Sender.Items[ddSuggestedInvisible.ItemIndex] := StrPosCopy(ddSuggestedInvisible.Items[ddSuggestedInvisible.ItemIndex], ':', True) + ': ' + currentString + ')';
    ddSuggestedInvisible.Items.Assign(Sender.Items);
    ddSuggestedInvisible.ItemIndex := Sender.ItemIndex;

    debugMsg := False;
    // End debugMsg section
end;

procedure ELLR_Btn_Add(Sender: TObject);
var
    ddSuggested, ddLeveledList: TComboBox;
    debugMsg, tempBoolean     : Boolean;
    i, tempInteger            : Integer;
    tempRecord                : IInterface;
    tempObject                : TObject;
    tempString                : string;
    frm                       : TForm;
begin
    // Begin debugMsg Section
    debugMsg := False;

    { Debug } if debugMsg then
        addmessage('[ELLR_OnClick_ddFile] Sender.Text := ' + Sender.Text);
    frm := Sender.Parent;

    tempString := AssociatedComponent('Target File: ', frm).Caption; { Debug }
    if debugMsg then
        addmessage('[ELLR_OnClick_ddFile] tempString := ' + tempString);
    tempInteger   := IntWithinStr(AssociatedComponent('Level: ', frm).Text);
    ddLeveledList := AssociatedComponent('Leveled List: ', frm); { Debug }
    if debugMsg then
        addmessage('[ELLR_OnClick_ddFile] Assigned(ddLeveledList) := ' + BoolToStr(Assigned(ddLeveledList)));
    if (ddLeveledList.ItemIndex = -1) then
        Exit;
    tempRecord := ObjectToElement(ddLeveledList.Items.Objects[ddLeveledList.ItemIndex]); { Debug }
    if debugMsg then
        addmessage('[ELLR_OnClick_ddFile] tempRecord := ' + EditorID(tempRecord));
    ddSuggested := AssociatedComponent('Current Lists: ', frm);
    tempBoolean := False;
    for i       := 0 to ddSuggested.Items.Count - 1 do
        if (StrPosCopy(ddSuggested.Items[i], ' ', True) = EditorID(tempRecord)) then
            tempBoolean := True;
    if not tempBoolean then
    begin
        ddSuggested.Items.AddObject(EditorID(tempRecord) + ' (Level: ' + IntToStr(IntWithinStr(AssociatedComponent('Level: ', frm).Caption)) + ')', tempRecord);
        if not slContains(slGlobal, '-/-' + tempString) then
            slGlobal.AddObject('-/-' + tempString + '=' + IntToStr(tempInteger), tempRecord);
        if CaptionExists('Added', frm) then
        begin
            AssociatedComponent('Added', frm).Caption := ddLeveledList.Items[ddLeveledList.ItemIndex];
        end else begin
            tempObject         := TLabel.Create(frm);
            tempObject.Parent  := frm;
            tempObject.Left    := 170;
            tempObject.Top     := ddLeveledList.Top + 40;
            tempObject.Caption := EditorID(tempRecord);

            tempObject         := TLabel.Create(frm);
            tempObject.Parent  := frm;
            tempObject.Left    := 24;
            tempObject.Top     := ddLeveledList.Top + 38;
            tempObject.Caption := 'Added';
        end;
        if CaptionExists('USE ADD BUTTON', frm) then
            ComponentByCaption('USE ADD BUTTON', frm).Free;
    end;

    debugMsg := False;
    // End debugMsg section
end;

procedure ELLR_Btn_AddTo(Sender: TObject);
var
    ddSelectedItem, ddFile, ddLeveledList, ddLevel: TComboBox;
    lblFile, lblLeveledList, lblLevel             : TLabel;
    debugMsg                                      : Boolean;
    btnOk, btnCancel, btnAdd                      : TButton;
    slTemp                                        : TStringList;
    tempObject                                    : TObject;
    tempString                                    : string;
    tempRecord, tempElement, ALLAfile             : IInterface;
    i                                             : Integer;
    frm                                           : TForm;
begin
    // Begin debugMsg Section
    debugMsg := False;

    // Initialize
    frm    := Sender.Parent;
    slTemp := TStringList.Create;

    if not CaptionExists('Target File: ', frm) then
    begin
        // Make space
        frm.Height := frm.Height + 80;
        TShift(Sender.Top + 1, 80, frm, False);

        { Target File Label } if debugMsg then
            addmessage('[ELLR_Btn_AddToLeveledList] Target File Label');
        lblFile         := TLabel.Create(frm);
        lblFile.Parent  := frm;
        lblFile.Left    := 24;
        lblFile.Top     := 160;
        lblFile.Caption := 'Target File: ';

        { Target File Drop Down } if debugMsg then
            addmessage('[ELLR_Btn_AddToLeveledList] Target File');
        ddFile        := TComboBox.Create(frm);
        ddFile.Parent := frm;
        ddFile.Left   := 170;
        ddFile.Top    := lblFile.Top - 2;
        ddFile.Width  := 680;
        for i         := 0 to FileCount - 1 do
            ddFile.Items.Add(GetFileName(FileByIndex(i)));
        ddFile.AutoComplete := True;
        ddFile.OnClick      := ELLR_OnClick_ddFile;

        { Leveled List Label } if debugMsg then
            addmessage('[ELLR_Btn_AddToLeveledList] Leveled List Label');
        lblLeveledList         := TLabel.Create(frm);
        lblLeveledList.Parent  := frm;
        lblLeveledList.Left    := lblFile.Left;
        lblLeveledList.Top     := lblFile.Top + 40;
        lblLeveledList.Caption := 'Leveled List: ';

        { Leveled List Drop Down } if debugMsg then
            addmessage('[ELLR_Btn_AddToLeveledList] Leveled List Drop Down');
        ddLeveledList              := TComboBox.Create(frm);
        ddLeveledList.Parent       := frm;
        ddLeveledList.Left         := 170;
        ddLeveledList.Top          := lblLeveledList.Top - 2;
        ddLeveledList.Width        := 550;
        ddLeveledList.AutoComplete := True;

        { Level Label } if debugMsg then
            addmessage('[ELLR_Btn_AddToLeveledList] Leveled List Label');
        lblLevel         := TLabel.Create(frm);
        lblLevel.Parent  := frm;
        lblLevel.Left    := 730;
        lblLevel.Top     := lblLeveledList.Top + 1;
        lblLevel.Caption := 'Level: ';

        { Level Drop Down } if debugMsg then
            addmessage('[ELLR_Btn_AddToLeveledList] Leveled List Drop Down');
        ddLevel        := TComboBox.Create(frm);
        ddLevel.Parent := frm;
        ddLevel.Left   := 790;
        ddLevel.Top    := lblLevel.Top - 2;
        ddLevel.Width  := 60;
        ddLevel.Items.Add('1');
        ddLevel.ItemIndex := 0;

        { Add Button }
        btnAdd         := TButton.Create(frm);
        btnAdd.Parent  := frm;
        btnAdd.Caption := 'Add';
        btnAdd.Top     := lblLeveledList.Top + 2;
        btnAdd.Left    := ddLevel.Left + ddLevel.Width + 10;
        btnAdd.Width   := 60;
        btnAdd.OnClick := ELLR_Btn_Add;

    end
    else
        if CaptionExists('Target File: ', frm) then
        begin
            slTemp.CommaText := '"Target File: ", "Leveled List: ", "Level: "';
            for i            := 0 to slTemp.Count - 1 do
                AssociatedComponent(slTemp[i], frm).Free;
            for i := 0 to slTemp.Count - 1 do
                ComponentByCaption(slTemp[i], frm).Free;
            ComponentByCaption('Add', frm).Free;
            TShift(Sender.Top + 1, 80, frm, True);
            frm.Height := frm.Height - 80;
        end;

    // Finalize
    slTemp.Free;

    { Debug } debugMsg := False;
    // End debugMsg Section
end;

procedure ELLR_OnClick_SelectedItem_AddToLeveledList(Sender: TObject);
var
    lblSelectedItemText, lblSelectedValueText, lblSelectedGoldValueText: TLabel;
    ddSelectedItem, ddSelectedValue, ddSelectedGoldValue, ddLevel      : TComboBox;
    debugMsg, tempBoolean                                              : Boolean;
    tempRecord, LLrecord                                               : IInterface;
    i, tempCount, tempInteger                                          : Integer;
    slTemp                                                             : TStringList;
    tempObject                                                         : TObject;
    tempString                                                         : string;
    frm                                                                : TForm;
begin
    // Begin debugMsg section
    debugMsg := False;

    // Set Input
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SelectedItem] Set sender form components');
    frm                 := Sender.Parent;
    lblSelectedItemText := AssociatedComponent('Selected Item: ', frm);
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SelectedItem] lblSelectedItemText.Caption := ' + lblSelectedItemText.Caption);
    ddSelectedItem := AssociatedComponent('Selected Item: ', frm);
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SelectedItem] ddSelectedItem.Caption := ' + ddSelectedItem.Caption);
    additionTemplatedSelectedIndex := ddSelectedItem.ItemIndex;
    ddLevel                        := AssociatedComponent('Level: ', frm);

    // Process Leveled Lists
    if CaptionExists('Current Lists: ', frm) then
    begin
        tempObject := AssociatedComponent('Current Lists: ', frm);
        { Debug } if debugMsg then
            addmessage('[ELLR_OnClick_SelectedItem_AddToLeveledList] tempObject.Caption := ' + tempObject.Caption);
        { Debug } if debugMsg then
            addmessage('[ELLR_OnClick_SelectedItem_AddToLeveledList] tempObject.Items[TempObject.ItemIndex] := ' + tempObject.Items[tempObject.ItemIndex]);
        { Debug } if debugMsg then
            addmessage('[ELLR_OnClick_SelectedItem_AddToLeveledList] StrPosCopy(tempObject.Items[tempObject.ItemIndex], :, True) := ' + StrPosCopy(tempObject.Items[tempObject.ItemIndex], ':', True));
        { Debug } if debugMsg then
            addmessage('[ELLR_OnClick_SelectedItem_AddToLeveledList] ddLevel.Caption := ' + ddLevel.Caption);
        { Debug } if debugMsg then
            addmessage('[ELLR_OnClick_SelectedItem_AddToLeveledList] IntToStr(IntWithinStr(ddLevel.Caption))+) := ' + IntToStr(IntWithinStr(ddLevel.Caption)) + ')');
        // Process old form components
        tempObject.Items[tempObject.ItemIndex] := StrPosCopy(tempObject.Items[tempObject.ItemIndex], ':', True) + ': ' + IntToStr(IntWithinStr(ddLevel.Caption)) + ')';
        if (tempObject.Items.Count > 0) then
        begin
            for i := 0 to tempObject.Items.Count - 1 do
            begin
                SetObject(EditorID(ObjectToElement(tempObject.Items.Objects[i])) + '-/LeveledList/-' + EditorID(selectedRecord), tempObject.Items.Objects[i], slGlobal);
                SetObject(EditorID(ObjectToElement(tempObject.Items.Objects[i])) + '-/Level/-' + EditorID(selectedRecord), StrToInt(Trim(StrPosCopyBtwn(tempObject.Items[i], ': ', ')'))), slGlobal);
            end;
        end;

        // Create new form components
        // Record
        selectedRecord := ObjectToElement(Sender.Items.Objects[Sender.ItemIndex]);
        if slContains(slGlobal, EditorID(selectedRecord) + 'Template') then
        begin
            templateRecord := WinningOverride(ObjectToElement(GetObject(EditorID(selectedRecord) + 'Template', slGlobal)));
        end
        else
            templateRecord := GetTemplate(selectedRecord);

        tempObject.Items.Clear;
        tempObject.Caption := 'Populating List...';
        tempInteger        := Pred(ReferencedByCount(templateRecord));
        if (tempInteger > 0) then
        begin
            for i := 0 to tempInteger do
            begin
                LLrecord := ReferencedByIndex(templateRecord, i);
                // Filter Invalid Entries
                if ContainsText(EditorID(LLrecord), '++') or not(Length(EditorID(LLrecord)) > 0) or not IsHighestOverride(LLrecord, GetLoadOrder(ObjectToElement(GetObject('ALLAfile', slGlobal)))) or not(signature(LLrecord) = 'LVLI') or FlagCheck(LLrecord, 'Use All') or FlagCheck(LLrecord, 'Special Loot') then
                    Continue;
                if slContains(slGlobal, EditorID(LLrecord)) then
                    if (EditorID(selectedRecord) = EditorID(ObjectToElement(slGlobal.Objects[slGlobal.IndexOf(EditorID(LLrecord))]))) then
                        Continue;
                tempCount   := 0;
                tempInteger := Pred(LLec(LLrecord));
                if (tempInteger > 0) then
                begin
                    for i := 0 to tempInteger do
                    begin // {Debug} if debugMsg then addmessage('[ELLR_Btn_AddToLeveledList] LLebi(LLrecord, i) := '+EditorID(LLebi(tempRecord, i)));
                        tempRecord := LLebi(tempRecord, i);
                        if (geev(tempRecord, 'LVLO\Reference') = name(selectedRecord)) then
                        begin
                            tempCount := GetElementNativeValues(tempRecord, 'LVLO\Level');
                            Break;
                        end;
                    end;
                end;
                if (tempCount = 0) then
                    tempCount := 1;
                tempString    := EditorID(LLrecord) + ' (Level: ' + IntToStr(tempCount) + ')';
                if not(tempObject.Items.IndexOf(tempString) > -1) then
                    tempObject.Items.AddObject(tempString, LLrecord);
            end;
        end;
        if (tempObject.Items.Count > 0) then
            tempObject.ItemIndex := 0;
    end;
    // Level
    if (tempObject.Items.Count = 0) then
        Exit;
    { Debug } if debugMsg then
        addmessage('[ELLR_OnClick_SelectedItem_AddToLeveledList] Level');
    ddLevel.Items.Clear;
    ddLevel.Caption := '';
    ddLevel.Items.Add(StrPosCopyBtwn(tempObject.Items[0], ': ', ')'));
    ddLevel.ItemIndex := 0;
    { Debug } if debugMsg then
        addmessage('[ELLR_OnClick_SelectedItem_AddToLeveledList] End');
end;

function ELLR_Btn_AddToLeveledList: Boolean;
var
    ddSelectedItem, ddSuggested, ddSuggestedInvisible, ddLevel     : TComboBox;
    lblSelectedItemText, lblSuggested, lblLevel                    : TLabel;
    debugMsg, CustomLevel, exist                                          : Boolean;
    btnOk, btnCancel, btnTemplate, btnRemove, btnAddTo, btnClearAll: TButton;
    slTemp                                                         : TStringList;
    tempString, currentString                                      : string;
    tempRecord, tempElement, ALLAfile, LLrecord                    : IInterface;
    i, x, tempInteger                                              : Integer;
    frm                                                            : TForm;
begin
    // Begin debugMsg Section
    debugMsg := False;

    // Initialize
    { Debug } if debugMsg then
        msgList('[ELLR_Btn_AddToLeveledList] slGlobal := ', slGlobal, '');
    Result := False;
    slTemp := TStringList.Create;
    if slContains(slGlobal, 'ALLAfile') then
        ALLAfile := ObjectToElement(GetObject('ALLAfile', slGlobal));
    if DoesFileExist(ALLAfile) then
				 
    begin
        if not Assigned(selectedRecord) and and (slGlobal.Count >= 0) then
        begin
            for i := 0 to slGlobal.Count - 1 do
            begin
                if not ContainsText(slGlobal[i], 'Original') then
                    Continue;
                selectedRecord := ObjectToElement(slGlobal.Objects[i]);
                Break;
            end;
        end;
    end;
    templateRecord := GetTemplate(selectedRecord);
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_AddToLeveledList] templateRecord := ' + EditorID(templateRecord));

    frm := TForm.Create(nil);
    try
        // Parent Form; Entire Box
        frm.Width    := 1000;
        frm.Height   := 280;
        frm.Position := poScreenCenter;
        frm.Caption  := 'Leveled List Addition Options';

        { Selected Item }
        lblSelectedItemText         := TLabel.Create(frm);
        lblSelectedItemText.Parent  := frm;
        lblSelectedItemText.Left    := 24;
        lblSelectedItemText.Top     := 40;
        lblSelectedItemText.Caption := 'Selected Item: ';

        { Selected Item Drop Down } if debugMsg then
            addmessage('[ELLR_Btn_AddToLeveledList] Selected Item Drop Down');
        ddSelectedItem         := TComboBox.Create(frm);
        ddSelectedItem.Parent  := frm;
        ddSelectedItem.Left    := 170;
        ddSelectedItem.Top     := lblSelectedItemText.Top - 2;
        ddSelectedItem.Width   := 680;
        ddSelectedItem.Caption := 'Populating List...';
        ddSelectedItem.OnClick := ELLR_OnClick_SelectedItem_AddToLeveledList;

        { Template Button }
        btnTemplate         := TButton.Create(frm);
        btnTemplate.Parent  := frm;
        btnTemplate.Caption := '*';
        btnTemplate.Top     := lblSelectedItemText.Top + 2;
        btnTemplate.Left    := ddSelectedItem.Left + ddSelectedItem.Width + 10;
        btnTemplate.Width   := 30;
        btnTemplate.OnClick := ELLR_Btn_SetTemplate;

        { Suggested Leveled List Label } if debugMsg then
            addmessage('[ELLR_Btn_AddToLeveledList] Suggested Leveled List Label');
        lblSuggested         := TLabel.Create(frm);
        lblSuggested.Parent  := frm;
        lblSuggested.Left    := 24;
        lblSuggested.Top     := 80;
        lblSuggested.Caption := 'Current Lists: ';

        { Suggested Leveled List Drop Down } if debugMsg then
            addmessage('[ELLR_Btn_AddToLeveledList] Suggested Leveled List Drop Down');
        ddSuggested         := TComboBox.Create(frm);
        ddSuggested.Parent  := frm;
        ddSuggested.Left    := ddSelectedItem.Left;
        ddSuggested.Top     := lblSuggested.Top - 2;
        ddSuggested.Width   := 550;
        ddSuggested.Caption := 'Populating List...';
        ddSuggested.OnClick := ELLR_OnClick_ddSuggested;

        { Suggested Leveled List Drop Down } if debugMsg then
            addmessage('[ELLR_Btn_AddToLeveledList] Invisible Suggested Leveled List Drop Down');
        ddSuggestedInvisible         := TComboBox.Create(frm);
        ddSuggestedInvisible.Parent  := frm;
        ddSuggestedInvisible.Left    := ddSelectedItem.Left;
        ddSuggestedInvisible.Top     := 83;
        ddSuggestedInvisible.Width   := 550;
        ddSuggestedInvisible.Visible := False;

        { Suggested Leveled List Label } if debugMsg then
            addmessage('[ELLR_Btn_AddToLeveledList] Suggested Leveled List Label');
        lblLevel         := TLabel.Create(frm);
        lblLevel.Parent  := frm;
        lblLevel.Left    := 730;
        lblLevel.Top     := 81;
        lblLevel.Caption := 'Level: ';

        { Suggested Leveled List Drop Down } if debugMsg then
            addmessage('[ELLR_Btn_AddToLeveledList] Suggested Leveled List Drop Down');
        ddLevel        := TComboBox.Create(frm);
        ddLevel.Parent := frm;
        ddLevel.Left   := 790;
        ddLevel.Top    := lblLevel.Top - 2;
        ddLevel.Width  := 60;

        { Remove Button }
        btnRemove         := TButton.Create(frm);
        btnRemove.Parent  := frm;
        btnRemove.Caption := 'Remove';
        btnRemove.Top     := lblSuggested.Top + 2;
        btnRemove.Left    := btnTemplate.Left;
        btnRemove.Width   := 90;
        btnRemove.OnClick := ELLR_OnClick_Remove;

        { Add To Button }
        btnAddTo         := TButton.Create(frm);
        btnAddTo.Parent  := frm;
        btnAddTo.Caption := 'Add a Leveled List';
        btnAddTo.Top     := lblSuggested.Top + 40;
        btnAddTo.Left    := ddSuggested.Left;
        btnAddTo.Width   := 200;
        btnAddTo.OnClick := ELLR_Btn_AddTo;

        { Clear All Button }
        btnClearAll         := TButton.Create(frm);
        btnClearAll.Parent  := frm;
        btnClearAll.Caption := 'Clear All';
        btnClearAll.Top     := btnAddTo.Top;
        btnClearAll.Width   := 100;
        btnClearAll.Left    := ddLevel.Left + ddLevel.Width - btnClearAll.Width;
        btnClearAll.OnClick := ELLR_OnClick_ClearAll;

        { Ok Button }
        btnOk             := TButton.Create(frm);
        btnOk.Parent      := frm;
        btnOk.Caption     := 'Ok';
        btnOk.ModalResult := mrOk;
        btnOk.Left        := frm.Width div 2 - btnOk.Width - 8;
        btnOk.Top         := frm.Height - 80;

        { Cancel Button }
        btnCancel             := TButton.Create(frm);
        btnCancel.Parent      := frm;
        btnCancel.Caption     := 'Cancel';
        btnCancel.ModalResult := mrCancel;
        btnCancel.Left        := btnOk.Left + btnOk.Width + 16;
        btnCancel.Top         := btnOk.Top;

        frm.Visible := True;
        if (slGlobal.Count >= 0) then
        begin
            for i := 0 to slGlobal.Count - 1 do
            begin
                if ContainsText(slGlobal[i], 'Original') then
                begin
                    tempString := full(ObjectToElement(slGlobal.Objects[i]));
                    { Debug } if debugMsg then
                        addmessage('[ELLR_Btn_AddToLeveledList] full(ObjectToElement(slGlobal.Objects[i]) := ' + tempString);
                    if not(ddSelectedItem.Items.IndexOf(tempString) > -1) then
                    begin
                        ddSelectedItem.Items.AddObject(tempString, slGlobal.Objects[i]);
                    end;
                end;
            end;
            if (currentString <> '') and (ddSelectedItem.Items.IndexOf(currentString) <> -1) then
            begin
                ddSelectedItem.ItemIndex := ddSelectedItem.Items.IndexOf(currentString);
                currentString            := nil;
            end else begin
                ddSelectedItem.ItemIndex := 0;
            end;

            additionTemplatedSelectedIndex := ddSelectedItem.ItemIndex;

            for i := 0 to Pred(ReferencedByCount(templateRecord)) do
            begin
                LLrecord := ReferencedByIndex(templateRecord, i); // {Debug} if debugMsg then addmessage('[ELLR_Btn_AddToLeveledList] LLrecord := '+EditorID(LLrecord));
                // Filter Invalid Entries
                if ContainsText(EditorID(LLrecord), '++') or not(Length(EditorID(LLrecord)) > 0) or not IsHighestOverride(LLrecord, GetLoadOrder(ALLAfile)) or not(signature(LLrecord) = 'LVLI') or FlagCheck(LLrecord, 'Use All') or FlagCheck(LLrecord, 'Special Loot') then
                    Continue;
                if slContains(slGlobal, EditorID(LLrecord)) then
                    if (EditorID(selectedRecord) = EditorID(ObjectToElement(slGlobal.Objects[slGlobal.IndexOf(EditorID(LLrecord))]))) then
                        Continue;
                // Previous custom input info
                CustomLevel := False;
                if slContains(slGlobal, EditorID(LLrecord) + '-/Level/-' + EditorID(selectedRecord)) then
                begin
                    tempInteger := Integer(GetObject(EditorID(LLrecord) + '-/Level/-' + EditorID(selectedRecord), slGlobal));
                    if (tempInteger <> 0) then
                    begin
                        CustomLevel := True;
                    end
                    else
                        Continue;
                end;
                // Get item level within LLrecord
                if not CustomLevel then
                begin
                    tempInteger := 0;
                    for x       := 0 to Pred(LLec(LLrecord)) do
                    begin // {Debug} if debugMsg then addmessage('[ELLR_Btn_AddToLeveledList] LLebi(LLrecord, x) := '+EditorID(LLebi(LLrecord, x)));
                        tempRecord := LLebi(LLrecord, x);
                        if (geev(tempRecord, 'LVLO\Reference') = name(selectedRecord)) then
                        begin
                            tempInteger := GetElementNativeValues(tempRecord, 'LVLO\Level');
                            Break;
                        end;
                    end;
                    if (tempInteger = 0) then
                        tempInteger := 1;
                end;
                // Set object
                // {Debug} if debugMsg then msgList('[ELLR_Btn_AddToLeveledList] ddSuggested.Items := ', ddSelectedItem.Items, '');
                tempString := EditorID(LLrecord) + ' (Level: ' + IntToStr(tempInteger) + ')';
                { Debug } if debugMsg then
                    addmessage('[ELLR_Btn_AddToLeveledList] EditorID(LLrecord) (Level: IntToStr(tempInteger)) := ' + tempString);
                if not(ddSuggested.Items.IndexOf(tempString) > -1) then
                    ddSuggested.Items.AddObject(tempString, LLrecord);
            end;
            ddSuggested.Sorted    := True;
            ddSuggested.ItemIndex := 0;
            ddSuggestedInvisible.Items.Assign(ddSuggested.Items);
            ddSuggestedInvisible.ItemIndex := 0;
            if (Length(ddSuggested.Text) > 0) then
                ddLevel.Items.Add(StrToInt(Trim(StrPosCopyBtwn(ddSuggested.Text, ':', ')'))))
            else
                ddLevel.Items.Add(1);
            ddLevel.ItemIndex := 0;
        end;

        { What happens when Ok is pressed }
        frm.Visible := False;
        frm.ShowModal;
        if (frm.ModalResult = mrOk) then
        begin
            if (ddSuggested.ItemIndex <> -1) then
                ddSuggested.Items[ddSuggested.ItemIndex] := StrPosCopy(ddSuggested.Items[ddSuggested.ItemIndex], ':', True) + ': ' + IntToStr(IntWithinStr(ddLevel.Text)) + ')';
            if (ddSuggested.Items.Count > 0) then
                for i := 0 to ddSuggested.Items.Count - 1 do
                begin
                    { Debug } if debugMsg then
                        addmessage('[ELLR_Btn_AddToLeveledList] SetObject( ' + EditorID(ObjectToElement(ddSuggested.Items.Objects[i])) + '-/LeveledList/-' + EditorID(selectedRecord) + ', ' + Trim(StrPosCopyBtwn(ddSuggested.Items[i], ':', ')')) + ' );');
                    SetObject(EditorID(ObjectToElement(ddSuggested.Items.Objects[i])) + '-/LeveledList/-' + EditorID(selectedRecord), ddSuggested.Items.Objects[i], slGlobal);
                    SetObject(EditorID(ObjectToElement(ddSuggested.Items.Objects[i])) + '-/Level/-' + EditorID(selectedRecord), StrToInt(Trim(StrPosCopyBtwn(ddSuggested.Items[i], ':', ')'))), slGlobal);
                end;
            { Debug } if debugMsg then
                msgList('[ELLR_Btn_AddToLeveledList] slGlobal := ', slGlobal, '');
            { Debug } if debugMsg then
                for i := 0 to slGlobal.Count - 1 do
                    if ContainsText(slGlobal[i], '-/LeveledList/-') then
                        addmessage('[ELLR_Btn_AddToLeveledList] ' + slGlobal[i] + ' := ' + IntToStr(Integer(slGlobal.Objects[i])));
        end;
    finally
        frm.Free;
    end;

    // Finalize
    slTemp.Free;

    { Debug } debugMsg := False;
    // End debugMsg Section
end;

procedure ELLR_OnClick_Template(Sender: TObject);
var
    ddFile, ddGroup, ddEditorID: TComboBox;
    debugMsg                   : Boolean;
    Group                      : IInterface;
    frm                        : TForm;
    i                          : Integer;
begin
    frm        := Sender.Parent;
    ddFile     := AssociatedComponent('File: ', frm);
    ddGroup    := AssociatedComponent('Group: ', frm);
    ddEditorID := AssociatedComponent('EditorID: ', frm);
    Group      := GroupBySignature(FileByName(ddFile.Text), ddGroup.Text);
    ddEditorID.Items.Clear;
    for i := 0 to Pred(ElementCount(Group)) do
        ddEditorID.Items.AddObject(EditorID(ElementByIndex(Group, i)), ElementByIndex(Group, i));
    ddEditorID.ItemIndex := 0;
end;

// Set template form creation
function ELLR_Btn_SetTemplate(Sender: TObject): Boolean;
var
    lblEditorID, lblFile, lblGroup, lblSelectedValueText, lblSelectedGoldValueText, lblSelectedItemText, lblTemplate, lblTemplateText, lblTemplateValueText, lblTemplateValue: TLabel;
    ddEditorID, ddGroup, ddFile, ddSelectedItem, ddSelectedValue, ddSelectedGoldValue                                                                                        : TComboBox;
    tempRecord, currentRecord, tempElement, templateRecord, LLrecord                                                                                                         : IInterface;
    debugMsg, tempBoolean, dgBoolean, dgbBoolean                                                                                                                             : Boolean;
    i, x, tempInteger                                                                                                                                                        : Integer;
    btnOk, btnCancel                                                                                                                                                         : TButton;
    frm, ParentForm                                                                                                                                                          : TForm;
    tempObject                                                                                                                                                               : TObject;
    slTemp                                                                                                                                                                   : TStringList;
    tempString                                                                                                                                                               : string;
begin
    // Begin debugMsg Section
    debugMsg := False;

    // Initialize
    Result := False;
    slTemp := TStringList.Create;

    frm := TForm.Create(nil);
    { try }
    // Parent Form; Entire Box
    frm.Width    := 800;
    frm.Height   := 330;
    frm.Position := poScreenCenter;
    frm.Caption  := 'Manual Item Type and Tier Selection';

    // Selected Item
    lblSelectedItemText         := TLabel.Create(frm);
    lblSelectedItemText.Parent  := frm;
    lblSelectedItemText.Left    := 24;
    lblSelectedItemText.Top     := 40;
    lblSelectedItemText.Caption := 'Selected Item: ';

    ddSelectedItem        := TComboBox.Create(frm);
    ddSelectedItem.Parent := frm;
    ddSelectedItem.Left   := 170;
    ddSelectedItem.Top    := lblSelectedItemText.Top - 2;
    ddSelectedItem.Width  := 480;

    // User-selected items are added to slGlobal with the 'Original' suffix.  This is grabbing all the user-input files.
    for i := 0 to slGlobal.Count - 1 do
    begin
        if ContainsText(slGlobal[i], 'Original') then
        begin
            ddSelectedItem.Items.AddObject(full(ObjectToElement(slGlobal.Objects[i])), slGlobal.Objects[i]);
        end;
    end;
    if (tempString <> '') and (ddSelectedItem.Items.IndexOf(tempString) <> -1) then
    begin
        ddSelectedItem.ItemIndex := ddSelectedItem.Items.IndexOf(tempString);
        tempString               := nil;
    end
    else
        ddSelectedItem.ItemIndex := 0;

    ddSelectedItem.ItemIndex := additionTemplatedSelectedIndex;
    ddSelectedItem.OnClick   := ELLR_OnClick_SelectedItem;
    currentRecord            := WinningOverride(ObjectToElement(ddSelectedItem.Items.Objects[ddSelectedItem.ItemIndex]));
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SetTemplate] currentRecord := ' + EditorID(currentRecord));

    // Game Value Label
    lblSelectedValueText        := TLabel.Create(frm);
    lblSelectedValueText.Parent := frm;
    lblSelectedValueText.Left   := 660;
    lblSelectedValueText.Top    := ddSelectedItem.Top + 1;
    if ContainsText(GetGameValueType(currentRecord), 'DNAM') then
    begin
        lblSelectedValueText.Caption := 'Armor: ';
    end
    else
        lblSelectedValueText.Caption := StrPosCopy(GetGameValueType(currentRecord), '\', False) + ': ';

    // Game Value Drop Down
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SetTemplate] Game Value Drop Down');
    ddSelectedValue        := TComboBox.Create(frm);
    ddSelectedValue.Parent := frm;
    ddSelectedValue.Left   := lblSelectedValueText.Left;
    ddSelectedValue.Top    := lblSelectedItemText.Top + 40 - 2;
    ddSelectedValue.Width  := 120;
    ddSelectedValue.Items.Add(GetGameValue(currentRecord));
    ddSelectedValue.ItemIndex := 0;

    // File Label
    lblFile         := TLabel.Create(frm);
    lblFile.Parent  := frm;
    lblFile.Top     := lblSelectedValueText.Top + 40;
    lblFile.Left    := lblSelectedItemText.Left;
    lblFile.Caption := 'File: ';

    // File Drop Down
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SetTemplate] File Drop Down');
    ddFile        := TComboBox.Create(frm);
    ddFile.Parent := frm;
    ddFile.Height := lblFile.Height;
    ddFile.Left   := ddSelectedItem.Left;
    ddFile.Top    := lblFile.Top - 2;
    ddFile.Width  := ddSelectedItem.Width;
    // Add loaded files into the list
    for i := 0 to FileCount - 1 do
    begin
        tempElement := FileByIndex(i);
        ddFile.Items.AddObject(GetFileName(tempElement), tempElement);
    end;
    ddFile.AutoComplete := True;

    // Group Label
    lblGroup         := TLabel.Create(frm);
    lblGroup.Parent  := frm;
    lblGroup.Left    := lblFile.Left;
    lblGroup.Top     := lblFile.Top + 40;
    lblGroup.Caption := 'Group: ';

    // Group Drop Down
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SetTemplate] Group Drop Down');
    ddGroup          := TComboBox.Create(frm);
    ddGroup.Parent   := frm;
    ddGroup.Left     := ddFile.Left;
    ddGroup.Top      := lblGroup.Top - 2;
    ddGroup.Width    := ddFile.Width;
    slTemp.CommaText := 'AMMO, ARMO, WEAP';
    for i            := 0 to slTemp.Count - 1 do
        ddGroup.Items.Add(slTemp[i]);
    ddGroup.AutoComplete := True;
    ddGroup.OnClick      := ELLR_OnClick_Template;

    // Resulting Item Label
    lblEditorID         := TLabel.Create(frm);
    lblEditorID.Parent  := frm;
    lblEditorID.Left    := lblGroup.Left;
    lblEditorID.Top     := lblGroup.Top + 40;
    lblEditorID.Caption := 'EditorID: ';

    // Resulting Item Drop Down
    ddEditorID              := TComboBox.Create(frm);
    ddEditorID.Parent       := frm;
    ddEditorID.Left         := ddGroup.Left;
    ddEditorID.Top          := lblEditorID.Top - 2;
    ddEditorID.Width        := ddFile.Width;
    ddEditorID.Sorted       := True;
    ddEditorID.AutoComplete := True;

    // Suggested Template Label
    lblTemplate         := TLabel.Create(frm);
    lblTemplate.Parent  := frm;
    lblTemplate.Left    := lblSelectedItemText.Left;
    lblTemplate.Top     := lblEditorID.Top + 40;
    lblTemplate.Caption := 'Current: ';

    // Suggested Template Item Label
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SetTemplate] Suggested Template Item Label');
    lblTemplateText        := TLabel.Create(frm);
    lblTemplateText.Parent := frm;
    lblTemplateText.Left   := ddSelectedItem.Left;
    lblTemplateText.Top    := lblTemplate.Top + 1;

    // Set caption as 'Armor: ', 'Damage: ', or 'Value: '
    if (ddSelectedItem.ItemIndex <> -1) then
    begin
        tempElement := WinningOverride(ObjectToElement(ddSelectedItem.Items.Objects[ddSelectedItem.ItemIndex]));
        if slContains(slGlobal, EditorID(tempElement) + 'Template') then
        begin
            tempElement := WinningOverride(ObjectToElement(GetObject(EditorID(tempElement) + 'Template', slGlobal)));
        end
        else
            tempElement := GetTemplate(WinningOverride(ObjectToElement(ddSelectedItem.Items.Objects[ddSelectedItem.ItemIndex])));
        { Debug } if debugMsg then
            addmessage('[ELLR_Btn_SetTemplate] tempElement := ' + EditorID(tempElement));
        if (GetGameValueType(tempElement) = 'DNAM') then
        begin
            lblTemplateText.Caption := full(tempElement) + ' (Armor: ' + GetGameValue(tempElement) + ')';
        end
        else
            lblTemplateText.Caption := full(tempElement) + ' (' + StrPosCopy(GetGameValueType(tempElement), '\', False) + ': ' + GetGameValue(tempElement) + ')';
    end;

    // Ok Button
    btnOk             := TButton.Create(frm);
    btnOk.Parent      := frm;
    btnOk.Caption     := 'Ok';
    btnOk.ModalResult := mrOk;
    btnOk.Left        := frm.Width div 2 - btnOk.Width - 8;
    btnOk.Top         := frm.Height - 80;

    // Cancel Button
    btnCancel             := TButton.Create(frm);
    btnCancel.Parent      := frm;
    btnCancel.Caption     := 'Cancel';
    btnCancel.ModalResult := mrCancel;
    btnCancel.Left        := btnOk.Left + btnOk.Width + 16;
    btnCancel.Top         := btnOk.Top;

    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SetTemplate] Create value box if not primary value');
    // Create value box if not primary value
    // If the primary value of the item is its gold value (like jewelry) then only a single editable value box is created
    // This code only runs if the item is a weapon/armor
    { Debug } if debugMsg then
        addmessage('[ELLR_Btn_SetTemplate] if not ContainsText(GetGameValueType(currentRecord) := ' + GetGameValueType(currentRecord) + ', Value) then begin');
    if not ContainsText(GetGameValueType(currentRecord), 'Value') then
    begin
        lblSelectedGoldValueText         := TLabel.Create(frm);
        lblSelectedGoldValueText.Parent  := frm;
        lblSelectedGoldValueText.Left    := 660;
        lblSelectedGoldValueText.Top     := ddSelectedItem.Top + 80;
        lblSelectedGoldValueText.Caption := 'Value: ';

        ddSelectedGoldValue        := TComboBox.Create(frm);
        ddSelectedGoldValue.Parent := frm;
        ddSelectedGoldValue.Left   := lblSelectedValueText.Left;
        ddSelectedGoldValue.Top    := lblSelectedGoldValueText.Top + 38;
        ddSelectedGoldValue.Width  := ddSelectedValue.Width;
        ddSelectedGoldValue.Items.Add(geev(currentRecord, 'DATA\Value'));
        ddSelectedGoldValue.ItemIndex := 0;
    end;

    // What happens when Ok is pressed
    selectedRecord := currentRecord;
    frm.ShowModal;
    currentRecord := WinningOverride(ObjectToElement(ddSelectedItem.Items.Objects[ddSelectedItem.ItemIndex]));
    tempBoolean   := False;
    if (frm.ModalResult = mrOk) then
    begin
        { Debug } if debugMsg then
            addmessage('[ELLR_Btn_SetTemplate] frm.ModalResult = mrOk');
        // Change template record
        if (ddEditorID.Text <> '') then
        begin
            if (MessageDlg('Do you wish to change the template of ' + full(currentRecord) + ' from ' + full(tempElement) + ' to ' + full(ObjectToElement(ddEditorID.Items.Objects[ddEditorID.ItemIndex])) + '?', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
            begin
                { Debug } if debugMsg then
                    addmessage('[ELLR_Btn_SetTemplate] currentRecord := ' + EditorID(currentRecord));
                templateRecord := WinningOverride(ObjectToElement(ddEditorID.Items.Objects[ddEditorID.ItemIndex]));
                { Debug } if debugMsg then
                    addmessage('[ELLR_Btn_SetTemplate] templateRecord := ' + EditorID(templateRecord));
                SetObject(EditorID(currentRecord) + 'Template', templateRecord, slGlobal);
                // Clear Leveled Lists in Global List
                slTemp.Clear;
                for i := 0 to Pred(slGlobal.Count) do
                begin
                    if ContainsText(slGlobal[i], 'Level: ') then
                        slTemp.Add(IntToStr(i))
                end;
                for i := 0 to Pred(slTemp.Count) do
                    slGlobal.Delete(StrToInt(slTemp[i]));
                // Clear Leveled Lists Menu
                ParentForm := Sender.Parent;
                tempObject := AssociatedComponent('Current Lists: ', ParentForm);
                tempObject.Items.Clear;
                for i := 0 to Pred(ReferencedByCount(templateRecord)) do
                begin
                    LLrecord := WinningOverride(ReferencedByIndex(templateRecord, i)); // {Debug} if debugMsg then addmessage('[ELLR_Btn_SetTemplate] LLrecord := '+EditorID(LLrecord));
                    // Filter Invalid Entries
                    if ContainsText(EditorID(LLrecord), '++') or not(Length(EditorID(LLrecord)) > 0) or not IsHighestOverride(LLrecord, GetLoadOrder(ObjectToElement(GetObject('ALLAfile', slGlobal)))) or not(signature(LLrecord) = 'LVLI') or FlagCheck(LLrecord, 'Use All') or FlagCheck(LLrecord, 'Special Loot') then
                        Continue;
                    if slContains(slGlobal, EditorID(LLrecord)) then
                        if (EditorID(selectedRecord) = EditorID(ObjectToElement(slGlobal.Objects[slGlobal.IndexOf(EditorID(LLrecord))]))) then
                            Continue;
                    if slContains(slGlobal, EditorID(LLrecord) + '-/Level/-' + EditorID(selectedRecord)) then
                    begin
                        tempInteger := Integer(GetObject(EditorID(LLrecord) + '-/Level/-' + EditorID(selectedRecord), slGlobal));
                        if (tempInteger = 0) then
                            Continue;
                    end else begin
                        tempInteger := 0;
                        for x       := 0 to Pred(LLec(LLrecord)) do
                        begin // {Debug} if debugMsg then addmessage('[ELLR_Btn_SetTemplate] LLebi(LLrecord, x) := '+EditorID(LLebi(LLrecord, x)));
                            tempRecord := LLebi(LLrecord, x);
                            if (geev(tempRecord, 'LVLO\Reference') = name(selectedRecord)) then
                            begin
                                tempInteger := GetElementNativeValues(tempRecord, 'LVLO\Level');
                                Break;
                            end;
                        end;
                        if (tempInteger = 0) then
                            tempInteger := 1;
                    end;
                    // Set object
                    tempObject.Items.AddObject(EditorID(LLrecord) + ' (Level: ' + IntToStr(tempInteger) + ')', LLrecord);
                end;
                tempObject.ItemIndex := 0;
            end;
        end;
        { Debug } if debugMsg then
            msgList('[ELLR_Btn_AddToLeveledListInfo] slGlobal := ', slGlobal, '');
        // Change record values if edit boxes were changed
        if (Length(full(currentRecord)) > 0) then
            if (full(currentRecord) <> full(currentRecord)) or (ddSelectedValue.Text <> GetGameValue(currentRecord)) then
                tempBoolean := True;
        if ContainsText(GetGameValueType(currentRecord), 'Value') then
            if ((ddSelectedGoldValue.Text <> geev(currentRecord, 'DATA\Value')) and (Length(ddSelectedGoldValue.Text) > 0)) then
                tempBoolean := True;
    end
    else
        Result := True;
    if tempBoolean then
    begin
        if MessageDlg('Do you wish to save changes to ' + full(currentRecord) + ' [YES] or discard [NO]?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        begin
            if (full(currentRecord) <> full(currentRecord)) and (Length(full(currentRecord)) > 0) then
            begin
                { Debug } if debugMsg then
                    addmessage('seev( currentRecord, FULL, ' + full(currentRecord) + ' )');
                seev(currentRecord, 'FULL', full(currentRecord));
            end;
            if (ddSelectedValue.Text <> GetGameValue(currentRecord)) and (Length(ddSelectedValue.Caption) > 0) then
            begin
                { Debug } if debugMsg then
                    addmessage('seev( ' + EditorID(currentRecord) + ', ' + GetGameValueType(currentRecord) + ', ' + full(currentRecord) + ' )');
                senv(currentRecord, GetGameValueType(currentRecord), StrToInt(ddSelectedValue.Caption));
            end;
            if not ContainsText(GetGameValueType(currentRecord), 'Value') then
                if (ddSelectedGoldValue.Text <> GetElementEditValues(currentRecord, 'DATA\Value')) and (Length(ddSelectedGoldValue.Text) > 0) then
                    seev(currentRecord, 'DATA\Value', ddSelectedGoldValue.Text);
            // Assign template item
            if ContainsText(ddFile.Text, '.esm') or ContainsText(ddFile.Text, '.exe') or ContainsText(ddFile.Text, '.esp') then
            begin
                slGlobal.Objects[IndexOfObjectEDID(EditorID(currentRecord))] := GetRecordByFormID(ddEditorID.Text);
            end
            else
                slGlobal.Objects[IndexOfObjectEDID(EditorID(currentRecord))] := ddEditorID.Objects[ddEditorID.ItemIndex];
        end;
    end;
    tempString := ddSelectedItem.Text;
    { finally }
    frm.Free;
    { end; }

    { Debug } debugMsg := False;
    // End debugMsg Section
end;

procedure ELLR_Btn_SelectedItemInfo(Sender: TObject);
var
    tempObject, btnDetectedItem: TObject;
    slCaption                  : TStringList;
    debugMsg, tempBoolean      : Boolean;
    frm                        : TForm;
    i                          : Integer;
begin
    // Begin debugMsg Section
    debugMsg := False;

    // Initialize
    slCaption := TStringList.Create;

    // Common function input
    frm := Sender.Parent;

    // Process
    slCaption.Add('A menu to edit values associated the selected records');
    slCaption.Add('Includes support for Male/Female Only armors');
    { Debug } if debugMsg then
        msgList('[ELLR_Btn_AddToLeveledListInfo] slCaption := ', slCaption, '');
    tempBoolean := False;
    for i       := 0 to slCaption.Count - 1 do
    begin
        if CaptionExists(slCaption[i], frm) then
        begin
            { Debug } if debugMsg then
                addmessage('[ELLR_Btn_AddToLeveledListInfo] CaptionExists := ' + slCaption[i]);
            tempBoolean := True;
            tempObject  := ComponentByCaption(slCaption[i], frm);
            tempObject.Free;
            frm.Width  := 610;
            frm.Height := frm.Height - 40;
            TShift(Sender.Top + 3, 40, frm, True);
        end;
    end;
    if not tempBoolean then
    begin
        for i := slCaption.Count - 1 downto 0 do
        begin
            frm.Width  := 1100;
            frm.Height := frm.Height + 40;
            TShift(Sender.Top + 3, 40, frm, False);
            tempObject         := TLabel.Create(frm);
            tempObject.Parent  := frm;
            tempObject.Top     := Sender.Top + 40;
            tempObject.Left    := Sender.Left + 60;
            tempObject.Caption := slCaption[i];
        end;
    end;

    // Finalize
    slCaption.Free;

    debugMsg := False;
    // End debugMsg Section
end;

procedure ELLR_Btn_OutputPluginInfo(Sender: TObject);
var
    tempObject, btnDetectedItem: TObject;
    slCaption                  : TStringList;
    debugMsg, tempBoolean      : Boolean;
    frm                        : TForm;
    i                          : Integer;
begin
    // Begin debugMsg Section
    debugMsg := False;

    // Initialize
    slCaption := TStringList.Create;

    // Common function input
    frm := Sender.Parent;

    // Process
    slCaption.Add('A menu to set the output file for the script');
    slCaption.Add('The three main sections can all have different output files');
    slCaption.Add('A new file will be created if it does not already exist');
    slCaption.Add('The output file must be loaded after enchantment mods if using Generate Enchanted Versions');
    slCaption.Add('The output file will have many new masters after the script is finished');
    slCaption.Add('For these reasons the default output plugin is highly recommended');
    { Debug } if debugMsg then
        msgList('[ELLR_Btn_AddToLeveledListInfo] slCaption := ', slCaption, '');
    tempBoolean := False;
    for i       := 0 to slCaption.Count - 1 do
    begin
        if CaptionExists(slCaption[i], frm) then
        begin
            { Debug } if debugMsg then
                addmessage('[ELLR_Btn_AddToLeveledListInfo] CaptionExists := ' + slCaption[i]);
            tempBoolean := True;
            tempObject  := ComponentByCaption(slCaption[i], frm);
            tempObject.Free;
            frm.Width  := 610;
            frm.Height := frm.Height - 40;
            TShift(Sender.Top + 3, 40, frm, True);
        end;
    end;
    if not tempBoolean then
    begin
        for i := slCaption.Count - 1 downto 0 do
        begin
            frm.Width  := 1100;
            frm.Height := frm.Height + 40;
            TShift(Sender.Top + 3, 40, frm, False);
            tempObject         := TLabel.Create(frm);
            tempObject.Parent  := frm;
            tempObject.Top     := Sender.Top + 40;
            tempObject.Left    := Sender.Left + 60;
            tempObject.Caption := slCaption[i];
        end;
    end;

    // Finalize
    slCaption.Free;

    debugMsg := False;
    // End debugMsg Section
end;

procedure ELLR_Btn_AddToLeveledListInfo(Sender: TObject);
var
    tempObject, btnDetectedItem: TObject;
    slCaption                  : TStringList;
    debugMsg, tempBoolean      : Boolean;
    frm                        : TForm;
    i                          : Integer;
begin
    // Begin debugMsg Section
    debugMsg := False;

    // Initialize
    slCaption := TStringList.Create;

    // Common function input
    frm := Sender.Parent;

    // Process
    slCaption.Add('The script automatically detects appropriate lists for ' + full(selectedRecord));
    slCaption.Add('The ''Add to Leveled Lists'' button shows what leveled lists ' + full(selectedRecord) + ' will be added to');
    slCaption.Add('Uncheck the checkbox to the right of the button to disable');
    { Debug } if debugMsg then
        msgList('[ELLR_Btn_AddToLeveledListInfo] slCaption := ', slCaption, '');
    tempBoolean := False;
    for i       := 0 to slCaption.Count - 1 do
    begin
        if CaptionExists(slCaption[i], frm) then
        begin
            { Debug } if debugMsg then
                addmessage('[ELLR_Btn_AddToLeveledListInfo] CaptionExists := ' + slCaption[i]);
            tempBoolean := True;
            tempObject  := ComponentByCaption(slCaption[i], frm);
            tempObject.Free;
            frm.Width  := 610;
            frm.Height := frm.Height - 40;
            TShift(Sender.Top + 3, 40, frm, True);
        end;
    end;
    if not tempBoolean then
    begin
        for i := slCaption.Count - 1 downto 0 do
        begin
            frm.Width  := 1100;
            frm.Height := frm.Height + 40;
            TShift(Sender.Top + 3, 40, frm, False);
            tempObject         := TLabel.Create(frm);
            tempObject.Parent  := frm;
            tempObject.Top     := Sender.Top + 40;
            tempObject.Left    := Sender.Left + 60;
            tempObject.Caption := slCaption[i];
        end;
    end;

    // Finalize
    slCaption.Free;

    debugMsg := False;
    // End debugMsg Section
end;

procedure ELLR_Btn_EnchantedInfo(Sender: TObject);
var
    tempObject, btnDetectedItem: TObject;
    slCaption                  : TStringList;
    debugMsg, tempBoolean      : Boolean;
    frm                        : TForm;
    i                          : Integer;
begin
    // Begin debugMsg Section
    debugMsg := False;

    // Initialize
    slCaption := TStringList.Create;

    // Common function input
    frm := Sender.Parent;

    // Process
    slCaption.Add('The script can automatically generate enchanted versions of the input item');
    slCaption.Add('The enchanted versions will also be added to leveled lists');
    slCaption.Add('Click the ''Generate Enchanted Versions'' button for options');
    slCaption.Add('Uncheck the checkbox next to the button to disable');
    { Debug } if debugMsg then
        msgList('[ELLR_Btn_AddToLeveledListInfo] slCaption := ', slCaption, '');
    tempBoolean := False;
    for i       := 0 to slCaption.Count - 1 do
    begin
        if CaptionExists(slCaption[i], frm) then
        begin
            { Debug } if debugMsg then
                addmessage('[ELLR_Btn_AddToLeveledListInfo] CaptionExists := ' + slCaption[i]);
            tempBoolean := True;
            tempObject  := ComponentByCaption(slCaption[i], frm);
            tempObject.Free;
            frm.Width  := 610;
            frm.Height := frm.Height - 40;
            TShift(Sender.Top + 3, 40, frm, True);
        end;
    end;
    if not tempBoolean then
    begin
        for i := slCaption.Count - 1 downto 0 do
        begin
            frm.Width  := 1100;
            frm.Height := frm.Height + 40;
            TShift(Sender.Top + 3, 40, frm, False);
            tempObject         := TLabel.Create(frm);
            tempObject.Parent  := frm;
            tempObject.Top     := Sender.Top + 40;
            tempObject.Left    := Sender.Left + 60;
            tempObject.Caption := slCaption[i];
        end;
    end;

    // Finalize
    slCaption.Free;

    debugMsg := False;
    // End debugMsg Section
end;

procedure ELLR_Btn_RecipeInfo(Sender: TObject);
var
    tempObject, btnDetectedItem: TObject;
    slCaption                  : TStringList;
    debugMsg, tempBoolean      : Boolean;
    frm                        : TForm;
    i                          : Integer;
begin
    // Begin debugMsg Section
    debugMsg := False;

    // Initialize
    slCaption := TStringList.Create;

    // Common function input
    frm := Sender.Parent;

    // Process
    slCaption.Add('The script can automatically generate recipes for the input item');
    slCaption.Add('Crafting, tempering, and breakdown recipes are supported');
    slCaption.Add('Click the ''Generate Recipes'' button for options');
    slCaption.Add('Uncheck the checkbox next to the button to disable ');
    { Debug } if debugMsg then
        msgList('[ELLR_Btn_AddToLeveledListInfo] slCaption := ', slCaption, '');
    tempBoolean := False;
    for i       := 0 to slCaption.Count - 1 do
    begin
        if CaptionExists(slCaption[i], frm) then
        begin
            { Debug } if debugMsg then
                addmessage('[ELLR_Btn_AddToLeveledListInfo] CaptionExists := ' + slCaption[i]);
            tempBoolean := True;
            tempObject  := ComponentByCaption(slCaption[i], frm);
            tempObject.Free;
            frm.Width  := 610;
            frm.Height := frm.Height - 40;
            TShift(Sender.Top + 3, 40, frm, True);
        end;
    end;
    if not tempBoolean then
    begin
        for i := slCaption.Count - 1 downto 0 do
        begin
            frm.Width  := 1100;
            frm.Height := frm.Height + 40;
            TShift(Sender.Top + 3, 40, frm, False);
            tempObject         := TLabel.Create(frm);
            tempObject.Parent  := frm;
            tempObject.Top     := Sender.Top + 40;
            tempObject.Left    := Sender.Left + 60;
            tempObject.Caption := slCaption[i];
        end;
    end;

    // Finalize
    slCaption.Free;

    debugMsg := False;
    // End debugMsg Section
end;

function ELLR_GeneralSettings: TStringList;
var
    lblDetectedItem, lblPlugin, lblEnchanted                                                                                                                                                         : TLabel;
    btnOk, btnCancel, btnBulk, btnAddToLeveledList, btnEnchanted, btnPlugin, btnDetectedItem, btnRemove, btnPatch, btnRecipe, btnAddToLeveledListInfo, btnEnchantedInfo, btnRecipeInfo, btnPluginInfo: TButton;
    ckAddToLeveledList, ckEnchanted, ckRecipe                                                                                                                                                        : TCheckBox;
    tempRecord, TF                                                                                                                                                                                       : IInterface;
    ddEnchanted                                                                                                                                                                                      : TComboBox;
    debugMsg, exist                                                                                                                                                                                         : Boolean;
    i                                                                                                                                                                                                : Integer;
    frm                                                                                                                                                                                              : TForm;
begin
    // Begin debugMsg Section
    debugMsg := False;

    // Initialize
    if not Assigned(selectedRecord) then
    begin
        for i := 0 to slGlobal.Count - 1 do
        begin
            if ContainsText(slGlobal[i], 'Original') then
            begin
                selectedRecord := ObjectToElement(slGlobal.Objects[i]);
                Break;
            end;
        end;
    end;

    frm := TForm.Create(nil);
    try
        // Parent Form; Entire Box
        frm.Width    := 610;
        frm.Height   := 350;
        frm.Position := poScreenCenter;
        frm.Caption  := 'General Settings';

        // Currently Selected Item Label
        lblDetectedItem         := TLabel.Create(frm);
        lblDetectedItem.Parent  := frm;
        lblDetectedItem.Left    := 90;
        lblDetectedItem.Top     := 70;
        lblDetectedItem.Caption := 'Currently Selected Item: ';

        // Currently Selected Item Button
        btnDetectedItem         := TButton.Create(frm);
        btnDetectedItem.Parent  := frm;
        btnDetectedItem.Left    := 330;
        btnDetectedItem.Top     := lblDetectedItem.Top + 1;
        btnDetectedItem.Caption := full(ObjectToElement(slGlobal.Objects[0]));
        btnDetectedItem.Width   := 160;
        btnDetectedItem.OnClick := ELLR_Btn_SelectedItem;

        // Output Plugin Label
        lblPlugin         := TLabel.Create(frm);
        lblPlugin.Parent  := frm;
        lblPlugin.Top     := lblDetectedItem.Top + 40;
        lblPlugin.Left    := lblDetectedItem.Left;
        lblPlugin.Caption := 'Output Plugin: ';
        frm.Height        := frm.Height + lblPlugin.Height + 8;

        // Output Plugin Button
        btnPlugin        := TButton.Create(frm);
        btnPlugin.Parent := frm;
        btnPlugin.Top    := lblPlugin.Top - 2;
        btnPlugin.Left   := lblPlugin.Left + (9 * Length(lblPlugin.Caption)) + 20;
        if slContains(slGlobal, 'ALLAfile') then
        begin
            btnPlugin.Caption := GetFileName(ObjectToElement(GetObject('ALLAfile', slGlobal)));
        end
        else
            btnPlugin.Caption := defaultOutputPlugin;
        btnPlugin.Width       := 245;
        btnPlugin.OnClick     := ELLR_Btn_Plugin;

        { // Output Plugin Info Button }
        { btnPluginInfo := TButton.Create(frm); }
        { btnPluginInfo.Parent := frm; }
        { btnPluginInfo.Left := lblPlugin.Left - 60; }
        { btnPluginInfo.Top := lblPlugin.Top; }
        { btnPluginInfo.Caption := '?'; }
        { btnPluginInfo.Width := 40; }
        { btnPluginInfo.OnClick := ELLR_Btn_OutputPluginInfo; }

        // Add to Leveled List Button
        btnAddToLeveledList         := TButton.Create(frm);
        btnAddToLeveledList.Parent  := frm;
        btnAddToLeveledList.Left    := lblPlugin.Left;
        btnAddToLeveledList.Top     := lblPlugin.Top + 40;
        btnAddToLeveledList.Caption := 'Add to Leveled Lists: ';
        btnAddToLeveledList.Width   := 400;
        btnAddToLeveledList.OnClick := ELLR_Btn_AddToLeveledList;

        // Add to Leveled List Check Box
        ckAddToLeveledList         := TCheckBox.Create(frm);
        ckAddToLeveledList.Parent  := frm;
        ckAddToLeveledList.Left    := 500;
        ckAddToLeveledList.Top     := btnAddToLeveledList.Top + 2;
        ckAddToLeveledList.Checked := Boolean(GetObject('ReplaceInLeveledList', slGlobal));

        // Add to Leveled List Info Button
        btnAddToLeveledListInfo         := TButton.Create(frm);
        btnAddToLeveledListInfo.Parent  := frm;
        btnAddToLeveledListInfo.Left    := btnAddToLeveledList.Left - 60;
        btnAddToLeveledListInfo.Top     := btnAddToLeveledList.Top;
        btnAddToLeveledListInfo.Caption := '?';
        btnAddToLeveledListInfo.Width   := 40;
        btnAddToLeveledListInfo.OnClick := ELLR_Btn_AddToLeveledListInfo;

        // Generate Enchanted Versions Button
        btnEnchanted         := TButton.Create(frm);
        btnEnchanted.Parent  := frm;
        btnEnchanted.Left    := btnAddToLeveledList.Left;
        btnEnchanted.Top     := btnAddToLeveledList.Top + 40;
        btnEnchanted.Caption := 'Generate Enchanted Versions: ';
        btnEnchanted.Width   := 400;
        slGlobal.AddObject('NoButtons', 0);
        btnEnchanted.OnClick := GEV_GeneralSettings;

        // Generate Enchanted Versions Check Box
        ckEnchanted         := TCheckBox.Create(frm);
        ckEnchanted.Parent  := frm;
        ckEnchanted.Left    := ckAddToLeveledList.Left;
        ckEnchanted.Top     := btnEnchanted.Top + 2;
        ckEnchanted.Checked := Boolean(GetObject('GenerateEnchantedVersions', slGlobal));

        // Generate Enchanted Versions Info Button
        btnEnchantedInfo         := TButton.Create(frm);
        btnEnchantedInfo.Parent  := frm;
        btnEnchantedInfo.Left    := btnEnchanted.Left - 60;
        btnEnchantedInfo.Top     := btnEnchanted.Top;
        btnEnchantedInfo.Caption := '?';
        btnEnchantedInfo.Width   := 40;
        btnEnchantedInfo.OnClick := ELLR_Btn_EnchantedInfo;

        // Generate Recipes Button
        btnRecipe         := TButton.Create(frm);
        btnRecipe.Parent  := frm;
        btnRecipe.Left    := btnAddToLeveledList.Left;
        btnRecipe.Top     := btnEnchanted.Top + 40;
        btnRecipe.Caption := 'Generate Recipes: ';
        btnRecipe.Width   := 400;
        btnRecipe.OnClick := ELLR_Btn_GenerateRecipes;

        // Generate Recipes Check Box
        ckRecipe         := TCheckBox.Create(frm);
        ckRecipe.Parent  := frm;
        ckRecipe.Left    := ckAddToLeveledList.Left;
        ckRecipe.Top     := btnRecipe.Top + 2;
        ckRecipe.Checked := Boolean(GetObject('GenerateRecipes', slGlobal));

        // Generate Enchanted Versions Info Button
        btnRecipeInfo         := TButton.Create(frm);
        btnRecipeInfo.Parent  := frm;
        btnRecipeInfo.Left    := btnRecipe.Left - 60;
        btnRecipeInfo.Top     := btnRecipe.Top;
        btnRecipeInfo.Caption := '?';
        btnRecipeInfo.Width   := 40;
        btnRecipeInfo.OnClick := ELLR_Btn_RecipeInfo;

        // Ok Button
        btnOk             := TButton.Create(frm);
        btnOk.Parent      := frm;
        btnOk.Caption     := 'Ok';
        btnOk.Left        := (frm.Width div 2) - btnOk.Width - 8;
        btnOk.Top         := frm.Height - 80;
        btnOk.ModalResult := mrOk;

        // Cancel Button
        btnCancel             := TButton.Create(frm);
        btnCancel.Parent      := frm;
        btnCancel.Caption     := 'Cancel';
        btnCancel.Left        := btnOk.Left + btnOk.Width + 16;
        btnCancel.Top         := btnOk.Top;
        btnCancel.ModalResult := mrCancel;

        { // Help Button }
        { btnCancel := TButton.Create(frm); }
        { btnCancel.Parent := frm; }
        { btnCancel.Caption := 'Help'; }
        { btnCancel.Left := btnEnchantedInfo; }
        { btnCancel.Top := btnOk.Top; }

        // Remove Button
        btnRemove         := TButton.Create(frm);
        btnRemove.Parent  := frm;
        btnRemove.Caption := 'Remove';
        btnRemove.Left    := 50;
        btnRemove.Top     := 20;
        btnRemove.Width   := 100;
        btnRemove.OnClick := ELLR_Btn_Remove;

        // Patch Button
        btnPatch         := TButton.Create(frm);
        btnPatch.Parent  := frm;
        btnPatch.Caption := 'Patch';
        btnPatch.Left    := 255;
        btnPatch.Top     := 20;
        btnPatch.Width   := 100;
        btnPatch.OnClick := ELLR_Btn_Patch;

        // Bulk Button
        btnBulk         := TButton.Create(frm);
        btnBulk.Parent  := frm;
        btnBulk.Caption := 'DO NOT USE';
		//btnBulk.ShowHint := 'vestigial method which has no use anymore. will be replaced with something better soon';
        btnBulk.Left    := frm.Width - 150;
        btnBulk.Top     := 20;
        btnBulk.Width   := 100;
        btnBulk.OnClick := Btn_Bulk_OnClick_Old;

        // What happens when Ok is pressed
        frm.ShowModal;
        slDeleteString('NoButtons', slGlobal);
        if (frm.ModalResult = mrOk) then
        begin
            if not DoesFileExist(btnPlugin.Caption) then
            begin
                if MessageDlg('Create a new plugin named ' + btnPlugin.Text + ' [YES] or cancel [NO]?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then
                begin
                    CancelAll := True;
                    Exit;
                end
                else
                    AddNewFileName(btnPlugin.Text);
            end;
            SetObject('GenerateEnchantedVersions', ckEnchanted.Checked, slGlobal);
            SetObject('ALLAfile', FileByName(btnPlugin.Caption), slGlobal);
            if not slContains(slGlobal, 'GEVfile') then
                SetObject('GEVfile', FileByName(btnPlugin.Caption), slGlobal);
            if not slContains(slGlobal, 'RecipeFile') then
                SetObject('RecipeFile', FileByName(btnPlugin.Caption), slGlobal);
            SetObject('GenerateRecipes', ckRecipe.Checked, slGlobal);
            SetObject('AddtoLeveledList', ckAddToLeveledList.Checked, slGlobal);
        end
        else
            if (frm.ModalResult = mrRetry) then
            begin
                SetObject('GenerateEnchantedVersions', False, slGlobal);
                SetObject('GenerateRecipes', False, slGlobal);
                SetObject('AddtoLeveledList', True, slGlobal);
            end
            else
                CancelAll := True;
    finally
        frm.Free;
    end;

    debugMsg := False;
    // End debugMsg Section
end;

/// /////////////////////////////////////////////////////////////////// SCRIPT INITIALIZATION ////////////////////////////////////////////////////////////////////////////////
// Runs on script start
function Initialize: Integer; // runs on script start
begin
    addmessage('---Starting Generator---');
    addmessage('If you get an ''IwbImplementation'' error or an ''access violation'' error set the xEdit.exe to run as administrator');
    addmessage('If you get an ''Out of Memory'' error use the 64bit xEdit.exe ');

    // Initialize Global
    slProcessTime := TStringList.Create;
    slGlobal      := TStringList.Create;
    IniProcess;
    IniBlacklist;
    IniALLASettings;
	template;
end;

// Process collects all the records into a single list; The main section is in Finalize so that records can use a common index
function Process(aRecord: IInterface): Integer;
var
    debugMsg           : Boolean;
    tempRecord         : IInterface;
    startTime, stopTime: TDateTime;
    slTemp             : TStringList;
    i, x               : Integer;
begin
    // Skip
    debugMsg := False;

    // Initialize
    startTime := Time;
    slTemp    := TStringList.Create;
    aRecord   := WinningOverride(aRecord);

    // Record selected
    slTemp.CommaText := 'ARMO, AMMO, WEAP';
    // Filter invalid records
    { Debug } if debugMsg then
        addmessage('[Process] Filtering Invalid Records');
    if slWithinStr(signature(aRecord), slTemp) then
    begin
        if not isBlacklist(aRecord) then
            Exit;
        { Debug } if debugMsg then
            addmessage('[Process] aRecord := ' + EditorID(aRecord));
        SetObject(EditorID(aRecord) + 'Original', aRecord, slGlobal);
    end else begin
        tempRecord := GroupBySignature(GetFile(aRecord), signature(aRecord));
        { Debug } if debugMsg then
            addmessage('[Process] if ( ' + IntToStr(FormID(aRecord)) + ' = ' + IntToStr(FormID(ElementByIndex(tempRecord, 0))) + ' then begin');
        if (FormID(aRecord) = FormID(ElementByIndex(tempRecord, 0))) then
            skipCount := ElementCount(tempRecord);
    end;
    { Debug } if debugMsg then
        msgList('[function Process] slGlobal := ', slGlobal, '');

    // Finalize
    slTemp.Free;
    stopTime := Time;
    if ProcessTime then
        addProcessTime('Process', TimeBtwn(stopTime, startTime));

    debugMsg := False;
    // End debugMsg Section
end;

/// /////////////////////////////////////////////////////////////////// MAIN SECTION BEGIN ///////////////////////////////////////////////////////////////////////////////////
function Finalize: Integer;
var
    slTemp, slIndex, slOutfit, slRecords, slTemplate, slFiles: TStringList;
    TF, tempRecord, ALLAfile, RecipeFile, outfitLevelList        : IInterface;
	tempGrup : IInterface;
    startTime, stopTime, tempStart, tempStop                 : TDateTime;
    i, x, y, z, tempInteger, debugMsgSection                 : Integer;
    debugMsg, tempBoolean, exist                                    : Boolean;
    tempString                                               : string;
begin
    /// /////////////////////////////////////////////////////////////////// PREP SECTION /////////////////////////////////////////////////////////////////////////////////////////
    // Skip
    if slGlobal.Count = 0 then
    begin
        addmessage('No valid records detected');
        Exit;
    end;
    // Initialize
    debugMsg   := false;
    startTime  := Time;
    slTemplate := TStringList.Create;
    slRecords  := TStringList.Create;
    slOutfit   := TStringList.Create;
    slFiles    := TStringList.Create;
    slTemp     := TStringList.Create;

    // Detect loaded plugins
    slTemp.CommaText := 'Skyrim.esm, Dawnguard.esm, Dragonborn.esm, HolyEnchants.esp, LostEnchantments.esp, "More Interesting Loot for Skyrim.esp", "Summermyst - Enchantments of Skyrim.esp", "Wintermyst - Enchantments of Skyrim.esp"';
    for i            := 0 to slTemp.Count - 1 do
        if DoesFileExist(slTemp[i]) then
            slFiles.AddObject(Trim(slTemp[i]), FileByName(slTemp[i]));
    // {Debug} if debugMsg then msgList('slFiles := ', slFiles, '');
    // {Debug} if debugMsg then for i := 0 to slFiles.Count-1 do addmessage('[GetTemplate] slFiles.Objects['+IntToStr(i)+'] := '+GetFileName(ObjectToElement(slFiles.Objects[i])));
    // Set default; Settings are easily found at the top of the code, this is just setting the variables

    { Debug } if debugMsg then
        msgList('slGlobal := ', slGlobal, '');
    { Debug } if debugMsg then
        addmessage('AllowDisenchanting := ' + BoolToStr(Boolean(GetObject('AllowDisenchanting', slGlobal))));
    { Debug } if debugMsg then
        addmessage('Breakdown := ' + BoolToStr(Boolean(GetObject('Breakdown', slGlobal))));
    { Debug } if debugMsg then
        addmessage('Temper := ' + BoolToStr(Boolean(GetObject('Temper', slGlobal))));

    // Assign ALLAfile
    if not Assigned(ALLAfile) then
    begin
        ELLR_GeneralSettings;
        ALLAfile   := ObjectToElement(GetObject('ALLAfile', slGlobal));
        RecipeFile := ObjectToElement(GetObject('RecipeFile', slGlobal));
        { Debug } if debugMsg then
            addmessage('ALLAfile := ' + GetFileName(ALLAfile));
    end;

    if Assigned(ALLAfile) then
    begin
        // Add necessary groups
        slTemp.CommaText := 'LVLI, ARMO, WEAP, OTFT';
        for y            := 0 to slTemp.Count - 1 do
            if not HasGroup(ALLAfile, slTemp[y]) then
                Add(ALLAfile, slTemp[y], True);
    end
    else
        CancelAll := True;
    if Assigned(ALLAfile) then
    begin
        // Add necessary groups
        slTemp.CommaText := 'AMMO, ARMO, WEAP';
        for y            := 0 to slTemp.Count - 1 do
            if not HasGroup(ALLAfile, slTemp[y]) then
                Add(ALLAfile, slTemp[y], True);
    end
    else
        CancelAll := True;
    if Assigned(ALLAfile) then
    begin
        // Add necessary groups
        slTemp.CommaText := 'COBJ';
        for y            := 0 to slTemp.Count - 1 do
            if not HasGroup(ALLAfile, slTemp[y]) then
                Add(ALLAfile, slTemp[y], True);
        AddmasterBySignature('ARMO', ALLAfile);
        AddmasterBySignature('KYWD', ALLAfile);
        AddmasterBySignature('AMMO', ALLAfile);
        AddmasterBySignature('WEAP', ALLAfile);
        AddmasterBySignature('LVLI', ALLAfile);
        AddmasterBySignature('ARMA', ALLAfile);
        AddmasterBySignature('ENCH', ALLAfile);
        AddmasterBySignature('OTFT', ALLAfile);
        AddmasterBySignature('COBJ', ALLAfile);
        AddmasterBySignature('MISC', ALLAfile);
        // heel sound exception
        if Assigned(FileByName('Heels Sound.esm')) then
            addmasterifmissing(ALLAfile, 'Heels Sound.esm');
    end
    else
        CancelAll := True;

    // Cancel all
    if CancelAll then
    begin
        // Finalize
        if Assigned(slTemplate) then
            slTemplate.Free;
        if Assigned(slRecords) then
            slRecords.Free;
        if Assigned(slOutfit) then
            slOutfit.Free;
        if Assigned(slGlobal) then
            slGlobal.Free;
        if Assigned(slFiles) then
            slFiles.Free;
        if Assigned(slTemp) then
            slTemp.Free;
        Exit;
    end;

    if Boolean(GetObject('AddtoLeveledList', slGlobal)) or Boolean(GetObject('GenerateEnchantedVersions', slGlobal)) then
    begin
        // Load templates
        debugMsgSection := 0;
//msgListObject('slGlobal', slGlobal,'');
        { Debug } addmessage('debugMsgSection := ' + IntToStr(debugMsgSection));
        for i := 0 to slGlobal.Count - 1 do
        begin
            if ContainsText(slGlobal[i], 'Original') then
            begin
                if not slContains(slGlobal, StrPosCopy(slGlobal[i], 'Original', True) + 'Template') then
                begin
                    SetObject(StrPosCopy(slGlobal[i], 'Original', True) + 'Template', GetTemplate(ObjectToElement(GetObject(slGlobal[i], slGlobal))), slGlobal);
                    { Debug } if debugMsg or (debugMsgSection >= 2) then
                        addmessage('SetObject(' + StrPosCopy(slGlobal[i], 'Original', True) + 'Template' + ', GetTemplate(' + EditorID(ObjectToElement(GetObject(slGlobal[i], slGlobal))) + ', slGlobal)');
                end;
            end;
        end;
        // Load valid records into lists
        for i := 0 to slGlobal.Count - 1 do
            if ContainsText(slGlobal[i], 'Original') then
                if (GetLoadOrder(ALLAfile) >= GetLoadOrder(GetFile(ObjectToElement(slGlobal.Objects[i])))) then
                    SetObject(StrPosCopy(slGlobal[i], 'Original', True), slGlobal.Objects[i], slRecords);
//msgListObject('slrecords', slRecords,'');
        for i := 0 to slRecords.Count - 1 do
            if not slContains(slTemplate, slRecords[i] + 'Template') then
                slTemplate.AddObject(slRecords[i] + 'Original', GetObject(slRecords[i] + 'Template', slGlobal));

        { Debug } if debugMsg or (debugMsgSection >= 1) then
            msgList('slGlobal := ', slGlobal, '');
        { Debug } if debugMsg or (debugMsgSection >= 1) then
            msgListObject('slGlobal(Objects) := ', slGlobal, '');
        { Debug } if debugMsg or (debugMsgSection >= 1) then
            msgList('slRecords := ', slRecords, '');
        { Debug } if debugMsg or (debugMsgSection >= 1) then
            msgListObject('slRecords(Objects) := ', slRecords, '');
        debugMsgSection := 0;

        // Add masters
        tempStart := Time;
        tempStop  := Time;
        addProcessTime('Add Masters', TimeBtwn(tempStart, tempStop));
    end;
    // Add to leveled lists
    tempStart := Time;
    if Boolean(GetObject('AddtoLeveledList', slGlobal)) then
        AddOutfitByList(slTemplate, ALLAfile);
    tempStop := Time;
    addProcessTime('Add to Leveled Lists', TimeBtwn(tempStart, tempStop));
    // Process Male/Female-Only Records
    addmessage('Processing Male/Female-Only Records');
    for i := 0 to slRecords.Count - 1 do
    begin
        tempRecord := ObjectToElement(slRecords.Objects[i]);
        // Check both Keyword/EditorID/IsFemaleOnly
        if signature(tempRecord) = 'ARMO' then
        begin
            if HasGenderKeyword(tempRecord) then
            begin
                GenderOnlyArmor(GetGenderFromKeyword(tempRecord), tempRecord, ALLAfile);
            end 
			else
				if ContainsText(EditorID(tempRecord), 'FemaleOnly') then
				begin
					GenderOnlyArmor('Female', tempRecord, ALLAfile);
				end
				else
					if IsFemaleOnly(tempRecord) then begin
						GenderOnlyArmor('Female', tempRecord, ALLAfile);
					end else if ContainsText(EditorID(tempRecord), 'MaleOnly') then
						GenderOnlyArmor('Male', tempRecord, ALLAfile);
        end;
    end;

    // Generate recipes
    tempStart := Time;
    { Debug } if debugMsg then
        addmessage('[GenerateRecipes] Generate Recipes; Recipes(' + BoolToStr(Boolean(GetObject('GenerateRecipes', slGlobal))) + ') Crafting(' + BoolToStr(Boolean(GetObject('Crafting', slGlobal))) + ') Temper(' + BoolToStr(Boolean(GetObject('Temper', slGlobal))) + ') Breakdown(' + BoolToStr(Boolean(GetObject('Breakdown', slGlobal))) + ')');

    if Boolean(GetObject('GenerateRecipes', slGlobal)) then
    begin
        InitializeRecipes;
        IniProcess;
        TempPerkFunctionSetup;
        addmessage('Generating Recipes');
        { Debug } if debugMsg then
            msgList('[GenerateRecipes] slRecords := ', slRecords, '');
        for i := 0 to slRecords.Count - 1 do
        begin
            tempRecord := ObjectToElement(slRecords.Objects[i]);
            // prepping yggs stuff
            if Boolean(GetObject('Crafting', slGlobal)) or Boolean(GetObject('Temper', slGlobal)) then
                GatherMaterials;
            if Boolean(GetObject('Crafting', slGlobal)) then
                MakeCraftable(tempRecord, RecipeFile);
            if Boolean(GetObject('Temper', slGlobal)) then
                MakeTemperable(tempRecord, Integer(GetObject('TemperLight', slGlobal)), Integer(GetObject('TemperHeavy', slGlobal)), RecipeFile);
            if Boolean(GetObject('Breakdown', slGlobal)) then
                MakeBreakdown(tempRecord, RecipeFile);
        end;
    end;
    tempStop := Time;
    addProcessTime('Generate Recipes', TimeBtwn(tempStart, tempStop));

    // Generate Enchanted Versions
    if ProcessTime then
        tempStart := Time;
    { Debug } if debugMsg then
        addmessage('[GenerateEnchantedVersions] GenerateEnchantedVersions := ' + BoolToStr(Boolean(GetObject('GenerateEnchantedVersions', slGlobal))));
    if Boolean(GetObject('GenerateEnchantedVersions', slGlobal)) then
        GenerateEnchantedVersionsAuto;
    if ProcessTime then
    begin
        tempStop := Time;
        addProcessTime('Generate Enchanted Versions', TimeBtwn(tempStart, tempStop));
    end;
    // Finalize
    stopTime := Time;
    addmessage('---Process Time Summary---');
    addProcessTime('Total Process Time', TimeBtwn(startTime, stopTime));
    for i := 0 to slProcessTime.Count - 1 do
        addmessage(slProcessTime[i] + ': ' + IntegerToTime(Integer(slProcessTime.Objects[i])));
    slProcessTime.Free;
    slTemplate.Free;
    slRecords.Free;
    slOutfit.Free;
    slGlobal.Free;
    slFiles.Free;
    slTemp.Free;

    /// /////////////////////////////////////////////////////////////////// MAIN SECTION END //////////////////////////////////////////////////////////////////////////////////////////

    addmessage('---Ending Generator---');
	tempGrup := GroupBySignature(ALLAfile, 'LVLI');
	for i := 0 to ElementCount(tempGrup) do begin
		RemoveInvalidEntries(ElementByIndex(tempGrup, i));
	end;
    CleanMasters(ALLAfile);
    // CleanMasters(RecipeFile); for when the separate files is fixed
    // CleanMasters(enchantfile); for when separate files is fixed
end;

end.
