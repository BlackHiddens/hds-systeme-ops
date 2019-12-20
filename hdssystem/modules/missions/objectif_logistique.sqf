params ["_pos_mission","_NomCible","_Taille"];

_rnum = str(round (random 999));

_marqueurzonedecombat = [(_this select 0),(_this select 2),"colorOPFOR"] call fnc_objectif_creermarqueur;
_marqueurdemission = [((_marqueurzonedecombat call bis_fnc_randomPosTrigger)),(_this select 2),"colorOPFOR"] call fnc_objectif_creermarqueur;

_marqueurzonedecombat setMarkerAlpha 0;
_marqueurdemission setMarkerAlpha var_mission_transparance_marqueur;

if(hdssysteme)then{_marqueurzonedecombat setMarkerAlpha 1};
if(hdssysteme)then{_marqueurdemission setMarkerAlpha 1};

//création du véhicule
//if (surfaceType (_marqueurdemission call bis_fnc_randomPosTrigger) == "SurfWater") then {/*Cree le vehicule marin*/};
_ListeRoutes = ((_this select 0) nearRoads (_this select 2));
_PositionDuVehicule = [(_this select 0),(_this select 2),(_this select 2),2,0,30,0] call BIS_fnc_findSafePos;
if (surfaceIsWater _PositionDuVehicule) then {

  _VehiculeTable = ["C_Boat_Civil_04_F"];
  _VehiculeSelect = selectRandom _VehiculeTable;
  _Vehicule = _VehiculeSelect createVehicle _PositionDuVehicule;  //Cible



  waitUntil {!alive _Vehicule || [_tache] call BIS_fnc_taskCompleted };
    [_tache,'SUCCEEDED',true] call BIS_fnc_taskSetState;

    waitUntil{[_tache] call BIS_fnc_taskCompleted}; // Nettoage de la tache


    deleteMarker _marqueurdemission;
    deleteMarker _marqueurzonedecombat;

    sleep 5;
    [_tache] call BIS_fnc_deleteTask;

    tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";

}else{

  _VehiculeTable = ["O_Truck_03_device_F","O_Truck_03_repair_F","O_Truck_03_ammo_F","O_Truck_03_fuel_F"];
  _VehiculeSelect = selectRandom _VehiculeTable;

  _Vehicule = _VehiculeSelect createVehicle _PositionDuVehicule;  //Cible
  _veh_nom = getText (configFile >> "cfgVehicles" >> (_VehiculeSelect) >> "displayName");
  _nomvariable = format ["Vehicle%1",_rnum];
  _Vehicule setVehicleVarName _nomvariable;// _VehiculeCible = _Vehicule;
  missionNamespace setVariable [_nomvariable,_Vehicule];

  //creation de la tache

  _tache = "Tache_Detruire" + _rnum + str((_this select 0));
_tachetitre = (_this select 1);
  _tacheDesc = format ["%1 est un élément de logistique prioritaire. détruisez-le",_NomCible];

  if(hdssysteme)then{
    [true,[_tache],[_tacheDesc,_tachetitre],(_marqueurzonedecombat call BIS_fnc_randomPosTrigger),0,2,true,"destroy"] call BIS_fnc_taskCreate;
  }else{
    [true,[_tache],[_tacheDesc,_tachetitre],objnull,0,2,true,"destroy"] call BIS_fnc_taskCreate;
  };

    waitUntil {!alive _Vehicule || [_tache] call BIS_fnc_taskCompleted };
    [_tache,'SUCCEEDED',true] call BIS_fnc_taskSetState;

    waitUntil{[_tache] call BIS_fnc_taskCompleted}; // Nettoage de la tache

    deleteMarker _marqueurdemission;                                               //Supprime le marquer sur carte
    deleteMarker _marqueurzonedecombat;

    tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";

};

true
