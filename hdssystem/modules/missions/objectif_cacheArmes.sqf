params ["_Position","_NomCache","_Taille"];

_rnum = str(round (random 999));

_marqueurzonedecombat = [(_this select 0),(_this select 2),"colorOPFOR"] call fnc_objectif_creermarqueur;
_marqueurdemission = [((_marqueurzonedecombat call bis_fnc_randomPosTrigger)),(_this select 2),"colorOPFOR"] call fnc_objectif_creermarqueur;

_marqueurzonedecombat setMarkerAlpha 0;
_marqueurdemission setMarkerAlpha var_mission_transparance_marqueur;

if(hdssysteme)then{_marqueurzonedecombat setMarkerAlpha 1};
if(hdssysteme)then{_marqueurdemission setMarkerAlpha 1};

_CacheTable = ["C_T_supplyCrate_F","C_IDAP_supplyCrate_F"];
_CacheSelectionner = selectRandom _CacheTable;

//création de la cache à détruire
_Cache = _CacheSelectionner createVehicle ([_marqueurdemission] call BIS_fnc_randomPosTrigger);

//Positionnement de la cible
//--------Début des vérifications-----------------
_TousObjetsTrouve = [(_this select 2),getpos _Cache,['house']] call fnc_objectif_liste_batimentsetplaces;
if(count _TousObjetsTrouve isequalto 0)exitWith{
  tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";
  deleteMarker _marqueurdemission;
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
//----------Fin-------------------
_Poste_dans_batiment = selectrandom ([_Un_Batiment_occupable] call BIS_fnc_buildingPositions);
_Cache setPos _Poste_dans_batiment;                                        //Place l'otage au coordonnées choisi

//creation de la tache
_tache = "TacheCache" + _rnum + str((_this select 0));
_tachetitre = (_this select 1);
_tacheDesc = format ["Détruire %1 se trouvant dans la zone d'opération",(_this select 1)];

if(hdssysteme)then{
  [true,[_tache],[_tacheDesc,_tachetitre],(_marqueurzonedecombat call BIS_fnc_randomPosTrigger),0,2,true,"box"] call BIS_fnc_taskCreate;
}else{
  [true,[_tache],[_tacheDesc,_tachetitre],objnull,0,2,true,"box"] call BIS_fnc_taskCreate;
};
//--------------------------------------------Condition de fin de mission-----------------------------------
//Attendre que la caisse soit complètement détruite
waitUntil {!alive _Cache || [_tache] call BIS_fnc_taskCompleted};

if (!alive _Cache) then {
  [_tache,'SUCCEEDED',true] call BIS_fnc_taskSetState;

};

deleteMarker _marqueurdemission;                                               //Supprime le marquer sur carte
deleteMarker _marqueurzonedecombat;


tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";
true
