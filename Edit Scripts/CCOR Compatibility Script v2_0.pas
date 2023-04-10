{											
CCOR Compatibility Script											
Created by matortheeternal											
Edited and maintained by kryptopyr and danielleonyett											
											
* DESCRIPTION *											
Applies CCOR global variable conditions to COBJ recipes in the selected mods.	

CHANGES
Updated CCO_Jewelry[xx] globals (Bracelet, Ring, Circlet, Earring, Necklace, Other).
Changed "Exotic" globals to "Style".										
}											
											
unit UserScript;											
											
uses mteFunctions;											
											
const	vs = 'v2.0';										
	ccofn = 'Complete Crafting Overhaul_Remastered.esp';										
	ccorfn = 'CCOResource.esp';										
	separatepatch = true; // set to true to generate a separate patch file										
											
VAR	slFiles, slGlobals, slMasters: TStringList;										
	patchedfiles: integer;										
//=========================================================================											
// get all values											
function gav(e: IInterface): string;											
											
VAR	i: integer;										
											
BEGIN	Result := GetEditValue(e);										
	FOR	i := 0									
	TO	ElementCount(e) - 1									
	DO	IF	(Result <> '')								
		THEN	Result := Result + ';' + gav(ElementByIndex(e, i))								
		ELSE	Result := gav(ElementByIndex(e, i))								
	{;}	;									
END											
;											
//=========================================================================											
// has keyword											
function HasKeyword(rec: IInterface; kw: string): boolean;											
											
VAR	kwda: IInterface;										
	n: integer;										
											
BEGIN	Result := false;										
	kwda := ElementByPath(rec, 'KWDA');										
	FOR	n := 0									
	TO	ElementCount(kwda) - 1									
	DO	IF	GetElementEditValues(LinksTo(ElementByIndex(kwda, n)), 'EDID') = kw								
		THEN	Result := true								
		{ELSE}									
	{;}	;									
END											
;											
//=========================================================================											
// not has (condition)											
function NotHas(rec: IInterface; cn: string): boolean;											
											
VAR	conditions: IInterface;										
	n: integer;										
	cnstring: string;										
											
BEGIN	Result := true;										
	conditions := ElementByPath(rec, 'Conditions');										
	FOR	n := 0									
	TO	ElementCount(conditions) - 1									
	DO	BEGIN	cnstring := gav(ElementByIndex(conditions, n));								
			IF	Pos(Lowercase(cn),Lowercase(cnstring)) > 0							
			THEN	Result := false							
			{ELSE}								
			;								
		END									
	;										
END											
;											
//=========================================================================											
// has substring in EDID											
function HasSubstringInEDID(rec: IInterface; ss: string): boolean;											
											
BEGIN	Result := false;										
	IF	Pos(Lowercase(ss), Lowercase(geev(rec, 'EDID'))) > 0									
	THEN	Result := true									
	{ELSE}										
	;										
END											
;											
//=========================================================================											
// has substring in FULL											
function HasSubstringInFULL(rec: IInterface; ss: string): boolean;											
											
BEGIN	Result := false;										
	IF	Pos(Lowercase(ss), Lowercase(geev(rec, 'FULL'))) > 0									
	THEN	Result := true									
	{ELSE}										
	;										
END											
;											
//=========================================================================											
// add daedric at night condition											
procedure adanc(c: IInterface);											
											
VAR	condition: IInterface;										
	index: integer;										
											
BEGIN	// first condition										
	index := slGlobals.IndexOf('CCO_OptionCraftDaedricOnlyAtNight');										
	IF	index = -1									
	THEN	BEGIN	AddMessage('Couldn''t find CCO_OptionCraftDaedricOnlyAtNight');								
			exit;								
		END									
	{ELSE}										
	;										
	condition := ElementAssign(c, HighInteger, nil, False);										
	SetElementEditValues(condition, 'CTDA - CTDA\Type', '10010000'); // Equal to / Or										
	SetElementEditValues(condition, 'CTDA - CTDA\Comparison Value', '0.0');										
	SetElementEditValues(condition, 'CTDA - CTDA\Function', 'GetGlobalValue');										
	SetElementNativeValues(condition, 'CTDA - CTDA\Global', slGlobals.Objects[index]);										
	// second condition										
	condition := ElementAssign(c, HighInteger, nil, False);										
	SetElementEditValues(condition, 'CTDA - CTDA\Type', '10110000'); // Less than or equal to / Or										
	SetElementEditValues(condition, 'CTDA - CTDA\Comparison Value', '6.0');										
	SetElementEditValues(condition, 'CTDA - CTDA\Function', 'GetCurrentTime');										
	// third condition										
	condition := ElementAssign(c, HighInteger, nil, False);										
	SetElementEditValues(condition, 'CTDA - CTDA\Type', '11010000'); // Greater than or equal to / Or										
	SetElementEditValues(condition, 'CTDA - CTDA\Comparison Value', '21.0');										
	SetElementEditValues(condition, 'CTDA - CTDA\Function', 'GetCurrentTime');										
END											
;											
//=========================================================================											
// add learning global value condition											
procedure algvc(c: IInterface; gv: string);											
											
VAR	condition: IInterface;										
	index1, index2: integer;										
											
BEGIN	// first condition										
	index1 := slGlobals.IndexOf('CCO_LearningEnabled');										
	IF	index1 = -1									
	THEN	BEGIN	AddMessage('Couldn''t find CCO_LearningEnabled');								
			exit;								
		END									
	{ELSE}										
	;										
	condition := ElementAssign(c, HighInteger, nil, False);										
	SetElementEditValues(condition, 'CTDA - CTDA\Type', '10010000'); // Equal to / Or										
	SetElementEditValues(condition, 'CTDA - CTDA\Comparison Value', '0.0');										
	SetElementEditValues(condition, 'CTDA - CTDA\Function', 'GetGlobalValue');										
	SetElementNativeValues(condition, 'CTDA - CTDA\Global', slGlobals.Objects[index1]);										
	// second condition										
	index1 := slGlobals.IndexOf('CCO_LearningRequiredtoSmith');										
	IF	index1 = -1									
	THEN	BEGIN	AddMessage('Couldn''t find CCO_LearningRequiredtoSmith');								
			exit;								
		END									
	{ELSE}										
	;										
	index2 := slGlobals.IndexOf(gv);										
	IF	index2 = -1									
	THEN	BEGIN	AddMessage('Couldn''t find '+gv);								
			exit;								
		END									
	{ELSE}										
	;										
	condition := ElementAssign(c, HighInteger, nil, False);										
	SetElementEditValues(condition, 'CTDA - CTDA\Type', '11000100'); // Greater than or equal to / Use global										
	SetElementNativeValues(condition, 'CTDA - CTDA\Comparison Value', slGlobals.Objects[index1]);										
	SetElementEditValues(condition, 'CTDA - CTDA\Function', 'GetGlobalValue');										
	SetElementNativeValues(condition, 'CTDA - CTDA\Global', slGlobals.Objects[index2]);										
END											
;											
//=========================================================================											
// add global value condition											
procedure agvc(c: IInterface; gv: string);											
											
VAR	condition: IInterface;										
	index: integer;										
											
BEGIN	index := slGlobals.IndexOf(gv);										
	IF	index = -1									
	THEN	BEGIN	AddMessage('Could not find '+gv);								
			exit;								
		END									
	{ELSE}										
	;										
	condition := ElementAssign(c, HighInteger, nil, False);										
	SetElementEditValues(condition, 'CTDA - CTDA\Type', '10000000'); // equal to										
	SetElementEditValues(condition, 'CTDA - CTDA\Comparison Value', '1.0');										
	SetElementEditValues(condition, 'CTDA - CTDA\Function', 'GetGlobalValue');										
	SetElementNativeValues(condition, 'CTDA - CTDA\Global', slGlobals.Objects[index]);										
	WHILE	CanMoveUp(condition)									
	DO	MoveUp(condition)									
	;										
END											
;											
//=========================================================================											
// CCO mod supported condition											
procedure cmcs(c: IInterface);											
											
VAR	condition: IInterface;										
	index: integer;										
											
BEGIN	index := slGlobals.IndexOf('CCO_MODSupported');										
	IF	index = -1									
	THEN	BEGIN	AddMessage('Could not find CCO_MODSupported');								
			exit;								
		END									
	{ELSE}										
	;										
	condition := ElementAssign(c, HighInteger, nil, False);										
	SetElementEditValues(condition, 'CTDA - CTDA\Type', '10000000'); // equal to										
	SetElementEditValues(condition, 'CTDA - CTDA\Comparison Value', '1.0');										
	SetElementEditValues(condition, 'CTDA - CTDA\Function', 'GetGlobalValue');										
	SetElementNativeValues(condition, 'CTDA - CTDA\Global', slGlobals.Objects[index]);										
	WHILE	CanMoveUp(condition)									
	DO	MoveUp(condition)									
	;										
END											
;	
//=========================================================================											
// Exclusive to Skyforge condition											
procedure exclsky(c: IInterface);											
											
VAR	condition: IInterface;										
	index: integer;										
											
BEGIN	index := slGlobals.IndexOf('CCO_CategoryForgeMaterialOR_Skyforge');										
	IF	index = -1									
	THEN	BEGIN	AddMessage('Could not find CCO_CategoryForgeMaterialOR_Skyforge');								
			exit;								
		END									
	{ELSE}										
	;										
	condition := ElementAssign(c, HighInteger, nil, False);										
	SetElementEditValues(condition, 'CTDA - CTDA\Type', '10010000'); // Equal to / Or										
	SetElementEditValues(condition, 'CTDA - CTDA\Comparison Value', '1.0');										
	SetElementEditValues(condition, 'CTDA - CTDA\Function', 'GetGlobalValue');										
	SetElementNativeValues(condition, 'CTDA - CTDA\Global', slGlobals.Objects[index]);										
	WHILE	CanMoveUp(condition)									
	DO	MoveUp(condition)									
	;										
END											
;		
//=========================================================================											
// Smithing Requirements for Silver jewelry condition											
procedure reqsilver(c: IInterface);											
											
VAR	condition: IInterface;										
	index: integer;										
											
BEGIN	index := slGlobals.IndexOf('CCO_SmithingReqSilver');										
	IF	index = -1									
	THEN	BEGIN	AddMessage('Could not find CCO_SmithingReqSilver');								
			exit;								
		END									
	{ELSE}										
	;										
	condition := ElementAssign(c, HighInteger, nil, False);										
	SetElementEditValues(condition, 'CTDA - CTDA\Type', '11000100'); // Greater than or Equal to / Use Global										
	SetElementEditValues(condition, 'CTDA - CTDA\Comparison Value', 'CCO_SmithingReqSilver');										
	SetElementEditValues(condition, 'CTDA - CTDA\Function', 'GetActorValue');	
	SetElementEditValues(condition, 'CTDA - CTDA\Actor Value', 'Smithing');										
	WHILE	CanMoveUp(condition)									
	DO	MoveUp(condition)									
	;										
END											
;	
//=========================================================================											
// Smithing Requirements for Gold jewelry condition											
procedure reqgold(c: IInterface);											
											
