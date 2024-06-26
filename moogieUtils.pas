unit moogieUtils;

uses praUtil;




  function GetFilteredFileName(e: IInterface; removeExt: boolean): string;
    var
      s: string;
    begin
      s := StringReplace(StringReplace(StringReplace(GetFileName(e), '[', '', [rfReplaceAll]), ']', ' -', [rfReplaceAll]), '_', ' ', [rfReplaceAll]);

      if removeExt then begin
        Result := Copy(s, 1, Length(s) - 4)
      end else begin
        Result := s
      end;
  end;

  function GetRawFileName(e: IInterface; removeExt: boolean): string;
    var
      s: string;
    begin
      if removeExt then begin
        Result := Copy(GetFileName(e), 1, Length(GetFileName(e)) - 4)
      end else begin
        Result := GetFileName(e)
      end;
  end;
  
  function CreateEditorIdFromString(str: string; prefix: string): string;
    begin
      Result := prefix + '-' + StringReplace(StringReplace(StringReplace(str, '[', '', [rfReplaceAll]), ']', '-', [rfReplaceAll]), ' ', '-', [rfReplaceAll]);
  end;

  function CreateNewRecordInFile(e: IwbFile; signature: string): IInterface;
    var
      recGroup: IInterface;
    begin
      if not HasGroup(e, signature) then begin  // Add 'begin' here
        recGroup := Add(e, signature, true); 
      end else begin                            // Add 'begin' and 'end' for the else block
        recGroup := GroupBySignature(e, signature);
      end;  
    Result := Add(recGroup, signature, true); // Does this belong inside the if-else?
  end;

  procedure CreateAndSetStructMember(struct: IInterface; memberName: string; memberType: string; value: variant);
  var
      curMember: IInterface;
  begin
    curMember := createRawStructMember(struct, memberName);
		SetElementEditValues(curMember, 'Type', memberType);
		setPropertyValue(curMember, value);
  end;


  function IsBethesdaFile(e: IInterface): Boolean;
    var
      bethesdaFilesString: string;
    begin
      bethesdaFilesString := 'Fallout4.esm,DLCRobot.esm,DLCworkshop01.esm,DLCCoast.esm,DLCworkshop02.esm,DLCworkshop03.esm,DLCNukaWorld.esm,ccBGSFO4001-PipBoy(Black).esl,ccBGSFO4002-PipBoy(Blue).esl,ccBGSFO4003-PipBoy(Camo01).esl,ccBGSFO4004-PipBoy(Camo02).esl,ccBGSFO4006-PipBoy(Chrome).esl,ccBGSFO4012-PipBoy(Red).esl,ccBGSFO4014-PipBoy(White).esl,ccBGSFO4005-BlueCamo.esl,ccBGSFO4016-Prey.esl,ccBGSFO4018-GaussRiflePrototype.esl,ccBGSFO4019-ChineseStealthArmor.esl,ccBGSFO4020-PowerArmorSkin(Black).esl,ccBGSFO4022-PowerArmorSkin(Camo01).esl,ccBGSFO4023-PowerArmorSkin(Camo02).esl,ccBGSFO4025-PowerArmorSkin(Chrome).esl,ccBGSFO4033-PowerArmorSkinWhite.esl,ccBGSFO4024-PACamo03.esl,ccBGSFO4038-HorseArmor.esl,ccBGSFO4041-DoomMarineArmor.esl,ccBGSFO4042-BFG.esl,ccBGSFO4044-HellfirePowerArmor.esl,ccFSVFO4001-ModularMilitaryBackpack.esl,ccFSVFO4002-MidCenturyModern.esl,ccFRSFO4001-HandmadeShotgun.esl,ccEEJFO4001-DecorationPack.esl,ccRZRFO4001-TunnelSnakes.esm,ccBGSFO4045-AdvArcCab.esl,ccFSVFO4003-Slocum.esl,ccGCAFO4001-FactionWS01Army.esl,ccGCAFO4002-FactionWS02ACat.esl,ccGCAFO4003-FactionWS03BOS.esl,ccGCAFO4004-FactionWS04Gun.esl,ccGCAFO4005-FactionWS05HRPink.esl,ccGCAFO4006-FactionWS06HRShark.esl,ccGCAFO4007-FactionWS07HRFlames.esl,ccGCAFO4008-FactionWS08Inst.esl,ccGCAFO4009-FactionWS09MM.esl,ccGCAFO4010-FactionWS10RR.esl,ccGCAFO4011-FactionWS11VT.esl,ccGCAFO4012-FactionAS01ACat.esl,ccGCAFO4013-FactionAS02BoS.esl,ccGCAFO4014-FactionAS03Gun.esl,ccGCAFO4015-FactionAS04HRPink.esl,ccGCAFO4016-FactionAS05HRShark.esl,ccGCAFO4017-FactionAS06Inst.esl,ccGCAFO4018-FactionAS07MM.esl,ccGCAFO4019-FactionAS08Nuk.esl,ccGCAFO4020-FactionAS09RR.esl,ccGCAFO4021-FactionAS10HRFlames.esl,ccGCAFO4022-FactionAS11VT.esl,ccGCAFO4023-FactionAS12Army.esl,ccAWNFO4001-BrandedAttire.esl,ccSWKFO4001-AstronautPowerArmor.esm,ccSWKFO4002-PipNuka.esl,ccSWKFO4003-PipQuan.esl,ccBGSFO4050-DgBColl.esl,ccBGSFO4051-DgBox.esl,ccBGSFO4052-DgDal.esl,ccBGSFO4053-DgGoldR.esl,ccBGSFO4054-DgGreatD.esl,ccBGSFO4055-DgHusk.esl,ccBGSFO4056-DgLabB.esl,ccBGSFO4057-DgLabY.esl,ccBGSFO4058-DGLabC.esl,ccBGSFO4059-DgPit.esl,ccBGSFO4060-DgRot.esl,ccBGSFO4061-DgShiInu.esl,ccBGSFO4036-TrnsDg.esl,ccRZRFO4004-PipInst.esl,ccBGSFO4062-PipPat.esl,ccRZRFO4003-PipOver.esl,ccFRSFO4002-AntimaterielRifle.esl,ccEEJFO4002-Nuka.esl,ccYGPFO4001-PipCruiser.esl,ccBGSFO4072-PipGrog.esl,ccBGSFO4073-PipMMan.esl,ccBGSFO4074-PipInspect.esl,ccBGSFO4075-PipShroud.esl,ccBGSFO4076-PipMystery.esl,ccBGSFO4071-PipArc.esl,ccBGSFO4079-PipVim.esl,ccBGSFO4078-PipReily.esl,ccBGSFO4077-PipRocket.esl,ccBGSFO4070-PipAbra.esl,ccBGSFO4008-PipGrn.esl,ccBGSFO4015-PipYell.esl,ccBGSFO4009-PipOran.esl,ccBGSFO4011-PipPurp.esl,ccBGSFO4021-PowerArmorSkinBlue.esl,ccBGSFO4027-PowerArmorSkinGreen.esl,ccBGSFO4034-PowerArmorSkinYellow.esl,ccBGSFO4028-PowerArmorSkinOrange.esl,ccBGSFO4031-PowerArmorSkinRed.esl,ccBGSFO4030-PowerArmorSkinPurple.esl,ccBGSFO4032-PowerArmorSkinTan.esl,ccBGSFO4029-PowerArmorSkinPink.esl,ccGRCFO4001-PipGreyTort.esl,ccGRCFO4002-PipGreenVim.esl,ccBGSFO4013-PipTan.esl,ccBGSFO4010-PipPnk.esl,ccSBJFO4001-SolarFlare.esl,ccZSEF04001-BHouse.esm,ccTOSFO4001-NeoSky.esm,ccKGJFO4001-bastion.esl,ccBGSFO4063-PAPat.esl,ccQDRFO4001_PowerArmorAI.esl,ccBGSFO4048-Dovah.esl,ccBGSFO4101-AS_Shi.esl,ccBGSFO4114-WS_Shi.esl,ccBGSFO4115-X02.esl,ccRZRFO4002-Disintegrate.esl,ccBGSFO4116-HeavyFlamer.esl,ccBGSFO4091-AS_Bats.esl,ccBGSFO4092-AS_CamoBlue.esl,ccBGSFO4093-AS_CamoGreen.esl,ccBGSFO4094-AS_CamoTan.esl,ccBGSFO4097-AS_Jack-oLantern.esl,ccBGSFO4104-WS_Bats.esl,ccBGSFO4105-WS_CamoBlue.esl,ccBGSFO4106-WS_CamoGreen.esl,ccBGSFO4107-WS_CamoTan.esl,ccBGSFO4111-WS_Jack-oLantern.esl,ccBGSFO4118-WS_TunnelSnakes.esl,ccBGSFO4113-WS_ReillysRangers.esl,ccBGSFO4112-WS_Pickman.esl,ccBGSFO4110-WS_Enclave.esl,ccBGSFO4108-WS_ChildrenOfAtom.esl,ccBGSFO4103-AS_TunnelSnakes.esl,ccBGSFO4099-AS_ReillysRangers.esl,ccBGSFO4098-AS_Pickman.esl,ccBGSFO4096-AS_Enclave.esl,ccBGSFO4095-AS_ChildrenOfAtom.esl,ccBGSFO4090-PipTribal.esl,ccBGSFO4089-PipSynthwave.esl,ccBGSFO4087-PipHaida.esl,ccBGSFO4085-PipHawaii.esl,ccBGSFO4084-PipRetro.esl,ccBGSFO4083-PipArtDeco.esl,ccBGSFO4082-PipPRC.esl,ccBGSFO4081-PipPhenolResin.esl,ccBGSFO4080-PipPop.esl,ccBGSFO4035-Pint.esl,ccBGSFO4086-PipAdventure.esl,ccJVDFO4001-Holiday.esl,ccBGSFO4047-QThund.esl,ccFRSFO4003-CR75L.esl,ccZSEFO4002-SManor.esm,ccACXFO4001-VSuit.esl,ccBGSFO4040-VRWorkshop01.esl,ccFSVFO4005-VRDesertIsland.esl,ccFSVFO4006-VRWasteland.esl,ccSBJFO4002_ManwellRifle.esl,ccTOSFO4002_NeonFlats.esm,ccBGSFO4117-CapMerc.esl,ccFSVFO4004-VRWorkshopGNRPlaza.esl,ccBGSFO4046-TesCan.esl,ccGCAFO4025-PAGunMM.esl,ccCRSFO4001-PipCoA.esl';

      Result := Pos(LowerCase(GetFileName(e)), LowerCase(bethesdaFilesString)) > 0;
  end;

  function IsBethesdaFile(e: IInterface): Boolean;
    var
      bethesdaFilesString: string;
    begin
      bethesdaFilesString := 'Fallout4.esm,DLCRobot.esm,DLCworkshop01.esm,DLCCoast.esm,DLCworkshop02.esm,DLCworkshop03.esm,DLCNukaWorld.esm,ccBGSFO4001-PipBoy(Black).esl,ccBGSFO4002-PipBoy(Blue).esl,ccBGSFO4003-PipBoy(Camo01).esl,ccBGSFO4004-PipBoy(Camo02).esl,ccBGSFO4006-PipBoy(Chrome).esl,ccBGSFO4012-PipBoy(Red).esl,ccBGSFO4014-PipBoy(White).esl,ccBGSFO4005-BlueCamo.esl,ccBGSFO4016-Prey.esl,ccBGSFO4018-GaussRiflePrototype.esl,ccBGSFO4019-ChineseStealthArmor.esl,ccBGSFO4020-PowerArmorSkin(Black).esl,ccBGSFO4022-PowerArmorSkin(Camo01).esl,ccBGSFO4023-PowerArmorSkin(Camo02).esl,ccBGSFO4025-PowerArmorSkin(Chrome).esl,ccBGSFO4033-PowerArmorSkinWhite.esl,ccBGSFO4024-PACamo03.esl,ccBGSFO4038-HorseArmor.esl,ccBGSFO4041-DoomMarineArmor.esl,ccBGSFO4042-BFG.esl,ccBGSFO4044-HellfirePowerArmor.esl,ccFSVFO4001-ModularMilitaryBackpack.esl,ccFSVFO4002-MidCenturyModern.esl,ccFRSFO4001-HandmadeShotgun.esl,ccEEJFO4001-DecorationPack.esl,ccRZRFO4001-TunnelSnakes.esm,ccBGSFO4045-AdvArcCab.esl,ccFSVFO4003-Slocum.esl,ccGCAFO4001-FactionWS01Army.esl,ccGCAFO4002-FactionWS02ACat.esl,ccGCAFO4003-FactionWS03BOS.esl,ccGCAFO4004-FactionWS04Gun.esl,ccGCAFO4005-FactionWS05HRPink.esl,ccGCAFO4006-FactionWS06HRShark.esl,ccGCAFO4007-FactionWS07HRFlames.esl,ccGCAFO4008-FactionWS08Inst.esl,ccGCAFO4009-FactionWS09MM.esl,ccGCAFO4010-FactionWS10RR.esl,ccGCAFO4011-FactionWS11VT.esl,ccGCAFO4012-FactionAS01ACat.esl,ccGCAFO4013-FactionAS02BoS.esl,ccGCAFO4014-FactionAS03Gun.esl,ccGCAFO4015-FactionAS04HRPink.esl,ccGCAFO4016-FactionAS05HRShark.esl,ccGCAFO4017-FactionAS06Inst.esl,ccGCAFO4018-FactionAS07MM.esl,ccGCAFO4019-FactionAS08Nuk.esl,ccGCAFO4020-FactionAS09RR.esl,ccGCAFO4021-FactionAS10HRFlames.esl,ccGCAFO4022-FactionAS11VT.esl,ccGCAFO4023-FactionAS12Army.esl,ccAWNFO4001-BrandedAttire.esl,ccSWKFO4001-AstronautPowerArmor.esm,ccSWKFO4002-PipNuka.esl,ccSWKFO4003-PipQuan.esl,ccBGSFO4050-DgBColl.esl,ccBGSFO4051-DgBox.esl,ccBGSFO4052-DgDal.esl,ccBGSFO4053-DgGoldR.esl,ccBGSFO4054-DgGreatD.esl,ccBGSFO4055-DgHusk.esl,ccBGSFO4056-DgLabB.esl,ccBGSFO4057-DgLabY.esl,ccBGSFO4058-DGLabC.esl,ccBGSFO4059-DgPit.esl,ccBGSFO4060-DgRot.esl,ccBGSFO4061-DgShiInu.esl,ccBGSFO4036-TrnsDg.esl,ccRZRFO4004-PipInst.esl,ccBGSFO4062-PipPat.esl,ccRZRFO4003-PipOver.esl,ccFRSFO4002-AntimaterielRifle.esl,ccEEJFO4002-Nuka.esl,ccYGPFO4001-PipCruiser.esl,ccBGSFO4072-PipGrog.esl,ccBGSFO4073-PipMMan.esl,ccBGSFO4074-PipInspect.esl,ccBGSFO4075-PipShroud.esl,ccBGSFO4076-PipMystery.esl,ccBGSFO4071-PipArc.esl,ccBGSFO4079-PipVim.esl,ccBGSFO4078-PipReily.esl,ccBGSFO4077-PipRocket.esl,ccBGSFO4070-PipAbra.esl,ccBGSFO4008-PipGrn.esl,ccBGSFO4015-PipYell.esl,ccBGSFO4009-PipOran.esl,ccBGSFO4011-PipPurp.esl,ccBGSFO4021-PowerArmorSkinBlue.esl,ccBGSFO4027-PowerArmorSkinGreen.esl,ccBGSFO4034-PowerArmorSkinYellow.esl,ccBGSFO4028-PowerArmorSkinOrange.esl,ccBGSFO4031-PowerArmorSkinRed.esl,ccBGSFO4030-PowerArmorSkinPurple.esl,ccBGSFO4032-PowerArmorSkinTan.esl,ccBGSFO4029-PowerArmorSkinPink.esl,ccGRCFO4001-PipGreyTort.esl,ccGRCFO4002-PipGreenVim.esl,ccBGSFO4013-PipTan.esl,ccBGSFO4010-PipPnk.esl,ccSBJFO4001-SolarFlare.esl,ccZSEF04001-BHouse.esm,ccTOSFO4001-NeoSky.esm,ccKGJFO4001-bastion.esl,ccBGSFO4063-PAPat.esl,ccQDRFO4001_PowerArmorAI.esl,ccBGSFO4048-Dovah.esl,ccBGSFO4101-AS_Shi.esl,ccBGSFO4114-WS_Shi.esl,ccBGSFO4115-X02.esl,ccRZRFO4002-Disintegrate.esl,ccBGSFO4116-HeavyFlamer.esl,ccBGSFO4091-AS_Bats.esl,ccBGSFO4092-AS_CamoBlue.esl,ccBGSFO4093-AS_CamoGreen.esl,ccBGSFO4094-AS_CamoTan.esl,ccBGSFO4097-AS_Jack-oLantern.esl,ccBGSFO4104-WS_Bats.esl,ccBGSFO4105-WS_CamoBlue.esl,ccBGSFO4106-WS_CamoGreen.esl,ccBGSFO4107-WS_CamoTan.esl,ccBGSFO4111-WS_Jack-oLantern.esl,ccBGSFO4118-WS_TunnelSnakes.esl,ccBGSFO4113-WS_ReillysRangers.esl,ccBGSFO4112-WS_Pickman.esl,ccBGSFO4110-WS_Enclave.esl,ccBGSFO4108-WS_ChildrenOfAtom.esl,ccBGSFO4103-AS_TunnelSnakes.esl,ccBGSFO4099-AS_ReillysRangers.esl,ccBGSFO4098-AS_Pickman.esl,ccBGSFO4096-AS_Enclave.esl,ccBGSFO4095-AS_ChildrenOfAtom.esl,ccBGSFO4090-PipTribal.esl,ccBGSFO4089-PipSynthwave.esl,ccBGSFO4087-PipHaida.esl,ccBGSFO4085-PipHawaii.esl,ccBGSFO4084-PipRetro.esl,ccBGSFO4083-PipArtDeco.esl,ccBGSFO4082-PipPRC.esl,ccBGSFO4081-PipPhenolResin.esl,ccBGSFO4080-PipPop.esl,ccBGSFO4035-Pint.esl,ccBGSFO4086-PipAdventure.esl,ccJVDFO4001-Holiday.esl,ccBGSFO4047-QThund.esl,ccFRSFO4003-CR75L.esl,ccZSEFO4002-SManor.esm,ccACXFO4001-VSuit.esl,ccBGSFO4040-VRWorkshop01.esl,ccFSVFO4005-VRDesertIsland.esl,ccFSVFO4006-VRWasteland.esl,ccSBJFO4002_ManwellRifle.esl,ccTOSFO4002_NeonFlats.esm,ccBGSFO4117-CapMerc.esl,ccFSVFO4004-VRWorkshopGNRPlaza.esl,ccBGSFO4046-TesCan.esl,ccGCAFO4025-PAGunMM.esl,ccCRSFO4001-PipCoA.esl';

      Result := Pos(LowerCase(GetFileName(e)), LowerCase(bethesdaFilesString)) > 0;
  end;

  function CreateRecipeKeywordWithInputName(e: IwbFile): IInterface;
    var
      craftingRecipeKeyword: IInterface;
      craftingRecipeName: string;
      canContinue: boolean;
    begin
      canContinue := InputQuery('Give a name for new Recipe Group', 'Name:', craftingRecipeName);
      if not canContinue then begin
        AddMessage('User cancelled script');
        Exit;
      end;

      craftingRecipeKeyword := CreateNewRecordInFile(e, 'KYWD');
      SetElementEditValues(craftingRecipeKeyword, 'FULL', craftingRecipeName);
      SetElementEditValues(craftingRecipeKeyword, 'TNAM', 'Recipe Filter');
      SetElementEditValues(craftingRecipeKeyword, 'EDID', CreateEditorIdFromString(craftingRecipeName, 'moo-key'));
      Add(craftingRecipeKeyword, 'CNAM', True);
      SetElementEditValues(craftingRecipeKeyword, 'CNAM\Red', '255');
      SetElementEditValues(craftingRecipeKeyword, 'CNAM\Green', '255');
      SetElementEditValues(craftingRecipeKeyword, 'CNAM\Blue', '255');
    
      Result := craftingRecipeKeyword;
    end;



end.