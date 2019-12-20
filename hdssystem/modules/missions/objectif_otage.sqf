params ["_pos_mission","_NomCible","_Taille"];

_rnum = str(round (random 999));

//La ZoneAttaque est une zone invisible pour placer le vrai marqueur visible

_marqueurzonedecombat = [(_this select 0),(_this select 2),"colorOPFOR"] call fnc_objectif_creermarqueur;
_marqueurdemission = [((_marqueurzonedecombat call bis_fnc_randomPosTrigger)),(_this select 2),"colorOPFOR"] call fnc_objectif_creermarqueur;

_marqueurzonedecombat setMarkerAlpha 0;
_marqueurdemission setMarkerAlpha var_mission_transparance_marqueur;

if(hdssysteme)then{_marqueurzonedecombat setMarkerAlpha 1};
if(hdssysteme)then{_marqueurdemission setMarkerAlpha 1};

_HommeTable = ["I_Survivor_F","C_man_pilot_F","C_IDAP_Pilot_01_F","I_pilot_F","B_Helipilot_F","B_Survivor_F","B_Pilot_F"];
_HommeSelectionner = selectRandom _HommeTable;


//création de l'homme à sauver
_groupe = createGroup blufor;
_HommeOtage = _groupe createUnit [_HommeSelectionner,_marqueurdemission call BIS_fnc_randomPosTrigger, [],((_this select 2) - 100), "NONE"]; //Cible
_HommeOtage setcaptive true;
_HommeOtage switchmove "Acts_AidlPsitMstpSsurWnonDnon01";

//Positionnement de la cible
//--------Début des vérifications-----------------
_TousObjetsTrouve = [(_this select 2),getpos _HommeOtage,['house']] call fnc_objectif_liste_batimentsetplaces;
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
//-------------Fin-----------
_Poste_dans_batiment = selectrandom ([_Un_Batiment_occupable] call BIS_fnc_buildingPositions);
_HommeOtage setPos _Poste_dans_batiment;                                   //Place l'otage au coordonnées choisi

//Ajout de l'addAction à l'otage
_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa";
[_HommeOtage,"Libérer",_Icone,_Icone,"_this distance _target < 2","_this distance _target < 2",
  {},
  {},
  {[group _caller,_caller] remoteExec ["selectLeader", groupOwner group _caller];
  _target playmove "Acts_AidlPsitMstpSsurWnonDnon_out";
  _target setCaptive false;
  [_target] join (group _caller);
    },
{},[],6,0,true,false] remoteExec ["BIS_fnc_holdActionAdd",0,_HommeOtage];

//creation de la tache
_tache = "TacheOtage" + _rnum + str((_this select 0));
_tachetitre = (_this select 1);
_tacheDesc = format ["Extraire %1 actuellement captif sur zone",_NomCible];

if(hdssysteme)then{
  [true,[_tache],[_tacheDesc,_tachetitre],(_marqueurzonedecombat call BIS_fnc_randomPosTrigger),0,2,true,"help"] call BIS_fnc_taskCreate;
}else{
  [true,[_tache],[_tacheDesc,_tachetitre],objnull,0,2,true,"help"] call BIS_fnc_taskCreate;
};

waituntil {_HommeOtage inArea [(getMarkerPos (hdsnombase select 0)),100,100,0,false] || !alive _HommeOtage || [_tache] call BIS_fnc_taskCompleted};

if (!alive _HommeOtage) then {[_tache,'FAILED',true] call BIS_fnc_taskSetState;};
if (_HommeOtage inArea [(getMarkerPos (hdsnombase select 0)),100,100,0,false]) then {[_tache,'SUCCEEDED',true] call BIS_fnc_taskSetState;};

[_HommeOtage] join grpNull;

deleteMarker _marqueurdemission;                                               //Supprime le marquer sur carte
deleteMarker _marqueurzonedecombat;

tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";
true