VAR	condition: IInterface;										
	index: integer;										
											
BEGIN	index := slGlobals.IndexOf('CCO_SmithingReqGold');										
	IF	index = -1									
	THEN	BEGIN	AddMessage('Could not find CCO_SmithingReqGold');								
			exit;								
		END									
	{ELSE}										
	;										
	condition := ElementAssign(c, HighInteger, nil, False);										
	SetElementEditValues(condition, 'CTDA - CTDA\Type', '11000100'); // Greater than or Equal to / Use Global										
	SetElementEditValues(condition, 'CTDA - CTDA\Comparison Value', 'CCO_SmithingReqGold');										
	SetElementEditValues(condition, 'CTDA - CTDA\Function', 'GetActorValue');	
	SetElementEditValues(condition, 'CTDA - CTDA\Actor Value', 'Smithing');										
	WHILE	CanMoveUp(condition)									
	DO	MoveUp(condition)									
	;										
END											
;									
//=========================================================================											
// smithing forge conditions 											
procedure SmithingForgeConditions(cnam: IInterface; conditions: IInterface; e: IInterface; bnam: IInterface);											
											
VAR	jewelry: boolean;										
											
BEGIN	jewelry := false;										
											
	IF	(Signature(cnam) = 'AMMO')			
	THEN	IF	HasSubstringInEDID(cnam, 'arrow')
		THEN	BEGIN	IF	NotHas(e, 'CCO_WeapAmmoArrowRecipes')											
			THEN	agvc(conditions, 'CCO_WeapAmmoArrowRecipes')		
			END		
	ELSE	IF	HasSubstringInEDID(cnam, 'bolt')
		THEN	BEGIN	IF	NotHas(e, 'CCO_WeapAmmoBoltRecipes')											
			THEN	agvc(conditions, 'CCO_WeapAmmoBoltRecipes')		
			END		
	ELSE	IF	NotHas(e, 'CCO_WeapAmmoOtherRecipes')								
		THEN	agvc(conditions, 'CCO_WeapAmmoOtherRecipes')		
		{ELSE}
	{ELSE}										
	;										
											
	IF	(Signature(cnam) = 'ARMO')									
	THEN	IF	HasKeyword(cnam, 'ArmorJewelry')		
		OR	HasKeyword(cnam, 'ClothingCirclet')	
		OR	HasKeyword(cnam, 'ClothingNecklace')								
		OR	HasKeyword(cnam, 'ClothingRing')		
		OR	HasKeyword(cnam, 'JewelryExpensive')		
		THEN	jewelry := true								
		{ELSE}									
	{ELSE}										
	;										

	IF	(Signature(cnam) = 'ARMO')									
	AND	NOT	jewelry		
	AND	NotHas(e, 'CCO_OptionCraftingMenuOptions')	
	THEN	IF	(	(GetElementEditValues(cnam, 'BODT\Armor Type') = 'Clothing')							
			OR	(GetElementEditValues(cnam, 'BOD2\Armor Type') = 'Clothing')							
			OR	HasKeyword(cnam, 'ArmorClothing')							
			)						
		THEN	BEGIN	IF	NotHas(e, 'CCO_ArmorClothingRecipes')											
			THEN	agvc(conditions, 'CCO_ArmorClothingRecipes')		
			END	
	ELSE	IF	(	(GetElementEditValues(cnam, 'BODT\Armor Type') = 'Heavy Armor')						
				OR	(GetElementEditValues(cnam, 'BOD2\Armor Type') = 'Heavy Armor')						
				OR	HasKeyword(cnam, 'ArmorHeavy')						
				)							
		THEN	BEGIN	IF	NotHas(e, 'CCO_ArmorHeavyRecipes')							
			THEN	agvc(conditions, 'CCO_ArmorHeavyRecipes')		
			END	
	ELSE	IF	(	(GetElementEditValues(cnam, 'BODT\Armor Type') = 'Light Armor')					
					OR	(GetElementEditValues(cnam, 'BOD2\Armor Type') = 'Light Armor')					
					OR	HasKeyword(cnam, 'ArmorLight')					
					)			
		THEN	BEGIN	IF	NotHas(e, 'CCO_ArmorLightRecipes')										
			THEN	agvc(conditions, 'CCO_ArmorLightRecipes')	
			END							
			{ELSE}							
	{ELSE}										
	;	

	IF	(Signature(cnam) = 'ARMO')									
	AND	jewelry									
	THEN	IF	(	HasKeyword(cnam, 'WAF_ClothingCloak')
			OR	HasSubstringInEDID(cnam, 'cloak')							
			OR	HasSubstringInFULL(cnam, 'cloak')		
			OR	HasSubstringInFULL(cnam, 'cape')			
			)	
		AND	NOT	HasSubstringInFULL(cnam, 'Stormcloak')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_ClothingCloakRecipes')			
			THEN	agvc(conditions, 'CCO_ClothingCloakRecipes')	
			END					
	ELSE	IF	HasSubstringInFULL(cnam, 'Bracelet')	
		OR	HasSubstringInFULL(cnam, 'Bangle')
		THEN	BEGIN	IF	NotHas(e, 'CCO_JewelryBraceletRecipes')							
			THEN	agvc(conditions, 'CCO_JewelryBraceletRecipes')		
			END						
	ELSE	IF	HasSubstringInFULL(cnam, 'Earring')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_JewelryEarringRecipes')							
			THEN	agvc(conditions, 'CCO_JewelryEarringRecipes')		
			END						
	ELSE	IF	HasKeyword(cnam, 'ClothingCirclet')	
		THEN	BEGIN	IF	NotHas(e, 'CCO_JewelryCircletRecipes')							
			THEN	agvc(conditions, 'CCO_JewelryCircletRecipes')		
			END	
	ELSE	IF	(	HasKeyword(cnam, 'ClothingNecklace')	
		OR	HasSubstringInFULL(cnam, 'Necklace')	
		OR	HasSubstringInFULL(cnam, 'Amulet')
		OR	HasSubstringInFULL(cnam, 'Choker')
		OR	HasSubstringInFULL(cnam, 'Torc')
		)
		THEN	BEGIN	IF	NotHas(e, 'CCO_JewelryNecklaceRecipes')				
			THEN	agvc(conditions, 'CCO_JewelryNecklaceRecipes')		
			END	
	ELSE	IF	HasKeyword(cnam, 'ClothingRing')	
		THEN	BEGIN	IF	NotHas(e, 'CCO_JewelryRingRecipes')						
			THEN	agvc(conditions, 'CCO_JewelryRingRecipes')	
			END		
	ELSE	IF	NotHas(e, 'CCO_JewelryOtherRecipes')								
		THEN	agvc(conditions, 'CCO_JewelryOtherRecipes')					
			{ELSE}						
	{ELSE}										
	;	
	
	IF	(Signature(cnam) = 'ARMO')									
	AND	NOT	jewelry	
	AND	NOT	HasSubstringInEDID(cnam, 'MenuOption')	
	AND	(	(GetElementEditValues(cnam, 'BODT\Armor Type') = 'Clothing')								
		OR	(GetElementEditValues(cnam, 'BOD2\Armor Type') = 'Clothing')															
		)									
	THEN	IF	(	HasKeyword(cnam, 'WAF_ClothingCloak')			
			OR	HasSubstringInEDID(cnam, 'cloak')			
			OR	HasSubstringInFULL(cnam, 'cloak')		
			OR	HasSubstringInFULL(cnam, 'cape')				
			)		
		THEN	BEGIN	IF	NotHas(e, 'CCO_ClothingCloakRecipes')							
			THEN	agvc(conditions, 'CCO_ClothingCloakRecipes')		
			END
	ELSE	IF	HasKeyword(cnam, 'WAF_ClothingPouch')									
		OR	HasSubstringInFULL(cnam, 'Backpack')	
		OR	HasSubstringInFULL(cnam, 'Bandolier')	
		OR	HasSubstringInFULL(cnam, 'Bag')		
		OR	HasSubstringInFULL(cnam, 'Pouch')	
		OR	HasSubstringInFULL(cnam, 'Satchel')				
		THEN	BEGIN	IF	NotHas(e, 'CCO_ClothingPouchRecipes')							
			THEN	agvc(conditions, 'CCO_ClothingPouchRecipes')																						
			END												
	ELSE	IF	HasKeyword(cnam, 'WAF_ClothingAccessories')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_ClothingMiscAccessories')						
			THEN	agvc(conditions, 'CCO_ClothingMiscAccessories')	
			END
	ELSE	IF	HasKeyword(cnam, 'ClothingBody')			
		THEN	BEGIN	IF	NotHas(e, 'CCO_ClothingRobeRecipes')		
			THEN	agvc(conditions, 'CCO_ClothingRobeRecipes')			
			END	
	ELSE	IF	HasKeyword(cnam, 'ClothingFeet')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_ClothingBootRecipes')							
			THEN	agvc(conditions, 'CCO_ClothingBootRecipes')		
			END	
	ELSE	IF	HasKeyword(cnam, 'ClothingHands')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_ClothingGlovesRecipes')	
			THEN	agvc(conditions, 'CCO_ClothingGlovesRecipes')	
			END	
	ELSE	IF	HasKeyword(cnam, 'ClothingHead')	
		THEN	BEGIN	IF	NotHas(e, 'CCO_ClothingHoodRecipes')		
			THEN	agvc(conditions, 'CCO_ClothingHoodRecipes')		
			END
	ELSE	IF	NotHas(e, 'CCO_ClothingMiscAccessories')								
		THEN	agvc(conditions, 'CCO_ClothingMiscAccessories')		
			{ELSE}					
	{ELSE}										
	;										
	
	IF	(Signature(cnam) = 'ARMO')									
	AND	NOT	jewelry								
	AND	NOT	(GetElementEditValues(cnam, 'BODT\Armor Type') = 'Clothing')								
	AND	NOT	(GetElementEditValues(cnam, 'BOD2\Armor Type') = 'Clothing')																
	THEN	IF	HasKeyword(cnam, 'ArmorBoots')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_ArmorBootRecipes')										
			THEN	agvc(conditions, 'CCO_ArmorBootRecipes')		
			END	
	ELSE	IF	HasKeyword(cnam, 'ArmorCuirass')		
		AND	NOT	HasSubstringInEDID(cnam, 'MenuOption')
		THEN	BEGIN	IF	NotHas(e, 'CCO_ArmorCuirassRecipes')	
			THEN	agvc(conditions, 'CCO_ArmorCuirassRecipes')	
			END
	ELSE	IF	HasKeyword(cnam, 'ArmorGauntlets')			
		THEN	BEGIN	IF	NotHas(e, 'CCO_ArmorGauntletRecipes')		
			THEN	agvc(conditions, 'CCO_ArmorGauntletRecipes')	
			END
	ELSE	IF	HasKeyword(cnam, 'ArmorHelmet')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_ArmorHelmetRecipes')		
			THEN	agvc(conditions, 'CCO_ArmorHelmetRecipes')		
			END	
	ELSE	IF	HasKeyword(cnam, 'ArmorShield')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_ArmorShieldRecipes')		
			THEN	agvc(conditions, 'CCO_ArmorShieldRecipes')		
			END	
	ELSE	IF	NotHas(e, 'CCO_ClothingMiscAccessories')								
		THEN	agvc(conditions, 'CCO_ClothingMiscAccessories')					
			{ELSE}					
	{ELSE}										
	;										
	
	IF	Signature(cnam) = 'MISC'	
	THEN	IF	(	HasSubstringInEDID(cnam, 'Gem')
		OR	HasSubstringInEDID(cnam, 'Ingot')
		OR	HasSubstringInEDID(cnam, 'Ore')
		OR	HasSubstringInEDID(cnam, 'FurPlate')
		OR	HasSubstringInEDID(cnam, 'Hide')		
		OR	HasSubstringInEDID(cnam, 'Leather')			
		OR	HasKeyword(cnam, 'BYOHHouseCraftingCategorySmithing')	
		)
		THEN	BEGIN	IF	NotHas(e, 'CCO_MiscSuppliesRecipes')							
			THEN	agvc(conditions, 'CCO_MiscSuppliesRecipes')							
			END									
	ELSE	IF	(	HasKeyword(cnam, 'BYOHHouseCraftingCategoryContainers')
		OR	HasKeyword(cnam, 'BYOHHouseCraftingCategoryFurniture')
		OR	HasKeyword(cnam, 'BYOHHouseCraftingCategoryShelf')
		OR	HasKeyword(cnam, 'BYOHHouseCraftingCategoryWeaponRacks')		
		)
		THEN	BEGIN	IF	NotHas(e, 'CCO_MiscDecorRecipes')							
			THEN	agvc(conditions, 'CCO_MiscDecorRecipes')							
			END		
	ELSE	IF	(	HasKeyword(cnam, 'BYOHAdoptionToyKeyword')
		OR	HasKeyword(cnam, 'BYOHAdoptionClothesKeyword')
		OR	HasKeyword(cnam, 'GiftChildSpecial')									
		OR	HasKeyword(cnam, 'GiftUniversallyValuable')	
		)
		THEN	BEGIN	IF	NotHas(e, 'CCO_MiscGiftRecipes')							
			THEN	agvc(conditions, 'CCO_MiscGiftRecipes')							
			END
	ELSE	IF	(	HasKeyword(cnam, 'WAF_ToolsMaterials')										
		OR	HasSubstringInFULL(cnam, 'Pickaxe')									
		OR	HasSubstringInFULL(cnam, 'Woodaxe')	
		OR	HasSubstringInFULL(cnam, 'Torch')			
		OR	HasSubstringInFULL(cnam, 'Tool')	
		)
		THEN	BEGIN	IF	NotHas(e, 'CCO_MiscToolRecipes')							
			THEN	agvc(conditions, 'CCO_MiscToolRecipes')																							
			END									
	ELSE	IF	(	HasSubstringInFULL(cnam, 'Tent')		
		OR	HasSubstringInFULL(cnam, 'Bed')		
		OR	HasSubstringInFULL(cnam, 'Camp')		
		OR	HasKeyword(cnam, 'WAF_MaterialSurvival')	
		)
		THEN	BEGIN	IF	NotHas(e, 'CCO_MiscSurvivalRecipes')							
			THEN	agvc(conditions, 'CCO_MiscSurvivalRecipes')	
			END
	ELSE	IF	NotHas(e, 'CCO_MiscOtherRecipes')								
		THEN	agvc(conditions, 'CCO_MiscOtherRecipes')					
			{ELSE}								
	{ELSE}										
	;										 
	
	IF	Signature(cnam) = 'WEAP'		
	THEN	IF	HasKeyword(cnam, 'WeapTypeStaff')	
		AND	NOT	HasSubstringInEDID(cnam, 'MenuOption')
		THEN	BEGIN	IF	NotHas(e, 'CCO_WeapStaffRecipes')							
			THEN	agvc(conditions, 'CCO_WeapStaffRecipes')		
			END	
	ELSE	IF	(	HasSubstringInFULL(cnam, 'Throw')
		OR HasSubstringInEDID(cnam, 'Throw')	
		OR HasSubstringInFULL(cnam, 'Grenade')
		OR HasSubstringInFULL(cnam, 'Bomb')		
		OR HasSubstringInEDID(cnam, 'Grenade')
		OR HasSubstringInEDID(cnam, 'Bomb')			
		)
		THEN	BEGIN	IF	NotHas(e, 'CCO_WeapOtherRangedRecipes')
			THEN	agvc(conditions, 'CCO_WeapOtherRangedRecipes')		
			END			
	ELSE	IF	(	HasSubstringInFULL(cnam, 'Staff')
		OR HasSubstringInFULL(cnam, 'Stave')	
		OR HasSubstringInFULL(cnam, 'Spear')
		OR HasSubstringInFULL(cnam, 'Halberd')		
		OR HasSubstringInFULL(cnam, 'Glaive')
		OR HasSubstringInFULL(cnam, 'Trident')			
		)
		THEN	BEGIN	IF	NotHas(e, 'CCO_WeapOther2HandRecipes')
			AND	(	HasKeyword(cnam, 'WeapTypeGreatsword')		
				OR	HasKeyword(cnam, 'WeapTypeBattleaxe')
				OR	HasKeyword(cnam, 'WeapTypeWarhammer')
				)
			THEN	agvc(conditions, 'CCO_WeapOther2HandRecipes')		
			END	
	ELSE	IF	(	HasSubstringInFULL(cnam, 'Staff')
		OR HasSubstringInFULL(cnam, 'Stave')	
		OR HasSubstringInFULL(cnam, 'Spear')
		OR HasSubstringInFULL(cnam, 'Halberd')		
		OR HasSubstringInFULL(cnam, 'Glaive')
		OR HasSubstringInFULL(cnam, 'Trident')			
		)
		THEN	BEGIN	IF	NotHas(e, 'CCO_WeapOther1HandRecipes')
			AND	(	HasKeyword(cnam, 'CCO_WeapDaggerRecipes')		
				OR	HasKeyword(cnam, 'CCO_WeapMaceRecipes')
				OR	HasKeyword(cnam, 'CCO_WeapSwordRecipes')
				OR	HasKeyword(cnam, 'CCO_WeapWarAxeRecipes')				
				)
			THEN	agvc(conditions, 'CCO_WeapOther1HandRecipes')		
			END				
	ELSE	IF	HasKeyword(cnam, 'WeapTypeBattleaxe')
		AND	NOT	HasSubstringInEDID(cnam, 'MenuOption')
		THEN	BEGIN	IF	NotHas(e, 'CCO_WeapBattleaxeRecipes')							
			THEN	agvc(conditions, 'CCO_WeapBattleaxeRecipes')		
			END	
	ELSE	IF	HasSubstringInFULL(cnam, 'Crossbow')
		THEN	BEGIN	IF	NotHas(e, 'CCO_WeapCrossbowRecipes')							
			THEN	agvc(conditions, 'CCO_WeapCrossbowRecipes')	
			END			
	ELSE	IF	HasKeyword(cnam, 'WeapTypeBow')
		THEN	BEGIN	IF	NotHas(e, 'CCO_WeapBowRecipes')							
			THEN	agvc(conditions, 'CCO_WeapBowRecipes')	
			END
	ELSE	IF	HasKeyword(cnam, 'WeapTypeDagger')
		THEN	BEGIN	IF	NotHas(e, 'CCO_WeapDaggerRecipes')												
			THEN	agvc(conditions, 'CCO_WeapDaggerRecipes')		
			END
	ELSE	IF	HasKeyword(cnam, 'WeapTypeGreatsword')				
		THEN	BEGIN	IF	NotHas(e, 'CCO_WeapGreatswordRecipes')							
			THEN	agvc(conditions, 'CCO_WeapGreatswordRecipes')					
			END
	ELSE	IF	HasKeyword(cnam, 'WeapTypeMace')				
		THEN	BEGIN	IF	NotHas(e, 'CCO_WeapMaceRecipes')					
			THEN	agvc(conditions, 'CCO_WeapMaceRecipes')				
			END
	ELSE	IF	HasKeyword(cnam, 'WeapTypeSword')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_WeapSwordRecipes')				
			THEN	agvc(conditions, 'CCO_WeapSwordRecipes')			
			END
	ELSE	IF	HasKeyword(cnam, 'WeapTypeWarAxe')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_WeapWarAxeRecipes')			
			THEN	agvc(conditions, 'CCO_WeapWarAxeRecipes')		
			END
	ELSE	IF	HasKeyword(cnam, 'WeapTypeWarhammer')	
		THEN	BEGIN	IF	NotHas(e, 'CCO_WeapWarhammerRecipes')		
			THEN	agvc(conditions, 'CCO_WeapWarhammerRecipes')	
			END
			{ELSE}		
	{ELSE}										
	;										
			
	IF	HasSubstringInFULL(cnam, 'Argonian')									
	OR	HasSubstringInFULL(cnam, 'Marsh')		
	OR	HasSubstringInFULL(cnam, 'Saxhleel')		
	OR	HasSubstringInFULL(cnam, 'An-Xileel')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_Argonian')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_Argonian')							
			{ELSE}								
			;																
		END									
	ELSE										
	IF	HasSubstringInFULL(cnam, 'Khajiit')									
	OR	HasSubstringInFULL(cnam, 'Elsweyr')	
	OR	HasSubstringInFULL(cnam, 'Senche')	
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_Khajiit')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_Khajiit')							
			{ELSE}								
			;																
		END									
	ELSE										
	IF	HasSubstringInFULL(cnam, 'Akavir')									
	OR	HasSubstringInFULL(cnam, 'Tsaesci')	
	OR	HasSubstringInFULL(cnam, 'Dragonguard')	
	OR	HasSubstringInFULL(cnam, 'Katana') 
	OR	HasSubstringInFULL(cnam, 'Tanto')
	OR	HasSubstringInFULL(cnam, 'Ninjato')
	OR	HasSubstringInFULL(cnam, 'Dadao') 
	OR	HasSubstringInFULL(cnam, 'Nodachi') 
	OR	HasSubstringInFULL(cnam, 'Wakizashi')
	OR	HasSubstringInFULL(cnam, 'Changdao') 
	OR	HasSubstringInFULL(cnam, 'Daito') 
	OR	HasSubstringInFULL(cnam, 'Samurai')	
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_Akaviri')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_Akaviri')							
			{ELSE}								
			;																
		END									
	ELSE										
	IF	HasKeyword(cnam, 'WAF_WeapMaterialRedguard')	
	OR	HasSubstringInFULL(cnam, 'Scimitar')		
	OR	HasSubstringInFULL(cnam, 'Hammerfell')									
	OR	HasSubstringInFULL(cnam, 'Redguard')			
	OR	HasSubstringInFULL(cnam, 'Yokuda')	
	OR	HasSubstringInFULL(cnam, 'Ra Gada')	
	OR	HasSubstringInFULL(cnam, 'Alik''r')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_Redguard')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_Redguard')							
			{ELSE}								
			;															
		END									
	ELSE		
	IF	HasSubstringInFULL(cnam, 'Breton')
	OR	HasSubstringInEDID(cnam, 'Breton')		
	OR	HasSubstringInFULL(cnam, 'High Rock')												
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_Breton')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_Breton')							
			{ELSE}								
			;															
		END									
	ELSE	
	IF	HasSubstringInFULL(cnam, 'Snow Elf')	
	OR	HasSubstringInFULL(cnam, 'Snow Elv')
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_SnowElf')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_SnowElf')							
			{ELSE}								
			;															
		END									
	ELSE			
	IF	HasKeyword(cnam, 'ArmorMaterialFalmer')									
	OR	HasKeyword(cnam, 'DLC1ArmorMaterialFalmerHardened')									
	OR	HasKeyword(cnam, 'DLC1ArmorMaterialFalmerHeavy')									
	OR	HasKeyword(cnam, 'DLC1ArmorMaterialFalmerHeavyOriginal')									
	OR	HasKeyword(cnam, 'WeapMaterialFalmer')									
	OR	HasKeyword(cnam, 'WeapMaterialFalmerHoned')									
	OR	HasSubstringInEDID(cnam, 'falmer')									
	OR	HasSubstringInFULL(cnam, 'falmer')			
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_Falmer')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_Falmer')							
			{ELSE}								
			;								
			IF	NotHas(e, 'CCO_LearningFalmer')							
			THEN	algvc(conditions, 'CCO_LearningFalmer')							
			{ELSE}								
			;								
		END									
	ELSE		
	IF	HasSubstringInFULL(cnam, 'Dwarven')									
	OR	HasSubstringInFULL(cnam, 'Dwemer')												
	OR	HasSubstringInFULL(cnam, 'Aetherium')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_Dwemer')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_Dwemer')							
			{ELSE}								
			;																
		END									
	ELSE											
	IF	HasSubstringInFULL(cnam, 'Bosmer')									
	OR	HasSubstringInEDID(cnam, 'Bosmer')	
	OR	HasSubstringInFULL(cnam, 'Wood Elf')
	OR	HasSubstringInFULL(cnam, 'Wood Elv')	
	OR	HasSubstringInFULL(cnam, 'Green Pact')	
	OR	HasSubstringInFULL(cnam, 'Wild Hunt')		
	OR	HasSubstringInFULL(cnam, 'Valenwood')	
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_Bosmer')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_Bosmer')							
			{ELSE}								
			;																
		END									
	ELSE	
	IF	HasSubstringInFULL(cnam, 'Dunmer')									
	OR	HasSubstringInEDID(cnam, 'Dunmer')
	OR	HasSubstringInFULL(cnam, 'Dark Elf')
	OR	HasSubstringInFULL(cnam, 'Dark Elv')	
	OR	HasSubstringInFULL(cnam, 'Morrowind')									
	OR	HasSubstringInFULL(cnam, 'Telvanni')
	OR	HasSubstringInFULL(cnam, 'Redoran')	
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_Dunmer')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_Dunmer')							
			{ELSE}								
			;																
		END									
	ELSE	
	IF	HasKeyword(cnam, 'WAF_ArmorMaterialThalmor')									
	OR	HasSubstringInFULL(cnam, 'Justiciar')									
	OR	HasSubstringInFULL(cnam, 'Thalmor')									
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_FactionThalmor')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_FactionThalmor')							
			{ELSE}								
			;																
		END									
	ELSE
	IF	HasSubstringInFULL(cnam, 'Aldmer')									
	OR	HasSubstringInEDID(cnam, 'Aldmer')
	OR	HasSubstringInFULL(cnam, 'Altmer')									
	OR	HasSubstringInEDID(cnam, 'Altmer')
	OR	HasSubstringInFULL(cnam, 'High Elf')
	OR	HasSubstringInFULL(cnam, 'High Elv')
	OR	HasSubstringInFULL(cnam, 'Summerset')
	OR	HasSubstringInFULL(cnam, 'Elven')									
	OR	HasSubstringInEDID(cnam, 'Elven')
	OR	HasSubstringInFULL(cnam, 'Elvish')									
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_Altmer')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_Altmer')							
			{ELSE}								
			;																
		END									
	ELSE		
	IF	HasSubstringInFULL(cnam, 'Orcish')									
	OR	HasSubstringInFULL(cnam, 'Orsimer')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_Orsimer')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_Orsimer')							
			{ELSE}								
			;																
		END									
	ELSE		
	IF	HasSubstringInFULL(cnam, 'Ancient Nord')	
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_NordAncient')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_NordAncient')							
			{ELSE}								
			;								
			IF	NotHas(e, 'CCO_LearningDraugr')							
			THEN	algvc(conditions, 'CCO_LearningDraugr')							
			{ELSE}								
			;								
		END									
	ELSE		
	IF	HasSubstringInFULL(cnam, 'Nordic')									
	OR	HasSubstringInFULL(cnam, 'Norse')									
	OR	HasSubstringInFULL(cnam, 'Skaal')	
	OR	HasSubstringInFULL(cnam, 'Viking')	
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_Nord')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_Nord')							
			{ELSE}								
			;																
		END									
	ELSE										
	IF	HasKeyword(cnam, 'WAF_ArmorMaterialDraugr')																	
	OR	HasKeyword(cnam, 'WeapMaterialDraugr')									
	OR	HasKeyword(cnam, 'WeapMaterialDraugrHoned')									
	OR	HasSubstringInEDID(cnam, 'Draugr')									
	OR	HasSubstringInFULL(cnam, 'Draugr')	
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_NordAncient')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_NordAncient')							
			{ELSE}								
			;								
			IF	NotHas(e, 'CCO_LearningDraugr')							
			THEN	algvc(conditions, 'CCO_LearningDraugr')							
			{ELSE}								
			;								
		END									
	ELSE										
	IF	HasKeyword(cnam, 'DLC2ArmorMaterialNordicHeavy')									
	OR	HasKeyword(cnam, 'DLC2ArmorMaterialNordicLight')									
	OR	HasKeyword(cnam, 'DLC2WeapMaterialNordic')									
	OR	HasKeyword(cnam, 'WAF_MaterialNordic')									
	OR	HasSubstringInFULL(cnam, 'Nord')									
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_Nord')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_Nord')							
			{ELSE}								
			;															
		END									
	ELSE																				
	IF	HasKeyword(cnam, 'ArmorMaterialImperialHeavy')									
	OR	HasKeyword(cnam, 'ArmorMaterialImperialLight')									
	OR	HasKeyword(cnam, 'ArmorMaterialImperialStudded')									
	OR	HasKeyword(cnam, 'ArmorMaterialPenitus')									
	OR	HasKeyword(cnam, 'WeapMaterialImperial')									
	OR	HasSubstringInFULL(cnam, 'Imperial')	
	OR	HasSubstringInFULL(cnam, 'Cyrodiil')	
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_Imperial')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_Imperial')							
			{ELSE}								
			;																
		END									
	ELSE										
	IF	HasKeyword(cnam, 'ArmorMaterialBearStormcloak')									
	OR	HasKeyword(cnam, 'ArmorMaterialStormcloak')									
	OR	HasSubstringInFULL(cnam, 'Stormcloak')									
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_FactionStormcloak')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_FactionStormcloak')							
			{ELSE}								
			;															
		END									
	ELSE																											
	IF	HasKeyword(cnam, 'WAF_WeapNightingale')									
	OR	HasSubstringInFULL(cnam, 'Nightingale')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_FactionNightingale')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_FactionNightingale')							
			{ELSE}								
			;																
		END									
	ELSE
	IF	HasKeyword(cnam, 'ArmorMaterialThievesGuild')									
	OR	HasKeyword(cnam, 'ArmorMaterialThievesGuildLeader')									
	OR	HasKeyword(cnam, 'WAF_ArmorMaterialTGLinwe')									
	OR	HasKeyword(cnam, 'WAF_ArmorMaterialTGSummerset')
	OR	HasKeyword(cnam, 'WAF_WeapNightingale')									
	OR	HasSubstringInFULL(cnam, 'Nightingale')	
	OR	HasSubstringInFULL(cnam, 'Thieves')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_FactionThievesGuild')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_FactionThievesGuild')							
			{ELSE}								
			;																
		END									
	ELSE										
	IF	HasKeyword(cnam, 'ArmorDarkBrotherhood')									
	OR	HasKeyword(cnam, 'WAF_ArmorDarkBrotherhoodAncient')		
	OR	HasSubstringInFULL(cnam, 'Dark Brotherhood')		
	OR	HasSubstringInFULL(cnam, 'Shrouded')									
	OR	HasSubstringInFULL(cnam, 'Sithis')	
	OR	HasSubstringInFULL(cnam, 'Morag Tong')	
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_FactionDarkBrotherhood')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_FactionDarkBrotherhood')							
			{ELSE}								
			;																
		END									
	ELSE										
	IF	HasKeyword(cnam, 'DLC1ArmorMaterialDawnguard')		
	OR	HasKeyword(cnam, 'WAF_DLC1WeapMaterialDawnguard')
	OR	HasKeyword(cnam, 'DLC1ArmorMaterialHunter')
	OR	HasSubstringInFULL(cnam, 'Dawnguard')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_FactionDawnguard')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_FactionDawnguard')							
			{ELSE}								
			;																
		END									
	ELSE				
	IF	HasKeyword(cnam, 'DLC1ArmorMaterialVampire')		
	OR	HasSubstringInFULL(cnam, 'Vampir')		
	OR	HasSubstringInEDID(cnam, 'Vampir')	
	OR	HasSubstringInFULL(cnam, 'Volkihar')		
	OR	HasSubstringInEDID(cnam, 'Volkihar')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_Vampire')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_Vampire')							
			{ELSE}								
			;															
		END									
	ELSE		
	IF	HasKeyword(cnam, 'ArmorMaterialBlades')									
	OR	HasKeyword(cnam, 'WAF_WeapMaterialBlades')	
	OR	HasSubstringInFULL(cnam, 'Blades')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_FactionBlades')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_FactionBlades')							
			{ELSE}								
			;															
		END									
	ELSE										
	IF	HasKeyword(cnam, 'ArmorMaterialForsworn')			
	OR	HasKeyword(cnam, 'WAF_WeapMaterialForsworn')																
	OR	HasSubstringInEDID(cnam, 'forsworn')									
	OR	HasSubstringInFULL(cnam, 'forsworn')									
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_FactionForsworn')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_FactionForsworn')							
			{ELSE}								
			;								
			IF	NotHas(e, 'CCO_LearningForsworn')							
			THEN	algvc(conditions, 'CCO_LearningForsworn')							
			{ELSE}								
			;								
		END									
	ELSE										
	IF	HasKeyword(cnam, 'WAF_ArmorWolf')									
	OR	HasSubstringInFULL(cnam, 'Jorrvaskr')									
	OR	HasSubstringInFULL(cnam, 'Wolf')									
	OR	HasSubstringInFULL(cnam, 'Ysgramor')									
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_FactionCompanions')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_FactionCompanions')							
			{ELSE}								
			;																
		END									
	ELSE			
	IF	HasSubstringInFULL(cnam, 'College')	
	OR	HasSubstringInFULL(cnam, 'Mages Guild')	
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_FactionMagesGuild')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_FactionMagesGuild')							
			{ELSE}								
			;																
		END									
	ELSE	
	IF	HasKeyword(cnam, 'WAF_ArmorMaterialGuard')									
	OR	HasSubstringInFULL(cnam, 'Guard')									
	OR	HasSubstringInFULL(cnam, 'Hold')									
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_FactionGuards')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_FactionGuards')							
			{ELSE}								
			;															
		END									
	ELSE	
	IF	HasKeyword(cnam, 'WAF_MaterialFaction')									
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeStyle_FactionOther')							
			THEN	agvc(conditions, 'CCO_CategoryForgeStyle_FactionOther')							
			{ELSE}								
			;																
		END									
	ELSE		
	IF	NotHas(e, 'CCO_CategoryForgeStyle_Misc')		
	AND	NOT	HasSubstringInEDID(cnam, 'MenuOption')
		THEN	agvc(conditions, 'CCO_CategoryForgeStyle_Misc')																															
		{ELSE}		
	{ELSE}										
	;
		
	IF	HasKeyword(cnam, 'ArmorMaterialDaedric')									
	OR	HasKeyword(cnam, 'WeapMaterialDaedric')	
	OR	HasSubstringInFULL(cnam, 'Daedra')									
	OR	HasSubstringInFULL(cnam, 'Daedric')									
	OR	HasSubstringInFULL(cnam, 'Dremora')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_OptionCraftDaedricOnlyAtNight')							
			THEN	adanc(conditions)							
			{ELSE}								
			;								
			IF	NotHas(e, 'CCO_CategoryForgeMaterial_Daedric')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Daedric')							
			{ELSE}								
			;																
		END									
	ELSE																											
	IF	HasKeyword(cnam, 'ArmorMaterialEbony')									
	OR	HasKeyword(cnam, 'WeapMaterialEbony')																	
	OR	HasSubstringInFULL(cnam, 'Ebony')									
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Ebony')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Ebony')							
			{ELSE}								
			;																
		END									
	ELSE							
	IF	HasKeyword(cnam, 'ArmorMaterialDragonplate')									
	OR	HasKeyword(cnam, 'ArmorMaterialDragonscale')									
	OR	HasKeyword(cnam, 'DLC1WeapMaterialDragonbone')									
	OR	HasSubstringInFULL(cnam, 'Alduin')					
	OR	HasSubstringInFULL(cnam, 'Dragon')	
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Dragon')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Dragon')							
			{ELSE}								
			;																
		END									
	ELSE	
	IF	HasSubstringInFULL(cnam, 'Gold')
	OR	HasSubstringInEDID(cnam, 'Gold')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Gold')	
						
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Gold')							
			{ELSE}								
			;	
