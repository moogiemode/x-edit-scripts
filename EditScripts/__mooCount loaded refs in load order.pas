Unit CountLoadedRefs;

Var
   giTemporaryCount: Integer;
   giPersistentCount: Integer;
   giPluginTemporaryCount: Integer;
   giPluginPersistentCount: Integer;

Const
   gtPersistent = 8;
   gtTemporary = 9;

Procedure IncCount(iTemporaryCount: Integer; iPersistentCount: Integer;);
Begin
   giPluginTemporaryCount := giPluginTemporaryCount + iTemporaryCount;
   giPluginPersistentCount := giPluginPersistentCount + iPersistentCount;
   giTemporaryCount := giTemporaryCount + iTemporaryCount;
   giPersistentCount := giPersistentCount + iPersistentCount;
End;

// Always count NEW Persistent Refs, never overridden ones
// Only count NEW Temporary Refs if new in esp, or previous overload was a master.
Function GetRefCount(eCell: IInterface; eCellChildren: IInterface; AGrupType: Integer; bESM: Boolean): Integer;
Var
   eCellGroup: IInterface;
   iChildIndex: Integer;
   eChildElement: IInterface;
Begin
   eCellGroup := FindChildGroup(eCellChildren, AGrupType, eCell);
   Result := 0;
   for iChildIndex := 0 To ElementCount(eCellGroup) - 1 Do Begin
      eChildElement := ElementByIndex(eCellGroup, iChildIndex);
      if (Signature(eChildElement) = 'REFR') or (Signature(eChildElement) = 'ACHR') or (Signature(eChildElement) = 'PHZD') then Begin
         if AGrupType = gtTemporary Then Begin
            if not bESM and IsWinningOverride(eChildElement) Then
               Result := Result + 1;
         End Else if AGrupType = gtPersistent Then Begin
            if IsMaster(eChildElement) Then
               Result := Result + 1;
         End;
      End;
   End;
End;

Procedure CountRefsInCell(eCell: IInterface; bESM: Boolean);
Var
   eCellChildren: IInterface;
   iPersistentCount: Integer;
   iTemporaryCount: Integer;
Begin
   eCellChildren := ChildGroup(eCell);
   iPersistentCount := GetRefCount(eCell, eCellChildren, gtPersistent, bESM);
   iTemporaryCount := GetRefCount(eCell, eCellChildren, gtTemporary, bESM);
   IncCount(iTemporaryCount, iPersistentCount);
End;

Procedure CountCellSpace(eBlockParent: IInterface; bESM: Boolean);
Var
   eBlock:     IInterface;
   eSubBlock:  IInterface;
   eCell:      IInterface;
   iBlockIndex: Integer;
   iSubBlockIndex: Integer;
   iCellIndex: Integer;
Begin
   For iBlockIndex := 0 To ElementCount(eBlockParent) - 1 Do Begin
      eBlock := ElementByIndex(eBlockParent, iBlockIndex);
      For iSubBlockIndex := 0 To ElementCount(eBlock) - 1 Do Begin
         eSubBlock := ElementByIndex(eBlock, iSubBlockIndex);
         for iCellIndex := 0 To ElementCount(eSubBlock) - 1 Do Begin
            eCell := ElementByIndex(eSubBlock, iCellIndex);
            CountRefsInCell(eCell, bESM);
         End;
      End;
   End;
End;

Function Initialize: Integer;
Var
   eFile:      IInterface;
   eWorlds:    IInterface;
   eWorld:     IInterface;
   eTemporary: IInterface;
   eCell:      IInterface;
   eCells:      IInterface;
   iFileIndex: Integer;
   iWorldIndex: Integer;
   bESM: Boolean;
   iTotalPluginCount: Integer;
Begin
   giTemporaryCount := 0;
   giPersistentCount := 0;
   //
   For iFileIndex := 0 To FileCount - 1 Do Begin
      giPluginTemporaryCount := 0;
      giPluginPersistentCount := 0;
      eFile   := FileByIndex(iFileIndex);
      bESM := GetIsESM(eFile);
      CountCellSpace(GroupBySignature(eFile, 'CELL'), bESM);

      eWorlds := GroupBySignature(eFile, 'WRLD');
      For iWorldIndex := 0 To ElementCount(eWorlds) - 1 Do Begin
         eWorld := ElementByIndex(eWorlds, iWorldIndex);
         eTemporary := ChildGroup(eWorld);
         
         eCell      := ElementByName(eTemporary, '<Persistent Worldspace Cell>');
         CountRefsInCell(eCell, bESM);

         CountCellSpace(eWorld, bESM);
      End;

      iTotalPluginCount := giPluginPersistentCount + giPluginTemporaryCount;
      if iTotalPluginCount > 100 then
         AddMessage(Format(
            'Found %d temporary and %d persistent (%d total) loaded references in %s.', [giPluginTemporaryCount, giPluginPersistentCount, iTotalPluginCount, Name(eFile)]));
   End;
   AddMessage(Format(
      'Found %d temporary and %d persistent loaded references, for a grand total of %d loaded references.', [giTemporaryCount, giPersistentCount, giTemporaryCount + giPersistentCount]
   ));
End;

End.
