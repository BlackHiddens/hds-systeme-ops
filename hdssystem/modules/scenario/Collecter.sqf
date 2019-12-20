params ["_Position","_Objets","_NomObjet","_Description","_Taille","_Visible"];

_Position = _this select 0; // Position de la mission
_Objets = _this select 1; // Cible de la mission
_NomObjet = _this select 2; // Nom de la cible
_Description = _this select 3; // Description de la mission
_Taille = _this select 4; // Taille du rayon de la zone de mission
_Visible = _this select 5; //true ou false pour rendre ou non visible la tache et la zone sur carte

_rnum = str(round (random 999)); // Génération d'un nombre aléatoire

_Position = _Position;

//Création du marqueur de mission
_NomMarquer = format ["Collecter_%1",_rnum];
_MarkerZoneMarquer = createMarker [_NomMarquer,_Position];
_MarkerZoneMarquer setMarkerShape "Ellipse";
_MarkerZoneMarquer setMarkerSize [_Taille,_Taille];
_MarkerZoneMarquer setMarkerColor "colorOPFOR";
_MarkerZoneMarquer setMarkerBrush "SolidBorder";
if (_Visible isEqualTo false) then {_MarkerZoneMarquer setMarkerAlpha 0} else {_MarkerZoneMarquer setMarkerAlpha 0.3};

//Création de la tache
_Tache = format ["CollecterObjet%1",_rnum];
_TitreTache = format ["Collecter|%1",_NomObjet];
//Rend visible ou non la tache selon la choix effectué via la variable <_Visible>
if (_Visible isEqualTo false) then {
  [true,[_Tache],[_Description,_TitreTache],objNull,0,2,true,"intel"] call BIS_fnc_taskCreate;
} else {
  [true,[_Tache],[_Description,_TitreTache],(_NomMarquer call BIS_fnc_randomPosTrigger),0,2,true,"intel"] call BIS_fnc_taskCreate;
};
//appliquer l'ajout d'action sur l'ensemble des objets passé en paramètre via la variable <_Objets>
{
  _Icone = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_hack_ca.paa";
  [_x,"Récupérer",_Icone,_Icone,"_this distance _target < 2","_this distance _target < 2",{},{},
    {
    deleteVehicle _target;
    },
  {},[],1,0,true,false] remoteExec ["BIS_fnc_holdActionAdd",0,_x];
} forEach _Objets;

//Vérifie si tous les objets ont été détruit
_TousMorts = false;
while {_TousMorts isEqualTo false} do {
    _Reponse = 0;
    {
      if (!alive _x) then {_Reponse = _Reponse + 1};
      } forEach _Objets;
      if (_Reponse == count _Objets) then {_TousMorts = true};
};

[_Tache,'SUCCEEDED',true] call BIS_fnc_taskSetState;
waitUntil{[_Tache] call BIS_fnc_taskCompleted};
//Mode nettoyage activé
deleteMarker _NomMarquer;
sleep 5;
//[_tache] call BIS_fnc_deleteTask;
tache_scenario = tache_scenario + 1;