//			IF	NotHas(e, 'CCO_SmithingReqGold')					
//			THEN	reqgold(conditions, 'CCO_SmithingReqGold')							
//			{ELSE}								
//			;	
		END									
	ELSE		
	IF	HasKeyword(cnam, 'VendorItemClutter')									
	AND	HasSubstringInFULL(cnam, 'Glass')			
	THEN	BEGIN	IF	NotHas(e, 'CCO_MiscToolRecipes')							
			THEN	agvc(conditions, 'CCO_MiscToolRecipes')							
			{ELSE}		
			;	
		END									
	ELSE		
	IF	HasKeyword(cnam, 'ArmorMaterialGlass')									
	OR	HasKeyword(cnam, 'WeapMaterialGlass')		
	OR	HasSubstringInFULL(cnam, 'Glass')	
	OR	HasSubstringInFULL(cnam, 'Malachite')	
	OR	HasSubstringInFULL(cnam, 'Moldavite')
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Glass')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Glass')							
			{ELSE}								
			;																
		END									
	ELSE		
	IF	HasKeyword(cnam, 'DLC2ArmorMaterialStalhrimHeavy')									
	OR	HasKeyword(cnam, 'DLC2ArmorMaterialStalhrimLight')									
	OR	HasKeyword(cnam, 'DLC2WeapMaterialStalhrim')
	OR	HasSubstringInFULL(cnam, 'Stalhrim')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Stalhrim')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Stalhrim')							
			{ELSE}								
			;																
		END									
	ELSE
	IF	HasSubstringInFULL(cnam, 'Quicksilver')		
	OR	HasSubstringInEDID(cnam, 'Quicksilver')	
	OR	HasSubstringInFULL(cnam, 'Mithril')	
	OR	HasSubstringInEDID(cnam, 'Mithril')	
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Quicksilver')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Quicksilver')							
			{ELSE}								
			;															
		END									
	ELSE		
	IF	HasKeyword(cnam, 'WeapMaterialSilver')									
	OR	HasKeyword(cnam, 'WAF_MaterialSilver')
	OR	HasSubstringInFULL(cnam, 'Silver')		
	OR	HasSubstringInEDID(cnam, 'Silver')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Silver')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Silver')							
			{ELSE}								
			;	
