params ["_Position","_NomZone","_Taille","_ModeFronts"];

_rnum = str(round (random 999));

//Positionnement de la cible
//--------------------------Création de marqueur----------------------------------
_marqueurzonedecombat = [(_this select 0),(_this select 2),"colorOPFOR"] call fnc_objectif_creermarqueur;
_marqueurzonedecombat setMarkerAlpha var_mission_transparance_marqueur;
if(hdssysteme)then{_marqueurzonedecombat setMarkerAlpha 1};

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
_tachetitre = (_this select 1);
_tacheDesc = "Capturer et sécuriser la zone";

if(hdssysteme)then{
  [true,[_tache],[_tacheDesc,_tachetitre],(_marqueurzonedecombat call BIS_fnc_randomPosTrigger),0,2,true,"attack"] call BIS_fnc_taskCreate;
}else{
  [true,[_tache],[_tacheDesc,_tachetitre],objnull,0,2,true,"attack"] call BIS_fnc_taskCreate;
};
//----------------------------------------------------------------------------------

waitUntil {Triggeractivated _Declencheur};

//------------------Création du trigger de vérification
[_tache,'SUCCEEDED',true] call BIS_fnc_taskSetState;

[_tache] call BIS_fnc_taskCompleted;
deleteMarker _marqueurzonedecombat;
deleteVehicle _declencheur;                                          //Supprime le marquer sur carte

if((_this select 3)isequalto false) then {
tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";
};
true
