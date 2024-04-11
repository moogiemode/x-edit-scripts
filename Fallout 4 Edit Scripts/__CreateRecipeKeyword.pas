unit __CreateRecipeKeyword;

uses praFunctions, mteFunctions, praUtil, moogieUtils;

var
	patchFile: IwbFile;
  recipeName: string;
	// patchFileCreated: boolean;
	// mainFileKeywords, patchFileKeywords: TList;
	craftingKeyword: IInterface;

//============================================================================

function Initialize: integer;
	var 
		i: integer;
		keywordRecord: IInterface;
	begin
		// mainFileKeywords := TList.Create;
		// patchFileKeywords := TList.Create;
	end;

//============================================================================

function Process(e: IInterface): integer;
	var
		recKeywords, keywordRecord, newCraftingRecipe: IInterface;
		i: Integer;
    recipeName: string;
    canContinue: boolean;
	begin
		// check if signature of the current record is COBJ meaning constructible object, if not we exit
    if not Assigned(craftingKeyword) then begin

      craftingKeyword := CreateRecipeKeywordWithInputName(GetFile(e));

    end;
	end;
end.


//============================================================================

function Finalize: integer;
	begin
		// free the memory used by the lists
		// mainFileKeywords.Free;
		// patchFileKeywords.Free;
	end;


//LinksTo(ElementBySignature(e, 'COCT')) = 0
//GetFileName(e) => gets the file name that the record is in
//FileByIndex(0) => gets the main file
// addRequiredMastersSilent