//			IF	NotHas(e, 'CCO_SmithingReqSilver')							
//			THEN	reqgold(conditions, 'CCO_SmithingReqSilver')							
//			{ELSE}								
//			;			
		END									
	ELSE	
	IF	HasSubstringInFULL(cnam, 'Copper')		
	OR	HasSubstringInEDID(cnam, 'Copper')	
	OR	HasSubstringInFULL(cnam, 'Brass')	
	OR	HasSubstringInFULL(cnam, 'Bronze')	
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Copper')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Copper')							
			{ELSE}								
			;																
		END									
	ELSE
	IF	HasSubstringInFULL(cnam, 'Calcinium')		
	OR	HasSubstringInEDID(cnam, 'Calcinium')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Calcinium')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Calcinium')							
			{ELSE}								
			;																
		END									
	ELSE
	IF	HasSubstringInFULL(cnam, 'Galatite')		
	OR	HasSubstringInEDID(cnam, 'Galatite')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Galatite')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Galatite')							
			{ELSE}								
			;																
		END									
	ELSE
	IF	HasKeyword(cnam, 'ArmorMaterialDwarven')									
	OR	HasKeyword(cnam, 'DLC1LD_CraftingMaterialAetherium')									
	OR	HasKeyword(cnam, 'WeapMaterialDwarven')		
	OR	HasSubstringInFULL(cnam, 'Dwarven Metal')										
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Dwarven')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Dwarven')							
			{ELSE}								
			;																
		END									
	ELSE										
	IF	HasKeyword(cnam, 'ArmorMaterialElven')									
	OR	HasKeyword(cnam, 'ArmorMaterialElvenGilded')									
	OR	HasKeyword(cnam, 'WeapMaterialElven')																	
	OR	HasSubstringInFULL(cnam, 'Moonstone')		
	OR	HasSubstringInEDID(cnam, 'Moonstone')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Moonstone')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Moonstone')							
			{ELSE}								
			;																
		END									
	ELSE	
	IF	HasKeyword(cnam, 'ArmorMaterialOrcish')									
	OR	HasKeyword(cnam, 'WeapMaterialOrcish')									
	OR	HasSubstringInFULL(cnam, 'Orichalcum')	
	OR	HasSubstringInEDID(cnam, 'Orichalcum')		
	OR	HasSubstringInFULL(cnam, 'Jade')									
	OR	HasSubstringInEDID(cnam, 'Jade')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Orichalcum')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Orichalcum')							
			{ELSE}								
			;																
		END									
	ELSE			
	IF	HasKeyword(cnam, 'DLC2ArmorMaterialChitinHeavy')									
	OR	HasKeyword(cnam, 'DLC2ArmorMaterialChitinLight')									
	OR	HasKeyword(cnam, 'DLC2ArmorMaterialMoragTong')									
	OR	HasKeyword(cnam, 'WAF_MaterialChitin')									
	OR	HasSubstringInFULL(cnam, 'Chitin')
	OR	HasKeyword(cnam, 'ArmorMaterialFalmer')	
	OR	HasKeyword(cnam, 'WeapMaterialFalmer')	
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Chitin')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Chitin')							
			{ELSE}								
			;															
		END									
	ELSE	
	IF	HasSubstringInFULL(cnam, 'Bone')		
	OR	HasSubstringInFULL(cnam, 'Tooth')		
	OR	HasSubstringInFULL(cnam, 'Tusk')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Bone')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Bone')							
			{ELSE}								
			;															
		END									
	ELSE	
	IF	HasKeyword(cnam, 'DLC2ArmorMaterialBonemoldHeavy')									
	OR	HasKeyword(cnam, 'DLC2ArmorMaterialBonemoldLight')									
	OR	HasKeyword(cnam, 'WAF_MaterialBonemold')									
	OR	HasSubstringInFULL(cnam, 'Bonemold')									
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Bonemold')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Bonemold')							
			{ELSE}								
			;																
		END									
	ELSE	
	IF	HasKeyword(cnam, 'WeapMaterialWood')									
	OR	HasSubstringInFULL(cnam, 'Wood')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Wood')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Wood')							
			{ELSE}								
			;																
		END									
	ELSE
	IF	HasSubstringInFULL(cnam, 'Stone')
	OR	HasSubstringInFULL(cnam, 'Flint')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Stone')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Stone')							
			{ELSE}								
			;																
		END									
	ELSE	
	IF	(	HasKeyword(cnam, 'ArmorMaterialIron')									
		OR	HasKeyword(cnam, 'ArmorMaterialIronBanded')									
		OR	HasKeyword(cnam, 'WeapMaterialIron')											
		OR	HasSubstringInFULL(cnam, 'Iron')	
		OR	HasKeyword(cnam, 'WAF_ArmorMaterialDraugr')																	
		OR	HasKeyword(cnam, 'WeapMaterialDraugr')	
		)
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Iron')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Iron')							
			{ELSE}								
			;																
		END									
	ELSE										
	IF	HasKeyword(cnam, 'ArmorMaterialSteel')									
	OR	HasKeyword(cnam, 'ArmorMaterialSteelPlate')									
	OR	HasKeyword(cnam, 'WeapMaterialSteel')															
	OR	HasSubstringInFULL(cnam, 'Steel')									
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Steel')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Steel')							
			{ELSE}								
			;																
		END									
	ELSE						
	IF	HasKeyword(cnam, 'ArmorMaterialLeather')																	
	OR	HasSubstringInFULL(cnam, 'Leather')									
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Leather')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Leather')							
			{ELSE}								
			;																
		END									
	ELSE	
	IF	HasKeyword(cnam, 'ArmorMaterialHide')									
	OR	HasKeyword(cnam, 'ArmorMaterialScaled')									
	OR	HasKeyword(cnam, 'ArmorMaterialStudded')									
	OR	HasSubstringInFULL(cnam, 'Fur')									
	OR	HasSubstringInFULL(cnam, 'Hide')		
	OR	HasSubstringInFULL(cnam, 'Pelt')		
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Hide')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Hide')							
			{ELSE}								
			;																
		END									
	ELSE			
	IF	HasKeyword(cnam, 'WAF_MaterialArcane')			
	OR	NOT	NotHas(e, 'ArcaneBlacksmith')	
	THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Arcane')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Arcane')							
			{ELSE}								
			;																
		END									
	ELSE				
	IF	HasKeyword(cnam, 'ArmorClothing')	
	OR	HasSubstringInFULL(cnam, 'Robe')		
	OR	HasSubstringInFULL(cnam, 'Cloth')	
	OR	HasSubstringInFULL(cnam, 'Linen')	
	OR	HasSubstringInEDID(cnam, 'Robe')	
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Cloth')							
			THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Cloth')					
			{ELSE}								
			;	
		END	
	ELSE	
	IF	NotHas(e, 'CCO_CategoryForgeMaterial_Misc')		
	AND	NOT	HasSubstringInEDID(cnam, 'MenuOption')
		THEN	agvc(conditions, 'CCO_CategoryForgeMaterial_Misc')																															
		{ELSE}	
		;			
	
	IF	(bnam = 'CraftingSmithingSkyforge')
	AND	NotHas(e, 'CCO_CategoryForgeMaterialOR_Skyforge') 
		THEN	exclsky(conditions)									
	{ELSE}		
	;	
		
	IF	NotHas(e, 'CCO_MODSupported')	
	AND	NotHas(e, 'CCO_OptionBreakdownEquipmentatSmelter')
	AND	NotHas(e, 'CCO_OptionBreakdownEquipmentatTanningRack')
	AND	NotHas(e, 'CCO_CCOAddedRecipes')	
	AND	NotHas(e, 'CCO_DisableIfCCOisInstalled')	
	AND	NotHas(e, 'CCO_VanillaRecipe')	
	AND	NotHas(e, 'CCO_DLCDawnguard')	
	AND	NotHas(e, 'CCO_DLCHearthfire')
	AND	NotHas(e, 'CCO_DLCDragonborn')
	AND	NotHas(e, 'CCO_MODStealthSkillsRebalanced')
	AND	NotHas(e, 'CCO_MODImmersiveArmors')
	AND	NotHas(e, 'CCO_MODImmersiveWeapons')
	AND	NotHas(e, 'CCO_MODJaysusSwords')
	AND	NotHas(e, 'CCO_MODHeavyArmory')
	AND	NotHas(e, 'CCO_MODJewelCraft')
	AND	NotHas(e, 'CCO_MODBandoliers')
	AND	NotHas(e, 'CCO_MODBookofSilence')
	AND	NotHas(e, 'CCO_MODCampfire')
	AND	NotHas(e, 'CCO_MODWinterIsComing')
	AND	NotHas(e, 'CCO_MODCloaks')
	AND	NotHas(e, 'CCO_MODImmersiveJewelry')
	AND	NotHas(e, 'CACO_CACOAddedRecipes')
	AND	NotHas(e, 'CCO_OptionCraftingMenuOptions')	
	AND	NOT	HasSubstringInEDID(cnam, 'MenuOption')
	AND	NOT	HasSubstringInEDID(e, 'Breakdown')	
	AND	NOT	HasSubstringInEDID(e, 'Learn')		
		THEN	cmcs(conditions)									
	{ELSE}			
	;	
