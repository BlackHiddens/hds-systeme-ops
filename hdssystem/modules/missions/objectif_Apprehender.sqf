
params ["_Position","_NomCible","_Taille"];

_rnum = str(round (random 999));
_Localiter = nearestLocations [[0,0,0],["NameVillage","NameCity","NameLocal","Name","Strategic"],40000];

//zone globale de la missions
_marqueurzonedecombat = [(_this select 0),(_this select 2),"colorOPFOR"] call fnc_objectif_creermarqueur;
_marqueurlieudelivraison = [(locationposition (selectrandom _Localiter)),100,"colorBlufor"] call fnc_objectif_creermarqueur;
_marqueurlieuderecuperation = [((_marqueurzonedecombat call bis_fnc_randomPosTrigger)),(_this select 2),"colorOPFOR"] call fnc_objectif_creermarqueur;

_marqueurzonedecombat setMarkerAlpha 0;
_marqueurlieuderecuperation setMarkerAlpha var_mission_transparance_marqueur;

if(hdssysteme)then{_marqueurzonedecombat setMarkerAlpha 1};
if(hdssysteme)then{_marqueurlieuderecuperation setMarkerAlpha 1};

//configuration de la Cible
_Cible = [(_this select 0),0,(selectRandom ["I_Story_Officer_01_F"]),independent] call bis_fnc_spawnvehicle;
_GroupeCible = [(_this select 0),independent,5] call bis_fnc_spawnGroup;
(units _GroupeCible) join (_Cible select 0);
_GroupeCible = (_Cible select 2);
//Positionnement de la cible
//--------Début des vérifications-----------------
_TousObjetsTrouve = [(_this select 2),getpos (_Cible select 0),['house']] call fnc_objectif_liste_batimentsetplaces;
if(count _TousObjetsTrouve isequalto 0)exitWith{
  tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";
  deleteMarker _marqueurzonedecombat;                                               //Supprime le marquer sur carte
  deleteMarker _marqueurlieuderecuperation;
  deleteMarker _marqueurlieudelivraison;
  if(hdssysteme)then{[format["%1 : L'une des tâche n'a pas pu être créée",hdsversion]] remoteexeccall ['systemChat',0]};
};
_Un_Batiment_occupable = selectrandom (_TousObjetsTrouve select 0);
if(isnil "_Un_Batiment_occupable")exitWith{
  tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";
  deleteMarker _marqueurzonedecombat;                                               //Supprime le marquer sur carte
  deleteMarker _marqueurlieuderecuperation;
  deleteMarker _marqueurlieudelivraison;
  if(hdssysteme)then{[format["%1 : L'une des tâche n'a pas pu être créée",hdsversion]] remoteexeccall ['systemChat',0]};
};
//------------Fin de vérification-------------
_Poste_dans_batiment = selectrandom ([_Un_Batiment_occupable] call BIS_fnc_buildingPositions);
{
  _Poste_dans_batiment = selectrandom ([_Un_Batiment_occupable] call BIS_fnc_buildingPositions);
  _x setPos _Poste_dans_batiment;
  _x forceSpeed 0;
} foreach (units _GroupeCible);


//creation de la tache
_tache = "TacheLivrer" + _rnum;
_tachetitre = (_this select 1);
_tacheDesc = format ["Capturer %1 en éliminant ses gardes",(_this select 1)];

if(hdssysteme)then{
  [true,[_tache],[_tacheDesc,_tachetitre],(_marqueurzonedecombat call BIS_fnc_randomPosTrigger),0,2,true,"interact"] call BIS_fnc_taskCreate;
}else{
  [true,[_tache],[_tacheDesc,_tachetitre],objnull,0,2,true,"interact"] call BIS_fnc_taskCreate;
};


_Apprehender = 0;
while {alive (_Cible select 0) && _Apprehender == 0} do {
    if(count units _GroupeCible < 3) then {
      (_Cible select 0) setCaptive true;
      [[(_Cible select 0),"Acts_CivilInjuredLegs_1"],"SwitchMove"] call bis_fnc_mp;
      //Ajout de l'addAction à lz cible
      _Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa";
      [(_Cible select 0),"Apprehender",_Icone,_Icone,"_this distance _target < 2","_this distance _target < 2",
        {},
        {},
        {[group _caller,_caller] remoteExec ["selectLeader", groupOwner group _caller];
        _target SwitchMove "";
        [_target] join (group _caller);
        removeAllPrimaryWeaponItems _target;
        },
      {},[_Apprehender],6,0,true,true] remoteExec ["BIS_fnc_holdActionAdd",0,(_Cible select 0)];
      _Apprehender = 1;
    };
    sleep 2;
};

waitUntil {[_marqueurlieudelivraison,(_Cible select 0)] call bis_fnc_intrigger or  !alive (_Cible select 0)};

if (!alive (_Cible select 0)) then {
  [_tache,'FAILED',true] call BIS_fnc_taskSetState;
};

if ([_marqueurlieudelivraison,(_Cible select 0)] call bis_fnc_intrigger) then {
  [_tache,'SUCCEEDED',true] call BIS_fnc_taskSetState;
};

waitUntil{[_tache] call BIS_fnc_taskCompleted}; // Nettoage de la tache

deleteMarker _marqueurzonedecombat;                                               //Supprime le marquer sur carte
deleteMarker _marqueurlieuderecuperation;
deleteMarker _marqueurlieudelivraison;

tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";
true
