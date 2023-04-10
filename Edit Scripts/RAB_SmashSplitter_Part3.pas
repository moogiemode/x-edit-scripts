unit RAB_SmashSplitter_Part3;
 
	uses mteFunctions;
 
	// Init global variables:
		var
			Int_Loop_FindQLs, Int_Loop_Sigs, Int_Iteration: integer;
			str_ThisFileDecription: string;
			obj_ThisQL, obj_ThisSmashPatch: IInterface;
			Arr_Sigs: TStringList;
 
	function Initialize: integer; begin
 
		// Startup message:
			ClearMessages();
			AddMessage( ' ' );
			AddMessage('===========================================================');
			AddMessage('                           STARTING SMASH MASTER LIMIT OVERLOAD SPLIT CLEANER');
			AddMessage('===========================================================');
			AddMessage( ' ' );
 
		// Init some variables:
			InitSigs();
 
		// Iterate all files:
			for Int_Loop_FindQLs := 0 to 9999 do begin
				Int_Iteration := 0;
				obj_ThisQL := FileByName('SmashSplitQL' + IntToStr(Int_Loop_FindQLs) + '.' + IntToStr(Int_Iteration) + '.esp');
				// No more QLs to find? break!
				if GetLoadOrder(obj_ThisQL) < 0 then break;
				for Int_Iteration := 0 to 9999 do begin
				// No more QLs to find? Break!
					obj_ThisQL := FileByName('SmashSplitQL' + IntToStr(Int_Loop_FindQLs) + '.' + IntToStr(Int_Iteration) + '.esp');
 
					if GetLoadOrder(obj_ThisQL) < 0 then break;
 
					AddMessage( 'Found ' + GetFileName(obj_ThisQL) + ' ... trimming unwanted record types from associated Smashed Patch...' );
					str_ThisFileDecription := GetElementNativeValues(ElementByIndex(obj_ThisQL,0),'SNAM');
 
					// Iterate sigs in this SmashedPatch:
						obj_ThisSmashPatch := FileByName('Smashed Patch ' + IntToStr(Int_Loop_FindQLs) + '.' + IntToStr(Int_Iteration) + '.esp');
						for Int_Loop_Sigs := 0 to Pred(Arr_Sigs.Count) do begin
							if (Assigned(GroupBySignature(obj_ThisSmashPatch,Arr_Sigs[Int_Loop_Sigs]))) and (Pos(Arr_Sigs[Int_Loop_Sigs],str_ThisFileDecription)<1) then begin
								AddMessage( '   SmashedPatch' + IntToStr(Int_Loop_FindQLs) + ' has unwanted sig group ' + Arr_Sigs[Int_Loop_Sigs] + '... deleting!' );
								RemoveNode( GroupBySignature(obj_ThisSmashPatch,Arr_Sigs[Int_Loop_Sigs]) );
							end;
						end;
						CleanMasters(obj_ThisSmashPatch);
				end;
			end;
 
		// Finale message:
			AddMessage( ' ' );
			AddMessage('===========================================================');
			AddMessage('                           FINISHED SMASH MASTER LIMIT OVERLOAD SPLIT CLEANER       ');
			AddMessage('===========================================================');
 
	end;
 
 
	function InitSigs(): null; begin
 
		// Definte the signatures to find:
			Arr_Sigs := TStringList.Create;
			Arr_Sigs.Add('AACT');
			Arr_Sigs.Add('ACHR');
			Arr_Sigs.Add('ACTI');
			Arr_Sigs.Add('ADDN');
			Arr_Sigs.Add('ALCH');
			Arr_Sigs.Add('AMMO');
			Arr_Sigs.Add('ANIO');
			Arr_Sigs.Add('APPA');
			Arr_Sigs.Add('ARMA');
			Arr_Sigs.Add('ARMO');
			Arr_Sigs.Add('ARTO');
			Arr_Sigs.Add('ASPC');
			Arr_Sigs.Add('ASTP');
			Arr_Sigs.Add('AVIF');
			Arr_Sigs.Add('BOOK');
			Arr_Sigs.Add('BPTD');
			Arr_Sigs.Add('CAMS');
			Arr_Sigs.Add('CELL');
			Arr_Sigs.Add('CLAS');
			Arr_Sigs.Add('CLDC');
			Arr_Sigs.Add('CLFM');
			Arr_Sigs.Add('CLMT');
			Arr_Sigs.Add('COBJ');
			Arr_Sigs.Add('COLL');
			Arr_Sigs.Add('CONT');
			Arr_Sigs.Add('CPTH');
			Arr_Sigs.Add('CSTY');
			Arr_Sigs.Add('DEBR');
			Arr_Sigs.Add('DIAL');
			Arr_Sigs.Add('DLBR');
			Arr_Sigs.Add('DLVW');
			Arr_Sigs.Add('DOBJ');
			Arr_Sigs.Add('DOOR');
			Arr_Sigs.Add('DUAL');
			Arr_Sigs.Add('ECZN');
			Arr_Sigs.Add('EFSH');
			Arr_Sigs.Add('ENCH');
			Arr_Sigs.Add('EQUP');
			Arr_Sigs.Add('EXPL');
			Arr_Sigs.Add('EYES');
			Arr_Sigs.Add('FACT');
			Arr_Sigs.Add('FLOR');
			Arr_Sigs.Add('FLST');
			Arr_Sigs.Add('FSTP');
			Arr_Sigs.Add('FSTS');
			Arr_Sigs.Add('FURN');
			Arr_Sigs.Add('GLOB');
			Arr_Sigs.Add('GMST');
			Arr_Sigs.Add('GRAS');
			Arr_Sigs.Add('HAIR');
			Arr_Sigs.Add('HAZD');
			Arr_Sigs.Add('HDPT');
			Arr_Sigs.Add('IDLE');
			Arr_Sigs.Add('IDLM');
			Arr_Sigs.Add('IMAD');
			Arr_Sigs.Add('IMGS');
			Arr_Sigs.Add('INFO');
			Arr_Sigs.Add('INGR');
			Arr_Sigs.Add('IPCT');
			Arr_Sigs.Add('IPDS');
			Arr_Sigs.Add('KEYM');
			Arr_Sigs.Add('KYWD');
			Arr_Sigs.Add('LAND');
			Arr_Sigs.Add('LCRT');
			Arr_Sigs.Add('LCTN');
			Arr_Sigs.Add('LENS');
			Arr_Sigs.Add('LGTM');
			Arr_Sigs.Add('LIGH');
			Arr_Sigs.Add('LSCR');
			Arr_Sigs.Add('LTEX');
			Arr_Sigs.Add('LVLI');
			Arr_Sigs.Add('LVLN');
			Arr_Sigs.Add('LVSP');
			Arr_Sigs.Add('MATO');
			Arr_Sigs.Add('MATT');
			Arr_Sigs.Add('MESG');
			Arr_Sigs.Add('MGEF');
			Arr_Sigs.Add('MISC');
			Arr_Sigs.Add('MOVT');
			Arr_Sigs.Add('MSTT');
			Arr_Sigs.Add('MUSC');
			Arr_Sigs.Add('MUST');
			Arr_Sigs.Add('NAVI');
			Arr_Sigs.Add('NAVM');
			Arr_Sigs.Add('NPC_');
			Arr_Sigs.Add('OTFT');
			Arr_Sigs.Add('PACK');
			Arr_Sigs.Add('PARW');
			Arr_Sigs.Add('PBAR');
			Arr_Sigs.Add('PBEA');
			Arr_Sigs.Add('PCON');
			Arr_Sigs.Add('PERK');
			Arr_Sigs.Add('PFLA');
			Arr_Sigs.Add('PGRE');
			Arr_Sigs.Add('PHZD');
			Arr_Sigs.Add('PLYR');
			Arr_Sigs.Add('PMIS');
			Arr_Sigs.Add('PROJ');
			Arr_Sigs.Add('PWAT');
			Arr_Sigs.Add('QUST');
			Arr_Sigs.Add('RACE');
			Arr_Sigs.Add('REFR');
			Arr_Sigs.Add('REGN');
			Arr_Sigs.Add('RELA');
			Arr_Sigs.Add('REVB');
			Arr_Sigs.Add('RFCT');
			Arr_Sigs.Add('RGDL');
			Arr_Sigs.Add('SCEN');
			Arr_Sigs.Add('SCOL');
			Arr_Sigs.Add('SCPT');
			Arr_Sigs.Add('SCRL');
			Arr_Sigs.Add('SHOU');
			Arr_Sigs.Add('SLGM');
			Arr_Sigs.Add('SMBN');
			Arr_Sigs.Add('SMEN');
			Arr_Sigs.Add('SMQN');
			Arr_Sigs.Add('SNCT');
			Arr_Sigs.Add('SNDR');
			Arr_Sigs.Add('SOPM');
			Arr_Sigs.Add('SOUN');
			Arr_Sigs.Add('SPEL');
			Arr_Sigs.Add('SPGD');
			Arr_Sigs.Add('STAT');
			Arr_Sigs.Add('TACT');
			Arr_Sigs.Add('TES4');
			Arr_Sigs.Add('TREE');
			Arr_Sigs.Add('TXST');
			Arr_Sigs.Add('VOLI');
			Arr_Sigs.Add('VTYP');
			Arr_Sigs.Add('WATR');
			Arr_Sigs.Add('WEAP');
			Arr_Sigs.Add('WOOP');
			Arr_Sigs.Add('WRLD');
			Arr_Sigs.Add('WTHR');
 
	end;
 
end.