END	
;																				
//=========================================================================											
// smithing smelter conditions											
procedure SmithingSmelterConditions(cobj: IInterface; conditions: IInterface);											
											
VAR	items, li, item: IInterface;										
	i: integer;										
											
BEGIN	items := ElementByPath(cobj, 'Items');										
	FOR	i := 0									
	TO	ElementCount(items) - 1									
	DO	BEGIN	li := ElementByIndex(items, i);								
			item := LinksTo(ElementByPath(li, 'CNTO - Item\Item'));								
			IF	NotHas(cobj, 'CCO_OptionBreakdownEquipmentatSmelter')	
			AND	HasSubstringInEDID(cobj, 'Breakdown')			
//			THEN	IF	(Signature(item) = 'WEAP')						
//				OR	(Signature(item) = 'ARMO')						
				THEN	BEGIN	agvc(conditions, 'CCO_OptionBreakdownEquipmentatSmelter');					
						Break;					
					END						
				{ELSE}							
				;							
			{ELSE}								
			;								
		END									
	;										
END											
;											
//=========================================================================											
// smithing smelter category conditions	
procedure SmithingSmelterCategoryConditions(cnam: IInterface; conditions: IInterface; e: IInterface);		

BEGIN
									
	IF	HasSubstringInFULL(cnam, 'Iron')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategorySmelter_Iron')							
			THEN	agvc(conditions, 'CCO_CategorySmelter_Iron')		
			END	
	ELSE	IF	HasSubstringInFULL(cnam, 'Steel')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategorySmelter_Steel')							
			THEN	agvc(conditions, 'CCO_CategorySmelter_Steel')		
			END
	ELSE	IF	HasSubstringInFULL(cnam, 'Corundum')	
			OR	HasSubstringInFULL(cnam, 'Copper')			
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategorySmelter_Corundum')							
			THEN	agvc(conditions, 'CCO_CategorySmelter_Corundum')		
			END	
	ELSE	IF	HasSubstringInFULL(cnam, 'Dwarven')	
			OR	HasSubstringInFULL(cnam, 'Dwemer')			
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategorySmelter_Dwarven')							
			THEN	agvc(conditions, 'CCO_CategorySmelter_Dwarven')		
			END	
	ELSE	IF	HasSubstringInFULL(cnam, 'Charcoal')	
			OR	HasSubstringInFULL(cnam, 'Coal')				
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategorySmelter_Charcoal')							
			THEN	agvc(conditions, 'CCO_CategorySmelter_Charcoal')		
			END			
	ELSE	IF	HasSubstringInFULL(cnam, 'Gold')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategorySmelter_Gold')							
			THEN	agvc(conditions, 'CCO_CategorySmelter_Gold')		
			END		
	ELSE	IF	HasSubstringInFULL(cnam, 'Quicksilver')	
			OR	HasSubstringInFULL(cnam, 'Mithril')			
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategorySmelter_Quicksilver')							
			THEN	agvc(conditions, 'CCO_CategorySmelter_Quicksilver')		
			END			
	ELSE	IF	HasSubstringInFULL(cnam, 'Silver')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategorySmelter_Silver')							
			THEN	agvc(conditions, 'CCO_CategorySmelter_Silver')		
			END		
	ELSE	IF	HasSubstringInFULL(cnam, 'Moonstone')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategorySmelter_Moonstone')							
			THEN	agvc(conditions, 'CCO_CategorySmelter_Moonstone')		
			END				
	ELSE	IF	HasSubstringInFULL(cnam, 'Orichalcum')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategorySmelter_Orichalcum')							
			THEN	agvc(conditions, 'CCO_CategorySmelter_Orichalcum')		
			END		
	ELSE	IF	HasSubstringInEDID(cnam, 'BYOHMaterialGlass')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategorySmelter_Misc')							
			THEN	agvc(conditions, 'CCO_CategorySmelter_Misc')		
			END				
	ELSE	IF	HasSubstringInFULL(cnam, 'Glass')	
			OR	HasSubstringInFULL(cnam, 'Malachite')			
			OR	HasSubstringInFULL(cnam, 'Moldavite')				
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategorySmelter_Glass')							
			THEN	agvc(conditions, 'CCO_CategorySmelter_Glass')		
			END				
	ELSE	IF	HasSubstringInFULL(cnam, 'Ebony')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategorySmelter_Ebony')							
			THEN	agvc(conditions, 'CCO_CategorySmelter_Ebony')		
			END	
	ELSE	IF	HasSubstringInFULL(cnam, 'Stalhrim')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategorySmelter_Stalhrim')							
			THEN	agvc(conditions, 'CCO_CategorySmelter_Stalhrim')		
			END		
	ELSE	IF	HasSubstringInFULL(cnam, 'Calcinium')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategorySmelter_Calcinium')							
			THEN	agvc(conditions, 'CCO_CategorySmelter_Calcinium')		
			END		
	ELSE	IF	HasSubstringInFULL(cnam, 'Galatite')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategorySmelter_Galatite')							
			THEN	agvc(conditions, 'CCO_CategorySmelter_Galatite')		
			END				
	ELSE	IF	HasSubstringInFULL(cnam, 'Bone')	
			OR	HasSubstringInFULL(cnam, 'Leather')			
			OR	HasSubstringInFULL(cnam, 'Chitin')		
			OR	HasSubstringInFULL(cnam, 'Hide')		
			OR	HasSubstringInFULL(cnam, 'Fur')	
			OR	HasSubstringInFULL(cnam, 'Scale')	
			OR	HasSubstringInFULL(cnam, 'Wood')	
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategorySmelter_Organics')							
			THEN	agvc(conditions, 'CCO_CategorySmelter_Organics')		
			END				
	ELSE	IF	NotHas(e, 'CCO_CategorySmelter_Misc')	
		AND	NOT	HasSubstringInEDID(cnam, 'MenuOption')	
		THEN	agvc(conditions, 'CCO_CategorySmelter_Misc')					
			{ELSE}						
	{ELSE}										
	;		
