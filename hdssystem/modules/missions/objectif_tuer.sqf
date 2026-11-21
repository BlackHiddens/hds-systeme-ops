params ["_pos_mission","_NomCible","_Taille"];
_rnum = str(round (random 999));

//La ZoneAttaque est une zone invisible pour placer aléatoirement le vrai marqueur visible

_marqueurzonedecombat = [(_this select 0),(_this select 2),"colorOPFOR"] call fnc_objectif_creermarqueur;
_marqueurdemission = [((_marqueurzonedecombat call bis_fnc_randomPosTrigger)),(_this select 2),"colorOPFOR"] call fnc_objectif_creermarqueur;

_marqueurzonedecombat setMarkerAlpha 0;
_marqueurdemission setMarkerAlpha var_mission_transparance_marqueur;

[_marqueurzonedecombat, 0] call hds_fnc_debugMarqueur;
[_marqueurdemission, var_mission_transparance_marqueur] call hds_fnc_debugMarqueur;

_HommeTable = ["O_officer_F"];
_HommeSelectionner = selectRandom _HommeTable;

//création de l'homme à abattre
_groupe = createGroup east;
_HommeCible = _groupe createUnit [_HommeSelectionner,_marqueurdemission call BIS_fnc_randomPosTrigger, [],((_this select 2) - 100), "NONE"]; //Cible
_HommeCible forceSpeed 0;

_nomvariable = ("hiddens_tuer" + _rnum);
_HommeCible setVehicleVarName _nomvariable;
missionNamespace setVariable [_nomvariable,_HommeCible];
publicVariable _nomvariable;


//Positionnement de la cible
//--------Début des vérifications-----------------
_TousObjetsTrouve = [(_this select 2),getpos _HommeCible,['house']] call fnc_objectif_liste_batimentsetplaces;
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
//--------Fin-----------------
_Poste_dans_batiment = selectrandom ([_Un_Batiment_occupable] call BIS_fnc_buildingPositions);
_HommeCible setPos _Poste_dans_batiment;                                     //Place l'objet au coordonnées selectionné

//creation de la tache
_tache = "Tache_tuer" + _rnum;
_tachetitre = (_this select 1);
_tacheDesc = format ["Eliminer %1 probablement présent dans la zone",_NomCible];
missionNamespace setVariable [_tache,_tache];
publicVariable _tache;

//Génération de la tache sur carte
// La tache est creee sans destination : c'est hds_fnc_debugTache
// qui pose le repere quand le mode debug est allume, et qui le
// retire dans la seconde s'il est decoche.
[true,[_tache],[_tacheDesc,_tachetitre],objnull,0,2,true,"kill"] call BIS_fnc_taskCreate;
[_tache, (_marqueurzonedecombat call BIS_fnc_randomPosTrigger)] call hds_fnc_debugTache;

//Attente que la cible soit tuée
waitUntil {!alive _HommeCible};
[_tache,'SUCCEEDED',true] call BIS_fnc_taskSetState;                  //Complete la tache

waitUntil{[_tache] call BIS_fnc_taskCompleted};

deleteMarker _marqueurdemission;                                               //Supprime le marquer sur carte
deleteMarker _marqueurzonedecombat;

tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";
true
