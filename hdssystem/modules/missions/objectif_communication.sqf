params ["_centre","_NomCible","_Taille"];

_rnum = str(round (random 999));

_marqueurzonedecombat = [(_this select 0),(_this select 2),"colorOPFOR"] call fnc_objectif_creermarqueur;
_marqueurdemission = [((_marqueurzonedecombat call bis_fnc_randomPosTrigger)),(_this select 2),"colorOPFOR"] call fnc_objectif_creermarqueur;

_marqueurzonedecombat setMarkerAlpha 0;
_marqueurdemission setMarkerAlpha var_mission_transparance_marqueur;

if(hdssysteme)then{_marqueurzonedecombat setMarkerAlpha 1};
if(hdssysteme)then{_marqueurdemission setMarkerAlpha 1};
_TourTable = ["Land_TTowerSmall_2_F","Land_Communication_F","Land_TTowerSmall_1_F"];
_TourSelect = selectRandom _TourTable;

//[_marqueurdemission,2,(_this select 2),1,0,20,0] call BIS_fnc_findSafePos
//création de l'homme à abattre
_Tour = _TourSelect createVehicle ([_marqueurdemission] call BIS_fnc_randomPosTrigger);  //Cible
_veh_nom = getText (configFile >> "cfgVehicles" >> (_TourSelect) >> "displayName");
_nomvariable = format ["Tour%1",_rnum];
_Tour setdammage 0.50;
//[vip2,getmarkerpos _marqueurdemission,_GrandeurZone] call CBA_fnc_taskPatrol; // L'officier patrouille avec ses gardes

//creation de la tache
_tache = "Tache_Hacker" + _rnum + str(_this select 0);
_tachetitre = (_this select 1);
_tacheDesc = format ["%1 doit être détruit",_NomCible];

if(hdssysteme)then{
  [true,[_tache],[_tacheDesc,_tachetitre],(_marqueurzonedecombat call BIS_fnc_randomPosTrigger),0,2,true,"destroy"] call BIS_fnc_taskCreate;
}else{
  [true,[_tache],[_tacheDesc,_tachetitre],objnull,0,2,true,"destroy"] call BIS_fnc_taskCreate;
};
//_Connexion = ("Identifiant_" + _rnum);
//Connexion setVehicleVarName _Connexion;
//[_tache,_Tour] call fnc_piratage;
_UnDesJoueur = selectRandom allPlayers;

While {alive _Tour} do {
  [format ["Capteur de distance %1",(leader selectRandom allplayers) distance _Tour]] remoteExec ["hintSilent",0];
  sleep 5;
};

  waitUntil {!alive _Tour};
  [_tache,'SUCCEEDED',true] call BIS_fnc_taskSetState;


  waitUntil{[_tache] call BIS_fnc_taskCompleted}; // Nettoage de la tache


  deleteMarker _marqueurdemission;
  deleteMarker _marqueurzonedecombat;

  tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";
  true