END											
;		
//=========================================================================											
// tanning rack conditions											
procedure TanningRackConditions(cobj: IInterface; conditions: IInterface);											
											
VAR	cnam, items, li, item: IInterface;										
	i: integer;										
											
BEGIN	cnam := LinksTo(ElementByPath(cobj, 'CNAM'));										
												
	items := ElementByPath(cobj, 'Items');										
	FOR	i := 0									
	TO	ElementCount(items) - 1									
	DO	BEGIN	li := ElementByIndex(items, i);								
			item := LinksTo(ElementByPath(li, 'CNTO - Item\Item'));								
			IF	NotHas(cobj, 'CCO_OptionBreakdownEquipmentatTanningRack')	
			AND	HasSubstringInEDID(cobj, 'Breakdown')					
				THEN	BEGIN	agvc(conditions, 'CCO_OptionBreakdownEquipmentatTanningRack');					
						Break;					
					END						
				{ELSE}							
				;							
			{ELSE}								
			;								
		END									
	;										
END											
;
//=========================================================================											
// smithing tanning rack category conditions	
procedure SmithingTanningRackCategoryConditions(cnam: IInterface; conditions: IInterface; e: IInterface);		

VAR	jewelry: boolean;										
											
BEGIN	jewelry := false;

	IF	Signature(cnam) = 'MISC'	
	THEN	IF	(	HasSubstringInEDID(cnam, 'Gem')
		OR	HasSubstringInEDID(cnam, 'Ingot')
		OR	HasSubstringInEDID(cnam, 'Ore')
		OR	HasSubstringInEDID(cnam, 'FurPlate')
		OR	HasSubstringInEDID(cnam, 'Hide')		
		OR	HasSubstringInEDID(cnam, 'Leather')			
		OR	HasKeyword(cnam, 'BYOHHouseCraftingCategorySmithing')	
		)
		THEN	BEGIN	IF	NotHas(e, 'CCO_MiscSuppliesRecipes')							
			THEN	agvc(conditions, 'CCO_MiscSuppliesRecipes')							
			END									
	ELSE	IF	(	HasKeyword(cnam, 'BYOHHouseCraftingCategoryContainers')
		OR	HasKeyword(cnam, 'BYOHHouseCraftingCategoryFurniture')
		OR	HasKeyword(cnam, 'BYOHHouseCraftingCategoryShelf')
		OR	HasKeyword(cnam, 'BYOHHouseCraftingCategoryWeaponRacks')		
		)
		THEN	BEGIN	IF	NotHas(e, 'CCO_MiscDecorRecipes')							
			THEN	agvc(conditions, 'CCO_MiscDecorRecipes')							
			END		
	ELSE	IF	(	HasKeyword(cnam, 'BYOHAdoptionToyKeyword')
		OR	HasKeyword(cnam, 'BYOHAdoptionClothesKeyword')
		OR	HasKeyword(cnam, 'GiftChildSpecial')									
		OR	HasKeyword(cnam, 'GiftUniversallyValuable')	
		)
		THEN	BEGIN	IF	NotHas(e, 'CCO_MiscGiftRecipes')							
			THEN	agvc(conditions, 'CCO_MiscGiftRecipes')							
			END
	ELSE	IF	(	HasKeyword(cnam, 'WAF_ToolsMaterials')										
		OR	HasSubstringInFULL(cnam, 'Pickaxe')									
		OR	HasSubstringInFULL(cnam, 'Woodaxe')
		OR	HasSubstringInFULL(cnam, 'Torch')		
		OR	HasSubstringInFULL(cnam, 'Tool')	
		)
		THEN	BEGIN	IF	NotHas(e, 'CCO_MiscToolRecipes')							
			THEN	agvc(conditions, 'CCO_MiscToolRecipes')																							
			END									
	ELSE	IF	(	HasSubstringInFULL(cnam, 'Tent')		
		OR	HasSubstringInFULL(cnam, 'Bed')		
		OR	HasSubstringInFULL(cnam, 'Camp')		
		OR	HasKeyword(cnam, 'WAF_MaterialSurvival')	
		)
		THEN	BEGIN	IF	NotHas(e, 'CCO_MiscSurvivalRecipes')							
			THEN	agvc(conditions, 'CCO_MiscSurvivalRecipes')	
			END
	ELSE	IF	NotHas(e, 'CCO_MiscOtherRecipes')								
		THEN	agvc(conditions, 'CCO_MiscOtherRecipes')					
			{ELSE}								
	{ELSE}										
	;	

	IF	(Signature(cnam) = 'ARMO')									
	THEN	IF	HasKeyword(cnam, 'ArmorJewelry')		
		OR	HasKeyword(cnam, 'ClothingCirclet')	
		OR	HasKeyword(cnam, 'ClothingNecklace')								
		OR	HasKeyword(cnam, 'ClothingRing')		
		OR	HasKeyword(cnam, 'JewelryExpensive')		
		THEN	jewelry := true								
		{ELSE}									
	{ELSE}										
	;	
	
	IF	(Signature(cnam) = 'ARMO')		
	AND	NOT	jewelry			
	AND	NotHas(e, 'CCO_OptionCraftingMenuOptions')	
	THEN	IF	(	(GetElementEditValues(cnam, 'BODT\Armor Type') = 'Clothing')							
			OR	(GetElementEditValues(cnam, 'BOD2\Armor Type') = 'Clothing')							
			OR	HasKeyword(cnam, 'ArmorClothing')							
			)						
		THEN	BEGIN	IF	NotHas(e, 'CCO_ArmorClothingRecipes')											
			THEN	agvc(conditions, 'CCO_ArmorClothingRecipes')		
			END	
	ELSE	IF	(	(GetElementEditValues(cnam, 'BODT\Armor Type') = 'Heavy Armor')						
				OR	(GetElementEditValues(cnam, 'BOD2\Armor Type') = 'Heavy Armor')						
				OR	HasKeyword(cnam, 'ArmorHeavy')						
				)							
		THEN	BEGIN	IF	NotHas(e, 'CCO_ArmorHeavyRecipes')							
			THEN	agvc(conditions, 'CCO_ArmorHeavyRecipes')		
			END	
	ELSE	IF	(	(GetElementEditValues(cnam, 'BODT\Armor Type') = 'Light Armor')					
					OR	(GetElementEditValues(cnam, 'BOD2\Armor Type') = 'Light Armor')					
					OR	HasKeyword(cnam, 'ArmorLight')					
					)			
		THEN	BEGIN	IF	NotHas(e, 'CCO_ArmorLightRecipes')										
			THEN	agvc(conditions, 'CCO_ArmorLightRecipes')	
			END							
			{ELSE}							
	{ELSE}										
	;		
	
	IF	(Signature(cnam) = 'ARMO')		
	AND	NOT	jewelry			
	AND	NOT	HasSubstringInEDID(cnam, 'MenuOption')	
	AND	(	(GetElementEditValues(cnam, 'BODT\Armor Type') = 'Clothing')								
		OR	(GetElementEditValues(cnam, 'BOD2\Armor Type') = 'Clothing')															
		)									
	THEN	IF	(	HasKeyword(cnam, 'WAF_ClothingCloak')			
			OR	HasSubstringInEDID(cnam, 'cloak')			
			OR	HasSubstringInFULL(cnam, 'cloak')		
			OR	HasSubstringInFULL(cnam, 'cape')				
			)		
		THEN	BEGIN	IF	NotHas(e, 'CCO_ClothingCloakRecipes')							
			THEN	agvc(conditions, 'CCO_ClothingCloakRecipes')		
			END
	ELSE	IF	HasKeyword(cnam, 'WAF_ClothingPouch')									
		OR	HasSubstringInFULL(cnam, 'Backpack')	
		OR	HasSubstringInFULL(cnam, 'Bandolier')	
		OR	HasSubstringInFULL(cnam, 'Bag')		
		OR	HasSubstringInFULL(cnam, 'Pouch')	
		OR	HasSubstringInFULL(cnam, 'Satchel')			
		THEN	BEGIN	IF	NotHas(e, 'CCO_ClothingPouchRecipes')							
			THEN	agvc(conditions, 'CCO_ClothingPouchRecipes')																						
			END												
	ELSE	IF	HasKeyword(cnam, 'WAF_ClothingAccessories')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_ClothingMiscAccessories')						
			THEN	agvc(conditions, 'CCO_ClothingMiscAccessories')	
			END
	ELSE	IF	HasKeyword(cnam, 'ClothingBody')			
		THEN	BEGIN	IF	NotHas(e, 'CCO_ClothingRobeRecipes')		
			THEN	agvc(conditions, 'CCO_ClothingRobeRecipes')			
			END	
	ELSE	IF	HasKeyword(cnam, 'ClothingFeet')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_ClothingBootRecipes')							
			THEN	agvc(conditions, 'CCO_ClothingBootRecipes')		
			END	
	ELSE	IF	HasKeyword(cnam, 'ClothingHands')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_ClothingGlovesRecipes')	
			THEN	agvc(conditions, 'CCO_ClothingGlovesRecipes')	
			END	
	ELSE	IF	HasKeyword(cnam, 'ClothingHead')	
		THEN	BEGIN	IF	NotHas(e, 'CCO_ClothingHoodRecipes')		
			THEN	agvc(conditions, 'CCO_ClothingHoodRecipes')		
			END
	ELSE	IF	NotHas(e, 'CCO_ClothingMiscAccessories')								
		THEN	agvc(conditions, 'CCO_ClothingMiscAccessories')		
			{ELSE}					
	{ELSE}										
	;										
	
	IF	(Signature(cnam) = 'ARMO')			
	AND	NOT	jewelry			
	AND	NOT	(GetElementEditValues(cnam, 'BODT\Armor Type') = 'Clothing')								
	AND	NOT	(GetElementEditValues(cnam, 'BOD2\Armor Type') = 'Clothing')																
	THEN	IF	HasKeyword(cnam, 'ArmorBoots')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_ArmorBootRecipes')										
			THEN	agvc(conditions, 'CCO_ArmorBootRecipes')		
			END	
	ELSE	IF	HasKeyword(cnam, 'ArmorCuirass')		
		AND	NOT	HasSubstringInEDID(cnam, 'MenuOption')
		THEN	BEGIN	IF	NotHas(e, 'CCO_ArmorCuirassRecipes')	
			THEN	agvc(conditions, 'CCO_ArmorCuirassRecipes')	
			END
	ELSE	IF	HasKeyword(cnam, 'ArmorGauntlets')			
		THEN	BEGIN	IF	NotHas(e, 'CCO_ArmorGauntletRecipes')		
			THEN	agvc(conditions, 'CCO_ArmorGauntletRecipes')	
			END
	ELSE	IF	HasKeyword(cnam, 'ArmorHelmet')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_ArmorHelmetRecipes')		
			THEN	agvc(conditions, 'CCO_ArmorHelmetRecipes')		
			END	
	ELSE	IF	HasKeyword(cnam, 'ArmorShield')		
		THEN	BEGIN	IF	NotHas(e, 'CCO_ArmorShieldRecipes')		
			THEN	agvc(conditions, 'CCO_ArmorShieldRecipes')		
			END	
	ELSE	IF	NotHas(e, 'CCO_ClothingMiscAccessories')								
		THEN	agvc(conditions, 'CCO_ClothingMiscAccessories')					
			{ELSE}					
	{ELSE}										
	;	
	
	IF	HasKeyword(cnam, 'ArmorMaterialHide')									
		OR	HasKeyword(cnam, 'ArmorMaterialScaled')									
		OR	HasKeyword(cnam, 'ArmorMaterialStudded')									
		OR	HasSubstringInFULL(cnam, 'Fur')									
		OR	HasSubstringInFULL(cnam, 'Hide')		
		OR	HasSubstringInFULL(cnam, 'Pelt')					
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryTanRack_Hide')							
			THEN	agvc(conditions, 'CCO_CategoryTanRack_Hide')		
			END
	ELSE	IF	HasSubstringInFULL(cnam, 'Leather')	
			OR	HasKeyword(cnam, 'ArmorMaterialLeather')
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryTanRack_Leather')							
			THEN	agvc(conditions, 'CCO_CategoryTanRack_Leather')		
			END		
	ELSE	IF	HasSubstringInFULL(cnam, 'Cloth')	
			OR	HasKeyword(cnam, 'ArmorClothing')
			OR	HasKeyword(cnam, 'WAF_ClothingCloak')	
			OR	HasSubstringInFULL(cnam, 'Cloak')	
			OR	HasSubstringInFULL(cnam, 'Cape')
			OR	HasSubstringInFULL(cnam, 'Linen')
		THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryTanRack_Cloth')							
			THEN	agvc(conditions, 'CCO_CategoryTanRack_Cloth')		
			END						
