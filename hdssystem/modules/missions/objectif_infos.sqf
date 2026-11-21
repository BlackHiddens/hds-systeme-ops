Private ["_pos_mission","_nom_infos","_Taille"];

_rnum = str(round (random 999));

_marqueurzonedecombat = [(_this select 0),(_this select 2),"colorOPFOR"] call fnc_objectif_creermarqueur;
_marqueurdemission = [((_marqueurzonedecombat call bis_fnc_randomPosTrigger)),(_this select 2),"colorOPFOR"] call fnc_objectif_creermarqueur;

_marqueurzonedecombat setMarkerAlpha 0;
_marqueurdemission setMarkerAlpha var_mission_transparance_marqueur;

[_marqueurzonedecombat, 0] call hds_fnc_debugMarqueur;
[_marqueurdemission, var_mission_transparance_marqueur] call hds_fnc_debugMarqueur;

_infosTable = ["Land_Suitcase_F","Land_PlasticCase_01_large_F","Land_PlasticCase_01_medium_F","Land_PlasticCase_01_small_F","Land_MetalCase_01_large_F","Land_MetalCase_01_medium_F","Land_MetalCase_01_small_F","Land_PCSet_01_case_F"];
_infosselectionner = selectRandom _infosTAble;



//création de l'information
_intelobj = createVehicle ["Land_PlasticCase_01_small_F",_marqueurdemission call BIS_fnc_randomPosTrigger, [], 0, "CAN_COLLIDE"];
if(isnil "_intelobj") exitWith {
  nombre_de_missions = nombre_de_missions - 1;
  publicVariable "nombre_de_missions";
};
_veh_nom = getText (configFile >> "cfgVehicles" >> (_infosselectionner) >> "displayName");
_nomvariable = ("hiddens_infos" + _rnum);
_intelobj setVehicleVarName _nomvariable;
missionNamespace setVariable [_nomvariable,_intelobj];
publicVariable _nomvariable;



//Positionnement de la cible
//--------Début des vérifications-----------------
_TousObjetsTrouve = [(_this select 2),getpos _intelobj,['house']] call fnc_objectif_liste_batimentsetplaces;
if(count _TousObjetsTrouve isequalto 0)exitWith{
  tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";
  deleteMarker _marqueurdemission;                                               //Supprime le marquer sur carte
  deleteMarker _marqueurzonedecombat;
  if(hdssysteme)then{[format["%1 : L'une des tâche n'a pas pu être créée",hdsversion]] remoteexeccall ['systemChat',0]};
};
_Un_Batiment_occupable = selectrandom (_TousObjetsTrouve select 0);
if(isnil "_Un_Batiment_occupable")exitWith{
  tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";
  deleteMarker _marqueurdemission;
  deleteMarker _marqueurzonedecombat;
  if(hdssysteme)then{[format["%1 : L'une des tâche n'a pas pu être créée",hdsversion]] remoteexeccall ['systemChat',0]};
};
//--------Fin------------------------------
_Poste_dans_batiment = selectrandom ([_Un_Batiment_occupable] call BIS_fnc_buildingPositions);
_intelobj setPos _Poste_dans_batiment;                                    //Place l'objet au coordonnées selectionné


//creation de la tache
_tache = "Tache_infos" + _rnum;
_tachetitre = (_this select 1);
_tacheDesc = format ["Rechercher la %1 dans la zone d'opération",_veh_nom];

// La tache est creee sans destination : c'est hds_fnc_debugTache
// qui pose le repere quand le mode debug est allume, et qui le
// retire dans la seconde s'il est decoche.
[true,[_tache],[_tacheDesc,_tachetitre],objnull,0,2,true,"intel"] call BIS_fnc_taskCreate;
[_tache, (_marqueurzonedecombat call BIS_fnc_randomPosTrigger)] call hds_fnc_debugTache;
//création de l'add action pour récuperer les documents
_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa";
[_intelobj,"Récupérer",_Icone,_Icone,"_this distance _target < 2","_this distance _target < 2",{},{},
  {
  deleteVehicle _target;
  },
{},[],3,0,true,false] remoteExec ["BIS_fnc_holdActionAdd",0,_intelobj];

//Attend que la tache soit effectué ou que l'objet n'existe plus
waitUntil {!alive _intelobj ||[_tache] call BIS_fnc_taskCompleted}; // Si la tache est accomplie
if (!alive _intelobj) then {
  [_tache,'SUCCEEDED',true] call BIS_fnc_taskSetState;
};
deleteMarker _marqueurdemission;                                               //Supprime le marquer sur carte
deleteMarker _marqueurzonedecombat;


tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";
true
