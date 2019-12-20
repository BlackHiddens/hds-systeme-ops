params ["_Position","_NomZone","_Taille"];

_rnum = str(round (random 999));

//Positionnement de la cible
//--------------------------Création de marqueur----------------------------------

_marqueurzonedecombat = createMarker [(format ["SecuriserM_%1",_rnum]),(_this select 0)];
_marqueurzonedecombat setMarkerShape "Ellipse";
_marqueurzonedecombat setMarkerSize [(_this select 2),(_this select 2)];
_marqueurzonedecombat setMarkerColor "colorOPFOR";
_marqueurzonedecombat setMarkerBrush "FDiagonal";
_marqueurzonedecombat setMarkerAlpha 0.3;
//--------------------------------------------------------------------------------

//Créatiion du trigger
_condition = format ["this"];
_quandactiver = "";
_quanddesactiver = "";

_declencheur = createtrigger ["emptydetector",(_this select 0)];
_declencheur settriggerarea [(_this select 2),(_this select 2),0,false,30];
_declencheur settriggeractivation ["WEST SEIZED","present",true];
_declencheur setTriggerStatements [_condition,_quandactiver,_quanddesactiver];

//-------------------------Création de la tache pour les joueurs------------------
_tache = "TacheCapturer" + _rnum;
_tachetitre = format ["Controler|%1", _NomZone];
_tacheDesc = "Capturer et sécuriser la zone";
[true,[_tache],[_tacheDesc,_tachetitre],(_marqueurzonedecombat call BIS_fnc_randomPosTrigger),0,2,true,"attack"] call BIS_fnc_taskCreate;
//----------------------------------------------------------------------------------

waitUntil {Triggeractivated _Declencheur};

//------------------Création du trigger de vérification
[_tache,'SUCCEEDED',true] call BIS_fnc_taskSetState;

[_tache] call BIS_fnc_taskCompleted;
deleteMarker _marqueurzonedecombat;
deleteVehicle _declencheur;                                          //Supprime le marquer sur carte
sleep 1;
//[_tache] call BIS_fnc_deleteTask;

tache_scenario = tache_scenario + 1;