//	ELSE	IF	HasSubstringInFULL(cnam, 'Bone')			
//			OR	HasSubstringInFULL(cnam, 'Chitin')		
//			OR	HasSubstringInFULL(cnam, 'Scale')	
//			OR	HasSubstringInFULL(cnam, 'Wood')	
//		THEN	BEGIN	IF	NotHas(e, 'CCO_CategoryTanRackOrganics')							
//			THEN	agvc(conditions, 'CCO_CategoryTanRackOrganics')		
//			END				
	ELSE	IF	NotHas(e, 'CCO_CategoryTanRack_Misc')		
		AND	NOT	HasSubstringInEDID(cnam, 'MenuOption')	
		THEN	agvc(conditions, 'CCO_CategoryTanRack_Misc')					
			{ELSE}						
	{ELSE}										
	;	

	IF	NotHas(e, 'CCO_MODSupported')	
	AND	NotHas(e, 'CCO_OptionBreakdownEquipmentatSmelter')
	AND	NotHas(e, 'CCO_OptionBreakdownEquipmentatTanningRack')
	AND	NotHas(e, 'CCO_CCOAddedRecipes')	
	AND	NotHas(e, 'CCO_DisableIfCCOisInstalled')	
	AND	NotHas(e, 'CCO_VanillaRecipe')	
	AND	NotHas(e, 'CCO_DLCDawnguard')	
	AND	NotHas(e, 'CCO_DLCHearthfire')
	AND	NotHas(e, 'CCO_DLCDragonborn')
	AND	NotHas(e, 'CCO_MODStealthSkillsRebalanced')
	AND	NotHas(e, 'CCO_MODImmersiveArmors')
	AND	NotHas(e, 'CCO_MODImmersiveWeapons')
	AND	NotHas(e, 'CCO_MODJaysusSwords')
	AND	NotHas(e, 'CCO_MODHeavyArmory')
	AND	NotHas(e, 'CCO_MODJewelCraft')
	AND	NotHas(e, 'CCO_MODBandoliers')
	AND	NotHas(e, 'CCO_MODBookofSilence')
	AND	NotHas(e, 'CCO_MODFrostfall')
	AND	NotHas(e, 'CCO_MODWinterIsComing')
	AND	NotHas(e, 'CCO_MODCloaks')
	AND	NotHas(e, 'CCO_MODImmersiveJewelry')
	AND	NotHas(e, 'CACO_CACOAddedRecipes')
	AND	NotHas(e, 'CCO_OptionCraftingMenuOptions')	
	AND	NOT	HasSubstringInFULL(cnam, 'Fur Plate')	
	AND	NOT	HasSubstringInEDID(e, 'Breakdown')	
	AND	NOT	HasSubstringInEDID(e, 'Learn')		
	THEN	cmcs(conditions)									
	{ELSE}										
	;										
