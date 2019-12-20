Private ["_pos_mission","_nom_box","_Taille"];

_rnum = str(round (random 999));

_marqueurzonedecombat = [(_this select 0),(_this select 2),"colorOPFOR"] call fnc_objectif_creermarqueur;
_marqueurdemission = [((_marqueurzonedecombat call bis_fnc_randomPosTrigger)),(_this select 2),"colorOPFOR"] call fnc_objectif_creermarqueur;

_marqueurzonedecombat setMarkerAlpha 0;
_marqueurdemission setMarkerAlpha var_mission_transparance_marqueur;

if(hdssysteme)then{_marqueurzonedecombat setMarkerAlpha 1};
if(hdssysteme)then{_marqueurdemission setMarkerAlpha 1};

_pirateTable = ["Land_DataTerminal_01_F"];
_ObjetPiratable = selectRandom _pirateTable;



//création du terminal
_Piratobj = createVehicle [_ObjetPiratable,_marqueurdemission call BIS_fnc_randomPosTrigger, [], 0, "CAN_COLLIDE"];
_veh_nom = getText (configFile >> "cfgVehicles" >> (_ObjetPiratable) >> "displayName");
_nomvariable = ("hiddens_pirate" + _rnum);
_Piratobj setVehicleVarName _nomvariable;
missionNamespace setVariable [_nomvariable,_Piratobj];
publicVariable _nomvariable;

//Positionnement de la cible
//--------Début des vérifications-----------------
_TousObjetsTrouve = [(_this select 2),getpos _Piratobj,['house']] call fnc_objectif_liste_batimentsetplaces;
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
//----------Fin----------------------------
_Poste_dans_batiment = selectrandom ([_Un_Batiment_occupable] call BIS_fnc_buildingPositions);                       //Selectionne une coordonnées parmis la liste récupéré
_Piratobj setPos _Poste_dans_batiment;                                                                              //Place l'objet au coordonnées selectionné

//creation de la tache
_tache = "Tache_pirate" + _rnum;
_tachemarquer = format ["%1",_veh_nom];
_tachetitre = (_this select 1);
_tacheDesc = format ["Telecharger les donnée de %1 dans la zone hostile",_veh_nom];

if(hdssysteme)then{
  [true,[_tache],[_tacheDesc,_tachetitre],(_marqueurzonedecombat call BIS_fnc_randomPosTrigger),0,2,true,"download"] call BIS_fnc_taskCreate;
}else{
  [true,[_tache],[_tacheDesc,_tachetitre],objnull,0,2,true,"download"] call BIS_fnc_taskCreate;
};


//création de l'add action pour récupérer mes données
_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa";
[_Piratobj,"Récupérer",_Icone,_Icone,"_this distance _target < 3","_this distance _target < 3",

{
  [_target,1] call BIS_fnc_dataTerminalAnimate;
  _caller switchMove "Acts_TerminalOpen";
},
{},
{_caller SwitchMove "";
[(_arguments select 0),'SUCCEEDED',true] call BIS_fnc_taskSetState;
},
{[_target,0] call BIS_fnc_dataTerminalAnimate;
_caller switchMove "";
},
[_tache],
60,0,true,false] remoteExec ["BIS_fnc_holdActionAdd",0,_Piratobj];


waitUntil {[_tache] call BIS_fnc_taskCompleted};

deleteMarker _marqueurdemission;                                               //Supprime le marquer sur carte
deleteMarker _marqueurzonedecombat;

tache_effectuee = tache_effectuee + 1;publicVariable "tache_effectuee";
true
