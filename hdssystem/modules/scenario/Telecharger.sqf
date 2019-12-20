Private ["_pos_mission","_Piratobj","_nom_box","_Description","_Taille","_Visible"];

_pos_mission = _this select 0; // position de la mission complète
_Piratobj = _this select 1; // L'objet concerné par la tache
_nom_box = _this select 2; // Nom donné a l'objet
_Description = _this select 3; // Description de la tache
_Taille = _this select 4; // Titre de la tâches
_Visible = _this select 5; //Visible sur la carte

_rnum = str(round (random 999));

_coord =  _pos_mission;

_ZOperation = _Taille;
_ZDangeureuse = _ZOperation + (_Taille/2);
//Création de marqueur
_NomMarqueur = format ["pirM%1",_rnum];
_MarkerZoneM = createMarker [_NomMarqueur,_coord];
_MarkerZoneM setMarkerShape "Ellipse";
_MarkerZoneM setMarkerSize [_ZOperation,_ZOperation];
_MarkerZoneM setMarkerColor "colorOPFOR";
_MarkerZoneM setMarkerBrush "SolidBorder";
if (_Visible isEqualTo false) then {_MarkerZoneM setMarkerAlpha 0} else {_MarkerZoneM setMarkerAlpha 0.3};

//creation de la tache
_tache = "Tache_pirate" + _rnum + str(_pos_mission);
_tachetitre = format ["Pirater|%1",_nom_box];
_tacheDesc = _Description;


//Rend visible ou non la tache selon la choix effectué via la variable <_Visible>
if (_Visible isEqualTo false) then {
  [true,[_tache],[_tacheDesc,_tachetitre],objNull,0,2,true,"download"] call BIS_fnc_taskCreate;
} else {
[true,[_tache],[_tacheDesc,_tachetitre],(_NomMarqueur call BIS_fnc_randomPosTrigger),0,2,true,"download"] call BIS_fnc_taskCreate;
};

//création de l'add action pour récuperer les documents
_Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa";
[_Piratobj,"Récupérer",_Icone,_Icone,"_this distance _target < 3","_this distance _target < 3",
{},
{},
{[(_arguments select 0),'SUCCEEDED',true] call BIS_fnc_taskSetState;},
{},
[_tache],
60,0,true,false] remoteExec ["BIS_fnc_holdActionAdd",0,_Piratobj];

waitUntil{[_tache] call BIS_fnc_taskCompleted}; // Nettoage de la tache
deleteMarker _NomMarqueur;

  sleep 5;
  //[_tache] call BIS_fnc_deleteTask;
tache_scenario = tache_scenario + 1;