END											
;													
//=========================================================================											
// initialize script											
function Initialize: integer;											
											
VAR	i: integer;										
	s: string;										
											
BEGIN	// welcome messages										
	AddMessage(#13#10);										
	AddMessage('----------------------------------------------------------');										
	AddMessage('CCO Global Variable Application Script '+vs);										
	AddMessage('----------------------------------------------------------');										
	AddMessage('');										
	// create stringlists										
	slFiles := TStringList.Create;										
	slGlobals := TStringList.Create;										
	slMasters := TStringList.Create;										
	slMasters.Sorted := True;										
	slMasters.Duplicates := dupIgnore;										
	slMasters.Add('Skyrim.esm');										
	slMasters.Add('Update.esm');										
	FOR	i := 0									
	TO	FileCount - 1									
	DO	BEGIN	s := GetFileName(FileByIndex(i));								
			IF	(s = ccorfn)							
			THEN	slMasters.Add('CCOResource.esp')							
			ELSE	IF	(s = ccofn)						
				THEN	slMasters.Add('Complete Crafting Overhaul_Remastered.esp')						
				{ELSE}							
			{;}	;							
		END									
	;										
	// process only files										
	ScriptProcessElements := [etFile];										
END											
;											
//=========================================================================											
// load selected files into slFiles stringlist											
function Process(f: IInterface): integer;											
											
VAR	fn: string;										
	i: integer;										
	masters, master: IInterface;										
											
BEGIN	fn := GetFileName(f);										
	IF	(fn = ccofn)									
	OR	(fn = ccorfn)									
	OR	(Pos(fn, bethesdaFiles) > 0)									
	THEN	exit									
	{ELSE}										
	;										
	slFiles.AddObject(fn, TObject(f));										
	// load masters from file										
	masters := ElementByPath(ElementByIndex(f, 0), 'Master Files');										
	FOR	i := 0									
	TO	ElementCount(masters) - 1									
	DO	BEGIN	master := ElementByIndex(masters, i);								
			slMasters.Add(geev(master, 'MAST'));								
		END									
	;										
	slMasters.Add(fn);										
END											
;											
//=========================================================================											
// add CCO global variables and modify COBJ conditions											
function Finalize: integer;											
											
VAR	ccoFile, patchFile, e, ne, cf, cobj, group, conditions, cnam, cc: IInterface;										
	i, j: integer;										
	s, edid, bnam: string;										
											
BEGIN	// find cco file										
	FOR	i := 0									
	TO	FileCount - 1									
	DO	BEGIN	s := GetFileName(FileByIndex(i));								
			IF	(s = ccofn)							
			OR	(s = ccorfn)							
			THEN	ccoFile := FileByIndex(i)							
			{ELSE}								
			;								
		END									
	;										
	// if cco file not found, terminate script										
	IF	NOT	Assigned(ccoFile)								
	THEN	BEGIN	AddMessage(ccorfn + ' not found, terminating script.');								
			Result := -1;								
			exit;								
		END									
	{ELSE}										
	;										
	{ generate patchfile }										
	IF	separatepatch									
	THEN	BEGIN	AddMessage('Making a CCOR compatibility patch for the selected files.');								
			patchFile := FileSelect('Select the file you want to use as your CCOR patch '+#13#10+'file below:');								
			IF	NOT	Assigned(patchFile)						
			THEN	BEGIN	AddMessage('Patch file not assigned. Terminating script.');						
					Result := -1;						
					exit;						
				END							
			{ELSE}								
			;								
			AddMastersToFile(patchFile, slMasters, true);								
			group := GroupBySignature(ccoFile, 'GLOB');								
			FOR	i := 0							
			TO	ElementCount(group) - 1							
			DO	BEGIN	e := ElementByIndex(group, i);						
					edid := Lowercase(GetElementEditValues(e, 'EDID'));						
					IF	(Pos('cco_', edid) = 1)					
					AND	(FormID(e) < 30408704)					
					THEN	BEGIN	ne := wbCopyElementToFile(e, patchFile, True, True);				
							SetLoadOrderFormID(ne, FormID(e));				
							slGlobals.AddObject(edid, TObject(FormID(e)));				
						END					
					{ELSE}						
					;						
				END							
			;								
			AddMessage('Globals copied.');								
		END									
	{ELSE}										
	;										
	{ patch records }										
	AddMessage(#13#10+'Patching records...');										
	FOR	i := 0									
	TO	slFiles.Count - 1									
	// skip file if no COBJ records present										
	DO	BEGIN	cf := ObjectToElement(slFiles.Objects[i]);								
			cobj := GroupBySignature(cf, 'COBJ');								
			IF	NOT	Assigned(cobj)						
			THEN	Continue							
			{ELSE}								
			;								
			AddMessage('Patching '+slFiles[i]);								
			Inc(patchedfiles);								
			IF	NOT	separatepatch						
			// add masters if missing								
			THEN	BEGIN	AddMasterIfMissing(cf, 'Skyrim.esm');						
					AddMasterIfMissing(cf, 'Update.esm');						
					// copy globals from ccoFile						
					AddMessage('Copying globals...');						
					group := GroupBySignature(ccoFile, 'GLOB');						
					FOR	j := 0					
					TO	ElementCount(group) - 1					
					DO	BEGIN	e := ElementByIndex(group, j);				
							edid := Lowercase(GetElementEditValues(e, 'EDID'));				
							IF	(Pos('cco_', edid) = 1)			
							AND	(FormID(e) < 30408704)			
							THEN	BEGIN	ne := wbCopyElementToFile(e, cf, True, True);		
									SetLoadOrderFormID(ne, FormID(e));		
									IF	i = 0	
									THEN	slGlobals.AddObject(edid, TObject(FormID(e)))	
									{ELSE}		
									;		
								END			
							{ELSE}				
							;				
						END					
					;						
				END							
			{ELSE}								
			;								
			// loop through COBJ records and apply conditions								
			AddMessage('Patching COBJ records...');								
			FOR	j := 0							
			TO	ElementCount(cobj) - 1							
			DO	BEGIN	cc := nil;						
					e := ElementByIndex(cobj, j);						
					bnam := GetElementEditValues(LinksTo(ElementByPath(e, 'BNAM')), 'EDID');						
					cnam := LinksTo(ElementByPath(e, 'CNAM'));						
					// skip temper records						
					IF	(bnam = 'CraftingSmithingSharpeningWheel')					
					OR	(bnam = 'CraftingSmithingArmorTable')					
					THEN	continue					
					{ELSE}						
					;						
					// process conditions on record						
					AddMessage('... '+Name(e));						
					IF	separatepatch					
					THEN	e := wbCopyElementToFile(ElementByIndex(cobj, j), patchFile, False, True)					
					{ELSE}						
					;						
					conditions := ElementByPath(e, 'Conditions');						
					IF	NOT	Assigned(conditions)				
					THEN	BEGIN	Add(e, 'Conditions', True);				
							conditions := ElementByPath(e, 'Conditions');				
							cc := ElementByIndex(conditions, 0);				
						END					
					{ELSE}						
					;						
					IF	(bnam = 'CraftingSmithingForge')		
					OR	(bnam = 'CraftingSmithingSkyforge')
					OR	(bnam = 'DLC1LD_CraftingForgeAetherium')					
					OR	(bnam = 'DLC1CraftingDawnguard')					
					THEN	SmithingForgeConditions(cnam, conditions, e, bnam)					
					{ELSE}						
					;									
					IF	bnam = 'CraftingSmelter'					
					THEN	BEGIN	SmithingSmelterConditions(e, conditions);				
							SmithingSmelterCategoryConditions(cnam, conditions, e);						
						END					
					{ELSE}						
					;						
					IF	bnam = 'CraftingTanningRack'					
					THEN	BEGIN	TanningRackConditions(e, conditions);				
							SmithingTanningRackCategoryConditions(cnam, conditions, e);				
						END					
					{ELSE}						
					;				
//					IF	(bnam = 'BYOHBuildingInterior')		
//					OR	(bnam = 'BYOHBuildingCarpenter')					
//					THEN	BEGIN	TanningRackConditions(e, conditions);				
//							SmithingTanningRackCategoryConditions(cnam, conditions, e);				
//						END					
//					{ELSE}						
//					;					
					IF	Assigned(cc)					
					THEN	Remove(cc)					
					{ELSE}						
					;						
				END							
			;								
		END									
	;										
//	AddMessage(#13#10'Removing '+GetFileName(ccoFile)+' master from patch file.');										
//	RemoveMaster(patchfile, GetFileName(ccoFile));										
	// final messages										
	AddMessage(#13#10);										
	AddMessage('----------------------------------------------------------');										
	AddMessage('The CCOR Compatibility Script is done.');										
	IF	patchedfiles = 1									
	THEN	AddMessage('Made 1 file compatible.')									
	ELSE	IF	patchedfiles > 1								
		THEN	AddMessage('Made '+IntToStr(patchedfiles)+' files compatible.')								
		{ELSE}									
	{;}	;									
	AddMessage(#13#10);										
END											
;											
END.