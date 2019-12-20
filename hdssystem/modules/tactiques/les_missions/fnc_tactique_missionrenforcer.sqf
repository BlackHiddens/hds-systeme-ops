params ["_centre","_vehiculeTT","_Listegroupes"];
if(hdssysteme)then{[format["%1 : Transport exécute insertion sur point insert",hdstactiqueversion]] remoteexeccall ['systemChat',0]};
//Bouger afin de débarquer des troupes de renfort
_pointintertion = ([(_this select 0),100,150,1,0,30,0] call BIS_fnc_findSafePos);
_itineraire_insertion = ((_this select 1) select 2) addWaypoint [_pointintertion,10];
_itineraire_insertion setWaypointType 'TR UNLOAD';
//Une fois cela fait, rouler pour sortir de la zone d'opération
_pointextraction = ([(_this select 0),700,800,1,0,60,0] call BIS_fnc_findSafePos);
_itineraire_extraction = ((_this select 1) select 2) addWaypoint [_pointextraction,0];
_itineraire_extraction setWaypointType 'MOVE';

{[_x,(_this select 0)] call bis_fnc_taskAttack} foreach (_this select 2);

waituntil {((_this select 1) select 0) inarea [_pointextraction,100,100,0,false,-1] or (!alive ((_this select 1) select 0))};
if(hdssysteme)then{[format["%1 : Transport exécute extraction vers point extrat",hdstactiqueversion]] remoteexeccall ['systemChat',0]};

{[_x,(_this select 0)] call bis_fnc_taskDefend} foreach (_this select 2);
//Une fois sortie du secteur  supprimer l'équipage et le véhicule si il est toujours en vie
if(alive ((_this select 1) select 0))then{
  {deletevehicle _x} foreach crew ((_this select 1) select 0);
  deleteVehicle ((_this select 1) select 0);
};

true
