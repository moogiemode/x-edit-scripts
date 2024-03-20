unit __SMMWorkshopMenuPatch;

uses praFunctions;

var
  vanillaMenuFilters: TStringList;

//============================================================================

function Initialize: integer;
	begin
		vanillaMenuFilters := TStringList.create;

		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02BallTrack');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02BallTrack03Curves');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02BallTrack03Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02BallTrack03Straight');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Barn');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Barn03Doors');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Barn03Floor');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Barn03Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Barn03Prefabs');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Barn03Roof');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Barn03Stairs');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Barn03Wall');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Boxcars');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Boxcars03Blue');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Boxcars03Orange');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Brick');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Brick03Floor');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Brick03Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Brick03Prefabs');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Brick03Roof');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Brick03Stairs');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Brick03Wall');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Concrete');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Concrete03Floor');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Concrete03Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Concrete03Prefabs');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Concrete03Roof');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Concrete03Stairs');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Concrete03Wall');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Doors');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Elevators');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Fences');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Fences03Junk');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Fences03Picket');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Fences03Wire');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Metal');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Metal03Floor');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Metal03Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Metal03Prefabs');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Metal03Roof');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Metal03Stairs');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Metal03Wall');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Scaffolding');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Scaffolding03Doors');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Scaffolding03Floor');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Scaffolding03Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Scaffolding03Prefabs');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Scaffolding03Roof');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Scaffolding03Stairs');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Scaffolding03Wall');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Warehouse');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Warehouse03Doors');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Warehouse03Floor');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Warehouse03Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Warehouse03Prefabs');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Warehouse03Roof');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Warehouse03Stairs');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Warehouse03Wall');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Wood');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Wood03Floor');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Wood03Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Wood03Prefabs');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Wood03Roof');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Wood03Stairs');
		vanillaMenuFilters.add('WorkshopRecipeFilterBuilding02Wood03Wall');
		vanillaMenuFilters.add('WorkshopRecipeFilterCages');
		vanillaMenuFilters.add('WorkshopRecipeFilterCrafting');
		vanillaMenuFilters.add('WorkshopRecipeFilterCreationClub');
		vanillaMenuFilters.add('WorkshopRecipeFilterCreationClub02ccBGSFO4045');
		vanillaMenuFilters.add('WorkshopRecipeFilterCreationClub02ccEEJFO4001');
		vanillaMenuFilters.add('WorkshopRecipeFilterCreationClub02ccEEJFO4002');
		vanillaMenuFilters.add('WorkshopRecipeFilterCreationClub02ccFSVFO4001');
		vanillaMenuFilters.add('WorkshopRecipeFilterCreationClub02ccFSVFO4003');
		vanillaMenuFilters.add('WorkshopRecipeFilterCreationClub02ccFSVFO4004GNRPlaza');
		vanillaMenuFilters.add('WorkshopRecipeFilterCreationClub02ccFSVFO4005DesertIsland');
		vanillaMenuFilters.add('WorkshopRecipeFilterCreationClub02ccKGJFO4001');
		vanillaMenuFilters.add('WorkshopRecipeFilterCreationClub02ccTOSFO4001');
		vanillaMenuFilters.add('WorkshopRecipeFilterCreationClub02ccTOSFO4002');
		vanillaMenuFilters.add('WorkshopRecipeFilterCreationClub02ccVRWorkshops');
		vanillaMenuFilters.add('WorkshopRecipeFilterCreationClub02ccVRWorkshopsAttackMarkers');
		vanillaMenuFilters.add('WorkshopRecipeFilterCreationClub02ccVRWorkshopsMisc');
		vanillaMenuFilters.add('WorkshopRecipeFilterCreationClub02ccVRWorkshopsPods');
		vanillaMenuFilters.add('WorkshopRecipeFilterCreationClub02Holiday');
		vanillaMenuFilters.add('WorkshopRecipeFilterCreationClub02Holiday03ccJVDFO4001');
		vanillaMenuFilters.add('WorkshopRecipeFilterCreationClub02HolidayChristmas');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02DisplayCases');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02DisplayCases03ArmorRacks');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02DisplayCases03DisplayCases');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02DisplayCases03PowerArmor');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02DisplayCases03WeaponRacks');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02Floor');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02NukaWorld');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02NukaWorld03BottlingPlant');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02NukaWorld03DryRock');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02NukaWorld03Galactic');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02NukaWorld03Kiddie');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02NukaWorld03Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02NukaWorld03NukaCade');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02NukaWorld03Nukatown');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02NukaWorld03Safari');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02Statues');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02Vault');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02Vault03Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02Vault03Posters');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02Vault03Signs');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02Vault03Statues');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02WallDecorations');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02WallDecorations03Flags');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02WallDecorations03Lettering');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02WallDecorations03Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02WallDecorations03MountedCreatures');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02WallDecorations03Paintings');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02WallDecorations03Posters');
		vanillaMenuFilters.add('WorkshopRecipeFilterDecor02WallDecorations03Signs');
		vanillaMenuFilters.add('WorkshopRecipeFilterFurniture');
		vanillaMenuFilters.add('WorkshopRecipeFilterFurniture02Beds');
		vanillaMenuFilters.add('WorkshopRecipeFilterFurniture02Chairs');
		vanillaMenuFilters.add('WorkshopRecipeFilterFurniture02Containers');
		vanillaMenuFilters.add('WorkshopRecipeFilterFurniture02Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterFurniture02Shelves');
		vanillaMenuFilters.add('WorkshopRecipeFilterFurniture02Tables');
		vanillaMenuFilters.add('WorkshopRecipeFilterMisc');
		vanillaMenuFilters.add('WorkshopRecipeFilterQuest');
		vanillaMenuFilters.add('WorkshopRecipeFilterRaider');
		vanillaMenuFilters.add('WorkshopRecipeFilterRaider02Disciples');
		vanillaMenuFilters.add('WorkshopRecipeFilterRaider02Flags');
		vanillaMenuFilters.add('WorkshopRecipeFilterRaider02Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterRaider02Operators');
		vanillaMenuFilters.add('WorkshopRecipeFilterRaider02Pack');
		vanillaMenuFilters.add('WorkshopRecipeFilterRaider02Resources');
		vanillaMenuFilters.add('WorkshopRecipeFilterRaider02Vendor');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Defense');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Food');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03AdvancedSwitches');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03ArcadeCabinets');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03ArcadeCabinets04AtomicCommand');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03ArcadeCabinets04Automatron');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03ArcadeCabinets04Grognak');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03ArcadeCabinets04Pipfall');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03ArcadeCabinets04RedMenace');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03ArcadeCabinets04ZetaInvaders');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03Conduit');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03Connectors');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03Generators');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03Lights');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03Manufacturing');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03Manufacturing04ConveyorBelts');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03Manufacturing04Machinery');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03Manufacturing04Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03Marquee');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03NeonLights');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Power03Wire');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Vault');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource02Water');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource03DefenseGuardPosts');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource03DefenseTraps');
		vanillaMenuFilters.add('WorkshopRecipeFilterResource03DefenseTurrets');
		vanillaMenuFilters.add('WorkshopRecipeFilterScrap');
		vanillaMenuFilters.add('WorkshopRecipeFilterVendor');
		vanillaMenuFilters.add('WorkshopRecipeFilterVendor02Armor');
		vanillaMenuFilters.add('WorkshopRecipeFilterVendor02Bar');
		vanillaMenuFilters.add('WorkshopRecipeFilterVendor02Clinic');
		vanillaMenuFilters.add('WorkshopRecipeFilterVendor02Clothing');
		vanillaMenuFilters.add('WorkshopRecipeFilterVendor02Misc');
		vanillaMenuFilters.add('WorkshopRecipeFilterVendor02Weapons');

	end;

//============================================================================

function Process(e: IInterface): integer;
var
    recipe, recipeCondition, recipeItem, items, currentKeyword: IInterface;

begin
    if (signature(e) <> 'COBJ') then begin exit; end;

    // Find the keywords of the record

		if( hasAnyKeyword(e, vanillaMenuFilters, 'FNAM') ) then begin
			AddMessage('Removing ' + GetElementEditValues(e, 'EDID'));
			exit;
		end;

end;

end.