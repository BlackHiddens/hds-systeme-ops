params ["_Centre","_Ratio","_Taille","_Visible"];

_Ratio = _this select 1;
_Taille = _this select 2;
_Visible = _this select 3;
//--------------------Création du marqueur de mission------------------------


_rnum = str(round (random 999));
_NomMarqueur = format ["OccupationH_%1",_rnum];
_MarkerZone = createMarker [_NomMarqueur,(_this select 0)];
_MarkerZone setMarkerShape "Ellipse";
_MarkerZone setMarkerSize [(_Taille + 100),(_Taille + 100)];
_MarkerZone setMarkerColor "colorOPFOR";
_MarkerZone setMarkerBrush "Border";
//----------------------------------------------------------------------------------

//Rend visible ou invisible selon le paramètre _Visible le Marqueur afficher sur la carte
if (_Visible isEqualto true) then {_MarkerZone setMarkerAlpha 0.15} else {_MarkerZone setMarkerAlpha 0.0};
//----------------------Stabilisation du ratio de personnels et autres variables---------------
//Cela évite qu'un fort ratio ne face apparaitre des groupes de trop grande taille
_NbPersonnels = round (_Taille / 130);
if (_NbPersonnels > 5) then {_NbPersonnels = 5};
if (_NbPersonnels < 3) then {_NbPersonnels = 3};
//----------------------Création d'infanterie opfor------------------------
if(hdssysteme)then{["hds-système : Création des patrouilles en cours"] remoteexeccall ["systemChat",0]};
for "_i" from 1 to round (_Ratio + (round random _Ratio)) do {
  _SpawnPosition = _NomMarqueur call bis_fnc_randomPosTrigger;
  if(surfaceIsWater _SpawnPosition) then {
    _Groupes= [_NomMarqueur call bis_fnc_randomPosTrigger,independent,(configfile >>  "CfgGroups" >> "independent" >> "IND_F" >> "SpecOps" >> "HAF_DiverTeam_Boat")] call BIS_fnc_spawnGroup;
    [_Groupes,(_this select 0),_Taille] call bis_fnc_taskpatrol;
    _Groupes enableDynamicSimulation true;
  }else{
    _Groupes = [_NomMarqueur call bis_fnc_randomPosTrigger,independent,_NbPersonnels] call BIS_fnc_spawnGroup;
    [_Groupes,(_this select 0),_Taille] call bis_fnc_taskpatrol;
    _Groupes enableDynamicSimulation true;
  };
  sleep 0.5;
};
if(hdssysteme)then{["hds-système : Création des patrouilles terminée"] remoteexeccall ["systemChat",0]};

/* _Condition = "this";
_QuandActiver = "
_VehiculeCree = [([getpos thistrigger,1500,1000,1,0,60,0] call BIS_fnc_findSafePos),180,(SelectRandom ['O_Heli_Light_02_unarmed_F']),independant] call bis_fnc_spawnvehicle;
_Troupes = [([getpos thistrigger,1500,1000,1,0,60,0] call BIS_fnc_findSafePos),independant,5] call BIS_fnc_spawnGroup;
createVehicleCrew (_VehiculeCree select 0);
{_x moveInCargo (_VehiculeCree select 0)} foreach Units _Troupes;
_itineraire_depart = _VehiculeCree select 2 addWaypoint [getpos thistrigger,0];
_itineraire_depart setWaypointType 'TR UNLOAD';
_itineraire_retour = _VehiculeCree select 2 addWaypoint [([getpos thistrigger,2000,1500,1,0,60,0] call BIS_fnc_findSafePos),0];
_itineraire_retour setWaypointType 'GETOUT';
";

_Declencheur = createTrigger ["EmptyDetector",(_this select 0)];
_Declencheur setTriggerArea [_Taille,_Taille, 0,false];
_Declencheur setTriggerActivation ["WEST", "GUER D",false];
_Declencheur setTriggerStatements [_Condition,_QuandActiver,""];

waitUntil {triggerActivated _Declencheur}; */
